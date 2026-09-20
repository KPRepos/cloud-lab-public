#!/usr/bin/env bash
set -Eeuo pipefail

# Usage:
#   sudo ./install.sh         # Latest upstream stable minor release
#   sudo ./install.sh 1.37    # Requested Kubernetes minor release
#
# This script is for a fresh Ubuntu/Debian-based kubeadm control-plane node.
# It initializes a single-control-plane cluster and installs Calico.

if [[ "${EUID}" -ne 0 ]]; then
  echo "Run this script as root: sudo $0 [major.minor]"
  exit 1
fi

export DEBIAN_FRONTEND=noninteractive

K8S_VERSION_INPUT="${1:-}"

require_command() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "Required command not found: $1" >&2
    exit 1
  }
}

get_kubernetes_version() {
  local requested="$1"
  local stable_version

  if [[ -n "${requested}" ]]; then
    if [[ ! "${requested}" =~ ^[0-9]+\.[0-9]+(\.[0-9]+)?$ ]]; then
      echo "Invalid Kubernetes version: '${requested}'" >&2
      echo "Use a version such as: 1.37" >&2
      exit 1
    fi

    # Accept 1.37 or v1.37 or 1.37.0, but repository selection needs major.minor.
    printf '%s\n' "${requested#v}" | awk -F. '{print $1 "." $2}'
    return
  fi

  stable_version="$(
    curl --fail --silent --show-error --location \
      --retry 3 --retry-delay 2 \
      https://dl.k8s.io/release/stable.txt
  )"

  if [[ ! "${stable_version}" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "Unable to determine a valid stable Kubernetes release." >&2
    echo "Received: '${stable_version}'" >&2
    exit 1
  fi

  printf '%s\n' "${stable_version#v}" | awk -F. '{print $1 "." $2}'
}

K8S_MINOR="$(get_kubernetes_version "${K8S_VERSION_INPUT}")"
K8S_REPO="https://pkgs.k8s.io/core:/stable:/v${K8S_MINOR}/deb/"
K8S_KEY_URL="${K8S_REPO}Release.key"

echo "Selected Kubernetes minor version: v${K8S_MINOR}"
echo "Kubernetes repository: ${K8S_REPO}"

# Basic packages
apt-get update
apt-get install -y \
  ca-certificates \
  curl \
  gpg \
  jq \
  nfs-common \
  apt-transport-https

# ---------------------------------------------------------------------------
# Helm repository and package
# ---------------------------------------------------------------------------
install -m 0755 -d /etc/apt/keyrings

HELM_BUILDKITE_APT_KEY_ID="DDF78C3E6EBB2D2CC223C95C62BA89D07698DBC6"

apt-get install curl gpg apt-transport-https --yes

curl -fsSL https://packages.buildkite.com/helm-linux/helm-debian/gpgkey > "${TMPDIR:-/tmp}/helm.gpg"

# Ensure that the key ID matches to prevent a repository compromise from establishing an attacker controlled key
if [ "$(gpg --show-keys --with-colons "${TMPDIR:-/tmp}/helm.gpg" | awk -F: '$1 == "fpr" {print $10}' | head -n 1)" != "${HELM_BUILDKITE_APT_KEY_ID}" ]; then echo "ERROR: Unexpected Helm APT key ID: potential key compromise"; exit 1; fi

cat "${TMPDIR:-/tmp}/helm.gpg" | gpg --dearmor | sudo tee /usr/share/keyrings/helm.gpg > /dev/null
echo "deb [signed-by=/usr/share/keyrings/helm.gpg] https://packages.buildkite.com/helm-linux/helm-debian/any/ any main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list

# apt-get update
# apt-get install helm

# ---------------------------------------------------------------------------
# Kubernetes host prerequisites
# ---------------------------------------------------------------------------

# Disable swap now.
swapoff -a

# Permanently disable all active swap mounts recorded in fstab.
sed -ri '/\sswap\s/s/^\s*#?/#/' /etc/fstab

cat > /etc/modules-load.d/kubernetes.conf <<'EOF'
overlay
br_netfilter
EOF

modprobe overlay
modprobe br_netfilter

cat > /etc/sysctl.d/99-kubernetes-cri.conf <<'EOF'
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF

sysctl --system

# ---------------------------------------------------------------------------
# Docker repository: only used here to install containerd.io
# ---------------------------------------------------------------------------
curl --fail --silent --show-error --location \
  https://download.docker.com/linux/ubuntu/gpg \
  | gpg --dearmor --yes -o /etc/apt/keyrings/docker.gpg

chmod 0644 /etc/apt/keyrings/docker.gpg

ARCH="$(dpkg --print-architecture)"
CODENAME="$(
  . /etc/os-release
  printf '%s' "${VERSION_CODENAME:-}"
)"

