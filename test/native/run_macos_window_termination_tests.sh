#!/usr/bin/env bash
set -euo pipefail

# Run after the existing CI macOS build. A second argument can point at an
# already built set of the same locked native dependencies during local work.
# Compile actual app sources into an importable dylib; its @main is NOT called.
repository_root="$(cd "$(dirname "$0")/../.." && pwd)"
products_dir="${2:-$repository_root/build/macos/Build/Products/Debug}"
output_dir="${1:-$(mktemp -d "${TMPDIR:-/tmp}/wuxia-native-exit-tests.XXXXXX")}"
mkdir -p "$output_dir"
test ! -e "$output_dir/libWuxiaNativeExitUnderTest.dylib"
test ! -e "$output_dir/macos_window_termination_tests"

developer_dir="$(xcode-select -p)"
frameworks="$developer_dir/Platforms/MacOSX.platform/Developer/Library/Frameworks"
private_frameworks="$developer_dir/Platforms/MacOSX.platform/Developer/Library/PrivateFrameworks"
swift_support="$developer_dir/Platforms/MacOSX.platform/Developer/usr/lib"
native_frameworks=(FlutterMacOS audioplayers_darwin isar_community_flutter_libs screen_retriever_macos shared_preferences_foundation window_manager)
flags=(-swift-version 5 -warnings-as-errors -F "$frameworks" -I "$swift_support" -L "$swift_support"
  -Xlinker -rpath -Xlinker "$frameworks"
  -Xlinker -rpath -Xlinker "$private_frameworks"
  -Xlinker -rpath -Xlinker "$swift_support")
framework_binaries=()
for name in "${native_frameworks[@]}"; do
  directory="$products_dir/$name"
  if [[ "$name" == FlutterMacOS ]]; then directory="$products_dir"; fi
  test -d "$directory/$name.framework"
  flags+=(-F "$directory" -framework "$name" -Xlinker -rpath -Xlinker "$directory")
  framework_binaries+=("$directory/$name.framework/$name")
done
# The generated registrant links the real Isar plugin even though tests never
# register plugins or open Isar. Resolve its native library from the built app.
bundled_libraries="$products_dir/wuxia_idle.app/Contents/Frameworks"
test -f "$bundled_libraries/libisar.dylib"
flags+=(-Xlinker -rpath -Xlinker "$bundled_libraries")
framework_binaries+=("$bundled_libraries/libisar.dylib")
sources=(
  "$repository_root/macos/Runner/AppDelegate.swift"
  "$repository_root/macos/Runner/MainFlutterWindow.swift"
  "$repository_root/macos/Runner/MacosSfxPool.swift"
  "$repository_root/macos/Flutter/GeneratedPluginRegistrant.swift"
)
shasum -a 256 "${sources[@]}" "${framework_binaries[@]}" \
  "$repository_root/pubspec.lock" \
  "$repository_root/test/native/macos_window_termination_tests.swift" \
  "$repository_root/test/native/run_macos_window_termination_tests.sh" > "$output_dir/input-sha256.txt"

xcrun swiftc "${flags[@]}" -parse-as-library -emit-library -emit-module -enable-testing \
  -module-name WuxiaNativeExitUnderTest \
  -emit-module-path "$output_dir/WuxiaNativeExitUnderTest.swiftmodule" \
  -Xlinker -install_name -Xlinker '@rpath/libWuxiaNativeExitUnderTest.dylib' \
  "${sources[@]}" -o "$output_dir/libWuxiaNativeExitUnderTest.dylib"
xcrun swiftc "${flags[@]}" -parse-as-library -I "$output_dir" -L "$output_dir" \
  -lWuxiaNativeExitUnderTest -Xlinker -rpath -Xlinker "$output_dir" \
  "$repository_root/test/native/macos_window_termination_tests.swift" \
  -o "$output_dir/macos_window_termination_tests"
"$output_dir/macos_window_termination_tests"
shasum -a 256 -c "$output_dir/input-sha256.txt" > "$output_dir/input-verified.txt"
