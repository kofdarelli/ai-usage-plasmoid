#!/usr/bin/env bash
set -euo pipefail

project_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
version="$(sed -n 's/.*"Version": "\([^"]*\)".*/\1/p' "$project_dir/package/metadata.json")"
output="$project_dir/dist/ai-usage-$version.plasmoid"

mkdir -p "$project_dir/dist"
rm -f "$output"
(cd "$project_dir/package" && cmake -E tar cf "$output" --format=zip -- metadata.json contents)
echo "$output"
