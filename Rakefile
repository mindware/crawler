require 'dotenv'
Dotenv.load

require 'bundler/setup'
Bundler.require

require 'resque'
require 'resque/tasks'
require 'resque/scheduler/tasks'

require 'resque/logging'

Dir.chdir File.dirname(__FILE__)

# include all the things!
Dir['./app/workers/*.rb',
		'./app/helpers/*.rb',
		'./app/models/*.rb' ].each {|file| require file }

$db = Redis.new

# testing adding a new logger
# Redis.logger = Logger.new

namespace :redis do
	desc "Redis"
	task :start do
		exec "sudo /etc/init.d/redis start"
	end

	task :stop do
		exec "redis-cli shutdown"
	end

        task :restart do
		:stop
		:start
        end

end

namespace :automata do
	desc "Automata"
	task :job do
		puts "Enquing job"
		Resque.enqueue(Worker, "Andres")
	end

	task :crawl do
		# urls  = ["http://www.kurzweilai.net/videos"]
		urls  = [
			 "https://www.engadget.com/",
			 "http://www.kurzweilai.net/videos",
			 "http://futurism.com/",
			 "https://www.reddit.com/r/Futurism/",
			 "http://ieet.org/index.php/IEET/media",
			 "http://www.deepstuff.org/"
		 ]
		urls.each do |url|
			Resque.enqueue(Crawler, url, 3)
		end
	end
end

namespace :scrape do
	desc "Scrape"
	task :test do
		scrape = Scraper.new
		url = "http://thoughtware.tv"
		scrape.fetch(url)
	end
end
