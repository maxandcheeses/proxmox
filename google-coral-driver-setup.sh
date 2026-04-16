#!/usr/bin/env bash
set -eo pipefail

# Remove broken or existing gasket-dkms apt package if present
if dpkg -l | grep -q "gasket-dkms"; then
    echo "Removing existing gasket-dkms package..."
    dpkg --remove --force-remove-reinstreq gasket-dkms || true
    apt-get remove -y gasket-dkms 2>/dev/null || true
fi

# Install build dependencies
# Try pve-headers first (PVE kernel), fall back to linux-headers (Debian stock kernel)
echo "Installing build dependencies..."
apt-get install -y pve-headers-$(uname -r) || \
    apt-get install -y linux-headers-$(uname -r)
apt-get install -y dkms dh-dkms build-essential devscripts git

# Clone patched gasket driver (fixes kernel 6.6+ API incompatibilities)
echo "Cloning patched gasket driver..."
rm -rf gasket-driver
git clone https://github.com/maxandcheeses/gasket-driver.git
cd gasket-driver
debuild -us -uc -tc -b
cd ..

# Move .deb to /tmp so apt can access it without root sandboxing warning
mv gasket-dkms_*_all.deb /tmp/
apt-get install -y /tmp/gasket-dkms_*_all.deb

# Cleanup
rm -f /tmp/gasket-dkms_*_all.deb
rm -rf gasket-driver gasket_* gasket-dkms_*.buildinfo gasket-dkms_*.changes

echo "Done. A full reboot is recommended."
