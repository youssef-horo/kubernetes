#!/bin/bash
apt update && apt upgrade -y
apt install vim sudo curl apt-transport-https gnupg2 -y 
cat <<EOF | sudo tee /etc/modules-load.d/containerd.conf
overlay
br_netfilter
EOF

modprobe overlay
modprobe br_netfilter

cat <<EOF | sudo tee /etc/sysctl.d/99-kubernetes-cri.conf
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF

apt install containerd -y
mkdir -p /etc/containerd

containerd config default  > /etc/containerd/config.toml && sed "s/SystemdCgroup = false/SystemdCgroup = true/g" /etc/containerd/config.toml -i

systemctl enable containerd && systemctl restart containerd

containerd config dump | grep SystemdCgroup

# Die Swap Partition disablen und in /etc/fstab auskommentieren
swapoff -a
 
SWAP=$(grep 'swap' /etc/fstab)

test ! -f /etc/fstab.backup && cp /etc/fstab /etc/fstab.backup
sed -i  -r "s|$SWAP|#$SWAP|" /etc/fstab

echo "Die Swap-Partition wurde disabled"

curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | gpg --dearmour -o /etc/apt/trusted.gpg.d/cgoogle.gpg

echo "deb [signed-by=/etc/apt/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list

apt update && apt install kubelet kubeadm kubectl -y && apt-mark hold kubelet kubeadm kubectl 

systemctl enable kubelet

tee /etc/modules-load.d/k8s.conf <<EOF
overlay
br_netfilter
EOF


tee /etc/sysctl.d/kubernetes.conf<<EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF
