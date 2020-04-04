require "pry"
require "json"
require "time"

profiles = JSON.parse(File.read("_data/user_profiles.json"))

users = profiles
  .map { |profile|
    {
      username: profile["username"],
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
    user[:username].ljust(20),
    ":",
    user[:completed_challenges].join(", ").ljust(20),
    ((Time.now - user[:first_completion_at]) / (3600 * 24)).round(1),
    "days ago"
  ].join(" ")
end
