#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "$0")" && pwd)"
repository_root="$(cd "$script_dir/../.." && pwd)"
expected_commit="${1:?expected commit is required}"
expected_fixture_checksum="${2:?expected fixture checksum is required}"
timestamp="$(date -u +%Y%m%dT%H%M%SZ)"
output_root="${3:-$repository_root/build/route_c_macos_matrix/$timestamp}"
runner="$script_dir/run_route_c_macos_profile.sh"

mkdir -p "$output_root"
"$runner" 1280x720 3 "$expected_commit" "$expected_fixture_checksum" "$output_root"
ROUTE_C_SKIP_BUILD=true "$runner" 1440x900 3 \
  "$expected_commit" "$expected_fixture_checksum" "$output_root"

cp "$repository_root/build/macos/Build/Products/Profile/wuxia_idle.app/Contents/MacOS/wuxia_idle" \
  "$output_root/wuxia_idle"
cp "$repository_root/data/phase0a_debug_battle.yaml" "$output_root/phase0a_debug_battle.yaml"
(
  cd "$output_root"
  find . -type f ! -name SHA256SUMS.txt -print | LC_ALL=C sort |
    while IFS= read -r evidence_file; do
      shasum -a 256 "$evidence_file"
    done > SHA256SUMS.txt
)
ditto -c -k --sequesterRsrc --keepParent "$output_root" "$output_root.zip"
echo "ROUTE_C_MACOS_MATRIX_PASS $output_root"
