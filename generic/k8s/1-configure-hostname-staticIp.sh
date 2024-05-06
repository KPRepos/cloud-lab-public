#!/bin/bash

# Update system and install necessary packages
sudo apt-get update
sudo apt-get install -y net-tools vim

# Ask for the network adapter name, default to ens160
read -p "Enter network adapter name [ens160]: " adapter_name
adapter_name=${adapter_name:-ens160}

# Ask for the new hostname
read -p "Enter new hostname: " new_hostname

# Ask for the static IP address
read -p "Enter static IP Address: " static_ip

# Ask for the subnet mask in CIDR notation
read -p "Enter subnet mask in CIDR notation (e.g., /24): " subnet_mask

# Ask for the DNS servers, comma-separated
read -p "Enter DNS servers separated by comma (e.g., 8.8.8.8,8.8.4.4): " dns_servers

# Ask for the Gateway IP
read -p "Enter Gateway IP  " gateway_ip

# Change hostname permanently
hostnamectl set-hostname $new_hostname

# Specify the directory where your netcfg files are located
directory="/etc/netplan/"

# Iterate over files matching the pattern *netcfg*
for file in "$directory"/*netcfg*; do
    if [ -f "$file" ]; then
        echo "Backing up $file"
        sudo cp "$file" "$file.backup"
    fi
done


# Create new netplan configuration
cat <<EOT | sudo tee /etc/netplan/01-netcfg.yaml
network:
  version: 2
  renderer: networkd
  ethernets:
    $adapter_name:
      dhcp4: no
      addresses: [$static_ip$subnet_mask]
      nameservers:
        addresses: [${dns_servers//,/, }]
      routes:
        - to: default
          via: $gateway_ip
          on-link: true 
EOT

# $sudo chmod 600 /etc/netplan/01-netcfg.yaml
# sudo chmod 600 /etc/netplan/01-network-manager-all.yaml

# Apply the netplan configuration
sudo netplan apply

# Reboot the system
read -p "Configuration updated. Do you want to reboot now? (y/n): " confirm_reboot
if [[ $confirm_reboot =~ ^[Yy]$ ]]; then
    sudo reboot
fi

read -p "Configuration updated. Do you want to reboot now? (y/n): " confirm_reboot
if [[ $confirm_reboot =~ ^[Yy]$ ]]; then
    echo "hi"
fi


