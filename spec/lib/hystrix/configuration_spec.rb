require 'spec_helper'

describe Hystrix::Configuration do
	after do
		Hystrix::Configuration.reset
	end

	it 'defines callbacks via dsl' do
		Hystrix.configure do
			on_success do |command_name, duration|
				raise 'callback'
			end
		end

		expect {
			Hystrix::Configuration.notify_success('test', 30)
		}.to raise_error('callback')
	end
end