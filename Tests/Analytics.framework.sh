set -e
set +u
# Avoid recursively calling this script.
if [[ $SF_MASTER_SCRIPT_RUNNING ]]
then
exit 0
fi
set -u
export SF_MASTER_SCRIPT_RUNNING=1

SF_TARGET_NAME=${PROJECT_NAME}
SF_EXECUTABLE_PATH="lib${SF_TARGET_NAME}.a"
SF_WRAPPER_NAME="${SF_TARGET_NAME}.framework"

# The following conditionals come from
# https://github.com/kstenerud/iOS-Universal-Framework

if [[ "$SDK_NAME" =~ ([A-Za-z]+) ]]
then
SF_SDK_PLATFORM=${BASH_REMATCH[1]}
else
echo "Could not find platform name from SDK_NAME: $SDK_NAME"
exit 1
fi

if [[ "$SDK_NAME" =~ ([0-9]+.*$) ]]
then
SF_SDK_VERSION=${BASH_REMATCH[1]}
else
echo "Could not find sdk version from SDK_NAME: $SDK_NAME"
exit 1
fi

if [[ "$SF_SDK_PLATFORM" = "iphoneos" ]]
then
SF_OTHER_PLATFORM=iphonesimulator
else
SF_OTHER_PLATFORM=iphoneos
fi

if [[ "$BUILT_PRODUCTS_DIR" =~ (.*)$SF_SDK_PLATFORM$ ]]
then
SF_OTHER_BUILT_PRODUCTS_DIR="${BASH_REMATCH[1]}${SF_OTHER_PLATFORM}"
else
echo "Could not find platform name from build products directory: $BUILT_PRODUCTS_DIR"
exit 1
fi

# Build the other platform.
xcodebuild -project "${PROJECT_FILE_PATH}" -target "${TARGET_NAME}" -configuration "${CONFIGURATION}" -sdk ${SF_OTHER_PLATFORM}${SF_SDK_VERSION} BUILD_DIR="${BUILD_DIR}" OBJROOT="${OBJROOT}" BUILD_ROOT="${BUILD_ROOT}" SYMROOT="${SYMROOT}" $ACTION

# Smash the two static libraries into one fat binary and store it in the .framework
lipo -create "${BUILT_PRODUCTS_DIR}/${SF_EXECUTABLE_PATH}" "${SF_OTHER_BUILT_PRODUCTS_DIR}/${SF_EXECUTABLE_PATH}" -output "${BUILT_PRODUCTS_DIR}/${SF_WRAPPER_NAME}/Versions/A/${SF_TARGET_NAME}"

# Copy the binary to the other architecture folder to have a complete framework in both.
cp -a "${BUILT_PRODUCTS_DIR}/${SF_WRAPPER_NAME}/Versions/A/${SF_TARGET_NAME}" "${SF_OTHER_BUILT_PRODUCTS_DIR}/${SF_WRAPPER_NAME}/Versions/A/${SF_TARGET_NAME}"

#
# Custom Segment.io Code
# Bugs to ilya@segment.io
#

# Find the /analytics-ios/Releases folder
PROJECT_FOLDER="`dirname ${PROJECT_DIR}`"
RELEASE_FOLDER="`dirname ${PROJECT_DIR}`/Releases"

# Remove any existing release in the folder
rm -rf "$RELEASE_FOLDER/${SF_WRAPPER_NAME}"
# Copy from the /DerivedData build directory into our /Releases directory
cp -r "${BUILT_PRODUCTS_DIR}/${SF_WRAPPER_NAME}" "$RELEASE_FOLDER"
cd "$RELEASE_FOLDER/${SF_WRAPPER_NAME}"; ln -s "Analytics" "libAnalytics.a"
rm -rf "$RELEASE_FOLDER/${SF_WRAPPER_NAME}/Versions"
cp "$PROJECT_FOLDER/Analytics.podspec" "$RELEASE_FOLDER/Analytics.podspec"
cp "$PROJECT_FOLDER/License.md" "$RELEASE_FOLDER/License.md"

# Zip File
# Remove the zip we're also about to create
rm -rf "$RELEASE_FOLDER/${SF_WRAPPER_NAME}.zip"
# Create the zip archive
cd "$RELEASE_FOLDER"
zip -r -X -y "${SF_WRAPPER_NAME}.zip" "${SF_WRAPPER_NAME}"
zip -X -u "${SF_WRAPPER_NAME}.zip" "Analytics.podspec"
zip -X -u "${SF_WRAPPER_NAME}.zip" "License.md"
