require "pry"
require "json"

profiles = JSON.parse(File.read("_data/user_profiles.json"))

users = profiles
  .sort_by { |profile| profile["joined_at"] }
  .map { |profile|
    {
      username: profile["username"],
      completed_challenges: profile["events"]
        .select { |event| event["type"] == "completed-challenge" }
        .map { |event| event["challenge"] }
    }
  }

users.each_with_index do |user, index| 
  puts "#{((index+1).to_s + ".").ljust(3)} #{user[:username].ljust(20)}: #{user[:completed_challenges].join(", ")}"
end
