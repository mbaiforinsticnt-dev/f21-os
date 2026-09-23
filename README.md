# F21 OS

A key-first Android system for the Xiaomi Qin F21 Pro, using the interaction discipline of the Nokia C2-01: explicit softkeys, predictable D-pad navigation, fast calling and messaging, and a full-screen 480x640 interface.

This is an independent, unofficial project. It is not affiliated with Xiaomi, Duoqin, Nokia, HMD Global or LineageOS.

## Current milestone

- Functional key-first launcher: S40-style idle screen, 3x3 menu, hardware D-pad and centre-key navigation, working detail screens and numeric entry
- Service bridge into Android facilities: contacts view and add, call log, messaging app and new-message composer, gallery, music, alarms, calendar and settings. Green-call-key dial flow: call log from idle, dial the entered number from a detail screen, dialler from anywhere else
- Hardware-ready ROM package assembled and checksummed: LineageOS 18.1 arm64_bvS-vndklite GSI with F21 treble overlays and the launcher provisioned at /system/priv-app/F21OS (see rom/PACKAGE-MANIFEST.md)
- Design baseline and physical-flash safety gates

## Stack

- LineageOS 18.1 GSI, arm64 A/B vndklite, pinned in rom/UPSTREAMS.lock
- F21 treble compatibility patches, pinned commit
- F21 OS launcher and key-first system layer
- T9 input method: Traditional T9 or QinBoard-T9 after emulator comparison
- Reproducible image packaging with pinned revisions

See [docs/DESIGN.md](docs/DESIGN.md).

## Development status

The launcher is emulator-verified in CI on every push (480x640 idle, menu and D-pad navigation screenshots under `screenshots/`). The hardware-ready package is assembled and checksummed. Flashing is only for an MT6761 Qin F21 Pro, only per docs/UNLOCK-FLASH-RESTORE.md, and only after a complete verified stock dump. Physical hardware validation (keylayout, modem, calls, SMS, camera, audio, radio) is pending a real handset.

## Build

```bash
./gradlew clean assembleDebug
```

CI runs the same clean build on every push and uploads the debug APK as an Actions artifact. `tools/emulator-proof.sh` installs the APK on a running emulator and captures the idle screen, menu, and D-pad navigation proof at `screenshots/`.
