require "pry"
require "json"
require "time"
require "yaml"

profiles = JSON.parse(File.read("_data/user_profiles.json"))

github_discord_mapping = YAML.load(File.read("_data/github_discord_mapping.yml")).map { |k|
  [k.fetch("github_username"), k.fetch("discord_username")]
}.to_h

users = profiles
  .map { |profile|
    {
      github_username: profile["username"],
      discord_username: github_discord_mapping.fetch(profile["username"], "NIL"),
      completed_challenges: profile["events"]
        .select { |event| event["type"] == "completed-challenge" }
        .map { |event| event["challenge"] },
      first_completion_at: profile["events"]
        .select { |event| event["type"] == "completed-challenge" }
        .map { |event| Time.parse(event["timestamp"]) }
        .min,
    }
  }
  .sort_by { |user| user[:first_completion_at] }

users.each_with_index do |user, index| 
  puts [
    ((index+1).to_s + ".").ljust(3),
    "#{user[:github_username]} (#{user[:discord_username]})".ljust(20),
    ":",
    user[:completed_challenges].join(", ").ljust(20),
    ((Time.now - user[:first_completion_at]) / (3600 * 24)).round(1),
    "days ago"
  ].join(" ")
end
