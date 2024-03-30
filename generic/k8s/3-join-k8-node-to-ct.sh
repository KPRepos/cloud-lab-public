#!/bin/bash

# Update Join command below and run this shell script

# kubeadm join 10.0.0.223:6443 --token h5bqd5xxxxxx \
# 	--discovery-token-ca-cert-hash sha256:38c7a44d9d81ebe70xxxxxxxxxxxx

# if token expired, get new token and ca cert uinsg belwo commands 
# kubeadm token create
# openssl x509 -pubkey -in /etc/kubernetes/pki/ca.crt | openssl rsa -pubin -outform der 2>/dev/null | openssl dgst -sha256 -hex | sed 's/^.* //'

kubeadm join ControlPlane-IP:6443 --token 99ivet.0vykxxxxxx \
	--discovery-token-ca-cert-hash sha256:38c7a4xxxxxxx

# Set up local kubeconfig
mkdir -p $HOME/.kube
# cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
# chown $(id -u):$(id -g) $HOME/.kube/config


# Set up for kubeadmin user

adduser --disabled-password --gecos "" k8admin
usermod -aG sudo k8admin
mkdir -p /home/k8admin/.kube
# cp -i /etc/kubernetes/admin.conf /home/k8admin/.kube/config
# chown k8admin:k8admin /home/k8admin/.kube/config

#Installing Calico 
kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml


echo "Kubernetes setup is complete. Please review any commented out sections relevant to your setup."

# alias k='kubectl'
