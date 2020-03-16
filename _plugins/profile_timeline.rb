module ProfileHelpers
  class CompletedChallengeEvent
    attr_reader :date
    attr_reader :challenge
    attr_reader :language

    def initialize(date, challenge, language)
      @date = date
      @challenge = challenge
      @language = language
    end

    def to_liquid
      {
        "text" => "Completed the #{challenge_link} challenge using #{language["name"]}",
        "color" => "teal",
      }
    end

    def challenge_link
      "<a href='/challenges/#{challenge["slug"]}'>#{challenge["name"]}</a>"
    end
  end

  class StartedChallengeEvent
    attr_reader :date
    attr_reader :challenge
    attr_reader :language

    def initialize(date, challenge, language)
      @date = date
      @challenge = challenge
      @language = language
    end

    def to_liquid
      {
        "text" => "Started the #{challenge_link} challenge using #{language["name"]}",
        "color" => "gray",
      }
    end

    def challenge_link
      "<a href='/challenges/#{challenge["slug"]}'>#{challenge["name"]}</a>"
    end
  end

  class JoinedEarlyAccessEvent
    attr_reader :date

    def initialize(date)
      @date = date
    end

    def to_liquid
      {
        "text" => "Joined the <a href='/early-access'>early access</a> program",
        "color" => "indigo",
      }
    end
  end

  # Takes a
  module TimelineFilter
    def profile_timeline(user)
      site = Jekyll.sites.first
      challenge_map = site.data["challenges"].map { |x| [x["slug"], x] }.to_h
      language_map = site.data["languages"].map { |x| [x["slug"], x] }.to_h
      events = user["events"].map { |event_hash|
        case event_hash["type"]
        when "completed-challenge"
          CompletedChallengeEvent.new(
            Time.parse(event_hash["timestamp"]),
            challenge_map[event_hash["challenge"]],
            language_map[event_hash["language"]],
          )
        when "joined-early-access"
          JoinedEarlyAccessEvent.new(
            Time.parse(event_hash["timestamp"])
          )
        when "started-challenge"
          StartedChallengeEvent.new(
            Time.parse(event_hash["timestamp"]),
            challenge_map[event_hash["challenge"]],
            language_map[event_hash["language"]],
          )
        else
          raise "Unrecognized event #{event_hash["type"]}"
        end
      }

      events.sort_by(&:date).group_by { |x| [x.date.month, x.date.year] }.map { |k, v|
        months = [
          "January", "February", "March", "April", "May", "June",
          "July", "August", "September", "October", "November", "December",
        ]

        {
          "month" => "#{months[k[0] - 1]} #{k[1]}",
          "entries" => process_events_in_month(v),
        }
      }.reverse
    end

    private

    def process_events_in_month(events)
      finished_challenges = events
        .select { |e| e.class == CompletedChallengeEvent }
        .map { |e| e.challenge }

      events = events.reject { |e|
        e.class == StartedChallengeEvent && finished_challenges.include?(e.challenge)
      }
      events.sort_by(&:date).reverse
    end
  end
end

Liquid::Template.register_filter(ProfileHelpers::TimelineFilter)
