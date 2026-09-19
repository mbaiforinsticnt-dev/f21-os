# ROM integration workspace

This directory holds pinned manifests, overlays, patch scripts and packaging notes for the LineageOS 18.1 GSI base. It deliberately contains no stock firmware or private keys.

Before touching hardware:

1. Confirm the device is the MT6761 F21 Pro, not the MT8766 F21 Pro+.
2. Dump every stock partition with MTKClient and retain checksums in private storage.
3. Record the active A/B slot and preserve the restore route.
4. Build and test the exact image in an Android emulator first.

## Default keyboard (Traditional T9)

The F21 OS keyboard is Traditional T9 (`sspanak/tt9`, pinned in `UPSTREAMS.lock`), chosen in the September 2026 emulator comparison over QinBoard-T9 (Apache-2.0 vs a commercial-use-prohibited custom license, active maintenance, upstream F21 Pro testing).

- `rom/scripts/fetch-tt9.sh` builds the pinned APK with English-only dictionaries (about 9.8MB; the upstream full flavor bundles 50+ languages at about 255MB).
- `rom/scripts/inject-f21-apps.sh` places it at `/system/app/TraditionalT9/` in the system image - a system ("secure") app, which InputMethodManagerService requires of a default IME - plus the launcher at `/system/priv-app/F21Launcher/` and `rom/prebuilts/privapp-permissions-f21os.xml` at `/system/etc/permissions/`.
- The launcher's `BootSetupReceiver` (and `MainActivity`) applies the default-IME setup on every boot through the allowlisted `WRITE_SECURE_SETTINGS`: tt9 is appended to `enabled_input_methods` and set as `default_input_method`. No manual enable on first boot, and the choice self-heals.
- `rom/assemble-package.sh` runs the fetch and ships the APK plus the allowlist in the bundle.
- CI proof: `.github/workflows/default-ime.yml` statically validates the injection payloads (tt9 APK, launcher APK, privapp allowlist), installs them data-side in an emulator, and verifies tt9 is enabled, set as `default_input_method` and bound as the current IME with zero manual steps. /system injection into the real GSI is verified during image assembly and on hardware.
