import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/attributes.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/domain/save_data.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/expedition/application/expedition_combat.dart';
import 'package:wuxia_idle/features/expedition/application/expedition_startup.dart';
import 'package:wuxia_idle/features/expedition/application/expedition_service.dart';
import 'package:wuxia_idle/data/defs/expedition_config.dart';
import 'package:wuxia_idle/features/expedition/domain/expedition_node.dart';
import 'package:wuxia_idle/features/expedition/domain/expedition_run.dart';

import '../../support/isar_test_support.dart';
import '../../support/test_data.dart';

/// 确定性 fake combat（同结算测体例）：全胜、成员满值上限固定。
class _FakeCombat implements ExpeditionCombat {
  final int maxHp = 1000;
  final int maxQi = 100;

  @override
  Future<Map<int, ExpeditionMemberCaps>> memberCaps(List<int> ids) async => {
    for (final id in ids) id: ExpeditionMemberCaps(maxHp: maxHp, maxQi: maxQi),
  };

  @override
  Future<ExpeditionNodeOutcome> fight({
    required ExpeditionNode node,
    required Map<int, ExpeditionMemberVital> memberStates,
    required int nodeSeed,
    required int cycleIndex,
  }) async {
    final hp = <int, int>{};
    final qi = <int, int>{};
    memberStates.forEach((id, v) {
      hp[id] = (v.hp - 100).clamp(0, maxHp);
      qi[id] = (v.qi - 10).clamp(0, maxQi);
    });
    return ExpeditionNodeOutcome(leftWin: true, survivorHp: hp, survivorQi: qi);
  }
}

ExpeditionConfig _config() => const ExpeditionConfig(
  normalNodeMinutes: 90,
  eliteNodeMinutes: 180,
  hpRecoverPctPerNode: 0.10,
  qiRecoverPctPerNode: 0.25,
  zhangshiPctPerLayer: 0.05,
);

Character _disciple() => Character()
  ..name = '弟子'
  ..realmTier = RealmTier.sanLiu
  ..realmLayer = RealmLayer.qiMeng
  ..attributes = Attributes()
  ..rarity = RarityTier.biaoZhun
  ..lineageRole = LineageRole.disciple
  ..createdAt = DateTime(2026, 7, 16)
  ..isFounder = false
  ..mainTechniqueId = 5;

void main() {
  late Directory tempDir;
  final departedAt = DateTime(2026, 7, 16, 10);

  setUpAll(() async {
    await initializeTestIsarCore();
    if (!GameRepository.isLoaded) await loadTestGameRepository();
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp(
      'wuxia_expedition_startup_',
    );
    await IsarSetup.init(directory: tempDir, inspector: false);
    await IsarSetup.instance.writeTxn(() async {
      await IsarSetup.instance.saveDatas.put(
        SaveData()
          ..id = 0
          ..saveVersion = '0.38.0'
          ..createdAt = departedAt
          ..lastSavedAt = departedAt
          ..lastOnlineAt = departedAt,
      );
    });
  });

  tearDown(() async {
    await IsarSetup.close();
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  test('有 active 远征：settle-on-open 按经过时长追平推进 currentNode', () async {
    final service = ExpeditionService(IsarSetup.instance);
    late int cid;
    await IsarSetup.instance.writeTxn(() async {
      cid = await IsarSetup.instance.characters.put(_disciple());
    });
    await service.dispatch(
      characterIds: [cid],
      policy: ExpeditionPolicy.yanJingCaiYao,
      now: departedAt,
    );

    // 出发 5h（300min）后：节点 1-3 各 90min（cum 270 ≤ 300），节点 4 需 360 > 300。
    final result = await settleActiveExpeditionOnOpen(
      service: service,
      combat: _FakeCombat(),
      config: _config(),
      now: departedAt.add(const Duration(hours: 5)),
    );

    expect(result.currentNode, 3);
    expect(result.caughtUp, isTrue);
    expect(result.defeated, isFalse);
    // 已持久化。
    final run = await service.activeRun();
    expect(run!.currentNode, 3);
  });

  test('无 active 远征：settle-on-open no-op', () async {
    final service = ExpeditionService(IsarSetup.instance);
    final result = await settleActiveExpeditionOnOpen(
      service: service,
      combat: _FakeCombat(),
      config: _config(),
      now: departedAt.add(const Duration(hours: 5)),
    );
    expect(result.nodesSettled, 0);
    expect(result.currentNode, 0);
    expect(result.caughtUp, isTrue);
  });

  test('路线 C 历史多人远征：兑现已落库状态并一次性释放会话', () async {
    final service = ExpeditionService(IsarSetup.instance);
    late int firstId;
    late int secondId;
    await IsarSetup.instance.writeTxn(() async {
      firstId = await IsarSetup.instance.characters.put(_disciple());
      secondId = await IsarSetup.instance.characters.put(_disciple());
    });
    await service.dispatch(
      characterIds: [firstId, secondId],
      policy: ExpeditionPolicy.yanJingCaiYao,
      now: departedAt,
    );

    expect(
      await retireLegacyMultiplayerExpeditionOnOpen(service: service),
      isTrue,
    );
    expect(await service.activeRun(), isNull);
    expect(
      await retireLegacyMultiplayerExpeditionOnOpen(service: service),
      isFalse,
      reason: '清场幂等',
    );
  });
}
