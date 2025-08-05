# IP-Changer

## Configuration Options

**Methods:**
- **dhcp_renew:** Release/renew DHCP lease (best for most users)
- **random_static:** Cycle through predefined static IPs (configure STATIC_IPS array)
- **restart_interface:** Full interface restart (most disruptive)

**Customization:**
- Edit STATIC_IPS, GATEWAY, and DNS_SERVERS for static IP mode
- Adjust sleep times if connection takes longer to reset
