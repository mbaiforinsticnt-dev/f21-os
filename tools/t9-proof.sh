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

wait_boot
wait_services
echo "== emulator booted, services up"

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
  install_retry app/build/outputs/apk/debug/app-debug.apk
  start_harness
  $ADB exec-out screencap -p > "screenshots-t9/$name-01-harness.png"
  # Stage 2: multi-tap attempt - "hi" (44 then 444, pauses to commit letters)
  $ADB shell input keyevent KEYCODE_4; sleep 0.3
  $ADB shell input keyevent KEYCODE_4; sleep 1.6
  $ADB shell input keyevent KEYCODE_4; sleep 0.3
  $ADB shell input keyevent KEYCODE_4; sleep 0.3
  $ADB shell input keyevent KEYCODE_4; sleep 1.6
  $ADB exec-out screencap -p > "screenshots-t9/$name-02-multitap-hi.png"
  # Stage 3: predictive attempt on a clean field - 43556 ("hello" in T9)
  start_harness
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
