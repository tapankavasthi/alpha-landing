# Usage: ruby scripts/import_ea_data.rb early-access-5 https://ea1-app.codecrafters.io
#
require "discordrb"
require "pry"

FILENAME = "_data/discord_joins.json"

existing_data = JSON.parse(File.read(FILENAME)).map { |m|
  {
    "id" => m.fetch("id"),
    "username" => m.fetch("username"),
    "joined_at" => Time.parse(m.fetch("joined_at")).round,
  }
}

bot = Discordrb::Bot.new(token: ENV.fetch("DISCORD_BOT_TOKEN"))

new_data = []
after = nil
loop do
  members_json = Discordrb::API::Server.resolve_members(bot.token, 673463293901537291, 200, after)
  members = JSON.parse(members_json)
  break if members.empty?
  new_data += members.map { |member|
    {
      "id" => member.fetch("user").fetch("id"),
      "username" => member.fetch("user").fetch("username"),
      "joined_at" => Time.parse(member.fetch("joined_at")).round,
    }
  }
  puts "Read #{new_data.count} members"
  after = members.last.fetch("user").fetch("id")
end

existing_data.each do |member|
  new_data_match = new_data
    .select { |m| m["id"] == member["id"] }
    .sort_by { |m| m["joined_at"] }
    .first

  if new_data_match and new_data_match["joined_at"] != member["joined_at"]
    raise RuntimeError.new <<~EOF
                             Expected values for #{member["username"]} to match.

                             Got #{member["joined_at"]} (old) and #{new_data_match["joined_at"]} (new)"
                           EOF
  end
end

new_data = new_data.sort_by { |m| m.fetch("joined_at") }
File.write(FILENAME, JSON.pretty_generate(new_data))
