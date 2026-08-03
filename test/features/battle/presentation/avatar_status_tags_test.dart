import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/defs/skill_def.dart';
import 'package:wuxia_idle/features/battle/domain/battle_state.dart';
import 'package:wuxia_idle/features/battle/presentation/avatar_status_tags.dart';
import 'package:wuxia_idle/features/battle/presentation/character_avatar.dart';
import 'package:wuxia_idle/features/battle/presentation/countdown_ring.dart';
import 'package:wuxia_idle/shared/strings.dart';
import 'package:wuxia_idle/shared/theme/colors.dart';

/// 批次 1.4:头像旁 buff/debuff 状态标签 + hover 释义。
///
/// 纯展示层验收:据真实战斗状态字段(internalInjury / staggerTicksRemaining /
/// swordSongResonanceActive)渲染状态标签,按「生死 > 操作 > 纯数值」优先级排序,
/// 每个标签挂 GlossaryTip 释义。
BattleCharacter _char({
  InternalInjurySlot? internalInjury,
  int staggerTicksRemaining = 0,
  bool swordSongResonanceActive = false,
  SkillDef? chargingSkill,
  int chargeTicksRemaining = 0,
}) => BattleCharacter(
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
  chargingSkill: chargingSkill,
  chargeTicksRemaining: chargeTicksRemaining,
);

const _chargeSkill = SkillDef(
  id: 'charge1',
  name: '雷霆万钧',
  description: '',
  type: SkillType.ultimate,
  powerMultiplier: 5000,
  internalForceCost: 0,
  cooldownTurns: 0,
  requiresManualTrigger: false,
  visualEffect: '',
);

