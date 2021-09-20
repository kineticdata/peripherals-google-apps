# Require the dependencies file to load the vendor libraries
require File.expand_path(File.join(File.dirname(__FILE__), "dependencies"))

class GoogleAppsApiV1
  # ==== Parameters
  # * +input+ - The String of Xml that was built by evaluating the node.xml handler template.
  def initialize(input)
    # Set the input document attribute
    @input_document = REXML::Document.new(input)

    # Retrieve all of the handler info values and store them in a hash variable named @info_values.
    @info_values = {}
    REXML::XPath.each(@input_document, "/handler/infos/info") do |item|
      @info_values[item.attributes["name"]] = item.text.to_s.strip
    end

    # Retrieve all of the handler parameters and store them in a hash variable named @parameters.
    @parameters = {}
    REXML::XPath.each(@input_document, "/handler/parameters/parameter") do |item|
      @parameters[item.attributes["name"]] = item.text.to_s.strip
    end

    @debug_logging_enabled = ["yes","true"].include?(@info_values['enable_debug_logging'].downcase)
    @error_handling = @parameters["error_handling"]

    @service_account = @info_values["service_account"]
    @private_key = formatPrivateKey(@info_values["private_key"])

    @body = @parameters["body"].nil? ? "" : @parameters["body"]
    @method = (@parameters["method"] || :get).downcase.to_sym
    @scope = @parameters["scope"]
    @user = @parameters["user"]
    @url = @parameters["url"]

    @accept = :json
    @content_type = :json
  end

  def execute
    # Initialize return data
    error_message = nil
    error_key = nil
    response_code = nil

    begin
      api_route = "#{@url}"
      puts "API ROUTE: #{@method.to_s.upcase} #{api_route}" if @debug_logging_enabled
      puts "BODY: \n #{@body}" if @debug_logging_enabled

      # get assertion needed for token request
      assertion = getAssertion()

      # Make token request
      tokenResponse = RestClient::Request.execute \
        method: :post, \
        url: "https://oauth2.googleapis.com/token", \
        payload: {
          grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
          assertion: assertion
        }, \
        headers: {:content_type => "application/x-www-form-urlencoded", :accept => @accept}

      token = JSON.parse(tokenResponse)["access_token"]
      puts "Token successfully retrieved" if token

      # Make requrest for assets
      response = RestClient::Request.execute \
        method: @method, \
        url: api_route, \
        payload: @body, \
        headers: {
          :content_type => @content_type, 
          :accept => @accept,
          :Authorization => "Bearer #{token}"
        }
      response_code = response.code
    rescue RestClient::Exception => e
      error = nil
      response_code = e.response.code
      error_message = e.inspect

      # Raise the error if instructed to, otherwise will fall through to
      # return an error message.
      raise if @error_handling == "Raise Error"
    end

    # Return (and escape) the results that were defined in the node.xml
    <<-RESULTS
    <results>
      <result name="Response Body">#{escape(response.nil? ? {} : response.body)}</result>
      <result name="Response Code">#{escape(response_code)}</result>
      <result name="Handler Error Message">#{escape(error_message)}</result>
    </results>
    RESULTS
  end

  ##############################################################################
  # General handler utility functions
  ##############################################################################

  def getAssertion()
    rsa_private = OpenSSL::PKey::RSA.new @private_key
    rsa_public = rsa_private.public_key

    # Create experation for token
    now = Time.now.to_i
    plusHour = now + 3600

    # Assumes service account and impersonated user will be used for requests
    payload = {
        "iss": @service_account,
        "sub": @user,
        "scope": @scope,
        "aud": "https://oauth2.googleapis.com/token",
        "exp": plusHour,
        "iat": now
      }

    return JWT.encode payload, rsa_private, 'RS256', header_fields={"typ":"JWT"}
  end

  def formatPrivateKey(private_key)
    private_key_arr = Array.new()

    # Task encodes carriage returns that cause issues in the getAssertion functons.  Remove \\n and rebuild private key.
    # Remove \n so the test harness will build PK correctly.
    private_key = private_key.gsub('\\n','').gsub("\n","")

    # Store header and footer
    private_key_arr[0] = private_key.slice!("-----BEGIN PRIVATE KEY-----")
    footer = private_key.slice!("-----END PRIVATE KEY-----")
    
    idx = 1;
    # Split PK into chuncks of 64 characters
    while private_key.length > 64 do
      x = private_key.slice!(0..63)  
      private_key_arr[idx] = x
      idx = idx + 1
    end
    # Add left over characters
    private_key_arr[idx] = private_key

    # Add the footer with a carriage return
    private_key_arr[idx + 1] = "#{footer}\n"

    # Rebuild private key
    private_key = private_key_arr.join("\n")

    puts "Private key reformat successful"
    return private_key
  end

  # This is a template method that is used to escape results values (returned in
  # execute) that would cause the XML to be invalid.  This method is not
  # necessary if values do not contain character that have special meaning in
  # XML (&, ", <, and >), however it is a good practice to use it for all return
  # variable results in case the value could include one of those characters in
  # the future.  This method can be copied and reused between handlers.
  def escape(string)
    # Globally replace characters based on the ESCAPE_CHARACTERS constant
    string.to_s.gsub(/[&"><]/) { |special| ESCAPE_CHARACTERS[special] } if string
  end
  # This is a ruby constant that is used by the escape method
  ESCAPE_CHARACTERS = {'&'=>'&amp;', '>'=>'&gt;', '<'=>'&lt;', '"' => '&quot;'}
end
