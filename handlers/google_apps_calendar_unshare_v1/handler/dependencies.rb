require 'rexml/document'
require 'time'
require 'date'


# If the Kinetic Task version is under 4, load the openssl and json libraries
# because they are not included in the ruby version
# if KineticTask::VERSION.split('.').first.to_i < 4
    # Load the JRuby Open SSL library unless it has already been loaded.  This
    # prevents multiple handlers using the same library from causing problems.
    if not defined?(Jopenssl)
      # Load the Bouncy Castle library unless it has already been loaded.  This
      # prevents multiple handlers using the same library from causing problems.
      # Calculate the location of this file
      handler_path = File.expand_path(File.dirname(__FILE__))
      # Calculate the location of our library and add it to the Ruby load path
      library_path = File.join(handler_path, 'vendor/bouncy-castle-java-1.5.0147/lib')
      $:.unshift library_path
      # Require the library
      require 'bouncy-castle-java'
      
      
      # Calculate the location of this file
      handler_path = File.expand_path(File.dirname(__FILE__))
      # Calculate the location of our library and add it to the Ruby load path
      library_path = File.join(handler_path, 'vendor/jruby-openssl-0.8.8/lib/shared')
      $:.unshift library_path
      # Require the library
      require 'openssl'
      # Require the version constant
      require 'jopenssl/version'
    end

    # Validate the the loaded openssl library is the library that is expected for
    # this handler to execute properly.
    if not defined?(Jopenssl::Version::VERSION)
      raise "The Jopenssl class does not define the expected VERSION constant."
    elsif Jopenssl::Version::VERSION != '0.8.8'
      raise "Incompatible library version #{Jopenssl::Version::VERSION} for Jopenssl.  Expecting version 0.8.8"
    end




    # Load the ruby JSON library unless it has already been loaded.  This prevents
    # multiple handlers using the same library from causing problems.
    if not defined?(JSON)
      # Calculate the location of this file
      handler_path = File.expand_path(File.dirname(__FILE__))
      # Calculate the location of our library and add it to the Ruby load path
      library_path = File.join(handler_path, 'vendor/json-1.8.0/lib')
      $:.unshift library_path
      # Require the library
      require 'json'
    end

    # Validate the the loaded JSON library is the library that is expected for
    # this handler to execute properly.
    if not defined?(JSON::VERSION)
      raise "The JSON class does not define the expected VERSION constant."
    elsif JSON::VERSION != '1.8.0'
      raise "Incompatible library version #{JSON::VERSION} for JSON.  Expecting version 1.8.0."
    end
# end



# Load the ruby MultiJSON library (used by the Google library) unless it has 
# already been loaded.  This prevents multiple handlers using the same library 
# from causing problems.
if not defined?(MultiJson)
  # Calculate the location of this file
  handler_path = File.expand_path(File.dirname(__FILE__))
  # Calculate the location of our library and add it to the Ruby load path
  library_path = File.join(handler_path, 'vendor/multi_json-1.7.5/lib')
  $:.unshift library_path
  # Require the library
  require 'multi_json'
  require 'multi_json/version'
  require 'multi_json/adapters/json_gem'

  # Specify what engine to use
  MultiJson.engine = :json_gem
end

# Validate the the loaded MultiJSON library is the library that is expected for
# this handler to execute properly.
if not defined?(MultiJson::Version)
  raise "The MultiJson class does not define the expected VERSION constant."
elsif MultiJson::Version.to_s != '1.7.5'
  raise "Incompatible library version #{MultiJson::Version} for MultiJson.  Expecting version 1.7.5."
end





# Load the ruby Rack library unless it has already been loaded.  This prevents
# multiple handlers using the same library from causing problems.
if not defined?(Rack)
  # Calculate the location of this file
  handler_path = File.expand_path(File.dirname(__FILE__))
  # Calculate the location of our library and add it to the Ruby load path
  library_path = File.join(handler_path, 'vendor/rack-1.4.1/lib')
  $:.unshift library_path
  # Require the library
  require 'rack'
end

# Validate the the loaded Rack library is the library that is expected for
# this handler to execute properly.
if not defined?(Rack.release)
  raise "The Rack class does not define the expected VERSION constant."
elsif Rack.release != '1.4'
  raise "Incompatible library version #{Rack.release} for Rack.  Expecting version 1.4."
end





# Load the ruby Addressable library unless it has already been loaded.  This prevents
# multiple handlers using the same library from causing problems.
if not defined?(Addressable)
  # Calculate the location of this file
  handler_path = File.expand_path(File.dirname(__FILE__))
  # Calculate the location of our library and add it to the Ruby load path
  library_path = File.join(handler_path, 'vendor/addressable-2.3.4/lib')
  $:.unshift library_path
  # Require the library
  require 'addressable/template'

