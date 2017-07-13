#!/bin/sh

# Meant to be executed from within XCode.
# See http://help.apple.com/xcode/mac/8.0/#/itcaec37c2a6 for a list of config variables.

if [ "X${BUILT_PRODUCTS_DIR}" = "X" ]; then
    echo "BUILT_PRODUCTS_DIR undefined; exiting."
    exit 1
fi

echo "Configuring Settings Bundle."

PLIST=/usr/libexec/PlistBuddy
PRODUCT_PATH="${BUILT_PRODUCTS_DIR}/${PRODUCT_NAME}.app"
INFOPLIST_PATH="${PRODUCT_PATH}/Info.plist"
SETTINGS_BUNDLE_PATH="${PRODUCT_PATH}/Settings.bundle"
SETTINGS_ROOT_PLIST_PATH="${SETTINGS_BUNDLE_PATH}/Root.plist"

# Check for presence of app group ID in Info.plist.
APP_GRP_ID=$(${PLIST} -c "Print KIAppGroupKey" ${INFOPLIST_PATH})
if [ "X${APP_GRP_ID}" = "X" ]; then
echo "WARN: No plist value found for KIAppGroupKey, skipping patch of Settings.bundle."
exit 0
fi

EXISTING_SETTINGS_APP_GRP_ID=$(${PLIST} -c "Print ApplicationGroupContainerIdentifier" ${SETTINGS_ROOT_PLIST_PATH})

if [ "X${EXISTING_SETTINGS_APP_GRP_ID}" != "X" ]; then
# We have an app grp id in settings; update it.
echo "Found existing Settings.bundle:ApplicationGroupContainerIdentifier == ${EXISTING_SETTINGS_APP_GRP_ID}; deleting it."
RMCMD="Delete ApplicationGroupContainerIdentifier"
echo "Executing '${PLIST} -c \"${RMCMD}\" ${SETTINGS_ROOT_PLIST_PATH}'"
${PLIST} -c "${RMCMD}" ${SETTINGS_ROOT_PLIST_PATH}
fi

SETCMD="Add ApplicationGroupContainerIdentifier string group.${APP_GRP_ID}"
echo "Will execute: '${PLIST} -c \"${SETCMD}\" ${SETTINGS_ROOT_PLIST_PATH}'"
${PLIST} -c "${SETCMD}" ${SETTINGS_ROOT_PLIST_PATH}

