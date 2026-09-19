package dev.mbaiforinstinct.f21os;

import android.app.Activity;
import android.os.Bundle;
import android.text.InputType;
import android.widget.EditText;

public final class ImeHarnessActivity extends Activity {
    @Override public void onCreate(Bundle state) {
        super.onCreate(state);
        EditText field = new EditText(this);
        field.setInputType(InputType.TYPE_CLASS_TEXT | InputType.TYPE_TEXT_FLAG_MULTI_LINE);
        field.setHint("T9 harness");
        field.setTextSize(28);
        setContentView(field);
        field.requestFocus();
    }
}
