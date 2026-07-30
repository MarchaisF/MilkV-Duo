# MilkV-Duo
Tryouts to make a usable distro for MilkV Duo based on Alpine Linux

# **Introduction**

This repository is dedicated to the MilkV Duo SBC. I personnaly own the Duo S but everything should work with other flavours of the board, except maybe the 64 Mb version
Although the SBC embeds a Cortex A53 ARM core, I don't know anything about RISC-V so I'll stick with this last one.
I'd like to be able to tinker with the board freely with a Raspberry OS-like experience; that's why I  don't like the provided SDK.

The idea is to make my own distro based on Alpine Linux, with the SDK functionnalities

Why Alpine Linux ?
 - It uses musl like the SDK
 - It is lightweight
 - I don't know it so it's an opportunity to learn

# The roadblockers

The T-Head XuanTie C906 core complies with a draft version of the vectorial extensions (Vector 0.7.1) and has T-Head optimized instructions as well. As a result, we can not use a mainline C compiler which complies with Vector 1.0. Doing so wil result in Ilegal instruction

## Step 1 : Kernel copy and necessary files

 
    SDK=/path/to/duo-buildroot-sdk-v2
    BOARD=sg2000_milkv_duos_musl_riscv64_emmc
    CHIP=cv181x
    # Kernel copy (It's a Sophgo custom fork, not a standard vanilla kernel.org)
    cp -r $SDK/linux_5.10 ~/MilkV-Duo/linux_5.10

Critical point: the DTS files are outside the kernel. The SDK symlinks in the kernel at build time. We must copy them manually

    # Destination in the kernel tree
    DTS_DIR=~/MilkV-Duo/linux_5.10/arch/riscv/boot/dts/cvitek
    # Base file (shared dtsi)
    cp $SDK/build/boards/default/dts/cv181x_riscv/cv181x_base_riscv.dtsi $DTS_DIR/
    # Board specific DTS
    cp $SDK/build/boards/cv181x/$BOARD/dts_riscv/${BOARD}.dts $DTS_DIR/

## Step 2 : defconfig copy :

    cd ~/MilkV-Duo/linux_5.10
    # defconfig copy in standard tree
    cp $SDK/build/boards/cv181x/$BOARD/linux/cvitek_${BOARD}_defconfig \arch/riscv/configs/cvitek_${BOARD}_defconfig

## Step 3 : Cross-compiler configuration

    export PATH=$SDK/host-tools/gcc/riscv64-linux-musl-x86_64/bin:$PATH
    export ARCH=riscv
    export CROSS_COMPILE=riscv64-unknown-linux-musl-

## Step 4 : Configure and compile kernel

    cd ~/MilkV-Duo/linux_5.10
    BUILD_DIR=./output
    # Apply defconfig in the out-of-tree output directory
    make O=$BUILD_DIR cvitek_${BOARD}_defconfig
    
    # (Optionnal) tune
    make O=$BUILD_DIR menuconfig
    
    # Compile kernel + modules
    make O=$BUILD_DIR -j$(nproc) Image modules

The output is here :

> out/arch/riscv/boot/Image ← kernel image
out/vmlinux ← complete ELF (debug)

