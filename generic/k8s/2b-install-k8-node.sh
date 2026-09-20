#!/usr/bin/env bash
set -Eeuo pipefail

# Usage:
#   sudo ./install-node.sh
#   sudo ./install-node.sh 1.37
#
# Optional automatic join:
#   sudo ./install-node.sh 1.37 \
#     "kubeadm join 10.0.0.223:6443 --token abcdef.0123456789abcdef \
#      --discovery-token-ca-cert-hash sha256:<ca-hash>"
#
# Recommended workflow:
#   1. Run this script on the worker node.
#   2. On the control plane, run:
#        kubeadm token create --print-join-command
#   3. Run the printed kubeadm join command on this worker node.
#
# This script is for a fresh Ubuntu 24.04 worker node.
# It does NOT initialize a control plane and does NOT install a CNI.

if [[ "${EUID}" -ne 0 ]]; then
  echo "Run this script as root: sudo $0 [major.minor] ['kubeadm join ...']" >&2
  exit 1
fi

export DEBIAN_FRONTEND=noninteractive

K8S_VERSION_INPUT="${1:-}"
JOIN_COMMAND="${2:-}"

get_kubernetes_minor() {
  local requested="$1"
  local stable_version

  if [[ -n "${requested}" ]]; then
    # Accept 1.37, v1.37, 1.37.0, or v1.37.0.
    if [[ ! "${requested}" =~ ^v?[0-9]+\.[0-9]+(\.[0-9]+)?$ ]]; then
      echo "Invalid Kubernetes version: '${requested}'" >&2
      echo "Use a version such as: 1.37" >&2
      exit 1
    fi

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

validate_join_command() {
  local join_command="$1"

  if [[ -z "${join_command}" ]]; then
    return 0
  fi

  if [[ ! "${join_command}" =~ ^kubeadm[[:space:]]+join[[:space:]] ]]; then
    echo "The second argument must begin with: kubeadm join" >&2
    exit 1
  fi

  if [[ "${join_command}" != *"--discovery-token-ca-cert-hash sha256:"* ]]; then
    echo "Refusing an incomplete join command." >&2
    echo "Expected --discovery-token-ca-cert-hash sha256:<hash>." >&2
    exit 1
  fi
}

K8S_MINOR="$(get_kubernetes_minor "${K8S_VERSION_INPUT}")"
K8S_REPO="https://pkgs.k8s.io/core:/stable:/v${K8S_MINOR}/deb/"
K8S_KEY_URL="${K8S_REPO}Release.key"

validate_join_command "${JOIN_COMMAND}"

echo "Selected Kubernetes repository minor: v${K8S_MINOR}"
echo "Kubernetes repository: ${K8S_REPO}"

if [[ -n "${JOIN_COMMAND}" ]]; then
  echo "A kubeadm join command was supplied and will be run after installation."
else
  echo "No join command supplied. This node will be prepared but not joined."
fi

# ---------------------------------------------------------------------------
# Refuse obvious accidental reuse against an existing joined node
# ---------------------------------------------------------------------------
if [[ -f /etc/kubernetes/kubelet.conf ]]; then
  echo "This node appears to have already joined a Kubernetes cluster:"
  echo "  /etc/kubernetes/kubelet.conf exists"
  echo
  echo "Refusing to overwrite the existing kubeadm node configuration."
  echo "Use 'kubeadm reset' only if you intentionally want to remove it first."
  exit 1
fi

# ---------------------------------------------------------------------------
# Base packages
# ---------------------------------------------------------------------------
apt-get update
apt-get install -y \
  ca-certificates \
  curl \
  gpg \
  jq \
  nfs-common \
  apt-transport-https

install -d -m 0755 /etc/apt/keyrings

# ---------------------------------------------------------------------------
# Helm APT repository: Buildkite, not the broken Balto CDN endpoint
# ---------------------------------------------------------------------------
HELM_BUILDKITE_APT_KEY_ID="DDF78C3E6EBB2D2CC223C95C62BA89D07698DBC6"
HELM_KEY_TMP="$(mktemp)"

cleanup() {
  rm -f "${HELM_KEY_TMP}"
}
trap cleanup EXIT

curl --fail --silent --show-error --location \
  --retry 3 --retry-delay 2 \
  https://packages.buildkite.com/helm-linux/helm-debian/gpgkey \
  -o "${HELM_KEY_TMP}"

HELM_KEY_FINGERPRINT="$(
  gpg --show-keys --with-colons "${HELM_KEY_TMP}" \
    | awk -F: '$1 == "fpr" {print $10; exit}'
)"

