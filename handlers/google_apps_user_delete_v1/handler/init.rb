# Require the dependencies file to load the vendor libraries
require File.expand_path(File.join(File.dirname(__FILE__), 'dependencies'))

class GoogleAppsUserDeleteV1
  def initialize(input)
    # Set the input document attribute
    @input_document = REXML::Document.new(input)

    debugValue = REXML::XPath.first(@input_document, "/handler/infos/info[@name='enable_debug_logging']")
    if debugValue.text != "Yes"
      @enable_debug_logging = nil 
    else 
      @enable_debug_logging = true 
    end

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
  end

  def execute()
    admin = @info_values['admin_email']
    password = @info_values['admin_password']

    puts "Creating GApps Provisioning client" if @enable_debug_logging
    api = GAppsProvisioning::ProvisioningApi.new(admin,password)

    user = @parameters['username'].split("@")

    puts "Deleting specified user" if @enable_debug_logging
    begin
      api.delete_user(user[0])
    rescue Exception => ex
      if ex.code == "1301"
        raise StandardError, "Invalid Request: The username #{user[0]} does not exist"
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