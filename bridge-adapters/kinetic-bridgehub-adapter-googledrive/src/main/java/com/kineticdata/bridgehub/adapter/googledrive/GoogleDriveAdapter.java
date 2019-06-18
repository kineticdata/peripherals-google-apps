package com.kineticdata.bridgehub.adapter.googledrive;

import com.kineticdata.bridgehub.adapter.BridgeAdapter;
import com.kineticdata.bridgehub.adapter.BridgeError;
import com.kineticdata.bridgehub.adapter.BridgeRequest;
import com.kineticdata.bridgehub.adapter.Count;
import com.kineticdata.bridgehub.adapter.Record;
import com.kineticdata.bridgehub.adapter.RecordList;
import com.kineticdata.commons.v1.config.ConfigurableProperty;
import com.kineticdata.commons.v1.config.ConfigurablePropertyMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import org.json.simple.JSONValue;
import com.google.api.client.googleapis.auth.oauth2.GoogleCredential;
import com.google.api.client.googleapis.javanet.GoogleNetHttpTransport;
import com.google.api.client.http.HttpTransport;
import com.google.api.client.json.JsonFactory;
import com.google.api.client.json.jackson2.JacksonFactory;
import com.google.api.services.drive.Drive;
import com.google.api.services.drive.DriveScopes;
import com.google.api.services.drive.model.ChildList;
import com.google.api.services.drive.model.ChildReference;
import com.google.api.services.drive.model.FileList;
import com.google.api.services.drive.model.File;
import com.kineticdata.bridgehub.adapter.BridgeUtils;
import java.io.IOException;
import java.security.GeneralSecurityException;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import org.apache.http.HttpEntity;
import org.apache.http.HttpResponse;
import org.apache.http.client.HttpClient;
import org.apache.http.client.methods.HttpGet;
import org.apache.http.impl.client.DefaultHttpClient;
import org.apache.http.util.EntityUtils;
import org.json.simple.JSONObject;
import org.slf4j.LoggerFactory;

public class GoogleDriveAdapter implements BridgeAdapter {
    /*----------------------------------------------------------------------------------------------
     * PROPERTIES
     *--------------------------------------------------------------------------------------------*/
    
    /** Defines the adapter display name */
    public static final String NAME = "Google Drive Bridge";
    
    /** Defines the logger */
    protected static final org.slf4j.Logger logger = LoggerFactory.getLogger(GoogleDriveAdapter.class);

    /** Adapter version constant. */
    public static String VERSION;
    /** Load the properties version from the version.properties file. */
    static {
        try {
            java.util.Properties properties = new java.util.Properties();
            properties.load(GoogleDriveAdapter.class.getResourceAsStream("/"+GoogleDriveAdapter.class.getName()+".version"));
            VERSION = properties.getProperty("version");
        } catch (IOException e) {
            logger.warn("Unable to load "+GoogleDriveAdapter.class.getName()+" version properties.", e);
            VERSION = "Unknown";
        }
    }
    
    /** Defines the collection of property names for the adapter */
    public static class Properties {
        public static final String PROPERTY_EMAIL = "Service Account Email";
        public static final String PROPERTY_P12_FILE = "P12 File Location";
        public static final String PROPERTY_USER_IMPERSONATION = "Impersonated User Email";
        public static final String PROPERTY_EXPIRATION_SCRIPT = "Google Apps Expiration Script Url";
    }
    
    private final ConfigurablePropertyMap properties = new ConfigurablePropertyMap(
        new ConfigurableProperty(Properties.PROPERTY_EMAIL).setIsRequired(true),
        new ConfigurableProperty(Properties.PROPERTY_P12_FILE).setIsRequired(true),
        new ConfigurableProperty(Properties.PROPERTY_USER_IMPERSONATION).setIsRequired(true),
        new ConfigurableProperty(Properties.PROPERTY_EXPIRATION_SCRIPT)
    );

    private String serviceAccountEmail;
    private String p12Location;
    private String impersonatedUser;
    private String expirationScript;
    Drive drive;
    Map<String,Map> prevTokenMap;
    
    /*---------------------------------------------------------------------------------------------
     * SETUP METHODS
     *-------------------------------------------------------------------------------------------*/
    
