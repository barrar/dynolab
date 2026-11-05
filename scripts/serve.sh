#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
if [ ! -f build/web/index.html ]; then
  echo "Build first: flutter build web --wasm --release --no-web-resources-cdn"
  exit 1
fi
exec python3 scripts/serve.py "${PORT:-52741}"
