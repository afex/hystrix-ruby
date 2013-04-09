require 'singleton'

module Hystrix
	class CommandExecutorPools
		include Singleton

		attr_accessor :pools, :lock

		def initialize
			self.lock = Mutex.new
			self.pools = {}
		end

		def get_pool(pool_name)
			lock.synchronize do
				pools[pool_name] ||= CommandExecutorPool.new(pool_name, 10)
			end
		end
	end

	class CommandExecutorPool
		attr_accessor :name, :size
		attr_accessor :executors, :lock

		def initialize(name, size)
			self.name = name
			self.size = size
			self.executors = []
			self.lock = Mutex.new
			size.times do
				self.executors << CommandExecutor.new
			end
		end

		def take
			self.lock.synchronize do
				for executor in self.executors
					unless executor.locked?
						executor.lock
						return executor
					end
				end
			end

			raise ExecutorPoolFullError.new("Unable to get executor from #{self.name} pool.")
		end
	end

	class CommandExecutor
		attr_accessor :owner

		def initialize
			self.owner = nil
		end

		def lock
			self.owner = Thread.current
		end

		def unlock
			self.owner = nil
		end
		
		def locked?
			!self.owner.nil?
		end

		def run(command)
			command.run
		end
	end
end