    @Override
    public void initialize() throws BridgeError {
        this.serviceAccountEmail = properties.getValue(Properties.PROPERTY_EMAIL);
        this.p12Location = properties.getValue(Properties.PROPERTY_P12_FILE);
        this.impersonatedUser = properties.getValue(Properties.PROPERTY_USER_IMPERSONATION);
        this.prevTokenMap = new HashMap<String,Map>();
        this.expirationScript = properties.getValue(Properties.PROPERTY_EXPIRATION_SCRIPT);
        
        JsonFactory JSON_FACTORY = JacksonFactory.getDefaultInstance();
        HttpTransport httpTransport;
        GoogleCredential credential;
        try {
            httpTransport = GoogleNetHttpTransport.newTrustedTransport();
            List<String> scopes = new ArrayList<String>();
            scopes.add(DriveScopes.DRIVE);
            credential = new GoogleCredential.Builder()
                .setTransport(httpTransport)
                .setJsonFactory(JSON_FACTORY)
                .setServiceAccountId(serviceAccountEmail)
                .setServiceAccountPrivateKeyFromP12File(new java.io.File(p12Location))
                .setServiceAccountScopes(scopes)
                .setServiceAccountUser(impersonatedUser)
                .build();
            
        } catch (GeneralSecurityException gse) {
            throw new BridgeError(gse);
        } catch (IOException gse) {
            throw new BridgeError(gse);
        }
        
        this.drive = new Drive.Builder(httpTransport, JSON_FACTORY, credential).build();
    }

    @Override
    public String getName() {
        return NAME;
    }
    
    @Override
    public String getVersion() {
        return VERSION;
    }
    
    @Override
    public void setProperties(Map<String,String> parameters) {
        properties.setValues(parameters);
    }
    
    @Override
    public ConfigurablePropertyMap getProperties() {
        return properties;
    }
    
    /*---------------------------------------------------------------------------------------------
     * IMPLEMENTATION METHODS
     *-------------------------------------------------------------------------------------------*/
        
    @Override
    public Count count(BridgeRequest request) throws BridgeError {
        // Initialize the result data and response variables
        Map<String,Object> data = new LinkedHashMap();

        GoogleDriveQualificationParser parser = new GoogleDriveQualificationParser();
        String query = parser.parse(request.getQuery(),request.getParameters());
        
        if (query.matches("^\\S*? = [\"']?\\*[\"']?$") || query.equals("*")) {
            query = "";
        }
        
        String nextToken = "";
        int count = 0;
        String folderId = getFolderId(query);
        query = removeFolderId(query);
        while (nextToken != null) {
            try {
                if (request.getStructure().equals("Files")) {
                    FileList fl = this.drive.files().list().setMaxResults(1000).setQ("not title contains 'expiringLink1'").setQ("trashed = false").setQ(query).setPageToken(nextToken).execute();
                    count += fl.getItems().size();
                    nextToken = fl.getNextPageToken();
                } else if (request.getStructure().equals("Folder")) {
                    ChildList cl = this.drive.children().list(folderId).setQ("not title contains 'expiringLink1'").setQ("trashed = false").setQ(query).setMaxResults(1000).execute();
                    count += cl.getItems().size();
                    nextToken = cl.getNextPageToken();
                }
            } catch (IOException ioe) {
                throw new BridgeError("Error attempting to retrieve Drive files.",ioe);
            }
        }

        // Retrieving the count tag from the response and then placing that 
        // value in the data hash that will be returned to the user as JSON
        data.put("count",Long.valueOf(count));
     
        //Return the response
        return new Count(count);

    }

