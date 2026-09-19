#!/usr/bin/env bash
set -euo pipefail
ADB=${ADB:-adb}
mkdir -p screenshots-t9

wait_boot() {
  local bc=""
  for _ in $(seq 1 90); do
    bc=$($ADB shell getprop sys.boot_completed 2>/dev/null | tr -d '\r' || true)
    [ "$bc" = "1" ] && return 0
    sleep 4
  done
  echo "!! emulator never reported sys.boot_completed=1" >&2
  return 1
}

wait_services() {
  for _ in $(seq 1 30); do
    if $ADB shell service check package 2>/dev/null | grep -q "found" \
       && $ADB shell service check input_method 2>/dev/null | grep -q "found"; then
      return 0
    fi
    sleep 3
  done
  echo "!! package/input_method services not up" >&2
  return 1
}

install_retry() {
  local apk="$1"
  for i in 1 2 3 4 5; do
    if $ADB install -r --no-streaming "$apk"; then
      return 0
    fi
    echo "!! install attempt $i failed for $apk; re-waiting for device/services" >&2
    $ADB wait-for-device || true
    wait_services || true
    sleep 10
  done
  echo "!! could not install $apk after 5 attempts" >&2
  return 1
}

discover_ime() {
  local match="$1" out="" all=""
  for _ in $(seq 1 20); do
    all=$($ADB shell ime list -s -a 2>/dev/null | tr -d '\r' || true)
    if [ -n "$all" ]; then
      out=$(printf '%s\n' "$all" | grep -i "$match" || true)
      out=${out%%$'\n'*}
      if [ -n "$out" ]; then
        printf '%s' "$out"
        return 0
      fi
    fi
    sleep 3
  done
  echo "!! no IME matching '$match' after 20 tries; last 'ime list -s -a' output:" >&2
  printf '%s\n' "$all" >&2
  echo "!! installed packages matching IME vendors:" >&2
  $ADB shell pm list packages | tr -d '\r' | grep -iE 'spanak|nyanya|ashivered' >&2 || true
  return 1
}

start_harness() {
  $ADB shell am force-stop dev.mbaiforinstinct.f21os || true
  $ADB shell am start -W -n dev.mbaiforinstinct.f21os/.ImeHarnessActivity
  sleep 3
}

anr_up() {
  # ANR/error dialogs are owned by WindowManager, not SystemUI, so dumpsys stays reliable
  # even when SystemUI is wedged (uiautomator dump fails exactly then).
  $ADB shell dumpsys window windows 2>/dev/null | tr -d '\r' | grep -iE 'mCurrentFocus|mFocusedApp' | grep -qiE 'not responding|application error'
}

dismiss_anr() {
  anr_up || return 0
  local xml x1 y1 x2 y2 line
  xml=$($ADB shell uiautomator dump /sdcard/__f21_ui.xml >/dev/null 2>&1; $ADB shell cat /sdcard/__f21_ui.xml 2>/dev/null || true)
  line=$(printf '%s' "$xml" | tr '<' '\n' | grep 'text="Wait"' | head -n 1 || true)
  x1=$(printf '%s' "$line" | sed -n 's/.*bounds="\[\([0-9]*\),\([0-9]*\)\]\[\([0-9]*\),\([0-9]*\)\]".*/\1/p')
  y1=$(printf '%s' "$line" | sed -n 's/.*bounds="\[\([0-9]*\),\([0-9]*\)\]\[\([0-9]*\),\([0-9]*\)\]".*/\2/p')
  x2=$(printf '%s' "$line" | sed -n 's/.*bounds="\[\([0-9]*\),\([0-9]*\)\]\[\([0-9]*\),\([0-9]*\)\]".*/\3/p')
  y2=$(printf '%s' "$line" | sed -n 's/.*bounds="\[\([0-9]*\),\([0-9]*\)\]\[\([0-9]*\),\([0-9]*\)\]".*/\4/p')
  if [ -n "$x1" ] && [ -n "$x2" ] && [ "$x1" -lt 480 ] && [ "$x2" -le 480 ] && [ "$y1" -lt 640 ] && [ "$y2" -le 640 ]; then
    echo "!! ANR dialog up; tapping Wait at ($(( (x1+x2)/2 )),$(( (y1+y2)/2 )))" >&2
    $ADB shell input tap $(( (x1+x2)/2 )) $(( (y1+y2)/2 )) || true
  else
    # uiautomator failed or returned garbage; blind-tap the fixed Wait-row position (480x640 dialog layout)
    echo "!! ANR dialog up; blind-tapping Wait at (240,445)" >&2
    $ADB shell input tap 240 445 || true
  fi
  sleep 2
}

