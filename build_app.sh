#!/bin/bash

# Build script for creating a distributable macOS app bundle
# This script builds, archives, and exports the application

echo "Starting build process for 任务管理器..."

# Project settings
PROJECT_NAME="final_ai_day_work"
SCHEME="final_ai_day_work"
CONFIGURATION="Release"
PROJECT_FILE="${PROJECT_NAME}.xcodeproj"
BUILD_DIR="build"
ARCHIVE_PATH="${BUILD_DIR}/${PROJECT_NAME}.xcarchive"
EXPORT_PATH="${BUILD_DIR}/export"

# Create build directories
echo "Creating build directories..."
mkdir -p "${BUILD_DIR}"
mkdir -p "${EXPORT_PATH}"

# Clean previous builds
echo "Cleaning previous builds..."
xcodebuild clean -project "${PROJECT_FILE}" -scheme "${SCHEME}" -configuration "${CONFIGURATION}" > /dev/null 2>&1

# Build the project
echo "Building project..."
xcodebuild build -project "${PROJECT_FILE}" -scheme "${SCHEME}" -configuration "${CONFIGURATION}" -derivedDataPath "${BUILD_DIR}" > /dev/null 2>&1

if [ $? -ne 0 ]; then
    echo "Build failed!"
    exit 1
fi

echo "Build successful!"

# Create archive
echo "Creating archive..."
xcodebuild archive -project "${PROJECT_FILE}" -scheme "${SCHEME}" -configuration "${CONFIGURATION}" -archivePath "${ARCHIVE_PATH}" > /dev/null 2>&1

if [ $? -ne 0 ]; then
    echo "Archive failed!"
    exit 1
fi

echo "Archive created at ${ARCHIVE_PATH}"

# Export the archive
echo "Exporting archive..."
xcodebuild -exportArchive -archivePath "${ARCHIVE_PATH}" -exportPath "${EXPORT_PATH}" -exportFormat app > /dev/null 2>&1

if [ $? -ne 0 ]; then
    # Try alternative export method
    echo "Trying alternative export method..."
    
    # Create export options plist
    cat > "${BUILD_DIR}/exportOptions.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>development</string>
    <key>teamID</key>
    <string></string>
</dict>
</plist>
EOF

    xcodebuild -exportArchive -archivePath "${ARCHIVE_PATH}" -exportPath "${EXPORT_PATH}" -exportOptionsPlist "${BUILD_DIR}/exportOptions.plist" > /dev/null 2>&1
    
    if [ $? -ne 0 ]; then
        echo "Export failed!"
        exit 1
    fi
fi

echo "Export successful!"

# Find the exported app
APP_NAME=$(find "${EXPORT_PATH}" -name "*.app" -type d | head -n 1)
APP_BASENAME=$(basename "${APP_NAME}")

if [ -z "${APP_NAME}" ]; then
    echo "Could not find exported app!"
    exit 1
fi

# Copy the app to a more accessible location
FINAL_APP_PATH="${BUILD_DIR}/${APP_BASENAME}"
cp -R "${APP_NAME}" "${FINAL_APP_PATH}"

echo "App successfully built and exported!"
echo "Location: ${FINAL_APP_PATH}"
echo ""
echo "To run the app:"
echo "  1. Right-click (or Control-click) on the app in Finder"
echo "  2. Select 'Open' from the context menu"
echo "  3. Confirm you want to open the app when prompted"
echo ""
echo "Alternatively, you can run it from the terminal:"
echo "  open \"${FINAL_APP_PATH}\""
echo ""
echo "Note: On first run, macOS may show a security warning since the app is not signed by Apple."
echo "This is normal for developer-built applications."