    @Override
    public Record retrieve(BridgeRequest request) throws BridgeError {
        // Initialize the result data and response variables
        Map<String,Object> data = new LinkedHashMap();
        Record record = new Record(null);
        
        GoogleDriveQualificationParser parser = new GoogleDriveQualificationParser();
        String query = parser.parse(request.getQuery(),request.getParameters());

        if (query.matches("^\\S*? = [\"']?\\*[\"']?$") || query.equals("*")) {
            query = "";
        }
        
        String folderId = getFolderId(query);
        query = removeFolderId(query);
        try {
            List items = null;
            File file = null;
            if (request.getStructure().equals("Files")) {
                FileList fl = this.drive.files().list().setMaxResults(2).setQ("trashed = false").setQ("not title contains 'expiringLink1'").setQ(query).execute();
                items = fl.getItems();
                
                if (items.size() == 1) {
                    file = (File)items.get(0);
                    Map<String,Object> recordMap = new LinkedHashMap<String,Object>();
                    for (String field : request.getFieldArray()) {
                        recordMap.put(field, getFileField(file, field));
                    }
                    record = new Record(recordMap);
                }
            } else if (request.getStructure().equals("Folder")) {
                ChildList cl = this.drive.children().list(folderId).setQ(query).setQ("trashed = false").setQ("not title contains 'expiringLink1'").setQ(query).execute();
                items = cl.getItems();
                
                if (items.size() == 1) {
                    ChildReference cr = (ChildReference)items.get(0);
                    file = this.drive.files().get(cr.getId()).execute();
                }
            } else {
                throw new BridgeError("Retrive method has not been implemented for this Strucutre.");
            }

            if (items.size() > 1) {
                throw new BridgeError("Multiple results matched an expected single match query");
            } else if (items.isEmpty()) {
                record = null;
            } else {
                Map<String,Object> recordMap = new LinkedHashMap<String,Object>();
                for (String field : request.getFieldArray()) {
                    if (field.equals("expiringLink")) {
                        recordMap.put(field, getExpiringLink(file));
                    } else {
                        recordMap.put(field, getFileField(file, field));
                    }
                }
                record = new Record(recordMap);
            }
        } catch (IOException ioe) {
            throw new BridgeError("Error attempting to retrieve Drive files.",ioe);
        }
        
        data.put("record",record);
        
        // Returning the response
        return record;
    }

    @Override
    public RecordList search(BridgeRequest request) throws BridgeError {
        // Initialize the result data and response variables
        Map<String,Object> data = new LinkedHashMap();
        ArrayList<Record> records = new ArrayList<Record>();
        List<String> fields = request.getFields();

        GoogleDriveQualificationParser parser = new GoogleDriveQualificationParser();
        String query = parser.parse(request.getQuery(),request.getParameters());

        // If query matches * or {field} eq *, it pass an empty string. Wilcards
        // are not supported by the Microsoft Project API, so this needs to be
        // added so that if a query is required, querying for everything is
        // still an option.
        if (query.matches("^\\S*? = [\"']?\\*[\"']?$") || query.equals("*")) {
            query = "";
        }
        
        logger.debug(query);
                
        String pageSize = request.getMetadata("pageSize");
        String pageNum = request.getMetadata("pageNumber");
        String pageToken = request.getMetadata("pageToken");
        String nextPageToken;
        String folderId = getFolderId(query);
        query = removeFolderId(query);

        try {
            if (request.getStructure().equals("Files")) {
                Drive.Files.List listObj = this.drive.files().list();
                listObj.setQ("trashed = false").setQ("not title contains 'expiringLink1'").setQ(query);
                if (pageSize != null) { listObj.setMaxResults(Integer.valueOf(pageSize)); }
                if (pageToken != null) { listObj.setPageToken(pageToken); }
                FileList fl = listObj.execute();
                for (File f : fl.getItems()) {
                    Map<String,Object> recordMap = new LinkedHashMap<String,Object>();
                    for (String field : request.getFieldArray()) {
                        recordMap.put(field, getFileField(f, field));
//                        record.add(getFileField(f, field));
                    }
                    records.add(new Record((Map<String,Object>)recordMap));
                }
                nextPageToken = fl.getNextPageToken();
            } else if (request.getStructure().equals("Folder")) {
                Drive.Children.List listObj = this.drive.children().list(folderId);
                listObj.setQ("trashed = false").setQ("not title contains 'expiringLink1'").setQ(query);
                if (pageSize != null) { listObj.setMaxResults(Integer.valueOf(pageSize)); }
                if (pageToken != null) { listObj.setPageToken(pageToken); }
                ChildList cl = listObj.execute();
                
                for (ChildReference cr : cl.getItems()) {
                    File f = this.drive.files().get(cr.getId()).execute();
                    Map<String,Object> recordMap = new LinkedHashMap<String,Object>();
                    for (String field : request.getFieldArray()) {
                        recordMap.put(field, getFileField(f, field));
                    }
                    records.add(new Record((Map<String,Object>)recordMap));
                }
                nextPageToken = cl.getNextPageToken();
            } else {
                throw new BridgeError("The Search method has not been implemented for the current Structure.");
            }
        } catch (IOException ioe) {
            throw new BridgeError("Error attempting to retrieve Drive files.",ioe);
        }

        if (pageSize == null) { pageSize = "0"; }
        if (pageNum == null) {pageNum = "1"; }
        String offset = "0";
        // Building the output metadata
        Map<String,String> metadata = BridgeUtils.normalizePaginationMetadata(request.getMetadata());
        metadata.put("pageSize", String.valueOf(pageSize));
        metadata.put("pageNumber", String.valueOf(pageNum));
        metadata.put("offset", String.valueOf(offset));
        metadata.put("size", String.valueOf(records.size()));
        metadata.put("count", null);

        // Lastly, getting the overall count for this call (if necessary). If
        // possible though, the count will be computed without making the method
        // call to try and save computing time
        Long currentPage = Long.valueOf(metadata.get("pageNumber"));
        if (!this.prevTokenMap.containsKey(request.getQuery())) {
            this.prevTokenMap.put(request.getQuery(), new HashMap<String,String>());
        }
        this.prevTokenMap.get(request.getQuery()).put(currentPage + 1L, nextPageToken);
        
        if (Long.valueOf(metadata.get("pageNumber")) > 2L) {
            System.out.println(currentPage - 1L);
            metadata.put("prevPage", (String) this.prevTokenMap.get(request.getQuery()).get(currentPage - 1L));
        } else {
            metadata.put("prevPage", null);
        }
        
        if (nextPageToken != null) {
            metadata.put("count", String.valueOf(metadata.get("size")) + 1L);
            metadata.put("nextPage", nextPageToken);
        } else {
            metadata.put("nextPage", null);
            metadata.put("count",metadata.get("size"));
        }
        
        data.put("metadata",metadata);
        data.put("fields",fields);
        data.put("records",records);
        
        // Returning the response
        return new RecordList(fields, records, metadata);
    }
    