void main() {
  Future<void> pump(WidgetTester tester, BattleCharacter c) async {
    await tester.binding.setSurfaceSize(const Size(1280, 720));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(child: CharacterAvatar(character: c)),
        ),
      ),
    );
  }

  testWidgets('无状态时不渲染任何状态标签', (tester) async {
    await pump(tester, _char());
    expect(find.byType(AvatarStatusTags), findsOneWidget);
    expect(find.byType(AvatarStatusTag), findsNothing);
  });

  testWidgets('内伤 debuff 渲染读秒环 + 中心剩余拍数', (tester) async {
    await pump(
      tester,
      _char(
        internalInjury: const InternalInjurySlot(
          remainingTurns: 3,
          damagePerTick: 200,
        ),
      ),
    );
    expect(find.byType(SteppedCountdownRing), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(SteppedCountdownRing),
        matching: find.text('3'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('踉跄/破绽 debuff 渲染读秒环 + 中心剩余拍数', (tester) async {
    await pump(tester, _char(staggerTicksRemaining: 2));
    expect(find.byType(BeatCountdownRing), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(BeatCountdownRing),
        matching: find.text('2'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('剑鸣 buff 保留文字药丸', (tester) async {
    await pump(tester, _char(swordSongResonanceActive: true));
    expect(find.text(UiStrings.statusSwordSongLabel), findsOneWidget);
  });

  // 视觉守卫(阶段 5 终验 D 项「总色板和低饱和关系」):护法结界是 boss 专属
  // buff,干笔题签取色必须与同屏 boss 金边同源,不得复用真气语义色 internalForce
  // (SteelBlue #4682B4 属 Material 默认饱和色,挂 boss 头顶会在水墨色板外多出
  // 一块高饱和蓝;基准图同位元素是绛红/金印)。约束写成「必须 boss 专属色 +
  // 不得是真气色」两条,改回旧色即红。
  testWidgets('护法结界使用干笔题签与 boss 专属深金,不得回退规则药丸', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 720));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: AvatarStatusTags(
              character: _char(),
              beat: const AlwaysStoppedAnimation<double>(0),
              wardActive: true,
            ),
          ),
        ),
      ),
    );

    expect(find.text(UiStrings.guardianWardActiveLabel), findsOneWidget);
    expect(
      find.byKey(const ValueKey('battle.statusTag.guardianWardBrushPaper')),
      findsOneWidget,
    );
    expect(find.byType(AvatarStatusTag), findsNothing);
    final tag = tester.widget<GuardianWardBrushTag>(
      find.byType(GuardianWardBrushTag),
    );
    expect(
      tag.spec.color,
      equals(WuxiaColors.bossFrame),
      reason: 'boss 专属 buff 须与同屏 boss 金边同源',
    );
    expect(
      tag.spec.color,
      isNot(WuxiaColors.internalForce),
      reason: 'internalForce 是真气语义色,不可挪用为 boss buff 标记',
    );
  });

  testWidgets('常驻状态最多保留两个关键态并按生死 > 操作优先', (tester) async {
    await pump(
      tester,
      _char(
        internalInjury: const InternalInjurySlot(
          remainingTurns: 3,
          damagePerTick: 200,
        ),
        staggerTicksRemaining: 2,
        swordSongResonanceActive: true,
      ),
    );
    final injuryX = tester.getTopLeft(find.byType(SteppedCountdownRing)).dx;
    final staggerX = tester.getTopLeft(find.byType(BeatCountdownRing)).dx;
    // 同一水平排（Wrap）按 x 升序即视觉优先级顺序；第三优先级不再
    // 与人物信息板争抢腿部和兵器空间。
    expect(injuryX, lessThan(staggerX));
    expect(find.text(UiStrings.statusSwordSongLabel), findsNothing);
  });

  testWidgets('内伤读秒环挂 Tooltip 释义(hover/长按可触发)', (tester) async {
    await pump(
      tester,
      _char(
        internalInjury: const InternalInjurySlot(
          remainingTurns: 3,
          damagePerTick: 200,
        ),
      ),
    );
    final tip = tester.widget<Tooltip>(
      find.ancestor(
        of: find.byType(SteppedCountdownRing),
        matching: find.byType(Tooltip),
      ),
    );
    expect(tip.message, UiStrings.statusInternalInjuryGloss);
  });

  testWidgets('蓄势中渲染暗绛小印 + 中心剩余拍数', (tester) async {
    await pump(
      tester,
      _char(chargingSkill: _chargeSkill, chargeTicksRemaining: 2),
    );
    expect(find.byType(BeatCountdownRing), findsNothing);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('battle.chargeSeal.1')),
        matching: find.text('2'),
      ),
      findsOneWidget,
    );
    // 保留「可破招」金标。
    expect(find.byIcon(Icons.flash_on), findsOneWidget);
  });

  // 题签底形走宣纸色板的旧金(WuxiaUi.goldOnPaper),**刻意不接** spec.color
  // (深底色板的 WuxiaColors.bossFrame 亮金)——两套色板混用会把 2026-08-02
  // 终拍认可的旧金干笔题签变成亮金。把 spec.color 接进 painter 即红。
  testWidgets('护法结界题签渲染不随 spec.color 变', (tester) async {
    Future<Uint8List> renderWith(Color color) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: RepaintBoundary(
                key: const ValueKey('wardProbe'),
                child: SizedBox(
                  width: 120,
                  height: 40,
                  child: GuardianWardBrushTag(
                    spec: AvatarStatusSpec(
                      label: UiStrings.guardianWardActiveLabel,
                      gloss: UiStrings.guardianWardActiveGloss,
                      color: color,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final boundary = tester.renderObject<RenderRepaintBoundary>(
        find.byKey(const ValueKey('wardProbe')),
      );
      late Uint8List bytes;
      await tester.runAsync(() async {
        final image = await boundary.toImage(pixelRatio: 3);
        final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
        bytes = data!.buffer.asUint8List();
      });
      return bytes;
    }

    final asBossGold = await renderWith(WuxiaColors.bossFrame);
    final asQiBlue = await renderWith(WuxiaColors.internalForce);

    expect(asBossGold.length, greaterThan(0));
    expect(
      asQiBlue,
      orderedEquals(asBossGold),
      reason:
          '题签像素若随 spec.color 变,说明画笔接了深底色板色,'
          '会打破终拍认可的宣纸旧金观感',
    );
  });
}
