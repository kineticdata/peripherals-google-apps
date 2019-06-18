# Require the dependencies file to load the vendor libraries
require File.expand_path(File.join(File.dirname(__FILE__), 'dependencies'))

class GoogleAppsCalendarEventCreateV2
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

    # Checking to see if the start and end times are one of the two valid date
    # formats
    for time in ['start','end']
      if (
        !@parameters[time].match(/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(Z$|$)/) &&
        !@parameters[time].match(/^\d{4}-\d{2}-\d{2}$/)
      )
        raise StandardError, "Invalid #{time} time: '#{@parameters[time]}' is not a valid time entry."
      end
    end

    # Checking to see if both the start and the end are of the same format
    if @parameters['start'].match(/^\d{4}-\d{2}-\d{2}$/) && !@parameters['end'].match(/^\d{4}-\d{2}-\d{2}$/)
      raise StandardError,"Invalid time formats: Start and End times do not use the same date format"
    elsif !@parameters['start'].match(/^\d{4}-\d{2}-\d{2}$/) && @parameters['end'].match(/^\d{4}-\d{2}-\d{2}$/)
      raise StandardError,"Invalid time formats: Start and End times do not use the same date format"
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

    calendar = client.discovered_api('calendar','v3')

    id = @parameters['calendar_id']

    # Retrieve the time zone
    puts "Retrieving the time zone of the current calendar" if @enable_debug_logging
    getCal = client.execute(:api_method => calendar.calendars.get,
      :parameters => {'calendarId' => id})
    timeZone = JSON.parse(getCal.response.body)['timeZone']

    # Create the event object
    event = configure_event(timeZone)

    # Send the create request
    puts "Creating the new event" if @enable_debug_logging
    result = client.execute(
      :api_method => calendar.events.insert,
      :parameters => {
        'calendarId' => id, 
        'sendNotifications' => (@parameters['send_notifications'] == "Yes").to_s.capitalize
      },
      :body => JSON.dump(event),
      :headers => {'Content-Type' => 'application/json'}
    )

    # Raise an error if the response was not successful
    if result.response.status.to_s != '200'
      puts JSON.parse(result.response.body).inspect
      if result.response.status.to_s == '404'
        raise StandardError, "Calendar Not Found -- Calendar '#{@parameters['calendar_id']}' does not exist or you don't have the proper permissions to modify it.\nMake sure to give the username '#{@info_values['service_account_email']}' permission to modify this calendar on your google account."
      end
      raise StandardError, JSON.parse(result.response.body)['error']['message']
    end

    # Return the results
    return <<-RESULTS
    <results>
        <result name="id">#{JSON.parse(result.body)['id']}</result>
    </results>
    RESULTS
  end

  #Takes the parameters that were fed into the program and converts them 
  #into the format that will be used for the actual API call
  def configure_event(timeZone)
    puts "Converting parameters to fit the Google standards" if @enable_debug_logging
    # Setting up the time and date information first
    if @parameters['is_all_day'].downcase == "true"
      start_date = @parameters['start'].split("T")[0]
      end_date = @parameters['end'].split("T")[0]
      data = {'start' => {'date' => start_date}, 'end' => {'date' => end_date}}
    elsif @parameters['start'].match(/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(Z$|$)/)
      data = {'start' => {'dateTime' => @parameters['start'], 'timeZone' => timeZone}, 'end' => {'dateTime' => @parameters['end'], 'timeZone' => timeZone}}
    else
      data = {'start' => {'date' => @parameters['start']}, 'end' => {'date' => @parameters['end']}}
    end

    # Then splitting and adding the attendees
    attendees = []
    @parameters['attendees'].split(',').each do |email|
      attendees.push({"email" => email.strip})
    end
    if attendees.length > 0
      data.merge!({'attendees' => attendees})
    end

    # A hash of values that changes from the parameter names to the names that
    # are required by the google call.
    changes = {'title' => 'summary'}

    @parameters.each_pair do |k,v|
      if !['start','end','attendees'].include?(k)
        if v!= ""
          data.merge!({if changes.has_key? k then changes[k] else k end => v})
        end
      end
    end
    
    return data
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