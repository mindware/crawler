require 'colorize'
require 'uri'
require 'domainatrix'

def valid_url?(url)
  uri = URI.parse(url)
  uri.kind_of?(URI::HTTP)
rescue URI::InvalidURIError
  false
rescue URI::InvalidComponentError
  false
rescue Exception => e
  puts red("[Error]") + " An exception ocurred of type #{e}.\n#{e.inspect}"
end

def get_domain(url)
  # we should check this is a URL. Raise exception if not.
  # return the root domain
  result= Domainatrix.parse(url)
  if (result.domain.to_s.length > 0 and result.public_suffix.to_s.length > 0)
     return result.domain + "." + result.public_suffix
  else
     return nil
  end
end

def same_domain(url1, url2)
  result1= Domainatrix.parse(url1)
  result2= Domainatrix.parse(url2)
  # if the public suffix and domain are the same and not nil
  if(result1.domain.to_s.length > 0 and
     result2.domain.to_s.length > 0 and
     result1.public_suffix.to_s.length > 0 and
     result2.public_suffix.to_s.length > 0 and
     result1.domain == result2.domain and
     result2.public_suffix == result2.public_suffix)
     return true
  else
    return false
  end
end
