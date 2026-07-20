import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/save_data.dart';
import 'package:wuxia_idle/data/defs/stage_def.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/features/battle/application/battle_providers.dart';
import 'package:wuxia_idle/features/debug/application/phase2_seed_service.dart';
import 'package:wuxia_idle/features/sweep/application/sweep_unit.dart';
import 'package:wuxia_idle/data/defs/tower_floor_def.dart';
import 'package:wuxia_idle/shared/audio/audio_assets.dart';
import 'package:wuxia_idle/shared/strings.dart';

import '../../../support/isar_test_support.dart';
import '../../../support/test_data.dart';

void main() {
  test('主线扫荡单位透传关卡展示信息并按 Boss 路由 BGM', () {
    final normal = MainlineSweepUnit(stage: _normalStage, cycle: 2);
    final boss = MainlineSweepUnit(stage: _bossStage, cycle: 3);

    expect(normal.label, _normalStage.name);
    expect(normal.battleHint, _normalStage.name);
    expect(normal.sceneBackgroundPath, _normalStage.sceneBackgroundPath);
    expect(normal.bgmTrack, BgmTrack.mainline);
    expect(normal.cycle, 2);

    expect(boss.bgmTrack, BgmTrack.boss);
    expect(boss.cycle, 3);
  });

  test('爬塔扫荡单位使用层号、塔背景和塔 BGM', () {
    final unit = TowerSweepUnit(floor: _floor, cycleIndex: 4);

    expect(unit.label, UiStrings.towerFloorLabel(_floor.floorIndex));
    expect(unit.battleHint, UiStrings.towerFloorLabel(_floor.floorIndex));
    expect(unit.sceneBackgroundPath, _floor.sceneBackgroundPath);
    expect(unit.bgmTrack, BgmTrack.tower);
    expect(unit.cycleIndex, 4);
  });

  // ── startBattle / settle 行为测(2026-07-19 夜批 coverage 补强,文件基线
  // 17/31):真 Isar + 真 StageBattleSetup + 真 battleProvider,钉装配起手与
  // 结算委托两段生产路径。全部 Isar 交互收 tester.runAsync。 ──────────────
  group('startBattle/settle(真 Isar)', () {
    late Directory tempDir;

    setUpAll(() async {
      await initializeTestIsarCore();
      if (!GameRepository.isLoaded) {
        await loadTestGameRepository();
      }
    });

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('wuxia_sweep_unit_');
      await IsarSetup.init(directory: tempDir, inspector: false);
    });

    tearDown(() async {
      await IsarSetup.close();
      IsarSetup.resetForTest();
      if (await tempDir.exists()) await tempDir.delete(recursive: true);
    });

    /// 泵最小宿主捕获 WidgetRef(runAsync 区内执行 body)。
    /// **每测试只泵一次**:重泵 = 新 ProviderScope 容器,battleProvider 等
    /// 容器内状态全丢(本文件 startBattle 测曾因此读到空队)。
    Future<WidgetRef> pumpRef(WidgetTester tester) async {
      WidgetRef? captured;
      await tester.pumpWidget(
        ProviderScope(child: _RefHarness(onReady: (ref) => captured = ref)),
      );
      return captured!;
    }

    testWidgets('主线单位 startBattle:装配 seed 队伍起手写入 battleProvider', (
      tester,
    ) async {
      await tester.runAsync(
        () => Phase2SeedService(isar: IsarSetup.instance).seedP3(),
      );
      final stage = GameRepository.instance.getStage('stage_01_01');
      final unit = MainlineSweepUnit(stage: stage, cycle: 1);
      final ref = await pumpRef(tester);

      await tester.runAsync(() => unit.startBattle(ref));

      final state = (await tester.runAsync(
        () async => ref.read(battleProvider),
      ))!;
      expect(state.isFinished, isFalse, reason: '刚起手,战斗未终态');
      final chars = (await tester.runAsync(
        () async => IsarSetup.instance.characters.where().findAll(),
      ))!;
      expect(
        state.leftTeam.map((c) => c.characterId).toSet(),
        chars.map((c) => c.id).toSet(),
        reason: 'P3 种子无 active ids → 兜底装配库中唯一角色,不漏不增',
      );
      expect(
        state.rightTeam.length,
        stage.enemyTeam.length,
        reason: '右队逐一出装 stage.enemyTeam,不漏不增',
      );
    });

    testWidgets('爬塔单位 startBattle:buildTeamsForTower 装配起手', (tester) async {
      await tester.runAsync(
        () => Phase2SeedService(isar: IsarSetup.instance).seedP3(),
      );
      final floor = GameRepository.instance.towerFloors.first;
      final unit = TowerSweepUnit(floor: floor, cycleIndex: 1);
      final ref = await pumpRef(tester);

      await tester.runAsync(() => unit.startBattle(ref));

      final state = (await tester.runAsync(
        () async => ref.read(battleProvider),
      ))!;
      expect(state.isFinished, isFalse);
      final chars = (await tester.runAsync(
        () async => IsarSetup.instance.characters.where().findAll(),
      ))!;
      expect(
        state.leftTeam.map((c) => c.characterId).toSet(),
        chars.map((c) => c.id).toSet(),
        reason: 'P3 种子无 active ids → 兜底装配库中唯一角色,不漏不增',
      );
      expect(
        state.rightTeam.length,
        floor.enemyTeam.length,
        reason: '右队逐一出装 floor.enemyTeam,不漏不增',
      );
    });

    testWidgets('主线单位 settle 委托:战备不足走忽略项分支', (tester) async {
      await tester.runAsync(() async {
        final save = await IsarSetup.currentSaveData();
        await IsarSetup.instance.writeTxn(() async {
          save!
            ..sweepReadinessPoints = 0
            ..sweepReadinessLastRecoveredAt = DateTime.now();
          await IsarSetup.instance.saveDatas.put(save);
        });
      });
      final stage = GameRepository.instance.getStage('stage_01_01');
      final unit = MainlineSweepUnit(stage: stage, cycle: 1);
      final ref = await pumpRef(tester);

      final outcome = await tester.runAsync(() => unit.settle(ref));

      expect(outcome, isNotNull);
      expect(outcome!.ignoredDrops, 1, reason: '委托 settleMainlineSweepVictory');
    });

    testWidgets('爬塔单位 settle 委托:重打发空账', (tester) async {
      final floor = GameRepository.instance.towerFloors.first;
      final unit = TowerSweepUnit(floor: floor, cycleIndex: 1);
      final ref = await pumpRef(tester);

      final outcome = await tester.runAsync(() => unit.settle(ref));

      expect(outcome, isNotNull);
      expect(outcome!.expGained, 0, reason: '委托 settleTowerSweepVictory');
      expect(outcome.equipmentDrops, 0);
    });
  });
}

class _RefHarness extends ConsumerWidget {
  const _RefHarness({required this.onReady});

  final ValueChanged<WidgetRef> onReady;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    onReady(ref);
    return const SizedBox.shrink();
  }
}

const _normalStage = StageDef(
  id: 'stage_sweep_normal',
  name: 'normal stage',
  stageType: StageType.mainline,
  requiredRealm: RealmTier.xueTu,
  enemyTeam: [],
  isBossStage: false,
  baseExpReward: 0,
  difficultyMultiplier: 1,
  sceneBackgroundPath: 'assets/scenes/test.png',
);

const _bossStage = StageDef(
  id: 'stage_sweep_boss',
  name: 'boss stage',
  stageType: StageType.mainline,
  requiredRealm: RealmTier.xueTu,
  enemyTeam: [],
  isBossStage: true,
  baseExpReward: 0,
  difficultyMultiplier: 1,
);

const _floor = TowerFloorDef(
  floorIndex: 5,
  requiredRealm: RealmTier.xueTu,
  enemyTeam: [],
  sceneBackgroundPath: 'assets/scenes/tower_test.png',
);
