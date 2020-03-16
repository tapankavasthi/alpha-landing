require "json"
require "yaml"
require "time"

class User
  attr_reader :username
  attr_reader :name
  attr_reader :avatar_url
  attr_reader :joined_early_access_at

  def initialize(username:, name:, avatar_url:, joined_early_access_at:)
    @username = username
    @name = name
    @avatar_url = avatar_url
    @joined_early_access_at = joined_early_access_at
  end

  def joined_early_access_event
    JoinedEarlyAccessEvent.new(
      username: username,
      date: joined_early_access_at,
    )
  end

  def self.from_file(path)
    json = YAML.load(File.read(path))

    json.map { |hash|
      User.new(
        username: hash.fetch("username"),
        name: hash.fetch("name"),
        avatar_url: hash.fetch("avatar_url"),
        joined_early_access_at: Time.parse(hash.fetch("joined_early_access_at")),
      )
    }
  end
end

class CompletedChallengeEvent
  attr_reader :username
  attr_reader :date
  attr_reader :challenge
  attr_reader :language

  def initialize(username:, date:, challenge:, language:)
    @username = username
    @date = date
    @challenge = challenge
    @language = language
  end

  def to_json(*args)
    {
      "type": "completed-challenge",
      "challenge": challenge,
      "language": language,
      "timestamp": date.iso8601,
    }
  end
end

class StartedChallengeEvent
  attr_reader :username
  attr_reader :date
  attr_reader :challenge
  attr_reader :language

  def initialize(username:, date:, challenge:, language:)
    @username = username
    @date = date
    @challenge = challenge
    @language = language
  end

  def to_json(*args)
    {
      "type": "started-challenge",
      "challenge": challenge,
      "language": language,
      "timestamp": date.iso8601,
    }
  end
end

class JoinedEarlyAccessEvent
  attr_reader :username
  attr_reader :date

  def initialize(username:, date:)
    @username = username
    @date = date
  end

  def to_json(*args)
    {
      "type": "joined-early-access",
      "timestamp": date.iso8601,
    }
  end
end

class EarlyAccessTrial
  attr_reader :slug
  attr_reader :challenge_slug
  attr_reader :started_at
  attr_reader :ended_at
  attr_reader :participants

  def initialize(slug:,
                 challenge_slug:,
                 started_at:,
                 ended_at:,
                 participants:)
    @slug = slug
    @challenge_slug = challenge_slug
    @started_at = started_at
    @ended_at = ended_at
    @participants = participants
  end

  def user_languages_completed(username)
    participants
      .select { |p| p.username == username }
      .select { |p| p.percentage_completed == 100 }
      .map { |p| p.language }
  end

  def user_percentage_completed(username)
    participant = participants.select { |p| p.username == username }.first
    return participant&.percentage_completed || 0
  end

  def self.from_file(path)
    json = JSON.parse(File.read(path))
    EarlyAccessTrial.new(
      slug: json.fetch("slug"),
      challenge_slug: json.fetch("challenge_slug"),
      started_at: Time.parse(json.fetch("started_at")),
      ended_at: Time.parse(json.fetch("ended_at")),
      participants: json.fetch("users").map { |user|
        EarlyAccessParticipant.new(
          username: user.fetch("username"),
          language: user.fetch("language"),
          stages_completed: user.fetch("stage_reached"),
          total_stages: json.fetch("total_stages"),
        )
      },
    )
  end

  def challenge_events
    participants.map { |participant|
      events = []
      events.push(
        StartedChallengeEvent.new(
          username: participant.username,
          date: started_at,
          challenge: challenge_slug,
          language: participant.language,
        )
      )

      if participant.has_completed?
        events.push(
          CompletedChallengeEvent.new(
            username: participant.username,
            date: ended_at,
            challenge: challenge_slug,
            language: participant.language,
          )
        )
      end

      events
    }.flatten
  end
end

class EarlyAccessParticipant
  attr_reader :username
  attr_reader :language
  attr_reader :stages_completed
  attr_reader :total_stages

  def initialize(username:, language:,
                 stages_completed:,
                 total_stages:)
    @username = username
    @language = language
    @stages_completed = stages_completed
    @total_stages = total_stages
  end

  def percentage_completed
    (100 * (@stages_completed * 1.0 / @total_stages)).to_i
  end

  def has_completed?
    percentage_completed == 100
  end
end

trials = Dir["_data/early_access_trials/*"].map { |f| EarlyAccessTrial.from_file(f) }

users_map = User.from_file("_data/users.yml").map { |user| [user.username, user] }.to_h
challenge_events = trials.map { |trial| trial.challenge_events }.flatten

# Only consider completed ones
challenge_events_by_user = challenge_events.group_by(&:username)
challenge_events_by_user = challenge_events_by_user.select do |_username, events|
  events.any? { |x| x.class == CompletedChallengeEvent }
end

users_to_consider = challenge_events_by_user.keys.map { |username| users_map.fetch(username) }

profiles = users_to_consider.map do |user|
  user_joined_event = user.joined_early_access_event
  user_challenge_events = challenge_events.select { |event| event.username == user.username }

  events = [user_joined_event, *user_challenge_events]
  challenge_status = ["docker", "redis"].map do |challenge_slug|
    percentage_completed = trials
      .select { |trial| trial.challenge_slug == challenge_slug }
      .map { |trial| trial.user_percentage_completed(user.username) }
      .max

    languages_used = trials
      .select { |trial| trial.challenge_slug == challenge_slug }
      .map { |trial| trial.user_languages_completed(user.username) }
      .flatten
    {
      "slug": challenge_slug,
      "percentage_completed": percentage_completed,
      "languages_used": languages_used,
    }
  end
  challenge_status = challenge_status.sort_by { |x| x["percentage_completed"] }.reverse
  languages_used = trials.map { |t| t.user_languages_completed(user.username) }.flatten
  {
    "username" => user.username,
    "name" => user.name,
    "joined_at" => user.joined_early_access_at,
    "avatar_url" => user.avatar_url,
    "languages_used" => languages_used,
    "events" => events.map(&:to_json),
    "challenge_status" => challenge_status,
  }
end

File.write("_data/user_profiles.json", JSON.pretty_generate(profiles))
puts "Dumped #{profiles.count} profiles."
puts profiles.map { |x| " - http://localhost:4000/users/#{x.fetch("username")}" }
