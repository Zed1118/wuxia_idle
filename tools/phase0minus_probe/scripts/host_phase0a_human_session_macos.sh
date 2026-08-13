#!/bin/zsh
set -euo pipefail

package_dir=${PHASE0A_PACKAGE_DIR:-${0:A:h}}
manifest="$package_dir/MANIFEST.txt"
lock_dir="$package_dir/.phase0a-session.lock"
results_root="$package_dir/results/sessions"
comparison_binary="$package_dir/挂机武侠_当前点招对照.app/Contents/MacOS/wuxia_idle"
gameplay_binary="$package_dir/挂机武侠_Phase0A.app/Contents/MacOS/phase0minus_probe"
gameplay_assets="$package_dir/挂机武侠_Phase0A.app/Contents/Frameworks/App.framework/Resources/flutter_assets"

usage() {
  printf '%s\n' \
    '用法: 主持试玩.command [P01|P02|P03|P04|P05|P06]' \
    '      主持试玩.command --print-schedule'
}

schedule() {
  case "$1" in
    P01) printf 'idle AB\n' ;;
    P02) printf 'idle BA\n' ;;
    P03) printf 'arpg AB\n' ;;
    P04) printf 'arpg BA\n' ;;
    P05) printf 'mixed AB\n' ;;
    P06) printf 'mixed BA\n' ;;
    *) return 1 ;;
  esac
}

if [[ "${1:-}" == '--print-schedule' ]]; then
  for id in P01 P02 P03 P04 P05 P06; do
    printf '%s %s\n' "$id" "$(schedule "$id")"
  done
  exit 0
fi

participant=${1:-}
if [[ -z "$participant" ]]; then
  printf '请输入匿名测试位(P01–P06): '
  read -r participant
fi
if ! assignment_line=$(schedule "$participant"); then
  usage >&2
  exit 64
