#!/usr/bin/env bash
set -euo pipefail
ADB=${ADB:-adb}
mkdir -p screenshots-t9
for _ in $(seq 1 60); do
  $ADB shell service check package 2>/dev/null | grep -q "found" && break
  sleep 2
done
$ADB shell service check package | grep -q "found"

run_ime() {
  local name="$1" match="$2"
  local apk
  apk=$(find "imes/$name" -name '*.apk' | head -n 1)
  echo "== $name apk: $apk"
  for _ in 1 2 3; do
    $ADB install -r "$apk" && break
    sleep 5
  done
  sleep 2
  if [ "$name" = "qinboard" ]; then
    $ADB shell appops set aiv.ashivered.qinboard.t9 MANAGE_EXTERNAL_STORAGE allow || true
    $ADB shell pm grant aiv.ashivered.qinboard.t9 android.permission.WRITE_EXTERNAL_STORAGE || true
  fi
  local imeid
  imeid=$($ADB shell ime list -s | tr -d '\r' | grep -i "$match" | head -n 1)
  echo "== $name ime id: $imeid"
  $ADB shell ime enable "$imeid"
  $ADB shell ime set "$imeid"
  for _ in 1 2 3; do
    $ADB install -r app/build/outputs/apk/debug/app-debug.apk && break
    sleep 5
  done
  $ADB shell am start -W -n dev.mbaiforinstinct.f21os/.ImeHarnessActivity
  sleep 3
  $ADB exec-out screencap -p > "screenshots-t9/$name-01-harness.png"
  # Stage 2: multi-tap attempt - "hi" (44 then 444, pauses to commit letters)
  $ADB shell input keyevent KEYCODE_4; sleep 0.3
  $ADB shell input keyevent KEYCODE_4; sleep 1.6
  $ADB shell input keyevent KEYCODE_4; sleep 0.3
  $ADB shell input keyevent KEYCODE_4; sleep 0.3
  $ADB shell input keyevent KEYCODE_4; sleep 1.6
  $ADB exec-out screencap -p > "screenshots-t9/$name-02-multitap-hi.png"
  # Stage 3: predictive attempt - 43556 ("hello" in T9)
  $ADB shell input keyevent KEYCODE_4; sleep 0.3
  $ADB shell input keyevent KEYCODE_3; sleep 0.3
  $ADB shell input keyevent KEYCODE_5; sleep 0.3
  $ADB shell input keyevent KEYCODE_5; sleep 0.3
  $ADB shell input keyevent KEYCODE_6; sleep 1.0
  $ADB exec-out screencap -p > "screenshots-t9/$name-03-predict-43556.png"
  # Stage 4: backspace behaviour
  $ADB shell input keyevent KEYCODE_DEL; sleep 0.6
  $ADB exec-out screencap -p > "screenshots-t9/$name-04-del.png"
  # Stage 5: mode-switch key behaviour (POUND)
  $ADB shell input keyevent KEYCODE_POUND; sleep 0.6
  $ADB exec-out screencap -p > "screenshots-t9/$name-05-pound.png"
  $ADB shell am force-stop dev.mbaiforinstinct.f21os
}

run_ime tt9 sspanak
run_ime qinboard nyanya
echo "T9 proof capture complete"
ls -la screenshots-t9/
