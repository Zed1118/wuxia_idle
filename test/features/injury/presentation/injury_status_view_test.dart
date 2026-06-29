import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/attributes.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/features/injury/presentation/injury_status_view.dart';
import 'package:wuxia_idle/shared/strings.dart';

void main() {
  Character character({
    double injuryHours = 0,
    int lightStacks = 0,
    double residueHours = 0,
  }) {
    final c = Character.create(
      name: '沈青',
      realmTier: RealmTier.xueTu,
      realmLayer: RealmLayer.qiMeng,
      attributes: Attributes()
        ..constitution = 5
        ..enlightenment = 5
        ..agility = 5
        ..fortune = 5,
      rarity: RarityTier.biaoZhun,
      lineageRole: LineageRole.founder,
      createdAt: DateTime(2026, 6, 29),
      internalForce: 100,
      internalForceMax: 500,
    );
    c.injuryHoursRemaining = injuryHours;
    c.lightInjuryStacks = lightStacks;
    c.innerDemonResidueHoursRemaining = residueHours;
    return c;
  }

  test('无伤返回明确可出战状态', () {
    expect(
      InjuryStatusFormatter.primaryStatus(character()),
      UiStrings.injuryStatusHealthy,
    );
  });

  test('重伤和轻伤合并为同一状态句', () {
    final c = character(injuryHours: 3.2, lightStacks: 2);

    expect(InjuryStatusFormatter.hasInjury(c), isTrue);
    expect(
      InjuryStatusFormatter.primaryStatus(c),
      contains(
        UiStrings.injuryStatusHeavy(
          hours: 3.2,
          attackPenaltyPct: 15,
          internalForcePenaltyPct: 15,
        ),
      ),
    );
    expect(
      InjuryStatusFormatter.primaryStatus(c),
      contains(UiStrings.injuryStatusLight(2, 6)),
    );
  });

  test('仅心魔余毒时不误报无伤', () {
    final c = character(residueHours: 5);

    expect(
      InjuryStatusFormatter.primaryStatus(c),
      contains(UiStrings.conditionInnerDemonResidueLabel),
    );
    expect(
      InjuryStatusFormatter.primaryStatus(c),
      isNot(UiStrings.injuryStatusHealthy),
    );
  });
}
