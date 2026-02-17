package com.AdobeAir.Yodo1Mas;

import com.adobe.fre.FREContext;
import com.adobe.fre.FREExtension;

/**
 * Yodo1 MAS Adobe AIR Native Extension - Entry Point
 * 
 * This is the main FREExtension class that Adobe AIR calls to create
 * the native context for the Yodo1 MAS SDK integration.
 */
public class Yodo1MasExtension implements FREExtension {

    public static Yodo1MasContext context;

    @Override
    public FREContext createContext(String extId) {
        context = new Yodo1MasContext();
        return context;
    }

    @Override
    public void dispose() {
        if (context != null) {
            context.dispose();
            context = null;
        }
    }

    @Override
    public void initialize() {
    }
}
