# F21 OS hardware-ready package manifest

The final hardware-ready bundle contains:

- `f21-os-launcher.apk` built from this repository.
- `images/TraditionalT9.apk`: the default keyboard, built from the pinned sspanak/tt9 commit with English-only dictionaries by `rom/scripts/fetch-tt9.sh`. Injected at flash time to `/system/app/TraditionalT9/` by `rom/scripts/inject-f21-apps.sh`, which also installs the launcher as a priv-app and the allowlist below.
- `images/privapp-permissions-f21os.xml`: privapp allowlist granting the launcher `WRITE_SECURE_SETTINGS` so it can apply (and self-heal) the default-IME setting on boot.
- A pinned LineageOS 18.1 arm64 A/B vndklite GSI source image checksum and provenance record.
- The reviewed F21 treble patch set with pinned commit SHA.
- Debloat list and image-time debloat script.
- Product overlays and launcher provisioning script.
- Unlock/flash/restore runbook.
- Stock dump hash helper and MT6761 guard.
- Image and bundle SHA256 sums.

The GSI binary is not committed here. `rom/assemble-package.sh` will fail closed until the approved upstream image and patch inputs are present and checksummed.
