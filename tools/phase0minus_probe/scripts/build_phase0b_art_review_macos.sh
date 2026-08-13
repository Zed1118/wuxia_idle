#!/bin/zsh
set -euo pipefail

probe_dir=${0:A:h:h}
repository_root=${probe_dir:h:h}
commit=$(git -C "$repository_root" rev-parse HEAD)
short_commit=${commit[1,8]}
dirty=false
if [[ -n "$(git -C "$repository_root" status --porcelain --untracked-files=all)" ]]; then
  dirty=true
fi
timestamp=$(date -u +%Y%m%dT%H%M%SZ)
package_root="$probe_dir/build/phase0b-review/phase0b-art-${short_commit}-${timestamp}"

cd "$probe_dir"
flutter build macos --profile \
  --dart-define=PROBE_MODE=phase0b_gallery \
  --dart-define=PROBE_VIEWPORT=desktop_1280x720

mkdir -p "$package_root"
ditto \
  "$probe_dir/build/macos/Build/Products/Profile/phase0minus_probe.app" \
  "$package_root/挂机武侠_Phase0B美术样片.app"
cp \
  "$repository_root/docs/spec/2026-08-13-phase0b-art-sample-spec.md" \
  "$package_root/美术样片规格.md"
cp "$probe_dir/assets/phase0b/PROMPTS.md" "$package_root/提示词账本.md"
cp "$probe_dir/assets/phase0b/manifest.json" "$package_root/asset_manifest.json"
cp "$probe_dir/assets/phase0b/SHA256SUMS.txt" "$package_root/原图校验.sha256"

embedded_assets="$package_root/挂机武侠_Phase0B美术样片.app/Contents/Frameworks/App.framework/Resources/flutter_assets/assets/phase0b"
[[ -f "$embedded_assets/manifest.json" ]] || {
  echo 'PHASE0B_PACKAGE_FAIL EMBEDDED_MANIFEST_MISSING' >&2
  exit 2
}
embedded_manifest_checksum=$(shasum -a 256 "$embedded_assets/manifest.json" | awk '{print $1}')
source_manifest_checksum=$(shasum -a 256 "$probe_dir/assets/phase0b/manifest.json" | awk '{print $1}')
[[ "$embedded_manifest_checksum" == "$source_manifest_checksum" ]] || {
  echo 'PHASE0B_PACKAGE_FAIL EMBEDDED_MANIFEST_DRIFT' >&2
  exit 3
}

printf '%s\n' \
  "commit=$commit" \
  "git_dirty=$dirty" \
  "built_at_utc=$timestamp" \
  'mode=phase0b_gallery' \
  'viewport=desktop_1280x720' \
  'claim=concept_review_only_not_runtime_animation_gate' \
  "source_manifest_checksum=$source_manifest_checksum" \
  "embedded_manifest_checksum=$embedded_manifest_checksum" \
  > "$package_root/MANIFEST.txt"

(
  cd "$package_root"
  shasum -a 256 \
    MANIFEST.txt \
    美术样片规格.md \
    提示词账本.md \
    asset_manifest.json \
    原图校验.sha256 \
    挂机武侠_Phase0B美术样片.app/Contents/MacOS/phase0minus_probe \
    > SHA256SUMS.txt
  shasum -a 256 -c SHA256SUMS.txt
)

echo "PHASE0B_ART_REVIEW_PACKAGE $package_root"
