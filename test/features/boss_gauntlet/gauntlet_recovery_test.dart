import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/domain/inventory_item.dart';
import 'package:wuxia_idle/core/domain/save_data.dart';
import 'package:wuxia_idle/data/defs/item_def.dart';
import 'package:wuxia_idle/data/defs/stage_def.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/features/activity/domain/activity_member_snapshot.dart';
import 'package:wuxia_idle/features/boss_gauntlet/application/gauntlet_service.dart';
import 'package:wuxia_idle/features/boss_gauntlet/domain/boss_gauntlet_config.dart';
import 'package:wuxia_idle/features/boss_gauntlet/domain/boss_gauntlet_run.dart';

/// C2.3b 崩溃恢复关次边界（§5.6/§10）。恢复本质 = 会话持久 + 驱动原子（已由 C2.3a
/// 保证），本切片补「配置损坏」边界：第一关前不可恢复 → 退帖关会话；已开战 → 认输
/// 关闭（信号交 C2.5 结算·不复制补给）。Isar-only 轻量环境（不载 GameRepository）。
void main() {
  late Directory tempDir;

  final itemDefs = <String, ItemDef>{
    'item_liaoshangdan': const ItemDef(
      defId: 'item_liaoshangdan',
      type: ItemType.miscMaterial,
      name: '疗伤丹',
      gauntletHpHealPct: 0.30,
    ),
  };

  // 最小可用配置：关1 敌队非空 → recover 判为「可用·resumed」。
  const usableConfig = BossGauntletConfig(
    stages: [
      GauntletStageConfig(role: 'elite', enemyTeamId: 't1'),
      GauntletStageConfig(role: 'elite', enemyTeamId: 't2'),
      GauntletStageConfig(role: 'boss', enemyTeamId: 't3'),
    ],
    supplyCap: 3,
    enemyTeams: {
      't1': [
        EnemyDef(
          id: 'e1',
          name: '喽啰',
          realmTier: RealmTier.xueTu,
          realmLayer: RealmLayer.qiMeng,
          school: TechniqueSchool.gangMeng,
          baseHp: 300,
          baseAttack: 25,
          baseSpeed: 80,
          skillIds: [],
          iconPath: '',
        ),
      ],
    },
  );

  // 三关配置但 enemyTeams 空 → enemiesForTeam 返回空 → 判为「损坏」。
  const emptyTeamsConfig = BossGauntletConfig(
    stages: [
      GauntletStageConfig(role: 'elite', enemyTeamId: 't1'),
      GauntletStageConfig(role: 'elite', enemyTeamId: 't2'),
      GauntletStageConfig(role: 'boss', enemyTeamId: 't3'),
    ],
    supplyCap: 3,
  );

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('wuxia_gauntlet_recovery_');
    await IsarSetup.init(directory: tempDir, inspector: false);
    await IsarSetup.instance.writeTxn(() async {
      await IsarSetup.instance.saveDatas.put(
        SaveData()
          ..id = 0
          ..saveVersion = '0.37.0'
          ..createdAt = DateTime(2026, 7, 17)
          ..lastSavedAt = DateTime(2026, 7, 17)
          ..lastOnlineAt = DateTime(2026, 7, 17),
      );
    });
  });

  tearDown(() async {
    await IsarSetup.close();
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  ActivityMemberSnapshot member(int id, {int maxHp = 0, int currentHp = 0}) =>
      ActivityMemberSnapshot()
        ..characterId = id
        ..maxHp = maxHp
        ..currentHp = currentHp
        ..isDowned = false;

  Future<void> putRun({
    required GauntletPhase phase,
    required int currentStage,
    required List<ActivityMemberSnapshot> members,
    List<String> escrowDefIds = const [],
    List<int> escrowLoaded = const [],
    List<int> escrowUsed = const [],
  }) async {
    await IsarSetup.instance.writeTxn(() async {
      await IsarSetup.instance.bossGauntletRuns.put(
        BossGauntletRun()
          ..saveDataId = 0
          ..seed = 0
          ..currentStage = currentStage
          ..sessionPhase = phase
          ..members = members
          ..escrowItemDefIds = List.of(escrowDefIds)
          ..escrowLoadedQty = List.of(escrowLoaded)
          ..escrowUsedQty = List.of(escrowUsed),
      );
    });
  }

  Future<void> putInventory(String defId, ItemType type, int qty) async {
    await IsarSetup.instance.writeTxn(() async {
      await IsarSetup.instance.inventoryItems.put(
        InventoryItem()
          ..defId = defId
          ..itemType = type
          ..quantity = qty
          ..firstObtainedAt = DateTime(2026, 7, 17)
          ..lastObtainedAt = DateTime(2026, 7, 17),
      );
    });
  }

  Future<int?> qtyOf(String defId) async =>
      (await IsarSetup.instance.inventoryItems.getByDefId(defId))?.quantity;

  Future<int> runCount() async => IsarSetup.instance.bossGauntletRuns.count();

  GauntletService svc() =>
      GauntletService(IsarSetup.instance, itemDefs: itemDefs);

  test('无 active 会话 → none', () async {
    expect(
      await svc().recover(config: usableConfig),
      GauntletRecoveryOutcome.none,
    );
  });

  test('配置可用 → resumed（不改会话）', () async {
    await putRun(
      phase: GauntletPhase.inBattle,
      currentStage: 1,
      members: [member(1)],
    );
    expect(
      await svc().recover(config: usableConfig),
      GauntletRecoveryOutcome.resumed,
    );
    expect(await runCount(), 1, reason: 'resumed 不动会话');
  });

  test('配置损坏（null）+ 第一关前未开战 → refundedTicket：退帖+返还+删会话', () async {
    await putRun(
      phase: GauntletPhase.inBattle,
      currentStage: 1,
      members: [member(1)], // maxHp=0 未开战
      escrowDefIds: ['item_liaoshangdan'],
      escrowLoaded: [3],
      escrowUsed: [1],
    );
    await putInventory('item_duanhuntie', ItemType.ticket, 0); // 入场已扣
    await putInventory('item_liaoshangdan', ItemType.miscMaterial, 0); // 已移入托管

    expect(
      await svc().recover(config: null),
      GauntletRecoveryOutcome.refundedTicket,
    );
    expect(await qtyOf('item_duanhuntie'), 1, reason: '退帖 +1');
    expect(await qtyOf('item_liaoshangdan'), 2, reason: '返还 Loaded-Used=3-1');
    expect(await runCount(), 0, reason: '关会话删除');
  });

  test('配置损坏（enemyTeams 空）+ 第一关前 → refundedTicket', () async {
    await putRun(
      phase: GauntletPhase.inBattle,
      currentStage: 1,
      members: [member(1)],
    );
    await putInventory('item_duanhuntie', ItemType.ticket, 0);
    expect(
      await svc().recover(config: emptyTeamsConfig),
      GauntletRecoveryOutcome.refundedTicket,
    );
    expect(await qtyOf('item_duanhuntie'), 1);
    expect(await runCount(), 0);
  });

  test('配置损坏 + 已开战（关2 / maxHp>0）→ concedeRequired（不改会话·不退帖）', () async {
    await putRun(
      phase: GauntletPhase.interlude,
      currentStage: 2,
      members: [member(1, maxHp: 1000, currentHp: 400)], // maxHp>0 已开战
    );
    await putInventory('item_duanhuntie', ItemType.ticket, 0);
    expect(
      await svc().recover(config: null),
      GauntletRecoveryOutcome.concedeRequired,
    );
    expect(await qtyOf('item_duanhuntie'), 0, reason: '已开战不退帖');
    expect(await runCount(), 1, reason: '会话留待 C2.5 认输结算');
  });
}
