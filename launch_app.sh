#!/bin/bash

# Launcher script for 任务管理器
# This script opens the application bundle

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"

# Define the path to the application
APP_PATH="${SCRIPT_DIR}/build/final_ai_day_work.app"

# Check if the application exists
if [ ! -d "${APP_PATH}" ]; then
    echo "应用程序未找到: ${APP_PATH}"
    echo "请先运行 build_app_v2.sh 构建应用程序"
    exit 1
fi

# Open the application
echo "正在启动 任务管理器..."
open "${APP_PATH}"

echo "任务管理器已启动"
echo "请在菜单栏中查看应用程序图标"