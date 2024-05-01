#!/usr/bin/env bash
set -eo pipefail

rm -rf gasket-driver
git clone https://github.com/google/gasket-driver.git
apt remove gasket-dkms -y
apt install pve-headers-$(uname -r) -y
#apt-get reinstall gasket-dkms libedgetpu1-std -y
apt install dh-dkms build-essential devscripts git -y
cd gasket-driver
debuild -us -uc -tc -b
mv ../gasket-dkms_*_all.deb /tmp
apt install /tmp/gasket-dkms_*_all.deb -y

echo "Full system reboot maybe required"
