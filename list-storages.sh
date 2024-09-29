#!/usr/bin/env bash

# Get the NVMe or SSD entries from lsblk
lsblk -do NAME,SIZE,MODEL | egrep -i 'nvme|ssd' | while read -r name size model; do
    # Convert the model to lowercase for better matching
    model_lower=$(echo "$model" | tr '[:upper:]' '[:lower:]')
    
    # Find the matching PCI entry using partial case-insensitive matching
    pci_info=$(lspci | egrep -i 'nvme|ssd' | grep -i -m 1 "$(echo "$model_lower" | awk '{print $1}')")

    # If a matching PCI entry is found, print the combined information
    if [ -n "$pci_info" ]; then
        echo "Device Name: /dev/$name"
        echo "Size: $size"
        echo "Model: $model"
        echo "PCI Info: $pci_info"
        echo "---------------------------------------"
    else
        echo "Device Name: /dev/$name"
        echo "Size: $size"
        echo "Model: $model"
        echo "PCI Info: Not Found"
        echo "---------------------------------------"
    fi
done
