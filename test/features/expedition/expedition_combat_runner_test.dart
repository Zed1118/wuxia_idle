import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/features/debug/application/phase2_seed_service.dart';
import 'package:wuxia_idle/features/expedition/application/expedition_combat_runner.dart';
import 'package:wuxia_idle/features/expedition/application/expedition_service.dart';
import 'package:wuxia_idle/features/expedition/domain/expedition_run.dart';

import '../../support/isar_test_support.dart';
import '../../support/test_data.dart';

/// B2.2b 生产路径 e2e（feedback_layered_bugs 守卫：fake 测过 ≠ 真落地）。
///
/// 真 Isar 角色（`Phase2SeedService.seedP3`）→ 派遣 → 用**生产**
/// [ExpeditionCombatRunner] 结算，证明「派遣成员装配真实战斗队（含装备/心法/
/// autoFill）+ YAML 敌池 + [ExpeditionBattleRunner] + settle」端到端跑通、真打真赢。
void main() {
  late Directory tempDir;
  final departedAt = DateTime(2026, 7, 16, 10);

  setUpAll(() async {
    await initializeTestIsarCore();
    if (!GameRepository.isLoaded) {
      await loadTestGameRepository();
    }
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('wuxia_expedition_combat_');
    await IsarSetup.init(directory: tempDir, inspector: false);
  });

  tearDown(() async {
    if (Isar.getInstance('wuxia_save_slot1') != null) {
      await IsarSetup.close();
    }
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('runner 不含中文文案或 Dart 数值常量，敌队只从配置取得', () {
    final source = File(
      'lib/features/expedition/application/expedition_combat_runner.dart',
    ).readAsStringSync();
    // 2026-07-19 注释回中文后口径对齐 §5.6:拦的是代码里的中文文案/数值
    // 常量,中文「注释」是项目惯例(接口文件 expedition_combat.dart 同)。
    // 先剥行注释再扫,守卫语义不变。
    final code = source
        .split('\n')
        .map((line) => line.replaceFirst(RegExp(r'//.*$'), ''))
        .join('\n');
    expect(code, isNot(contains(RegExp(r'[\u4e00-\u9fff]'))));
    expect(code, isNot(contains(RegExp(r'(?<![A-Za-z_])\d+(?:\.\d+)?'))));
    expect(code, isNot(contains('EnemyDef(')));
    expect(source, contains('expeditionConfig'));
  });

  test('生产 ExpeditionCombatRunner + settle：真角色端到端推进并打赢配置敌队', () async {
    await Phase2SeedService(isar: IsarSetup.instance).seedP3();
    // 使 id=1 角色可派遣：非祖师、未占用。
    await IsarSetup.instance.writeTxn(() async {
      final c = (await IsarSetup.instance.characters.get(1))!
        ..isFounder = false
        ..lineageRole = LineageRole.disciple
        ..currentRetreatSessionId = null;
      await IsarSetup.instance.characters.put(c);
    });

    final svc = ExpeditionService(IsarSetup.instance);
    final runId = await svc.dispatch(
      characterIds: [1],
      policy: ExpeditionPolicy.yiZhanLiXing,
      now: departedAt,
    );

    final combat = ExpeditionCombatRunner(IsarSetup.instance);
    final config = GameRepository.instance.expeditionConfig!;

    // caps 由真实派生（fromCharacter maxHp/maxQi）→ 证明真实建队路径落地。
    final caps = await combat.memberCaps([1]);
    expect(caps[1]!.maxHp, greaterThan(0));
    expect(caps[1]!.maxQi, greaterThan(0));

    // 540 分 → 目标 5 节点（第 5 险关）；真角色应打赢占位弱敌推进到 5。
    final result = await svc.settle(
      combat: combat,
      config: config,
      now: departedAt.add(const Duration(minutes: 540)),
    );

    expect(result.defeated, isFalse, reason: '真角色应胜前五节点配置敌队');
    expect(result.currentNode, 5, reason: '含险关战斗节点全推进 → 真打真赢');
    final run = (await IsarSetup.instance.expeditionRuns.get(runId))!;
    expect(run.currentNode, 5);
    expect(run.stagedRewards, isNotEmpty);
    // 成员未倒下、HP 在合法区间（真打过战斗节点、经节点恢复）。
    final member = run.members.single;
    expect(member.isDowned, isFalse);
    expect(member.currentHp, greaterThan(0));
    expect(member.currentHp, lessThanOrEqualTo(caps[1]!.maxHp));
  });
}
