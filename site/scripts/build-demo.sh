#!/usr/bin/env bash
# Builds the example app with Flutter Web into site/public/demo.
# Requires `flutter` on PATH (the repo CI uses 3.47.6).
set -euo pipefail
cd "$(dirname "$0")/../../example"
flutter pub get
# --profile keeps runtimeType names: the demos print intent types in logs and
# the debug overlay, and release builds minify them ("minified:Gt").
flutter build web --profile --base-href /JIntent/demo/
rm -rf ../site/public/demo
mkdir -p ../site/public
cp -R build/web ../site/public/demo
echo "Demo copied to site/public/demo"
