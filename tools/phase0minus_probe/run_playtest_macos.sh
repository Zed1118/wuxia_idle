#!/bin/zsh
set -euo pipefail

script_dir=${0:A:h}
cd "$script_dir"

flutter run \
  -d macos \
  --profile \
  --dart-define=PROBE_MODE=playtest \
  --dart-define=PROBE_VIEWPORT=desktop_1280x720
