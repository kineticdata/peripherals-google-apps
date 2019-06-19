package com.kineticdata.bridgehub.adapter.google;

import com.kineticdata.bridgehub.adapter.QualificationParser;

/**
 *
 */
public class GoogleAdminQualificationParser extends QualificationParser {
    public String encodeParameter(String name, String value) {
        return value;
    }
}
