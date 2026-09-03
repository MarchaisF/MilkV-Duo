# Debian rootfs creation

## Package installation if needed

    sudo apt install mmdebstrap qemu-user-static

## Target directory creation

    mkdir -p duos-rootfs

# Minimal Debian Trixie rootfs generation

    sudo mmdebstrap \
      --arch=arm64 \
      --variant=minbase \
      --include=systemd,systemd-sysv,dbus,iproute2,isc-dhcp-client,nfs-common,openssh-server,nano,ca-certificates,udev,vim-tiny,locales,systemd-timesyncd,kmod,sudo,libatomic1,network-manager,wpasupplicant,bluetooth,bluez,libubootenv-tool \
      trixie \
      ./duos-rootfs \
      http://deb.debian.org/debian
    
    sudo chroot duos-rootfs /bin/bash

## Hostname and root password definition

    echo "duos-debian" > /etc/hostname
    echo "127.0.0.1 MilkV-DuoS" >> /etc/hosts
    passwd root

## Automatic NFS root mount setting

    echo "proc /proc proc defaults 0 0" > /etc/fstab

## Allow root SSH (if wanted)

    echo "PermitRootLogin yes" >> /etc/ssh/sshd_config
    exit

## Getting a working serial console (no more needed, added at install)

    apt update && apt install -y udev
    systemctl status systemd-udevd
    udevadm trigger --subsystem-match=tty

## Locales

    apt install locales
    dpkg-reconfigure locales
    134

## NTP server (no more needed, added at install)

    date -s "2026-08-03 23:38:00"
    apt install systemd-timesyncd
    timedatectl set-ntp true

## Timezone setting

    sudo timedatectl set-timezone Europe/Paris

## U-boot environement variables edition from command line
    cat << 'EOF' > /etc/fw_env.config
    # Device        Offset      Env. size   Sector size
    /dev/mmcblk0    0xa00000    0x20000     0x200
    EOF
