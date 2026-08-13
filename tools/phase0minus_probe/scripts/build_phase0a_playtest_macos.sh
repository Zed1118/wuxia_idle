#!/bin/zsh
set -euo pipefail

probe_dir=${0:A:h:h}
repository_root=${probe_dir:h:h}
dirty=$(git -C "$repository_root" status --porcelain --untracked-files=all)
if [[ -n "$dirty" ]]; then
  echo 'PACKAGE_FAIL GIT_WORKTREE_DIRTY' >&2
  exit 2
fi
commit=$(git -C "$repository_root" rev-parse HEAD)
short_commit=${commit[1,8]}
timestamp=$(date -u +%Y%m%dT%H%M%SZ)
package_root="$probe_dir/build/playtest-packages/phase0a-${short_commit}-${timestamp}"

mkdir -p "$package_root/results"
if [[ -n "$(find "$package_root/results" -mindepth 1 -print -quit)" ]]; then
  echo 'PACKAGE_FAIL RESULTS_DIRECTORY_NOT_EMPTY' >&2
  exit 3
fi

cd "$repository_root"
flutter build macos --profile
ditto \
  "$repository_root/build/macos/Build/Products/Profile/wuxia_idle.app" \
  "$package_root/挂机武侠_当前点招对照.app"

cd "$probe_dir"
flutter build macos --profile \
  --dart-define=PROBE_MODE=playtest \
  --dart-define=PROBE_VIEWPORT=desktop_1280x720 \
  --dart-define=PROBE_BUILD_COMMIT="$commit"

ditto \
  "$probe_dir/build/macos/Build/Products/Profile/phase0minus_probe.app" \
  "$package_root/挂机武侠_Phase0A.app"
cp "$repository_root/docs/phase0/phase0a-playtest-keycard.md" "$package_root/键位卡.md"
cp "$repository_root/docs/phase0/phase0a-playtest-protocol.md" "$package_root/试玩记录.md"
cp "$repository_root/docs/phase0/phase0a-production-comparison.md" "$package_root/对照说明.md"
cp \
  "$probe_dir/config/phase0a_human_gate_schedule.json" \
  "$package_root/匿名排期.json"
cp \
  "$probe_dir/config/phase0a_human_session.template.json" \
  "$package_root/问卷模板.json"
cp \
  "$probe_dir/scripts/host_phase0a_human_session_macos.sh" \
  "$package_root/主持试玩.command"
chmod +x "$package_root/主持试玩.command"
dart compile exe \
  "$probe_dir/bin/phase0a_human_gate.dart" \
  -o "$package_root/phase0a_human_gate"
mkdir -p "$package_root/可读性五帧"
cp "$probe_dir/assets/readability/manifest.json" "$package_root/可读性五帧/"
cp "$probe_dir/assets/readability/"frame*.png "$package_root/可读性五帧/"
(
  cd "$package_root/可读性五帧"
  shasum -a 256 manifest.json frame*.png > checksums.sha256
)

scenario_checksum=$(shasum -a 256 assets/probe_scenarios.yaml | awk '{print $1}')
comparison_binary_checksum=$(shasum -a 256 "$package_root/挂机武侠_当前点招对照.app/Contents/MacOS/wuxia_idle" | awk '{print $1}')
gameplay_binary_checksum=$(shasum -a 256 "$package_root/挂机武侠_Phase0A.app/Contents/MacOS/phase0minus_probe" | awk '{print $1}')
gameplay_assets="$package_root/挂机武侠_Phase0A.app/Contents/Frameworks/App.framework/Resources/flutter_assets"
embedded_asset_manifest_checksum=$(shasum -a 256 "$gameplay_assets/AssetManifest.bin" | awk '{print $1}')
embedded_scenario_checksum=$(shasum -a 256 "$gameplay_assets/assets/probe_scenarios.yaml" | awk '{print $1}')
embedded_readability_manifest_checksum=$(shasum -a 256 "$gameplay_assets/assets/readability/manifest.json" | awk '{print $1}')
embedded_readability_frames_checksum=$(
  cd "$gameplay_assets/assets/readability"
  shasum -a 256 frame*.png | shasum -a 256 | awk '{print $1}'
)
[[ "$embedded_scenario_checksum" == "$scenario_checksum" ]] || {
  echo 'PACKAGE_FAIL EMBEDDED_SCENARIO_DRIFT' >&2
  exit 4
}
keycard_checksum=$(shasum -a 256 "$package_root/键位卡.md" | awk '{print $1}')
protocol_checksum=$(shasum -a 256 "$package_root/试玩记录.md" | awk '{print $1}')
comparison_protocol_checksum=$(shasum -a 256 "$package_root/对照说明.md" | awk '{print $1}')
schedule_checksum=$(shasum -a 256 "$package_root/匿名排期.json" | awk '{print $1}')
questionnaire_template_checksum=$(shasum -a 256 "$package_root/问卷模板.json" | awk '{print $1}')
host_checksum=$(shasum -a 256 "$package_root/主持试玩.command" | awk '{print $1}')
validator_checksum=$(shasum -a 256 "$package_root/phase0a_human_gate" | awk '{print $1}')
readability_manifest_checksum=$(shasum -a 256 "$package_root/可读性五帧/manifest.json" | awk '{print $1}')
readability_checksums_checksum=$(shasum -a 256 "$package_root/可读性五帧/checksums.sha256" | awk '{print $1}')
printf '%s\n' \
  "commit=$commit" \
  "scenario_checksum=$scenario_checksum" \
  "built_at_utc=$timestamp" \
  'mode=playtest' \
  'viewport=desktop_1280x720' \
  'storage=package-local-results-directory' \
  'production_save_isar=unreachable' \
  'comparison_audio_preferences=read-only-production-setting' \
  'comparison_route=battle_tap_live' \
  'comparison_seed=20260719' \
  'comparison_isar=system-temp-recreated-on-launch' \
  "comparison_binary_checksum=$comparison_binary_checksum" \
  "gameplay_binary_checksum=$gameplay_binary_checksum" \
  "embedded_asset_manifest_checksum=$embedded_asset_manifest_checksum" \
  "embedded_scenario_checksum=$embedded_scenario_checksum" \
  "embedded_readability_manifest_checksum=$embedded_readability_manifest_checksum" \
  "embedded_readability_frames_checksum=$embedded_readability_frames_checksum" \
  "keycard_checksum=$keycard_checksum" \
  "protocol_checksum=$protocol_checksum" \
  "comparison_protocol_checksum=$comparison_protocol_checksum" \
  "schedule_checksum=$schedule_checksum" \
  "questionnaire_template_checksum=$questionnaire_template_checksum" \
  "host_checksum=$host_checksum" \
  "validator_checksum=$validator_checksum" \
  "readability_manifest_checksum=$readability_manifest_checksum" \
  "readability_checksums_checksum=$readability_checksums_checksum" \
  > "$package_root/MANIFEST.txt"

if [[ -n "$(find "$package_root/results" -mindepth 1 -print -quit)" ]]; then
  echo 'PACKAGE_FAIL RESULTS_DIRECTORY_NOT_EMPTY_AFTER_BUILD' >&2
  exit 3
fi

echo "PHASE0A_PLAYTEST_PACKAGE $package_root"
