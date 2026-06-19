import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/core/domain/attributes.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/domain/equipment.dart';
import 'package:wuxia_idle/core/domain/save_data.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/features/battle/domain/battle_stats.dart';
import 'package:wuxia_idle/features/battle_record/application/boss_memory_hook.dart';
import 'package:wuxia_idle/features/battle_record/application/boss_memory_service.dart';
import 'package:wuxia_idle/features/battle_record/domain/boss_memory_source.dart';
import 'package:wuxia_idle/features/equipment/application/drop_service.dart';

/// 最简 BattleStatsSummary（无需 BattleState，直接 const）。
const _testStats = BattleStatsSummary(
  totalDamage: 18000,
  critCount: 5,
  totalTicks: 40,
);

/// 构造 Equipment 并设 tier。
Equipment _makeEquipment(String defId, EquipmentTier tier) {
  return Equipment.create(
    defId: defId,
    tier: tier,
    slot: EquipmentSlot.weapon,
    obtainedAt: DateTime(2026, 6, 20),
    obtainedFrom: 'test',
  );
}

/// 将 SaveData 写入（activeCharacterIds 可传入）。
Future<void> _writeSaveData(Isar isar, {List<int> activeIds = const []}) async {
  await isar.writeTxn(() => isar.saveDatas.put(
        SaveData()
          ..id = 0
          ..slotId = IsarSetup.currentSlotId
          ..saveVersion = '0.0.1'
          ..createdAt = DateTime(2026, 6, 20)
          ..lastSavedAt = DateTime(2026, 6, 20)
          ..lastOnlineAt = DateTime(2026, 6, 20)
          ..activeCharacterIds = activeIds,
      ));
}

/// 构造并入库 Character，返回 id。
Future<int> _insertCharacter(
  Isar isar, {
  required String name,
  String? portraitPath,
}) async {
  final c = Character.create(
    name: name,
    realmTier: RealmTier.xueTu,
    realmLayer: RealmLayer.qiMeng,
    attributes: Attributes(),
    rarity: RarityTier.biaoZhun,
    lineageRole: LineageRole.founder,
    createdAt: DateTime(2026, 6, 20),
    portraitPath: portraitPath,
  );
  return isar.writeTxn(() => isar.characters.put(c));
}

