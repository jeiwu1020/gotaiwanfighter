#!/usr/bin/env bash
# Vercel Linux build: fetch the exact Godot engine/templates needed for Web export.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VERSION="4.5.2-stable"
ENGINE_NAME="Godot_v${VERSION}_linux.x86_64"
CACHE_DIR="${HOME}/.cache/taiwanfighter-godot/${VERSION}"
TEMPLATE_DIR="${HOME}/.local/share/godot/export_templates/4.5.2.stable"
ENGINE="${CACHE_DIR}/${ENGINE_NAME}"

mkdir -p "${CACHE_DIR}" "${TEMPLATE_DIR}"
if [[ ! -x "${ENGINE}" ]]; then
  curl --fail --location --retry 3 \
    "https://github.com/godotengine/godot-builds/releases/download/${VERSION}/${ENGINE_NAME}.zip" \
    --output "${CACHE_DIR}/engine.zip"
  unzip -q -o "${CACHE_DIR}/engine.zip" -d "${CACHE_DIR}"
  chmod +x "${ENGINE}"
fi

if [[ ! -f "${TEMPLATE_DIR}/templates/web_release.zip" ]]; then
  curl --fail --location --retry 3 \
    "https://github.com/godotengine/godot-builds/releases/download/${VERSION}/Godot_v${VERSION}_export_templates.tpz" \
    --output "${CACHE_DIR}/templates.tpz"
  unzip -q -o "${CACHE_DIR}/templates.tpz" -d "${TEMPLATE_DIR}"
fi

cd "${ROOT}"
"${ENGINE}" --headless --path "${ROOT}" --import --quit
"${ENGINE}" --headless --path "${ROOT}" --export-release Web
python3 tools/prepare_web.py
