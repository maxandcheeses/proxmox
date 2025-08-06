#!/usr/bin/env bash
set -eo pipefail

# Check if gasket-dkms is installed
if dpkg -l | grep -q "gasket-dkms"; then
    echo "gasket-dkms is installed."
else
    # Add Coral EdgeTPU APT repo and GPG key
    echo "Adding Coral EdgeTPU repository..."
    curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg -o /usr/share/keyrings/coral-edgetpu.gpg

    echo "deb [signed-by=/usr/share/keyrings/coral-edgetpu.gpg] https://packages.cloud.google.com/apt coral-edgetpu-stable main" \
        | tee /etc/apt/sources.list.d/coral-edgetpu.list > /dev/null

    apt-get update
    apt-get install -y dkms
fi

# Clone driver repo and build
rm -rf gasket-driver
git clone https://github.com/google/gasket-driver.git

apt-get remove -y gasket-dkms
apt-get install -y pve-headers-$(uname -r)
apt-get install -y dh-dkms build-essential devscripts git

cd gasket-driver
debuild -us -uc -tc -b

mv ../gasket-dkms_*_all.deb /tmp
apt-get install -y /tmp/gasket-dkms_*_all.deb
rm -rf ../gasket-dkms_*

echo "Full system reboot may be required."
