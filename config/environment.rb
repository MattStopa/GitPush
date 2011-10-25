# Load the rails application
require File.expand_path('../application', __FILE__)

# Initialize the rails application
GitPush::Application.initialize!

Mongoid.configure do |config|
  config.master = Mongo::Connection.new.db("git_push")
end
