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
    if !@memory.visited? root_url
      @memory.save_url(root_url)
    end

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

    # save the totals, we'll use it later to know how many we filtered
    total = links.length
    # Link Filter: Pass 2 (discard duplicates on this page)
    links = links.group_by{|r|
      r[:url]}.map do |k, v| v.inject({}) { |r, h|
        r.merge(h){ |key, o, n| o || n } }
      end
      #
      # links.each do |link|
      #   if link[:title].to_s.length > 0
      #     puts link[:title].green
      #   else
      #     puts "[Untitled]".light_black
      #   end
      #   puts "\t#{link[:url]}".cyan
      # end

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
              # remember all urls that are being visited so we don't
              # over-queue stuff that hasn't been visited but is
              # already queued for visiting.
              @memory.save_url(link[:url])
              Resque.enqueue(Crawler, link[:url], @max_depth, @depth + 1)
            else
              puts "[Skipping]".yellow + " #{link[:url]}".light_black
            end
          else
            # if not a traesure, it wont get saved and we can safely
            # document this as a non external link
            if (!@memory.is_treasure?(link[:url]))
              puts "[External]".magenta + " #{link[:url]}".light_black
            end
          end
        end
      end
    end
  end
