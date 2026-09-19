#!/usr/bin/env bash
# Injects F21 OS apps into a system image offline (debugfs), following the same
# pattern as apply-f21-patches.sh:
#   /system/app/TraditionalT9/TraditionalT9.apk    - default keyboard; a system
#     ("secure") app, which InputMethodManagerService requires for a default IME.
#   /system/priv-app/F21Launcher/F21Launcher.apk   - launcher; priv-app so its
#     allowlisted WRITE_SECURE_SETTINGS is granted for the default-IME setup.
#   /system/etc/permissions/privapp-permissions-f21os.xml - the allowlist.
set -euo pipefail
IMG=${1:?usage: inject-f21-apps.sh SYSTEM_IMAGE TT9_APK LAUNCHER_APK PRIVAPP_XML}
TT9=${2:?missing TraditionalT9.apk}
LAUNCHER=${3:?missing F21Launcher.apk}
XML=${4:?missing privapp-permissions-f21os.xml}
[[ -f "$IMG" && -f "$TT9" && -f "$LAUNCHER" && -f "$XML" ]] || { echo 'missing image or app payloads' >&2; exit 2; }
command -v debugfs >/dev/null
# GSI system images mount as / (system-as-root), so app paths live under /system.
d_mkdir() { debugfs -w -R "mkdir $1" "$IMG" >/dev/null 2>&1 || true; }
d_rm() { debugfs -w -R "rm $1" "$IMG" >/dev/null 2>&1 || true; }
d_put() { debugfs -w -R "write $1 $2" "$IMG"; debugfs -w -R "set_inode_field $2 mode 0100644" "$IMG" >/dev/null; }
d_mkdir /system/app; d_mkdir /system/app/TraditionalT9
d_mkdir /system/priv-app; d_mkdir /system/priv-app/F21Launcher
d_mkdir /system/etc; d_mkdir /system/etc/permissions
d_rm /system/app/TraditionalT9/TraditionalT9.apk
d_rm /system/priv-app/F21Launcher/F21Launcher.apk
d_rm /system/etc/permissions/privapp-permissions-f21os.xml
d_put "$TT9" /system/app/TraditionalT9/TraditionalT9.apk
d_put "$LAUNCHER" /system/priv-app/F21Launcher/F21Launcher.apk
d_put "$XML" /system/etc/permissions/privapp-permissions-f21os.xml
e2fsck -fy "$IMG"
echo "injected TraditionalT9 + F21Launcher + privapp allowlist into $IMG"
