#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "$0")" && pwd)"
repository_root="$(cd "$script_dir/../.." && pwd)"
viewport="${1:-1280x720}"
repeat="${2:-1}"
expected_commit="${3:?expected commit is required}"
expected_fixture_checksum="${4:?expected fixture checksum is required}"
result_root="${5:-$repository_root/build/route_c_macos_gate}"
expected_dpr="${ROUTE_C_MACOS_DPR:-2}"
app_container_root="${ROUTE_C_MACOS_APP_CONTAINER:-$HOME/Library/Containers/com.pen.wuxia.wuxiaIdle/Data}"
app_evidence_root="$app_container_root/tmp/route_c_macos_gate"

case "$viewport" in
  1280x720|1440x900) ;;
  *) echo "Unsupported viewport: $viewport" >&2; exit 2 ;;
esac
if ! [[ "$repeat" =~ ^[1-9][0-9]*$ ]] || (( repeat > 20 )); then
  echo "Repeat must be an integer from 1 to 20." >&2
  exit 2
fi
if ! command -v jq >/dev/null 2>&1; then
  echo "jq is required to validate each macOS result." >&2
  exit 3
fi

actual_commit="$(git -C "$repository_root" rev-parse HEAD)"
[[ "$actual_commit" == "$expected_commit" ]] || {
  echo "Commit mismatch. Expected $expected_commit, found $actual_commit." >&2
  exit 4
}
[[ -z "$(git -C "$repository_root" status --porcelain)" ]] || {
  echo "Physical Gate runs require a clean worktree." >&2
  exit 5
}
fixture="$repository_root/data/phase0a_debug_battle.yaml"
actual_fixture_checksum="$(shasum -a 256 "$fixture" | awk '{print $1}')"
expected_fixture_checksum="$(printf '%s' "$expected_fixture_checksum" | tr '[:upper:]' '[:lower:]')"
[[ "$actual_fixture_checksum" == "$expected_fixture_checksum" ]] || {
  echo "Production fixture checksum mismatch." >&2
  exit 6
}

mkdir -p "$result_root"
cd "$repository_root"
if [[ "${ROUTE_C_SKIP_BUILD:-false}" != "true" ]]; then
  flutter pub get
  flutter build macos --profile
fi
launcher="$repository_root/build/macos/Build/Products/Profile/wuxia_idle.app/Contents/MacOS/wuxia_idle"
app_payload="$repository_root/build/macos/Build/Products/Profile/wuxia_idle.app/Contents/Frameworks/App.framework/Versions/A/App"
[[ -x "$launcher" ]] || { echo "Root production Profile launcher not found: $launcher" >&2; exit 7; }
[[ -f "$app_payload" ]] || { echo "Root production Profile AOT payload not found: $app_payload" >&2; exit 7; }
binary_checksum="$(shasum -a 256 "$app_payload" | awk '{print $1}')"
expected_width="${viewport%x*}"
expected_height="${viewport#*x}"

for ((index = 1; index <= repeat; index++)); do
  timestamp="$(date -u +%Y%m%dT%H%M%SZ)"
  run_id="route-c-macos-${viewport}-r${index}-${timestamp}"
  run_dir="$result_root/$run_id"
  app_run_dir="$app_evidence_root/$run_id"
  mkdir -p "$run_dir"
  rm -rf "$app_run_dir"
  mkdir -p "$app_run_dir"
  VISUAL_WINDOW_W="$expected_width" VISUAL_WINDOW_H="$expected_height" \
    caffeinate -dimsu "$launcher" \
    --visual-route=phase0a_battle_profile \
    --battle-profile-run-id="$run_id" \
    --battle-profile-output="$app_run_dir" \
    --battle-profile-sample-seconds=60 \
    --battle-profile-warmup-seconds=12 \
    --battle-profile-cooldown-seconds=30 \
    --battle-profile-viewport="$viewport" \
    --battle-profile-native-content-viewport=true \
    --battle-profile-auto-close=true 2>&1 | tee "$run_dir/run.log"

  cp -R "$app_run_dir/." "$run_dir/"
  rm -rf "$app_run_dir"

  summary="$run_dir/summary.json"
  [[ -f "$summary" ]] || { echo "$run_id did not produce summary.json." >&2; exit 8; }
  jq -e \
    --argjson width "$expected_width" \
    --argjson height "$expected_height" \
    --argjson dpr "$expected_dpr" \
    '.sampled_frames >= 3000 and
     .p99_total_span_ms < 16.6 and
     .max_consecutive_severe_frames <= 1 and
     .frame_streak_gate_passes == true and
     .gc_telemetry_status == "GC_TELEMETRY_COLLECTED" and
     .logical_width == $width and
     .logical_height == $height and
     .device_pixel_ratio == $dpr and
     .rss_end_bytes <= (.rss_start_bytes * 1.10 + 67108864)' \
    "$summary" >/dev/null || {
      echo "$run_id failed the production composite Gate." >&2
      exit 9
    }

  jq -n \
    --arg run_id "$run_id" \
    --arg commit "$actual_commit" \
    --arg binary_sha256 "$binary_checksum" \
    --arg fixture_sha256 "$actual_fixture_checksum" \
    --arg viewport "$viewport" \
    --argjson dpr "$expected_dpr" \
    '{schema:"route-c-macos-production-run-v1", run_id:$run_id,
      app_package:"wuxia_idle", route_id:"phase0a_battle_profile",
      commit:$commit, binary_sha256:$binary_sha256,
      fixture_sha256:$fixture_sha256, viewport:$viewport,
      device_pixel_ratio:$dpr, composite_gate:"PASS",
      raw_evidence:{frames_jsonl:"frames.jsonl", memory_gc_jsonl:"memory_gc.jsonl",
        summary_json:"summary.json", run_log:"run.log"}}' > "$run_dir/manifest.json"
  echo "ROUTE_C_MACOS_RUN_PASS $run_dir"
done
