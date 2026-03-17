# recovery/linux/ — Linux Recovery

Scripts and procedures for Linux disk and filesystem recovery.

---

## recovery.sh — Interactive Recovery Menu

```bash
recover                                    # alias
bash ~/recovery/linux/recovery.sh
```

**Menu options:**
1. Show connected drives (`lsblk`)
2. Mount USB drive
3. Clone disk (`dd` with progress)
4. Create/restore disk image
5. Filesystem check and repair (`fsck`)
6. Secure erase (dd zeros)
7. Windows PE tools (wimtools)
8. GRUB repair instructions
9. Network boot server (dnsmasq + TFTP)

---

## GRUB Repair (manual)

```bash
# Boot from live USB, then:
mount /dev/sdaX /mnt
mount --bind /dev /mnt/dev
mount --bind /proc /mnt/proc
mount --bind /sys /mnt/sys
chroot /mnt
grub-install /dev/sda
update-grub
exit
umount -R /mnt
```

---

## Disk Recovery with ddrescue

```bash
# First pass (fast, skip errors):
ddrescue /dev/sdX /path/recovered.img recovery.log

# Second pass (retry errors, reverse direction):
ddrescue -d -r3 /dev/sdX /path/recovered.img recovery.log

# Mount recovered image:
mount -o loop,offset=$(( 512 * START_SECTOR )) recovered.img /mnt
```
