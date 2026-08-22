#!/usr/bin/env bash
set -euo pipefail

repository="$(git rev-parse --show-toplevel)"
candidate="${1:-HEAD}"
output="${2:-$repository/build/route_c_human_gate}"
commit="$(git -C "$repository" rev-parse "$candidate^{commit}")"

if [[ -n "$(git -C "$repository" status --porcelain)" ]]; then
  echo "refusing to package a dirty worktree" >&2
  exit 1
fi
if [[ "$(git -C "$repository" rev-parse HEAD)" != "$commit" ]]; then
  echo "candidate must be the checked-out HEAD" >&2
  exit 1
fi

cd "$repository"
flutter build macos --profile --no-pub

source_app="$repository/build/macos/Build/Products/Profile/wuxia_idle.app"
package_app="$output/package/wuxia_idle.app"
package_fixture="$output/package/phase0a_debug_battle.yaml"
mkdir -p "$output/package"
ditto "$source_app" "$package_app"
cp "$repository/data/phase0a_debug_battle.yaml" "$package_fixture"

dart run tool/route_c_human_gate.dart prepare \
  --candidate "$commit" \
  --app "$package_app/Contents/Frameworks/App.framework/Versions/A/App" \
  --fixture "$package_fixture" \
  --output "$output"

echo "Package ready. Facilitator launches the copied executable locally with:"
echo "  $package_app/Contents/MacOS/wuxia_idle --visual-route=phase0a_battle_playable"
echo "Do not launch it from this preparation script."
