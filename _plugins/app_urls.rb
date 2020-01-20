module AppURLHelpers
  class AppURL < Liquid::Tag
    def initialize(tag_name, markup, opts)
      super
      @endpoint_name = markup.strip
    end

    def render(context)
      base_url = base_url_from_context(context)
      path = context.registers[:site].data["app_urls"][@endpoint_name]
      "#{base_url}#{path}"
    end

    private

    def base_url_from_context(context)
      if Jekyll.env == "production"
        return "https://app.codecrafters.io"
      else
        return "https://#{Jekyll.env}-app.codecrafters.io"
      end
    end
  end
end

Liquid::Template.register_tag("app_url", AppURLHelpers::AppURL)
