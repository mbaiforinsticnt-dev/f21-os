#!/usr/bin/env bash
set -euo pipefail
ADB=${ADB:-adb}
mkdir -p screenshots
$ADB install -r app/build/outputs/apk/debug/app-debug.apk
$ADB install -r app/build/outputs/apk/androidTest/debug/app-debug-androidTest.apk
$ADB shell am instrument -w dev.mbaiforinstinct.f21os.test/androidx.test.runner.AndroidJUnitRunner
for f in idle.png menu.png menu-key-navigation.png; do
  $ADB pull "/sdcard/Android/data/dev.mbaiforinstinct.f21os/files/proof/$f" "screenshots/$f"
done
