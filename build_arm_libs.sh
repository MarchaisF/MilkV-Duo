#!/bin/bash
set -uo pipefail

# Target directory for libraries and headers
TARGET_ROOTFS="target_rootfs"
TOP_DIR=$(pwd)
STAGING_DIR="${TOP_DIR}/staging_arm"
HOST_TOOLS_DIR="${TOP_DIR}/host_tools_internal"
EXTERNAL_RESOURCES_DIR="${TOP_DIR}/external_resources"
SOPHGO_TDL_MODELS_DIR="${EXTERNAL_RESOURCES_DIR}/tdl_models"
SOPHGO_TDL_MODELS_URL="https://github.com/sophgo/tdl_models.git"
SOPHGO_DEPLOYED_MODELS_LIST=()
CLEAN_BUILD=0

# Function to show help
show_help() {
    echo "Usage: $0 [target_rootfs_path] [--clean] [--help]"
    echo "  target_rootfs_path: Path to the target root filesystem (default: target_rootfs)"
    echo "  --clean: Wipe target_rootfs, staging_arm, host_tools_internal and all component"
    echo "           build_arm/build_host directories before building, for a fully"
    echo "           repeatable, from-scratch rootfs in a single command."
    echo "  --help: Show this help message"
    echo ""
    echo "Environment variables:"
    echo "  SKIP_SOPHGO_TDL_MODELS=1   Skip cloning/updating sophgo/tdl_models"
}

# Parse arguments: a single positional argument (target_rootfs path) plus flags,
# in any order, so the script remains a one-liner for a repeatable build.
POSITIONAL_SET=0
for arg in "$@"; do
    case "${arg}" in
        --help)
            show_help
            exit 0
            ;;
        --clean)
            CLEAN_BUILD=1
            ;;
        -*)
            echo "Unknown option: ${arg}"
            show_help
            exit 1
            ;;
        *)
            if [[ "${POSITIONAL_SET}" -eq 1 ]]; then
                echo "Unexpected extra argument: ${arg}"
                show_help
                exit 1
            fi
            TARGET_ROOTFS="${arg}"
            POSITIONAL_SET=1
            ;;
    esac
done

if [[ "${CLEAN_BUILD}" -eq 1 ]]; then
    echo "Performing a clean, from-scratch build (--clean): removing previous outputs..."
    rm -rf "${TARGET_ROOTFS}" "${STAGING_DIR}" "${HOST_TOOLS_DIR}"
    # Remove per-component build directories so every library is rebuilt from source.
    for build_dir in \
        flatbuffers/build_host flatbuffers/build_arm \
        cvibuilder/build_arm cnpy/build_arm cvikernel/build_arm \
        cviruntime/build_arm cvimath/build_arm ive/build_arm; do
        rm -rf "${TOP_DIR}/${build_dir}"
    done
    rm -rf oss/build_zlib cvi_rtsp/prebuilt cvi_rtsp/install
    rm -rf tdl_sdk/tmp tdl_sdk/install
    ( cd cvi_mpi && make clean_all ) || true
fi

# Create target and staging directories
mkdir -p "${TARGET_ROOTFS}"
mkdir -p "${STAGING_DIR}"
mkdir -p "${HOST_TOOLS_DIR}"
mkdir -p "${EXTERNAL_RESOURCES_DIR}"

# Source environment setup. envsetup_milkv.sh isn't written for strict mode
# (it reads variables like $TOP without ever setting them first), so relax
# -u/-o pipefail just for this call.
echo "Setting up environment..."
set +u +o pipefail
source build/envsetup_milkv.sh milkv-duos-glibc-arm64-emmc || { echo "Failed to source envsetup_milkv.sh"; exit 1; }
set -u -o pipefail

# Put the cross-compiler in PATH for the rest of the script (and all subshells).
export PATH="${CROSS_COMPILE_PATH}/bin:${PATH}"

# Function to build and install a component
build_and_install() {
    local component_name=$1
    local build_cmd=$2
    local install_cmd=$3

    echo "Building ${component_name}..."
    ( eval "${build_cmd}" ) || { echo "Failed to build ${component_name}"; exit 1; }

    echo "Installing ${component_name}..."
    ( eval "${install_cmd}" ) || { echo "Failed to install ${component_name}"; exit 1; }
}

sync_sophgo_tdl_models() {
    if [[ "${SKIP_SOPHGO_TDL_MODELS}" == "1" ]]; then
        echo "Skipping Sophgo tdl_models sync (SKIP_SOPHGO_TDL_MODELS=1)"
        return 0
    fi

    echo "Syncing Sophgo tdl_models..."
    if [[ -d "${SOPHGO_TDL_MODELS_DIR}/.git" ]]; then
        GIT_TERMINAL_PROMPT=0 git -C "${SOPHGO_TDL_MODELS_DIR}" pull --ff-only || {
            echo "Failed to update ${SOPHGO_TDL_MODELS_DIR}"
            exit 1
        }
    elif [[ -e "${SOPHGO_TDL_MODELS_DIR}" ]]; then
        echo "${SOPHGO_TDL_MODELS_DIR} exists but is not a git repository"
        exit 1
    else
        GIT_TERMINAL_PROMPT=0 git clone --depth 1 "${SOPHGO_TDL_MODELS_URL}" "${SOPHGO_TDL_MODELS_DIR}" || {
            echo "Failed to clone ${SOPHGO_TDL_MODELS_URL}"
            exit 1
        }
    fi
}

