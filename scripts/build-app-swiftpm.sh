#!/usr/bin/env bash
#
# 润言 · 不走 Xcode 的构建路径
#
# `xcodebuild` 解析 SwiftPM 依赖时会起一个嵌套沙箱（sandbox-exec）。在受限环境里
# 这一步会直接失败（sandbox_apply: Operation not permitted），工程再干净也构建不了。
# 这个脚本绕开 xcodebuild：SwiftPM 直接编译出可执行文件，再按 Xcode 的目录结构
# 手工组装 .app，产出和 build-app.sh 完全一致，后面的安装脚本照常可用。
#
# 用法：RUNYAN_SIGN_IDENTITY="Apple Development: …" bash scripts/build-app-swiftpm.sh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$ROOT/build/Release"
APP="$OUT/Runyan.app"
SETTINGS_APP="$APP/Contents/Applications/Runyan Settings.app"
IDENTITY="${RUNYAN_SIGN_IDENTITY:--}"
STAMP="$(date '+%Y-%m-%d %H:%M')"

cd "$ROOT"

# ---- 1. 依赖就位 ------------------------------------------------------------
[[ -d Packages/RunyanKit/Frameworks/CRime.xcframework ]] || bash scripts/fetch-librime.sh
[[ -f build/SharedSupport/default.yaml ]] || bash scripts/fetch-dicts.sh
ditto SharedSupport build/SharedSupport
/usr/bin/python3 scripts/dictionary-metadata.py --shared-dir build/SharedSupport

# ---- 2. 命令行工具 ----------------------------------------------------------
echo "==> 编译命令行工具"
swift build --package-path Packages/RunyanKit -c release --product runyan --disable-sandbox >/dev/null
CLI_DIR="$(swift build --package-path Packages/RunyanKit -c release --show-bin-path --disable-sandbox)"

# ---- 3. 两个 App 的可执行文件 ----------------------------------------------
# SwiftPM 的多架构链接找不到 xcframework 里的单架构 librime，所以按架构分别编译再合并。
WORK="$ROOT/build/swiftpm-app"
rm -rf "$WORK"
mkdir -p "$WORK/Sources/RunyanIME" "$WORK/Sources/RunyanSettings"
rsync -a --include='*/' --include='*.swift' --exclude='*' Apps/Runyan/ "$WORK/Sources/RunyanIME/"
rsync -a --include='*/' --include='*.swift' --exclude='*' Apps/RunyanSettings/ "$WORK/Sources/RunyanSettings/"

cat > "$WORK/Package.swift" <<EOF
// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "RunyanManualBuild",
    platforms: [.macOS(.v26)],
    dependencies: [.package(path: "$ROOT/Packages/RunyanKit")],
    targets: [
        .executableTarget(
            name: "RunyanIME",
            dependencies: [
                .product(name: "RimeKit", package: "RunyanKit"),
                .product(name: "RunyanCore", package: "RunyanKit"),
                .product(name: "RunyanPanel", package: "RunyanKit"),
                .product(name: "RunyanAI", package: "RunyanKit"),
            ],
            path: "Sources/RunyanIME"
        ),
        .executableTarget(
            name: "RunyanSettings",
            dependencies: [
                .product(name: "RunyanCore", package: "RunyanKit"),
                .product(name: "RunyanPanel", package: "RunyanKit"),
                .product(name: "RunyanAI", package: "RunyanKit"),
            ],
            path: "Sources/RunyanSettings"
        ),
    ]
)
EOF

for arch in arm64 x86_64; do
  echo "==> 编译 App（${arch}）"
  swift build --package-path "$WORK" -c release --arch "$arch" --disable-sandbox >/dev/null
done

# ---- 4. 组装 .app -----------------------------------------------------------
echo "==> 组装 $APP"
rm -rf "$OUT" && mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources" \
  "$APP/Contents/Frameworks" "$APP/Contents/Helpers" "$APP/Contents/SharedSupport" \
  "$SETTINGS_APP/Contents/MacOS" "$SETTINGS_APP/Contents/Resources"

for pair in "RunyanIME:Runyan" "RunyanSettings:Runyan Settings"; do
  src="${pair%%:*}"; dst="${pair##*:}"
  target="$APP/Contents/MacOS/$dst"
  [[ "$dst" == "Runyan Settings" ]] && target="$SETTINGS_APP/Contents/MacOS/$dst"
  lipo -create -output "$target" \
    "$WORK/.build/arm64-apple-macosx/release/$src" \
    "$WORK/.build/x86_64-apple-macosx/release/$src"
  install_name_tool -add_rpath @executable_path/../Frameworks "$target" 2>/dev/null || true
  chmod 755 "$target"
