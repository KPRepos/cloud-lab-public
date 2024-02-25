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
curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | gpg --dearmor -o /etc/apt/keyrings/kubernetes-archive-keyring.gpg

# Add the Kubernetes repository
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | tee /etc/apt/sources.list.d/kubernetes.list

# Update the package list
apt-get update

# Install kubelet, kubeadm, and kubectl
apt-get install -y kubelet kubeadm kubectl
apt-mark hold kubelet kubeadm kubectl

LB_DNS="${lb_dns}"

# Initialize the Kubernetes cluster
# Run kubeadm init and redirect output to a temporary file

echo $LB_DNS

echo ""

kubeadm init --control-plane-endpoint $LB_DNS --ignore-preflight-errors=Mem | tee /tmp/kubeadm_init_output.txt


joinCommand=$(awk '/kubeadm join/{flag=1; print; next} flag && /--discovery-token-ca-cert-hash/{print; exit} flag' /tmp/kubeadm_init_output.txt)
joinCommand=$(echo $joinCommand | sed 's/\\//g')

echo "............."


# Check if the join command was extracted successfully
if [ -z "$joinCommand" ]; then
    echo "Failed to extract the kubeadm join command from the output."
    exit 1
else
    echo "Join command extracted successfully:"
fi


REGION=$(curl -s http://169.254.169.254/latest/meta-data/placement/region)

echo "........"

echo $joinCommand

echo "........"

echo $REGION

k8_ct_auth_key="${k8_ct_auth_key}"

echo ".............."

# Save the join command to AWS Secrets Manager
aws secretsmanager update-secret --secret-id "$k8_ct_auth_key" \
    --description "Kubernetes join command for worker nodes" \
    --secret-string "$joinCommand" --region "$REGION"

# Check if the AWS Secrets Manager command was successful
if [ $? -eq 0 ]; then
    echo "Successfully saved the join command to AWS Secrets Manager."
else
    echo "Failed to save the join command to AWS Secrets Manager."
    exit 1
fi


# # Cleanup: Remove the temporary file
rm -f /tmp/kubeadm_init_output.txt

# Set up local kubeconfig
mkdir -p $HOME/.kube
cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
chown $(id -u):$(id -g) $HOME/.kube/config

# Set up for kubeadmin user

adduser k8admin
usermod -aG sudo k8admin
mkdir -p /home/k8admin/.kube
cp -i /etc/kubernetes/admin.conf /home/k8admin/.kube/config
chown k8admin:k8admin /home/k8admin/.kube/config

#Installing Calico 
kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml


echo "Kubernetes setup is complete. Please review any commented out sections relevant to your setup."

apt-get install apt-transport-https gnupg curl -y
curl -fsSL https://baltocdn.com/helm/signing.asc | sudo apt-key add -
echo "deb https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
apt-get update -y
apt-get install helm -y

