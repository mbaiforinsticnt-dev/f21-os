# ROM integration workspace

This directory holds pinned manifests, overlays, patch scripts and packaging notes for the LineageOS 18.1 GSI base. It deliberately contains no stock firmware or private keys.

Before touching hardware:

1. Confirm the device is the MT6761 F21 Pro, not the MT8766 F21 Pro+.
2. Dump every stock partition with MTKClient and retain checksums in private storage.
3. Record the active A/B slot and preserve the restore route.
4. Build and test the exact image in an Android emulator first.
