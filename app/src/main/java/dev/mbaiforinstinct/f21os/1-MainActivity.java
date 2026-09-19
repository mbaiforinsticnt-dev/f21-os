package dev.mbaiforinstinct.f21os;

import android.app.Activity;
import android.content.Intent;
import android.net.Uri;
import android.os.Bundle;
import android.provider.AlarmClock;
import android.provider.CalendarContract;
import android.provider.ContactsContract;
import android.provider.MediaStore;
import android.provider.Settings;
import android.view.KeyEvent;
import dev.mbaiforinstinct.f21os.ui.S40LauncherView;

/** Bridges the Nokia-style key shell to Android's hardware-backed system apps. */
public final class MainActivity extends Activity implements S40LauncherView.Actions {
    private S40LauncherView launcher;
    @Override public void onCreate(Bundle state) { super.onCreate(state); launcher = new S40LauncherView(this,this); setContentView(launcher); }
    @Override public boolean dispatchKeyEvent(KeyEvent event) { return launcher.handleKey(event) || super.dispatchKeyEvent(event); }
    @Override public void open(String section,String item,String input){
        Intent i=null;
        if(section.equals("Contacts")) i=new Intent(item.equals("Add new")?Intent.ACTION_INSERT:Intent.ACTION_VIEW,item.equals("Add new")?ContactsContract.Contacts.CONTENT_URI:ContactsContract.Contacts.CONTENT_URI);
        else if(section.equals("Call log")) i=new Intent(Intent.ACTION_VIEW,Uri.parse("content://call_log/calls"));
        else if(section.equals("Messaging")){ if(item.equals("New message")){i=new Intent(Intent.ACTION_SENDTO,Uri.parse("smsto:"+Uri.encode(input)));i.putExtra("sms_body","");}else i=new Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_APP_MESSAGING); }
        else if(section.equals("Gallery")) i=new Intent(Intent.ACTION_VIEW, MediaStore.Images.Media.EXTERNAL_CONTENT_URI);
        else if(section.equals("Music")) i=new Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_APP_MUSIC);
        else if(section.equals("Organiser")&&item.equals("Alarm clock")) i=new Intent(AlarmClock.ACTION_SHOW_ALARMS);
        else if(section.equals("Organiser")&&item.equals("Calendar")) i=new Intent(Intent.ACTION_VIEW, CalendarContract.CONTENT_URI);
        else if(section.equals("Settings")) i=new Intent(Settings.ACTION_SETTINGS);
        else if(section.equals("Applications")) i=new Intent(Settings.ACTION_APPLICATION_SETTINGS);
        if(i!=null){try{startActivity(i);}catch(Exception ignored){startActivity(new Intent(Settings.ACTION_SETTINGS));}}
    }
}
