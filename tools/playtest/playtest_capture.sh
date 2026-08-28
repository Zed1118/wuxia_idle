#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DRIVER_SOURCE="$REPO_ROOT/tools/playtest/cgevent_driver.swift"
EXTRACTOR="$REPO_ROOT/tools/playtest/extract_keyframes.py"
MANIFEST_WRITER="$REPO_ROOT/tools/playtest/write_playtest_manifest.py"
SWIFT_WINID="$REPO_ROOT/tools/visual_capture/window_id.swift"
LOCK_STATE_HELPER="$REPO_ROOT/tools/visual_capture/lock_state.py"
APP_PROCESS_NAME="wuxia_idle"
ALL_SPACES=0
source "$REPO_ROOT/tools/visual_capture/visual_capture_lib.sh"

APP_EXECUTABLE="$REPO_ROOT/build/macos/Build/Products/Debug/wuxia_idle.app/Contents/MacOS/wuxia_idle"
SCENARIO=""
OUTPUT_DIR=""
SAVE_BACKUP_DIR=""
SAVE_DIR="${PLAYTEST_SAVE_DIR:-$(python3 -c 'from pathlib import Path; print(Path.home() / "Library/Containers/com.pen.wuxia.wuxiaIdle/Data/Documents")')}"
WINDOW_WIDTH=1440
WINDOW_HEIGHT=900
READY_TIMEOUT=90
DRY_RUN=0

APP_PID=""
RECORDER_PID=""
APP_LOG=""
SAVES_RESTORED=0
SAVE_GUARD_ARMED=0

usage() {
  cat <<'USAGE'
Production playtest capture runner.

Usage:
  tools/playtest/playtest_capture.sh --scenario FILE --output DIR \
    --save-backup DIR [options]

Options:
  --scenario FILE       JSON action sequence. production_entry must be true.
  --output DIR          New build/ output directory for video, frames, and manifest.
  --save-backup DIR     Cold backup containing all three wuxia_save_slotN.isar files.
  --save-dir DIR        Live save container. Defaults to the app sandbox container.
  --app PATH            Debug .app executable. Defaults to this worktree build.
  --window WIDTHxHEIGHT Production window size. Default: 1440x900.
  --ready-timeout SEC   Window-ready timeout. Default: 90.
  --dry-run             Validate inputs and print the planned run without launching.
  -h, --help            Show this help.

The runner fails closed unless live saves match the supplied cold backup before
launch. On every normal, failed, or interrupted run it stops the app, restores
all three slots from that backup, and verifies byte equality with cmp.
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --scenario)
      SCENARIO="$2"
      shift 2
      ;;
    --output)
      OUTPUT_DIR="$2"
      shift 2
      ;;
    --save-backup)
      SAVE_BACKUP_DIR="$2"
      shift 2
      ;;
    --save-dir)
      SAVE_DIR="$2"
      shift 2
      ;;
    --app)
      APP_EXECUTABLE="$2"
      shift 2
      ;;
    --window)
      WINDOW_WIDTH="${2%x*}"
      WINDOW_HEIGHT="${2#*x}"
      shift 2
      ;;
    --ready-timeout)
      READY_TIMEOUT="$2"
      shift 2
      ;;
    --dry-run)
      DRY_RUN=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage
      exit 2
      ;;
  esac
done

if [[ -z "$SCENARIO" || -z "$OUTPUT_DIR" || -z "$SAVE_BACKUP_DIR" ]]; then
  usage >&2
  exit 2
fi
if [[ ! -f "$SCENARIO" ]]; then
  echo "Scenario does not exist: $SCENARIO" >&2
  exit 2
fi
if [[ ! "$WINDOW_WIDTH" =~ ^[0-9]+$ || ! "$WINDOW_HEIGHT" =~ ^[0-9]+$ ]]; then
  echo "--window must be WIDTHxHEIGHT" >&2
  exit 2
fi
if [[ ! "$READY_TIMEOUT" =~ ^[0-9]+$ || "$READY_TIMEOUT" -le 0 ]]; then
  echo "--ready-timeout must be a positive integer" >&2
  exit 2
fi

scenario_values="$(python3 - "$SCENARIO" <<'PY'
import json
import sys
from pathlib import Path

data = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
if data.get("schema_version") != 1:
    raise SystemExit("scenario schema_version must be 1")
if data.get("production_entry") is not True:
    raise SystemExit("scenario production_entry must be true")
if not isinstance(data.get("recording_max_seconds"), int) or data["recording_max_seconds"] <= 0:
    raise SystemExit("scenario recording_max_seconds must be a positive integer")
print(data.get("id", ""))
print(data["recording_max_seconds"])
PY
)"
SCENARIO_ID="$(printf '%s\n' "$scenario_values" | sed -n '1p')"
RECORDING_MAX_SECONDS="$(printf '%s\n' "$scenario_values" | sed -n '2p')"
if [[ -z "$SCENARIO_ID" ]]; then
  echo "Scenario id must not be empty" >&2
  exit 2
