module Hystrix
	class ExecutorPoolFullError < StandardError; end

	class Command
		include Celluloid

		attr_accessor :executor_pool

		def initialize(*args)
			self.executor_pool = CommandExecutorPools.instance.get_pool(executor_pool_name)
		end

		def execute
			executor = nil
			begin
				executor = executor_pool.take
				result = executor.run(self)
			rescue Exception => main_error
				begin
					result = fallback
				rescue NotImplementedError => fallback_error
					raise main_error
				end
			ensure
				executor.unlock if executor
				self.terminate
			end

			return result
		end

		def executor_pool_name
			self.class.name
		end

		def queue
			future.execute
		end

		def fallback
			raise NotImplementedError
		end
	end
end