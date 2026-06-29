import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/defs/drop_entry.dart';
import 'package:wuxia_idle/data/defs/stage_def.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/loot_preview/domain/drop_rumor.dart';
import 'package:wuxia_idle/features/loot_preview/presentation/stage_intel_dialog.dart';
import 'package:wuxia_idle/shared/strings.dart';

void main() {
  setUpAll(() async {
    if (!GameRepository.isLoaded) {
      await GameRepository.loadAllDefs(
        loader: (path) => File(path).readAsString(),
      );
    }
  });

  StageDef stage({bool boss = false, List<EnemyDef>? enemies}) {
    return StageDef(
      id: 'stage_test',
      name: '试剑坡',
      stageType: StageType.mainline,
      chapterIndex: 1,
      requiredRealm: RealmTier.sanLiu,
      enemyTeam:
          enemies ??
          [
            const EnemyDef(
              id: 'bandit_a',
              name: '山道悍匪',
              realmTier: RealmTier.sanLiu,
              realmLayer: RealmLayer.ruMen,
              school: TechniqueSchool.gangMeng,
              baseHp: 1200,
              baseAttack: 180,
              baseSpeed: 110,
              skillIds: ['skill_normal'],
              iconPath: '',
            ),
          ],
      isBossStage: boss,
      dropTable: const [
        EquipmentDrop(
          equipmentDefId: 'weapon_xunchang_tie_jian',
          dropChance: 0.3,
        ),
        ItemDrop(
          inventoryItemDefId: 'item_mojianshi',
          quantityMin: 1,
          quantityMax: 2,
          dropChance: 1.0,
        ),
      ],
      baseExpReward: 100,
      difficultyMultiplier: 1,
    );
  }

  Future<void> pumpIntel(
    WidgetTester tester,
    StageDef stage, {
    RealmTier currentRealm = RealmTier.xueTu,
    int targetCycle = 1,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StageIntelContent(
            stage: stage,
            currentRealm: currentRealm,
            targetCycle: targetCycle,
            rumorTable: DropRumorTable.fromDropTable(
              stage.dropTable,
              gating: FirstClearGating.scrollOnly,
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('战前情报显敌阵/应对/风险/掉落，去整备难度冗余', (tester) async {
    await pumpIntel(tester, stage());

    expect(find.text(UiStrings.prebattleIntelEnemySection), findsOneWidget);
    expect(find.textContaining('山道悍匪'), findsOneWidget);
    expect(find.text(UiStrings.prebattleIntelResponseSection), findsOneWidget);
    expect(find.textContaining('可备克制路数'), findsOneWidget);
    expect(find.text(UiStrings.prebattleRiskNone), findsOneWidget);
    expect(find.text(UiStrings.prebattleIntelLootSection), findsOneWidget);
    expect(find.text(UiStrings.lootBucketChangKeDe), findsOneWidget);
    expect(find.text(UiStrings.prebattleIntelCycleTraitSection), findsNothing);
    expect(find.textContaining('推荐：'), findsNothing);
    expect(find.textContaining('境界低于推荐'), findsNothing);
  });

  testWidgets('首领蓄力三人阵给应对与风险提示', (tester) async {
    await pumpIntel(
      tester,
      stage(
        boss: true,
        enemies: const [
          EnemyDef(
            id: 'm1',
            name: '黑风喽啰',
            realmTier: RealmTier.sanLiu,
            realmLayer: RealmLayer.qiMeng,
            school: TechniqueSchool.lingQiao,
            baseHp: 1000,
            baseAttack: 120,
            baseSpeed: 130,
            skillIds: ['skill_normal'],
            iconPath: '',
          ),
          EnemyDef(
            id: 'm2',
            name: '黑风刀客',
            realmTier: RealmTier.sanLiu,
            realmLayer: RealmLayer.ruMen,
            school: TechniqueSchool.lingQiao,
            baseHp: 1100,
            baseAttack: 140,
            baseSpeed: 130,
            skillIds: ['skill_normal'],
            iconPath: '',
          ),
          EnemyDef(
            id: 'boss',
            name: '黑风寨主',
            realmTier: RealmTier.sanLiu,
            realmLayer: RealmLayer.shuLian,
            school: TechniqueSchool.lingQiao,
            baseHp: 2200,
            baseAttack: 220,
            baseSpeed: 130,
            skillIds: ['skill_normal', 'skill_charge'],
            iconPath: '',
            isBoss: true,
            chargeSkillId: 'skill_charge',
          ),
        ],
      ),
    );

    expect(find.textContaining('黑风寨主'), findsOneWidget);
    expect(
      find.textContaining(
        '${UiStrings.prebattleIntelBossTag} / ${UiStrings.prebattleIntelChargeTag}',
      ),
      findsOneWidget,
    );
    expect(find.text(UiStrings.prebattlePrepGroup), findsOneWidget);
    expect(find.text(UiStrings.prebattlePrepCharge), findsOneWidget);
    expect(find.text(UiStrings.prebattleRiskBoss), findsOneWidget);
    expect(find.text(UiStrings.prebattleRiskCharge), findsOneWidget);
    expect(find.text(UiStrings.prebattleRiskOutnumbered), findsOneWidget);
  });

  testWidgets('二周目战前情报解释周目词条', (tester) async {
    await pumpIntel(tester, stage(), targetCycle: 2);

    expect(
      find.text(UiStrings.prebattleIntelCycleTraitSection),
      findsOneWidget,
    );
    expect(find.textContaining('御体'), findsOneWidget);
    expect(find.textContaining('真气'), findsOneWidget);
    expect(find.textContaining('多放一次大招'), findsOneWidget);
  });
}
