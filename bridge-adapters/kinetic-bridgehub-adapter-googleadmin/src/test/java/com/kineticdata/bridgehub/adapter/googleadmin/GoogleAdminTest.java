package com.kineticdata.bridgehub.adapter.googleadmin;

import com.kineticdata.bridgehub.adapter.BridgeAdapterTestBase;
import com.kineticdata.bridgehub.adapter.BridgeError;
import com.kineticdata.bridgehub.adapter.BridgeRequest;
import com.kineticdata.bridgehub.adapter.Count;
import com.kineticdata.bridgehub.adapter.RecordList;
import com.kineticdata.bridgehub.adapter.google.GoogleAdminAdapter;
import java.util.Arrays;
import java.util.HashMap;
import java.util.List;
import static org.junit.Assert.assertNull;
import static org.junit.Assert.assertTrue;
import org.junit.Test;

public class GoogleAdminTest  extends BridgeAdapterTestBase {

    @Override
    public Class getAdapterClass() {
        return GoogleAdminAdapter.class;
    }

    @Override
    public String getConfigFilePath() {
        return "src/test/resources/bridge-config.yml";
    }
    
    @Test
    public void test_count() throws Exception{
        BridgeError error = null;

        BridgeRequest request = new BridgeRequest();

        List<String> fields = Arrays.asList();

        request.setStructure("Users");
        request.setFields(fields);

        request.setParameters(new HashMap(){{
            
        }});
        
        request.setQuery("name:'Chad'");
        
        Count count = null;
        try {
            count = getAdapter().count(request);
        } catch (BridgeError e) {
            error = e;
        }

        assertNull(error);
        assertTrue(count.getValue() > 0);
    }
    
    @Test
    public void test_search() throws Exception{
        BridgeError error = null;

        BridgeRequest request = new BridgeRequest();

        List<String> fields = Arrays.asList("name","gender");

        request.setStructure("Users");
        request.setFields(fields);

        request.setParameters(new HashMap(){{
            
        }});
        
        request.setQuery("name:'Chad'");
        
        RecordList records = null;
        try {
            records = getAdapter().search(request);
        } catch (BridgeError e) {
            error = e;
        }

        assertNull(error);
        assertTrue(records.getRecords().size() > 0);
    }
}