shot() {
  local i
  for i in 1 2 3 4 5 6; do
    anr_up || break
    dismiss_anr || true
  done
  anr_up && echo "!! ANR dialog still up before $1; capturing anyway" >&2
  $ADB exec-out screencap -p > "$1"
}

wait_boot
wait_services
# Suppress ANR/crash dialogs (System UI ANR'd under swiftshader in run #9 and a
# modal dialog ate every stage screenshot) and let SystemUI settle after boot.
$ADB shell settings put global hide_error_dialogs 1 || true
$ADB shell settings put global anr_show_background 1 || true
sleep 30
echo "== emulator booted, services up, error dialogs suppressed"

run_ime() {
  local name="$1" match="$2"
  local apk
  apk=$(find "imes/$name" -name '*.apk')
  apk=${apk%%$'\n'*}
  echo "== $name apk: $apk"
  install_retry "$apk"
  sleep 2
  if [ "$name" = "qinboard" ]; then
    $ADB shell appops set aiv.ashivered.qinboard.t9 MANAGE_EXTERNAL_STORAGE allow || true
    $ADB shell pm grant aiv.ashivered.qinboard.t9 android.permission.WRITE_EXTERNAL_STORAGE || true
  fi
  local imeid
  imeid=$(discover_ime "$match")
  echo "== $name ime id: $imeid"
  $ADB shell ime enable "$imeid"
  $ADB shell ime set "$imeid"
  echo "== $name active ime: $($ADB shell settings get secure default_input_method | tr -d '\r')"
  sleep 10
  dismiss_anr || true
  dismiss_anr || true
  install_retry app/build/outputs/apk/debug/app-debug.apk
  start_harness
  shot "screenshots-t9/$name-01-harness.png"
  # Stage 2: multi-tap attempt - "hi" (44 then 444, pauses to commit letters)
  $ADB shell input keyevent KEYCODE_4; sleep 0.3
  $ADB shell input keyevent KEYCODE_4; sleep 1.6
  $ADB shell input keyevent KEYCODE_4; sleep 0.3
  $ADB shell input keyevent KEYCODE_4; sleep 0.3
  $ADB shell input keyevent KEYCODE_4; sleep 1.6
  shot "screenshots-t9/$name-02-multitap-hi.png"
  # Stage 3: predictive attempt on a clean field - 43556 ("hello" in T9)
  start_harness
  $ADB shell input keyevent KEYCODE_4; sleep 0.3
  $ADB shell input keyevent KEYCODE_3; sleep 0.3
  $ADB shell input keyevent KEYCODE_5; sleep 0.3
  $ADB shell input keyevent KEYCODE_5; sleep 0.3
  $ADB shell input keyevent KEYCODE_6; sleep 1.0
  shot "screenshots-t9/$name-03-predict-43556.png"
  # Stage 4: backspace behaviour
  $ADB shell input keyevent KEYCODE_DEL; sleep 0.6
  shot "screenshots-t9/$name-04-del.png"
  # Stage 5: mode-switch key behaviour (POUND)
  $ADB shell input keyevent KEYCODE_POUND; sleep 0.6
  shot "screenshots-t9/$name-05-pound.png"
  $ADB shell am force-stop dev.mbaiforinstinct.f21os
}

run_ime tt9 sspanak
run_ime qinboard nyanya
echo "T9 proof capture complete"
ls -la screenshots-t9/
