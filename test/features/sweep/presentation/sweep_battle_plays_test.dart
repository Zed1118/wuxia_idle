import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/application/battle_providers.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/defs/skill_def.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/battle/domain/battle_state.dart';
import 'package:wuxia_idle/features/sweep/application/sweep_unit.dart';
import 'package:wuxia_idle/features/sweep/domain/sweep_recap.dart';
import 'package:wuxia_idle/features/sweep/presentation/sweep_screen.dart';
import 'package:wuxia_idle/shared/audio/audio_assets.dart';
import 'package:wuxia_idle/shared/strings.dart';

/// 回归锚（2026-06-26 一键扫荡黑屏 hang bug）：
///
/// SweepScreen 在 `_preparing` spinner 期间不挂 BattleScreen，向 **autoDispose**
/// 的 `battleProvider` 注入队伍后无监听者 → 被回收重置回空团；且迟挂载错过
/// `empty→非空` listen 边沿 → timer 不起。两者叠加：进入扫荡卡「连播中 1/N」
/// 黑屏无限转圈，战斗永不前进、永不到 recap。
///
/// 本测用一个真往 `battleProvider` 注入「快速 leftWin」真战斗的假单位复现：
/// 修复前战斗永不前进 → 永不显「扫荡完成」recap（本测 RED）；
/// 修复后逐场真跑到胜负 → 收工显 recap（GREEN）。
class _FastWinUnit implements SweepUnit {
  @override
  String get label => '试炼一关';
  @override
  String get battleHint => '试炼一关';
  @override
  String? get sceneBackgroundPath => null;
  @override
  BgmTrack get bgmTrack => BgmTrack.tower;

  @override
  Future<void> startBattle(WidgetRef ref) async {
    // 复刻真实 startBattle 的 async 间隙：装配队伍是 await Isar 的，注入发生在
    // spinner 重建之后（此刻 BattleScreen 尚未挂载、无 watcher）。
    await Future<void>.delayed(Duration.zero);
    ref.read(battleProvider.notifier).startBattle(
          _team(side: 0, hp: 12000),
          _team(side: 1, hp: 80), // 右队残血 → 数拍内必 leftWin
          seed: 7,
        );
  }

  @override
  Future<SweepBattleOutcome?> settle(WidgetRef ref) async =>
      const SweepBattleOutcome();

  static const _normal = SkillDef(
    id: 'skill_sweep_normal',
    name: '普攻',
    description: 'sweep 测普攻',
    type: SkillType.normalAttack,
    powerMultiplier: 500,
    internalForceCost: 0,
    cooldownTurns: 0,
    requiresManualTrigger: false,
    visualEffect: 'stub',
  );

  static List<BattleCharacter> _team({required int side, required int hp}) {
    return List.generate(3, (i) {
      final id = side == 0 ? i + 1 : -(i + 1);
      return BattleCharacter(
        characterId: id,
        name: '$id',
        realmTier: RealmTier.yiLiu,
        realmLayer: RealmLayer.qiMeng,
        school: TechniqueSchool.gangMeng,
        maxHp: hp,
        currentHp: hp,
        maxInternalForce: 2000,
        currentInternalForce: 2000,
        speed: side == 0 ? 200 : 90,
        criticalRate: 0.2,
        evasionRate: 0.0,
        defenseRate: 0.1,
        totalEquipmentAttack: side == 0 ? 800 : 200,
        mainCultivationLayer: CultivationLayer.daCheng,
        availableSkills: const <SkillDef>[_normal],
        skillCooldowns: const {},
        activeBuffs: const [],
        actionPoint: 0,
        isAlive: true,
        teamSide: side,
        slotIndex: i,
      );
    });
  }
}

void main() {
  setUpAll(() async {
    if (!GameRepository.isLoaded) {
      await GameRepository.loadAllDefs(loader: (p) => File(p).readAsString());
    }
  });

  testWidgets('一键扫荡：逐关真跑战斗到胜负，收工显「扫荡完成」recap（黑屏 hang 回归锚）',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 720));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: SweepScreen(
            units: [_FastWinUnit()],
            unitName: '问鼎江湖',
          ),
        ),
      ),
    );

    // 有界 pump 循环：战斗经 fastForward timer 逐拍前进直到 leftWin → onVictory
    // → settle → 收工 recap。修复前永不到 recap，循环耗尽后断言失败（RED）。
    for (var i = 0;
        i < 400 &&
            find.text(UiStrings.sweepRecapCompleted).evaluate().isEmpty;
        i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    expect(find.text(UiStrings.sweepRecapCompleted), findsOneWidget,
        reason: '扫荡战斗应真跑到胜负并收工显 recap；若卡黑屏说明 hang 未修');
  });

  testWidgets('一键扫荡：多关连播跨场转换不卡，2 关全打完收工（保活跨间隙回归锚）',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 720));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: SweepScreen(
            units: [_FastWinUnit(), _FastWinUnit()],
            unitName: '问鼎江湖',
          ),
        ),
      ),
    );

    for (var i = 0;
        i < 600 &&
            find.text(UiStrings.sweepRecapCompleted).evaluate().isEmpty;
        i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    expect(find.text(UiStrings.sweepRecapCompleted), findsOneWidget);
    // 两关均真跑到胜负 → recap 计「通关 2 关」(跨场注入未被 autoDispose 回收)。
    expect(find.text(UiStrings.sweepRecapStages(2)), findsOneWidget,
        reason: '第 2 关须接着第 1 关连播；若只 1 关说明跨场转换/保活失效');
  });
}
