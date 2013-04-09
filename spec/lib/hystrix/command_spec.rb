require 'spec_helper'

describe Hystrix::Command do
	class CommandHelloWorld < Hystrix::Command
		attr_accessor :string, :wait, :fail

		def initialize(string, wait = 0, fail = false)
			self.string = string
			self.fail = fail
			self.wait = wait
			super
		end

		def run
			sleep wait

			if fail
				abort 'error'
			else
				return self.string
			end
		end

		def fallback
			return 'it failed'
		end
	end

	context '.execute' do
		it 'supports sychronous execution' do
			CommandHelloWorld.new('keith').execute.should == 'keith'
		end

		it 'returns fallback value on error' do
			CommandHelloWorld.new('keith', 0, true).execute.should == 'it failed'
		end
	end	

	context '.queue' do
		it 'supports asynchronous execution' do
			CommandHelloWorld.new('keith').queue.value.should == 'keith'
		end

		it 'returns fallback value on error' do
			CommandHelloWorld.new('keith', 0, true).queue.value.should == 'it failed'
		end	
	end

	it 'can execute only once' do
		c = CommandHelloWorld.new('keith')
		c.execute.should == 'keith'
		expect { c.execute }.to raise_error
		expect { c.queue.value }.to raise_error
	end

	it 'raises the original exception if no fallback is defined' do
		class CommandWithNoFallback < Hystrix::Command
			def run
				abort 'the error'
			end
		end

		expect { CommandWithNoFallback.new.execute }.to raise_error('the error')
	end

	it 'executes the fallback if it unable to grab an executor to run the command' do
		pool = Hystrix::CommandExecutorPool.new('my pool', 1)

		c1 = CommandHelloWorld.new('foo', 1)
		c1.executor_pool = pool
		c2 = CommandHelloWorld.new('bar')
		c2.executor_pool = pool

		future = c1.queue
		c2.execute.should == 'it failed'
		future.value.should == 'foo'
	end
end