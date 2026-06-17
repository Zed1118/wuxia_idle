import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/features/battle/domain/battle_state.dart';
import 'package:wuxia_idle/features/battle/presentation/avatar_status_tags.dart';
import 'package:wuxia_idle/features/battle/presentation/character_avatar.dart';
import 'package:wuxia_idle/shared/strings.dart';

/// 批次 1.4:头像旁 buff/debuff 状态标签 + hover 释义。
///
/// 纯展示层验收:据真实战斗状态字段(internalInjury / staggerTicksRemaining /
/// swordSongResonanceActive)渲染状态标签,按「生死 > 操作 > 纯数值」优先级排序,
/// 每个标签挂 GlossaryTip 释义。
BattleCharacter _char({
  InternalInjurySlot? internalInjury,
  int staggerTicksRemaining = 0,
  bool swordSongResonanceActive = false,
}) =>
    BattleCharacter(
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
      internalInjury: internalInjury,
      staggerTicksRemaining: staggerTicksRemaining,
      swordSongResonanceActive: swordSongResonanceActive,
    );

void main() {
  Future<void> pump(WidgetTester tester, BattleCharacter c) async {
    await tester.binding.setSurfaceSize(const Size(1280, 720));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: Center(child: CharacterAvatar(character: c))),
    ));
  }

  testWidgets('无状态时不渲染任何状态标签', (tester) async {
    await pump(tester, _char());
    expect(find.byType(AvatarStatusTags), findsOneWidget);
    expect(find.byType(AvatarStatusTag), findsNothing);
  });

  testWidgets('内伤 debuff 渲染「内伤」标签', (tester) async {
    await pump(
      tester,
      _char(
        internalInjury:
            const InternalInjurySlot(remainingTurns: 3, damagePerTick: 200),
      ),
    );
    expect(find.text(UiStrings.statusInternalInjuryLabel), findsOneWidget);
  });

  testWidgets('踉跄 debuff 渲染「踉跄」标签', (tester) async {
    await pump(tester, _char(staggerTicksRemaining: 2));
    expect(find.text(UiStrings.statusStaggerLabel), findsOneWidget);
  });

  testWidgets('剑鸣 buff 渲染「剑鸣」标签', (tester) async {
    await pump(tester, _char(swordSongResonanceActive: true));
    expect(find.text(UiStrings.statusSwordSongLabel), findsOneWidget);
  });

  testWidgets('多状态按优先级排序:生死(内伤) > 操作(踉跄) > 纯数值(剑鸣)',
      (tester) async {
    await pump(
      tester,
      _char(
        internalInjury:
            const InternalInjurySlot(remainingTurns: 3, damagePerTick: 200),
        staggerTicksRemaining: 2,
        swordSongResonanceActive: true,
      ),
    );
    final injuryY = tester
        .getTopLeft(find.text(UiStrings.statusInternalInjuryLabel))
        .dx;
    final staggerY =
        tester.getTopLeft(find.text(UiStrings.statusStaggerLabel)).dx;
    final swordX =
        tester.getTopLeft(find.text(UiStrings.statusSwordSongLabel)).dx;
    // 同一水平排（Wrap）按 x 升序即视觉优先级顺序。
    expect(injuryY, lessThan(staggerY));
    expect(staggerY, lessThan(swordX));
  });

  testWidgets('状态标签挂 Tooltip 释义(hover/长按可触发)', (tester) async {
    await pump(
      tester,
      _char(
        internalInjury:
            const InternalInjurySlot(remainingTurns: 3, damagePerTick: 200),
      ),
    );
    final tip = tester.widget<Tooltip>(
      find.ancestor(
        of: find.text(UiStrings.statusInternalInjuryLabel),
        matching: find.byType(Tooltip),
      ),
    );
    expect(tip.message, UiStrings.statusInternalInjuryGloss);
  });
}
