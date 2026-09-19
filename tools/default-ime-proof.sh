#!/usr/bin/env bash
# Default-IME proof (emulator, data-side path).
# The /system remount+reboot injection hangs this AVD image: overlayfs activation
# reboot never returns to adbd (run 35467568949, cancelled). So CI proves the
# ACTIVATION mechanism instead:
#   tt9 + launcher installed as data apps, WRITE_SECURE_SETTINGS granted via adb
#   (standing in for the privapp allowlist), the setup receiver run, then verify
#   default_input_method=tt9 with NO manual enable and tt9 binding in the harness.
# The image-time injection (rom/scripts/inject-f21-apps.sh) is validated
# statically in CI and verified on the real GSI build (hardware item).
set -euo pipefail
ADB=${ADB:-adb}
TT9_ID="io.github.sspanak.tt9/.ime.TraditionalT9"
APP_PKG="dev.mbaiforinstinct.f21os"
mkdir -p screenshots-ime

wait_boot() {
  local tries=${1:-90} bc=""
  for _ in $(seq 1 "$tries"); do
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

restart_systemui() {
  local pid
  pid=$($ADB shell pidof com.android.systemui 2>/dev/null | tr -d '\r' || true)
  if [ -n "$pid" ]; then
    echo "== restarting SystemUI (pid $pid)" >&2
    $ADB shell kill "$pid" 2>/dev/null || true
    sleep 12
    wait_services || true
  fi
}

wait_boot
wait_services
$ADB shell settings put global hide_error_dialogs 1 || true
sleep 20
$ADB root >/dev/null 2>&1 || true
$ADB wait-for-device
wait_services
restart_systemui

echo "== installing tt9 and the launcher (data-side proof path)"
tt9apk=$(find imes/tt9 -name '*.apk' | head -n 1)
$ADB install -r --no-streaming "$tt9apk"
$ADB install -r --no-streaming app/build/outputs/apk/debug/app-debug.apk

echo "== granting WRITE_SECURE_SETTINGS (stands in for the privapp allowlist)"
$ADB shell pm grant "$APP_PKG" android.permission.WRITE_SECURE_SETTINGS
$ADB shell dumpsys package "$APP_PKG" | tr -d '\r' \
  | grep -q 'android.permission.WRITE_SECURE_SETTINGS: granted=true' \
  || { echo '!! WRITE_SECURE_SETTINGS grant failed' >&2; exit 1; }
echo "grant ok"

echo "== delivering BOOT_COMPLETED to the setup receiver"
$ADB shell am broadcast -a android.intent.action.BOOT_COMPLETED -p "$APP_PKG" || true
sleep 3
echo "== launching the launcher once (MainActivity runs the same setup)"
$ADB shell am start -W -n "$APP_PKG/.MainActivity" || true
sleep 5

echo "== verifying the default IME was applied with no manual enable"
def=""
for _ in $(seq 1 12); do
  def=$($ADB shell settings get secure default_input_method | tr -d '\r')
  [ "$def" = "$TT9_ID" ] && break
  sleep 5
done
[ "$def" = "$TT9_ID" ] || { echo "!! default_input_method=$def (want $TT9_ID)" >&2; exit 1; }
en=$($ADB shell settings get secure enabled_input_methods | tr -d '\r')
echo "enabled_input_methods=$en"
echo "$en" | grep -q "$TT9_ID" || { echo '!! tt9 not in enabled_input_methods' >&2; exit 1; }
echo "default_input_method=$def"

echo "== driving the harness: tt9 must bind as the current IME"
$ADB shell am force-stop "$APP_PKG" || true
$ADB shell am start -W -n "$APP_PKG/.ImeHarnessActivity"
sleep 8
ime_dump=$($ADB shell dumpsys input_method | tr -d '\r')
printf '%s\n' "$ime_dump" | grep -E 'mCurMethodId|mCurId' || true
printf '%s\n' "$ime_dump" | grep -q "$TT9_ID" || { echo '!! tt9 is not the current input method' >&2; exit 1; }
$ADB shell input keyevent KEYCODE_4; sleep 0.3
$ADB shell input keyevent KEYCODE_4; sleep 0.3
sleep 1
restart_systemui
$ADB exec-out screencap -p > screenshots-ime/default-ime-harness.png
echo "== PROOF OK: app-applied default IME = tt9 with no manual enable"
