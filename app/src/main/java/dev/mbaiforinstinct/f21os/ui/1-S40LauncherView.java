package dev.mbaiforinstinct.f21os.ui;

import android.content.Context;
import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.Paint;
import android.graphics.RectF;
import android.view.KeyEvent;
import android.view.MotionEvent;
import android.view.View;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.Locale;

/** C2-derived key-first launcher shell for the Qin F21 Pro's 480x640 display. */
public final class S40LauncherView extends View {
    private enum Screen { IDLE, MENU, LIST, DETAIL }
    public interface Actions { void open(String section, String item, String input); }
    private final Actions actions;
    private final Paint p = new Paint(Paint.ANTI_ALIAS_FLAG);
    private final String[] apps = {"Messaging", "Contacts", "Call log", "Gallery", "Organiser", "Settings", "Music", "Radio", "Applications"};
    private final String[][] items = {
        {"Conversations", "New message", "Inbox view", "Message log", "SIM messages", "Memory status"},
        {"Names", "Add new", "Groups", "Speed dials"},
        {"All calls", "Missed calls", "Received calls", "Dialled numbers"},
        {"Photos", "Music & videos", "All content"},
        {"Alarm clock", "Calendar", "Notes", "Calculator", "Countdown timer", "Stopwatch"},
        {"Profiles", "Themes", "Tones", "Display", "Date and time", "Shortcuts", "Connectivity"},
        {"Music player", "Playlists", "All songs"}, {"Radio", "Stations"}, {"Extras", "Games", "Downloads"}
    };
    private Screen screen = Screen.IDLE;
    private int selected = 0, row = 0;
    private final StringBuilder input = new StringBuilder();

    public S40LauncherView(Context context, Actions actions) { super(context); this.actions=actions; setFocusable(true); }

    @Override protected void onDraw(Canvas c) { super.onDraw(c); if(screen==Screen.IDLE) drawIdle(c); else if(screen==Screen.MENU) drawMenu(c); else if(screen==Screen.LIST) drawList(c); else drawDetail(c); }

    private void drawIdle(Canvas c) {
        int w=getWidth(),h=getHeight(); c.drawColor(Color.rgb(50,95,158));
        p.setColor(Color.rgb(215,226,246)); c.drawRect(0,0,w,h*.55f,p);
        drawStatus(c);
        p.setColor(Color.rgb(7,141,240)); p.setTextAlign(Paint.Align.RIGHT); p.setTextSize(w*.13f);
        c.drawText(new SimpleDateFormat("HH:mm",Locale.UK).format(new Date()),w-16,h*.22f,p);
        p.setTextAlign(Paint.Align.LEFT); p.setTextSize(w*.04f); c.drawText(new SimpleDateFormat("EEEE",Locale.UK).format(new Date()),16,h*.15f,p);
        c.drawText(new SimpleDateFormat("d MMMM",Locale.UK).format(new Date()),16,h*.20f,p);
        p.setColor(Color.argb(210,250,253,254)); c.drawRoundRect(new RectF(8,h*.64f,w-8,h*.74f),5,5,p);
        p.setColor(Color.rgb(23,79,114)); p.setTextSize(w*.034f); c.drawText("No new notifications",20,h*.695f,p);
        drawSoftkeys(c,"Go to","Menu","Names");
    }

    private void drawStatus(Canvas c){ int w=getWidth(),h=getHeight();p.setColor(Color.rgb(5,7,8));c.drawRect(0,0,w,h*.075f,p);p.setColor(Color.WHITE);p.setTextSize(w*.03f);p.setTextAlign(Paint.Align.LEFT);c.drawText("▮▮▮  3G",10,h*.05f,p);p.setTextAlign(Paint.Align.RIGHT);c.drawText("▰",w-12,h*.05f,p); }

