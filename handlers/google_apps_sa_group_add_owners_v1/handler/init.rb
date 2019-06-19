# Require the dependencies file to load the vendor libraries
require File.expand_path(File.join(File.dirname(__FILE__), 'dependencies'))

class GoogleAppsSaGroupAddOwnersV1
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
      :scope => "https://www.googleapis.com/auth/admin.directory.user https://www.googleapis.com/auth/admin.directory.group",
      :issuer => @info_values['service_account_email'],
      :person => @info_values['impersonated_username'],
      :signing_key => key)
    client.authorization.fetch_access_token!

    directory = client.discovered_api('admin','directory_v1')

    new_owners = @parameters["users"].split(",")

    puts "Looping through the inputted user(s)" if @enable_debug_logging
    for user in new_owners
      params = {:groupKey => @parameters["group_id"]}
      body = {"email" => user, "role" => "OWNER"}

      result = client.execute(
        :api_method => directory.members.insert,
        :parameters => params,
        :body => body.to_json,
        :headers => {'Content-Type' => 'application/json'}
      )

      # Raise an error if the response was not successful
      if result.response.status.to_s.slice(0,1) != '2'
        puts JSON.parse(result.response.body).inspect
        raise StandardError, JSON.parse(result.response.body)['error']['message']
      end
      puts "Successfully added '#{user}' as a group owner" if @enable_debug_logging
    end


    # Retrieving a list of the current owners to see if all the users were added
    # correctly
    puts "Retrieving a list of the current project users" if @enable_debug_logging
    params = {:groupKey => @parameters["group_id"]}

    result = client.execute(
      :api_method => directory.members.list,
      :parameters => params,
      :headers => {'Content-Type' => 'application/json'}
    )

    json = JSON.parse(result.response.body)
    for member in json["members"]
      new_owners.delete(member["email"])
    end

    if !new_owners.empty?
      raise StandardError, "The following users were not able to be added to the group: #{new_owners.join(', ')}"
    end

    # # Send the create request
    # puts "Adding '#{email}' as a group owner" if @enable_debug_logging
    # params = {:groupKey => "041mghml4b9ytal"}
    # body = {"email" => email, "role" => "OWNER"}

    # result = client.execute(
    #   :api_method => directory.members.insert,
    #   :parameters => params,
    #   :body => body.to_json,
    #   :headers => {'Content-Type' => 'application/json'}
    # )





    # # Send the delete request
    # puts "Deleting the user from the group" if @enable_debug_logging
    # params = {:groupKey => "041mghml4b9ytal", :memberKey => "testing55318@gmail.com"}

    # result = client.execute(
    #   :api_method => directory.members.delete,
    #   :parameters => params,
    #   :headers => {'Content-Type' => 'application/json'}
    # )

    # # Raise an error if the response was not successful
    # if result.response.status.to_s.slice(0,1) != '2'
    #   puts JSON.parse(result.response.body).inspect
    #   raise StandardError, JSON.parse(result.response.body)['error']['message']
    # end

    # puts result.response.body

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