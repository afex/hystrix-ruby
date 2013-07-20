module Hystrix
	class InlineDSL
		def initialize(executor_pool_name = nil)
			@executor_pool_name = executor_pool_name
			@mode = :execute
		end

		def execute(&block)
			@mode = :execute
			@run_block = block
		end

		def queue(&block)
			@mode = :queue
			@run_block = block
		end

		def fallback(&block)
			@fallback_block = block
		end

		def run
			cmd = InlineCommand.new(@executor_pool_name, @run_block, @fallback_block)
			cmd.send(@mode)
		end
	end

	class InlineCommand < Command
		def initialize(executor_pool_name, run_block, fallback_block)
			@run_block = run_block
			@fallback_block = fallback_block
			@executor_pool_name = executor_pool_name
			super
		end

		def run
			@run_block.yield
		end

		def fallback(error)
			if @fallback_block
				@fallback_block.yield(error)
			else
				raise NotImplementedError
			end
		end
	end
end