void main() {
  late Directory tempDir;

  setUpAll(() async {
    await Isar.initializeIsarCore(download: true);
    if (!GameRepository.isLoaded) {
      await GameRepository.loadAllDefs(
        loader: (path) => File(path).readAsString(),
      );
    }
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('wuxia_boss_memory_hook_');
    await IsarSetup.init(directory: tempDir, inspector: false);
    await _writeSaveData(IsarSetup.instance);
  });

  tearDown(() async {
    if (Isar.getInstance('wuxia_save_slot1') != null) {
      await IsarSetup.close();
    }
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('runBossMemoryHookAfterVictory', () {
    test('Boss 胜利 → 留档一条', () async {
      const drops = DropResult(equipments: [], items: []);
      await runBossMemoryHookAfterVictory(
        source: BossMemorySource.mainline,
        bossKey: 'stage_01_05',
        groupIndex: 1,
        bossName: '撑伞高人',
        stats: _testStats,
        drops: drops,
      );
      final all = await BossMemoryService(isar: IsarSetup.instance)
          .allMemories(IsarSetup.currentSlotId);
      expect(all, hasLength(1));
      final m = all.first;
      expect(m.bossKey, 'stage_01_05');
      expect(m.source, BossMemorySource.mainline);
      expect(m.totalDamage, 18000);
      expect(m.critCount, 5);
      expect(m.totalTicks, 40);
      expect(m.defeatCount, 1);
      expect(m.isPreRecord, isFalse);
    });

    test('重打同 bossKey → defeatCount 累加', () async {
      const drops = DropResult(equipments: [], items: []);
      await runBossMemoryHookAfterVictory(
        source: BossMemorySource.mainline,
        bossKey: 'stage_01_05',
        groupIndex: 1,
        bossName: '撑伞高人',
        stats: _testStats,
        drops: drops,
      );
      await runBossMemoryHookAfterVictory(
        source: BossMemorySource.mainline,
        bossKey: 'stage_01_05',
        groupIndex: 1,
        bossName: '撑伞高人',
        stats: _testStats,
        drops: drops,
      );
      final all = await BossMemoryService(isar: IsarSetup.instance)
          .allMemories(IsarSetup.currentSlotId);
      expect(all, hasLength(1));
      expect(all.first.defeatCount, 2);
      // 首胜快照冻结
      expect(all.first.totalDamage, 18000);
    });

    test('treasure = 最高阶装备掉落', () async {
      // 两件装备：好家伙(idx2) vs 神物(idx6) → 取 idx6
      final lowTier = _makeEquipment('equip_placeholder_01', EquipmentTier.haoJiaHuo);
      final highTier = _makeEquipment('equip_placeholder_01', EquipmentTier.shenWu);
      final drops = DropResult(equipments: [lowTier, highTier], items: []);
      await runBossMemoryHookAfterVictory(
        source: BossMemorySource.mainline,
        bossKey: 'stage_01_05',
        groupIndex: 1,
        bossName: '撑伞高人',
        stats: _testStats,
        drops: drops,
      );
      final m = (await BossMemoryService(isar: IsarSetup.instance)
              .allMemories(IsarSetup.currentSlotId))
          .single;
      expect(m.treasureTier, EquipmentTier.shenWu);
    });

    test('无装备掉落时 treasureTier = null', () async {
      const drops = DropResult(equipments: [], items: []);
      await runBossMemoryHookAfterVictory(
        source: BossMemorySource.mainline,
        bossKey: 'stage_01_05',
        groupIndex: 1,
        bossName: '撑伞高人',
        stats: _testStats,
        drops: drops,
      );
      final m = (await BossMemoryService(isar: IsarSetup.instance)
              .allMemories(IsarSetup.currentSlotId))
          .single;
      expect(m.treasureTier, isNull);
    });

    test('topContributorName/Damage 传入后存入纪念', () async {
      const drops = DropResult(equipments: [], items: []);
      await runBossMemoryHookAfterVictory(
        source: BossMemorySource.mainline,
        bossKey: 'stage_01_05',
        groupIndex: 1,
        bossName: '撑伞高人',
        stats: _testStats,
        drops: drops,
        topContributorName: '祖师',
        topContributorDamage: 9000,
      );
      final m = (await BossMemoryService(isar: IsarSetup.instance)
              .allMemories(IsarSetup.currentSlotId))
          .single;
      expect(m.topContributorName, '祖师');
      expect(m.topContributorDamage, 9000);
    });

    test('roster 从 activeCharacterIds 读取 name + portrait', () async {
      final isar = IsarSetup.instance;
      final id1 = await _insertCharacter(isar,
          name: '祖师', portraitPath: 'portraits/founder.png');
      final id2 = await _insertCharacter(isar,
          name: '大弟子', portraitPath: 'portraits/senior.png');
      // 写 SaveData，activeCharacterIds = [id1, id2]
      await _writeSaveData(isar, activeIds: [id1, id2]);

      await runBossMemoryHookAfterVictory(
        source: BossMemorySource.mainline,
        bossKey: 'stage_01_05',
        groupIndex: 1,
        bossName: '撑伞高人',
        stats: _testStats,
        drops: const DropResult(equipments: [], items: []),
      );

      final m = (await BossMemoryService(isar: isar)
              .allMemories(IsarSetup.currentSlotId))
          .single;
      expect(m.rosterNames, ['祖师', '大弟子']);
      expect(m.rosterPortraits, ['portraits/founder.png', 'portraits/senior.png']);
    });

    test('Isar 未 ready → no-op 不抛', () async {
      await IsarSetup.close();
      await expectLater(
        runBossMemoryHookAfterVictory(
          source: BossMemorySource.mainline,
          bossKey: 'stage_01_05',
          groupIndex: 1,
          bossName: '撑伞高人',
          stats: _testStats,
          drops: const DropResult(equipments: [], items: []),
        ),
        completes,
      );
    });
  });
}
