# Домашнее задание к занятию «Установка Kubernetes»-***Вуколов Евгений***
 
### Цель задания
 
Установить кластер K8s.
 
### Чеклист готовности к домашнему заданию
 
1. Развёрнутые ВМ с ОС Ubuntu 20.04-lts.
 
### Инструменты и дополнительные материалы, которые пригодятся для выполнения задания
 
1. [Инструкция по установке kubeadm](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/create-cluster-kubeadm/).
2. [Документация kubespray](https://kubespray.io/).
 
-----
 
### Задание 1. Установить кластер k8s с 1 master node
 
1. Подготовка работы кластера из 5 нод: 1 мастер и 4 рабочие ноды.
2. В качестве CRI — containerd.
3. Запуск etcd производить на мастере.
4. Способ установки выбрать самостоятельно.
 
## Дополнительные задания (со звёздочкой)
 
**Настоятельно рекомендуем выполнять все задания под звёздочкой.** Их выполнение поможет глубже разобраться в материале.   
Задания под звёздочкой необязательные к выполнению и не повлияют на получение зачёта по этому домашнему заданию. 
 
------
### Задание 2*. Установить HA кластер
 
1. Установить кластер в режиме HA.
2. Использовать нечётное количество Master-node.
3. Для cluster ip использовать keepalived или другой способ.
 
### Правила приёма работы
 
1. Домашняя работа оформляется в своем Git-репозитории в файле README.md. Выполненное домашнее задание пришлите ссылкой на .md-файл в вашем репозитории.
2. Файл README.md должен содержать скриншоты вывода необходимых команд `kubectl get nodes`, а также скриншоты результатов.
3. Репозиторий должен содержать тексты манифестов или ссылки на них в файле README.md.


# **Решение**

### **Задание 1.**

- Для выполнения задания сначала при помощи terraform разварачиваю 5 VM в Yandex cloud, 1 master (2 CPU, 4 Гб RAM, доля CPU 20%, 30 Гб HDD), 4 work nodes (2 CPU, 4 Гб RAM, доля CPU 20%, 20 Гб HDD):

- Ссылка terraform:

[terraform](https://github.com/Evgenii-379/3.2-3.2.md/tree/main/terraform)

- ![scrin](https://github.com/Evgenii-379/3.2-3.2.md/blob/main/Снимок%20экрана%202025-04-07%20230202.png) 

- Для установки Kubernetes-кластера на 5 виртуальных машинах в Yandex Cloud (1 master + 4 worker nodes) с использованием containerd в качестве CRI и etcd на мастере, использую kubeadm.
Для этого создал Bash-скрипт, который запустил на всех нодах (мастер и воркеры) для базовой настройки containerd, kubelet и всех зависимостей:

- Ссылка на Bash скрипт:

[bash](https://github.com/Evgenii-379/3.2-3.2.md/tree/main/bash)

```
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


echo "✅ Базовая установка завершена."

```
- Затем в мастере выполнил команды: 

```
# Иициализация:

sudo kubeadm init --pod-network-cidr=10.244.0.0/16

mkdir -p $HOME/.kube
sudo cp /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# Установка CNI (Flannel):

kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml

```
- На WORKER-нодах — подключение к кластеру:

```
kubeadm join 10.128.0.31:6443 --token byoxv7.d838pyina9asqd3u --discovery-token-ca-cert-hash sha256:392d713021a3661b410cbc4f47505edbba418e4ef677d7f29f5f49248313b60f 

```

- ![scrin](https://github.com/Evgenii-379/3.2-3.2.md/blob/main/Снимок%20экрана%202025-04-07%20230014.png)
- ![scrin](https://github.com/Evgenii-379/3.2-3.2.md/blob/main/Снимок%20экрана%202025-04-07%20225923.png)
- ![scrin](https://github.com/Evgenii-379/3.2-3.2.md/blob/main/Снимок%20экрана%202025-04-07%20225905.png)

- Проверка на мастере:

```
kubectl get nodes

```

- ![scrin](https://github.com/Evgenii-379/3.2-3.2.md/blob/main/Снимок%20экрана%202025-04-07%20225812.png)


