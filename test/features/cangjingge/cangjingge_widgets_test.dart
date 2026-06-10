import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/defs/skill_def.dart';
import 'package:wuxia_idle/data/numbers_config.dart';
import 'package:wuxia_idle/features/cangjingge/presentation/fragment_progress_row.dart';
import 'package:wuxia_idle/features/cangjingge/presentation/skill_proficiency_row.dart';
import 'package:wuxia_idle/shared/strings.dart';
import 'package:wuxia_idle/shared/widgets/wuxia_ui/meridian_bar.dart';

/// cangjingge 展示组件测试（P1b Task7）。
///
/// 验证 [SkillProficiencyRow] 阶段名 / 进度条 / 加成文字，以及
/// [FragmentProgressRow] 方块进度与 UiStrings 文案。
void main() {
  // 最小 5 阶配置（对应 numbers.yaml skill_proficiency.stages）
  final cfg = const SkillProficiencyConfig(stages: [
    SkillProficiencyStageConfig(id: 'chuShi', minUses: 0, damageMult: 1.00),
    SkillProficiencyStageConfig(id: 'shunShou', minUses: 30, damageMult: 1.05),
    SkillProficiencyStageConfig(id: 'shuLian', minUses: 100, damageMult: 1.12),
    SkillProficiencyStageConfig(id: 'jingTong', minUses: 300, damageMult: 1.20),
    SkillProficiencyStageConfig(id: 'huaJing', minUses: 800, damageMult: 1.30),
  ]);

  // 最简 SkillDef（name 字段是关键，其余用默认值）
  final skill = const SkillDef(
    id: 'skill_test_liezhizhang',
    name: '裂掌',
    description: '一掌裂石',
    type: SkillType.powerSkill,
    powerMultiplier: 120,
    internalForceCost: 0,
    cooldownTurns: 0,
    requiresManualTrigger: false,
    visualEffect: 'none',
  );

  Widget wrap(Widget child) => MaterialApp(
        home: Scaffold(
          body: SizedBox(width: 400, child: child),
        ),
      );

  group('SkillProficiencyRow', () {
    testWidgets('中间阶(shunShou 50 uses)→ 显示阶段名+MeridianBar+加成%',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      // 50 uses → shunShou 阶（30 ~ 99），下一阶 shuLian minUses=100
      await tester.pumpWidget(wrap(
        SkillProficiencyRow(
          skill: skill,
          uses: 50,
          cfg: cfg,
          equipped: true,
        ),
      ));

      // 阶段中文名「顺手」
      expect(find.textContaining('顺手'), findsOneWidget);
      // 进度条 widget
      expect(find.byType(MeridianBar), findsOneWidget);
      // 伤害加成：shunShou damageMult=1.05 → +5%
      expect(find.textContaining('+5'), findsOneWidget);
      // 还需次数：100 - 50 = 50
      expect(
        find.textContaining(UiStrings.cangjingProficiencyNeed(50)),
        findsOneWidget,
      );
      // 已装配标记
      expect(find.textContaining('装'), findsOneWidget);
    });

    testWidgets('最高阶(huaJing)→ 满格 MeridianBar + 不显示还需次数',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(wrap(
        SkillProficiencyRow(
          skill: skill,
          uses: 900,
          cfg: cfg,
          equipped: false,
        ),
      ));

      // 化境阶段名（至少一处显示含「化境」的文字）
      expect(find.textContaining('化境'), findsWidgets);
      expect(find.byType(MeridianBar), findsOneWidget);
      // 最高阶不显示还需次数提示（文案含「再用」）
      expect(find.textContaining('再用'), findsNothing);
      // 最高阶显示「已达化境」
      expect(find.textContaining('已达化境'), findsOneWidget);
    });

    testWidgets('初识阶(chuShi 0 uses) → +0%', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(wrap(
        SkillProficiencyRow(
          skill: skill,
          uses: 0,
          cfg: cfg,
          equipped: false,
        ),
      ));

      expect(find.textContaining('初识'), findsOneWidget);
      // 加成为 0%
      expect(find.textContaining('+0'), findsOneWidget);
    });
  });

  group('FragmentProgressRow', () {
    testWidgets('3/5 → 显示文案 + 方块', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(wrap(
        const FragmentProgressRow(name: '裂石掌谱', has: 3, total: 5),
      ));

      // UiStrings.cangjingFragmentProgress(3, 5) = '3 / 5 页'
      expect(
        find.textContaining(UiStrings.cangjingFragmentProgress(3, 5)),
        findsOneWidget,
      );
      // 秘籍名
      expect(find.textContaining('裂石掌谱'), findsOneWidget);
      // 实心 ▣ × 3
      expect(
        find.textContaining('▣'),
        findsWidgets,
      );
    });

    testWidgets('0/5 → 全空心方块', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(wrap(
        const FragmentProgressRow(name: '玄铁剑谱', has: 0, total: 5),
      ));

      expect(
        find.textContaining(UiStrings.cangjingFragmentProgress(0, 5)),
        findsOneWidget,
      );
      // 不含实心
      expect(find.textContaining('▣'), findsNothing);
      // 含空心 ▢
      expect(find.textContaining('▢'), findsWidgets);
    });

    testWidgets('5/5 全满 → 全实心', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(wrap(
        const FragmentProgressRow(name: '圣火令', has: 5, total: 5),
      ));

      // 无空心方块
      expect(find.textContaining('▢'), findsNothing);
    });
  });
}
