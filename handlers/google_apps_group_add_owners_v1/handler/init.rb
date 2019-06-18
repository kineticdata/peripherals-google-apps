# Require the dependencies file to load the vendor libraries
require File.expand_path(File.join(File.dirname(__FILE__), 'dependencies'))

class GoogleAppsGroupAddOwnersV1
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
    # Initialize the API helper object
    puts "Creating GApps Provisioning client" if @enable_debug_logging
    api = GAppsProvisioning::ProvisioningApi.new(@info_values['admin_email'],@info_values['admin_password'])

    # Validate that all of the users exist
    users = check_users(api)

    # Add each of the validated users as an owner
    add_owners(api,users)

    # Return the results
    return "<results/>"
  end

  # Checking the usernames to see if they are valid. Throws exception if an
  # invalid username is found. Returns the list of new users.
  def check_users(api)
    puts "Checking if usernames are valid" if @enable_debug_logging
    users = @parameters['users'].split(',')
    domain = @info_values['admin_email'].split('@')[1]
    users.each do |reference|
      if reference.split("@")[-1] == domain
        reference = reference.strip
        user = api.retrieve_user(reference.chomp("@#{domain}"))
      end
    end
    puts "All users are valid" if @enable_debug_logging
    return users
  end

  # This helper method takes the list of checked usernames and then adds 
  # them as owners to the specified group
  def add_owners(api,owners)
    # Adds the usernames to the specified group and then gives them ownership access
    # as well. Throws an exception if the given group id does not exist
    owners.each do |user|
      user = user.strip
      api.add_member_to_group(user,@parameters['group_id'])
      api.add_owner_to_group(user,@parameters['group_id'])
    end
    puts "All owners have been added to the group" if @enable_debug_logging
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