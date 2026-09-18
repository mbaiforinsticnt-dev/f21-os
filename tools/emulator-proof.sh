#!/usr/bin/env bash
set -euo pipefail
ADB=${ADB:-adb}
mkdir -p screenshots
$ADB install -r app/build/outputs/apk/debug/app-debug.apk
$ADB shell am start -a android.intent.action.MAIN -c android.intent.category.HOME -n dev.mbaiforinstinct.f21os/.MainActivity
sleep 2
# Some CI images report boot complete before input/display services are published.
for _ in $(seq 1 60); do
  $ADB shell service check input 2>/dev/null | grep -q "found" && break
  sleep 1
done
$ADB shell service check input | grep -q "found"
$ADB exec-out screencap -p > screenshots/idle.png
$ADB shell input keyevent KEYCODE_DPAD_CENTER
sleep 1
$ADB exec-out screencap -p > screenshots/menu.png
$ADB shell input keyevent KEYCODE_DPAD_RIGHT
$ADB shell input keyevent KEYCODE_DPAD_DOWN
sleep 1
$ADB exec-out screencap -p > screenshots/menu-key-navigation.png
