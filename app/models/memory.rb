require 'colorize'
require_relative "../helpers/url"

class Memory

  def initialize
    @default_term = 3600; # 1 hour
  end

  # path for the set containing visited urls per domain.
  def db_domain_path_visited(domain)
    db_domain_path(domain, "visited")
  end

  # gives the path to a domain key for the db
  # appends the type value to the key (automatically adding : if type is empty)
  def db_domain_path(domain, type="")
    # if type is not nil or empty, add : before the key
    type = ":#{type}" if type.to_s.length > 0
    "automata:domain:#{domain}#{type}"
  end

  # Updates a domain Set (instead of sorted, because of speed is O(1) vs O(log(n)))
  # No need to check if domain_key exists, as if it doesn't it'll be created
  # No need to check if url exists as a member, as it won't be added it if does
  # (by redis design).
  def save_url(url)
    domain = get_domain(url)
    raise Exception, "The domain appears to be nil for #{url}." if(domain.nil?)
    domain_key = db_domain_path_visited(domain)

    # append the url to this set.
    # ie: set key: "automata:domain:thoughtware.tv" value: "http://youtube.com/1"
    puts "[Memory]".blue + " Saving #{url.yellow} in #{domain_key.green}"
    $db.sadd(domain_key, url)
    $db.expire(domain_key, @default_term)
  end

  def visited?(url)
    domain_key = db_domain_path_visited(get_domain(url))
    $db.sismember(domain_key, url) == 1 ? true : false
  end


  # def save_treasure(url, url_from)
  #
  # end


end
