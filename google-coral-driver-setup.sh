#!/usr/bin/env bash
set -eo pipefail

if [[ ! -d gasket-driver ]]; then
	git clone git@github.com:google/gasket-driver.git
fi

apt install pve-headers-$(uname -r)
#apt-get reinstall gasket-dkms libedgetpu1-std
apt install dh-dkms build-essential devscripts git
cd gasket-driver
debuild -us -uc -tc -b
apt install ../gasket-dkms_*_all.deb
