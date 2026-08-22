import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/attributes.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/domain/save_data.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/features/expedition/application/expedition_service.dart';
import 'package:wuxia_idle/features/expedition/domain/expedition_run.dart';

import '../../support/isar_test_support.dart';

void main() {
  late Directory tempDir;

  setUpAll(() => initializeTestIsarCore());

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp(
      'wuxia_expedition_dispatch_',
    );
    await IsarSetup.init(directory: tempDir, inspector: false);
    await IsarSetup.instance.writeTxn(() async {
      await IsarSetup.instance.saveDatas.put(
        SaveData()
          ..id = 0
          ..saveVersion = '0.38.0'
          ..createdAt = DateTime(2026, 7, 16)
          ..lastSavedAt = DateTime(2026, 7, 16)
          ..lastOnlineAt = DateTime(2026, 7, 16),
      );
    });
  });

  tearDown(() async {
    await IsarSetup.close();
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  Future<int> putDisciple({
    bool isFounder = false,
    int? weaponId,
    int? mainTech,
    List<int> assist = const [],
    int? retreatSessionId,
  }) async {
    late int id;
    await IsarSetup.instance.writeTxn(() async {
      final c = Character()
        ..name = isFounder ? '祖师' : '弟子'
        ..realmTier = RealmTier.sanLiu
        ..realmLayer = RealmLayer.qiMeng
        ..attributes = Attributes()
        ..rarity = RarityTier.biaoZhun
        ..lineageRole = isFounder ? LineageRole.founder : LineageRole.disciple
        ..createdAt = DateTime(2026, 7, 16)
        ..isFounder = isFounder
        ..equippedWeaponId = weaponId
        ..mainTechniqueId = mainTech
        ..assistTechniqueIds = assist
        ..currentRetreatSessionId = retreatSessionId;
      id = await IsarSetup.instance.characters.put(c);
    });
    return id;
  }

  test(
    '成功派遣：ExpeditionRun 落库 + 保留 id 快照 + serial++ + departedAt + seed',
    () async {
      final cid = await putDisciple(weaponId: 100, mainTech: 5, assist: [6]);
      final svc = ExpeditionService(IsarSetup.instance);

      final runId = await svc.dispatch(
        characterIds: [cid],
        policy: ExpeditionPolicy.yanJingCaiYao,
        now: DateTime(2026, 7, 16, 10),
      );

      final run = await IsarSetup.instance.expeditionRuns.get(runId);
      expect(run, isNotNull);
      final member = run!.members.single;
      expect(member.characterId, cid);
      expect(member.reservedEquipmentIds, [100]);
      expect(member.reservedTechniqueIds, [5, 6]);
      expect(run.departedAt, DateTime(2026, 7, 16, 10));
      expect(run.policy, ExpeditionPolicy.yanJingCaiYao);
      expect(run.currentNode, 0);

      final save = await IsarSetup.instance.saveDatas.get(0);
      expect(save!.expeditionRunSerial, 1);
      expect(run.seed, 1); // seed = 新 serial（B2.2 用作 generateNode runSerial）
    },
  );

  test('祖师入队 → 抛错', () async {
    final founder = await putDisciple(isFounder: true, mainTech: 5);
    final svc = ExpeditionService(IsarSetup.instance);
    await expectLater(
      svc.dispatch(
        characterIds: [founder],
        policy: ExpeditionPolicy.yanJingCaiYao,
      ),
      throwsStateError,
    );
  });

  test('已被占用角色（闭关中）入队 → 抛错', () async {
    final cid = await putDisciple(mainTech: 5, retreatSessionId: 9);
    final svc = ExpeditionService(IsarSetup.instance);
    await expectLater(
      svc.dispatch(characterIds: [cid], policy: ExpeditionPolicy.yanJingCaiYao),
      throwsStateError,
    );
  });

  test('每存档最多一条 active：二次派遣 → 抛错', () async {
    final a = await putDisciple(mainTech: 5);
    final b = await putDisciple(mainTech: 7);
    final svc = ExpeditionService(IsarSetup.instance);
    await svc.dispatch(
      characterIds: [a],
      policy: ExpeditionPolicy.yanJingCaiYao,
    );
    await expectLater(
      svc.dispatch(characterIds: [b], policy: ExpeditionPolicy.xunJiFangYou),
      throwsStateError,
    );
  });

  test('队伍为空 → 抛错', () async {
    final svc = ExpeditionService(IsarSetup.instance);
    await expectLater(
      svc.dispatch(characterIds: [], policy: ExpeditionPolicy.yanJingCaiYao),
      throwsStateError,
    );
  });

  test('路线 C 多于 1 人 → 抛错且不建新会话', () async {
    final ids = [for (var i = 0; i < 2; i++) await putDisciple(mainTech: 5)];
    final svc = ExpeditionService(IsarSetup.instance);
    await expectLater(
      svc.dispatch(characterIds: ids, policy: ExpeditionPolicy.yanJingCaiYao),
      throwsStateError,
    );
    expect(await IsarSetup.instance.expeditionRuns.count(), 0);
  });

  test('队伍含重复角色 → 抛错', () async {
    final cid = await putDisciple(mainTech: 5);
    final svc = ExpeditionService(IsarSetup.instance);
    await expectLater(
      svc.dispatch(
        characterIds: [cid, cid],
        policy: ExpeditionPolicy.yanJingCaiYao,
      ),
      throwsStateError,
    );
  });

  test('无存档 → 抛错（事务回滚·无 run）', () async {
    final cid = await putDisciple(mainTech: 5);
    await IsarSetup.instance.writeTxn(() async {
      await IsarSetup.instance.saveDatas.delete(0);
    });
    final svc = ExpeditionService(IsarSetup.instance);
    await expectLater(
      svc.dispatch(characterIds: [cid], policy: ExpeditionPolicy.yanJingCaiYao),
      throwsStateError,
    );
    expect(await IsarSetup.instance.expeditionRuns.count(), 0);
  });

  test('角色不存在 → 抛错（事务回滚·serial 不增）', () async {
    final svc = ExpeditionService(IsarSetup.instance);
    await expectLater(
      svc.dispatch(characterIds: [999], policy: ExpeditionPolicy.yanJingCaiYao),
      throwsStateError,
    );
    expect(await IsarSetup.instance.expeditionRuns.count(), 0);
    final save = await IsarSetup.instance.saveDatas.get(0);
    expect(save!.expeditionRunSerial, 0, reason: '回滚·serial 未消费');
  });

  test('未修主修 → 抛错', () async {
    final cid = await putDisciple(mainTech: null);
    final svc = ExpeditionService(IsarSetup.instance);
    await expectLater(
      svc.dispatch(characterIds: [cid], policy: ExpeditionPolicy.yanJingCaiYao),
      throwsStateError,
    );
  });
}
