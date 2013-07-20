require 'spec_helper'

describe Hystrix::InlineDSL do
	context 'declares commands' do
		it 'synchronously' do
			foo = 'bar'

			thing = Hystrix.inline do
				execute { foo*2 }
			end

			thing.should == 'barbar'
		end

		it 'asynchronously' do
			thing = Hystrix.inline do
				queue { 2+2 }
			end

			thing.value.should == 4
		end

		it 'with fallbacks' do
			thing = Hystrix.inline do
				execute { raise 'woops' }
				fallback { |error| 'fallback' }
			end

			thing.should == 'fallback'
		end	
	end

	it 'sets the executor_pool_name for the block' do
		mock = double
		mock.should_receive(:check).with('sup')

		Hystrix.configure do
			on_success do |command_name, duration|
				mock.check(command_name)
			end
		end

		thing = Hystrix.inline 'sup' do
			execute { 'hi' }
		end

		Hystrix::Configuration.reset
	end
end