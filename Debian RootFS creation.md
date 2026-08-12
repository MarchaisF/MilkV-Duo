# Debian rootfs creation

## Package installation if needed

    sudo apt install mmdebstrap qemu-user-static

## Target directory creation

    mkdir -p duos-rootfs

# Minimal Debian Trixie rootfs generation

    sudo mmdebstrap \
      --arch=arm64 \
      --variant=minbase \
      --include=systemd,systemd-sysv,dbus,iproute2,isc-dhcp-client,nfs-common,openssh-server,nano,ca-certificates,udev,vim-tiny,locales,systemd-timesyncd,kmod \
      trixie \
      ./duos-rootfs \
      http://deb.debian.org/debian
    
    sudo chroot duos-rootfs /bin/bash

## Hostname and root password definition

    echo "duos-debian" > /etc/hostname
    passwd root

## Automatic NFS root mount setting

    echo "proc /proc proc defaults 0 0" > /etc/fstab

## Allow root SSH (if wanted)

    echo "PermitRootLogin yes" >> /etc/ssh/sshd_config
    exit

## Getting a working serial console

    apt update && apt install -y udev
    systemctl status systemd-udevd
    udevadm trigger --subsystem-match=tty

## Locales

    apt install locales
    dpkg-reconfigure locales
    134

## NTP server

    date -s "2026-08-03 23:38:00"
    apt install systemd-timesyncd
    timedatectl set-ntp true
    timedatectl status
