#!/bin/bash

# Check if gcloud CLI is installed
if ! command -v gcloud &> /dev/null; then
    # 输出重定向到devnull，判断指令是否存在
    echo "Google Cloud CLI not installed. Please install it and configure it with 'gcloud init'."
    exit 1
fi

# Step 1: Generate a local SSH key pair if it doesn't already exist
# The key files will be named id_rsa and id_rsa.pub with "gcp_user" as a comment in the public key
if [ ! -f ~/.ssh/id_rsa ]; then
    # 测试[]，没有输出，判断是否存在
    # 生成rsa密钥，保存在-f，-C用作注释，-N为空密码
    ssh-keygen -t rsa -f ~/.ssh/id_rsa -C "gcp_user" -N ""
else
    echo "SSH key pair already exists at ~/.ssh/id_rsa"
fi

# Step 2: Prepare a modified copy of the public key for GCP
# Ensure that the username in the key matches the one used with ssh-keygen
# 读取公钥，保存在PUBLIC_KEY变量中，cat是读取文件内容，$()是命令替换
PUBLIC_KEY=$(cat ~/.ssh/id_rsa.pub)
# 将公钥写入文件，gcp_metadata_ssh_key，gcp_user:是固定的，PUBLIC_KEY是变量
echo "gcp_user:$PUBLIC_KEY" > ~/gcp_metadata_ssh_key

# Step 3: Upload the modified public key to GCP project metadata
# This allows SSH access to all instances in this project
#
gcloud compute project-info add-metadata \
    # compute涉及计算资源
    # project-info是项目信息
    # add-metadata是添加元数据，指定添加元数据
    # ssh-keys是ssh密钥，键和值
    # cat ~/gcp_metadata_ssh_key是读取文件内容
    --metadata ssh-keys="$(cat ~/gcp_metadata_ssh_key)"

# Step 4: Create a firewall rule that allows ICMP and SSH traffic for VMs tagged with "cc"
# Only create the rule if it doesn't already exist
# 列出防火墙规则（很多信息：IP地址，端口，协议。。。），简化输出，grep -q搜索无输出
# gcloud执行默认返回0
if gcloud compute firewall-rules list --filter="name=allow-icmp-ssh" --format="value(name)" | grep -q "allow-icmp-ssh"; then
    echo "Firewall rule 'allow-icmp-ssh' already exists. Skipping creation."
else
    gcloud compute firewall-rules create allow-icmp-ssh \
        --allow icmp,tcp:22 \
        --target-tags=cc
    echo "Firewall rule 'allow-icmp-ssh' created successfully."
fi

# Step 5: Launch three GCP instances, each with a different machine type
# Instances will have the "cc" tag, use the "Ubuntu Server 22.04" image,
# have nested virtualization enabled, and a disk size of 100GB

# Define the instance types
instance_types=("c3-standard-4" "c4-standard-4" "n4-standard-4" "e2-standard-4")

# Loop through the instance types and create instances with the specified settings
# 遍历实例类型，创建实例，指定设置

for instance_type in "${instance_types[@]}"; do
    gcloud compute instances create "instance-${instance_type}" \
        --machine-type=${instance_type} \
        --image-family=ubuntu-2204-lts \
        --image-project=ubuntu-os-cloud \
        --tags=cc \
        --boot-disk-size=100GB \
        --zone=us-central1-a \
        --metadata google-logging-enabled=true \
        --enable-nested-virtualization
    echo "Instance 'instance-${instance_type}' created successfully."
done

echo "All instances have been created and configured successfully."