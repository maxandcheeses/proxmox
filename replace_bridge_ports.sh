#!/usr/bin/env bash

# Check if the script has write permissions
if [ ! -w "/etc/network/interfaces" ]; then
    echo "Error: You do not have write permissions for /etc/network/interfaces."
    echo "Please run the script as root or adjust file permissions."
    exit 1
fi

# Backup the original /etc/network/interfaces file
cp /etc/network/interfaces /etc/network/interfaces.bak

# Read the interfaces file into an array, line by line
mapfile -t interfaces_file_array < /etc/network/interfaces

# Find lines with 'bridge-ports' (using hyphen)
bridge_ports_lines=()
for i in "${!interfaces_file_array[@]}"; do
    if [[ "${interfaces_file_array[$i]}" =~ ^[[:space:]]*bridge-ports ]]; then
        bridge_ports_lines+=("$i")
    fi
done

# Check if any bridge-ports lines were found
if [ ${#bridge_ports_lines[@]} -eq 0 ]; then
    echo "No 'bridge-ports' configurations found in /etc/network/interfaces."
    exit 0
fi

# Get list of available network interfaces
available_ifaces=($(ls /sys/class/net | grep -v lo))

# Function to prompt for interface selection
select_interfaces() {
    local prompt_message=$1
    local selected_ifaces=()
    echo "$prompt_message"
    for i in "${!available_ifaces[@]}"; do
        echo "$i) ${available_ifaces[$i]}"
    done
    echo -n "Enter the numbers of the interfaces you want to select (separated by spaces): "
    read -a selections
    # Validate the selections
    for selection in "${selections[@]}"; do
        if [[ ! "$selection" =~ ^[0-9]+$ ]] || [ "$selection" -lt 0 ] || [ "$selection" -ge "${#available_ifaces[@]}" ]]; then
            echo "Invalid selection: $selection"
            return 1
        fi
        selected_ifaces+=("${available_ifaces[$selection]}")
    done
    # Remove duplicates
    selected_ifaces=($(echo "${selected_ifaces[@]}" | tr ' ' '\n' | sort -u | tr '\n' ' '))
    echo "You selected: ${selected_ifaces[@]}"
    selected_iface_list="${selected_ifaces[@]}"
    return 0
}

# Iterate over each line with 'bridge-ports'
for line_index in "${bridge_ports_lines[@]}"; do
    # Get the current bridge-ports line
    current_line="${interfaces_file_array[$line_index]}"
    echo
    echo "Found 'bridge-ports' configuration at line $((line_index + 1)):"
    echo "$current_line"

    # Extract the current interfaces in bridge-ports
    current_ports=($(echo "$current_line" | awk '{for (i=2; i<=NF; i++) print $i}'))

    # Display current ports
    echo "Current bridge ports: ${current_ports[@]}"

    # Ask if the user wants to replace the ports
    read -p "Do you want to replace these bridge ports? (y/n): " replace_choice

    if [[ "$replace_choice" =~ ^[Yy]$ ]]; then
        # Prompt the user to select new interfaces
        while true; do
            if select_interfaces "Available interfaces:"; then
                # Replace the line in the interfaces file array
                new_line="$(printf '%*s' $((`echo "$current_line" | awk -F'[^ ]' '{print length($1)}'`)) '')bridge-ports $selected_iface_list"
                interfaces_file_array[$line_index]="$new_line"
                echo "Updated line $((line_index + 1)) in /etc/network/interfaces."
                break
            else
                echo "Please try again."
            fi
        done
    else
        echo "Keeping the original bridge ports."
    fi
done

# Show the updated interfaces file
echo
echo "Updated /etc/network/interfaces content:"
echo "----------------------------------------"
printf "%s\n" "${interfaces_file_array[@]}"
echo "----------------------------------------"

# Confirm before writing changes
read -p "Do you want to save these changes to /etc/network/interfaces? (y/n): " save_changes

if [[ "$save_changes" =~ ^[Yy]$ ]]; then
    # Write the updated content back to /etc/network/interfaces
    printf "%s\n" "${interfaces_file_array[@]}" > /etc/network/interfaces
    if [ $? -eq 0 ]; then
        echo "Changes saved successfully."
    else
        echo "Failed to save changes."
        exit 1
    fi

    # Restart networking service
    read -p "Do you want to restart the networking service now? (y/n): " restart_choice
    if [[ "$restart_choice" =~ ^[Yy]$ ]]; then
        systemctl restart networking
        if [ $? -eq 0 ]; then
            echo "Networking service restarted successfully."
        else
            echo "Failed to restart networking service."
            echo "You may need to restart the networking service manually."
        fi
    else
        echo "Please remember to restart the networking service to apply changes."
    fi
else
    echo "Changes discarded. Original file preserved."
fi
