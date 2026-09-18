# Buying the correct Qin F21 Pro

## Required version

Buy only a Qin F21 Pro whose chipset is explicitly listed as MediaTek MT6761 / Helio A22. Do not buy the F21 Pro+ MT8766 version for this project.

## Before buying

Ask for a photograph of Android's device information or a hardware-info app showing `MT6761`, plus the phone's model label. Treat a title that says only “F21 Pro”, “global”, “Google”, “4/64” or “unlocked” as insufficient. Seller ROMs and memory sizes are not proof of the chipset.

## On arrival, before unlock

1. Do not accept an OTA update.
2. Enable developer options and USB debugging.
3. Run `rom/scripts/verify-device.sh` and confirm `ro.board.platform` contains `mt6761`.
4. Stop immediately if it reports MT8766 or anything else.
5. Make the complete stock dump before any flash operation.
