# F21 OS hardware-ready package manifest

The final hardware-ready bundle contains:

- `images/f21-os-patched-lineage18.1-vndklite.img`: the LineageOS 18.1 arm64 A/B vndklite GSI after assembly-time mutation - F21 bluetooth and devinputjack overlays at `/vendor/overlay/`, the debloat list applied, Traditional T9 at `/system/app/TraditionalT9/` (a system "secure" app, which InputMethodManagerService requires of a default IME), the launcher at `/system/priv-app/F21Launcher/`, and the privapp allowlist at `/system/etc/permissions/`.
- `tools/`: the assembly and device scripts (`apply-f21-patches.sh`, `debloat-image.sh`, `inject-f21-apps.sh`, `fetch-tt9.sh`, `hash-stock-dump.sh`, `verify-device.sh`).
- `debloat-packages.txt`: the reviewed debloat list. Gallery, Music, Calendar, DeskClock and Calculator stay in the image because the launcher bridges to them.
- `docs/`: the unlock/flash/restore runbook and buying guide.
- `SHA256SUMS` covering every bundle file, plus the gzipped tarball and its own SHA256.

`rom/assemble-package.sh` fails closed: it verifies the locked GSI checksum before use, converts a sparse image only when simg2img is present, and refuses to package unless every injected payload verifies inside the patched image. The GSI binary is not committed here.
