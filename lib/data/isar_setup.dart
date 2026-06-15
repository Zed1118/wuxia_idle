import 'dart:io';

import 'package:isar_community/isar.dart';
import 'package:path_provider/path_provider.dart';

import 'game_repository.dart';
import '../core/domain/enums.dart';
import '../core/domain/character.dart';
import '../features/encounter/domain/encounter_progress.dart';
import '../core/domain/equipment.dart';
import '../core/domain/game_event.dart';
import '../core/domain/inventory_item.dart';
import '../features/mainline/domain/mainline_progress.dart';
import '../features/seclusion/domain/retreat_session.dart';
import '../core/domain/save_data.dart';
import '../core/domain/skill_unlock_entry.dart';
import '../core/domain/technique.dart';
import '../features/tower/domain/tower_progress.dart';
import '../features/jianghu/domain/reputation.dart';
import '../features/jianghu/domain/npc_relation.dart';
import '../features/sect/domain/sect.dart';
import '../features/sect/domain/sect_event.dart';
import '../features/pvp/domain/pvp_record.dart';
import '../features/pvp/domain/pvp_snapshot.dart';

/// Isar 初始化与生命周期（data_schema.md §7.1，简化版）。
///
/// **Phase 1 简化**：只支持单槽位（slotId=1）。多槽切换 / 列表 / 删除
/// 推迟到 Phase 5（见类内 TODO Phase 5 标注）。
///
/// 文件命名仍按 `wuxia_save_slot{slotId}.isar`，便于 Phase 5 扩展。
class IsarSetup {
  static Isar? _instance;

  /// 已初始化的 Isar 实例（生产路径用）。未 init 时抛 [StateError],
  /// 强制调用方先跑 [init]。
  static Isar get instance =>
      _instance ??
      (throw StateError('IsarSetup 未初始化,请先 await IsarSetup.init()'));

  /// 探测式 getter（Phase 5 W6-S2 引入,供 [isarProvider] 走 nullable
  /// propagation）：未 init 时返回 null,不抛错。生产路径走 [instance]。
  static Isar? get instanceOrNull => _instance;

  /// 当前槽位 SaveData（id 固定 0）。init 后必非 null；未 init 时 instance 抛错。
  static Future<SaveData?> currentSaveData() => instance.saveDatas.get(0);

  static int currentSlotId = 1;

  /// 全部持久化 schema 清单（data_schema.md §7.1）。
  ///
  /// Phase 1 起 6 个：SaveData / Character / Equipment / Technique /
  /// InventoryItem / GameEvent。Phase 3 T34 加 MainlineProgress；
  /// Phase 3 T41 加 TowerProgress；Phase 3 T48 加 RetreatSession。
  /// 剩余 AdventureRecord / DailyChallenge 在后续任务建模时追加。
  static const _allSchemas = [
    SaveDataSchema,
    CharacterSchema,
    EquipmentSchema,
    TechniqueSchema,
    InventoryItemSchema,
    GameEventSchema,
    MainlineProgressSchema,
    TowerProgressSchema,
    RetreatSessionSchema,
    EncounterProgressSchema,
    ReputationSchema,
    NpcRelationSchema,
    SectSchema,
    SectEventSchema,
    PvpRecordSchema,
    PvpSnapshotSchema,
  ];

