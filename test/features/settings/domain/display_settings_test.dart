import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/settings/domain/display_settings.dart';

/// L1 显示设置值对象 + 窗口尺寸预设映射。
void main() {
  group('WindowSizePreset', () {
    test('三档预设映射到正确像素尺寸', () {
      expect(WindowSizePreset.hd720.size, const Size(1280, 720));
      expect(WindowSizePreset.hd900.size, const Size(1600, 900));
      expect(WindowSizePreset.hd1080.size, const Size(1920, 1080));
    });

    test('byStorageKey 反查（持久化 round-trip 用）', () {
      expect(WindowSizePreset.byStorageKey('hd1080'), WindowSizePreset.hd1080);
      expect(WindowSizePreset.byStorageKey('unknown'), isNull);
    });
  });

  group('DisplaySettings', () {
    test('默认：窗口模式 + hd900', () {
      const s = DisplaySettings();
      expect(s.fullscreen, isFalse);
      expect(s.sizePreset, WindowSizePreset.hd900);
    });

    test('copyWith 单字段覆盖', () {
      const s = DisplaySettings();
      final f = s.copyWith(fullscreen: true);
      expect(f.fullscreen, isTrue);
      expect(f.sizePreset, s.sizePreset);
      final p = s.copyWith(sizePreset: WindowSizePreset.hd1080);
      expect(p.sizePreset, WindowSizePreset.hd1080);
      expect(p.fullscreen, s.fullscreen);
    });

    test('值相等性', () {
      expect(const DisplaySettings(), const DisplaySettings());
      expect(
        const DisplaySettings(fullscreen: true),
        isNot(const DisplaySettings()),
      );
      expect(
        const DisplaySettings(sizePreset: WindowSizePreset.hd1080),
        isNot(const DisplaySettings()),
      );
    });
  });
}