end

# Validate the the loaded Addressable library is the library that is expected for
# this handler to execute properly.
if not defined?(Addressable::VERSION::STRING)
  raise "The Addressable class does not define the expected VERSION constant."
elsif Addressable::VERSION::STRING != '2.3.4'
  raise "Incompatible library version #{Addressable::VERSION::STRING} for Addressable.  Expecting version 2.3.4."
end



# Load the ruby Extlib library unless it has already been loaded.  This prevents
# multiple handlers using the same library from causing problems.
if not defined?(Extlib)
  # Calculate the location of this file
  handler_path = File.expand_path(File.dirname(__FILE__))
  # Calculate the location of our library and add it to the Ruby load path
  library_path = File.join(handler_path, 'vendor/extlib-0.9.15/lib')
  $:.unshift library_path
  # Require the library
  require 'extlib'
end

# Validate the the loaded Extlib library is the library that is expected for
# this handler to execute properly.
if not defined?(Extlib::VERSION)
  raise "The Extlib class does not define the expected VERSION constant."
elsif Extlib::VERSION != '0.9.15'
  raise "Incompatible library version #{Extlib::VERSION} for Extlib.  Expecting version 0.9.15."
end




# Load the ruby Multipart Post library unless it has already been loaded.  This prevents
# multiple handlers using the same library from causing problems.
if not defined?(MultipartPost)
  # Calculate the location of this file
  handler_path = File.expand_path(File.dirname(__FILE__))
  # Calculate the location of our library and add it to the Ruby load path
  library_path = File.join(handler_path, 'vendor/multipart-post-1.2.0/lib')
  $:.unshift library_path
  # Require the library
  require 'multipart_post'
  require 'multipartable'
end

# Validate the the loaded Multipart Post library is the library that is expected for
# this handler to execute properly.
if not defined?(MultipartPost::VERSION)
  raise "The MultipartPost class does not define the expected VERSION constant."
elsif MultipartPost::VERSION != '1.2.0'
  raise "Incompatible library version #{MultipartPost::VERSION} for Multipart Post.  Expecting version 1.2.0."
end




# Load the ruby Faraday library (used by the Twitter library) unless it has 
#already been loaded.  This prevents multiple handlers using the same library 
#from causing problems.
if not defined?(Faraday)
  # Calculate the location of this file
  handler_path = File.expand_path(File.dirname(__FILE__))
  # Calculate the location of our library and add it to the Ruby load path
  library_path = File.join(handler_path, 'vendor/faraday-0.9.0/lib')
  $:.unshift library_path
  # Require the library
  require 'faraday'
end

# Validate the the loaded Faraday library is the library that is expected for
# this handler to execute properly.
if not defined?(Faraday::VERSION)
  raise "The Faraday class does not define the expected VERSION constant."
elsif Faraday::VERSION != '0.9.0'
  raise "Incompatible library version #{Faraday::VERSION} for Faraday.  Expecting version 0.9.0."
end





# Load the ruby Launchy library unless it has already been loaded.  This prevents
# multiple handlers using the same library from causing problems.
if not defined?(Launchy)
  # Calculate the location of this file
  handler_path = File.expand_path(File.dirname(__FILE__))
  # Calculate the location of our library and add it to the Ruby load path
  library_path = File.join(handler_path, 'vendor/launchy-2.4.2-java/lib')
  $:.unshift library_path
  # Require the library
  require 'launchy'
end

# Validate the the loaded Launchy library is the library that is expected for
# this handler to execute properly.
if not defined?(Launchy::VERSION)
  raise "The Launchy class does not define the expected VERSION constant."
elsif Launchy::VERSION != '2.4.2'
  raise "Incompatible library version #{Launchy::VERSION} for Launchy.  Expecting version 2.4.2."
end




# Load the ruby Retriable library (used by the Google library) unless it has 
# already been loaded.  This prevents multiple handlers using the same library 
# from causing problems.
if not defined?(Retriable)
  # Calculate the location of this file
  handler_path = File.expand_path(File.dirname(__FILE__))
  # Calculate the location of our library and add it to the Ruby load path
  library_path = File.join(handler_path, 'vendor/retriable-1.4.1/lib')
  $:.unshift library_path
  # Require the library
  require 'retriable'
  require 'retriable/version'
end

# Validate the the loaded Retriable library is the library that is expected for
# this handler to execute properly.
if not defined?(Retriable::VERSION)
  raise "The Retriable class does not define the expected VERSION constant."
