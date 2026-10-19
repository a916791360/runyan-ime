#!/usr/bin/env bash
# Produces dist/Runyan-<version>.pkg: installs Runyan.app to /Library/Input Methods (and
# Runyan Settings.app to /Applications) and
# registers it for the installing user. Unsigned unless RUNYAN_INSTALLER_IDENTITY
# (a "Developer ID Installer" certificate) is set.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
VERSION="$(awk -F'"' '/MARKETING_VERSION/ {print $2; exit}' project.yml)"

[[ "${SKIP_BUILD:-0}" == 1 ]] || RUNYAN_REQUIRE_TIMESTAMP=$([[ "${RUNYAN_SIGN_IDENTITY:--}" == "-" ]] && echo 0 || echo 1) bash scripts/build-app.sh

STAGE="$ROOT/build/pkg-stage"; rm -rf "$STAGE"; mkdir -p "$STAGE"
mkdir -p "$STAGE/root/Library/Input Methods" dist
ditto --noextattr --noqtn build/Release/Runyan.app "$STAGE/root/Library/Input Methods/Runyan.app"
# Settings also goes to /Applications so it is easy to find (Launchpad, Spotlight).
mkdir -p "$STAGE/root/Applications"
ditto --noextattr --noqtn "build/Release/Runyan.app/Contents/Applications/Runyan Settings.app" "$STAGE/root/Applications/Runyan Settings.app"
# Extended attributes would be archived as ._* AppleDouble files in the payload.
xattr -cr "$STAGE/root"

# Bundles are relocatable by default: Installer would follow any other Runyan.app with the
# same bundle ID (a dev build, a copy in Downloads) and update it in place instead of
# installing to /Library/Input Methods, leaving the input method unregistered.
pkgbuild --analyze --root "$STAGE/root" "$STAGE/components.plist" >/dev/null
plutil -convert xml1 "$STAGE/components.plist"
perl -0pi -e 's#(<key>BundleIsRelocatable</key>\s*)<true/>#$1<false/>#g' "$STAGE/components.plist"
if grep -A1 BundleIsRelocatable "$STAGE/components.plist" | grep -q '<true/>'; then
  echo "error: a bundle is still relocatable" >&2; exit 1
fi
COPYFILE_DISABLE=1 pkgbuild --root "$STAGE/root" --install-location / \
  --component-plist "$STAGE/components.plist" \
  --identifier app.runyan.inputmethod.zh.pkg --version "$VERSION" \
  --scripts scripts/pkg/scripts "$STAGE/Runyan-component.pkg" >/dev/null

cat > "$STAGE/distribution.xml" <<XML
<?xml version="1.0" encoding="utf-8"?>
<installer-gui-script minSpecVersion="2">
  <title>Runyan $VERSION</title>
  <welcome file="welcome.html" mime-type="text/html"/>
  <license file="LICENSE"/>
  <conclusion file="conclusion.html" mime-type="text/html"/>
  <options customize="never" require-scripts="false" hostArchitectures="arm64,x86_64"/>
  <volume-check><allowed-os-versions><os-version min="26.0"/></allowed-os-versions></volume-check>
  <domains enable_localSystem="true"/>
  <choices-outline><line choice="default"><line choice="runyan"/></line></choices-outline>
  <choice id="default"/>
  <choice id="runyan" visible="false"><pkg-ref id="app.runyan.inputmethod.zh.pkg"/></choice>
  <pkg-ref id="app.runyan.inputmethod.zh.pkg" version="$VERSION" onConclusion="none">Runyan-component.pkg</pkg-ref>
</installer-gui-script>
XML
cp scripts/pkg/resources/*.html "$STAGE/"
# The installer's license page: what the package contains, then MIT and GPL-3.0 in full.
{
  cat scripts/pkg/LICENSE-header.txt
  printf '\n\n==== MIT License (Runyan original code) ====\n\n'
  cat LICENSE
  printf '\n\n==== GNU General Public License v3.0 ====\n\n'
  cat licenses/native-plugins/librime-octagram.LICENSE.txt
} > "$STAGE/LICENSE"

SIGN_ARGS=()
[[ -n "${RUNYAN_INSTALLER_IDENTITY:-}" ]] && SIGN_ARGS=(--sign "$RUNYAN_INSTALLER_IDENTITY")
productbuild --distribution "$STAGE/distribution.xml" --resources "$STAGE" --package-path "$STAGE" \
  ${SIGN_ARGS[@]+"${SIGN_ARGS[@]}"} "dist/Runyan-$VERSION.pkg" >/dev/null
rm -rf "$STAGE"
echo "==> dist/Runyan-$VERSION.pkg ($(du -h "dist/Runyan-$VERSION.pkg" | cut -f1))"
