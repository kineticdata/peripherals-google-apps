# Require the dependencies file to load the vendor libraries
require File.expand_path(File.join(File.dirname(__FILE__), 'dependencies'))

class GoogleAppsUserCreateV2
  def initialize(input)
    # Set the input document attribute
    @input_document = REXML::Document.new(input)

    # Store the info values in a Hash of info names to values.
    @info_values = {}
    REXML::XPath.each(@input_document,"/handler/infos/info") { |item|
      @info_values[item.attributes['name']] = item.text
    }

    # Store parameters values in a Hash of parameter names to values.
    @parameters = {}
    REXML::XPath.match(@input_document, '/handler/parameters/parameter').each do |node|
      @parameters[node.attribute('name').value] = node.text.to_s
    end

    @enable_debug_logging = @info_values['enable_debug_logging'] == 'Yes'
  end

  def execute()
    admin = @info_values['admin_email']
    password = @info_values['admin_password']

    puts "Creating GApps Provisioning client" if @enable_debug_logging
    api = GAppsProvisioning::ProvisioningApi.new(admin,password)

    domain = @info_values['admin_email'].split("@")[1]

    puts "Checking to see if password is at least 8 characters long" if @enable_debug_logging
    if @parameters['password'].length < 8
      raise StandardError, "Invalid Password: Password must be 8 characters or longer"
    end

    puts "Creating new user" if @enable_debug_logging
    begin
      api.create_user(@parameters['username'],@parameters['first_name'],@parameters['last_name'],@parameters['password'])
    rescue Exception => ex
      if ex.reason == "EntityNameNotValid"
        raise StandardError, "Invalid Username: #{@parameters['username']} is not a valid username"
      elsif ex.reason == "EntityExists"
        raise StandardError, "Invalid Username: #{@parameters['username']} is already a username"
      else
        raise
      end
    end

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