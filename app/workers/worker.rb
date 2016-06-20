require 'resque-retry'

class Worker

	@queue = "automata"
	def self.perform(*args)
		Resque.logger.debug "This is work, #{args}."
	end
end
