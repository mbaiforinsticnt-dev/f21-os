package dev.mbaiforinstinct.f21os;

import android.content.Context;
import android.content.pm.PackageManager;
import android.provider.Settings;
import android.util.Log;

/** Ensures Traditional T9 (the F21 OS keyboard) stays enabled and the default IME. */
public final class ImeSetup {
    public static final String TT9_IME_ID = "io.github.sspanak.tt9/.ime.TraditionalT9";
    private static final String TAG = "F21ImeSetup";

    private ImeSetup() {}

    /**
     * Idempotent: enables tt9 and makes it the default IME. Only acts when the app
     * holds WRITE_SECURE_SETTINGS (priv-app on the F21 OS image); a sideloaded debug
     * build without the permission leaves input-method settings alone.
     */
    public static void ensureDefaultIme(Context context) {
        if (context.checkSelfPermission(android.Manifest.permission.WRITE_SECURE_SETTINGS)
                != PackageManager.PERMISSION_GRANTED) {
            Log.i(TAG, "WRITE_SECURE_SETTINGS not held; leaving input-method settings alone");
            return;
        }
        String enabled = Settings.Secure.getString(
                context.getContentResolver(), Settings.Secure.ENABLED_INPUT_METHODS);
        if (enabled == null || !containsIme(enabled)) {
            String next = (enabled == null || enabled.isEmpty())
                    ? TT9_IME_ID : enabled + ":" + TT9_IME_ID;
            Settings.Secure.putString(
                    context.getContentResolver(), Settings.Secure.ENABLED_INPUT_METHODS, next);
            Log.i(TAG, "enabled " + TT9_IME_ID);
        }
        String current = Settings.Secure.getString(
                context.getContentResolver(), Settings.Secure.DEFAULT_INPUT_METHOD);
        if (!TT9_IME_ID.equals(current)) {
            Settings.Secure.putString(
                    context.getContentResolver(), Settings.Secure.DEFAULT_INPUT_METHOD, TT9_IME_ID);
            Log.i(TAG, "default IME -> " + TT9_IME_ID + " (was " + current + ")");
        }
    }

    private static boolean containsIme(String enabledList) {
        for (String id : enabledList.split(":")) {
            if (TT9_IME_ID.equals(id)) {
                return true;
            }
        }
        return false;
    }
}
