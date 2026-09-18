# F21 OS design baseline

## Goal

Turn the Xiaomi Qin F21 Pro into a key-first phone whose everyday behaviour follows the Nokia C2-01 rather than a touch-first Android launcher. The first release is a LineageOS 18.1 GSI base, a custom home and system-app layer, an F21-tuned T9 input method, and a reproducible flash package. Emulator work is provisional until checked on the physical phone.

## Evidence order

1. Moti's physical Nokia C2-01 and his recordings.
2. The frozen C2 Reborn v4.89 implementation and its evidence ledger.
3. The matching Series 40 emulator.
4. Third-party descriptions only as leads.

Do not remove a proven C2 behaviour without asking. Improvements can be added, but they must not make the key-first path slower.

## Behaviours to carry over

### Idle and navigation
- S40-style idle screen with clear time, date, signal, battery and persistent unread state.
- Left, centre and right softkey labels always state what those keys do.
- Centre key opens the 3x3 menu grid. Direction keys wrap predictably.
- Left softkey `Options` is the context menu on every screen.
- Common actions take no more than four key presses.
- Touch remains a fallback, not the primary path.

### Calls
- A missed call raises a full-screen notice that remains until dismissed.
- Calling from that notice calls the missed number directly.
- Profiles include Nokia-style ringing choices, including a rising ring.
- Call log and contacts are reachable from the idle screen without opening Android settings.

### Messaging
- `Conversations` is the primary view, with Inbox view still available.
- New message supports `New number` without forcing contact creation.
- Persistent unread symbol survives returning home.
- Composer is usable blind from the hardware keypad.
- Messaging options preserve: Conversations, New message, Inbox view, Message log, SIM messages and Memory status where the Android/telephony stack can support them.

### Media and organiser
- Gallery opens with Photos, Music & videos, and All content.
- Organiser contains alarm, calendar, notes, calculator, timer, stopwatch and countdown paths.
- Each app has correct softkeys and complete Options commands rather than placeholder routes.

## F21 hardware mapping hypothesis

This mapping must be measured on the real MT6761 F21 Pro before it becomes final.

| F21 input | F21 OS action |
|---|---|
| D-pad | move focus / scroll |
| Centre | Select |
| Left softkey | Options / Go to |
| Right softkey | Back / Exit / Names by screen |
| Green call | open dialler or call selected number |
| Red end | end call; return home when idle |
| 0-9, *, # | T9, shortcuts and dialling |
| Touch | fallback activation and accessibility |

## Architecture

- Base: LineageOS 18.1 GSI for arm64 A/B, vndklite variant, plus the known F21 treble patches.
- Product layer: launcher/home activity, dialler and messaging integration, system overlays, boot animation, sounds, fonts and profile defaults.
- Input: evaluate Traditional T9 (`sspanak/tt9`) first because it includes F21-specific work; keep QinBoard-T9 as the hardware-focused comparison.
- Packaging: pinned upstream SHAs, deterministic patch scripts, checksums and a recovery/restore guide. Never distribute proprietary stock images.
- Privacy: no personal names, phone numbers, keys or account details in source, build logs or screenshots.

## Release gates

1. Emulator boots at 480x640 and launcher is the HOME activity.
2. Every screen works with D-pad, centre, softkeys, Back and keypad alone.
3. Idle, menu, calls and messaging are compared move-for-move against C2 evidence.
4. Full stock ROM dump and checksum are captured before the first physical flash.
5. Exact device variant is confirmed as MT6761. Stop if it is the MT8766 Pro+.
6. Boot and partition slot are checked before any write; recovery path is tested first.
7. Hardware keycodes, modem, audio, camera, charging, Bluetooth, Wi-Fi and suspend are verified on-device.

## First implementation slice

The repository starts with a native Android HOME activity rather than ROM packaging. This gives us a fast, emulator-testable loop for the product-defining idle screen, menu grid and key handling. ROM manifests and patch scripts follow once the launcher interaction baseline is stable.
