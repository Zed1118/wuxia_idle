#!/usr/bin/env bash
set -euo pipefail

repository="$(git rev-parse --show-toplevel)"
cd "$repository"

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "macOS release verification requires Darwin" >&2
  exit 2
fi
if [[ -n "$(git status --porcelain)" ]]; then
  echo "refusing to verify a dirty worktree" >&2
  exit 3
fi

commit="$(git rev-parse HEAD)"
app="$repository/build/macos/Build/Products/Release/wuxia_idle.app"
launcher="$app/Contents/MacOS/wuxia_idle"
aot="$app/Contents/Frameworks/App.framework/Versions/A/App"

echo "==> clean macOS release build @ $commit"
flutter clean
flutter pub get
dart run build_runner build
flutter build macos --release --no-pub

[[ -x "$launcher" ]] || { echo "missing launcher: $launcher" >&2; exit 4; }
[[ -f "$aot" ]] || { echo "missing AOT payload: $aot" >&2; exit 4; }

codesign --verify --deep --strict --verbose=2 "$app"

architectures="$(lipo -archs "$launcher")"
for required_arch in x86_64 arm64; do
  if [[ " $architectures " != *" $required_arch "* ]]; then
    echo "launcher is missing architecture: $required_arch ($architectures)" >&2
    exit 5
  fi
done

launcher_sha256="$(shasum -a 256 "$launcher" | awk '{print $1}')"
aot_sha256="$(shasum -a 256 "$aot" | awk '{print $1}')"
size="$(du -sh "$app" | awk '{print $1}')"

echo "MACOS_RELEASE_VERIFY_PASS"
echo "commit=$commit"
echo "architectures=$architectures"
echo "size=$size"
echo "launcher_sha256=$launcher_sha256"
echo "aot_sha256=$aot_sha256"
