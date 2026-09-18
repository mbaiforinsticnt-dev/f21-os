#!/usr/bin/env bash
set -euo pipefail
ADB=${ADB:-adb}
echo "Model: $($ADB shell getprop ro.product.model | tr -d '\r')"
echo "SoC platform: $($ADB shell getprop ro.board.platform | tr -d '\r')"
echo "Hardware: $($ADB shell getprop ro.hardware | tr -d '\r')"
echo "AB update: $($ADB shell getprop ro.build.ab_update | tr -d '\r')"
echo "Dynamic partitions: $($ADB shell getprop ro.boot.dynamic_partitions | tr -d '\r')"
platform=$($ADB shell getprop ro.board.platform | tr -d '\r' | tr '[:upper:]' '[:lower:]')
[[ "$platform" == *mt6761* ]] || { echo 'STOP: this is not confirmed MT6761.' >&2; exit 3; }
