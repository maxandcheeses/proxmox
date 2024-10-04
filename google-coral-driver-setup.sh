#!/usr/bin/env bash
set -eo pipefail

# Check if gasket-dkms is installed
if dpkg -l | grep -q "gasket-dkms"; then
    echo "gasket-dkms is installed."
else
    echo "deb https://packages.cloud.google.com/apt coral-edgetpu-stable main" | tee /etc/apt/sources.list.d/coral-edgetpu.list
    curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
    apt-get update
    apt install dkms
fi

rm -rf gasket-driver
git clone https://github.com/google/gasket-driver.git
apt-get remove gasket-dkms -y
apt-get install pve-headers-$(uname -r) -y
#apt-get reinstall gasket-dkms libedgetpu1-std -y
apt-get install dh-dkms build-essential devscripts git -y
cd gasket-driver
debuild -us -uc -tc -b
mv ../gasket-dkms_*_all.deb /tmp
apt-get install /tmp/gasket-dkms_*_all.deb -y
rm -rf ../gasket-dkms_*

echo "Full system reboot maybe required"
