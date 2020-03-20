module Jekyll
  class CategoryPageGenerator < Generator
    safe true

    def generate(site)
      site.data["user_profiles"].each do |user|
        site.pages << UserPage.new(site, user["username"])
      end
    end
  end

  # A Page subclass used in the `CategoryPageGenerator`
  class UserPage < PageWithoutAFile
    def initialize(site, username)
      @site = site
      @base = site.source
      @dir = "users"
      @name = "#{username}.html"

      profile = site.data["user_profiles"].select { |profile|
        profile["username"] == username
      }.first

      self.process(@name)

      name = profile["name"]
      completed = profile["challenge_status"].select { |status|
        status["percentage_completed"] == 100
      }.count
      avatar_url = profile["avatar_url"]
      description = if completed == 1
                      "#{name || username} has completed 1 challenge on CodeCrafters"
                    else
                      "#{name || username} has completed #{completed} challenges on CodeCrafters"
                    end
      self.data = {
        "layout" => "default_tailwind",
        "title" => username + (name ? " (#{name})" : ""),
        "description" => description,
      }
      self.content = "{% include user_profile_page.html username=\"#{username}\" %}"
    end
  end
end
