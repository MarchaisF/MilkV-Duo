# How to add networking boot capability

1. Add network support at kernel level

The kernel must be able to get an IP address alone at boot (without waiting for network daemon in userspace)
`Networking support` $\rightarrow$ `Networking options`

-   `<*>` **TCP/IP networking** (`CONFIG_INET`)
-   `<*>` **IP: kernel level autoconfiguration** (`CONFIG_IP_PNP`)
    -   `<*>` **IP: DHCP support** (`CONFIG_IP_PNP_DHCP`) _(Recommanded if your router/server handles DHCP)_
    -   `<*>` **IP: BOOTP support** (`CONFIG_IP_PNP_BOOTP`) _(Optionnal)_
    -   `<*>` **IP: RARP support** (`CONFIG_IP_PNP_RARP`) _(Optionnal)_

2. Enable network chip driver (Ethernet)

Ensure the hardware network driver of the SoC is included in the kernel and not compiled as a module
`Device Drivers` $\rightarrow$ `Network device support` $\rightarrow$ `Ethernet driver support`

-   Enable SoC specific network driver with `<*>`.

3. Enable NFS client and NFS root

This step allows to mount / via NFS during boot process

`File systems`  $\rightarrow$  `Network File Systems`
-   `<*>`  **NFS client support** (`CONFIG_NFS_FS`)
-   `<*>` **NFS client support for NFS version 3** (`CONFIG_NFS_V3`) _(Highly recommended, rather simple to configure compared to NFSv4)_
-   `<*>`  **Root file system on NFS** (`CONFIG_ROOT_NFS`)

4. U-Boot bootloager configuration

The TFTP kernel download is handled by the bootloader. We have to tell U-Boot to do so, how to get an IP address, where to find the kernel, how to mount the rootfs and so on.

Here is an example of the bootargs to be set in U-Boot :

    console=ttyS0,115200 root=/dev/nfs nfsroot=192.168.1.10:/srv/nfs/rootfs,v3,tcp ip=dhcp rw

Parameters details :

 - root=/dev/nfs: indicates to the kernel to mount the root via NFS
 - nfsroot=<SERVER_IP>:<NFS_PATH>,v3,tcp: TFTP/NFS server address and exported folder path
 - ip=dhcp: asks to the kernel to use integrated DHCP client (IP_PNP) to get it IP address
 - rw: mounts the filesystem in read/write

> Written with [StackEdit](https://stackedit.io/).
