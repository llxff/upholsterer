module Upholsterer
  module UrlMethods
    def default_url_options
      Rails.configuration.upholsterer.default_url_options ||
      Rails.configuration.action_mailer.default_url_options ||
      {}
    end
  end
end
