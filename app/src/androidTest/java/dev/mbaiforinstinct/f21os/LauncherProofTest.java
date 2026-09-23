package dev.mbaiforinstinct.f21os;

import android.graphics.Bitmap;
import android.graphics.Canvas;
import android.content.Intent;
import android.view.KeyEvent;
import androidx.test.core.app.ActivityScenario;
import androidx.test.ext.junit.runners.AndroidJUnit4;
import androidx.test.platform.app.InstrumentationRegistry;
import java.io.File;
import java.io.FileOutputStream;
import org.junit.Test;
import org.junit.runner.RunWith;

@RunWith(AndroidJUnit4.class)
public final class LauncherProofTest {
    private void shot(MainActivity a, String name) throws Exception {
        Bitmap b=Bitmap.createBitmap(a.getWindow().getDecorView().getWidth(),a.getWindow().getDecorView().getHeight(),Bitmap.Config.ARGB_8888);
        a.getWindow().getDecorView().draw(new Canvas(b));
        File d=new File(InstrumentationRegistry.getInstrumentation().getTargetContext().getFilesDir(),"proof"); d.mkdirs();
        try(FileOutputStream o=new FileOutputStream(new File(d,name))){b.compress(Bitmap.CompressFormat.PNG,100,o);}
    }
    @Test public void captureKeyNavigation() throws Exception {
        try(ActivityScenario<MainActivity> s=ActivityScenario.launch(MainActivity.class)){
            s.onActivity(a->{try{shot(a,"idle.png");a.dispatchKeyEvent(new KeyEvent(KeyEvent.ACTION_DOWN,KeyEvent.KEYCODE_DPAD_CENTER));shot(a,"menu.png");a.dispatchKeyEvent(new KeyEvent(KeyEvent.ACTION_DOWN,KeyEvent.KEYCODE_DPAD_RIGHT));a.dispatchKeyEvent(new KeyEvent(KeyEvent.ACTION_DOWN,KeyEvent.KEYCODE_DPAD_DOWN));shot(a,"menu-key-navigation.png");}catch(Exception e){throw new RuntimeException(e);}});
        }
    }

    @Test public void greenKeyDialFlow() {
        try(ActivityScenario<MainActivity> s=ActivityScenario.launch(MainActivity.class)){
            s.onActivity(a->{
                // Idle + green opens the call log (C2: home green goes to all calls).
                a.dispatchKeyEvent(new KeyEvent(KeyEvent.ACTION_DOWN,KeyEvent.KEYCODE_CALL));
                Intent log=MainActivity.lastBridgeIntent;
                if(log==null||!"content://call_log/calls".equals(String.valueOf(log.getData())))
                    throw new AssertionError("idle green should open the call log, got "+log);
                // Digits on a detail screen + green dials that number.
                a.dispatchKeyEvent(new KeyEvent(KeyEvent.ACTION_DOWN,KeyEvent.KEYCODE_DPAD_CENTER));
                a.dispatchKeyEvent(new KeyEvent(KeyEvent.ACTION_DOWN,KeyEvent.KEYCODE_DPAD_CENTER));
                a.dispatchKeyEvent(new KeyEvent(KeyEvent.ACTION_DOWN,KeyEvent.KEYCODE_DPAD_CENTER));
                a.dispatchKeyEvent(new KeyEvent(KeyEvent.ACTION_DOWN,KeyEvent.KEYCODE_1));
                a.dispatchKeyEvent(new KeyEvent(KeyEvent.ACTION_DOWN,KeyEvent.KEYCODE_2));
                a.dispatchKeyEvent(new KeyEvent(KeyEvent.ACTION_DOWN,KeyEvent.KEYCODE_3));
                a.dispatchKeyEvent(new KeyEvent(KeyEvent.ACTION_DOWN,KeyEvent.KEYCODE_CALL));
                Intent d=MainActivity.lastBridgeIntent;
                if(d==null||!Intent.ACTION_DIAL.equals(d.getAction())||!"tel:123".equals(String.valueOf(d.getData())))
                    throw new AssertionError("green with digits should fire tel:123, got "+d);
                // Menu + green opens the dialler with no number.
                a.dispatchKeyEvent(new KeyEvent(KeyEvent.ACTION_DOWN,KeyEvent.KEYCODE_BACK));
                a.dispatchKeyEvent(new KeyEvent(KeyEvent.ACTION_DOWN,KeyEvent.KEYCODE_BACK));
                a.dispatchKeyEvent(new KeyEvent(KeyEvent.ACTION_DOWN,KeyEvent.KEYCODE_CALL));
                Intent dial=MainActivity.lastBridgeIntent;
                if(dial==null||!Intent.ACTION_DIAL.equals(dial.getAction())||dial.getData()!=null)
                    throw new AssertionError("menu green should open the dialler, got "+dial);
            });
        }
    }
}