fi
for slot in 1 2 3; do
  if [[ ! -f "$SAVE_BACKUP_DIR/wuxia_save_slot${slot}.isar" ]]; then
    echo "Cold backup is missing slot $slot: $SAVE_BACKUP_DIR" >&2
    exit 2
  fi
done

if [[ "$DRY_RUN" -eq 1 ]]; then
  printf '[dry-run] scenario=%s production_entry=true actions=CGEvent\n' "$SCENARIO_ID"
  printf '[dry-run] app=%s window=%sx%s ready_timeout=%ss\n' \
    "$APP_EXECUTABLE" "$WINDOW_WIDTH" "$WINDOW_HEIGHT" "$READY_TIMEOUT"
  printf '[dry-run] record=screencapture window-id max=%ss keyframes=entry,first_contact,skill_release,settlement\n' \
    "$RECORDING_MAX_SECONDS"
  printf '[dry-run] save_guard=three-slot fail-closed restore-and-cmp backup=%s\n' \
    "$SAVE_BACKUP_DIR"
  exit 0
fi

export LC_ALL=en_US.UTF-8
for command in swiftc screencapture ffmpeg ffprobe python3 shasum; do
  if ! command -v "$command" >/dev/null 2>&1; then
    echo "Required command is unavailable: $command" >&2
    exit 2
  fi
done
if [[ ! -x "$APP_EXECUTABLE" ]]; then
  echo "App executable is missing or not executable: $APP_EXECUTABLE" >&2
  exit 2
fi
if [[ -e "$OUTPUT_DIR" ]]; then
  echo "Output directory already exists; refusing to overwrite: $OUTPUT_DIR" >&2
  exit 2
fi
if [[ ! -d "$SAVE_DIR" ]]; then
  echo "Live save directory does not exist: $SAVE_DIR" >&2
  exit 2
fi

stop_recording() {
  if [[ -z "$RECORDER_PID" ]]; then
    return 0
  fi
  if kill -0 "$RECORDER_PID" >/dev/null 2>&1; then
    kill -INT "$RECORDER_PID" >/dev/null 2>&1 || true
    local elapsed=0
    while kill -0 "$RECORDER_PID" >/dev/null 2>&1 && [[ "$elapsed" -lt 15 ]]; do
      sleep 1
      elapsed=$((elapsed + 1))
    done
    if kill -0 "$RECORDER_PID" >/dev/null 2>&1; then
      kill "$RECORDER_PID" >/dev/null 2>&1 || true
    fi
  fi
  wait "$RECORDER_PID" >/dev/null 2>&1 || true
  RECORDER_PID=""
}

stop_app() {
  if [[ -n "$APP_PID" ]]; then
    stop_pid "$APP_PID" "$APP_LOG"
    APP_PID=""
  fi
  terminate_visual_app
  if pgrep -x "$APP_PROCESS_NAME" >/dev/null 2>&1; then
    echo "App process remains alive after termination" >&2
    return 1
  fi
}

restore_saves() {
  local restore_failed=0
  for slot in 1 2 3; do
    cp -p \
      "$SAVE_BACKUP_DIR/wuxia_save_slot${slot}.isar" \
      "$SAVE_DIR/wuxia_save_slot${slot}.isar" || restore_failed=1
  done
  for slot in 1 2 3; do
    cmp -s \
      "$SAVE_BACKUP_DIR/wuxia_save_slot${slot}.isar" \
      "$SAVE_DIR/wuxia_save_slot${slot}.isar" || restore_failed=1
  done
  if [[ "$restore_failed" -ne 0 ]]; then
    echo "SAVE_RESTORE_FAILED: one or more slots differ from the cold backup" >&2
    return 1
  fi
  SAVES_RESTORED=1
  printf 'SAVE_RESTORE_OK: slots=3 backup=%s\n' "$SAVE_BACKUP_DIR"
}

on_exit() {
  local rc=$?
  trap - EXIT INT TERM
  set +e
  stop_recording
  stop_app
  if [[ "$SAVE_GUARD_ARMED" -eq 1 && "$SAVES_RESTORED" -eq 0 ]]; then
    if ! restore_saves; then
      rc=1
    fi
  fi
  exit "$rc"
}
trap on_exit EXIT INT TERM

terminate_visual_app
if pgrep -x "$APP_PROCESS_NAME" >/dev/null 2>&1; then
  echo "Unable to establish a cold app state" >&2
  exit 1
fi
for slot in 1 2 3; do
  live="$SAVE_DIR/wuxia_save_slot${slot}.isar"
  backup="$SAVE_BACKUP_DIR/wuxia_save_slot${slot}.isar"
  if [[ ! -f "$live" ]] || ! cmp -s "$backup" "$live"; then
    echo "Live slot $slot does not match the cold backup; refusing to overwrite it" >&2
    exit 1
  fi
done
SAVE_GUARD_ARMED=1

