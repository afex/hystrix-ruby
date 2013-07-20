module Hystrix
	module DSL
		def configure(&block)
			Configuration.class_eval(&block)
		end

		def inline(executor_pool_name = nil, &block)
			inline = InlineDSL.new(executor_pool_name)
			inline.instance_eval(&block)
			inline.run
		end
	end
end