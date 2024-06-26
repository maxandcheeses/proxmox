#!/usr/bin/env bash
set -eo pipefail

# Proxmox 8.2
# Remove subscription prompt from proxmox. Applies to desktop and mobile

sed -Ezi.bak "s/(function\(orig_cmd\) \{)/\1\n\torig_cmd\(\);\n\treturn;/g" /usr/share/javascript/proxmox-widget-toolkit/proxmoxlib.js
sed -Ezi.bak "s/(function\(orig_cmd\) \{)/\1\n\torig_cmd\(\);\n\treturn;/g" /usr/share/pve-manager/touch/pvemanager-mobile.js
sed -Ezi.bak "s/(function\(orig_cmd\) \{)/\1\n\torig_cmd\(\);\n\treturn;/g" /usr/share/pve-manager/js/pvemanagerlib.js
systemctl restart pveproxy.service
