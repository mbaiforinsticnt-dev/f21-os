package dev.mbaiforinstinct.f21os;

import android.graphics.Bitmap;
import android.graphics.Canvas;
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
}
