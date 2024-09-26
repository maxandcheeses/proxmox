#!/usr/bin/env bash
set -eo pipefail

. .env

for share in "${CIFS_SHARES[@]}"; do
  echo "unmounting $share"	
  umount /mnt/pve/$share || true
  pvesm set $share --disable
  pvesm set $share --disable 0
  echo "re-mounted $share"
done
echo "done."
