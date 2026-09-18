package dev.mbaiforinstinct.f21os;

import android.app.Activity;
import android.os.Bundle;
import android.view.KeyEvent;
import dev.mbaiforinstinct.f21os.ui.S40LauncherView;

public final class MainActivity extends Activity {
    private S40LauncherView launcher;

    @Override public void onCreate(Bundle state) {
        super.onCreate(state);
        launcher = new S40LauncherView(this);
        setContentView(launcher);
    }

    @Override public boolean dispatchKeyEvent(KeyEvent event) {
        return launcher.handleKey(event) || super.dispatchKeyEvent(event);
    }
}
