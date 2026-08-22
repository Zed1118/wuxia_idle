import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/features/debug/application/phase2_seed_service.dart';
import 'package:wuxia_idle/features/expedition/application/expedition_combat.dart';
import 'package:wuxia_idle/features/expedition/application/expedition_combat_runner.dart';
import 'package:wuxia_idle/features/expedition/application/expedition_combat_selector.dart';
import 'package:wuxia_idle/features/expedition/application/phase0a_expedition_combat_runner.dart';
import 'package:wuxia_idle/features/expedition/application/phase0a_expedition_gate.dart';
import 'package:wuxia_idle/features/expedition/domain/expedition_node.dart';

import '../../support/isar_test_support.dart';
import '../../support/test_data.dart';

void main() {
  late Directory tempDir;

  setUpAll(() async {
    await initializeTestIsarCore();
    if (!GameRepository.isLoaded) {
      await loadTestGameRepository();
    }
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp(
      'wuxia_phase0a_expedition_',
    );
    await IsarSetup.init(directory: tempDir, inspector: false);
    await Phase2SeedService(isar: IsarSetup.instance).seedP3();
    await IsarSetup.instance.writeTxn(() async {
      final character = (await IsarSetup.instance.characters.get(1))!
        ..isFounder = false
        ..lineageRole = LineageRole.disciple
        ..currentRetreatSessionId = null;
      await IsarSetup.instance.characters.put(character);
    });
  });

  tearDown(() async {
    Phase0aExpeditionGate.testOverride = null;
    if (Isar.getInstance('wuxia_save_slot1') != null) {
      await IsarSetup.close();
    }
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('灰度默认关闭；仅单成员启用，历史多成员会话回落旧 runner', () {
    expect(Phase0aExpeditionGate.enabled, isFalse);
    expect(
      expeditionCombatFor(IsarSetup.instance, memberCount: 1),
      isA<ExpeditionCombatRunner>(),
    );

    Phase0aExpeditionGate.testOverride = true;
    expect(
      expeditionCombatFor(IsarSetup.instance, memberCount: 1),
      isA<Phase0aExpeditionCombatRunner>(),
    );
    expect(
      expeditionCombatFor(IsarSetup.instance, memberCount: 2),
      isA<ExpeditionCombatRunner>(),
    );
  });

  test('单角色真实节点同 seed 确定，且战后 HP/真气写回合法区间', () async {
    final firstRunner = Phase0aExpeditionCombatRunner(IsarSetup.instance);
    final secondRunner = Phase0aExpeditionCombatRunner(IsarSetup.instance);
    final caps = (await firstRunner.memberCaps([1]))[1]!;
    final memberStates = {
      1: ExpeditionMemberVital(hp: caps.maxHp, qi: caps.maxQi ~/ 2),
    };
    const node = ExpeditionNode(
      index: 5,
      type: ExpeditionNodeType.xianGuan,
      durationMinutes: 180,
    );

    final first = await firstRunner.fight(
      node: node,
      memberStates: memberStates,
      nodeSeed: 820225,
      cycleIndex: 1,
    );
    final replay = await secondRunner.fight(
      node: node,
      memberStates: memberStates,
      nodeSeed: 820225,
      cycleIndex: 1,
    );

    expect(replay.leftWin, first.leftWin);
    expect(replay.survivorHp, first.survivorHp);
    expect(replay.survivorQi, first.survivorQi);
    expect(first.survivorHp.keys, [1]);
    expect(first.survivorQi.keys, [1]);
    expect(first.survivorHp[1], inInclusiveRange(0, caps.maxHp));
    expect(first.survivorQi[1], inInclusiveRange(0, caps.maxQi));
  });

  test('runner 拒绝多成员误入 Phase 0A 路径', () async {
    final runner = Phase0aExpeditionCombatRunner(IsarSetup.instance);

    await expectLater(runner.memberCaps([1, 2]), throwsA(isA<StateError>()));
  });
}
