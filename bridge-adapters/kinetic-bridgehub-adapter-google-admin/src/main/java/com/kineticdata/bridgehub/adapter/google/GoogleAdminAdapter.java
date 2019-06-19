package com.kineticdata.bridgehub.adapter.google;

import com.kineticdata.bridgehub.adapter.BridgeAdapter;
import com.kineticdata.bridgehub.adapter.BridgeError;
import com.kineticdata.bridgehub.adapter.BridgeRequest;
import com.kineticdata.bridgehub.adapter.Count;
import com.kineticdata.bridgehub.adapter.Record;
import com.kineticdata.bridgehub.adapter.RecordList;
import com.kineticdata.commons.v1.config.ConfigurableProperty;
import com.kineticdata.commons.v1.config.ConfigurablePropertyMap;
import java.io.IOException;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

import com.google.api.client.googleapis.auth.oauth2.GoogleCredential;
import com.google.api.client.googleapis.javanet.GoogleNetHttpTransport;
import com.google.api.client.http.HttpTransport;
import com.google.api.client.json.jackson2.JacksonFactory;
import com.google.api.client.json.JsonFactory;
import com.google.api.services.admin.directory.DirectoryScopes;
import com.google.api.services.admin.directory.model.*;
import com.google.api.services.admin.directory.Directory;
import com.kineticdata.bridgehub.adapter.BridgeUtils;
import java.security.GeneralSecurityException;
import java.util.HashMap;
import org.apache.commons.lang.StringUtils;
import org.slf4j.LoggerFactory;

/**
 *
 */
public class GoogleAdminAdapter implements BridgeAdapter {
    /*----------------------------------------------------------------------------------------------
     * PROPERTIES
     *--------------------------------------------------------------------------------------------*/
    
    /** Defines the adapter display name. */
    public static final String NAME = "Google Admin Bridge";
    
    /** Defines the logger */
    protected static final org.slf4j.Logger logger = LoggerFactory.getLogger(GoogleAdminAdapter.class);

    /** Adapter version constant. */
    public static String VERSION;
    /** Load the properties version from the version.properties file. */
    static {
        try {
            java.util.Properties properties = new java.util.Properties();
            properties.load(GoogleAdminAdapter.class.getResourceAsStream("/"+GoogleAdminAdapter.class.getName()+".version"));
            VERSION = properties.getProperty("version");
        } catch (IOException e) {
            logger.warn("Unable to load "+GoogleAdminAdapter.class.getName()+" version properties.", e);
            VERSION = "Unknown";
        }
    }
    
    /** Defines the collection of property names for the adapter. */
    public static class Properties {
        public static final String EMAIL = "Service Account Email";
        public static final String P12_FILE = "P12 File Location";
        public static final String USER_IMPERSONATION = "Impersonated User Email";
        public static final String DOMAIN = "Domain";
    }

    private String email;
    private String p12File;
    private String userImpersonation;
    private String domain;
    private Directory directory;

    private final ConfigurablePropertyMap properties = new ConfigurablePropertyMap(
            new ConfigurableProperty(Properties.EMAIL).setIsRequired(true),
            new ConfigurableProperty(Properties.P12_FILE).setIsRequired(true),
            new ConfigurableProperty(Properties.USER_IMPERSONATION).setIsRequired(true),
            new ConfigurableProperty(Properties.DOMAIN).setIsRequired(false).setDescription("Optionally set the domain where "
                    + "the bridge will query. The domain can also be set in each individual bridge query if it isn't set here.")
    );
    
    /**
     * Structures that are valid to use in the bridge
     */
    public static final List<String> VALID_STRUCTURES = Arrays.asList(new String[] {
        "Users"
    });
    
    /*---------------------------------------------------------------------------------------------
     * SETUP METHODS
     *-------------------------------------------------------------------------------------------*/
    @Override
    public String getName() {
        return NAME;
    }
    
    @Override
    public String getVersion() {
       return VERSION;
    }
    
    @Override
    public ConfigurablePropertyMap getProperties() {
        return properties;
    }
    
    @Override
    public void setProperties(Map<String,String> parameters) {
        properties.setValues(parameters);
    }
    
    @Override
    public void initialize() throws BridgeError {
        this.email = properties.getValue(Properties.EMAIL);
        this.p12File = properties.getValue(Properties.P12_FILE);
        this.userImpersonation = properties.getValue(Properties.USER_IMPERSONATION);
        this.domain = properties.getValue(Properties.DOMAIN);
        this.directory = setBridge();
    }
    
      /*---------------------------------------------------------------------------------------------
     * CONSTRUCTOR
     *-------------------------------------------------------------------------------------------*/
    
    /**
     * Initialize a new unique GoogleDriveBridge. The constructor takes a map of
     * configuration name/value pairs.
     *
     * @param configuration
     * @throws BridgeError If it was not possible to register the adapter class.
     * added void to fix error-C
     */
    public Directory setBridge() throws BridgeError {
        
        JsonFactory JSON_FACTORY = JacksonFactory.getDefaultInstance();
        HttpTransport httpTransport;
        GoogleCredential credential;
        try {
            httpTransport = GoogleNetHttpTransport.newTrustedTransport();
            List<String> scopes = new ArrayList<String>();
            scopes.add(DirectoryScopes.ADMIN_DIRECTORY_USER);
            credential = new GoogleCredential.Builder()
                .setTransport(httpTransport)
                .setJsonFactory(JSON_FACTORY)
                .setServiceAccountId(email)
                .setServiceAccountPrivateKeyFromP12File(new java.io.File(p12File))
                .setServiceAccountScopes(scopes)
                .setServiceAccountUser(userImpersonation)
                .build();
            
        } catch (GeneralSecurityException gse) {
            throw new BridgeError(gse);
        } catch (IOException ioe) {
            throw new BridgeError(ioe);
        }
        
        Directory directory = new Directory.Builder(httpTransport, JSON_FACTORY, credential).build();
        return directory;
    }
    
