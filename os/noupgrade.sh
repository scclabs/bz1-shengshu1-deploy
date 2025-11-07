#!/bin/bash

# 获取当前内核版本
kernel_version=$(uname -r)

# 要修改的GRUB配置文件路径
grub_config="/etc/default/grub"

# 检查第6行是否包含 GRUB_DEFAULT=
if grep -q "^GRUB_DEFAULT=" "$grub_config"; then
    # 检查第6行是否是GRUB_DEFAULT=开头
    current_grub_default=$(sed -n '6p' "$grub_config")
    if [[ "$current_grub_default" == GRUB_DEFAULT=* ]]; then
        # 使用sed命令替换第6行的GRUB_DEFAULT值为新的内核版本
        sudo sed -i "6s|^GRUB_DEFAULT=.*|GRUB_DEFAULT=\"Advanced options for Ubuntu>Ubuntu, with Linux $kernel_version\"|" $grub_config
        # 更新 grub 配置
        sudo update-grub
        echo "内核版本已更新到GRUB配置中，当前内核版本：$kernel_version"
    else
        echo "第6行不符合预期格式，未进行修改。"
    fi
else
    echo "没有找到GRUB_DEFAULT配置项，未进行修改。"
fi


rm -f /etc/apt/apt.conf.d/50unattended-upgrades

systemctl stop unattended-upgrades.service
systemctl disable unattended-upgrades.service

for i in `dpkg -l | grep -E '^(ii|hi)\s+linux-(generic|headers|image|modules)' | awk '!/linux-(generic|headers-generic|image-generic)/ {print $2}' | grep 'generic$'`;do apt-mark hold $i;done

systemctl status sleep.target

