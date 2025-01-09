#!/bin/bash

# 设置参数
PROJECT_ID="siyuxtest"          # 替换为你的 GCP 项目 ID
ZONE="europe-west1-b"                   # 修改为欧洲的 west 区域
MACHINE_TYPE="n2-standard-2"            # 虚拟机类型
IMAGE_FAMILY="ubuntu-2204-lts"          # 使用 Ubuntu Server 22.04
IMAGE_PROJECT="ubuntu-os-cloud"         # 官方镜像项目
TAG="allow-all"                         # 防火墙规则标签
VM_NAMES=("vm1" "vm2" "vm3")            # 虚拟机名称数组
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

# 设置防火墙规则
echo "Setting up firewall rules..."
gcloud compute firewall-rules create "$TAG" \
  --project="$PROJECT_ID" \
  --allow tcp,icmp \
  --direction=INGRESS \
  --priority=1000 \
  --target-tags="$TAG" \
  --quiet
echo "Firewall rules created successfully."

# 配置虚拟机
echo "Installing dependencies on VMs..."
for VM in "${VM_NAMES[@]}"; do
  gcloud compute ssh "$VM" --zone="$ZONE" --command="bash -c '
    sudo apt update &&
    sudo apt install -y python3-pip &&
    echo \"Dependencies installed successfully on $VM.\"
  '"
done

echo "All VMs are ready for Kubernetes setup!"