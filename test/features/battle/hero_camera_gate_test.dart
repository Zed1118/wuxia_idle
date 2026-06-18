import 'package:flutter_test/flutter_test.dart';

import 'package:wuxia_idle/features/battle/presentation/hero_camera_overlay.dart';
import 'package:wuxia_idle/features/battle/presentation/victory_ceremony.dart';

void main() {
  final sampleData = const HeroCameraData(
    portraitPath: null,
    heroName: '无名侠客',
    realmLabel: '三流',
    bossName: '山贼头子',
    topDamage: 12345,
  );

  group('shouldShowHeroCamera gate', () {
    test('Boss 首胜 + 有数据 → true', () {
      expect(
        shouldShowHeroCamera(
          isBoss: true,
          isFirstClear: true,
          data: sampleData,
        ),
        isTrue,
      );
    });

    test('非 Boss → false', () {
      expect(
        shouldShowHeroCamera(
          isBoss: false,
          isFirstClear: true,
          data: sampleData,
        ),
        isFalse,
      );
    });

    test('非首胜 → false', () {
      expect(
        shouldShowHeroCamera(
          isBoss: true,
          isFirstClear: false,
          data: sampleData,
        ),
        isFalse,
      );
    });

    test('data == null → false', () {
      expect(
        shouldShowHeroCamera(
          isBoss: true,
          isFirstClear: true,
          data: null,
        ),
        isFalse,
      );
    });
  });
}
