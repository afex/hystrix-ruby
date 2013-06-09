require 'celluloid'

require 'hystrix/command'
require 'hystrix/configuration'
require 'hystrix/dsl'
require 'hystrix/executor_pool'

module Hystrix
	extend DSL

	def self.reset
		CommandExecutorPools.instance.shutdown
	end
end