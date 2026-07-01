import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/defs/skill_def.dart';
import 'package:wuxia_idle/features/battle/domain/battle_state.dart';
import 'package:wuxia_idle/features/battle/presentation/character_avatar.dart';
import 'package:wuxia_idle/features/battle/presentation/countdown_ring.dart';
import 'package:wuxia_idle/shared/theme/colors.dart';

const _bossFrameKey = ValueKey<String>('battle.bossAvatarFrame');

const _chargeSkill = SkillDef(
  id: 'test_charge',
  name: '裂石掌',
  description: '',
  type: SkillType.ultimate,
  powerMultiplier: 5000,
  internalForceCost: 1000,
  cooldownTurns: 5,
  requiresManualTrigger: false,
  visualEffect: '',
);

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

Finder _avatarCoreFinder() => find.byWidgetPredicate(
  (widget) =>
      widget is Container &&
      widget.decoration is BoxDecoration &&
      (widget.decoration as BoxDecoration).shape == BoxShape.circle,
);

Border _avatarBorder(WidgetTester tester) {
  final container = tester.widget<Container>(_avatarCoreFinder().first);
  return (container.decoration as BoxDecoration).border as Border;
}

Size _avatarCoreSize(WidgetTester tester) =>
    tester.getSize(_avatarCoreFinder().first);

Size _avatarFootprintSize(WidgetTester tester) =>
    tester.getSize(find.byType(Opacity).first);

void main() {
  Future<void> pump(WidgetTester tester, BattleCharacter c) async {
    await tester.binding.setSurfaceSize(const Size(400, 600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(child: CharacterAvatar(character: c)),
        ),
      ),
    );
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

  testWidgets('普通头像布局尺寸保持默认 110（P0-2 放大·适配 720p）', (tester) async {
    await pump(tester, _char(isBoss: false));
    expect(find.byKey(_bossFrameKey), findsNothing);
    expect(_avatarCoreSize(tester), const Size(110, 110));
  });

  testWidgets('Boss 外框参与布局且头像核心保持 110', (tester) async {
    await pump(tester, _char(isBoss: true));

    const avatarSize = 110.0;
    const expectedFrameSize = avatarSize * 1.42;

    expect(_avatarCoreSize(tester), const Size(avatarSize, avatarSize));

    final frameSize = tester.getSize(find.byKey(_bossFrameKey));
    expect(frameSize.width, greaterThan(avatarSize));
    expect(frameSize.height, greaterThan(avatarSize));
    expect(frameSize.width, closeTo(expectedFrameSize, 0.01));
    expect(frameSize.height, closeTo(expectedFrameSize, 0.01));
  });

  testWidgets('死亡单位叠 grayscale ColorFiltered（P0-2）', (tester) async {
    final dead = _char(isBoss: false).copyWith(isAlive: false);
    await pump(tester, dead);
    expect(find.byType(ColorFiltered), findsWidgets);
  });

  testWidgets('存活单位不灰（无 grayscale ColorFiltered）', (tester) async {
    await pump(tester, _char(isBoss: false)); // isAlive 默认 true
    expect(find.byType(ColorFiltered), findsNothing);
  });

  testWidgets('内力条带「内 X / Y」标签与数值（批次 1.1）', (tester) async {
    // 内力 80/120，HP 100/100，避免内力与 HP 数值相同导致歧义。
    final c = _char(isBoss: false).copyWith(
      maxHp: 100,
      currentHp: 100,
      maxInternalForce: 120,
      currentInternalForce: 80,
    );
    await pump(tester, c);

    // 内力条标签：内 80 / 120
    expect(find.text('内 80 / 120'), findsOneWidget);
    // HP 条仍是裸数值，不带「内 」前缀（现状不破坏）。
    expect(find.text('100 / 100'), findsOneWidget);
  });

  testWidgets('状态环与蓄力环预留稳定高度，避免同队槽位独立缩放', (tester) async {
    await pump(tester, _char(isBoss: false));
    final plainSize = _avatarFootprintSize(tester);

    final dense = _char(isBoss: false).copyWith(
      internalInjury: const InternalInjurySlot(
        remainingTurns: 2,
        damagePerTick: 200,
      ),
      staggerTicksRemaining: 2,
      swordSongResonanceActive: true,
      chargingSkill: _chargeSkill,
      chargeTicksRemaining: 1,
    );
    await pump(tester, dense);
    final denseSize = _avatarFootprintSize(tester);

    expect(denseSize, plainSize);
    expect(find.byType(BeatCountdownRing), findsNWidgets(2));
    expect(find.byIcon(Icons.flash_on), findsOneWidget);
  });
}
