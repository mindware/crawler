require 'colorize'
require 'resque-retry'

class Crawler
	@queue = "automata_crawl"

	def self.perform(*args)
		# grab the url
		if args.length >= 1
			url	= args[0]
		else
			raise ArgumentError, "Crawler is missing url parameter."
		end
		# now grab the rest of the values if available, individually.
		# grab max_length, used to know how many links deep the crawler can go.
		if args.length >= 2
			max_depth = args[1]
		else
			max_depth = 0
		end
		# if depth is defined, incorporate it. This is used when
		# the job requests itself in a loop via the scraper, and flags how deep
		# we've gone thus far.
		if args.length >= 3
			depth	= args[2]
		else
			depth = 0
		end

		Resque.logger.debug "Crawler is running on depth level #{depth} with a "+
		"max depth of #{max_depth}."
		Scraper.new(max_depth, depth).fetch(url)

		# In case we shut down halfway, requeue.
	rescue Resque::TermException
		Resque.enqueue(self, args)
	rescue Exception => e
		puts "Error: #{e} ocurred\n#{e.backtrace.join("\n")}".red
		logger.error "Error: #{e} ocurred while updating transaction"
	end
end
