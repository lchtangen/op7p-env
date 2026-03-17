#!/bin/bash
# root-enter.sh — Enter Ubuntu chroot as root from Termux
# Run from Termux: su -c "bash /path/to/root-enter.sh"
# Or from Android ADB: adb shell su -c "bash ..."
#
# This script finds the Ubuntu chroot path and enters it as root,
# allowing sudo and sysfs writes that are blocked in user chroot sessions.

UBUNTU_ROOT=""

# Common chroot/proot locations
for path in \
    /data/local/ubuntu \
    /data/user/0/com.termux/files/usr/var/lib/proot-distro/installed-rootfs/ubuntu \
    /data/data/com.termux/files/usr/var/lib/proot-distro/installed-rootfs/ubuntu \
    /data/local/tmp/ubuntu \
    /mnt/sdcard/ubuntu; do
    if [ -d "${path}/usr" ] && [ -d "${path}/etc" ]; then
        UBUNTU_ROOT="$path"
        break
    fi
done

if [ -z "$UBUNTU_ROOT" ]; then
    echo "Ubuntu chroot not found. Check common paths above."
    echo "Set UBUNTU_ROOT manually: UBUNTU_ROOT=/your/path bash root-enter.sh"
    exit 1
fi

echo "Ubuntu root: $UBUNTU_ROOT"
echo "Entering chroot as root..."

# Mount required filesystems
mount --bind /dev     "${UBUNTU_ROOT}/dev"     2>/dev/null
mount --bind /dev/pts "${UBUNTU_ROOT}/dev/pts" 2>/dev/null
mount --bind /proc    "${UBUNTU_ROOT}/proc"    2>/dev/null
mount --bind /sys     "${UBUNTU_ROOT}/sys"     2>/dev/null
mount --bind /data    "${UBUNTU_ROOT}/data"    2>/dev/null

# Enter chroot as root
chroot "$UBUNTU_ROOT" /bin/bash -c "
    export HOME=/root
    export USER=root
    export TERM=xterm-256color
    export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
    cd /root
    exec /bin/bash --login
"
