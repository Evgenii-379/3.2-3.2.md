#!/bin/bash

set -e

echo "[Step 1] Отключаем swap..."
swapoff -a
sed -i '/ swap / s/^/#/' /etc/fstab

echo "[Step 2] Установка зависимостей..."
apt update && apt upgrade -y
apt install -y apt-transport-https ca-certificates curl gnupg lsb-release

echo "[Step 3] Установка containerd..."
apt install -y containerd

mkdir -p /etc/containerd
containerd config default | tee /etc/containerd/config.toml

sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
systemctl restart containerd
systemctl enable containerd

echo "[Step 4] Установка Kubernetes компонентов..."
# Удаляем старый репозиторий (если есть)
rm -f /etc/apt/sources.list.d/kubernetes.list

# Добавляем официальный репозиторий Kubernetes для Ubuntu Jammy
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.28/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.28/deb/ /" | sudo tee /etc/apt/sources.list.d/kubernetes.list

apt update
apt install -y kubelet kubeadm kubectl
apt-mark hold kubelet kubeadm kubectl

echo "[Step 5] Настройка параметров ядра..."

cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
br_netfilter
EOF

modprobe br_netfilter

cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF

# Применяем параметры:
sysctl --system


echo " Базовая установка завершена."