    /*---------------------------------------------------------------------------------------------
     * IMPLEMENTATION METHODS
     *-------------------------------------------------------------------------------------------*/
    
    @Override
    public Count count(BridgeRequest request) throws BridgeError {
        // Validate the Structure
        if (!VALID_STRUCTURES.contains(request.getStructure())) {
            throw new BridgeError("Invalid Structure: '" + request.getStructure() + "' is not a valid structure");
        }
        
        // If the metadata is null, set it to an empty map so the while loop can
        // easily add the next page token to the metadata as needed
        if (request.getMetadata() == null) request.setMetadata(new HashMap<String,String>());

        // Get the count of the users by looping over and counting all the returned
        // pages
        Users users = requestUsers(request);
        int count = users.getUsers() != null ? users.getUsers().size() : 0;
        while (users.getUsers() != null && users.getNextPageToken() != null) {
            request.getMetadata().put("pageToken",users.getNextPageToken());
            users = requestUsers(request);
            count += users.getUsers().size();
        }
            
        //Return the response
        return new Count(count);
    }
    
    @Override
    public Record retrieve(BridgeRequest request) throws BridgeError {
        // Validate the Structure
        if (!VALID_STRUCTURES.contains(request.getStructure())) {
            throw new BridgeError("Invalid Structure: '" + request.getStructure() + "' is not a valid structure");
        }

        // Load fields into a variable and initiate it as an empty list if it is null
        List<String> fields = request.getFields();
        if (fields == null) fields = new ArrayList<String>();
        
        // Add a limit of 2 to the request because only 2 records are needed before
        // an error will be thrown for multiple results returned.
        if (request.getMetadata() == null) request.setMetadata(new HashMap<String,String>());
        request.getMetadata().put("pageSize","2");

        Users users = requestUsers(request);
        User user = null;
        if (users.getUsers() != null) {
            if (users.getUsers().size() > 1) {
                throw new BridgeError("Multiple results matched an expected single match query");
            } else if (users.getUsers().size() == 1) {
                user = users.getUsers().get(0);
            }
        }
        
        // Create the new record
        Record record = new Record(user);
        if (!fields.isEmpty()) record = BridgeUtils.getNestedFields(fields, Arrays.asList(record)).get(0);

        // Return the response
        return record;
    }

    @Override
    public RecordList search(BridgeRequest request) throws BridgeError {
        // Initialize the result data
        List<Record> records = new ArrayList<Record>();

        // Validate the Structure
        if (!VALID_STRUCTURES.contains(request.getStructure())) {
            throw new BridgeError("Invalid Structure: '" + request.getStructure() + "' is not a valid structure");
        }
        
        // Load fields into a variable and initiate it as an empty list if it is null
        List<String> fields = request.getFields();
        if (fields == null) fields = new ArrayList<String>();
        
        Users users = requestUsers(request);
        if (users.getUsers() != null) {
            for (User user : users.getUsers()) {
                if (fields.isEmpty()) fields.addAll(user.keySet());
                records.add(new Record(user));
            }
        }
        
        // Build the return metadata
        Map<String,String> metadata = new LinkedHashMap<String,String>();
        metadata.put("size",String.valueOf(records.size()));
        metadata.put("nextPageToken",users.getNextPageToken());
        
        if (!fields.isEmpty()) records = BridgeUtils.getNestedFields(fields, records);
        
        // Return the response
        return new RecordList(fields, records, metadata);
    }
    
    /*----------------------------------------------------------------------------------------------
     * HELPER METHODS
     *--------------------------------------------------------------------------------------------*/
    private Users requestUsers(BridgeRequest request) throws BridgeError {
        // Parse and replace parameters in the query
        GoogleAdminQualificationParser parser = new GoogleAdminQualificationParser();
        String query = parser.parse(request.getQuery(),request.getParameters());
        
        // Pull the domain out of the query (if it has been included) and assign it to
        // a local variable. Add any other parts to the queryParts list so that it can
        // be rebuilt into a query
        List<String> queryParts = new ArrayList<String>();
        String adminDomain = this.domain;
        // Split the query into individual parts
        String[] keyValueArray = query.split("&");
        for(String pair : keyValueArray){
            String[] individualValue = pair.split("=");
            if(individualValue[0].trim().toLowerCase().equals("domain")){
                // If the key is domain, assign the value to the searchDomain variable
                adminDomain = individualValue[1].trim();
            } else {
                // If the key isn't domain, add the query to the list to be rebuilt
                queryParts.add(pair);
            }
        }
        // Rebuild the query parts into a query string
        String googleQuery = StringUtils.join(queryParts,"&");
        if (adminDomain.isEmpty()) throw new BridgeError("A domain must be included in either the Bridge Configuration or Bridge Query.");
        
        // Get the limit from the request metadata if included
        int limit = request.getMetadata("pageSize") != null ? Integer.parseInt(request.getMetadata("pageSize")) : 500;
        
        Users users;
        try {
            // Build the google call
            Directory.Users.List list = this.directory.users().list().setQuery(googleQuery).setMaxResults(limit);
            if (!adminDomain.isEmpty()) list = list.setDomain(adminDomain);
            if (request.getFields() != null && !request.getFields().isEmpty()) list = list.setFields("nextPageToken,users("+request.getFieldString()+")");
            if (request.getMetadata("pageToken") != null) list = list.setPageToken(request.getMetadata("pageToken"));
            // Execute the call to retrieve users
            users = list.execute();
        } catch (IOException e) {
            throw new BridgeError("There was an error calling the API",e);
        }
        
        return users;
    }
}
