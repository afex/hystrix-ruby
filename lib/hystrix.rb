require 'celluloid'

require 'hystrix/command'
require 'hystrix/configuration'
require 'hystrix/circuit'
require 'hystrix/dsl'
require 'hystrix/executor_pool'
require 'hystrix/inline'

module Hystrix
	extend DSL

	def self.reset
		CommandExecutorPools.instance.shutdown
	end
end