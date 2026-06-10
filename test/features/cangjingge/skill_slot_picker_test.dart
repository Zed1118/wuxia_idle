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
  });
}
