#!/usr/bin/env bash
# Renders the built-in themes with the real candidate panel (ThemeRenderProbe), horizontal
# and vertical, for the website: <out>/<id>-linear.png and <id>-stacked.png (@2x).
#   bash scripts/render-themes.sh [<out-dir>]     default: ../runyan-web/public/themes/renders
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="${1:-$ROOT/../runyan-web/public/themes/renders}"
mkdir -p "$OUT"
OUT="$(cd "$OUT" && pwd)"
SCHEMES="$(python3 -c 'import json,sys; print(",".join(t["id"] for t in json.load(open(sys.argv[1]))))' \
  "$ROOT/Packages/RunyanKit/Tests/RunyanCoreTests/Fixtures/theme-v1/valid.json" | tr ',' '\n' | grep -v -e sakura_test -e low_contrast | paste -sd, -)"
Runyan_RENDER_FRONTEND="$ROOT/SharedSupport/runyan.yaml" Runyan_RENDER_OUT="$OUT" Runyan_RENDER_PREEDIT=1 Runyan_RENDER_SCHEMES="$SCHEMES" \
  swift test --package-path "$ROOT/Packages/RunyanKit" --filter ThemeRenderProbe >/dev/null
echo "rendered images: $(find "$OUT" -name "*.png" | wc -l | tr -d " ")"
