#!/usr/bin/env bash
set -euo pipefail

# Compile the actual shipping pool together with controlled-player XCTest cases.
# No Flutter build, application launch, audio device or player save is involved.
repository_root="$(cd "$(dirname "$0")/../.." && pwd)"
developer_dir="$(xcode-select -p)"
frameworks="$developer_dir/Platforms/MacOSX.platform/Developer/Library/Frameworks"
private_frameworks="$developer_dir/Platforms/MacOSX.platform/Developer/Library/PrivateFrameworks"
swift_support="$developer_dir/Platforms/MacOSX.platform/Developer/usr/lib"
output_dir="${1:-$(mktemp -d "${TMPDIR:-/tmp}/wuxia-native-sfx-tests.XXXXXX")}"
mkdir -p "$output_dir"

xcrun swiftc -swift-version 5 -warnings-as-errors \
  -F "$frameworks" -I "$swift_support" -L "$swift_support" \
  -Xlinker -rpath -Xlinker "$frameworks" \
  -Xlinker -rpath -Xlinker "$private_frameworks" \
  -Xlinker -rpath -Xlinker "$swift_support" \
  "$repository_root/macos/Runner/MacosSfxPool.swift" \
  "$repository_root/test/native/macos_sfx_pool_tests.swift" \
  -o "$output_dir/macos_sfx_pool_tests"
"$output_dir/macos_sfx_pool_tests"
