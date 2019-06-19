# Require the dependencies file to load the vendor libraries
require File.expand_path(File.join(File.dirname(__FILE__), 'dependencies'))

class GoogleAppsSaSheetsRowAppendV1
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
    service_account_details = JSON.parse(@info_values["service_account_key_json"])

    # Load the Service Account Private Key
    key = OpenSSL::PKey::RSA.new(service_account_details["private_key"])

    # Initialize the Google Sheets API client
    client = Google::APIClient.new({:authorization => :oauth_2})
    client.authorization = Signet::OAuth2::Client.new(
      :token_credential_uri => 'https://accounts.google.com/o/oauth2/token',
      :audience => 'https://accounts.google.com/o/oauth2/token',
      :scope => "https://www.googleapis.com/auth/drive",
      :issuer => service_account_details["client_email"],
      :person => @info_values['impersonated_username'],
      :signing_key => key)
    client.authorization.fetch_access_token!(:connection => client.connection)

    puts "Google API Client fully configured" if @enable_debug_logging

    sheets = client.discovered_api('sheets','v4')
    method = sheets.spreadsheets.values.append
    method.method_base = sheets.discovery_document["baseUrl"]

    data = {
      "values" => [@parameters["values"].to_s.split(",")]
    }

    # Send the rename request
    puts "Appending values to the bottom of '#{@parameters["sheet_id"]}:#{@parameters["worksheet_name"]}'" if @enable_debug_logging
    result = client.execute(
      :api_method => method,
      :body => data.to_json,
      :parameters => {
        'spreadsheetId' => @parameters['sheet_id'],
        'range' => @parameters['worksheet_name'],
        'valueInputOption' => "USER_ENTERED"
      },
      :headers => {'Content-Type' => 'application/json'}
    )

    # Raise an error if the response was not successful
    if result.response.status.to_s != '200'
      puts result.response.body
      raise StandardError, JSON.parse(result.response.body)['error']['message']
    end

    # Return the results
    return "<results/>"
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