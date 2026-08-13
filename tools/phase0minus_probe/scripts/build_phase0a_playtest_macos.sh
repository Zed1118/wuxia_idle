#!/bin/zsh
set -euo pipefail

probe_dir=${0:A:h:h}
repository_root=${probe_dir:h:h}
commit=$(git -C "$repository_root" rev-parse HEAD)
short_commit=${commit[1,8]}
timestamp=$(date -u +%Y%m%dT%H%M%SZ)
package_root="$probe_dir/build/playtest-packages/phase0a-${short_commit}-${timestamp}"

mkdir -p "$package_root/results"
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

launcher="$package_root/启动试玩.command"
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

scenario_checksum=$(shasum -a 256 assets/probe_scenarios.yaml | awk '{print $1}')
printf '%s\n' \
  "commit=$commit" \
  "scenario_checksum=$scenario_checksum" \
  "built_at_utc=$timestamp" \
  'mode=playtest' \
  'viewport=desktop_1280x720' \
  'storage=package-local-results-directory' \
  'production_storage=unreachable' \
  > "$package_root/MANIFEST.txt"

echo "PHASE0A_PLAYTEST_PACKAGE $package_root"
