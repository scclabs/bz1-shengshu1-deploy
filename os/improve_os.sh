#!/bin/bash

set -e 

export PDSH_RCMD_TYPE=ssh
export PDSH_REMOTE_PDCP_PATH=/usr/bin/pdcp
export PDSH_SSH_ARGS="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR"
export PDSH_SSH_ARGS_APPEND="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"

nodes=${*}

if [[ -z ${nodes} ]]; then echo "empty nodes"; exit 0; fi

# allow linux kernel upgrade
pdsh -w "${nodes}" rm /etc/apt/preferences.d/nolinuxupgrades
pdsh -w "${nodes}" rm /etc/apt/apt.conf.d/80proxy

# install pdsh and other tools
# pdsh -w "${nodes}" rm /etc/apt/apt.conf.d/80proxy
pdsh -w "${nodes}" apt update
pdsh -w "${nodes}" 'apt install -y pdsh net-tools cpufrequtils socat build-essential linux-headers-$(uname -r) gcc make tuned'

# disable linux kernel auto upgrade
# pdsh -w "${nodes}" mkdir -p /etc/apt/preferences.d
# pdcp -w "${nodes}" nolinuxupgrades /etc/apt/preferences.d/nolinuxupgrades
pdcp -w "${nodes}" noupgrade.sh /tmp/noupgrade.sh
pdsh -w "${nodes}" /tmp/noupgrade.sh


# enable cpu performance mode
pdsh -w "${nodes}" systemctl enable tuned --now
pdsh -w "${nodes}" tuned-adm profile latency-performance

# disable firewall
pdsh -w "${nodes}" ufw disable

# resolve container log too long issue
pdcp -w "${nodes}" 80-inotify.conf /etc/sysctl.d/
pdsh -w "${nodes}" sysctl --system | grep 80-inotify.conf -A 2

# disable ssh password login
pdsh -w "${nodes}" mkdir -p /etc/ssh/sshd_config.d
pdcp -w "${nodes}" 50-cloud-init.conf /etc/ssh/sshd_config.d/50-cloud-init.conf
pdsh -w "${nodes}" systemctl reload ssh

# sleep 2

# config timesyncd
# pdcp -w "${nodes}" timesyncd.conf /etc/systemd/timesyncd.conf
# pdsh -w "${nodes}" systemctl restart systemd-timesyncd
# pdsh -w "${nodes}" timedatectl set-timezone Asia/Shanghai
# pdsh -w "${nodes}" timedatectl timesync-status

# config nvidia driver
pdcp -w "${nodes}" nvidia-persistenced.service /lib/systemd/system/nvidia-persistenced.service
pdsh -w "${nodes}" systemctl enable --now nvidia-persistenced

# update grub
# pdsh -w "${nodes}" 'sed -i -e "s/^GRUB_CMDLINE_LINUX_DEFAULT=.*/GRUB_CMDLINE_LINUX_DEFAULT=\"quiet splash nokaslr amd_iommu=off\"/" -e "s/^GRUB_CMDLINE_LINUX=.*/GRUB_CMDLINE_LINUX=\"apparmor=0\"/" /etc/default/grub'
pdsh -w "${nodes}" 'sed -i -e "s/^GRUB_CMDLINE_LINUX_DEFAULT=.*/GRUB_CMDLINE_LINUX_DEFAULT=\"quiet splash nokaslr intel_iommu=off\"/" -e "s/^GRUB_CMDLINE_LINUX=.*/GRUB_CMDLINE_LINUX=\"apparmor=0\"/" /etc/default/grub'
pdsh -w "${nodes}" update-grub

# update /etc/hosts
pdsh -w "${nodes}" 'grep -q "10.196.255.200 lb-apiserver.kubernetes.local" /etc/hosts || echo "10.196.255.200 lb-apiserver.kubernetes.local" >> /etc/hosts'

pdsh -w "${nodes}" <<- 'EOF'
mkdir -p /mnt/nvme0n1 
mkfs.ext4 /dev/nvme0n1
UUID=$(blkid -s UUID -o value /dev/nvme0n1) && (grep -qs "$UUID" /etc/fstab && echo "/etc/fstab 中已存在 $UUID" || (echo "UUID=$UUID  /mnt/nvme0n1   ext4  defaults  0  2" | sudo tee -a /etc/fstab && mount -a))
EOF

pdsh -w "${nodes}" <<- 'EOF'
mkdir -p /mnt/nvme0n1/containerd /mnt/nvme0n1/kubelet /var/lib/containerd /var/lib/kubelet
grep -qs "/mnt/nvme0n1/containerd" /etc/fstab && echo "/etc/fstab 中已存在 /mnt/nvme0n1/containerd" || (echo "/mnt/nvme0n1/containerd /var/lib/containerd none defaults,bind 0 0" | sudo tee -a /etc/fstab && mount -a)
grep -qs "/mnt/nvme0n1/kubelet" /etc/fstab && echo "/etc/fstab 中已存在 /mnt/nvme0n1/kubelet" || (echo "/mnt/nvme0n1/kubelet /var/lib/kubelet none defaults,bind 0 0" | sudo tee -a /etc/fstab && mount -a)
EOF

# change dns and netplan
# pdsh -w "${nodes}" "sed -i '/nameservers:/,/search:/ { /^\s*-\s*[0-9]\{1,3\}\(\.[0-9]\{1,3\}\)\{3\}$/d; /addresses:/s/$/ \n        - 223.5.5.5\n        - 119.29.29.29/ }' /etc/netplan/00-installer-config.yaml"

pdsh -w "${nodes}" tuned-adm active
pdsh -w "${nodes}" 'lscpu | grep "Thread(s) per core"'
pdsh -w "${nodes}" 'ip link show bond0 | grep mtu'
pdsh -w "${nodes}" 'cat /etc/netplan/00-installer-config.yaml | grep nameservers -A 5'
pdsh -w "${nodes}" apt-mark showhold
