#!/bin/bash

# 设置参数
PROJECT_ID="siyuxtest"         # 替换为你的 GCP 项目 ID
ZONE="europe-west1-b"                  # 替换为你选择的 GCP 区域
MACHINE_TYPE="n2-standard-2"           # 虚拟机类型
IMAGE_FAMILY="ubuntu-2204-lts"         # 使用 Ubuntu Server 22.04
IMAGE_PROJECT="ubuntu-os-cloud"        # 官方镜像项目
TAG="restricted-access"                # 防火墙规则标签
VM_NAMES=("vm1" "vm2" "vm3")           # 虚拟机名称数组
SSH_PUBLIC_KEY="/Users/siyux1927/.ssh/id_rsa_gcp.pub" # 本地公钥路径

# 检查公钥是否存在
if [ ! -f "$SSH_PUBLIC_KEY" ]; then
  echo "Error: SSH public key not found at $SSH_PUBLIC_KEY"
  exit 1
fi

# 创建虚拟机
echo "Creating virtual machines..."
for VM in "${VM_NAMES[@]}"; do
  gcloud compute instances create "$VM" \
    --project="$PROJECT_ID" \
    --zone="$ZONE" \
    --machine-type="$MACHINE_TYPE" \
    --image-family="$IMAGE_FAMILY" \
    --image-project="$IMAGE_PROJECT" \
    --tags="$TAG" \
    --boot-disk-size=20GB \
    --metadata=ssh-keys="$(whoami):$(cat $SSH_PUBLIC_KEY)"
done
echo "Virtual machines created successfully."

# 设置防火墙规则（限制端口，仅开放 22 和 2379/2380）
echo "Setting up restrictive firewall rules..."
gcloud compute firewall-rules create "$TAG" \
  --project="$PROJECT_ID" \
  --allow tcp:22,tcp:2379,tcp:2380 \
  --target-tags="$TAG" \
  --description "Restrictive access for SSH and etcd communication" \
  --direction INGRESS
echo "Firewall rules created successfully."

# 为虚拟机设置无密码 sudo
echo "Configuring VMs for password-less sudo..."
for VM in "${VM_NAMES[@]}"; do
  EXTERNAL_IP=$(gcloud compute instances describe "$VM" --zone "$ZONE" --format='get(networkInterfaces[0].accessConfigs[0].natIP)')
  echo "Configuring $VM ($EXTERNAL_IP)..."
  ssh -i "$SSH_PUBLIC_KEY" -o StrictHostKeyChecking=no "$(whoami)@$EXTERNAL_IP" <<EOF
    # 添加当前用户到 sudoers
    echo "$(whoami) ALL=(ALL) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/$(whoami)
EOF
done
echo "Password-less sudo configuration completed."

# 测试 SSH 连接
echo "Testing SSH connections..."
for VM in "${VM_NAMES[@]}"; do
  EXTERNAL_IP=$(gcloud compute instances describe "$VM" --zone "$ZONE" --format='get(networkInterfaces[0].accessConfigs[0].natIP)')
  echo "Testing SSH for $VM ($EXTERNAL_IP)..."
  ssh -i "$SSH_PUBLIC_KEY" -o StrictHostKeyChecking=no "$(whoami)@$EXTERNAL_IP" "echo 'SSH connection to $VM successful.'"
done

echo "All VMs are ready for Ansible usage!"