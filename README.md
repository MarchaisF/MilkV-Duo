# Milk-V Duo S — SDK build tools

Single-command, fully repeatable build of the Milk-V Duo S (SG2000 / CV181X)
SDK: kernel, kernel modules, Debian rootfs and deployable TFTP images, all
built from the **same source tree and the same `.config`** to guarantee
kernel/module ABI coherence.

---

## Repository contents

| File / Directory | Purpose |
|---|---|
| [`build_sdk.sh`](build_sdk.sh) | Main unified build script — clones the SDK, builds everything, produces a rootfs and `tftp_deploy/` in one command |
| [`build_arm_libs.sh`](build_arm_libs.sh) | Incremental build for AI/TPU libraries only (for use on an existing SDK checkout) |
| [`resources/kernel_fragments/`](resources/kernel_fragments/) | Kconfig fragments merged onto the vendor defconfig |
| [`resources/dts/displays/`](resources/dts/displays/) | Corrected device-tree overlays for SPI TFT displays (ILI9488, SPFD5408) |

---

## Quick start

### Prerequisites

```bash
# Debian / Ubuntu host
sudo apt install git build-essential cmake python3 python3-pip \
     gcc-aarch64-linux-gnu g++-aarch64-linux-gnu \
     bison flex libssl-dev libncurses-dev \
     mmdebstrap qemu-user-static debootstrap
```

### Build

```bash
git clone https://github.com/MarchaisF/MilkV-Duo.git
cd MilkV-Duo
./build_sdk.sh
```

By default the SDK is cloned into `./sdk_build/`.  Use `--workdir` to
choose a different location (e.g. an existing checkout):

```bash
./build_sdk.sh --workdir /path/to/duo-buildroot-sdk-v2
```

### Options

```
--workdir DIR        SDK working directory (default: ./sdk_build)
--clean              Remove build artefacts, keep downloads (like 'make clean')
--mrproper           Full reset: wipe everything and rebuild from scratch
--with-dvb           Keep the vendor DVB/DTV tuner modules (disabled by default)
--skip-sophgo-tdl-models  Skip cloning sophgo/tdl_models (offline build)
--help               Show all options
```

### Output

After a successful build:

| Path | Contents |
|---|---|
| `sdk_build/target_rootfs/` | Debian rootfs ready to export via NFS or flash to eMMC |
| `sdk_build/tftp_deploy/Image` | Kernel image to place on your TFTP server |
| `sdk_build/tftp_deploy/*.dtb` | Three DTBs: no display / ILI9488 / SPFD5408 |

Copy the DTB that matches your hardware alongside `Image` on the TFTP server.

---

## Kernel configuration

The vendor defconfig (`sg2000_milkv_duos_glibc_arm64_emmc_defconfig`) is
extended with three Kconfig fragments via `merge_config.sh`:

| Fragment | Effect |
|---|---|
| `nfs-tftp-boot.config` | NFS root + TFTP kernel boot (IP_PNP, NFS_FS, ROOT_NFS, …) |
| `spi-displays.config` | ILI9488 and SPFD5408 fbtft drivers |
| `disable-dvb.config` | Disables ~110 useless DVB frontend/tuner modules |

---

## Why this script exists

The Milk-V Duo S crashes when the booted kernel and the SDK kernel modules
are built from different `.config` files (different `CONFIG_CGROUPS`,
`CONFIG_SCHED_INFO`, etc. shift internal struct offsets → kernel panic in
`cv181x_base.ko`).  This script ensures the kernel, modules, and rootfs are
always built together from a single coherent configuration.
