#!/usr/bin/env bash
set -eo pipefail

# 1. Force-clear the broken package state
echo "Cleaning up broken package state..."
apt-get purge -y gasket-dkms || true
rm -rf /var/lib/dkms/gasket/1.0

# 2. Identify the latest installed kernel version
LATEST_KRNL=$(ls -v /lib/modules | tail -n 1)
echo "Targeting kernel version: $LATEST_KRNL"

# 3. Install build dependencies
echo "Installing build dependencies..."
apt-get update
apt-get install -y "pve-headers-$LATEST_KRNL" || \
    apt-get install -y "linux-headers-$LATEST_KRNL"
apt-get install -y dkms dh-dkms build-essential devscripts git patch

# 4. Clone and Patch
echo "Cloning gasket driver..."
rm -rf gasket-driver
git clone https://github.com/maxandcheeses/gasket-driver.git
cd gasket-driver

echo "Applying patches for Kernel 6.12+ compatibility..."

# Fix REMAKE_INITRD warning only if file exists
if [ -f "dkms.conf" ]; then
    sed -i '/REMAKE_INITRD/d' dkms.conf
fi

# Apply Kernel 6.12+ fix for the memory fault handler
cat << 'EOF' > kernel_6_12.patch
--- a/src/gasket_page_table.c
+++ b/src/gasket_page_table.c
@@ -1480,7 +1480,11 @@
 }
 
 static vm_fault_t gasket_pci_spec_fault(
+#if LINUX_VERSION_CODE >= KERNEL_VERSION(6, 12, 0)
+	struct vm_fault *vmf)
+#else
 	struct vm_area_struct *vma, struct vm_fault *vmf)
+#endif
 {
 	return VM_FAULT_SIGBUS;
 }
EOF

# Apply the patch to the source
patch -p1 < kernel_6_12.patch || echo "Patch failed - checking source structure..."

# 5. Build and Install
echo "Building .deb package..."
# -us -uc: do not sign; -tc: clean after; -b: binary only
debuild -us -uc -tc -b
cd ..

echo "Installing built .deb..."
# Use a wildcard to find the deb produced by debuild in the parent folder
apt-get install -y ./gasket-dkms_*_all.deb
rm -f gasket-dkms_*_all.deb gasket_*

echo "Done. Please reboot to load kernel $LATEST_KRNL."