# --- 0. Zlib (Prebuilt from OSS) ---
echo "Installing prebuilt Zlib..."
mkdir -p oss/build_zlib
tar -xf oss/oss_release_tarball/64bit/zlib.tar.gz -C oss/build_zlib
mkdir -p "${STAGING_DIR}/include"
mkdir -p "${STAGING_DIR}/lib"
mkdir -p "${STAGING_DIR}/share"
cp -rav oss/build_zlib/include/* "${STAGING_DIR}/include/"
cp -rav oss/build_zlib/lib/* "${STAGING_DIR}/lib/"
cp -rav oss/build_zlib/share/* "${STAGING_DIR}/share/"

# --- 1. Flatbuffers (Host) ---
build_and_install "flatbuffers-host" \
    "mkdir -p flatbuffers/build_host && cd flatbuffers/build_host && cmake .. -DCMAKE_INSTALL_PREFIX=${HOST_TOOLS_DIR} -DFLATBUFFERS_BUILD_TESTS=OFF && make -j$(nproc)" \
    "cd flatbuffers/build_host && make install"

# --- 2. Flatbuffers (ARM) ---
build_and_install "flatbuffers-arm" \
    "mkdir -p flatbuffers/build_arm && cd flatbuffers/build_arm && cmake .. -DCMAKE_TOOLCHAIN_FILE=${TOP_DIR}/cviruntime/scripts/toolchain-aarch64-linux.cmake -DCMAKE_INSTALL_PREFIX=${STAGING_DIR} -DFLATBUFFERS_BUILD_SHAREDLIB=ON -DFLATBUFFERS_BUILD_TESTS=OFF -DFLATBUFFERS_BUILD_FLATC=OFF && make -j$(nproc)" \
    "cd flatbuffers/build_arm && make install"

# --- 3. Cvibuilder ---
build_and_install "cvibuilder" \
    "mkdir -p cvibuilder/build_arm && cd cvibuilder/build_arm && cmake .. -DFLATBUFFERS_PATH=${HOST_TOOLS_DIR} -DCMAKE_INSTALL_PREFIX=${STAGING_DIR} && make -j$(nproc)" \
    "cd cvibuilder/build_arm && make install"

# --- 4. Cnpy (ARM) ---
build_and_install "cnpy" \
    "mkdir -p cnpy/build_arm && cd cnpy/build_arm && cmake .. -DCMAKE_TOOLCHAIN_FILE=${TOP_DIR}/cviruntime/scripts/toolchain-aarch64-linux.cmake -DCMAKE_INSTALL_PREFIX=${STAGING_DIR} -DCMAKE_SYSROOT=${SYSROOT_PATH} && make -j$(nproc)" \
    "cd cnpy/build_arm && make install"

# --- 5. Cvikernel ---
build_and_install "cvikernel" \
    "mkdir -p cvikernel/build_arm && cd cvikernel/build_arm && cmake .. -DCMAKE_TOOLCHAIN_FILE=${TOP_DIR}/cviruntime/scripts/toolchain-aarch64-linux.cmake -DCMAKE_INSTALL_PREFIX=${STAGING_DIR} -DCHIP=cv181x && make -j$(nproc)" \
    "cd cvikernel/build_arm && make install"

# --- 6. Cviruntime (TPU) ---
build_and_install "cviruntime" \
    "mkdir -p cviruntime/build_arm && cd cviruntime/build_arm && cmake .. -DCMAKE_TOOLCHAIN_FILE=${TOP_DIR}/cviruntime/scripts/toolchain-aarch64-linux.cmake -DCMAKE_INSTALL_PREFIX=${STAGING_DIR} -DCHIP=cv181x -DRUNTIME=SOC -DCVIKERNEL_PATH=${STAGING_DIR} -DFLATBUFFERS_PATH=${STAGING_DIR} -DCVIBUILDER_PATH=${STAGING_DIR} -DCMAKE_PREFIX_PATH=${STAGING_DIR} -DCMAKE_SYSROOT=${SYSROOT_PATH} && make -j$(nproc)" \
    "cd cviruntime/build_arm && make install"

# --- 7. Cvimath ---
build_and_install "cvimath" \
    "mkdir -p cvimath/build_arm && cd cvimath/build_arm && cmake .. -DCMAKE_TOOLCHAIN_FILE=${TOP_DIR}/cviruntime/scripts/toolchain-aarch64-linux.cmake -DCMAKE_INSTALL_PREFIX=${STAGING_DIR} -DTPU_SDK_ROOT=${STAGING_DIR} && make -j$(nproc)" \
    "cd cvimath/build_arm && make install"

# --- 8. Cvi_mpi (ISP and Sensors) ---
build_and_install "cvi_mpi" \
    "cd cvi_mpi && make all" \
    "cd cvi_mpi && make install DESTDIR=${STAGING_DIR}"

# Stage MPI headers for downstream consumers such as ive.
mkdir -p "${STAGING_DIR}/include"
cp -rav cvi_mpi/include/* "${STAGING_DIR}/include/"

build_kernel_standalone() {
    local kernel_output_dir="${KERNEL_PATH}/${KERNEL_OUTPUT_FOLDER}"
    local kernel_defconfig="${BUILD_PATH}/boards/${CHIP_ARCH,,}/${PROJECT_FULLNAME}/linux/cvitek_${PROJECT_FULLNAME}_defconfig"

    if [[ "${CLEAN_BUILD}" -eq 1 ]]; then
        echo "Removing previous kernel output (--clean): ${kernel_output_dir}"
        rm -rf "${kernel_output_dir}"
    fi

    # Skip if already built (Module.symvers is the reliable completion marker)
    if [[ -f "${kernel_output_dir}/Module.symvers" ]]; then
        echo "Kernel already built, skipping."
        return 0
    fi

    echo "Building standalone kernel output..."
    make -C "${KERNEL_PATH}" ARCH=arm64 CROSS_COMPILE="${CROSS_COMPILE}" mrproper || {
        echo "Failed to clean kernel source tree"
        exit 1
    }
    mkdir -p "${kernel_output_dir}"
    cp -vf "${kernel_defconfig}" "${kernel_output_dir}/.config"

    make -C "${KERNEL_PATH}" O="${kernel_output_dir}" ARCH=arm64 CROSS_COMPILE="${CROSS_COMPILE}" olddefconfig || {
        echo "Failed to prepare kernel config"
        exit 1
    }

    make -j$(nproc) -C "${KERNEL_PATH}" O="${kernel_output_dir}" ARCH=arm64 CROSS_COMPILE="${CROSS_COMPILE}" Image modules || {
        echo "Failed to build kernel image/modules"
        exit 1
    }

    make -j$(nproc) -C "${KERNEL_PATH}" O="${kernel_output_dir}" ARCH=arm64 CROSS_COMPILE="${CROSS_COMPILE}" \
        INSTALL_MOD_PATH="${kernel_output_dir}/modules" \
        INSTALL_HDR_PATH="${kernel_output_dir}/arm64/usr" \
        modules_install headers_install || {
        echo "Failed to install kernel modules/headers"
        exit 1
    }

    mkdir -p "${kernel_output_dir}/usr"
    ln -snf "${kernel_output_dir}/arm64/usr/include" "${kernel_output_dir}/usr/include"
}

build_kernel_standalone

KERNEL_HEADERS_ROOT="${KERNEL_PATH}/${KERNEL_OUTPUT_FOLDER}/arm64/usr"

# --- 9. Ive ---
build_and_install "ive" \
    "mkdir -p ive/build_arm && cd ive/build_arm && cmake .. -DCMAKE_TOOLCHAIN_FILE=${TOP_DIR}/cviruntime/scripts/toolchain-aarch64-linux.cmake -DCMAKE_INSTALL_PREFIX=${STAGING_DIR} -DCVI_PLATFORM=CV181X -DMLIR_SDK_ROOT=${STAGING_DIR} -DMIDDLEWARE_SDK_ROOT=${STAGING_DIR} -DKERNEL_ROOT=${KERNEL_HEADERS_ROOT} -DKERNEL_HEADERS_ROOT=${KERNEL_HEADERS_ROOT} -DTC_PATH=${CROSS_COMPILE_PATH}/bin/ && make -j$(nproc)" \
    "cd ive/build_arm && make install"

# --- 10. Osdrv (Kernel Modules) ---
mkdir -p "${STAGING_DIR}/ko/3rd"
build_and_install "osdrv" \
    "K_DIR=${KERNEL_PATH}/${KERNEL_OUTPUT_FOLDER}; cd osdrv && INSTALL_DIR=${STAGING_DIR}/ko make KERNEL_DIR=\$K_DIR all" \
    "true"

# --- 11. Cvi_rtsp ---
echo "Installing prebuilt Live555..."
mkdir -p cvi_rtsp/prebuilt
tar -xf oss/oss_release_tarball/64bit/live555.tar.gz -C cvi_rtsp/prebuilt/
build_and_install "cvi_rtsp" \
    "cd cvi_rtsp && SDK_VER=64bit CROSS_COMPILE=aarch64-linux-gnu- MW_DIR=${TOP_DIR}/cvi_mpi LIVE555_DIR=${TOP_DIR}/cvi_rtsp/prebuilt ./build.sh" \
    "cd cvi_rtsp && make install DESTDIR=${STAGING_DIR}"

# --- 12. Tdl_sdk ---
rm -rf cvi_rtsp/install
mkdir -p cvi_rtsp/install
cp -a "${STAGING_DIR}/include" cvi_rtsp/install/
cp -a "${STAGING_DIR}/lib" cvi_rtsp/install/
rm -rf "${OUTPUT_DIR}/tpu_64bit/cvitek_tpu_sdk" "${OUTPUT_DIR}/tpu_64bit/cvitek_ive_sdk"
mkdir -p "${OUTPUT_DIR}/tpu_64bit/cvitek_tpu_sdk/include" \
         "${OUTPUT_DIR}/tpu_64bit/cvitek_tpu_sdk/lib" \
         "${OUTPUT_DIR}/tpu_64bit/cvitek_ive_sdk/include" \
         "${OUTPUT_DIR}/tpu_64bit/cvitek_ive_sdk/lib"
cp -a "${STAGING_DIR}/include/." "${OUTPUT_DIR}/tpu_64bit/cvitek_tpu_sdk/include/"
cp -a "${STAGING_DIR}/lib/." "${OUTPUT_DIR}/tpu_64bit/cvitek_tpu_sdk/lib/"
cp -a "${STAGING_DIR}/include/." "${OUTPUT_DIR}/tpu_64bit/cvitek_ive_sdk/include/"
cp -a "${STAGING_DIR}/lib/." "${OUTPUT_DIR}/tpu_64bit/cvitek_ive_sdk/lib/"
build_and_install "tdl_sdk" \
    "cd tdl_sdk && ./build_tdl_sdk.sh all" \
    "cp -a tdl_sdk/install/* ${STAGING_DIR}/"

# --- 13. Isp_tuning (Config files) ---
echo "Copying ISP tuning configurations..."
mkdir -p "${STAGING_DIR}/etc/cvitek"
cp -rf isp_tuning/cv181x/src/* "${STAGING_DIR}/etc/cvitek/"

# --- Final Step: Install into target_rootfs using FHS layout for Debian ---
KERNEL_VER=$(ls "${KERNEL_PATH}/${KERNEL_OUTPUT_FOLDER}/modules/lib/modules/")
echo "Installing artifacts to ${TARGET_ROOTFS} (FHS layout, kernel ${KERNEL_VER})..."

# Shared libraries → /usr/lib/
mkdir -p "${TARGET_ROOTFS}/usr/lib"
find "${STAGING_DIR}/lib/" -maxdepth 1 -name '*.so*' -exec cp -a {} "${TARGET_ROOTFS}/usr/lib/" \;
find "${STAGING_DIR}/usr/lib/" -maxdepth 1 -name '*.so*' -exec cp -a {} "${TARGET_ROOTFS}/usr/lib/" \; 2>/dev/null || true
# ive installs its TPU extension lib under ex_lib/, not lib/ or usr/lib/ — don't miss it.
find "${STAGING_DIR}/ex_lib/" -maxdepth 1 -name '*.so*' -exec cp -a {} "${TARGET_ROOTFS}/usr/lib/" \; 2>/dev/null || true
if [[ -d "${STAGING_DIR}/usr/lib/3rd" ]]; then
    mkdir -p "${TARGET_ROOTFS}/usr/lib/cvitek/3rd"
    find "${STAGING_DIR}/usr/lib/3rd/" -name '*.so*' -exec cp -a {} "${TARGET_ROOTFS}/usr/lib/cvitek/3rd/" \;
fi
if [[ -d "${STAGING_DIR}/sample/3rd" ]]; then
    mkdir -p "${TARGET_ROOTFS}/usr/lib/cvitek/3rd"
    find "${STAGING_DIR}/sample/3rd/" -path '*/lib/*.so*' -exec cp -a {} "${TARGET_ROOTFS}/usr/lib/cvitek/3rd/" \;
fi

# ldconfig config so the dynamic linker finds all cvitek libs
mkdir -p "${TARGET_ROOTFS}/etc/ld.so.conf.d"
cat > "${TARGET_ROOTFS}/etc/ld.so.conf.d/cvitek.conf" << 'EOF'
# Cvitek SG2000 / CV181X SDK libraries
/usr/lib
/usr/lib/cvitek/3rd
EOF

# Kernel modules → /lib/modules/<version>/extra/cvitek/
KO_DEST="${TARGET_ROOTFS}/lib/modules/${KERNEL_VER}/extra/cvitek"
mkdir -p "${KO_DEST}/3rd"
find "${STAGING_DIR}/ko/" -maxdepth 1 -name '*.ko' -exec cp -f {} "${KO_DEST}/" \;
find "${STAGING_DIR}/ko/3rd/" -name '*.ko' -exec cp -f {} "${KO_DEST}/3rd/" \; 2>/dev/null || true

# modules-load.d: load CVI kernel modules at boot via systemd-modules-load
MODULES_LOAD_DIR="${TARGET_ROOTFS}/etc/modules-load.d"
mkdir -p "${MODULES_LOAD_DIR}"
cat > "${MODULES_LOAD_DIR}/cvitek.conf" << 'EOF'
# Cvitek SG2000 / CV181X kernel modules
# Loaded at boot by systemd-modules-load.service
# Order matters: dependencies first
cv181x_sys
cv181x_base
cv181x_rtos_cmdqu
cv181x_fast_image
cvi_mipi_rx
snsr_i2c
cv181x_vi
cv181x_vpss
cv181x_dwa
cv181x_vo
cv181x_mipi_tx
cv181x_rgn
cv181x_clock_cooling
cv181x_tpu
cv181x_vcodec
cv181x_jpeg
cvi_vc_driver
cv181x_ive
EOF

# Binaries → /usr/bin/ (SDK samples)
mkdir -p "${TARGET_ROOTFS}/usr/bin"
[[ -d "${STAGING_DIR}/usr/bin" ]] && cp -a "${STAGING_DIR}/usr/bin/." "${TARGET_ROOTFS}/usr/bin/"
# TDL/AI samples → dedicated dir to avoid polluting /usr/bin
mkdir -p "${TARGET_ROOTFS}/usr/share/cvitek/samples"
[[ -d "${STAGING_DIR}/bin" ]] && cp -a "${STAGING_DIR}/bin/." "${TARGET_ROOTFS}/usr/share/cvitek/samples/"
ln -sfn . "${TARGET_ROOTFS}/usr/share/cvitek/samples/bin"

# Sample launcher scripts from cviruntime
[[ -d "cviruntime/samples" ]] && \
    find cviruntime/samples -maxdepth 1 -name 'run_*.sh' -exec cp -a {} "${TARGET_ROOTFS}/usr/share/cvitek/samples/" \;
mkdir -p "${TARGET_ROOTFS}/usr/share/cvitek/samples/samples_extra"
[[ -d "cviruntime/samples/samples_extra" ]] && \
    find cviruntime/samples/samples_extra -maxdepth 1 -name 'run_*.sh' -exec cp -a {} "${TARGET_ROOTFS}/usr/share/cvitek/samples/samples_extra/" \;
ln -sfn .. "${TARGET_ROOTFS}/usr/share/cvitek/samples/samples_extra/bin"
ln -sfn ../data "${TARGET_ROOTFS}/usr/share/cvitek/samples/samples_extra/data"

# Sample resources (images, labels) bundled in the SDK
mkdir -p "${TARGET_ROOTFS}/usr/share/cvitek/samples/data"
[[ -d "cviruntime/samples/data" ]] && \
    cp -a cviruntime/samples/data/. "${TARGET_ROOTFS}/usr/share/cvitek/samples/data/"
[[ -d "cviruntime/samples/samples_extra/data" ]] && \
    cp -a cviruntime/samples/samples_extra/data/. "${TARGET_ROOTFS}/usr/share/cvitek/samples/data/"

# A few demo models are available in the SDK tree; expose them under a stable path
mkdir -p "${TARGET_ROOTFS}/usr/share/cvitek/models"
[[ -d "device/generic/rootfs_overlay/duos/mnt/cvimodel" ]] && \
    cp -a device/generic/rootfs_overlay/duos/mnt/cvimodel/. "${TARGET_ROOTFS}/usr/share/cvitek/models/"
[[ -d "cvi_rtsp/cvi_models" ]] && \
    cp -a cvi_rtsp/cvi_models/. "${TARGET_ROOTFS}/usr/share/cvitek/models/"
sync_sophgo_tdl_models
if [[ "${SKIP_SOPHGO_TDL_MODELS}" != "1" ]]; then
    mkdir -p "${TARGET_ROOTFS}/usr/share/cvitek/models/tdl_models"
    while IFS= read -r model_path; do
        cp -a "${model_path}" "${TARGET_ROOTFS}/usr/share/cvitek/models/tdl_models/"
        SOPHGO_DEPLOYED_MODELS_LIST+=("$(basename "${model_path}")")
    done < <(find "${SOPHGO_TDL_MODELS_DIR}" -type f -name '*cv181x*.cvimodel' | sort)
    if ! compgen -G "${TARGET_ROOTFS}/usr/share/cvitek/models/tdl_models/*.cvimodel" > /dev/null; then
        echo "No cv181x .cvimodel files were found in ${SOPHGO_TDL_MODELS_DIR}"
        exit 1
    fi
fi
mkdir -p "${TARGET_ROOTFS}/mnt"
ln -sfn /usr/share/cvitek/models "${TARGET_ROOTFS}/mnt/cvimodel"

# Helper to set sample-related environment variables and show available launchers
cat > "${TARGET_ROOTFS}/usr/bin/cvitek-samples-env" << 'EOF'
#!/bin/bash

CVITEK_SAMPLES_DIR=/usr/share/cvitek/samples
CVITEK_SAMPLES_EXTRA_DIR=/usr/share/cvitek/samples/samples_extra
CVITEK_MODELS_DIR=/usr/share/cvitek/models

if [[ -d "${CVITEK_MODELS_DIR}/tdl_models" ]]; then
    DEFAULT_MODEL_PATH="${CVITEK_MODELS_DIR}/tdl_models"
else
    DEFAULT_MODEL_PATH=/mnt/cvimodel
fi

show_launchers() {
    local dir=$1
    if compgen -G "${dir}/run_*.sh" > /dev/null; then
        find "${dir}" -maxdepth 1 -name 'run_*.sh' -printf '  %f\n' | sort
    fi
}

show_help() {
    cat <<HELP_EOF
Usage:
  source /usr/bin/cvitek-samples-env

This sets:
  CVITEK_SAMPLES_DIR=${CVITEK_SAMPLES_DIR}
  CVITEK_SAMPLES_EXTRA_DIR=${CVITEK_SAMPLES_EXTRA_DIR}
  CVITEK_MODELS_DIR=${CVITEK_MODELS_DIR}
  MODEL_PATH=${DEFAULT_MODEL_PATH}

Quick start:
  source /usr/bin/cvitek-samples-env
  cd "${CVITEK_SAMPLES_DIR}"
  ./run_classifier.sh

Direct example:
  ${CVITEK_SAMPLES_DIR}/sample_img_face_det /mnt/cvimodel/scrfd_768_432_int8_1x.cvimodel ${CVITEK_SAMPLES_DIR}/data/obama1.jpg

Main launchers:
HELP_EOF
    show_launchers "${CVITEK_SAMPLES_DIR}"
    echo ""
    echo "Extra launchers:"
    show_launchers "${CVITEK_SAMPLES_EXTRA_DIR}"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    show_help
    exit 0
fi

export CVITEK_SAMPLES_DIR
export CVITEK_SAMPLES_EXTRA_DIR
export CVITEK_MODELS_DIR
export MODEL_PATH="${MODEL_PATH:-${DEFAULT_MODEL_PATH}}"

echo "cvitek sample environment loaded"
echo "  CVITEK_SAMPLES_DIR=${CVITEK_SAMPLES_DIR}"
echo "  CVITEK_SAMPLES_EXTRA_DIR=${CVITEK_SAMPLES_EXTRA_DIR}"
echo "  CVITEK_MODELS_DIR=${CVITEK_MODELS_DIR}"
echo "  MODEL_PATH=${MODEL_PATH}"
echo "Run 'cvitek-samples-env' to list available launcher scripts."
EOF
chmod 755 "${TARGET_ROOTFS}/usr/bin/cvitek-samples-env"

# ISP / sensor config files
mkdir -p "${TARGET_ROOTFS}/etc/cvitek"
[[ -d "${STAGING_DIR}/etc/cvitek" ]] && cp -a "${STAGING_DIR}/etc/cvitek/." "${TARGET_ROOTFS}/etc/cvitek/"

# OV5647 sensor config (two CSI connectors J1 and J2 on Duo S)
mkdir -p "${TARGET_ROOTFS}/etc/cvitek/sensor"
cp -f device/generic/rootfs_overlay/duos/mnt/data/sensor_cfg_OV5647_J1.ini \
    "${TARGET_ROOTFS}/etc/cvitek/sensor/" 2>/dev/null || true
cp -f device/generic/rootfs_overlay/duos/mnt/data/sensor_cfg_OV5647_J2.ini \
    "${TARGET_ROOTFS}/etc/cvitek/sensor/" 2>/dev/null || true
# ISP tuning bin for OV5647
mkdir -p "${TARGET_ROOTFS}/etc/cvitek/param"
cp -f device/generic/rootfs_overlay/common/mnt/cfg/param/cvi_sdr_bin_OV5647.bin \
    "${TARGET_ROOTFS}/etc/cvitek/param/" 2>/dev/null || true

# USB gadget scripts (RNDIS, NCM, host mode) – USB stack is built-in, no insmod needed
USB_SCRIPT_DIR="${TARGET_ROOTFS}/usr/share/cvitek/usb"
mkdir -p "${USB_SCRIPT_DIR}"
# run_usb.sh and uhubon.sh (gadget configfs helpers)
cp -f device/generic/br_overlay/common/etc/run_usb.sh  "${USB_SCRIPT_DIR}/"
cp -f device/generic/br_overlay/common/etc/uhubon.sh   "${USB_SCRIPT_DIR}/"
# Board-specific mode scripts (adapt /mnt/system/ko paths removed – USB is built-in)
for script in usb-rndis.sh usb-ncm.sh usb-host.sh; do
    src="device/generic/rootfs_overlay/duos/mnt/system/${script}"
    if [[ -f "${src}" ]]; then
        # Rewrite insmod paths: USB modules are built-in, strip those lines
        sed '/insmod.*\(configfs\|libcomposite\|u_serial\|usb_f_\|u_audio\|u_ether\|dwc2\)/d' \
            "${src}" > "${USB_SCRIPT_DIR}/${script}"
        chmod +x "${USB_SCRIPT_DIR}/${script}"
    fi
done
# Install convenience symlinks in /usr/sbin
mkdir -p "${TARGET_ROOTFS}/usr/sbin"
ln -sf /usr/share/cvitek/usb/usb-rndis.sh "${TARGET_ROOTFS}/usr/sbin/cvitek-usb-rndis"
ln -sf /usr/share/cvitek/usb/usb-ncm.sh   "${TARGET_ROOTFS}/usr/sbin/cvitek-usb-ncm"
ln -sf /usr/share/cvitek/usb/usb-host.sh  "${TARGET_ROOTFS}/usr/sbin/cvitek-usb-host"

# Generate README
KERNEL_VER_FINAL="${KERNEL_VER}"
cat > "${TARGET_ROOTFS}/usr/share/cvitek/README.md" << 'README_EOF'
# Cvitek SG2000 / Milk-V Duo S — SDK libraries on Debian Trixie

## First boot checklist

### 1. Rebuild module dependency map
After the first boot (or after installing new kernel modules), run:
\`\`\`
depmod -a
\`\`\`
Modules are installed in \`/lib/modules/KERNEL_VER_PLACEHOLDER/extra/cvitek/\`.
They are loaded automatically at boot by **systemd-modules-load** via
\`/etc/modules-load.d/cvitek.conf\`.

### 2. Update the dynamic linker cache
\`\`\`
ldconfig
\`\`\`
This makes all Cvitek \`.so\` files (in \`/usr/lib/\` and \`/usr/lib/cvitek/3rd/\`)
visible to the dynamic linker. Already configured via \`/etc/ld.so.conf.d/cvitek.conf\`.

### 3. Build fiptool for ARM64 (optional — needed to reflash RTOS firmware)

If you ever need to rebuild the RISC-V RTOS firmware autonomously on the board
(without an x86 host), compile \`fiptool\` natively:

\`\`\`bash
apt install build-essential git
git clone --depth 1 https://git.trustedfirmware.org/TF-A/trusted-firmware-a.git /opt/tf-a
make -C /opt/tf-a fiptool
install -m 755 /opt/tf-a/tools/fiptool/fiptool /usr/local/bin/fiptool
\`\`\`

This is a one-time operation. Once \`fiptool\` is in \`/usr/local/bin\`, the full
RTOS firmware build → pack → flash cycle can be done entirely on the Duo S.
See the **Real-time core** section below for the complete workflow.

---

## Library overview

| Library | Purpose |
|---|---|
| libcviruntime.so | TPU runtime (model inference) |
| libcvikernel.so | TPU kernel primitives |
| libcvimath.so | TPU math operations |
| libcvi_tdl.so | TDL (AI inference framework: faces, objects, etc.) |
| libcvi_ive.so / libcvi_ive_tpu.so | IVE (Image Vector Engine) |
| libsys.so / libvi.so / libvo.so / libvpss.so … | MPI middleware (ISP, video pipeline) |
| libcvi_rtsp.so | RTSP streaming server |
| libsns_ov5647.so / libsns_gc2083.so … | Sensor driver libraries |

---

## Camera (OV5647)

The OV5647 module is supported on both CSI connectors of the Duo S (J1 and J2).
Sensor config files are in \`/etc/cvitek/sensor/\`:
- \`sensor_cfg_OV5647_J1.ini\` — CSI connector J1
- \`sensor_cfg_OV5647_J2.ini\` — CSI connector J2

ISP tuning binary: \`/etc/cvitek/param/cvi_sdr_bin_OV5647.bin\`

### Quick camera test
\`\`\`bash
# Set the sensor config (adjust path for J1 or J2)
export SENSOR_CFG=/etc/cvitek/sensor/sensor_cfg_OV5647_J1.ini
/usr/bin/sample_vio
\`\`\`

---

## USB connectivity

The USB OTG stack (DWC2, gadget, RNDIS, NCM) is built into the kernel — no \`insmod\` needed.
Scripts are in \`/usr/share/cvitek/usb/\`, with symlinks in \`/usr/sbin/\`.

### RNDIS (USB Ethernet — Windows / Linux host)
\`\`\`bash
cvitek-usb-rndis
# Board IP: 192.168.42.1  — connect from host at 192.168.42.x
\`\`\`

### NCM (USB Ethernet — preferred on Linux/macOS host)
\`\`\`bash
cvitek-usb-ncm
# Board IP: 192.168.42.1
\`\`\`

### USB Host mode (connect USB peripherals to the board)
\`\`\`bash
cvitek-usb-host
\`\`\`

> **Note:** The \`run_usb.sh\` and \`uhubon.sh\` helper scripts are in
> \`/usr/share/cvitek/usb/\` and are called internally by the mode scripts.

---

## Samples (TDL / AI SDK)

AI inference samples are in \`/usr/share/cvitek/samples/\`.
They require a \`.cvimodel\` file (neural network compiled for the SG2000 TPU).

Bundled sample assets:
- images / labels: \`/usr/share/cvitek/samples/data/\`
- demo models: \`/mnt/cvimodel/\` (symlink to \`/usr/share/cvitek/models/\`)
- launcher scripts: \`/usr/share/cvitek/samples/run_*.sh\` and
  \`/usr/share/cvitek/samples/samples_extra/run_*.sh\`

Additional prebuilt models are synced during the build from Sophgo's \`tdl_models\` repository
(unless \`SKIP_SOPHGO_TDL_MODELS=1\` is set):
\`https://github.com/sophgo/tdl_models\`

### Deploying additional Sophgo models

By default, \`build_arm_libs.sh\` clones or updates:
\`\`\`bash
<sdk-root>/external_resources/tdl_models
\`\`\`

and copies all \`*cv181x*.cvimodel\` files into:
\`\`\`bash
/usr/share/cvitek/models/tdl_models/
\`\`\`

For an offline build, disable this step:
\`\`\`bash
SKIP_SOPHGO_TDL_MODELS=1 ./build_arm_libs.sh
\`\`\`

To add extra models manually, copy them into the same directory and then either call a
sample directly with the full model path, or export:
\`\`\`bash
export MODEL_PATH=/usr/share/cvitek/models/tdl_models
\`\`\`
and run the helper scripts from \`/usr/share/cvitek/samples/\`.

### Helper environment script

\`\`\`bash
source /usr/bin/cvitek-samples-env
cd "$CVITEK_SAMPLES_DIR"
./run_classifier.sh
\`\`\`

If executed directly, \`cvitek-samples-env\` prints the available launcher scripts.

The build script also prints the list of Sophgo \`cv181x\` models copied into
\`/usr/share/cvitek/models/tdl_models/\`.

### Example: face detection on an image
\`\`\`bash
/usr/share/cvitek/samples/sample_img_face_det /mnt/cvimodel/scrfd_768_432_int8_1x.cvimodel /usr/share/cvitek/samples/data/obama1.jpg
\`\`\`

### Example: run a packaged launcher script
\`\`\`bash
cd /usr/share/cvitek/samples
export MODEL_PATH=/mnt/cvimodel
./run_classifier.sh
\`\`\`

MPI middleware samples (ISP, video, audio) are in \`/usr/bin/\`:
\`\`\`bash
sample_venc   # H.264/H.265 encode test
sample_vdec   # decode test
sample_vio    # video input/output pipeline test
\`\`\`

---

## LED blink (GPIO)

The user LED on the Duo S is on GPIO 509 (XGPIOA[29]):
\`\`\`bash
echo 509 > /sys/class/gpio/export
echo out > /sys/class/gpio/gpio509/direction
while true; do
  echo 0 > /sys/class/gpio/gpio509/value; sleep 0.5
  echo 1 > /sys/class/gpio/gpio509/value; sleep 0.5
done
\`\`\`

---

## Real-time core (C906L RISC-V — FreeRTOS)

The SG2000 has a second CPU core (C906L, RISC-V 64-bit) running FreeRTOS.
The firmware binary is embedded in \`fip.bin\` and loaded by the bootloader at power-on.

### Step 1 — install the RISC-V toolchain on the Duo S

\`\`\`bash
apt install gcc-riscv64-unknown-elf binutils-riscv64-unknown-elf
# Verify
riscv64-unknown-elf-gcc --version
\`\`\`

This installs GCC 10.2 with support for \`rv64imafdc / lp64d\` — exactly the flags
the SDK uses. No x86 PC required for application compilation.

> **Note on T-Head extensions:** the SDK ships a custom T-Head GCC (v2.0.3.0-xialf)
> with C906-specific intrinsics. The Debian GCC does **not** support those, but the
> FreeRTOS application layer does not use them — only the pre-compiled HAL/BSP does.
> The Debian toolchain is fully usable for all application-level code.

---

### Step 2 — hello blink: LED on GPIO from the RTOS core

The user LED on the Duo S is connected to XGPIOA[29] (GPIO 509 on the Linux side,
but from the RTOS the hardware register is accessed directly via the HAL).

The simplest way to blink the LED **without reflashing** is from Linux using sysfs
(see the LED blink section above). To blink it from a **standalone RTOS firmware**,
you need to modify the FreeRTOS task sources and rebuild \`fip.bin\`.

Below is a self-contained FreeRTOS LED blink task for the C906L.
Save it as \`/opt/rtos-blink/blink_task.c\`:

\`\`\`c
/*
 * blink_task.c — blink the Duo S user LED from FreeRTOS (C906L core)
 *
 * The LED is on XGPIOA[29]. On the SG2000 the GPIO base address is 0x03020000.
 * XGPIOA group: base + 0x000, pin 29.
 * Registers (ARM PrimeCell GPIO, 32-bit):
 *   offset 0x000 : GPIODIR  (1=output)
 *   offset 0x004 : GPIODATA (bit per pin when direction=output)
 */
