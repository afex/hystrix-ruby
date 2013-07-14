require 'spec_helper'

describe Hystrix::CommandExecutor do
	let(:executor) { Hystrix::CommandExecutor.new }

	it 'can be locked' do
		executor.locked?.should == false
		executor.lock
		executor.locked?.should == true
	end

	it 'executes commands' do
		class MyCommand < Hystrix::Command
			def run
				return 'hi'
			end
		end

		executor.run(MyCommand.new).should == 'hi'
	end
end

describe Hystrix::CommandExecutorPool do
	it 'creates pool objects when constructed' do
		Hystrix::CommandExecutorPool.new('test', 10).executors.size.should == 10
	end

	context '.take' do
		it 'fails if all executors are locked' do
			pool = Hystrix::CommandExecutorPool.new('test', 1)
			pool.take.should_not == nil
			expect { pool.take }.to raise_error(Hystrix::ExecutorPoolFullError)
		end

		it 're-uses executors after they are unlocked' do
			pool = Hystrix::CommandExecutorPool.new('test', 1)
			executor = pool.take
			executor.unlock
			pool.take.object_id.should == executor.object_id
		end

		it 'fails if there are no executors configured' do
			pool = Hystrix::CommandExecutorPool.new('test', 0)
			expect { pool.take }.to raise_error
		end
	end

	context '.shutdown' do
		it 'shuts down all registered pools' do
			pool = Hystrix::CommandExecutorPool.new('test', 10)
			pool.shutdown
			pool.executors.size.should == 0
		end

		it 'lets commands finish when shutting down' do
			class SleepCommand < Hystrix::Command
				def run
					sleep 1
					return 'my value'
				end
			end
			pool = Hystrix::CommandExecutorPool.new('test', 10)
			command = SleepCommand.new
			command.executor_pool = pool
			future = command.queue

			sleep 0.1
			
			pool.shutdown

			pool.executors.size.should == 0
			future.value.should == 'my value'
		end
	end
end