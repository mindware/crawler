require 'capybara'
require 'capybara/dsl'
require 'capybara/poltergeist'

class Scraper
    include Capybara::DSL

    def initialize(max_depth=0, depth=0)
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

    def fetch(url)
        # if we got fed an invalid url, raise an exception.
        if ! valid_url?(url)
          raise Exception, "Cannot scrape an invalid URL: #{url}"
        end

        # fetch the url
        visit url

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
                Resque.enqueue(Crawler, link[:url], @max_depth, @depth + 1)
            end
        end
    end
end
