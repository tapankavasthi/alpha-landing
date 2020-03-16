serve:
	bundle exec jekyll serve --livereload

compile_profiles:
	bundle exec ruby scripts/compile_profiles.rb

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