done

# Info.plist：模板 + 构建时间。
# 模板里留着 $(EXECUTABLE_NAME) 这类构建设置占位符——平时由 Xcode 展开，
# 手工组装得自己填，否则 codesign 找不到主可执行文件（"code object is not signed at all"）。
cp Apps/Runyan/Info.plist "$APP/Contents/Info.plist"
cp Apps/RunyanSettings/Info.plist "$SETTINGS_APP/Contents/Info.plist"
fill_plist() {
  local plist="$1" exe="$2" identifier="$3" name="$4" display="$5"
  /usr/bin/plutil -replace CFBundleExecutable -string "$exe" "$plist"
  /usr/bin/plutil -replace CFBundleIdentifier -string "$identifier" "$plist"
  /usr/bin/plutil -replace CFBundleName -string "$name" "$plist"
  /usr/bin/plutil -replace CFBundleDisplayName -string "$display" "$plist"
  /usr/bin/plutil -replace CFBundleShortVersionString -string "0.1.0" "$plist"
  /usr/bin/plutil -replace CFBundleVersion -string "1" "$plist"
  /usr/bin/plutil -replace CFBundleDevelopmentRegion -string "zh-Hans" "$plist"
  /usr/bin/plutil -replace RunyanBuildDate -string "$STAMP" "$plist"
}
fill_plist "$APP/Contents/Info.plist" "Runyan" "app.runyan.inputmethod.zh" "Runyan" "润言"
fill_plist "$SETTINGS_APP/Contents/Info.plist" "Runyan Settings" "app.runyan.inputmethod.zh.settings" "Runyan Settings" "润言设置"

# 资源：图标与界面图片先编译成 Assets.car，再拷散装 PNG 和本地化
xcrun actool Apps/Shared/Assets.xcassets --compile "$APP/Contents/Resources" \
  --platform macosx --minimum-deployment-target 26.0 --app-icon AppIcon \
  --output-partial-info-plist "$WORK/actool.plist" >/dev/null
ditto "$APP/Contents/Resources/Assets.car" "$SETTINGS_APP/Contents/Resources/Assets.car"
cp Apps/Runyan/Resources/*.png "$APP/Contents/Resources/"
cp -R Apps/Runyan/Resources/zh-Hans.lproj Apps/Runyan/Resources/en.lproj "$APP/Contents/Resources/"

# 命令行工具与它自己的资源包
cp "$CLI_DIR/runyan" "$APP/Contents/Helpers/runyan"
ditto "$CLI_DIR/RunyanKit_RunyanCore.bundle" "$APP/Contents/Helpers/RunyanKit_RunyanCore.bundle"
ditto "$CLI_DIR/RunyanKit_RunyanCore.bundle" "$APP/Contents/Resources/RunyanKit_RunyanCore.bundle"
install_name_tool -add_rpath "@executable_path/../Frameworks" "$APP/Contents/Helpers/runyan" 2>/dev/null || true

# librime 与插件、随包配置
cp -L Vendor/librime/lib/librime.1.dylib "$APP/Contents/Frameworks/"
cp -R Vendor/librime/lib/rime-plugins "$APP/Contents/Frameworks/rime-plugins"
rsync -a build/SharedSupport/ "$APP/Contents/SharedSupport/"

/usr/bin/python3 scripts/embed-license-materials.py --app "$APP"

# ---- 5. 签名 ---------------------------------------------------------------
echo "==> 签名：$IDENTITY"
sign() { codesign --force --options runtime --timestamp=none --sign "$IDENTITY" "$@"; }
for lib in "$APP"/Contents/Frameworks/librime.1.dylib "$APP"/Contents/Frameworks/rime-plugins/*.dylib; do
  sign "$lib"
done
for bundle in "$APP/Contents/Resources/RunyanKit_RunyanCore.bundle" \
              "$APP/Contents/Helpers/RunyanKit_RunyanCore.bundle"; do
  [[ -d "$bundle" ]] && sign "$bundle"
done
sign --entitlements Apps/Runyan/Runyan.entitlements "$APP/Contents/Helpers/runyan"
sign --entitlements Apps/RunyanSettings/RunyanSettings.entitlements "$SETTINGS_APP"
sign --entitlements Apps/Runyan/Runyan.entitlements "$APP"
codesign --verify --deep --strict "$APP"
echo "==> 完成：$APP"
