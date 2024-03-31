#!/bin/bash

## Tools

apt-get install apt-transport-https gnupg curl -y
curl -fsSL https://baltocdn.com/helm/signing.asc | sudo apt-key add -
echo "deb https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list

apt-get update -y
apt-get install helm -y
apt-get install jq -y
apt-get install apt-transport-https gnupg curl -y
apt-get install helm -y

sleep 10


# Disable swap
swapoff -a
sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

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


# kubeadm init --control-plane-endpoint 10.0.0.223 

kubeadm init 



# Set up local kubeconfig
mkdir -p $HOME/.kube
cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
chown $(id -u):$(id -g) $HOME/.kube/config


# Set up for kubeadmin user

adduser --disabled-password --gecos "" k8admin
usermod -aG sudo k8admin
mkdir -p /home/k8admin/.kube
cp -i /etc/kubernetes/admin.conf /home/k8admin/.kube/config
chown k8admin:k8admin /home/k8admin/.kube/config

#Installing Calico 
kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml


echo "Kubernetes setup is complete. Please review any commented out sections relevant to your setup."

# alias k='kubectl'
echo "alias k='kubectl'" | sudo tee /etc/profile.d/kubectl_alias.sh > /dev/null
