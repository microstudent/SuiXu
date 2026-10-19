#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
configuration="${1:-release}"
if [[ "$configuration" != "release" && "$configuration" != "debug" ]]; then
  echo "Usage: scripts/build.sh [release|debug]" >&2
  exit 1
fi

swift build -c "$configuration"
bin_path="$(swift build -c "$configuration" --show-bin-path)"
mkdir -p dist
staging_dir="$(mktemp -d "$PWD/dist/.suixu-build.XXXXXX")"
trap 'rm -rf "$staging_dir"' EXIT
app_path="$staging_dir/岁序.app"
resource_path="$app_path/Contents/Resources"
mkdir -p "$app_path/Contents/MacOS" "$resource_path/Legal"
cp "$bin_path/Suixu" "$app_path/Contents/MacOS/Suixu"
cp Resources/Info.plist "$app_path/Contents/Info.plist"
cp -R "$bin_path/Suixu_SuixuCore.bundle" "$resource_path/"
cp Resources/AppIcon.icns "$resource_path/"
cp LICENSE "$resource_path/Legal/LICENSE.txt"
cp THIRD_PARTY_NOTICES.md "$resource_path/Legal/THIRD_PARTY_NOTICES.md"
cp docs/legal/*.txt "$resource_path/Legal/"

plutil -lint "$app_path/Contents/Info.plist"
codesign --force --deep --sign - "$app_path"
codesign --verify --deep --strict "$app_path"
# Replace only generated output after a complete bundle has passed validation.
rm -rf "$PWD/dist/岁序.app"
mv "$app_path" "$PWD/dist/岁序.app"
echo "Built: $PWD/dist/岁序.app"
