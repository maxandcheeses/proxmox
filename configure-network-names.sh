#!/usr/bin/env bash

# Path to the udev rules file
UDEV_RULES_FILE="/etc/udev/rules.d/10-network-names.rules"

# Check if the udev rules file exists, if not create it
if [[ ! -f $UDEV_RULES_FILE ]]; then
    echo "Creating udev rules file: $UDEV_RULES_FILE"
    touch $UDEV_RULES_FILE
    chmod 644 $UDEV_RULES_FILE
fi

# Get all network interfaces that start with "en"
network_devices=$(ls /sys/class/net | grep '^en')

# Check if there are any devices found
if [[ -z "$network_devices" ]]; then
    echo "No network devices found that start with 'en'."
    exit 1
fi

# Loop through each device
for device in $network_devices; do
    echo "Found network device: $device"
    
    # Get the MAC address of the device
    mac_address=$(cat /sys/class/net/$device/address)
    echo "MAC Address: $mac_address"
    
    # Prompt the user if they want to add this device
    read -p "Do you want to add this device to the udev rules file? (y/n): " add_device
    
    if [[ "$add_device" == "y" || "$add_device" == "Y" ]]; then
        # Prompt the user for the desired name
        read -p "Enter the new name for this device: " new_name
        
        # Add the rule to the udev rules file
        echo "SUBSYSTEM==\"net\", ACTION==\"add\", ATTR{address}==\"$mac_address\", NAME=\"$new_name\"" >> $UDEV_RULES_FILE
        echo "Added rule for $device with new name $new_name to $UDEV_RULES_FILE"
    else
        echo "Skipping $device"
    fi
done

echo "Script completed. Please review $UDEV_RULES_FILE and reload udev rules if necessary."
