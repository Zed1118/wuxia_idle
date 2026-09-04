#!/usr/bin/env bash
set -euo pipefail

repository="$(git rev-parse --show-toplevel)"
candidate="${1:-HEAD}"
commit="$(git -C "$repository" rev-parse "$candidate^{commit}")"
short_commit="${commit:0:12}"
output="${2:-$repository/build/phase2_human_acceptance/$short_commit}"

if [[ -n "$(git -C "$repository" status --porcelain)" ]]; then
  echo "refusing to package a dirty worktree" >&2
  exit 1
fi
if [[ "$(git -C "$repository" rev-parse HEAD)" != "$commit" ]]; then
  echo "candidate must be the checked-out HEAD" >&2
  exit 1
fi
if [[ -e "$output" ]]; then
  echo "refusing to replace an existing package: $output" >&2
  exit 1
fi

cd "$repository"
flutter build macos --profile --no-pub

source_app="$repository/build/macos/Build/Products/Profile/wuxia_idle.app"
if [[ ! -d "$source_app" ]]; then
  echo "profile app was not produced: $source_app" >&2
  exit 1
fi

package_dir="$output/package"
package_app="$package_dir/wuxia_idle.app"
package_fixture="$package_dir/phase0a_debug_battle.yaml"
package_archive="$output/wuxia_idle-macos-profile-$short_commit.zip"
mkdir -p "$package_dir"
ditto "$source_app" "$package_app"
cp "$repository/data/phase0a_debug_battle.yaml" "$package_fixture"
ditto -c -k --sequesterRsrc --keepParent "$package_dir" "$package_archive"

dart run tool/phase2_human_acceptance_package.dart \
  --candidate "$commit" \
  --app "$package_app/Contents/Frameworks/App.framework/Versions/A/App" \
  --fixture "$package_fixture" \
  --archive "$package_archive" \
  --template "$repository/docs/dispatch/phase2_consolidated_human_acceptance_template.md" \
  --output "$output"

echo "Package ready: $output"
echo "Formal rows must be executed from the copied wuxia_idle.app production root entry."
echo "The copied fixture and --visual-route screens are supplemental evidence only."
echo "This preparation script never launches the GUI and never records a PASS."
