# F21 OS hardware-ready package manifest

The final hardware-ready bundle contains:

- `f21-os-launcher.apk` built from this repository.
- A pinned LineageOS 18.1 arm64 A/B vndklite GSI source image checksum and provenance record.
- The reviewed F21 treble patch set with pinned commit SHA.
- Debloat list and image-time debloat script.
- Product overlays and launcher provisioning script.
- Unlock/flash/restore runbook.
- Stock dump hash helper and MT6761 guard.
- Image and bundle SHA256 sums.

The GSI binary is not committed here. `rom/assemble-package.sh` will fail closed until the approved upstream image and patch inputs are present and checksummed.
