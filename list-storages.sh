#!/usr/bin/env bash

# Check if nvme-cli is installed
if ! command -v nvme >/dev/null 2>&1; then
    echo "nvme-cli is not installed. Installing it now using apt..."

    # Update package lists and install nvme-cli
    apt update && apt install -y nvme-cli
    
    # Check if the installation was successful
    if ! command -v nvme >/dev/null 2>&1; then
        echo "Error: nvme-cli installation failed. Please install it manually."
        exit 1
    fi
fi

echo "nvme-cli is installed. Proceeding with the script."

# Get the list of NVMe devices using nvme-cli
nvme list | awk 'NR>2 {print $1}' | while read -r device_path; do
    # Get the model of the NVMe device and remove any extra newlines or spaces
    model=$(nvme id-ctrl "$device_path" | grep -i "mn" | awk -F: '{print $2}' | tr -d '\n' | sed 's/^[ \t]*//;s/[ \t]*$//')
    
    # Get the size of the NVMe device
    size=$(lsblk -nd -o SIZE "$device_path")
    
    # Get the PCI bus ID using udevadm
    bus_id=$(udevadm info --query=all --name="$device_path" | grep -oP 'ID_PATH=pci-\K[^/]+')

    # Print the details
    echo "Model: $model"
    echo "Device Path: $device_path"
    echo "Bus ID: $bus_id"
    echo "Storage Size: $size"
    echo "---------------------------------------"
done
