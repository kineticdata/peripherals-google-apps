# Require the dependencies file to load the vendor libraries
require File.expand_path(File.join(File.dirname(__FILE__), 'dependencies'))

class GoogleAppsCalendarCreateV2
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
  end

  def execute()
    # Initialize the Google Calendar API client
    client = Google::APIClient.new({:authorization => :oauth_2})

    client.authorization = Signet::OAuth2::Client.new(
      :token_credential_uri => 'https://accounts.google.com/o/oauth2/token',
      :client_id => @info_values['client_id'],
      :client_secret => @info_values['client_secret'],
      :refresh_token => @info_values['refresh_token']
    )
    client.authorization.fetch_access_token!

    puts "Google API Client fully configured" if @enable_debug_logging

    puts "Converting parameters to fit the Google standards"
    data = {}
    changes = {'title' => 'summary'}
    @parameters.each_pair do |k,v|
      if v!= ""
        data.merge!({if changes.has_key? k then changes[k] else k end => v})
      end
    end

    calendar = client.discovered_api('calendar','v3')

    # Send the create request
    puts "Creating the calendar" if @enable_debug_logging
    result = client.execute(
      :api_method => calendar.calendars.insert,
      :parameters => nil,
      :body => JSON.dump(data),
      :headers => {'Content-Type' => 'application/json'}
    )

    # Raise an error if the response was not successful
    if result.response.status.to_s != '200'
      puts JSON.parse(result.response.body).inspect
      raise StandardError, JSON.parse(result.response.body)['error']['message']
    end

    # Return the results
    return <<-RESULTS
    <results>
        <result name="id">#{escape(JSON.parse(result.body)['id'])}</result>
    </results>
    RESULTS
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