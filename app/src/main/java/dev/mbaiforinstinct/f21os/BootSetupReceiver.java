package dev.mbaiforinstinct.f21os;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;

/** Re-applies the default-IME setup after every boot so the choice self-heals. */
public final class BootSetupReceiver extends BroadcastReceiver {
    @Override public void onReceive(Context context, Intent intent) {
        if (intent != null && Intent.ACTION_BOOT_COMPLETED.equals(intent.getAction())) {
            ImeSetup.ensureDefaultIme(context.getApplicationContext());
        }
    }
}
