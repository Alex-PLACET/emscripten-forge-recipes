#!/usr/bin/env bash
set -euo pipefail
WORK=$(mktemp -d)
cp tests/app.cpp tests/check_page.js "${WORK}/"
cd "${WORK}"

em++ app.cpp -o app.html \
  $(wx-config --cxxflags) \
  $(wx-config --libs base,core,html) \
  --pre-js "${PREFIX}/share/wx/wasm/wx.js" \
  --shell-file "${PREFIX}/share/wx/wasm/template.html"

# playwright comes from this test's build requirements, so resolve the node
# module from the prefix that provides the playwright CLI.
PLAYWRIGHT_PREFIX="$(dirname "$(dirname "$(command -v playwright)")")"
export PLAYWRIGHT_BROWSERS_PATH="${WORK}/pw-browsers"
playwright install chromium
NODE_PATH="${PLAYWRIGHT_PREFIX}/lib/node_modules" node check_page.js "${WORK}"
