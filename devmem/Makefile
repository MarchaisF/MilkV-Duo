# Build and deployment helpers for the ARM64 devmem compatibility utility.
#
# Example:
#   make -C devmem deploy-camera-prereqs TARGET=root@192.168.0.234 \
#     CROSS_COMPILE=/path/to/aarch64-linux-gnu-

DEVMEM_DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
REPO_DIR := $(abspath $(DEVMEM_DIR)/..)
SDK_DIR ?= $(REPO_DIR)/sdk_build
CROSS_COMPILE ?= aarch64-linux-gnu-
TARGET ?=
SSH ?= ssh
SCP ?= scp
BUILD_DIR ?= $(DEVMEM_DIR)/.build
OUTPUT ?= $(BUILD_DIR)/devmem

VCODEC_FIRMWARE_DIR := $(SDK_DIR)/device/generic/rootfs_overlay/common/usr/share/fw_vcodec
DEVMEM_SOURCE := $(DEVMEM_DIR)/devmem.c
DEVMEM := $(OUTPUT)
VCODEC_FIRMWARE := $(VCODEC_FIRMWARE_DIR)/coda980.bin $(VCODEC_FIRMWARE_DIR)/monet.bin

.PHONY: help check-camera-prereqs build devmem deploy-camera-prereqs

help:
	@printf '%s\n' \
	  'Targets:' \
	  '  build                  Build the ARM64 devmem compatibility utility.' \
	  '  devmem                 Alias for build.' \
	  '  deploy-camera-prereqs  Deploy devmem and VENC firmware to TARGET.' \
	  '' \
	  'Variables:' \
	  '  SDK_DIR=$(SDK_DIR)' \
	  '  CROSS_COMPILE=$(CROSS_COMPILE)' \
	  '  OUTPUT=$(OUTPUT)' \
	  '  TARGET=root@duos-debian'

check-camera-prereqs:
	@test -f "$(DEVMEM_SOURCE)" || { echo "Missing $(DEVMEM_SOURCE)"; exit 1; }
	@test -f "$(VCODEC_FIRMWARE_DIR)/coda980.bin" || { echo "Missing coda980.bin below $(SDK_DIR)"; exit 1; }
	@test -f "$(VCODEC_FIRMWARE_DIR)/monet.bin" || { echo "Missing monet.bin below $(SDK_DIR)"; exit 1; }

$(DEVMEM): $(DEVMEM_SOURCE) | $(BUILD_DIR)
	@mkdir -p "$(dir $@)"
	$(CROSS_COMPILE)gcc -static -O2 -std=c11 -Wall -Wextra $< -o $@

$(BUILD_DIR):
	mkdir -p $@

build: $(DEVMEM)

devmem: build

deploy-camera-prereqs: check-camera-prereqs devmem
	@test -n "$(TARGET)" || { echo "Set TARGET, for example TARGET=root@duos-debian"; exit 1; }
	$(SCP) "$(DEVMEM)" $(VCODEC_FIRMWARE) "$(TARGET):/tmp/"
	$(SSH) "$(TARGET)" 'set -eu; install -Dm755 /tmp/devmem /usr/bin/devmem; install -Dm644 /tmp/coda980.bin /usr/share/fw_vcodec/coda980.bin; install -Dm644 /tmp/monet.bin /usr/share/fw_vcodec/monet.bin; rm -f /tmp/devmem /tmp/coda980.bin /tmp/monet.bin; command -v devmem; test -s /usr/share/fw_vcodec/coda980.bin'
