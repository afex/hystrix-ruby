module Hystrix
	module DSL
		def configure(&block)
			Configuration.class_eval(&block)
		end
	end
end