if [[ "${HELM_KEY_FINGERPRINT}" != "${HELM_BUILDKITE_APT_KEY_ID}" ]]; then
  echo "ERROR: Unexpected Helm APT signing-key fingerprint." >&2
  echo "Expected: ${HELM_BUILDKITE_APT_KEY_ID}" >&2
  echo "Received: ${HELM_KEY_FINGERPRINT:-<none>}" >&2
  exit 1
fi

gpg --dearmor --yes \
  --output /etc/apt/keyrings/helm.gpg \
  "${HELM_KEY_TMP}"

chmod 0644 /etc/apt/keyrings/helm.gpg

cat > /etc/apt/sources.list.d/helm-stable-debian.list <<'EOF'
deb [signed-by=/etc/apt/keyrings/helm.gpg] https://packages.buildkite.com/helm-linux/helm-debian/any/ any main
EOF

chmod 0644 /etc/apt/sources.list.d/helm-stable-debian.list

# ---------------------------------------------------------------------------
# Kubernetes host prerequisites
# ---------------------------------------------------------------------------

# Kubernetes requires swap disabled unless explicitly configured otherwise.
swapoff -a

# Comment out all fstab-backed swap entries, rather than only /swap.img.
sed -ri '/^[[:space:]]*[^#].*[[:space:]]swap[[:space:]]/ s/^[[:space:]]*/#/' \
  /etc/fstab

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
# Docker APT repository: used solely for containerd.io
# ---------------------------------------------------------------------------
DOCKER_KEY_TMP="$(mktemp)"

curl --fail --silent --show-error --location \
  --retry 3 --retry-delay 2 \
  https://download.docker.com/linux/ubuntu/gpg \
  -o "${DOCKER_KEY_TMP}"

gpg --dearmor --yes \
  --output /etc/apt/keyrings/docker.gpg \
  "${DOCKER_KEY_TMP}"

rm -f "${DOCKER_KEY_TMP}"
chmod 0644 /etc/apt/keyrings/docker.gpg

ARCH="$(dpkg --print-architecture)"

. /etc/os-release
CODENAME="${VERSION_CODENAME:-}"

if [[ -z "${CODENAME}" ]]; then
  echo "Could not determine the Ubuntu codename from /etc/os-release." >&2
  exit 1
fi

cat > /etc/apt/sources.list.d/docker.list <<EOF
deb [arch=${ARCH} signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu ${CODENAME} stable
EOF

chmod 0644 /etc/apt/sources.list.d/docker.list

apt-get update
apt-get install -y containerd.io

# Kubernetes and containerd must use compatible cgroup-driver configuration.
install -d -m 0755 /etc/containerd
containerd config default > /etc/containerd/config.toml

sed -ri 's/^(\s*)SystemdCgroup = false/\1SystemdCgroup = true/' \
  /etc/containerd/config.toml

systemctl daemon-reload
systemctl enable --now containerd
systemctl restart containerd

# ---------------------------------------------------------------------------
# Kubernetes v${K8S_MINOR} package repository and node packages
# ---------------------------------------------------------------------------
K8S_KEY_TMP="$(mktemp)"

curl --fail --silent --show-error --location \
  --retry 3 --retry-delay 2 \
  "${K8S_KEY_URL}" \
  -o "${K8S_KEY_TMP}"

gpg --dearmor --yes \
  --output /etc/apt/keyrings/kubernetes-apt-keyring.gpg \
  "${K8S_KEY_TMP}"

rm -f "${K8S_KEY_TMP}"
chmod 0644 /etc/apt/keyrings/kubernetes-apt-keyring.gpg

cat > /etc/apt/sources.list.d/kubernetes.list <<EOF
deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] ${K8S_REPO} /
EOF

chmod 0644 /etc/apt/sources.list.d/kubernetes.list

apt-get update
apt-get install -y \
  helm \
  kubelet \
  kubeadm \
  kubectl

# Prevent unattended upgrades from silently changing the Kubernetes minor.
apt-mark hold kubelet kubeadm kubectl

systemctl enable --now kubelet

echo
echo "Worker node prerequisites are complete."
echo "Installed Kubernetes repository minor: v${K8S_MINOR}"
echo "Installed kubeadm version: $(kubeadm version -o short)"
echo

# ---------------------------------------------------------------------------
# Optional join
# ---------------------------------------------------------------------------
if [[ -n "${JOIN_COMMAND}" ]]; then
  echo "Joining Kubernetes cluster..."
  echo

  # The join command comes from the control plane:
  # kubeadm token create --print-join-command
  bash -c "${JOIN_COMMAND}"

  echo
  echo "Node successfully submitted a kubeadm join request."
  echo "Verify from the control plane with:"
  echo "  kubectl get nodes -o wide"
else
  echo "Run this on the control plane to generate a fresh join command:"
  echo "  kubeadm token create --print-join-command"
  echo
  echo "Then run the printed command on this worker node."
fi
