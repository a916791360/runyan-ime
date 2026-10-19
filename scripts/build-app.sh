#!/usr/bin/env bash
# Builds and assembles a complete, signed Runyan.app at build/Release/Runyan.app:
#   Contents/MacOS/Runyan                      input method
#   Contents/Helpers/runyan                    CLI (+ its resource bundle)
#   Contents/Applications/Runyan Settings.app  settings
#   Contents/Frameworks/librime + rime-plugins, Contents/SharedSupport
# Used by install-dev.sh and install-runyan.sh. Signs ad-hoc unless RUNYAN_SIGN_IDENTITY is set.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CONFIG="${CONFIG:-Release}"
DERIVED="$ROOT/build/DerivedData"
OUT="$ROOT/build/Release"
IDENTITY="${RUNYAN_SIGN_IDENTITY:--}"

cd "$ROOT"
[[ -d Packages/RunyanKit/Frameworks/CRime.xcframework ]] || bash scripts/fetch-librime.sh
[[ -f build/SharedSupport/default.yaml ]] || bash scripts/fetch-dicts.sh
# Runyan's own data changes more often than the dictionaries: always refresh it.
ditto SharedSupport build/SharedSupport
# Refresh public metadata even when reusing an older dictionary build cache.
/usr/bin/python3 scripts/dictionary-metadata.py --shared-dir build/SharedSupport
command -v xcodegen >/dev/null || { echo "xcodegen is required: brew install xcodegen" >&2; exit 1; }
xcodegen generate --quiet

echo "==> building apps ($CONFIG)"
xcodebuild -project Runyan.xcodeproj -scheme Runyan -configuration "$CONFIG" -derivedDataPath "$DERIVED" \
  CODE_SIGN_STYLE=Manual CODE_SIGN_IDENTITY="$IDENTITY" CODE_SIGN_INJECT_BASE_ENTITLEMENTS=NO build -quiet
BUILT="$DERIVED/Build/Products/$CONFIG"

echo "==> building CLI"
swift build --package-path Packages/RunyanKit -c release --product runyan >/dev/null
CLI_DIR="$(swift build --package-path Packages/RunyanKit -c release --show-bin-path)"

rm -rf "$OUT" && mkdir -p "$OUT"
APP="$OUT/Runyan.app"
ditto "$BUILT/Runyan.app" "$APP"
# Not Contents/MacOS: the file system is case-insensitive and "runyan" would replace "Runyan".
mkdir -p "$APP/Contents/Helpers" "$APP/Contents/Applications"
cp "$CLI_DIR/runyan" "$APP/Contents/Helpers/runyan"
ditto "$CLI_DIR/RunyanKit_RunyanCore.bundle" "$APP/Contents/Helpers/RunyanKit_RunyanCore.bundle"
install_name_tool -add_rpath "@executable_path/../Frameworks" "$APP/Contents/Helpers/runyan" 2>/dev/null || true
ditto "$BUILT/Runyan Settings.app" "$APP/Contents/Applications/Runyan Settings.app"

# Keep CFBundleShortVersionString numeric, but retain the full SemVer for updates.
# This only modifies staging bundles, before signing; project/CLI versions stay unchanged.
if [[ -n "${RUNYAN_RELEASE_VERSION:-}" ]]; then
  for bundle in "$APP" "$APP/Contents/Applications/Runyan Settings.app"; do
    plutil -replace RunyanReleaseVersion -string "$RUNYAN_RELEASE_VERSION" "$bundle/Contents/Info.plist"
  done
fi

# Local builds are signed ad-hoc by default. Set RUNYAN_SIGN_IDENTITY to a certificate
# hash to use a real identity — but make sure it is not revoked: macOS treats code
# signed with a revoked certificate as malware (kills it and moves the app to Trash).
echo "==> signing with: $IDENTITY"
TIMESTAMP=--timestamp
[[ "$IDENTITY" == "-" ]] && TIMESTAMP=--timestamp=none
# Development builds tolerate an unreachable timestamp service; release packaging sets
# RUNYAN_REQUIRE_TIMESTAMP=1 (notarization needs secure timestamps).
sign() {
  codesign --force --options runtime "$TIMESTAMP" --sign "$IDENTITY" "$@" 2>/dev/null && return 0
  [[ "${RUNYAN_REQUIRE_TIMESTAMP:-0}" == 1 ]] && { echo "timestamp service unavailable" >&2; return 1; }
  codesign --force --options runtime --timestamp=none --sign "$IDENTITY" "$@"
}
for lib in "$APP"/Contents/Frameworks/librime.1.dylib "$APP"/Contents/Frameworks/rime-plugins/*.dylib; do sign "$lib"; done
sign "$APP/Contents/Helpers/RunyanKit_RunyanCore.bundle"
sign --entitlements Apps/Runyan/Runyan.entitlements "$APP/Contents/Helpers/runyan"
sign --entitlements Apps/RunyanSettings/RunyanSettings.entitlements "$APP/Contents/Applications/Runyan Settings.app"
sign --entitlements Apps/Runyan/Runyan.entitlements "$APP"
codesign --verify --deep --strict "$APP"
echo "==> built $APP"
