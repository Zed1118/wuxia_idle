import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/defs/skill_def.dart';
import 'package:wuxia_idle/features/cangjingge/presentation/skill_slot_picker.dart';
import 'package:wuxia_idle/shared/strings.dart';

/// 换招 bottom sheet picker 测试（P1b Task8）。
///
/// 验证：
/// 1. 两候选招式都在列表中显示；
/// 2. 高 tier 锁招显示 [UiStrings.cangjingTierLocked]，点击无返回；
/// 3. 达境界招式可点击，sheet pop 并返回对应 [SkillDef]。
void main() {
  // 低境界招（tier=1，xueTu 即可装配）
  const skillUnlocked = SkillDef(
    id: 'skill_liezhizhang',
    name: '裂掌',
    description: '一掌裂石',
    type: SkillType.powerSkill,
    powerMultiplier: 120,
    internalForceCost: 0,
    cooldownTurns: 0,
    requiresManualTrigger: false,
    visualEffect: 'none',
    tier: 1,
  );

  // 高 tier 锁招（tier=7，xueTu 境界无法装配）
  const skillLocked = SkillDef(
    id: 'skill_tianwai',
    name: '天外飞仙',
    description: '绝顶一击',
    type: SkillType.powerSkill,
    powerMultiplier: 300,
    internalForceCost: 80,
    cooldownTurns: 5,
    requiresManualTrigger: false,
    visualEffect: 'none',
    tier: 7,
  );

  // 可破招（canInterrupt=true，tier=1 xueTu 可装配）
  const skillInterrupt = SkillDef(
    id: 'skill_poshi',
    name: '破势',
    description: '破敌蓄力',
    type: SkillType.powerSkill,
    powerMultiplier: 200,
    internalForceCost: 30,
    cooldownTurns: 3,
    requiresManualTrigger: false,
    visualEffect: 'none',
    tier: 1,
    canInterrupt: true,
  );

  // 破防技（defenseBreakPct>0，tier=1 xueTu 可装配）
  const skillDefenseBreak = SkillDef(
    id: 'skill_pojia',
    name: '破甲掌',
    description: '撕开护甲破绽',
    type: SkillType.powerSkill,
    powerMultiplier: 180,
    internalForceCost: 20,
    cooldownTurns: 4,
    requiresManualTrigger: false,
    visualEffect: 'none',
    tier: 1,
    defenseBreakPct: 0.5,
  );

  // 用 xueTu（index=0）让 tier-7 招锁死（需 index >= 6）
  const lowRealm = RealmTier.xueTu;

  Widget wrapWithTrigger(void Function(BuildContext) open) {
    return MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (ctx) => ElevatedButton(
            onPressed: () => open(ctx),
            child: const Text('open'),
          ),
        ),
      ),
    );
  }

  group('openSkillSlotPicker', () {
    testWidgets('两候选招式都在列表中显示', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        wrapWithTrigger((ctx) => openSkillSlotPicker(
              ctx,
              candidates: [skillUnlocked, skillLocked],
              currentRealmTier: lowRealm,
              equippedId: null,
            )),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.text(skillUnlocked.name), findsOneWidget);
      expect(find.text(skillLocked.name), findsOneWidget);
    });

    testWidgets('高 tier 锁招显示境界不足文案', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        wrapWithTrigger((ctx) => openSkillSlotPicker(
              ctx,
              candidates: [skillUnlocked, skillLocked],
              currentRealmTier: lowRealm,
              equippedId: null,
            )),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(
        find.textContaining(UiStrings.cangjingTierLocked),
        findsOneWidget,
      );
    });

    testWidgets('点高 tier 锁招 → sheet 不关闭（无返回值）', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      SkillDef? result;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () async {
                  result = await openSkillSlotPicker(
                    ctx,
                    candidates: [skillUnlocked, skillLocked],
                    currentRealmTier: lowRealm,
                    equippedId: null,
                  );
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      // 点锁招 → 应 disabled，sheet 仍在
      await tester.tap(find.text(skillLocked.name));
      await tester.pumpAndSettle();

      // sheet 仍显示（未 pop）
      expect(find.text(skillLocked.name), findsOneWidget);
      expect(result, isNull);
    });

    testWidgets('点达境界招 → sheet pop 返回该 SkillDef', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      SkillDef? result;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () async {
                  result = await openSkillSlotPicker(
                    ctx,
                    candidates: [skillUnlocked, skillLocked],
                    currentRealmTier: lowRealm,
                    equippedId: null,
                  );
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text(skillUnlocked.name));
      await tester.pumpAndSettle();

      expect(result, equals(skillUnlocked));
    });

    testWidgets('已装配招式高亮显示装配标记', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        wrapWithTrigger((ctx) => openSkillSlotPicker(
              ctx,
              candidates: [skillUnlocked, skillLocked],
              currentRealmTier: lowRealm,
              equippedId: skillUnlocked.id,
            )),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(
        find.textContaining(UiStrings.cangjingEquippedTag),
        findsOneWidget,
      );
    });

    testWidgets('subtitle 不出现 tier/倍率 开发味文案', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        wrapWithTrigger((ctx) => openSkillSlotPicker(
              ctx,
              candidates: [skillUnlocked, skillLocked],
              currentRealmTier: lowRealm,
              equippedId: null,
            )),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.textContaining('tier'), findsNothing);
      expect(find.textContaining('倍率'), findsNothing);
    });

    testWidgets('subtitle 显示阶位中文 + 伤害 + 可破招标', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        wrapWithTrigger((ctx) => openSkillSlotPicker(
              ctx,
              candidates: [skillInterrupt],
              currentRealmTier: lowRealm,
              equippedId: null,
            )),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      // tier=1 → 心法阶「入门功」
      expect(find.textContaining('入门功'), findsOneWidget);
      // 倍率改为玩家化「伤害 N」
      expect(find.textContaining('伤害'), findsOneWidget);
      // canInterrupt 招带「可破招」标
      expect(
        find.textContaining(UiStrings.cangjingPickerCanInterrupt),
        findsOneWidget,
      );
    });

    testWidgets('破防技 subtitle 显示「破防」特性标（与 canInterrupt 模式一致）',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        wrapWithTrigger((ctx) => openSkillSlotPicker(
              ctx,
              candidates: [skillDefenseBreak],
              currentRealmTier: lowRealm,
              equippedId: null,
            )),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      // defenseBreakPct>0 → subtitle 应包含 UiStrings.skillTraitDefenseBreak
      expect(
        find.textContaining(UiStrings.skillTraitDefenseBreak),
        findsOneWidget,
      );
    });

    testWidgets('普通技（defenseBreakPct==0）不显示「破防」标', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        wrapWithTrigger((ctx) => openSkillSlotPicker(
              ctx,
              candidates: [skillUnlocked],
              currentRealmTier: lowRealm,
              equippedId: null,
            )),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(
        find.textContaining(UiStrings.skillTraitDefenseBreak),
        findsNothing,
      );
    });
  });
}