    /*----------------------------------------------------------------------------------------------
     * PRIVATE HELPER METHODS
     *--------------------------------------------------------------------------------------------*/   
    
    private Object getFileField(File file, String field) {
        Object value = null;
        if (field.equals("title")) {
            value = file.getTitle();
        } else if (field.equals("id")) {
            value = file.getId();
        } else if (field.equals("fileSize")) {
            value = file.getFileSize();
        } else if (field.equals("lastModifiedUser")) {
            value = file.getLastModifyingUser();
        } else if (field.equals("lastModified")) {
            value = file.getModifiedDate().toString();
        } else if (field.equals("owners")) {
            value = file.getOwners();
        } else if (field.equals("downloadUrl")) {
            value = file.getDownloadUrl();
        } else if (field.equals("kind")) {
            value = file.getKind();
        } else if (field.equals("alternateLink")) {
            value = file.getAlternateLink();
        }
        
        return value;
    }
    
    private String getExpiringLink(File file) throws BridgeError {
        String link;
        String getUrl = this.expirationScript + "?fileId=" + file.getId();
        logger.trace("File Id: " + file.getId());
        
        // Initializing the Http Objects
        HttpClient client = new DefaultHttpClient();
        HttpResponse response;
        HttpGet get = new HttpGet(getUrl);
        
        String output;
        try {
            response = client.execute(get);

            logger.trace("Request response code: " + response.getStatusLine().getStatusCode());
            HttpEntity entity = response.getEntity();
            output = EntityUtils.toString(entity);
        }
        catch (IOException e) {
            logger.error(e.getMessage());
            throw new BridgeError("Unable to make a connection to Google Apps Script"); 
        }
        
        System.out.println(output);
        
        JSONObject json = (JSONObject)JSONValue.parse(output);
        link = json.get("url").toString();
        
        return link;
    }
    
    private String getFolderId(String query) {
        String folderId = null;

        Pattern folderIdPattern = Pattern.compile("folderId\\s?=\\s?[\"'](.*?)[\"'](?: and)?");
        Matcher folderIdMatcher = folderIdPattern.matcher(query);
        while (folderIdMatcher.find()) {
            folderId = folderIdMatcher.group(1);
        }
        
        return folderId;
    }
    
    private String removeFolderId(String query) {
        return query.replaceFirst("folderId\\s?=\\s?[\"'](.*?)[\"'](?: and)?", "");
    }

}