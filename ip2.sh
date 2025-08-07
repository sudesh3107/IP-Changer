#!/bin/bash

# Force IP Changer Script for Nobara OS
# Uses MAC spoofing to guarantee IP changes
# Usage: sudo ./ip-changer.sh <interface> <interval_minutes>

# Validate root privileges
if [ "$(id -u)" != "0" ]; then
    echo "This script must be run as root. Use sudo!" >&2
    exit 1
fi

# Validate arguments
if [ $# -lt 2 ]; then
    echo "Usage: sudo $0 <interface> <interval_minutes>"
    echo "Example: sudo $0 enp0s3 15"
    exit 1
fi

INTERFACE="$1"
INTERVAL="$2"
INTERVAL_SECONDS=$((INTERVAL * 60))

# Get current connection name
CONN_NAME=$(nmcli -t -f DEVICE,CONNECTION dev | grep "^$INTERFACE:" | cut -d: -f2)

if [ -z "$CONN_NAME" ]; then
    echo "Error: No active NetworkManager connection found for $INTERFACE"
    exit 1
fi

echo "Starting IP rotation every $INTERVAL minutes on $INTERFACE ($CONN_NAME)"

# Function to generate random MAC address
generate_mac() {
    printf '00:%02X:%02X:%02X:%02X:%02X\n' \
    $((RANDOM%256)) $((RANDOM%256)) $((RANDOM%256)) $((RANDOM%256)) $((RANDOM%256))
}

# Main IP change function
change_ip() {
    # Step 1: Disconnect interface
    echo "[$(date +'%H:%M:%S')] Disconnecting interface..."
    nmcli dev disconnect "$INTERFACE"
    sleep 2

    # Step 2: Generate new MAC address
    NEW_MAC=$(generate_mac)
    echo "Setting new MAC: $NEW_MAC"
    
    # Step 3: Apply new MAC address
    nmcli con mod "$CONN_NAME" 802-3-ethernet.cloned-mac-address "$NEW_MAC"
    
    # Step 4: Release current DHCP lease
    dhclient -r "$INTERFACE" 2>/dev/null
    ip addr flush dev "$INTERFACE"
    ip route flush dev "$INTERFACE"
    
    # Step 5: Reconnect with new MAC
    echo "Reconnecting with new identity..."
    nmcli dev connect "$INTERFACE"
    sleep 5  # Allow time for connection establishment

    # Step 6: Force DHCP renewal
    dhclient -v "$INTERFACE"
    
    # Verify new IP
    NEW_IP=$(ip -4 addr show dev "$INTERFACE" | grep inet | awk '{print $2}' | head -n1)
    echo "[$(date +'%H:%M:%S')] New IP: ${NEW_IP:-Failed!}"
    
    # Verify public IP if internet available
    if ping -c1 -W2 8.8.8.8 &>/dev/null; then
        PUBLIC_IP=$(curl -s ifconfig.me)
        echo "Public IP: $PUBLIC_IP"
    fi
}

# Initial state
OLD_IP=$(ip -4 addr show dev "$INTERFACE" | grep inet | awk '{print $2}' | head -n1)
echo "Current IP: ${OLD_IP:-Not assigned}"

# Main loop
while true; do
    change_ip
    
    # Verify change
    CURRENT_IP=$(ip -4 addr show dev "$INTERFACE" | grep inet | awk '{print $2}' | head -n1)
    if [ "$OLD_IP" == "$CURRENT_IP" ]; then
        echo "Warning: IP address didn't change! Using nuclear option..."
        systemctl restart NetworkManager
        sleep 10
    else
        OLD_IP="$CURRENT_IP"
    fi
    
    echo "Next change in $INTERVAL minutes..."
    sleep "$INTERVAL_SECONDS"
done
