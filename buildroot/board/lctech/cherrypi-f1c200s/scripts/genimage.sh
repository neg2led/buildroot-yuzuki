#!/bin/bash
set -e
STARTDIR=$(pwd)
SCRIPTDIR="$( cd -- "$(dirname "$0")" >/dev/null 2>&1; pwd -P )"
BOARDDIR=$(dirname ${SCRIPTDIR})

MKIMAGE="${HOST_DIR}/bin/mkimage"
IMAGE_ITS="kernel.its"
OUTPUT_NAME="kernel.itb"

[ $# -eq 2 ] || {
    echo "SYNTAX: $0 <output dir> <u-boot-with-spl image>"
    echo "Given: $@"
    exit 1
}

cp ${BOARDDIR}/scripts/${IMAGE_ITS} "${BINARIES_DIR}/"
cd "${BINARIES_DIR}"
"${MKIMAGE}" -f ${IMAGE_ITS} ${OUTPUT_NAME} && rm ${IMAGE_ITS} || exit 1

cd "${STARTDIR}/"
${BOARDDIR}/scripts/mknanduboot.sh ${1}/${2} ${1}/u-boot-sunxi-with-nand-spl.bin

# disable stop-on-error so our file checks don't break it; everything important has already failed
set +e

# sdcard ext4
if [[ -f "${BINARIES_DIR}/rootfs.ext4" ]]; then
    cp "${BOARDDIR}/uboot.env" "${BINARIES_DIR}/"
    ${CONFIG_DIR}/support/scripts/genimage.sh ${1} -c ${BOARDDIR}/genimage-sdcard.cfg
fi

# nand squashfs
if [[ -f "${BINARIES_DIR}/rootfs.squashfs" ]]; then
    ${CONFIG_DIR}/support/scripts/genimage.sh ${1} -c ${BOARDDIR}/genimage-nand-squashfs.cfg
fi

# nand ubifs
if [[ -f "${BINARIES_DIR}/rootfs.ubi" ]]; then
    ${CONFIG_DIR}/support/scripts/genimage.sh ${1} -c ${BOARDDIR}/genimage-nand-ubifs.cfg
fi
