#!/usr/bin/env bash
set -euo pipefail
ADB=${ADB:-adb}
mkdir -p screenshots
$ADB install -r app/build/outputs/apk/debug/app-debug.apk
$ADB shell am start -a android.intent.action.MAIN -c android.intent.category.HOME -n dev.mbaiforinstinct.f21os/.MainActivity
# Let the first activity frame settle before checking platform services.
sleep 5
# Some CI images report boot complete before input/display services are published.
for _ in $(seq 1 60); do
  $ADB shell service check input 2>/dev/null | grep -q "found" && break
  sleep 1
done
$ADB shell service check input | grep -q "found"
# Dismiss the headless-emulator watchdog by choosing Wait, never Close app.
$ADB shell input tap 300 440 || true
sleep 2
# Fail if a platform error dialog still owns the focused window.
focus=$($ADB shell dumpsys window windows | grep -m1 'mCurrentFocus' || true)
echo "$focus"
[[ "$focus" == *dev.mbaiforinstinct.f21os* ]]
$ADB exec-out screencap -p > screenshots/idle.png
$ADB shell input keyevent KEYCODE_DPAD_CENTER
sleep 1
$ADB exec-out screencap -p > screenshots/menu.png
$ADB shell input keyevent KEYCODE_DPAD_RIGHT
$ADB shell input keyevent KEYCODE_DPAD_DOWN
sleep 1
$ADB exec-out screencap -p > screenshots/menu-key-navigation.png