fi
cohort=${assignment_line%% *}
assignment=${assignment_line##* }

[[ -f "$manifest" ]] || { echo 'HOST_FAIL MANIFEST_MISSING' >&2; exit 65; }
[[ -x "$comparison_binary" ]] || { echo 'HOST_FAIL COMPARISON_BINARY_MISSING' >&2; exit 65; }
[[ -x "$gameplay_binary" ]] || { echo 'HOST_FAIL GAMEPLAY_BINARY_MISSING' >&2; exit 65; }

manifest_value() {
  sed -n "s/^$1=//p" "$manifest"
}

verify_hash() {
  local key=$1 file=$2 expected actual
  expected=$(manifest_value "$key")
  [[ -n "$expected" ]] || { echo "HOST_FAIL HASH_KEY_MISSING:$key" >&2; exit 66; }
  actual=$(shasum -a 256 "$file" | awk '{print $1}')
  [[ "$actual" == "$expected" ]] || { echo "HOST_FAIL HASH_MISMATCH:$key" >&2; exit 66; }
}

verify_hash comparison_binary_checksum "$comparison_binary"
verify_hash gameplay_binary_checksum "$gameplay_binary"
verify_hash embedded_asset_manifest_checksum "$gameplay_assets/AssetManifest.bin"
verify_hash embedded_scenario_checksum "$gameplay_assets/assets/probe_scenarios.yaml"
verify_hash embedded_readability_manifest_checksum "$gameplay_assets/assets/readability/manifest.json"
expected_embedded_frames=$(manifest_value embedded_readability_frames_checksum)
actual_embedded_frames=$(
  cd "$gameplay_assets/assets/readability"
  shasum -a 256 frame*.png | shasum -a 256 | awk '{print $1}'
)
[[ "$actual_embedded_frames" == "$expected_embedded_frames" ]] || {
  echo 'HOST_FAIL HASH_MISMATCH:embedded_readability_frames_checksum' >&2
  exit 66
}
verify_hash keycard_checksum "$package_dir/键位卡.md"
verify_hash protocol_checksum "$package_dir/试玩记录.md"
verify_hash comparison_protocol_checksum "$package_dir/对照说明.md"
verify_hash schedule_checksum "$package_dir/匿名排期.json"
verify_hash questionnaire_template_checksum "$package_dir/问卷模板.json"
verify_hash host_checksum "$package_dir/主持试玩.command"
verify_hash validator_checksum "$package_dir/校验汇总器"
verify_hash readability_manifest_checksum "$package_dir/可读性五帧/manifest.json"
verify_hash readability_checksums_checksum "$package_dir/可读性五帧/checksums.sha256"
(cd "$package_dir/可读性五帧" && shasum -a 256 -c checksums.sha256 >/dev/null) || {
  echo 'HOST_FAIL STIMULUS_HASH_MISMATCH' >&2
  exit 66
}

if pgrep -x wuxia_idle >/dev/null 2>&1 || pgrep -x phase0minus_probe >/dev/null 2>&1; then
  echo 'HOST_FAIL APP_ALREADY_RUNNING' >&2
  exit 67
fi
if ! mkdir "$lock_dir" 2>/dev/null; then
  echo 'HOST_FAIL SESSION_LOCKED' >&2
  exit 67
fi
trap 'rmdir "$lock_dir" 2>/dev/null || true' EXIT INT TERM

session_dir="$results_root/$participant"
if [[ -e "$session_dir" ]]; then
  echo "HOST_FAIL DUPLICATE_PARTICIPANT:$participant" >&2
  exit 68
fi
mkdir -p "$session_dir/raw" "$session_dir/logs"
slot=${participant#P}
slot=$((10#$slot))
session_id="phase0a-${participant:l}-$(date -u +%Y%m%dt%H%M%Sz)"
manifest_commit=$(manifest_value commit)
printf '%s\n' \
  "session_id=$session_id" \
  "participant_id=$participant" \
  "cohort=$cohort" \
  "assignment=$assignment" \
  "manifest_commit=$manifest_commit" \
  'status=IN_PROGRESS' \
  > "$session_dir/session.state"
: > "$session_dir/execution.events"
sed \
  -e "s/REPLACE_WITH_MANIFEST_COMMIT/$manifest_commit/" \
  -e "s/REPLACE_WITH_SESSION_STATE_ID/$session_id/" \
  -e "s/\"participant_id\": \"P01\"/\"participant_id\": \"$participant\"/" \
  -e "s/\"player_type\": \"idle\"/\"player_type\": \"$cohort\"/" \
  -e "s/\"order\": \"AB\"/\"order\": \"$assignment\"/" \
  -e "s/\"slot\": 1/\"slot\": $slot/" \
  "$package_dir/问卷模板.json" > "$session_dir/human-session.json"

run_comparison() {
  printf '\n[对照段] 只用单步，不点继续。完成 45–60 秒后关闭窗口。\n'
  VISUAL_WINDOW_W=1280 VISUAL_WINDOW_H=720 \
    "$comparison_binary" --visual-route=battle_tap_live \
    > "$session_dir/logs/comparison.log" 2>&1
  echo 'comparison_complete' >> "$session_dir/execution.events"
}

run_gameplay() {
  printf '\n[Phase 0A] 首轮前 30 秒不提示技能时机。结束后先询问意愿，再允许点 PLAY AGAIN。\n'
  PROBE_MODE=playtest \
  PROBE_VIEWPORT=desktop_1280x720 \
  PROBE_OUTPUT_ROOT="$session_dir/raw" \
  PHASE0A_SESSION_ID="$session_id" \
  PHASE0A_PARTICIPANT_ID="$participant" \
  PHASE0A_SLOT="$slot" \
  PHASE0A_ORDER="$assignment" \
    "$gameplay_binary" > "$session_dir/logs/gameplay.log" 2>&1
  echo 'gameplay_complete' >> "$session_dir/execution.events"
}

run_readability() {
  printf '\n[可读性五帧] 每帧只显示 1 秒，遮罩后再记录回答。\n'
  PROBE_MODE=readability \
  PROBE_VIEWPORT=desktop_1280x720 \
    "$gameplay_binary" > "$session_dir/logs/readability.log" 2>&1
  echo 'readability_complete' >> "$session_dir/execution.events"
}

if [[ "$assignment" == 'AB' ]]; then
  run_comparison
  run_gameplay
else
  run_gameplay
  run_comparison
fi
run_readability

sed 's/^status=IN_PROGRESS$/status=COMPLETE/' \
  "$session_dir/session.state" > "$session_dir/session.state.tmp"
mv "$session_dir/session.state.tmp" "$session_dir/session.state"

printf '\n三段执行证据已完成；请填写并校验结构化问卷。\n'
echo "HOST_SESSION_DIR $session_dir"
