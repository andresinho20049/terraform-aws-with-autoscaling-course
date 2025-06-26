#!/bin/bash
echo "Configuring bastion host..."

EFS_FS_ID="${efs_file_system_id}"
AWS_REGION="${aws_region}"
EFS_MOUNT_POINT="/mnt/efs"
EFS_DNS="$${EFS_FS_ID}.efs.$${AWS_REGION}.amazonaws.com"

echo "Attempting to mount EFS $${EFS_DNS} to $${EFS_MOUNT_POINT}"
sudo mkdir -p "$${EFS_MOUNT_POINT}"
if ! mountpoint -q "$${EFS_MOUNT_POINT}"; then
    echo "EFS not mounted yet. Attempting to mount..."
    sudo mount -t nfs4 -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport "$${EFS_DNS}:/" "$${EFS_MOUNT_POINT}"
    if [ $? -eq 0 ]; then
        echo "EFS mounted successfully."
    else
        echo "Error: Failed to mount EFS on bastion. Check logs."
    fi
else
    echo "EFS already mounted at $${EFS_MOUNT_POINT}."
fi
echo "Bastion host configuration completed."