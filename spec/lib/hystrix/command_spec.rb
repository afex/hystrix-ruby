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

		def fallback(error)
			return 'it failed'
		end
	end

	context 'notifies callbacks,' do
		before do
			
		end

		after do
			Hystrix::Configuration.reset
		end

		it 'on success' do
			test_name = nil
			test_duration = nil

			Hystrix.configure do
				on_success do |command_name, duration|
					test_name = command_name
					test_duration = duration
				end
			end

			CommandHelloWorld.new('keith').execute

			test_name.should == 'CommandHelloWorld'
			test_duration.should > 0
		end

		it 'on fallback' do
			pending 'todo'
		end

		it 'on failure' do
			pending 'todo'
		end
	end

	it 'allows commands to define their pool size' do
		class SizedPoolCommand < Hystrix::Command
			pool_size 3
		end

		cmd = SizedPoolCommand.new
		cmd.executor_pool.size.should == 3
	end

	context '.execute' do
		it 'supports sychronous execution' do
			CommandHelloWorld.new('keith').execute.should == 'keith'
		end

		it 'returns fallback value on error' do
			CommandHelloWorld.new('keith', 0, true).execute.should == 'it failed'
		end

		it 'sends exception to fallback method on error' do
			c = CommandHelloWorld.new('keith', 0, true)
			c.wrapped_object.should_receive(:fallback).with do |error|
				error.message.should == 'error'
			end
			c.execute
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

	it 'throws an error if a command class does not run the base initialize method' do
		class Cmd < Hystrix::Command
			def initialize; end
			def run; end
		end

		expect {
			Cmd.new.execute
		}.to raise_error
	end
end