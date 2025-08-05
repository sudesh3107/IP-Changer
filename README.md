# IP-Changer

## Configuration Options

**Methods:**
- **dhcp_renew:** Release/renew DHCP lease (best for most users)
- **random_static:** Cycle through predefined static IPs (configure STATIC_IPS array)
- **restart_interface:** Full interface restart (most disruptive)

**Customization:**
- Edit STATIC_IPS, GATEWAY, and DNS_SERVERS for static IP mode
- Adjust sleep times if connection takes longer to reset

## Usage Instructions

### Verify IP Changes
Check current IP with:
```bash
ip addr show dev <interface>
```

### To Run in Background
```bash
sudo nohup ./ip-changer.sh enp0s3 15 dhcp_renew > /dev/null 2>&1 &
```

### Stop the Script
```bash
sudo pkill -f ip-changer.sh
```

## Important Notes
- Works best with Ethernet connections
- For WiFi, add MAC address randomization for better anonymity:
  ```bash
  nmcli con mod "$CONNECTION_NAME" wifi.cloned-mac-address random
  ```
- Test different methods to see which works best with your network
- Static IPs must be in your router's valid range
