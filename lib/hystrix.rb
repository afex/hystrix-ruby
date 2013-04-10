require 'celluloid'

require 'hystrix/command'
require 'hystrix/executor_pool'

module Hystrix
	def self.reset
		CommandExecutorPools.instance.shutdown
	end
end