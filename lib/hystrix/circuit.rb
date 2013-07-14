# Circuit-breaker to track and disable commands based on previous attempts
module Hystrix
	class Circuit
		include Celluloid

		attr_accessor :lock, :health, :recent_latency_errors, :last_health_check_time

		def initialize
			self.lock = Mutex.new
			self.recent_latency_errors = []
			self.health = 0
			self.last_health_check_time = nil
		end

		def is_closed?
			async.calculate_health if self.last_health_check_time == nil or self.last_health_check_time < Time.now.to_f - 10.0

			return false unless self.is_healthy?
			return true
		end

		def add_latency_error(duration)
			self.lock.synchronize do
				self.recent_latency_errors << {duration: duration, timestamp: Time.now.to_i}
			end
			async.calculate_health
		end

		def calculate_health
			now = Time.now.to_i
			self.lock.synchronize do
				self.recent_latency_errors = self.recent_latency_errors.reject{|error| error[:timestamp] < now - 10}
				self.health = self.recent_latency_errors.size * 0.2
				self.last_health_check_time = now.to_f
			end
		end

		def is_healthy?
			self.health < 1
		end
	end
end