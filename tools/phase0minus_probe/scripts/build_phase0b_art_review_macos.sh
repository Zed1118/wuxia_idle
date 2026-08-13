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

cat > "$package_root/查看概念样片.command" <<'EOF'
#!/bin/zsh
set -euo pipefail
package_root=${0:A:h}
PROBE_MODE=phase0b_gallery PROBE_VIEWPORT=desktop_1280x720 \
  "$package_root/挂机武侠_Phase0B美术样片.app/Contents/MacOS/phase0minus_probe"
EOF
cat > "$package_root/查看运行样片.command" <<'EOF'
#!/bin/zsh
set -euo pipefail
package_root=${0:A:h}
PROBE_MODE=phase0b_runtime PROBE_VIEWPORT=desktop_1280x720 \
  "$package_root/挂机武侠_Phase0B美术样片.app/Contents/MacOS/phase0minus_probe"
EOF
cat > "$package_root/查看动画路线失败对照.command" <<'EOF'
#!/bin/zsh
set -euo pipefail
package_root=${0:A:h}
PROBE_MODE=phase0b_joint_compare PROBE_VIEWPORT=desktop_1280x720 \
  "$package_root/挂机武侠_Phase0B美术样片.app/Contents/MacOS/phase0minus_probe"
EOF
cat > "$package_root/查看20加1镜头与负载.command" <<'EOF'
#!/bin/zsh
set -euo pipefail
package_root=${0:A:h}
PROBE_MODE=phase0b_art_load PROBE_VIEWPORT=desktop_1280x720 \
PROBE_AUTO_CLOSE=false PROBE_DURATION_SCALE=0.05 \
PROBE_OUTPUT_ROOT=/tmp/wuxia_phase0b_art_load \
PROBE_RUN_ID=packaged-camera-review \
  "$package_root/挂机武侠_Phase0B美术样片.app/Contents/MacOS/phase0minus_probe"
EOF
cat > "$package_root/查看连续地图方向.command" <<'EOF'
#!/bin/zsh
set -euo pipefail
package_root=${0:A:h}
PROBE_MODE=phase0b_scroll_review PROBE_VIEWPORT=desktop_1280x720 \
  "$package_root/挂机武侠_Phase0B美术样片.app/Contents/MacOS/phase0minus_probe"
EOF
chmod +x \
  "$package_root/查看概念样片.command" \
  "$package_root/查看运行样片.command" \
  "$package_root/查看动画路线失败对照.command" \
  "$package_root/查看20加1镜头与负载.command" \
  "$package_root/查看连续地图方向.command"

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
for runtime_asset in \
  founder_pose_atlas_v1.png \
  bandit_pose_atlas_v1.png \
  elite_pose_atlas_v1.png \
  founder_cutout_parts_v1.png \
  mountain_pass_background_v1.webp \
  mountain_pass_background_v2.png; do
  [[ -s "$embedded_assets/runtime/$runtime_asset" ]] || {
    echo "PHASE0B_PACKAGE_FAIL EMBEDDED_RUNTIME_ASSET_MISSING $runtime_asset" >&2
    exit 4
  }
done

printf '%s\n' \
  "commit=$commit" \
  "git_dirty=$dirty" \
  "built_at_utc=$timestamp" \
  'modes=phase0b_gallery,phase0b_runtime,phase0b_joint_compare,phase0b_art_load,phase0b_scroll_review' \
  'viewport=desktop_1280x720' \
  'claim=concept_camera_v2_art_load_and_rejected_auto_cutout_review_only' \
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
    查看概念样片.command \
    查看运行样片.command \
    查看动画路线失败对照.command \
    查看20加1镜头与负载.command \
    查看连续地图方向.command \
    挂机武侠_Phase0B美术样片.app/Contents/MacOS/phase0minus_probe \
    > SHA256SUMS.txt
  shasum -a 256 -c SHA256SUMS.txt
)

echo "PHASE0B_ART_REVIEW_PACKAGE $package_root"
