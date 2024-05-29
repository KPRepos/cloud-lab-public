#!/bin/bash
# make sure to update to Static IP and Hostname first using shell script
## Tools

apt-get install apt-transport-https gnupg curl -y
curl -fsSL https://baltocdn.com/helm/signing.asc | sudo apt-key add -
echo "deb https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list

apt-get update -y
apt-get install helm -y
apt-get install jq -y
apt-get install apt-transport-https gnupg curl -y
apt-get install helm -y
apt-get install nfs-common


sleep 10


# Disable swap
swapoff -a
sed -i '/swap.img/ s/^/#/' /etc/fstab

# Load necessary modules
cat <<EOF | tee /etc/modules-load.d/containerd.conf
overlay
br_netfilter
EOF

modprobe overlay
modprobe br_netfilter

# Set sysctl parameters
cat <<EOT | tee /etc/sysctl.d/kube.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOT

# Apply sysctl parameters without reboot
sysctl --system


# Update the package list and install required packages
apt-get update
apt-get install -y ca-certificates curl gnupg lsb-release

# Add Docker's official GPG key
mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# Set up the Docker repository
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install containerd
apt-get update
apt-get install -y containerd.io

# Configure containerd and start the service
mkdir -p /etc/containerd
containerd config default | tee /etc/containerd/config.toml
sed -i 's/SystemdCgroup = false/SystemdCgroup = true/g' /etc/containerd/config.toml
systemctl restart containerd
systemctl enable containerd

# Add the Kubernetes GPG key
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.28/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
# Add the Kubernetes repository

echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.28/deb/ /" | sudo tee /etc/apt/sources.list.d/kubernetes.list


# Update the package list
apt-get update

# Install kubelet, kubeadm, and kubectl
apt-get install -y kubelet kubeadm kubectl
apt-mark hold kubelet kubeadm kubectl


# Disable swap again to ensure it remains off
swapoff -a
sed -i '/swap/ s/^/#/' /etc/fstab
