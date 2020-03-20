# Usage: ruby scripts/import_ea_data.rb early-access-5 https://ea1-app.codecrafters.io
#
require "octokit"
require "pry"

FILENAME = "_data/github_data.json"

client = Octokit::Client.new(access_token: ENV["GITHUB_TOKEN"])

all_gh_logins = Dir["_data/early_access_trials/*"].map { |f|
  JSON.parse(File.read(f)).fetch("users").map { |user| user["username"] }
}.flatten.uniq

existing_data = JSON.parse(File.read(FILENAME))
existing_usernames = existing_data.map { |user| user.fetch("username") }

all_gh_logins.each do |login|
  next if existing_usernames.include?(login)

  puts "Fetching details for #{login}"

  gh_user = client.user(login)
  existing_data.push({
    "username": gh_user[:login],
    "id": gh_user[:id],
    "name": gh_user[:name],
  })
end

File.write(FILENAME, JSON.pretty_generate(existing_data))