if [[ -z "${CODENAME}" ]]; then
  echo "Could not determine the distribution codename from /etc/os-release." >&2
  exit 1
fi

cat > /etc/apt/sources.list.d/docker.list <<EOF
deb [arch=${ARCH} signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu ${CODENAME} stable
EOF

apt-get update
apt-get install -y containerd.io

# Generate a default containerd configuration, then enable systemd cgroups.
install -d -m 0755 /etc/containerd
containerd config default > /etc/containerd/config.toml

sed -ri 's/^(\s*)SystemdCgroup = false/\1SystemdCgroup = true/' \
  /etc/containerd/config.toml

systemctl daemon-reload
systemctl enable --now containerd
systemctl restart containerd

# ---------------------------------------------------------------------------
# Kubernetes v${K8S_MINOR} package repository and components
# ---------------------------------------------------------------------------
curl --fail --silent --show-error --location "${K8S_KEY_URL}" \
  | gpg --dearmor --yes -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

chmod 0644 /etc/apt/keyrings/kubernetes-apt-keyring.gpg

cat > /etc/apt/sources.list.d/kubernetes.list <<EOF
deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] ${K8S_REPO} /
EOF

chmod 0644 /etc/apt/sources.list.d/kubernetes.list

apt-get update
apt-get install -y helm kubelet kubeadm kubectl

# Prevent unattended or manual apt upgrades from moving Kubernetes packages.
apt-mark hold kubelet kubeadm kubectl

systemctl enable --now kubelet

# ---------------------------------------------------------------------------
# Initialize the control plane
# ---------------------------------------------------------------------------
if [[ -f /etc/kubernetes/admin.conf ]]; then
  echo "Kubernetes appears to be initialized already: /etc/kubernetes/admin.conf exists."
  echo "Refusing to run kubeadm init again."
  exit 1
fi

kubeadm init

# Configure kubectl for the invoking non-root user when run via sudo.
TARGET_USER="${SUDO_USER:-root}"
TARGET_HOME="$(getent passwd "${TARGET_USER}" | cut -d: -f6)"

install -d -m 0700 -o "${TARGET_USER}" -g "${TARGET_USER}" \
  "${TARGET_HOME}/.kube"

install -m 0600 -o "${TARGET_USER}" -g "${TARGET_USER}" \
  /etc/kubernetes/admin.conf \
  "${TARGET_HOME}/.kube/config"

# Retain your requested k8admin user, but do not clobber an existing account.
if ! id k8admin >/dev/null 2>&1; then
  adduser --disabled-password --gecos "" k8admin
fi

usermod -aG sudo k8admin
install -d -m 0700 -o k8admin -g k8admin /home/k8admin/.kube
install -m 0600 -o k8admin -g k8admin \
  /etc/kubernetes/admin.conf \
  /home/k8admin/.kube/config

cat > /etc/profile.d/kubectl_alias.sh <<'EOF'
alias k='kubectl'
EOF
chmod 0644 /etc/profile.d/kubectl_alias.sh

# Use the Calico manifest URL deliberately. Pin a tested Calico release here
# if you want reproducible deployments rather than tracking the URL's content.
kubectl --kubeconfig=/etc/kubernetes/admin.conf apply \
  -f https://docs.projectcalico.org/manifests/calico.yaml

echo
echo "Kubernetes setup is complete."
echo "Installed Kubernetes repository minor: v${K8S_MINOR}"
echo "Verify with:"
echo "  kubectl get nodes"
echo "  kubectl get pods -A"
