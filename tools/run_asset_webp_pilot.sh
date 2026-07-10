#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
output_root="${1:-$repo_root/build/asset_webp_pilot}"

for tool in cwebp ffmpeg file rg; do
  if ! command -v "$tool" >/dev/null 2>&1; then
    printf 'Missing required tool: %s\n' "$tool" >&2
    exit 1
  fi
done

content_kind() {
  case "$(file -b "$1")" in
    'PNG image data'*) printf 'png' ;;
    'RIFF (little-endian) data, Web/P image'*) printf 'webp' ;;
    *) printf 'other' ;;
  esac
}

samples=(
  "opaque|assets/characters/first_disciple.png"
  "opaque|assets/enemies/bandit_head.png"
  "alpha|assets/equipment/accessory_liqi_hu_xin_jing_detail.png"
  "alpha|assets/equipment/armor_baowu_wu_jin_zhan_jia_detail.png"
  "opaque|assets/maps/taohuaIsland.webp"
  "opaque|assets/scenes/battle_alley.png"
  "alpha|assets/ui/mj/overlay_low_health_blend.png"
  "opaque|assets/ui/paper_bg.png"
)

bytes() {
  if stat -f '%z' "$1" >/dev/null 2>&1; then
    stat -f '%z' "$1"
  else
    stat -c '%s' "$1"
  fi
}

ratio() {
  awk -v candidate="$1" -v original="$2" \
    'BEGIN { printf "%.1f", candidate * 100 / original }'
}

ssim() {
  ffmpeg -hide_banner -i "$1" -i "$2" -lavfi ssim -f null - 2>&1 \
    | sed -n 's/.*All:\([0-9.]*\).*/\1/p' \
    | tail -1
}

alpha_hash() {
  ffmpeg -hide_banner -loglevel error -i "$1" -vf format=rgba,alphaextract \
    -f hash -hash md5 - 2>/dev/null \
    | sed -n 's/^MD5=//p'
}

rm -rf "$output_root"
mkdir -p \
  "$output_root/candidates/q82" \
  "$output_root/candidates/q88" \
  "$output_root/candidates/lossless" \
  "$output_root/comparisons"

csv="$output_root/results.csv"
printf '%s\n' \
  'source,source_codec,alpha,png_bytes,q82_bytes,q82_pct,q82_ssim,q88_bytes,q88_pct,q88_ssim,lossless_bytes,lossless_pct,alpha_exact' \
  >"$csv"

inventory_csv="$output_root/magic_inventory.csv"
printf '%s\n' 'path,bytes,content' >"$inventory_csv"
while IFS= read -r relative; do
  source="$repo_root/$relative"
  printf '%s,%s,%s\n' \
    "$relative" "$(bytes "$source")" "$(content_kind "$source")" \
    >>"$inventory_csv"
done < <(cd "$repo_root" && rg --files assets -g '*.png')

for entry in "${samples[@]}"; do
  mode="${entry%%|*}"
  relative="${entry#*|}"
  source="$repo_root/$relative"
  safe_name="${relative#assets/}"
  safe_name="${safe_name//\//__}"
  safe_name="${safe_name%.png}"

  q82="$output_root/candidates/q82/$safe_name.webp"
  q88="$output_root/candidates/q88/$safe_name.webp"
  lossless="$output_root/candidates/lossless/$safe_name.webp"

  cwebp -quiet -preset picture -q 82 -m 6 -alpha_q 100 \
    -metadata none "$source" -o "$q82"
  cwebp -quiet -preset picture -q 88 -m 6 -alpha_q 100 \
    -metadata none "$source" -o "$q88"
  cwebp -quiet -z 9 -exact -metadata none "$source" -o "$lossless"

  original_bytes="$(bytes "$source")"
  q82_bytes="$(bytes "$q82")"
  q88_bytes="$(bytes "$q88")"
  lossless_bytes="$(bytes "$lossless")"

  alpha_exact='n/a'
  if [[ "$mode" == 'alpha' ]]; then
    original_alpha="$(alpha_hash "$source")"
    if [[ "$original_alpha" == "$(alpha_hash "$q82")" \
      && "$original_alpha" == "$(alpha_hash "$q88")" \
      && "$original_alpha" == "$(alpha_hash "$lossless")" ]]; then
      alpha_exact='yes'
    else
      alpha_exact='no'
    fi
  fi

  printf '%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s\n' \
    "$relative" \
    "$(content_kind "$source")" \
    "$mode" \
    "$original_bytes" \
    "$q82_bytes" \
    "$(ratio "$q82_bytes" "$original_bytes")" \
    "$(ssim "$source" "$q82")" \
    "$q88_bytes" \
    "$(ratio "$q88_bytes" "$original_bytes")" \
    "$(ssim "$source" "$q88")" \
    "$lossless_bytes" \
    "$(ratio "$lossless_bytes" "$original_bytes")" \
    "$alpha_exact" \
    >>"$csv"

  ffmpeg -hide_banner -loglevel error -y \
    -i "$source" -i "$q82" -i "$q88" -i "$lossless" \
    -filter_complex \
      '[0:v]format=rgba[a];[1:v]format=rgba[b];[2:v]format=rgba[c];[3:v]format=rgba[d];[a][b][c][d]hstack=inputs=4[out]' \
    -map '[out]' -frames:v 1 "$output_root/comparisons/$safe_name.png"
done

printf 'Pilot output: %s\n' "$output_root"
printf 'Metrics: %s\n' "$csv"
printf 'Magic inventory: %s\n' "$inventory_csv"
