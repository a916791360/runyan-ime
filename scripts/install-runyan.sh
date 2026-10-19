#!/usr/bin/env bash
#
# 润言 · 构建 + 安装
#
# 一条命令完成：编译 → 替换已安装版本 → 注册输入源。
# 名称与图标的刷新依赖登录会话缓存，安装后仍需注销重登一次。
#
# 用法：
#   RUNYAN_SIGN_IDENTITY="Apple Development: xxx (TEAMID)" bash scripts/install-runyan.sh

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DEST="$HOME/Library/Input Methods"
APP="$DEST/Runyan.app"

if ! bash "$ROOT/scripts/build-app.sh"; then
  echo "==> Xcode 构建不可用（xcodebuild 解析依赖需要嵌套沙箱），改走 SwiftPM 路径"
  bash "$ROOT/scripts/build-app-swiftpm.sh"
fi

echo "==> 停止旧进程"
pkill -f "Input Methods/Runyan.app/Contents/MacOS/Runyan" 2>/dev/null || true

echo "==> 安装到 $DEST"
mkdir -p "$DEST"
# 输入法目录必须 755，否则系统扫描器会跳过
chmod 755 "$DEST"
rm -rf "$APP"
ditto "$ROOT/build/Release/Runyan.app" "$APP"

echo "==> 注册输入源"
"$APP/Contents/Helpers/runyan" register --app "$APP" --enable || true

echo ""
echo "✅ 已安装：$APP"
echo ""
echo "下一步：注销重登一次（或重启），名称与图标才会刷新。"
echo "登录后：系统设置 → 键盘 → 输入源 → 添加「润言」"
