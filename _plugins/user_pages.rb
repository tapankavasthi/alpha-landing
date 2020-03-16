module Jekyll
  class CategoryPageGenerator < Generator
    safe true

    def generate(site)
      site.data["users"].each do |user|
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

      self.process(@name)
      self.data = { "layout" => "default_tailwind" }
      self.content = "{% include user_profile_page.html username=\"#{username}\" %}"
    end
  end
end
