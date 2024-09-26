. .env
umount /mnt/pve/$SMB_SHARE
pvesm set $SMB_SHARE --disable
pvesm set $SMB_SHARE --disable 0
