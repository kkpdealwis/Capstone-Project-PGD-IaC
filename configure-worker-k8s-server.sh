#!/bin/bash
configure_containerd() {
    if [ ! -f /etc/modules-load.d/containerd.conf ]; then
    cat <<EOF | sudo tee /etc/modules-load.d/containerd.conf
overlay
br_netfilter
EOF
    fi

    if [ ! -f /etc/sysctl.d/99-kubernetes-cri.conf ]; then
    cat <<EOF | sudo tee /etc/sysctl.d/99-kubernetes-cri.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF
    fi

    sudo modprobe overlay
    sudo modprobe br_netfilter

    # Reload kernel parameters
    sudo sysctl --system

    # Configure containerd
    if [ ! -f /etc/containerd/config.toml ]; then
    sudo mkdir -p /etc/containerd
    containerd config default | sudo tee /etc/containerd/config.toml
    sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/g' /etc/containerd/config.toml
    sudo systemctl restart containerd
    fi
}

# Remove any preinstalled containerd packages
which containerd
if [ $? -eq 0 ]; then
    sudo systemctl stop containerd
    sudo apt-get remove -y containerd
    sudo apt-get purge -y containerd
    sudo apt -y autoremove
    [ -f /etc/modules-load.d/containerd.conf ] && sudo rm /etc/modules-load.d/containerd.conf
    [ -f /etc/sysctl.d/99-kubernetes-cri.conf ] && sudo rm /etc/sysctl.d/99-kubernetes-cri.conf
    [ -f /etc/containerd/config.toml ] && sudo rm /etc/containerd/config.toml
else
    echo "containerd is not installed.. continuing with installation"
fi

# Install containerd
sudo apt-get update
sudo apt-get install -y containerd
if [ $? -eq 0 ]; then
    echo "containerd installed successfully"
    configure_containerd
else
    echo "Issue with containerd installation - process aborted"
    exit 1
fi

# Install Kubernetes Components
sudo apt-get install -y apt-transport-https ca-certificates curl gpg
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.29/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.29/deb/ /" | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
if [ $? -eq 0 ]; then
    echo "Kubernetes components successfully installed"
    sudo apt-mark hold kubelet kubeadm kubectl
else
    echo "Issue installing Kubernetes components - process aborted"
    exit 2
fi