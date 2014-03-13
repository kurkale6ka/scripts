#! /usr/bin/env bash

# virt-install --os-variant list

(($# == 1)) || { echo 'Usage: vinstall <vm>' >&2; exit 1; }

images="$HOME"/images
name="$1"

image="$images/$name".img
size=7 # in Gigabytes

# Mirrors found at: http://isoredirect.centos.org/centos/6/isos/x86_64/
# The location must be the root directory of an install tree
# Note the URL must specify the major version only: 6 Vs 6.4!
mirror=http://mirror.as29550.net/mirror.centos.org/6/os/x86_64/

# # http://fedoraproject.org/wiki/Anaconda/Kickstart
# wgetpaste -r << 'KS'
# install
# text
# reboot
# lang en_GB.UTF-8
# keyboard uk
# network --bootproto dhcp
# rootpw password
# firewall --disabled
# selinux --disabled
# timezone --utc Europe/London
# bootloader --location=mbr --append="console=tty0 console=ttyS0,115200 rd_NO_PLYMOUTH"
# zerombr
# clearpart --all --initlabel
# autopart
#
# %packages
# @core
# vim-enhanced
# %end
# # %end (unavailable in centos 5)
# KS

# I used to use the qemu group (Vs kvm)
if qemu-img create "$image" "$size"G && chown mitko:kvm "$image"
then
   virt-install                                          \
      --location "$mirror"                               \
      --connect qemu:///system                           \
      --extra-args "ks=http://dpaste.com/1719977/plain/" \
      --name "$name"                                     \
      --ram 2048                                         \
      --vcpus 2                                          \
      --os-type linux                                    \
      --os-variant rhel6                                 \
      --accelerate                                       \
      --hvm                                              \
      --network bridge=virbr0                            \
      --graphics none                                    \
      --disk path="$image",size="$size"
fi

# Note:
#    if using --graphics vnc, you can monitor the progress of your install with
#    a VNC client (use netstat -nltp to get the port (eg: localhost:5900))

# After reboot steps:
#    passwd
#    hostame <vm>
#    useradd <user>
#    passwd <user>
#    visudo (uncomment %wheel)
#    gpasswd -a <user> wheel
#    ifconfig (to see IP)
#    add <vm> to ~/.ssh/config
#    ssh-copy-id <vm>
