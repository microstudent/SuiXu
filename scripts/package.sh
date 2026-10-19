#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
./scripts/build.sh release
version=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' Resources/Info.plist)
if [[ ! "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "CFBundleShortVersionString must use MAJOR.MINOR.PATCH" >&2
  exit 1
fi
architecture="$(uname -m)"
archive="SuiXu-${version}-macos-${architecture}.zip"
ditto -c -k --sequesterRsrc --keepParent dist/岁序.app "dist/$archive"
(
  cd dist
  shasum -a 256 "$archive" > SHA256SUMS
  shasum -a 256 -c SHA256SUMS
)
echo "Packaged: $PWD/dist/$archive"
