import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/ascension/domain/ascension_models.dart';

void main() {
  group('AscensionEligibility.missingReasons 不泄漏原始 stage id', () {
    test('全条件未满足时,无任何 reason 含 stage_ 原始 id', () {
      const eligibility = AscensionEligibility(
        inActiveCharacters: false,
        realmAtPeak: false,
        innerDemon07Cleared: false,
        mainline0605Cleared: false,
        hasDiscipleTarget: false,
      );

      final reasons = eligibility.missingReasons;
      expect(reasons, isNotEmpty);
      for (final reason in reasons) {
        expect(
          reason.contains('stage_'),
          isFalse,
          reason: 'reason 泄漏原始 stage id(违 CLAUDE.md §5.6): "$reason"',
        );
      }
    });

    test('仅心魔/主线未通时,两条对应 reason 均无 stage_ 泄漏', () {
      const eligibility = AscensionEligibility(
        inActiveCharacters: true,
        realmAtPeak: true,
        innerDemon07Cleared: false,
        mainline0605Cleared: false,
        hasDiscipleTarget: true,
      );

      final reasons = eligibility.missingReasons;
      expect(reasons.length, 2);
      expect(reasons.any((r) => r.contains('stage_')), isFalse);
    });
  });
}
