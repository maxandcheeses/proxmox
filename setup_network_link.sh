#!/usr/bin/env bash

# Ensure the script is run interactively
if [[ ! -t 0 ]]; then
    echo "Please run this script interactively."
    exit 1
fi

# Get list of network interfaces and their MAC addresses
interfaces=$(ip link show | awk '/^[0-9]+: / {gsub(":", "", $2); iface=$2} /link\/ether/ {print iface " " $2}')

# Check if any interfaces were found
if [ -z "$interfaces" ]; then
    echo "No network interfaces found."
    exit 1
fi

# Present the list to the user
echo "Available network interfaces:"
IFS=$'\n' read -rd '' -a iface_array <<<"$interfaces"

for index in "${!iface_array[@]}"; do
    iface_name=$(echo "${iface_array[$index]}" | awk '{print $1}')
    mac_addr=$(echo "${iface_array[$index]}" | awk '{print $2}')
    echo "$((index+1)). Interface: $iface_name, MAC Address: $mac_addr"
done

# Prompt the user to select an interface
echo -n "Enter the number of the interface you want to use [1-${#iface_array[@]}]: "
read selection

# Validate the selection
if ! [[ "$selection" =~ ^[0-9]+$ ]] || [ "$selection" -lt 1 ] || [ "$selection" -gt "${#iface_array[@]}" ]; then
    echo "Invalid selection."
    exit 1
fi

selected_iface=$(echo "${iface_array[$((selection-1))]}" | awk '{print $1}')
selected_mac=$(echo "${iface_array[$((selection-1))]}" | awk '{print $2}')

# Prompt for custom interface name (default to eth0)
echo -n "Enter the Name for the interface (default: eth0): "
read iface_name

if [ -z "$iface_name" ]; then
    iface_name="eth0"
fi

# Determine the prefix number based on the interface name
# Extract the number from the interface name (e.g., eth0 -> 0)
iface_number=$(echo "$iface_name" | grep -o '[0-9]\+')
if [ -z "$iface_number" ]; then
    # If no number is found, assign a default number (e.g., 0)
    iface_number=0
fi

# Calculate the prefix number (90 + interface number)
prefix_number=$((90 + iface_number))

# Create the filename
filename="/etc/systemd/network/${prefix_number}-${iface_name}.link"

# Display the configuration
echo
echo "Creating ${filename} with the following content:"
echo "---------------------------------------------------------"
echo "[Match]"
echo "MACAddress=$selected_mac"

echo "[Link]"
echo "Name=$iface_name"
echo "---------------------------------------------------------"
echo

# Confirm before writing
echo -n "Do you want to proceed? (y/n): "
read confirmation

if [[ "$confirmation" != "y" && "$confirmation" != "Y" ]]; then
    echo "Operation cancelled."
    exit 0
fi

# Write the configuration to the file
bash -c "cat > ${filename} <<EOF
[Match]
MACAddress=$selected_mac

[Link]
Name=$iface_name
EOF"

if [ $? -eq 0 ]; then
    echo "Configuration written to ${filename}"
else
    echo "Failed to write configuration."
    exit 1
fi

# Optionally restart systemd-networkd service (requires root privileges)
echo -n "Do you want to restart the systemd-networkd service now? (y/n): "
read restart_confirmation

if [[ "$restart_confirmation" == "y" || "$restart_confirmation" == "Y" ]]; then
    systemctl restart systemd-networkd
    if [ $? -eq 0 ]; then
        echo "systemd-networkd service restarted."
    else
        echo "Failed to restart systemd-networkd service."
    fi
else
    echo "Please remember to restart the systemd-networkd service to apply changes."
fi
