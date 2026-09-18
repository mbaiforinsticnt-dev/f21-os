package dev.mbaiforinstinct.f21os.ui;

import android.content.Context;
import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.Paint;
import android.graphics.RectF;
import android.view.KeyEvent;
import android.view.View;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.Locale;

/** Key-first launcher shell sized for the Qin F21 Pro's 480x640 display. */
public final class S40LauncherView extends View {
    private enum Screen { IDLE, MENU }
    private final Paint p = new Paint(Paint.ANTI_ALIAS_FLAG);
    private final String[] apps = {"Messaging", "Contacts", "Call log", "Gallery", "Organiser", "Settings", "Music", "Radio", "Applications"};
    private Screen screen = Screen.IDLE;
    private int selected = 0;

    public S40LauncherView(Context context) { super(context); setFocusable(true); }

    @Override protected void onDraw(Canvas c) {
        super.onDraw(c);
        if (screen == Screen.IDLE) drawIdle(c); else drawMenu(c);
    }

    private void drawIdle(Canvas c) {
        int w = getWidth(), h = getHeight();
        c.drawColor(Color.rgb(27, 72, 124));
        p.setColor(Color.rgb(69, 132, 183)); c.drawRect(0, h * .38f, w, h, p);
        p.setColor(Color.WHITE); p.setTextAlign(Paint.Align.CENTER); p.setTextSize(w * .15f);
        c.drawText(new SimpleDateFormat("HH:mm", Locale.UK).format(new Date()), w/2f, h*.29f, p);
        p.setTextSize(w*.046f); c.drawText(new SimpleDateFormat("EEE d MMM", Locale.UK).format(new Date()), w/2f, h*.36f, p);
        drawSoftkeys(c, "Go to", "Menu", "Names");
    }

    private void drawMenu(Canvas c) {
        int w=getWidth(), h=getHeight(); c.drawColor(Color.rgb(224,231,235));
        p.setColor(Color.rgb(30,57,84)); p.setTextAlign(Paint.Align.LEFT); p.setTextSize(w*.055f); c.drawText("Menu", 14, 34, p);
        float top=54, cellW=w/3f, cellH=(h-105)/3f;
        for(int i=0;i<apps.length;i++){
            int col=i%3,row=i/3; float left=col*cellW+6, y=top+row*cellH+6;
            p.setColor(i==selected?Color.rgb(70,119,170):Color.WHITE);
            c.drawRoundRect(new RectF(left,y,left+cellW-12,y+cellH-12),12,12,p);
            p.setColor(i==selected?Color.WHITE:Color.rgb(30,57,84)); p.setTextAlign(Paint.Align.CENTER); p.setTextSize(w*.032f);
            c.drawText(apps[i],left+(cellW-12)/2,y+cellH*.63f,p);
        }
        drawSoftkeys(c,"Options","Select","Exit");
    }

    private void drawSoftkeys(Canvas c,String left,String centre,String right){
        int w=getWidth(),h=getHeight(); p.setColor(Color.rgb(236,240,242)); c.drawRect(0,h-46,w,h,p);
        p.setColor(Color.rgb(20,40,64)); p.setTextSize(w*.038f); p.setTextAlign(Paint.Align.LEFT); c.drawText(left,12,h-16,p);
        p.setTextAlign(Paint.Align.CENTER); c.drawText(centre,w/2f,h-16,p);
        p.setTextAlign(Paint.Align.RIGHT); c.drawText(right,w-12,h-16,p);
    }

    public boolean handleKey(KeyEvent e){
        if(e.getAction()!=KeyEvent.ACTION_DOWN) return false;
        int k=e.getKeyCode();
        if(screen==Screen.IDLE && (k==KeyEvent.KEYCODE_DPAD_CENTER||k==KeyEvent.KEYCODE_ENTER)){ screen=Screen.MENU; invalidate(); return true; }
        if(screen==Screen.MENU){
            if(k==KeyEvent.KEYCODE_BACK||k==KeyEvent.KEYCODE_SOFT_RIGHT){screen=Screen.IDLE; invalidate(); return true;}
            if(k==KeyEvent.KEYCODE_DPAD_LEFT) selected=(selected%3==0)?selected+2:selected-1;
            else if(k==KeyEvent.KEYCODE_DPAD_RIGHT) selected=(selected%3==2)?selected-2:selected+1;
            else if(k==KeyEvent.KEYCODE_DPAD_UP) selected=(selected+6)%9;
            else if(k==KeyEvent.KEYCODE_DPAD_DOWN) selected=(selected+3)%9;
            else return false;
            invalidate(); return true;
        }
        return false;
    }
}
