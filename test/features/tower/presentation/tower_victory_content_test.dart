import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/features/battle/domain/battle_stats.dart';
import 'package:wuxia_idle/features/equipment/application/drop_service.dart';
import 'package:wuxia_idle/features/tower/domain/tower_floor_def.dart';
import 'package:wuxia_idle/features/tower/presentation/tower_entry_flow.dart';
import 'package:wuxia_idle/shared/strings.dart';
import 'package:wuxia_idle/shared/theme/wuxia_tokens.dart';

/// 第七阶段批二④:爬塔 victory dialog 残页轻提示行(TowerVictoryContent seam)。
void main() {
  const floor = TowerFloorDef(
    floorIndex: 5,
    requiredRealm: RealmTier.xueTu,
    enemyTeam: [],
    bossKind: TowerBossKind.minor,
  );

  const emptyDrops = DropResult(equipments: [], items: []);

  testWidgets('skillFragmentLine 非空(重打)→ 渲染残页轻提示行', (tester) async {
    final line = UiStrings.skillFragmentGainedLine('神龙一式', 3, 5);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TowerVictoryContent(
            floor: floor,
            isFirstClear: false,
            drops: emptyDrops,
            advancements: const [],
            skillFragmentLine: line,
          ),
        ),
      ),
    );
    expect(find.text(line), findsOneWidget);
  });

  testWidgets('skillFragmentLine 非空(首通)→ 渲染残页轻提示行', (tester) async {
    final line = UiStrings.skillFragmentGainedLine('神龙一式', 2, 5);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TowerVictoryContent(
            floor: floor,
            isFirstClear: true,
            drops: emptyDrops,
            advancements: const [],
            skillFragmentLine: line,
          ),
        ),
      ),
    );
    expect(find.text(line), findsOneWidget);
  });

  testWidgets('skillFragmentLine=null → 不渲染残页行', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: TowerVictoryContent(
            floor: floor,
            isFirstClear: false,
            drops: emptyDrops,
            advancements: [],
          ),
        ),
      ),
    );
    expect(find.textContaining('得残页'), findsNothing);
  });

  testWidgets('战斗摘要在宣纸底使用浅底墨色', (tester) async {
    const stats = BattleStatsSummary(
      totalDamage: 3047,
      critCount: 0,
      totalTicks: 5,
    );
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: TowerVictoryContent(
            floor: floor,
            isFirstClear: false,
            drops: emptyDrops,
            advancements: [],
            stats: stats,
          ),
        ),
      ),
    );

    final text = tester.widget<Text>(
      find.text(UiStrings.battleSummary(3047, 0, 5)),
    );
    expect(text.style?.color, WuxiaUi.ink2);
    expect(text.style?.fontWeight, FontWeight.w600);
  });
}
