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
	end
end