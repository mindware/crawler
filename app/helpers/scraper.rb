require 'capybara'
require 'capybara/dsl'
require 'capybara/poltergeist'
require 'colorize'
require_relative '../models/memory'

class Scraper
    include Capybara::DSL

    def initialize(max_depth=0, depth=0)
      @memory = Memory.new

      if depth == max_depth
        puts "Crawling depth is at Maximum depth. No additional "+
             "crawling will be performed."
      end

      # max_depth will determine how many links we'll crawl.
      # A default max_depth of 0 means no crawling.
      @max_depth = max_depth
      @depth = depth

      # register poltergeist not to blow up on websites with js errors
      Capybara.register_driver :poltergeist do |app|
          Capybara::Poltergeist::Driver.new(app, js_errors: false, phantom_js_options: ['--ignore-ssl-errors=yes'])
      end
      Capybara.default_driver = :poltergeist
    end

    def fetch(root_url)
        # if we got fed an invalid url, raise an exception.
        if ! valid_url?(root_url)
          raise Exception, "Cannot scrape an invalid URL: #{root_url}"
        end

        # fetch the url
        visit root_url

        # Remember for a temporary term (defined in @Memory), that we've
        # visited this url. Usually this will last about one hour.
        # We need to make sure we remember it here, so that if this url
        # links to itself, we won't be caught in a loop.
        @memory.save_url(root_url)

        # Get links from this url
        links = []
        all("a").each do |link|
          title = link.text.to_s.strip
          url   = link['href'].to_s.strip
          # Link Filter: Pass 1 (only grab valid urls)
          if valid_url?(url)
              item = {}
              # don't add a title if it's not available. This is useful
              # on merges.
              item[:title] = title if title.to_s.length > 0
              item[:url] = url # we already know url is valid
              # append this item to the list of links
              links << item
          end
        end

        # Link Filter: Pass 2 (discard duplicates on this page)
        total = links.length
        links.each do |link|
          if link[:title].to_s.length > 0
            puts link[:title].green
          else
            puts "[Untitled]".light_black
          end
          puts "\t#{link[:url]}".cyan
        end

        puts "Filtered a total of: #{total - links.length} out of #{total}."


        # Filter links that we've seen lately

        # Crawl

        # only do crawling if our current @depth is less than @max_depth
        if (@depth < @max_depth)
            # Later we may want to do this atomically for all links together
            # on redis, so that no link is added in case this worker dies
            links.each do |link|
                # if this link belongs to this domain. Only allow crawling
                # for this specific site. Ignore external links and links
                # that have already been visited recently.
                if(same_domain(root_url, link[:url]))
                  if(!@memory.visited?(link[:url]))
                    puts "[Queuing]".green + " #{link[:url]}".cyan
                    Resque.enqueue(Crawler, link[:url], @max_depth, @depth + 1)
                  else
                    puts "[Visited]".yellow + " #{link[:url]}".light_black
                  end
                else
                  puts "[External]".magenta + " #{link[:url]}".light_black
                end
            end
        end
    end
end
