package com.kineticdata.bridgehub.adapter.googledrive;

import com.kineticdata.bridgehub.adapter.QualificationParser;

public class GoogleDriveQualificationParser extends QualificationParser {
    public String encodeParameter(String name, String value) {
        return value;
    }
}
