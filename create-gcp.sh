#!/bin/bash

# Ensure the script exits immediately if a command fails
set -e

# Step 1: Generate a local SSH key pair
# Check if SSH key already exists, if not, create it
if [[ ! -f ~/.ssh/id_rsa_gcp ]]; then
    echo "Generating SSH key pair..."
    ssh-keygen -t rsa -b 2048 -f ~/.ssh/id_rsa_gcp -C "siyux1927@gmail.com" -N ""
    echo "SSH key pair generated: ~/.ssh/id_rsa_gcp and ~/.ssh/id_rsa_gcp.pub"
else
    echo "SSH key pair already exists. Skipping generation."
fi

# Step 2: Prepare the public key in the GCP format
PUBLIC_KEY=$(cat ~/.ssh/id_rsa_gcp.pub)
USERNAME="siyux1927"
GCP_PUBLIC_KEY="${USERNAME}:${PUBLIC_KEY}"
echo "Formatted public key: ${GCP_PUBLIC_KEY}"

# Step 3: Upload the public key to GCP project metadata
# echo "Uploading SSH public key to project metadata..."
# gcloud compute project-info add-metadata \
#     --metadata ssh-keys="${GCP_PUBLIC_KEY}"

# Step 4: Create a firewall rule to allow ICMP and SSH traffic for "cc" tagged VMs
# echo "Creating a firewall rule for ICMP and SSH traffic..."
# gcloud compute firewall-rules create allow-icmp-ssh \
#     --direction=INGRESS \
#     --action=ALLOW \
#     --rules=icmp,tcp:22 \
#     --target-tags=cc

# Step 5: Launch multiple GCP instances
MACHINE_TYPES=("c3-standard-4" "c4-standard-4" "n4-standard-4" "e2-standard-4")
DISK_SIZE=100  # Disk size in GB
ZONE="europe-west1-b"
IMAGE_PROJECT="ubuntu-os-cloud"
IMAGE_FAMILY="ubuntu-2204-lts"

echo "Launching GCP instances..."
for MACHINE_TYPE in "${MACHINE_TYPES[@]}"; do
    INSTANCE_NAME="vm-${MACHINE_TYPE}"
    echo "Creating instance: ${INSTANCE_NAME} with machine type: ${MACHINE_TYPE}"
    
    gcloud compute instances create "${INSTANCE_NAME}" \
        --zone="${ZONE}" \
        --machine-type="${MACHINE_TYPE}" \
        --image-family="${IMAGE_FAMILY}" \
        --image-project="${IMAGE_PROJECT}" \
        --boot-disk-size="${DISK_SIZE}" \
        --metadata-from-file ssh-keys=/Users/siyux1927/.ssh/id_rsa_gcp.pub \
        --tags="cc" \
        --metadata nested-virtualization-enabled=true

    echo "Instance ${INSTANCE_NAME} created successfully."
done

echo "All instances created successfully."