#!/bin/bash

# Package script for 任务管理器
# This script creates a distributable package with the app and instructions

echo "Creating distribution package for 任务管理器..."

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"

# Define paths
BUILD_DIR="${SCRIPT_DIR}/build"
APP_PATH="${BUILD_DIR}/final_ai_day_work.app"
PACKAGE_DIR="${SCRIPT_DIR}/任务管理器_分发包"
README_SRC="${SCRIPT_DIR}/README_任务管理器.md"
LAUNCH_SCRIPT="${SCRIPT_DIR}/launch_app.sh"

# Check if the application exists
if [ ! -d "${APP_PATH}" ]; then
    echo "应用程序未找到: ${APP_PATH}"
    echo "请先运行 build_app_v2.sh 构建应用程序"
    exit 1
fi

# Create package directory
echo "Creating package directory..."
rm -rf "${PACKAGE_DIR}"
mkdir -p "${PACKAGE_DIR}"

# Copy application
echo "Copying application..."
cp -R "${APP_PATH}" "${PACKAGE_DIR}/"

# Copy README
echo "Copying README..."
cp "${README_SRC}" "${PACKAGE_DIR}/"

# Copy launcher script
echo "Copying launcher script..."
cp "${LAUNCH_SCRIPT}" "${PACKAGE_DIR}/"
chmod +x "${PACKAGE_DIR}/launch_app.sh"

# Create a simple run.command file for double-click execution
echo "Creating run.command file..."
cat > "${PACKAGE_DIR}/运行任务管理器.command" << 'EOF'
#!/bin/bash

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"

# Define the path to the application
APP_PATH="${SCRIPT_DIR}/final_ai_day_work.app"

# Check if the application exists
if [ ! -d "${APP_PATH}" ]; then
    echo "应用程序未找到: ${APP_PATH}"
    echo "请确保此脚本与应用程序在同一目录中"
    read -p "按 Enter 键退出..."
    exit 1
fi

# Open the application
echo "正在启动 任务管理器..."
open "${APP_PATH}"

echo "任务管理器已启动"
echo "请在菜单栏中查看应用程序图标"
echo ""
echo "您可以关闭此窗口"
read -p "按 Enter 键退出..."
EOF

chmod +x "${PACKAGE_DIR}/运行任务管理器.command"

echo "Package creation complete!"

echo ""
echo "分发包已创建: ${PACKAGE_DIR}"
echo ""
echo "包内包含:"
echo "  - final_ai_day_work.app: 主应用程序"
echo "  - README_任务管理器.md: 使用说明"
echo "  - 运行任务管理器.command: 双击运行脚本"
echo "  - launch_app.sh: 命令行启动脚本"
echo ""
echo "使用方法:"
echo "  1. 将整个文件夹压缩为 zip 文件进行分发"
echo "  2. 用户解压后可以:"
echo "     - 双击 '运行任务管理器.command' 启动应用"
echo "     - 或者直接双击 'final_ai_day_work.app' 启动应用"
echo ""