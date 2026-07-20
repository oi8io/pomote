#!/bin/zsh

set -euo pipefail

script_dir=${0:A:h}
app_dir="$script_dir/dist/Pomote.app"
contents_dir="$app_dir/Contents"
build_dir="$script_dir/.build"

cd "$script_dir"
mkdir -p "$build_dir/ModuleCache"
mkdir -p "$contents_dir/MacOS" "$contents_dir/Resources"
xcrun clang \
    -fobjc-arc \
    -fmodules-cache-path="$build_dir/ModuleCache" \
    -mmacosx-version-min=13.0 \
    -arch arm64 \
    -arch x86_64 \
    -framework Cocoa \
    -framework UserNotifications \
    -O2 \
    "Sources/main.m" \
    -o "$contents_dir/MacOS/Pomote"
cp "Resources/Info.plist" "$contents_dir/Info.plist"
chmod +x "$contents_dir/MacOS/Pomote"
codesign --force --sign - "$app_dir" >/dev/null

echo "$app_dir"
