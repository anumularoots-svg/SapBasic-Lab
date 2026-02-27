#!/bin/bash
set -e
hostnamectl set-hostname sap-student-${student_id}
mkdir -p /mnt/sapsoft /mnt/hanabackup
grep -q '/mnt/sapsoft' /etc/fstab || \
  echo '${nfs_gateway_ip}:/mnt/sapsoft /mnt/sapsoft nfs defaults,_netdev,nofail 0 0' >> /etc/fstab
grep -q '/mnt/hanabackup' /etc/fstab || \
  echo '${nfs_gateway_ip}:/mnt/hanabackup /mnt/hanabackup nfs defaults,_netdev,nofail 0 0' >> /etc/fstab
mount -a 2>/dev/null || true
echo "Setup complete: student${student_id}" >> /var/log/student-setup.log
