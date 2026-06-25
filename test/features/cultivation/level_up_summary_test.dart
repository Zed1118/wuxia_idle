import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/features/cultivation/application/character_advancement_service.dart';
import 'package:wuxia_idle/features/cultivation/presentation/advancement_summary.dart';
import 'package:wuxia_idle/features/level/application/level_service.dart';
import 'package:wuxia_idle/shared/strings.dart';

/// 第八阶段 D·Lv 升级 victory banner widget 测。
void main() {
  AdvancementResult noAdvance() => const AdvancementResult(
        layersGained: 0,
        tierBefore: RealmTier.sanLiu,
        layerBefore: RealmLayer.qiMeng,
        tierAfter: RealmTier.sanLiu,
        layerAfter: RealmLayer.qiMeng,
        internalForceMaxBefore: 500,
        internalForceMaxAfter: 500,
      );

  Future<void> pump(WidgetTester tester, List<AdvancementEntry> entries) async {
    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: LevelUpSummary(entries: entries))),
    );
  }

  testWidgets('有角色升级 → 显「修为精进」+「晋 · 名 Lv N」', (tester) async {
    await pump(tester, [
      AdvancementEntry(
        chName: '阿牛',
        result: noAdvance(),
        levelUp: const LevelUpResult(
            levelsGained: 2, levelBefore: 3, levelAfter: 5),
      ),
    ]);
    expect(find.text(UiStrings.levelUpCeremonyTitle), findsOneWidget);
    expect(find.text('晋 · 阿牛 Lv 5'), findsOneWidget);
  });

  testWidgets('无升级(levelUp null / didLevelUp=false) → shrink 不显', (tester) async {
    await pump(tester, [
      AdvancementEntry(chName: '甲', result: noAdvance()), // levelUp null
      AdvancementEntry(
        chName: '乙',
        result: noAdvance(),
        levelUp: const LevelUpResult(
            levelsGained: 0, levelBefore: 4, levelAfter: 4),
      ),
    ]);
    expect(find.text(UiStrings.levelUpCeremonyTitle), findsNothing);
  });
}