  /// 当前 schema 对应的存档版本（写入新建 SaveData.saveVersion）。
  /// Phase 3 T34 schema 加 MainlineProgress collection → 升 0.2.0；
  /// Phase 3 T41 加 TowerProgress collection → 升 0.3.0；
  /// Phase 3 T48 加 RetreatSession collection → 升 0.4.0。
  /// Phase 4 W14-1 加 EncounterProgress collection → 升 0.5.0。
  /// Phase 4 W14-2 EncounterProgress 加 biomeMinutes/weatherMinutes 嵌入 → 升 0.6.0。
  /// Phase 4 W14-3-A Character 加 equippedEncounterSkillId String? → 升 0.7.0。
  /// W15 #30 第 2 期 Character 加 insightPoints int(领悟点 wallet) → 升 0.8.0。
  /// P0.2 #40 Phase 1 TowerProgress 加 perFloorClearTimes/bestClearTime/lastClearedAt → 升 0.9.0。
  /// P1 #42 Phase 1 SaveData 加 tutorialStep(留 §10 P1.x 接口)→ 升 0.10.0。
  /// P1 #42 Phase 2 §10 P1.y SaveData 加 tutorialHintsRead(banner 已读状)→ 升 0.11.0。
  /// P1.1 A1 E.1 SaveData 加 recruitmentOffered/recruitedDiscipleIds(收徒)→ 升 0.12.0。
  /// P1.2 T17 + P3 T19b 合并升:Reputation/NpcRelation(P1.2)+ Sect/SectEvent/PvpRecord/
  /// PvpSnapshot(T19b)6 schema 一并接入 `_allSchemas` → 升 0.13.0。
  /// P4.1 1.1 Q6B SaveData 加 triggeredBossRecruitStageIds(Boss 招降防刷)→ 升 0.14.0。
  /// sect 立绘 wiring Character 加 portraitPath String?(sect 成员立绘)→ 升 0.15.0。
  // P1b 藏经阁:Character 加 5 装配槽字段(mainSkillId1/2/assist/resonance/ultimate)→ 0.17.0。
  // 波A:Character 加 keySkillId 破招槽 + 奇遇 unlock 池迁入 skillUnlockProgress → 0.18.0。
  // 半手动 P0 步骤5:加 BattleReplayRecord collection(seed+ops 重放落盘)→ 0.19.0。
  //   新 collection,旧档天然空(无已手动通关记录是正确初始态),无数据迁移动作。
  // 半手动 P0 步骤5 全闭环:BattleReplayRecord 加 autoPlayOverride bool?(每关记忆)→ 0.20.0。
  //   既有 collection 加 nullable 字段,旧记录读为 null(=随全局 autoPlayDefault),无迁移动作。
  // P1 周目进化 A3:MainlineProgress 加 clearedStageCycleKeys(旧档补 "#1" 键)
  //   + TowerProgress 加 currentCycleIndex/maxClearedCycle(旧档按 highestClearedFloor 推导)→ 0.21.0。
  // 周目按章(2026-06-14):MainlineProgress 加 clearedChapterCycleKeys。旧
  //   clearedStageCycleKeys 中的章末 Boss 关(isBoss)→ "chapterKey#cycle" → 0.22.0。
  // 战斗交互重做 Phase 3(2026-06-14):废录制回放,删 BattleReplayRecord collection
  //   (从 _allSchemas 移除)。旧档该 collection 数据 orphaned 不再读;per-stage
  //   autoPlayOverride 迁 SharedPreferences(设置≠存档,见 stage_auto_play_pref.dart),
  //   旧 Isar override 不迁移(语义已从「自动/手动单步」变「挂机/拖招」,重置随全局)。
  //   无数据迁移动作,仅版本标记 → 0.23.0。
  //   M2 范围 B 被动离线挂机:SaveData 加 totalPassiveMojianshi/totalPassiveExperience
  //   (旧档新 int 字段自动 0,无显式迁移动作,_migrateSaveData 尾部统一落版本号)→ 0.24.0。
  static const _currentSaveVersion = '0.24.0';

  /// 打开 Isar 实例。`directory` 可注入用于测试；生产由 path_provider 提供。
  static Future<void> init({
    int slotId = 1,
    Directory? directory,
    bool inspector = true,
  }) async {
    assert(slotId >= 1 && slotId <= 3, 'slotId 必须是 1/2/3');

    final dir = directory ?? await getApplicationDocumentsDirectory();
    _instance = await Isar.open(
      _allSchemas,
      directory: dir.path,
      name: 'wuxia_save_slot$slotId',
      inspector: inspector,
    );
    currentSlotId = slotId;

    await _ensureSaveData();
  }

