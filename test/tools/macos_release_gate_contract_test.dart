import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('macOS release 门禁强制 clean build、deep 验签与双架构', () {
    final source = File('tool/verify_macos_release.sh').readAsStringSync();

    expect(source, contains('git status --porcelain'));
    expect(source, contains('flutter clean'));
    expect(source, contains('flutter pub get'));
    expect(source, contains('dart run build_runner build'));
    expect(source, contains('flutter build macos --release --no-pub'));
    expect(source, contains('codesign --verify --deep --strict'));
    expect(source, contains('lipo -archs'));
    expect(source, contains('x86_64 arm64'));
    expect(source, contains('shasum -a 256'));
    expect(source, contains('MACOS_RELEASE_VERIFY_PASS'));
  });
}
