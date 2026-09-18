# F21 OS

A key-first Android system for the Xiaomi Qin F21 Pro, using the interaction discipline of the Nokia C2-01: explicit softkeys, predictable D-pad navigation, fast calling and messaging, and a full-screen 480x640 interface.

This is an independent, unofficial project. It is not affiliated with Xiaomi, Duoqin, Nokia, HMD Global or LineageOS.

## Current milestone

- Native Android HOME activity scaffold
- S40-style idle screen and 3x3 menu shell
- Hardware D-pad and centre-key navigation
- Design baseline and physical-flash safety gates
- ROM integration workspace

## Planned stack

- LineageOS 18.1 GSI, arm64 A/B vndklite
- F21 treble compatibility patches
- F21 OS launcher and key-first system layer
- Traditional T9 or QinBoard-T9 after emulator comparison
- Reproducible image packaging with pinned revisions

See [docs/DESIGN.md](docs/DESIGN.md).

## Development status

Early emulator-first scaffold. Do not flash this repository to a phone yet.

## Build

```bash
./gradlew clean assembleDebug
```

CI runs the same clean build on every push and uploads the debug APK as an Actions artifact. `tools/emulator-proof.sh` installs the APK on a running emulator and captures the idle screen, menu, and D-pad navigation proof at `screenshots/`.
