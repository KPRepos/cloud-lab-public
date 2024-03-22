#!/bin/bash

sudo apt-get update
sleep 10

while ! command -v aws &> /dev/null; do
    echo "AWS CLI not found. Installing..."

    # Update the package list
    sudo apt-get update

    # Install AWS CLI
    sudo apt-get install awscli -y

    if ! command -v aws &> /dev/null; then
        echo "AWS CLI installation failed. Retrying in 10 seconds..."
        sleep 10
    fi
done

echo "AWS CLI is already installed."

## Tools

apt-get install apt-transport-https gnupg curl -y
curl -fsSL https://baltocdn.com/helm/signing.asc | sudo apt-key add -
echo "deb https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
apt-get update -y
apt-get install helm -y
apt-get install jq -y

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

# Cleanup: Remove the temporary file

adduser k8admin
usermod -aG sudo k8admin
mkdir -p /home/k8admin/.kube


API_SERVER_PORT=6443
k8_ct_auth_key="${k8_ct_auth_key}"
REGION=$(curl -s http://169.254.169.254/latest/meta-data/placement/region)

echo "Running Control Plane API Liveness Check"

# echo $CONTROL_PLANE_DNS

echo ""


check_api_server() {
    while true; do
        echo $REGION
        secret=$(aws secretsmanager get-secret-value --secret-id "$k8_ct_auth_key" --query SecretString --output text --region "$REGION")
        joinCommand=$(echo $secret | tr -d '\\' | tr -s ' ')
        ip_address=$(echo $joinCommand | grep -oP 'join \K.*(?=:6443)' | sed 's/ --token.*//')
        echo $ip_address
        response=$(curl --silent --max-time 5 --insecure "https://$ip_address:$API_SERVER_PORT")
        code=$(echo $response | jq '.code')
        echo "code is ..."
        echo ""
        echo $code
        echo ""
        if [[ "$code" == "403" ]]; then
            echo "403 found"
            return 0  # Success, exit the loop
        else
            echo "API server at $ip_address:$API_SERVER_PORT not ready, response code: $code. Retrying..."
            sleep 5  # Wait before retrying
        fi
    done
}

echo "call function"
check_api_server
echo "done function"

 #make sure  to remove secretsmanager delay
echo "running join"


# Retrieve the join command from AWS Secrets Manager
joinCommand=$(aws secretsmanager get-secret-value --secret-id "$k8_ct_auth_key" --region "$REGION" --query SecretString --output text)

if [ -z "$joinCommand" ]; then
    echo "Failed to retrieve join command from AWS Secrets Manager"
    exit 1
fi

# Execute the join command
echo "Executing join command..."
joinCommand=$(echo $joinCommand | tr -d '\\' | tr -s ' ')
eval $joinCommand


echo "Kubernetes setup is complete. Please review any commented out sections relevant to your setup."
