# Require the dependencies file to load the vendor libraries
require File.expand_path(File.join(File.dirname(__FILE__), 'dependencies'))

class GoogleAppsSaCalendarShareV1
  def initialize(input)
    # Set the input document attribute
    @input_document = REXML::Document.new(input)

    # Store the info values in a Hash of info names to values.
    @info_values = {}
    REXML::XPath.each(@input_document,"/handler/infos/info") { |item|
      @info_values[item.attributes['name']] = item.text
    }
    @enable_debug_logging = @info_values['enable_debug_logging'] == 'Yes'

    # Store parameters values in a Hash of parameter names to values.
    @parameters = {}
    REXML::XPath.match(@input_document, '/handler/parameters/parameter').each do |node|
      @parameters[node.attribute('name').value] = node.text.to_s
    end

    if @info_values['impersonated_username'].to_s == ""
      raise StandardError, "Invalid Info Value: The Info Value 'impersonated_username' cannot be left blank."
    end
  end

  def execute()
    key_location = RESOURCES_PATH + "/" + @info_values["p12_file_name"]

    if !File.exist? key_location
      key_location = @info_values["p12_file_name"]
      if !File.exist? key_location
        raise StandardError, "Invalid Info Value: The Info Value 'p12_file_name' does not point to a p12 file in the resources directory nor does it point to a p12 file in the filesystem."
      end
    end

    #We must tell ruby to read the keyfile in binary mode.
    key = nil
    File.open(key_location, 'rb') do |io|
      key = Google::APIClient::KeyUtils.load_from_pkcs12(io.read, "notasecret")
    end
    
    # Initialize the Google Calendar API client
    client = Google::APIClient.new({:authorization => :oauth_2})
    client.authorization = Signet::OAuth2::Client.new(
      :token_credential_uri => 'https://accounts.google.com/o/oauth2/token',
      :audience => 'https://accounts.google.com/o/oauth2/token',
      :scope => "https://www.googleapis.com/auth/calendar",
      :issuer => @info_values['service_account_email'],
      :person => @info_values['impersonated_username'],
      :signing_key => key)
    client.authorization.fetch_access_token!

    puts "Google API Client fully configured" if @enable_debug_logging

    calendar = client.discovered_api('calendar','v3')

    id = get_calendar_id(client, calendar)
    id.gsub!("%40","@")

    data = {'role' => @parameters['calendar_access']}
    if @parameters['scope'] == 'default'
      data.merge!({'scope' => {'type' => 'default'}})
    else
      data.merge!({'scope' => {'type' => @parameters['scope'], 'value' => @parameters['recipient']}})
    end

    if @enable_debug_logging && data["scope"].has_key?("value")
      puts "Sharing the calendar with the scope of #{@parameters['scope']} and a recipient of #{@parameters['recipient']}."
    elsif @enable_debug_logging
      puts "Making the calendar public"
    end
    result = client.execute(:api_method => calendar.acl.insert,
      :parameters => {'calendarId' => id},
      :body => JSON.dump(data),
      :headers => {'Content-Type' => 'application/json'})

    puts "Google Response:" if @enable_debug_logging
    puts result.body if @enable_debug_logging

    if result.response.status.to_s != '200'
        raise StandardError, JSON.parse(result.response.body)['error']['message']
    end
    return "<results/>"
  end

  def get_calendar_id(client, calendar)
    puts "Retrieving the calendar id using calendar name" if @enable_debug_logging
    result = client.execute(
      :api_method => calendar.calendar_list.list,
      :parameters => {},
      :body => nil,
      :headers => {'Content-Type' => 'application/json'}
    )

    puts "Retrieving the list of calendars" if @enable_debug_logging
    calendar_list = JSON.parse(result.body)['items']

    puts "Parsing through retrieved calendars to get appropriate calendar id" if @enable_debug_logging
    for item in calendar_list
      if item["summary"] == @parameters["calendar_name"]
        puts "Calendar id has been found: #{item["id"]}" if @enable_debug_logging
        return item["id"]
      end
    end
    raise StandardError, "Invalid Calendar Name: Account does not contain the calendar '#{@parameters['calendar_name']}'."
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