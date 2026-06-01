import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/features/battle/domain/battle_state.dart';
import 'package:wuxia_idle/features/battle/presentation/character_avatar.dart';
import 'package:wuxia_idle/shared/theme/colors.dart';

BattleCharacter _char({required bool isBoss}) => BattleCharacter(
      characterId: 1,
      name: '黑风寨主',
      realmTier: RealmTier.yiLiu,
      realmLayer: RealmLayer.qiMeng,
      school: TechniqueSchool.gangMeng,
      maxHp: 100,
      currentHp: 100,
      maxInternalForce: 100,
      currentInternalForce: 100,
      speed: 100,
      criticalRate: 0.05,
      evasionRate: 0.05,
      defenseRate: 0.1,
      totalEquipmentAttack: 100,
      mainCultivationLayer: CultivationLayer.daCheng,
      availableSkills: const [],
      skillCooldowns: const {},
      activeBuffs: const [],
      actionPoint: 0,
      isAlive: true,
      teamSide: 1,
      slotIndex: 0,
      isBoss: isBoss,
    );

Border _avatarBorder(WidgetTester tester) {
  final container = tester
      .widgetList<Container>(find.byType(Container))
      .firstWhere((c) =>
          c.decoration is BoxDecoration &&
          (c.decoration as BoxDecoration).shape == BoxShape.circle);
  return (container.decoration as BoxDecoration).border as Border;
}

void main() {
  Future<void> pump(WidgetTester tester, BattleCharacter c) async {
    await tester.binding.setSurfaceSize(const Size(400, 600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: Center(child: CharacterAvatar(character: c))),
    ));
  }

  testWidgets('普通敌人:流派色 4px 边框', (tester) async {
    await pump(tester, _char(isBoss: false));
    final b = _avatarBorder(tester);
    expect(b.top.color, WuxiaColors.gangMeng); // 刚猛流派色
    expect(b.top.width, 4.0);
  });

  testWidgets('Boss:金色 6px 边框', (tester) async {
    await pump(tester, _char(isBoss: true));
    final b = _avatarBorder(tester);
    expect(b.top.color, WuxiaColors.bossFrame);
    expect(b.top.width, 6.0);
  });
}
