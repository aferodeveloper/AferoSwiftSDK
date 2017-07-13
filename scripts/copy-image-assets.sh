#!/bin/sh

# Meant to be executed from within XCode.
# See http://help.apple.com/xcode/mac/8.0/#/itcaec37c2a6 for a list of config variables.

if [ "X${BUILT_PRODUCTS_DIR}" = "X" ]; then
    echo "BUILT_PRODUCTS_DIR undefined; exiting."
    exit 1
fi

if [ "X${CONTENTS_FOLDER_PATH}" = "X" ]; then
    echo "BUILD_PRODUCTS_DIR undefined; exiting."
    exit 2
fi

if [ "X${ASSETS_DIR}" = "X" ]; then
    ASSETS_DIR="iTokui/Assets"
fi

SRC_DIR=${ASSETS_DIR}
if [ ! -d "${SRC_DIR}" ]; then
    echo "Source dir '${SRC_DIR}' does not exist."
    exit 8
fi

TARGET_DIR=${BUILT_PRODUCTS_DIR}/${CONTENTS_FOLDER_PATH}
if [ ! -d "${TARGET_DIR}" ]; then
    echo "Target dir '${TARGET_DIR}' does not exist."
    exit 16
fi

echo "Copying images from '${SRC_DIR}' to '${TARGET_DIR}'"

# -v: verbose; -X: don't add extended attributes/resource forks.
CMD="(cd \"$SRC_DIR\" && ls -1 | egrep -i '(png|jpg|jpeg|ps)$' | while read f; do cp -vX \"\${f}\" \"${TARGET_DIR}\"; done)"

echo "Will execute '${CMD}'"

/bin/sh -c "${CMD}"

echo "Copy complete."


