# Require the dependencies file to load the vendor libraries
require File.expand_path(File.join(File.dirname(__FILE__), 'dependencies'))

class GoogleAppsGroupCreateV1
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
    api = GAppsProvisioning::ProvisioningApi.new(@info_values['admin_email'], @info_values['admin_password'])

    # Checking to see if the group permission input will be recognizable
    # for google api
    puts "Checking to see if group permission input will be recognizable for api" if @enable_debug_logging
    if !["owner","member","domain","anyone"].include?(@parameters['group_permission'].downcase)
      raise StandardError, "The value for Group Permission is not valid"
    end

    # Creates the group, and throws an exception if a group with the same
    # id already exists
    puts "Creating the new group" if @enable_debug_logging
    properties = [
      @parameters['group_name'],
      @parameters['group_description'],
      @parameters['group_permission']
    ]
    api.create_group(@parameters['group_id'],properties)
    
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