#!/bin/zsh

set -euo pipefail

script_dir=${0:A:h}
version=$(tr -d '[:space:]' < "$script_dir/VERSION")
dist_dir="$script_dir/dist"
dmg_name="Pomote-$version.dmg"
dmg_path="$dist_dir/$dmg_name"
staging_dir=$(mktemp -d "${TMPDIR:-/tmp}/pomote-dmg.XXXXXX")

cleanup() {
    rm -rf "$staging_dir"
}
trap cleanup EXIT

cd "$script_dir"
./build-app.sh

cp -R "$dist_dir/Pomote.app" "$staging_dir/Pomote.app"
ln -s /Applications "$staging_dir/Applications"

hdiutil create \
    -volname "Pomote $version" \
    -srcfolder "$staging_dir" \
    -format UDZO \
    -ov \
    "$dmg_path"

cd "$dist_dir"
shasum -a 256 "$dmg_name" > "$dmg_name.sha256"

echo "$dmg_path"
