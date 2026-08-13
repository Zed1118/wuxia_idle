#!/bin/zsh
set -euo pipefail

probe_dir=${0:A:h:h}
repository_root=${probe_dir:h:h}
commit=$(git -C "$repository_root" rev-parse HEAD)
short_commit=${commit[1,8]}
timestamp=$(date -u +%Y%m%dT%H%M%SZ)
package_root="$probe_dir/build/playtest-packages/phase0a-${short_commit}-${timestamp}"

mkdir -p "$package_root/results"

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

comparison_launcher="$package_root/1_启动当前点招对照.command"
printf '%s\n' \
  '#!/bin/zsh' \
  'set -euo pipefail' \
  'package_dir=${0:A:h}' \
  'export VISUAL_WINDOW_W=1280' \
  'export VISUAL_WINDOW_H=720' \
  'exec "$package_dir/挂机武侠_当前点招对照.app/Contents/MacOS/wuxia_idle" --visual-route=battle_tap_live' \
  > "$comparison_launcher"
chmod +x "$comparison_launcher"

launcher="$package_root/2_启动Phase0A灰盒.command"
printf '%s\n' \
  '#!/bin/zsh' \
  'set -euo pipefail' \
  'package_dir=${0:A:h}' \
  'export PROBE_MODE=playtest' \
  'export PROBE_VIEWPORT=desktop_1280x720' \
  'export PROBE_OUTPUT_ROOT="$package_dir/results"' \
  'exec "$package_dir/挂机武侠_Phase0A.app/Contents/MacOS/phase0minus_probe"' \
  > "$launcher"
chmod +x "$launcher"
cp "$launcher" "$package_root/启动试玩.command"

scenario_checksum=$(shasum -a 256 assets/probe_scenarios.yaml | awk '{print $1}')
comparison_binary_checksum=$(shasum -a 256 "$package_root/挂机武侠_当前点招对照.app/Contents/MacOS/wuxia_idle" | awk '{print $1}')
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
  > "$package_root/MANIFEST.txt"

echo "PHASE0A_PLAYTEST_PACKAGE $package_root"
