# Usage: ruby scripts/import_ea_data.rb early-access-5 https://ea1-app.codecrafters.io
#
require "json"
require "net/http"
require "httparty"

slug = ARGV[0]
base_url = ARGV[1]

puts "Importing data from #{base_url} into #{slug}.."
Net::HTTP.get("example.com", "/index.html")
response = HTTParty.get("#{base_url}/api/v1/ea_data")
data = JSON.parse(response.body)

filename = "_data/early_access_trials/#{slug}.json"
File.write(filename, JSON.pretty_generate(data))
puts "Written data into #{filename}."
