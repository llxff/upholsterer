require "bundler/setup"
Bundler.require(:default, :development)

require "upholsterer"
require "ostruct"

Dir[File.dirname(__FILE__) + "/support/**/*.rb"].each do |file|
  require file
end
