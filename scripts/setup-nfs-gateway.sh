#!/bin/bash
# setup-nfs-gateway.sh — Run on NFS gateway EC2 after SSH tunnel is working
set -e
echo "Setting up NFS re-export..."

sudo zypper install -y nfs-kernel-server
sudo systemctl enable --now nfs-server

# Verify SSH tunnel mounts exist
if ! mountpoint -q /mnt/sapsoft; then
  echo "ERROR: /mnt/sapsoft not mounted. Set up SSH tunnel first."
  exit 1
fi

# Re-export to VPC
grep -q '/mnt/sapsoft' /etc/exports || \
  echo '/mnt/sapsoft    10.0.0.0/16(ro,sync,no_subtree_check,fsid=1)' | sudo tee -a /etc/exports
grep -q '/mnt/hanabackup' /etc/exports || \
  echo '/mnt/hanabackup 10.0.0.0/16(ro,sync,no_subtree_check,fsid=2)' | sudo tee -a /etc/exports

sudo exportfs -ra
echo "NFS re-export configured:"
sudo exportfs -v