#include "FreeRTOS.h"
#include "task.h"

#define XGPIOA_BASE   0x03020000UL
#define GPIO_SWPORTA_DR   (*(volatile unsigned int *)(XGPIOA_BASE + 0x000))
#define GPIO_SWPORTA_DDR  (*(volatile unsigned int *)(XGPIOA_BASE + 0x004))
#define LED_PIN       (1U << 29)

void vBlinkTask(void *pvParameters)
{
    /* Set pin 29 as output */
    GPIO_SWPORTA_DDR |= LED_PIN;

    for (;;) {
        GPIO_SWPORTA_DR |=  LED_PIN;   /* LED on  */
        vTaskDelay(pdMS_TO_TICKS(500));
        GPIO_SWPORTA_DR &= ~LED_PIN;   /* LED off */
        vTaskDelay(pdMS_TO_TICKS(500));
    }
}

/* Register this task from your main() or cvirtos task entry point:
 *   xTaskCreate(vBlinkTask, "blink", 256, NULL, tskIDLE_PRIORITY + 1, NULL);
 */
\`\`\`

### Step 3 — build and deploy (requires x86 host for fip.bin packaging)

> **Important — why an x86 host is still required:**
> The RISC-V code itself can be compiled with `riscv64-unknown-elf-gcc` on any
> architecture including ARM64. However, the result must be packed into `fip.bin`
> together with ATF and U-Boot using `fiptool`. The SDK ships `fiptool` as a
> pre-built x86-64 binary — it cannot run on ARM64.
>
> **Workaround (advanced):** compile `fiptool` natively for ARM64:
> ```bash
> git clone --depth 1 https://git.trustedfirmware.org/TF-A/trusted-firmware-a.git
> cd trusted-firmware-a && make fiptool
> # produces tools/fiptool/fiptool — native ARM64 binary
> ```
> With this binary available on the Duo S the entire chain becomes self-contained.

On the **x86 host**, get the SDK source and build:
\`\`\`bash
# Clone (shallow)
git clone --depth 1 https://github.com/milkv-duo/duo-buildroot-sdk-v2
cd duo-buildroot-sdk-v2

# Drop your blink_task.c into the FreeRTOS task sources and register it in
# freertos/cvitek/task/main/src/, then:
source build/envsetup_milkv.sh milkv-duos-glibc-arm64-emmc
build_rtos    # compiles RTOS firmware
build_uboot   # repacks fip.bin with the new RTOS binary
\`\`\`

The output ELF and raw binary appear in \`freertos/cvitek/install/\`.
The repacked \`fip.bin\` is in \`install/soc_sg2000_milkv_duos_glibc_arm64_emmc/\`.

### Step 4 — flash fip.bin

\`\`\`bash
# WARNING: a wrong fip.bin can make the board unbootable.
# Recommended: use Milk-V's cvidownload tool or burn-image.sh
./burn-image.sh --board milkv-duos --image fip.bin
\`\`\`

> **During development:** prefer communicating with the existing RTOS firmware via
> \`/dev/cvi-rtos-cmdqu\` rather than reflashing on every iteration. Only reflash
> when the RTOS-side logic truly needs to change.

---

### ARM ↔ RTOS communication (cmdqu mailbox)

The two cores share a command queue through the \`cv181x_rtos_cmdqu\` kernel module
(auto-loaded at boot). The device node is \`/dev/cvi-rtos-cmdqu\`.

The header is installed at \`/usr/include/rtos_cmdqu.h\`.

#### Minimal ARM-side example

\`\`\`c
// cmdqu_test.c — send a message to the RTOS core
#include <stdio.h>
#include <fcntl.h>
#include <sys/ioctl.h>
#include "rtos_cmdqu.h"

int main(void) {
    int fd = open("/dev/cvi-rtos-cmdqu", O_RDWR);
    if (fd < 0) { perror("open"); return 1; }

    cmdqu_t cmd = {
        .ip_id  = IP_SYSTEM,
        .cmd_id = SYS_CMD_INFO_LINUX_INIT_DONE,
        .block  = 0,
    };
    if (ioctl(fd, RTOS_CMDQU_SEND, &cmd) < 0)
        perror("ioctl RTOS_CMDQU_SEND");

    close(fd);
    return 0;
}
\`\`\`

Compile on the Duo S:
\`\`\`bash
gcc -I/usr/include -o cmdqu_test cmdqu_test.c
./cmdqu_test
\`\`\`

See \`/usr/include/rtos_cmdqu.h\` for all IP types (\`IP_ISP\`, \`IP_VCODEC\`,
\`IP_VI\`, \`IP_RGN\`, \`IP_AUDIO\`, \`IP_SYSTEM\`) and command IDs.

---

## Troubleshooting

- **Modules not loading:** run \`depmod -a\` then \`systemctl restart systemd-modules-load\`
- **Library not found:** run \`ldconfig\` and check \`ldconfig -p | grep cvi\`
- **USB not working:** check \`dmesg | grep dwc2\` — the controller must show \`dual-role\`
- **Camera not detected:** verify the CSI cable and check \`dmesg | grep ov5647\`
README_EOF

# Substitute the kernel version placeholder (heredoc is quoted, no expansion)
sed -i "s|KERNEL_VER_PLACEHOLDER|${KERNEL_VER}|g" "${TARGET_ROOTFS}/usr/share/cvitek/README.md"

echo "Build and installation complete!"
echo ""
echo "Kernel version: ${KERNEL_VER}"
echo "Modules installed in: ${TARGET_ROOTFS}/lib/modules/${KERNEL_VER}/extra/cvitek/"
echo "Libraries installed in: ${TARGET_ROOTFS}/usr/lib/"
echo "README: ${TARGET_ROOTFS}/usr/share/cvitek/README.md"
if [[ "${SKIP_SOPHGO_TDL_MODELS}" != "1" ]]; then
    echo "Sophgo cv181x models installed in: ${TARGET_ROOTFS}/usr/share/cvitek/models/tdl_models/"
    echo "Sophgo cv181x models copied: ${#SOPHGO_DEPLOYED_MODELS_LIST[@]}"
    for model_name in "${SOPHGO_DEPLOYED_MODELS_LIST[@]}"; do
        echo "  - ${model_name}"
    done
fi
echo ""
echo "First-boot steps on the target:"
echo "  1. depmod -a"
echo "  2. ldconfig"
