# Unlock, flash and restore runbook

This runbook is intentionally staged. Do not cross a stage unless its checks pass.

## 0. Confirm the hardware

Run `rom/scripts/verify-device.sh`. The platform must be MT6761. Do not use this on the MT8766 F21 Pro+.

## 1. Prepare

- Use a known-good data cable and a charged battery.
- Install MTKClient and its USB dependencies from its official repository.
- Keep F21 OS files and stock files in separate directories.
- Record the serial, Android build number, storage/RAM variant and active slot.

## 2. Mandatory full stock dump

Before unlocking or flashing, use MTKClient to read the GPT and every partition into a private `stock-dump` directory. The exact MTKClient command must be taken from the installed version's current help, because command syntax can change. Do not paste a command from an old guide without checking.

After the read:

```bash
rom/scripts/hash-stock-dump.sh /path/to/stock-dump
```

Copy the dump and `SHA256SUMS` to two separate storage locations. Verify both copies. The dump is private and must never be committed.

## 3. Unlock

Use MTKClient's current bootloader unlock path only after the dump is verified. Expect a data wipe. Reboot to stock once and confirm the phone still starts before flashing a system image.

## 4. Flash F21 OS

- Confirm the package manifest matches MT6761 and the recorded partition layout.
- Confirm image hashes.
- Confirm the active/inactive A/B slot.
- Flash only the documented system-related images. Never guess at preloader, nvram, nvdata, protect or modem partitions.
- First boot may take several minutes. Stop rather than repeatedly power-cycling.

## 5. Hardware test

Test keypad keycodes, calls, SMS, mobile data, Wi-Fi, Bluetooth, audio in/out, camera, charging, sleep/wake, touchscreen and both slots. Preserve logs for every failure.

## 6. Restore

If the device does not boot or core hardware is broken, return to the known MTKClient connection state and write back only from the verified stock dump, following the installed MTKClient version's current restore syntax. Restore the original slot state, then boot stock and repeat the hardware test. Never source a preloader or NVRAM image from another handset.