    private void drawMenu(Canvas c) {
        int w=getWidth(),h=getHeight(); c.drawColor(Color.rgb(215,226,246)); drawTitle(c,"Menu");
        float top=54,cellW=w/3f,cellH=(h-104)/3f;
        for(int i=0;i<apps.length;i++){ int col=i%3,r=i/3;float left=col*cellW+6,y=top+r*cellH+6;
            p.setColor(i==selected?Color.rgb(24,25,28):Color.argb(205,255,255,255)); c.drawRoundRect(new RectF(left,y,left+cellW-12,y+cellH-12),10,10,p);
            if(i==selected){p.setStyle(Paint.Style.STROKE);p.setStrokeWidth(2);p.setColor(Color.LTGRAY);c.drawRoundRect(new RectF(left,y,left+cellW-12,y+cellH-12),10,10,p);p.setStyle(Paint.Style.FILL);}
            p.setColor(i==selected?Color.WHITE:Color.rgb(30,57,84));p.setTextAlign(Paint.Align.CENTER);p.setTextSize(w*.032f);c.drawText(apps[i],left+(cellW-12)/2,y+cellH*.60f,p);
        } drawSoftkeys(c,"Options","Select","Exit");
    }

    private void drawList(Canvas c){ int w=getWidth(),h=getHeight();c.drawColor(Color.rgb(238,242,244));drawTitle(c,apps[selected]);String[] list=items[selected];float y=72;
        for(int i=0;i<list.length;i++,y+=58){if(i==row){p.setColor(Color.rgb(39,130,173));c.drawRect(6,y-34,w-6,y+14,p);}p.setColor(i==row?Color.WHITE:Color.rgb(34,45,56));p.setTextAlign(Paint.Align.LEFT);p.setTextSize(w*.038f);c.drawText(list[i],18,y,p);}drawSoftkeys(c,"Options","Select","Back"); }


    private void drawDetail(Canvas c){
        int w=getWidth(),h=getHeight();c.drawColor(Color.rgb(238,242,244));String name=items[selected][row];drawTitle(c,name);
        p.setColor(Color.rgb(39,130,173));c.drawRoundRect(new RectF(10,62,w-10,122),6,6,p);p.setColor(Color.WHITE);p.setTextSize(w*.038f);p.setTextAlign(Paint.Align.LEFT);
        String primary=input.length()==0?detailHint(name):input.toString();c.drawText(primary,22,99,p);
        p.setColor(Color.rgb(55,67,78));p.setTextSize(w*.032f);float y=165;for(String line:detailLines(name)){c.drawText(line,18,y,p);y+=42;}
        drawSoftkeys(c,detailLeft(name),detailCentre(name),"Back");
    }
    private String detailHint(String n){if(n.equals("New message"))return "New number";if(n.contains("call")||n.equals("All calls"))return "No calls";if(n.equals("Calculator"))return "0";if(n.equals("Countdown timer"))return "00:00:00";return n;}
    private String[] detailLines(String n){if(n.equals("Conversations"))return new String[]{"No conversations","Start with New message"};if(n.equals("New message"))return new String[]{"Enter number with keypad","Centre key continues to composer"};if(n.equals("Photos")||n.equals("Music & videos")||n.equals("All content"))return new String[]{"No media yet","Key-first Gallery category"};if(n.equals("Profiles"))return new String[]{"General","Silent","Meeting","Outdoor","My style"};if(n.equals("Calculator"))return new String[]{"Use keypad for numbers","Options: Clear, Memory"};return new String[]{"Ready for hardware services","Options available from left softkey"};}
    private String detailLeft(String n){return n.equals("New message")?"Options":"Options";}
    private String detailCentre(String n){return n.equals("New message")?"Continue":"Select";}

    private void drawTitle(Canvas c,String title){p.setColor(Color.rgb(30,57,84));p.setTextAlign(Paint.Align.LEFT);p.setTextSize(getWidth()*.052f);c.drawText(title,14,37,p);}
    private void drawSoftkeys(Canvas c,String left,String centre,String right){int w=getWidth(),h=getHeight();p.setColor(Color.rgb(2,3,4));c.drawRect(0,h-46,w,h,p);p.setColor(Color.WHITE);p.setTextSize(w*.038f);p.setTextAlign(Paint.Align.LEFT);c.drawText(left,12,h-16,p);p.setTextAlign(Paint.Align.CENTER);c.drawText(centre,w/2f,h-16,p);p.setTextAlign(Paint.Align.RIGHT);c.drawText(right,w-12,h-16,p);}

