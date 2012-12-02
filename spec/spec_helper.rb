ENV["RAILS_ENV"] ||= 'test'

require File.expand_path('../../../../config/environment', __FILE__)

RSpec.configure do |config|
  config.mock_with :rspec
  config.filter_run :focus => true
  config.run_all_when_everything_filtered = true
end
