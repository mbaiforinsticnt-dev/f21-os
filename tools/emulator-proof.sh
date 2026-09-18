#!/usr/bin/env bash
set -euo pipefail
ADB=${ADB:-adb}
mkdir -p screenshots
for _ in $(seq 1 60); do
  $ADB shell service check package 2>/dev/null | grep -q "found" && break
  sleep 2
done
$ADB shell service check package | grep -q "found"
for _ in 1 2 3; do
  $ADB install -r app/build/outputs/apk/debug/app-debug.apk && break
  sleep 5
done
$ADB shell pm path dev.mbaiforinstinct.f21os >/dev/null
for _ in 1 2 3; do
  $ADB install -r app/build/outputs/apk/androidTest/debug/app-debug-androidTest.apk && break
  sleep 5
done
$ADB shell pm path dev.mbaiforinstinct.f21os.test >/dev/null
$ADB shell am instrument -w dev.mbaiforinstinct.f21os.test/androidx.test.runner.AndroidJUnitRunner
for f in idle.png menu.png menu-key-navigation.png; do
  $ADB exec-out run-as dev.mbaiforinstinct.f21os cat "files/proof/$f" > "screenshots/$f"
done