  /// 启动时确保 SaveData 单例存在；不存在则建一行默认值。
  /// 旧档(saveVersion != 当前)→ 跑迁移后升版(幂等,见 [_migrateSaveData])。
  static Future<SaveData> _ensureSaveData() async {
    final isar = instance;
    final existing = await isar.saveDatas.get(0);
    if (existing != null) {
      if (existing.saveVersion != _currentSaveVersion) {
        await _migrateSaveData(isar, existing);
      }
      return existing;
    }

    final now = DateTime.now();
    final fresh = SaveData()
      ..id = 0
      ..slotId = currentSlotId
      ..saveVersion = _currentSaveVersion
      ..createdAt = now
      ..lastSavedAt = now
      ..lastOnlineAt = now;
    await isar.writeTxn(() => isar.saveDatas.put(fresh));
    return fresh;
  }

  /// 波A A4 0.18.0 迁移:旧池 `EncounterProgress.unlockedSkillIds`(全部行)
  /// 并入新池 `SaveData.skillUnlockProgress`(markUnlocked 幂等,可重复跑)。
  /// 迁移后旧字段退役只读(写路径已切 encounter_service / seed)。
  ///
  /// P1 A3 0.21.0 迁移（追加段）:
  ///   - MainlineProgress.clearedStageCycleKeys:将旧 clearedStageIds 里每个 id
  ///     补入 "$id#1"(幂等:已存在则跳过)。
  ///   - TowerProgress.currentCycleIndex = 1(显式落档);
  ///     maxClearedCycle = highestClearedFloor >= 30 ? 1 : 0。
  static Future<void> _migrateSaveData(Isar isar, SaveData save) async {
    // 段 1(0.18.0+):encounter 旧 unlock 池并入 skillUnlockProgress。
    final progresses = await isar.encounterProgress.where().findAll();

    // 段 2(0.21.0):周目字段迁移。
    final mainlineRows = await isar.mainlineProgress.where().findAll();
    final towerRows = await isar.towerProgress.where().findAll();

    await isar.writeTxn(() async {
      // --- 段 1 ---
      save.skillUnlockProgress = List.of(save.skillUnlockProgress);
      for (final p in progresses) {
        for (final sid in p.unlockedSkillIds) {
          save.skillUnlockProgress.markUnlocked(sid);
        }
      }

      // --- 段 2 ---
      for (final mp in mainlineRows) {
        final keys = List<String>.of(mp.clearedStageCycleKeys);
        for (final stageId in mp.clearedStageIds) {
          final key = '$stageId#1';
          if (!keys.contains(key)) {
            keys.add(key);
          }
        }
        mp.clearedStageCycleKeys = keys;
        // 段 3(0.22.0 周目按章):旧 per-stage cycle key 中的章末 Boss 关(isBoss)
        // → per-chapter cycle key "chapterKey#cycle"。chapterKey 逻辑须与
        // MainlineProgressService.chapterKeyForStage 同步。GameRepository 未加载
        // (理论不会:splash 先 loadAllDefs 再 init)→ 跳过,玩家重打 Boss 时重建。
        if (GameRepository.isLoaded) {
          final defs = GameRepository.instance.stageDefs;
          final cKeys = List<String>.of(mp.clearedChapterCycleKeys);
          for (final k in keys) {
            final parts = k.split('#');
            if (parts.length != 2) continue;
            final def = defs[parts[0]];
            if (def == null || !def.isBossStage) continue;
            final chapterKey =
                (def.stageType == StageType.mainline && def.chapterIndex != null)
                    ? 'ch${def.chapterIndex}'
                    : def.stageType.name;
            final chKey = '$chapterKey#${parts[1]}';
            if (!cKeys.contains(chKey)) cKeys.add(chKey);
          }
          mp.clearedChapterCycleKeys = cKeys;
        }
        await isar.mainlineProgress.put(mp);
      }
      for (final tp in towerRows) {
        tp.currentCycleIndex = 1;
        tp.maxClearedCycle = tp.highestClearedFloor >= 30 ? 1 : 0;
        await isar.towerProgress.put(tp);
      }

      save.saveVersion = _currentSaveVersion;
      await isar.saveDatas.put(save);
    });
  }

  static Future<void> close() async {
    await _instance?.close();
    _instance = null;
  }

  // TODO Phase 5: switchSlot(int newSlotId) — 切换存档槽位
  // TODO Phase 5: listAllSlots() — 存档选择界面用
  // TODO Phase 5: deleteSlot(int slotId) — 删除指定槽位
}
