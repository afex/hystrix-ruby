require 'timecop'

require 'rspec'
require 'simplecov'
require 'simplecov-rcov'
SimpleCov.formatter = SimpleCov::Formatter::RcovFormatter
SimpleCov.add_filter 'vendor'
SimpleCov.add_filter 'spec'
SimpleCov.start

require_relative '../lib/hystrix.rb'

RSpec.configure do |config|
  config.mock_with :rspec
end