elsif Retriable::VERSION != '1.4.1'
  raise "Incompatible library version #{Retriable::VERSION} for Retriable.  Expecting version 1.4.1."
end





# Load the ruby JWT library unless it has already been loaded.  This prevents
# multiple handlers using the same library from causing problems.
if not defined?(JWT)
  # Calculate the location of this file
  handler_path = File.expand_path(File.dirname(__FILE__))
  # Calculate the location of our library and add it to the Ruby load path
  library_path = File.join(handler_path, 'vendor/jwt-0.1.5/lib')
  $:.unshift library_path
  # Require the library
  require 'jwt' 
end

# Validate the the loaded JWT library is the library that is expected for
# this handler to execute properly.
if not defined?(JWT::VERSION)
  raise "The JWT class does not define the expected VERSION constant."
elsif JWT::VERSION != '0.1.5'
  raise "Incompatible library version #{JWT::VERSION} for JWT.  Expecting version 0.1.5."
end




# Load the ruby UUID Tools library unless it has already been loaded.  This 
# prevents multiple handlers using the same library from causing problems.
if not defined?(UUIDTools)
  # Calculate the location of this file
  handler_path = File.expand_path(File.dirname(__FILE__))
  # Calculate the location of our library and add it to the Ruby load path
  library_path = File.join(handler_path, 'vendor/uuidtools-2.1.4/lib')
  $:.unshift library_path
  # Require the library
  require 'uuidtools' 
end

# Validate the the loaded UUID Tools library is the library that is expected for
# this handler to execute properly.
if not defined?(UUIDTools::VERSION)
  raise "The UUIDTools class does not define the expected VERSION constant."
elsif UUIDTools::VERSION::STRING != '2.1.4'
  raise "Incompatible library version #{UUIDTools::VERSION::STRING} for UUIDTools.  Expecting version 2.1.4."
end




# Load the ruby Signet library (used by the Twitter library) unless it has 
#already been loaded.  This prevents multiple handlers using the same library 
#from causing problems.
if not defined?(Signet)
  # Calculate the location of this file
  handler_path = File.expand_path(File.dirname(__FILE__))
  # Calculate the location of our library and add it to the Ruby load path
  library_path = File.join(handler_path, 'vendor/signet-0.5.0/lib')
  $:.unshift library_path
  # Require the library
  require 'signet'
  require 'signet/oauth_2/client'
  require 'signet/oauth_2'
end

# Validate the the loaded Signet library is the library that is expected for
# this handler to execute properly.
if not defined?(Signet::VERSION)
  raise "The Signet class does not define the expected VERSION constant."
elsif Signet::VERSION::STRING != '0.5.0'
  raise "Incompatible library version #{Signet::VERSION::STRING} for Signet.  Expecting version 0.5.0."
end




# Load the ruby AutoParse library (used by the Twitter library) unless it has 
#already been loaded.  This prevents multiple handlers using the same library 
#from causing problems.
if not defined?(AutoParse)
  # Calculate the location of this file
  handler_path = File.expand_path(File.dirname(__FILE__))
  # Calculate the location of our library and add it to the Ruby load path
  library_path = File.join(handler_path, 'vendor/autoparse-0.3.3/lib')
  $:.unshift library_path
  # Require the library
  require 'autoparse'
  require 'autoparse/version'
end

# Validate the the loaded AutoParse library is the library that is expected for
# this handler to execute properly.
if not defined?(AutoParse::VERSION)
  raise "The AutoParse class does not define the expected VERSION constant."
elsif AutoParse::VERSION::STRING != '0.3.3'
  raise "Incompatible library version #{AutoParse::VERSION::STRING} for AutoParse.  Expecting version 0.3.3."
end




# Load the ruby Google API Client library (used by the Twitter library) unless it has 
#already been loaded.  This prevents multiple handlers using the same library 
#from causing problems.
if not defined?(Google)
  # Calculate the location of this file
  handler_path = File.expand_path(File.dirname(__FILE__))
  # Calculate the location of our library and add it to the Ruby load path
  library_path = File.join(handler_path, 'vendor/google-api-client-0.7.1/lib')
  $:.unshift library_path
  # Require the library
  require 'google/api_client'
  require 'google/api_client/version'
end

# Validate the the loaded Google API Client library is the library that is expected for
# this handler to execute properly.
if not defined?(Google::APIClient::VERSION)
  raise "The Google class does not define the expected VERSION constant."
elsif Google::APIClient::VERSION::STRING != '0.7.1'
  raise "Incompatible library version #{Google::APIClient::VERSION::STRING} for Google.  Expecting version 0.7.1."
end


