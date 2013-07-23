require 'simplecov'

SimpleCov.start do
  add_group "Rack Code", "/lib"
end

require 'rspec'
require 'rack/contrib/sign'

RSpec.configure do |config|
  config.mock_with :rspec
end

