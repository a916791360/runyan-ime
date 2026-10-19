#!/usr/bin/env bash
# Assembles build/SharedSupport — the read-only data directory bundled into Runyan.app:
#   * 雾凇拼音 (rime-ice) at the version pinned in dicts/registry.json, sha256-verified
#   * OpenCC data from the pinned librime release
#   * Runyan's own files from SharedSupport/ (runyan.yaml, runyan/defaults/…)
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$ROOT/build/SharedSupport"
CACHE="$ROOT/Vendor/.cache"
REGISTRY="$ROOT/dicts/registry.json"

[[ -d "$ROOT/Vendor/librime/share/opencc" ]] || bash "$ROOT/scripts/fetch-librime.sh"

read -r URL SHA ASSET < <(/usr/bin/python3 - "$REGISTRY" <<'PY'
import json, sys
pkg = next(p for p in json.load(open(sys.argv[1]))["packages"] if p["id"] == "rime-ice")
s = pkg["source"]
print(f'https://github.com/{s["repo"]}/releases/download/{s["tag"]}/{s["asset"]}', pkg["sha256"], f'rime-ice-{s["tag"]}-{s["asset"]}')
PY
)

mkdir -p "$CACHE"
if [[ ! -f "$CACHE/$ASSET" ]]; then
  echo "==> downloading $URL"
  curl -fL --retry 3 -o "$CACHE/$ASSET.part" "$URL"
  mv "$CACHE/$ASSET.part" "$CACHE/$ASSET"
fi
echo "==> verifying $ASSET"
echo "$SHA  $CACHE/$ASSET" | shasum -a 256 -c -

echo "==> assembling $OUT"
rm -rf "$OUT"
mkdir -p "$OUT"
ditto -x -k "$CACHE/$ASSET" "$OUT"
# Strip a wrapping folder if the archive has one.
if [[ $(find "$OUT" -mindepth 1 -maxdepth 1 | wc -l) -eq 1 && -d "$(find "$OUT" -mindepth 1 -maxdepth 1)" ]]; then
  inner="$(find "$OUT" -mindepth 1 -maxdepth 1)"
  mv "$inner"/* "$OUT"/ && rmdir "$inner"
fi
# Frontend files Runyan does not use.
rm -f "$OUT/squirrel.yaml" "$OUT/weasel.yaml" "$OUT"/*.custom.yaml
rm -rf "$OUT/others" "$OUT/.github"

mkdir -p "$OUT/opencc"
cp -n "$ROOT/Vendor/librime/share/opencc/"* "$OUT/opencc/" 2>/dev/null || true
ditto "$ROOT/SharedSupport" "$OUT"

# The 2026 AI / internet vocabulary is no longer bundled: it is an optional online
# vocabulary subscribed from 润言设置。
rm -f "$OUT/runyan_tech.txt" "$OUT/runyan/runyan_tech.tsv"

echo "rime-ice $(basename "$ASSET")" > "$OUT/runyan/VERSION"
# Diagnostic metadata for Settings, which intentionally does not link librime.
sed -n 's/^LIBRIME_VERSION=//p' "$ROOT/Vendor/librime.lock" > "$OUT/runyan/LIBRIME_VERSION"
/usr/bin/python3 "$ROOT/scripts/dictionary-metadata.py" --shared-dir "$OUT" --registry "$REGISTRY"
bash "$ROOT/scripts/stage-plugins.sh" >/dev/null
echo "==> done: $(du -sh "$OUT" | cut -f1) in $OUT"
