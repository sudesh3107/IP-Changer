#!/bin/bash

# Usage: sudo ./ip-changer.sh <interface> <interval_minutes> [method]

# Methods: 
#   dhcp_renew (default) - Release/Renew DHCP lease
#   random_static - Cycle through random static IPs (configure below)
#   restart_interface - Restart network interface

# Configuration
STATIC_IPS=("192.168.1.100/24" "192.168.1.101/24" "192.168.1.102/24")  # Add your IP ranges
GATEWAY="192.168.1.1"  # Your gateway
DNS_SERVERS="8.8.8.8,8.8.4.4"  # Comma-separated DNS

# Validate arguments
if [ $# -lt 2 ]; then
    echo "Usage: sudo $0 <interface> <interval_minutes> [dhcp_renew|random_static|restart_interface]"
    exit 1
fi

INTERFACE="$1"
INTERVAL_MINUTES="$2"
METHOD="${3:-dhcp_renew}"

# Convert minutes to seconds
INTERVAL_SECONDS=$((INTERVAL_MINUTES * 60))

# Function to change IP using DHCP release/renew
change_dhcp() {
    echo "[$(date)] Releasing DHCP lease..."
    sudo dhclient -r "$INTERFACE"
    
    echo "[$(date)] Requesting new DHCP lease..."
    sudo dhclient -v "$INTERFACE"
}

# Function to set random static IP
change_static() {
    RANDOM_IP="${STATIC_IPS[$RANDOM % ${#STATIC_IPS[@]}]}"
    
    echo "[$(date)] Setting static IP: $RANDOM_IP"
    
    sudo nmcli con mod "$CONNECTION_NAME" ipv4.method manual \
        ipv4.addresses "$RANDOM_IP" \
        ipv4.gateway "$GATEWAY" \
        ipv4.dns "$DNS_SERVERS"
    
    sudo nmcli con down "$CONNECTION_NAME"
    sleep 2
    sudo nmcli con up "$CONNECTION_NAME"
}

# Function to restart interface
restart_interface() {
    echo "[$(date)] Restarting network interface..."
    sudo nmcli dev disconnect "$INTERFACE"
    sleep 3
    sudo nmcli dev connect "$INTERFACE"
}

# Get connection name
CONNECTION_NAME=$(nmcli -t -f DEVICE,CONNECTION dev | grep "^$INTERFACE:" | cut -d: -f2)

if [ -z "$CONNECTION_NAME" ]; then
    echo "Error: No active connection found for $INTERFACE"
    exit 1
fi

echo "Starting IP rotation every $INTERVAL_MINUTES minutes on $INTERFACE ($CONNECTION_NAME)"
echo "Method: $METHOD"

# Main loop
while true; do
    case $METHOD in
        dhcp_renew)
            change_dhcp
            ;;
        random_static)
            change_static
            ;;
        restart_interface)
            restart_interface
            ;;
        *)
            echo "Invalid method: $METHOD"
            exit 1
            ;;
    esac
    
    # Show new IP
    NEW_IP=$(ip -4 addr show dev "$INTERFACE" | grep inet | awk '{print $2}')
    echo "[$(date)] New IP: $NEW_IP"
    
    # Wait for next change
    echo "Next change in $INTERVAL_MINUTES minutes..."
    sleep "$INTERVAL_SECONDS"
done