    public boolean handleKey(KeyEvent e){if(e.getAction()!=KeyEvent.ACTION_DOWN)return false;int k=e.getKeyCode();
        if(screen==Screen.IDLE&&(k==KeyEvent.KEYCODE_DPAD_CENTER||k==KeyEvent.KEYCODE_ENTER)){screen=Screen.MENU;invalidate();return true;}
        if(screen==Screen.MENU){if(k==KeyEvent.KEYCODE_BACK||k==KeyEvent.KEYCODE_SOFT_RIGHT||k==KeyEvent.KEYCODE_ENDCALL){screen=Screen.IDLE;invalidate();return true;}if(k==KeyEvent.KEYCODE_DPAD_CENTER||k==KeyEvent.KEYCODE_ENTER){row=0;screen=Screen.LIST;invalidate();return true;}if(k==KeyEvent.KEYCODE_DPAD_LEFT)selected=(selected%3==0)?selected+2:selected-1;else if(k==KeyEvent.KEYCODE_DPAD_RIGHT)selected=(selected%3==2)?selected-2:selected+1;else if(k==KeyEvent.KEYCODE_DPAD_UP)selected=(selected+6)%9;else if(k==KeyEvent.KEYCODE_DPAD_DOWN)selected=(selected+3)%9;else return false;invalidate();return true;}
        if(screen==Screen.LIST){if(k==KeyEvent.KEYCODE_BACK||k==KeyEvent.KEYCODE_SOFT_RIGHT){screen=Screen.MENU;invalidate();return true;}if(k==KeyEvent.KEYCODE_ENDCALL){screen=Screen.IDLE;invalidate();return true;}if(k==KeyEvent.KEYCODE_DPAD_CENTER||k==KeyEvent.KEYCODE_ENTER){input.setLength(0);screen=Screen.DETAIL;invalidate();return true;}if(k==KeyEvent.KEYCODE_DPAD_UP)row=(row+items[selected].length-1)%items[selected].length;else if(k==KeyEvent.KEYCODE_DPAD_DOWN)row=(row+1)%items[selected].length;else return false;invalidate();return true;}if(screen==Screen.DETAIL){if(k==KeyEvent.KEYCODE_DPAD_CENTER||k==KeyEvent.KEYCODE_ENTER){actions.open(apps[selected],items[selected][row],input.toString());return true;}if(k==KeyEvent.KEYCODE_BACK||k==KeyEvent.KEYCODE_SOFT_RIGHT){screen=Screen.LIST;invalidate();return true;}if(k==KeyEvent.KEYCODE_ENDCALL){screen=Screen.IDLE;invalidate();return true;}if(k>=KeyEvent.KEYCODE_0&&k<=KeyEvent.KEYCODE_9){input.append((char)('0'+k-KeyEvent.KEYCODE_0));invalidate();return true;}if(k==KeyEvent.KEYCODE_DEL&&input.length()>0){input.deleteCharAt(input.length()-1);invalidate();return true;}return false;}return false;}

    @Override public boolean onTouchEvent(MotionEvent e){if(e.getAction()!=MotionEvent.ACTION_UP)return true;float x=e.getX(),y=e.getY();if(y>getHeight()-70){if(x>getWidth()*.33f&&x<getWidth()*.67f)handleKey(new KeyEvent(KeyEvent.ACTION_DOWN,KeyEvent.KEYCODE_DPAD_CENTER));else if(x>=getWidth()*.67f)handleKey(new KeyEvent(KeyEvent.ACTION_DOWN,KeyEvent.KEYCODE_BACK));return true;}if(screen==Screen.MENU){int col=Math.min(2,(int)(x/(getWidth()/3f)));int r=Math.max(0,Math.min(2,(int)((y-54)/((getHeight()-104)/3f))));selected=r*3+col;invalidate();}return true;}
}
