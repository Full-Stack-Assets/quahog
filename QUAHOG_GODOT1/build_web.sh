#!/usr/bin/env bash
# Vercel build step: export the Godot project to a static Web (WASM) build.
#
# Vercel can't `npm install` a Godot project, so vercel.json points its build
# command here. We fetch the Godot 4.6 headless binary, drop in the committed
# web export template (.godot-templates/), then run the headless exporter. The
# 53 MB .pck/.wasm output is produced fresh each deploy into build/web (which
# Vercel serves) — it is NOT committed, keeping git lean.
set -euo pipefail

GODOT_VERSION="4.6-stable"
TPL_VERSION="4.6.stable"          # export_templates dir name
HERE="$(cd "$(dirname "$0")" && pwd)"
WORK="${HERE}/.vercel-godot"
mkdir -p "$WORK"

# Sandbox Godot's user dirs inside the build workspace.
export XDG_DATA_HOME="$WORK/data"
export XDG_CONFIG_HOME="$WORK/config"
export XDG_CACHE_HOME="$WORK/cache"

# 1. Godot headless editor binary (needed to run an export).
if [ ! -x "$WORK/godot" ]; then
  echo "Downloading Godot ${GODOT_VERSION}..."
  curl -fsSL -o "$WORK/godot.zip" \
    "https://github.com/godotengine/godot/releases/download/${GODOT_VERSION}/Godot_v${GODOT_VERSION}_linux.x86_64.zip"
  unzip -oq "$WORK/godot.zip" -d "$WORK"
  mv "$WORK/Godot_v${GODOT_VERSION}_linux.x86_64" "$WORK/godot"
  chmod +x "$WORK/godot"
fi

# 2. Install the committed web export template.
TPL_DIR="$XDG_DATA_HOME/godot/export_templates/${TPL_VERSION}"
mkdir -p "$TPL_DIR"
cp "$HERE/.godot-templates/web_nothreads_release.zip" "$TPL_DIR/"
echo "${TPL_VERSION}" > "$TPL_DIR/version.txt"

# 3. Import resources, then export the "Web" preset.
echo "Importing project..."
"$WORK/godot" --headless --path "$HERE" --import || true
mkdir -p "$HERE/build/web"
echo "Exporting Web build..."
"$WORK/godot" --headless --path "$HERE" --export-release "Web" "build/web/index.html"

echo "Web build ready in build/web:"
ls -lh "$HERE/build/web"
