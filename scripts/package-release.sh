#!/usr/bin/env bash
# Packages the built Runyan.app into:
#   build/Release/Runyan-v<version>.dmg
#   build/Release/Runyan-v<version>.zip
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CONFIG="${CONFIG:-Release}"
APP="$ROOT/build/$CONFIG/Runyan.app"
OUT="$ROOT/build/$CONFIG"

if [[ ! -d "$APP" ]]; then
  echo "==> Runyan.app missing, running build-app.sh..."
  bash "$ROOT/scripts/build-app.sh"
fi

VERSION="$(defaults read "$APP/Contents/Info.plist" CFBundleShortVersionString 2>/dev/null || echo "1.0.0")"
echo "==> packaging Runyan v$VERSION"

ZIP="$OUT/Runyan-v$VERSION.zip"
DMG="$OUT/Runyan-v$VERSION.dmg"
STAGE="$OUT/dmg-stage"

rm -rf "$ZIP" "$DMG" "$STAGE"

echo "==> creating $ZIP"
COPYFILE_DISABLE=1 ditto -c -k --norsrc --keepParent "$APP" "$ZIP"

echo "==> creating $DMG"
mkdir -p "$STAGE"
cp -R "$APP" "$STAGE/"
ln -s "/Library/Input Methods" "$STAGE/Input Methods"

cat << 'EOF' > "$STAGE/安装指南.txt"
润言 · Runyan 安装指南
============================

【方法一：快捷安装（推荐）】
1. 将「Runyan」应用拖拽到右侧的「Input Methods」替身文件夹中；
   （若系统弹出密码提示，输入 Mac 开机密码确认授权即可）
2. 打开「系统设置」→「键盘」→「文本输入（输入法）」；
3. 点击「编辑...」→「+」号，搜索并添加「润言」；
4. 注销重登一次 Mac，即可开始顺畅打字！

【常见提示处理】
• 若首次打开提示「无法验证开发者」：
  前往「系统设置」→「隐私与安全性」，在页面底部找到并点击「仍要打开」即可。
• 若提示「文件损坏」：
  打开终端运行以下命令消除隔离标记：
  xattr -dr com.apple.quarantine "/Library/Input Methods/Runyan.app"
EOF

hdiutil create -volname "润言 $VERSION" -srcfolder "$STAGE" -ov -format UDZO "$DMG" >/dev/null
rm -rf "$STAGE"

echo "✅ 打包完成："
echo "   $ZIP"
echo "   $DMG"
