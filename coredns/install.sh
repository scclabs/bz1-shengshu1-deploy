#!/bin/bash

set -e 

export PDSH_RCMD_TYPE=ssh
export PDSH_REMOTE_PDCP_PATH=/usr/bin/pdcp
export PDSH_SSH_ARGS_APPEND="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"

nodes=${*}

if [[ -z ${nodes} ]]; then echo "empty nodes"; exit 0; fi

# mkdir -p tmp
# wget https://github.com/coredns/coredns/releases/download/v1.12.2/coredns_1.12.2_linux_amd64.tgz -O tmp/coredns.tgz
# tar xf tmp/coredns.tgz -C tmp

pdsh -w "${nodes}" rm /etc/apt/apt.conf.d/80proxy
pdsh -w "${nodes}" apt update
pdsh -w "${nodes}" apt install -y pdsh
pdsh -w "${nodes}" systemctl disable --now systemd-resolved
pdsh -w "${nodes}" "echo nameserver 223.5.5.5 | tee /etc/resolv.conf"
pdsh -w "${nodes}" "echo nameserver 119.29.29.29 | tee -a /etc/resolv.conf"
pdsh -w "${nodes}" "mkdir -p /opt/paratera/coredns/{bin,conf}"

pdcp -w "${nodes}" tmp/coredns /opt/paratera/coredns/bin/coredns
pdcp -w "${nodes}" Corefile /opt/paratera/coredns/conf/Corefile
pdcp -w "${nodes}" coredns.service /etc/systemd/system/coredns.service

pdsh -w "${nodes}" systemctl enable --now coredns.service
