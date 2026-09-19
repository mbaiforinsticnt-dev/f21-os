#!/usr/bin/env bash
# Default-IME proof on the emulator: inject tt9 (system app), the launcher
# (priv-app) and the privapp allowlist into a writable system, reboot, and verify
# tt9 comes up as the DEFAULT input method with no manual enable.
# Expects: imes/tt9/*.apk, app/build/outputs/apk/debug/app-debug.apk,
# rom/prebuilts/privapp-permissions-f21os.xml. Emulator needs -writable-system.
set -euo pipefail
ADB=${ADB:-adb}
TT9_ID="io.github.sspanak.tt9/.ime.TraditionalT9"
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

echo "== remounting system writable"
remount_out=$($ADB remount 2>&1 || true)
printf '%s\n' "$remount_out"
# The first remount only STAGES the overlayfs; it takes effect after a reboot.
if printf '%s\n' "$remount_out" | grep -qi 'reboot'; then
  echo "== overlayfs staged; rebooting to activate it"
  $ADB reboot || true
  sleep 15
  $ADB wait-for-device
  # First boot with overlayfs active can take several minutes.
  wait_boot 180
  $ADB root >/dev/null 2>&1 || true
  $ADB wait-for-device
  wait_services
  remount_out=$($ADB remount 2>&1 || true)
  printf '%s\n' "$remount_out"
  sleep 3
fi
echo "== probing /system writability"
if ! $ADB shell 'touch /system/.f21w && rm /system/.f21w' >/dev/null 2>&1; then
  echo "!! /system still read-only after remount" >&2
  exit 1
fi

echo "== injecting apps into the system image"
tt9apk=$(find imes/tt9 -name '*.apk' | head -n 1)
$ADB shell mkdir -p /system/app/TraditionalT9 /system/priv-app/F21Launcher /system/etc/permissions
$ADB push "$tt9apk" /system/app/TraditionalT9/TraditionalT9.apk
$ADB push app/build/outputs/apk/debug/app-debug.apk /system/priv-app/F21Launcher/F21Launcher.apk
$ADB push rom/prebuilts/privapp-permissions-f21os.xml /system/etc/permissions/privapp-permissions-f21os.xml
$ADB shell chmod 0644 /system/app/TraditionalT9/TraditionalT9.apk \
  /system/priv-app/F21Launcher/F21Launcher.apk \
  /system/etc/permissions/privapp-permissions-f21os.xml
$ADB shell sync

echo "== rebooting into the injected image"
$ADB reboot || true
wait_boot
wait_services
$ADB root >/dev/null 2>&1 || true
$ADB wait-for-device
wait_services
restart_systemui
echo "== letting PackageManager settle and BOOT_COMPLETED receivers run"
sleep 20

echo "== verifying tt9 is installed as a system app"
path=$($ADB shell pm path io.github.sspanak.tt9 | tr -d '\r')
echo "$path"
echo "$path" | grep -q '/system/app/TraditionalT9/' || { echo '!! tt9 not installed from /system/app' >&2; exit 1; }

echo "== verifying launcher holds WRITE_SECURE_SETTINGS via the privapp allowlist"
$ADB shell dumpsys package dev.mbaiforinstinct.f21os | tr -d '\r' \
  | grep -q 'android.permission.WRITE_SECURE_SETTINGS: granted=true' \
  || { echo '!! WRITE_SECURE_SETTINGS not granted to the launcher' >&2; exit 1; }
echo "launcher holds WRITE_SECURE_SETTINGS"

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
$ADB shell am force-stop dev.mbaiforinstinct.f21os || true
$ADB shell am start -W -n dev.mbaiforinstinct.f21os/.ImeHarnessActivity
sleep 8
ime_dump=$($ADB shell dumpsys input_method | tr -d '\r')
printf '%s\n' "$ime_dump" | grep -E 'mCurMethodId|mCurId|mCurrentFocus' || true
printf '%s\n' "$ime_dump" | grep -q "$TT9_ID" || { echo '!! tt9 is not the current input method' >&2; exit 1; }
$ADB shell input keyevent KEYCODE_4; sleep 0.3
$ADB shell input keyevent KEYCODE_4; sleep 0.3
sleep 1
restart_systemui
$ADB exec-out screencap -p > screenshots-ime/default-ime-harness.png
echo "== PROOF OK: tt9 system app + launcher priv-app + default IME with no manual enable"