mkdir -p "$(dirname "$OUTPUT_DIR")"
mkdir "$OUTPUT_DIR"
KEYFRAMES_DIR="$OUTPUT_DIR/keyframes"
mkdir "$KEYFRAMES_DIR"
SCENARIO_COPY="$OUTPUT_DIR/scenario.json"
cp -p "$SCENARIO" "$SCENARIO_COPY"
SAVE_BEFORE="$OUTPUT_DIR/save_before.sha256"
SAVE_AFTER="$OUTPUT_DIR/save_after.sha256"
shasum -a 256 "$SAVE_DIR"/wuxia_save_slot{1,2,3}.isar >"$SAVE_BEFORE"

DRIVER_DIR="$REPO_ROOT/build/playtest_tools"
mkdir -p "$DRIVER_DIR"
DRIVER_BIN="$DRIVER_DIR/cgevent_driver"
swiftc "$DRIVER_SOURCE" -o "$DRIVER_BIN"
"$DRIVER_BIN" validate --scenario "$SCENARIO_COPY"

APP_LOG="$OUTPUT_DIR/app.log"
VISUAL_WINDOW_W="$WINDOW_WIDTH" VISUAL_WINDOW_H="$WINDOW_HEIGHT" \
  "$APP_EXECUTABLE" >"$APP_LOG" 2>&1 < /dev/null &
APP_PID=$!

READY_LOG="$OUTPUT_DIR/window_ready.json"
ready_elapsed=0
while [[ "$ready_elapsed" -lt "$READY_TIMEOUT" ]]; do
  if ! kill -0 "$APP_PID" >/dev/null 2>&1; then
    echo "App exited before its production window became ready: $APP_LOG" >&2
    exit 1
  fi
  if "$DRIVER_BIN" bounds --pid "$APP_PID" --app-path "${APP_EXECUTABLE%/Contents/MacOS/wuxia_idle}" \
      >"$READY_LOG" 2>/dev/null; then
    break
  fi
  sleep 1
  ready_elapsed=$((ready_elapsed + 1))
done
if [[ "$ready_elapsed" -ge "$READY_TIMEOUT" ]]; then
  echo "Production app window did not become ready within ${READY_TIMEOUT}s" >&2
  exit 1
fi

WINDOW_ID="$(window_id "$APP_PID")"
if [[ -z "$WINDOW_ID" ]]; then
  echo "Unable to resolve the production app window id" >&2
  exit 1
fi
VIDEO="$OUTPUT_DIR/playtest.mov"
RECORDING_LOG="$OUTPUT_DIR/recording.log"
RECORD_START_EPOCH_MS="$(python3 -c 'import time; print(time.time_ns() // 1_000_000)')"
screencapture -x -v -T0 -V"$RECORDING_MAX_SECONDS" -l"$WINDOW_ID" "$VIDEO" \
  >"$RECORDING_LOG" 2>&1 &
RECORDER_PID=$!
sleep 1
if ! kill -0 "$RECORDER_PID" >/dev/null 2>&1; then
  wait "$RECORDER_PID" || true
  echo "Screen recording failed to start; verify Screen Recording permission: $RECORDING_LOG" >&2
  exit 1
fi

ACTIONS_LOG="$OUTPUT_DIR/actions.jsonl"
"$DRIVER_BIN" run \
  --pid "$APP_PID" \
  --app-path "${APP_EXECUTABLE%/Contents/MacOS/wuxia_idle}" \
  --scenario "$SCENARIO_COPY" \
  --log "$ACTIONS_LOG"
if ! wait "$RECORDER_PID"; then
  RECORDER_PID=""
  echo "Screen recording failed before its fixed duration completed: $RECORDING_LOG" >&2
  exit 1
fi
RECORDER_PID=""
if [[ ! -s "$VIDEO" ]]; then
  echo "Screen recording is empty: $VIDEO" >&2
  exit 1
fi
ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1 "$VIDEO"

stop_app
restore_saves
shasum -a 256 "$SAVE_DIR"/wuxia_save_slot{1,2,3}.isar >"$SAVE_AFTER"

python3 "$EXTRACTOR" \
  --video "$VIDEO" \
  --actions-log "$ACTIONS_LOG" \
  --output-dir "$KEYFRAMES_DIR" \
  --record-start-epoch-ms "$RECORD_START_EPOCH_MS"

MANIFEST="$OUTPUT_DIR/manifest.json"
python3 "$MANIFEST_WRITER" \
  --capture-root "$OUTPUT_DIR" \
  --scenario "$SCENARIO_COPY" \
  --actions-log "$ACTIONS_LOG" \
  --video "$VIDEO" \
  --keyframes-index "$KEYFRAMES_DIR/keyframes.json" \
  --save-before "$SAVE_BEFORE" \
  --save-after "$SAVE_AFTER" \
  --save-backup-dir "$SAVE_BACKUP_DIR" \
  --repo-root "$REPO_ROOT" \
  --record-start-epoch-ms "$RECORD_START_EPOCH_MS" \
  --output "$MANIFEST"

printf 'PLAYTEST_CAPTURE_OK: scenario=%s video=%s keyframes=4 manifest=%s saves_restored=true\n' \
  "$SCENARIO_ID" "$VIDEO" "$MANIFEST"
