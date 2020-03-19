serve: compile_profiles
	bundle exec jekyll serve --livereload

refresh_ea_data:
	bundle exec ruby scripts/import_ea_data.rb early-access-7 https://ea2-app.codecrafters.io
	bundle exec ruby scripts/import_ea_data.rb early-access-8 https://ea1-app.codecrafters.io

refresh_github_data:
	bundle exec ruby scripts/import_github_data.rb

refresh_discord_data:
	bundle exec ruby scripts/import_discord_joins.rb

refresh_and_compile_profiles: refresh_ea_data refresh_github_data refresh_discord_data compile_profiles

compile_profiles:
	bundle exec ruby scripts/compile_profiles.rb

preview_profiles:
	curl localhost:4000 # Checking the server is up
	cat _data/user_profiles.json \
		| jq ". | map(.username)" \
		| head -n -1 \
		| tail -n +2 \
		| tr -d ", \"" \
		| xargs -I {} xdg-open http://localhost:4000/users/{}

copy_course_files:
	hub api \
		repos/rohitpaulk/codecrafters-server/contents/codecrafters/store/data/redis.yml \
		| jq -r .content \
		| base64 -d \
		> _data/redis.yml

	hub api \
		repos/rohitpaulk/codecrafters-server/contents/codecrafters/store/data/docker.yml \
		| jq -r .content \
		| base64 -d \
		> _data/docker.yml
