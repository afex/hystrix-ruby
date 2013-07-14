require 'spec_helper'

describe Hystrix::Circuit do
	context 'health threshold, ' do
		it 'is healthy if no commands have reported latency errors' do
			circuit = Hystrix::Circuit.new
			circuit.is_healthy?.should == true
		end

		it 'becomes unhealthy if X commands are slow within the last Y seconds.' do
			circuit = Hystrix::Circuit.new
			5.times do
				circuit.add_latency_error(rand(10))
			end
			circuit.is_healthy?.should == false
		end

		it 'opens the circuit when unhealthy' do
			circuit = Hystrix::Circuit.new
			circuit.wrapped_object.stub(:is_healthy?).and_return(false)
			circuit.is_closed?.should == false
		end

		it 'prunes old latency errors over time' do
			circuit = Hystrix::Circuit.new
			now = Time.now
			13.times do |i|
				Timecop.freeze(now - i) do
					circuit.add_latency_error(rand(10))
				end
			end

			sleep 1

			circuit.calculate_health
			circuit.recent_latency_errors.size.should == 10
		end

		it 'doesnt recalculate health every closed check' do
			circuit = Hystrix::Circuit.new
			circuit.wrapped_object.should_receive(:calculate_health).once.and_call_original
			now = Time.now
			
			2.times do |i|
				Timecop.freeze(now - i) do
					circuit.is_closed?
				end
			end
		end

		it 'only recalculates health every X seconds' do
			circuit = Hystrix::Circuit.new
			circuit.wrapped_object.should_receive(:calculate_health).twice.and_call_original
			now = Time.now
			
			12.times do |i|
				Timecop.freeze(now + i) do
					circuit.is_closed?
				end
			end
		end

		it 'allows the health to return back to 0' do
			circuit = Hystrix::Circuit.new
			now = Time.now
			Timecop.freeze(now - 11) do
				circuit.add_latency_error(rand(10))
			end

			circuit.health.should > 0

			circuit.calculate_health

			circuit.health.should == 0
		end
	end
end