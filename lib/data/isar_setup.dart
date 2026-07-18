import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:isar_community/isar.dart';
import 'package:path_provider/path_provider.dart';

import 'game_repository.dart';
import 'isar_restore_paths.dart';
import 'slot_summary.dart';
import '../core/domain/enums.dart';
import '../core/domain/character.dart';
// 分层豁免(2026-07-18 审查批):本文件是 Isar schema 注册表(composition root,
// 同 main.dart 性质),必须 import 全部 feature 的持久化 collection——这些是
// feature 拥有的运行时状态模型(非 yaml def),不适用「data 不依赖 features」约束。
import '../features/battle/domain/enum_localizations.dart';
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
import '../features/battle_record/domain/boss_memory.dart';
import '../features/weapon_codex/domain/equipment_catalog_entry.dart';
import '../features/expedition/domain/expedition_run.dart';
import '../features/boss_gauntlet/domain/boss_gauntlet_run.dart';

/// Isar 初始化与生命周期（data_schema.md §7.1）。
///
/// **多存档槽（1.0 spec B）**：固定 3 槽，多 db 方案——每槽一个独立
/// `wuxia_save_slot{slotId}.isar` 文件，切 db = 切全部数据，无串档。
/// [switchSlot] / [slotHasSave] / [listSlots] / [deleteSlot] 实装见类尾。
/// 启动先进存档选择屏（SaveSelectScreen），选中后 [switchSlot] 开槽。
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

  /// 当前存档 schema 版本（展示/测试用）。
  static String get currentSaveVersion => _currentSaveVersion;

  /// 当前槽位 SaveData（id 固定 0）。init 后必非 null；未 init 时 instance 抛错。
  static Future<SaveData?> currentSaveData() => instance.saveDatas.get(0);

  /// 写当前在线时间戳到 SaveData.lastOnlineAt（M2 范围 B 离线时长基准）。
  /// 由 app lifecycle（main.dart AppLifecycleListener onHide/onInactive/onDetach）
  /// 及 gate「旧档首启不回溯」分支调用；[now] 仅供测试注入。
  /// 未 init / 无存档时安全 no-op。
  static Future<void> touchOnlineNow({DateTime? now}) async {
    final save = await currentSaveData();
    if (save == null) return;
    await instance.writeTxn(() async {
      save.lastOnlineAt = now ?? DateTime.now();
      await instance.saveDatas.put(save);
    });
  }

  static int currentSlotId = 1;

  /// 存档目录记忆(init/switchSlot 时存):供 slot 方法在生产路径复用同一目录,
  /// 不必每次 path_provider 重解析。测试经各方法的可选 `directory` 参数注入覆盖。
  static Directory? _directory;

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
    BossMemorySchema,
    EquipmentCatalogEntrySchema,
    ExpeditionRunSchema,
    BossGauntletRunSchema,
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
  /// PVP 已于 2026-06-27 切除;PvpRecord/PvpSnapshot 仅为旧档 collection 兼容保留,
  /// 生产路径不再读写。
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
  //   autoPlayOverride 当时迁 SharedPreferences(设置≠存档);该逐关覆盖链已于
  //   2026-07-10 退役,入口只读全局 autoPlayDefault。旧 Isar override 不迁移。
  //   无数据迁移动作,仅版本标记 → 0.23.0。
  //   M2 范围 B 被动离线挂机:SaveData 加 totalPassiveMojianshi/totalPassiveExperience
  //   (旧档新 int 字段自动 0,无显式迁移动作,_migrateSaveData 尾部统一落版本号)→ 0.24.0。
  // 第七阶段批三 队伍成长:命名弟子 lineageRole 重映射 + 拜入防重预填 → 0.25.0。
  //   老档(<0.25.0)已由旧 onboarding 种满 3 人队(两弟子 role=disciple)。迁移段 4:
  //   a) founder.discipleIds 顺序前 2 位 disciple → senior/junior(通用收徒弟子不动);
  //   b) 预填全部 join stage id(弟子已在,disciple-join hook 不再触发、不重建)。
  // 段(0.26.0 战绩册):新 BossMemory collection,旧档天然空(正确初始态)。
  // 老档已击败 Boss 的回填骨架在后续 task 由 BossMemoryService.backfillFromProgress 处理,
  // 此处仅 bump 版本号,无 collection 操作。
  //   段(0.27.0 兵器谱):新 EquipmentCatalogEntry collection,旧档天然空。
  //   老档当前持有装备的回填在 reconcileFromInventory 处理(后续 task 接 load 钩子)。
  //   段(0.28.0 F1 里程碑装备授予):SaveData 加 grantedMilestoneEquipmentIds List,
  //   新字段旧档读默认空,无数据迁移动作,仅 bump 版本号。
  // 0.29.0 伤势系统:Character +lightInjuryStacks/injuryHoursRemaining,新字段旧档读默认 0,无迁移分支,仅 bump。
  // 0.30.0 桃花岛:SaveData +islandBuildings/islandLastSettledAt(嵌入 IslandBuildingState),新字段旧档读默认空/null,无迁移分支纯 bump。
  // 0.31.0 曾新增两项角色等级字段；现仅保留旧存档结构兼容，无迁移与运行时消费。
  // 0.32.0 装备锁定:Equipment +isLocked(默认 false),旧档装备均视为未锁定,无迁移分支纯 bump。
  // 0.33.0 祖师开局塑形:Character +founderCreationSchoolId/OriginId/FateId
  // nullable id 字段,旧档为空回退传统纪事,无迁移分支纯 bump。
  // 0.34.0 扫荡战备:SaveData +sweepReadinessPoints/sweepReadinessLastRecoveredAt,
  // nullable 字段旧档由 SweepReadinessService 首读补满,无迁移分支纯 bump。
  // 0.35.0 开放式闭关:RetreatSession +realmTierAtStart(nullable enum),
  // 旧 active session 迁移时以关联角色当前境界固化，startedAt 不动。
  // 0.36.0 内力/真气拆分:Character +innerBreathDisorderHoursRemaining;
  // 旧档永久内力保护性补满上限，心魔余毒迁入内息紊乱。
  // 0.37.0 江湖远行:SaveData +6 永久进度字段(默认空/false)+ ExpeditionRun/
  //   BossGauntletRun 两个空会话 collection(可加性迁移,旧档零 active 记录)。
  static const _currentSaveVersion = '0.37.0';

  /// 打开 Isar 实例。`directory` 可注入用于测试；生产由 path_provider 提供。
  static Future<void> init({
    int slotId = 1,
    Directory? directory,
    bool inspector = true,
  }) async {
    assert(slotId >= 1 && slotId <= 3, 'slotId 必须是 1/2/3');

    final dir = directory ?? await getApplicationDocumentsDirectory();
    _directory = dir;
    await recoverInterruptedRestoreFiles(dir, slotId);
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
    // 迁入前的旧版本(save.saveVersion 在本函数末尾才升到当前)。tower 周目
    // 字段初始化须按此版本判定:0.21.0 才引入,对 0.21+ 存档重跑会把已推进的
    // currentCycleIndex/maxClearedCycle 重置成初值 → 数据丢失。
    final fromVersion = save.saveVersion;

    // 段 1(0.18.0+):encounter 旧 unlock 池并入 skillUnlockProgress。
    final progresses = await isar.encounterProgress.where().findAll();

    // 段 2(0.21.0):周目字段迁移。
    final mainlineRows = await isar.mainlineProgress.where().findAll();
    final towerRows = await isar.towerProgress.where().findAll();
    final activeRetreats = (await isar.retreatSessions.where().findAll())
        .where((s) => s.status == RetreatStatus.active)
        .toList(growable: false);
    final characters = await isar.characters.where().findAll();

    await isar.writeTxn(() async {
      // --- 段 1(0.18.0 · 版本门 <0.18.0)---
      // P0-5(2026-06-29):补版本门。0.18+ 存档旧 unlock 池已并入,不再每次升级
      // 重跑(此前仅靠 markUnlocked 幂等承诺)。markUnlocked 仍幂等,门是防御加固。
      if (_compareVersion(fromVersion, '0.18.0') < 0) {
        save.skillUnlockProgress = List.of(save.skillUnlockProgress);
        for (final p in progresses) {
          for (final sid in p.unlockedSkillIds) {
            save.skillUnlockProgress.markUnlocked(sid);
          }
        }
      }

      // --- 段 2(0.21.0 周目 per-stage key · 版本门 <0.21.0)---
      // P1-10(2026-07-07 体检批5):补版本门。此段与 tower 段(同 0.21.0 引入)
      // 一致,0.21+ 存档周目键已建,不再每次 saveVer bump 用退役的 clearedStageIds
      // 快照重跑 "#1" 回填(否则污染周目首通判定)。<0.21.0 旧档仍一次性回填。
      for (final mp in mainlineRows) {
        final keys = List<String>.of(mp.clearedStageCycleKeys);
        if (_compareVersion(fromVersion, '0.21.0') < 0) {
          for (final stageId in mp.clearedStageIds) {
            final key = '$stageId#1';
            if (!keys.contains(key)) {
              keys.add(key);
            }
          }
        }
        mp.clearedStageCycleKeys = keys;
        // 段 3(0.22.0 周目按章 · 版本门 <0.22.0):旧 per-stage cycle key 中的章末
        // Boss 关(isBoss)→ per-chapter cycle key "chapterKey#cycle"。chapterKey
        // 逻辑须与 MainlineProgressService.chapterKeyForStage 同步。
        // P0-5(2026-06-29):补版本门。0.22+ 存档章 key 已建,不再每次升级重跑,
        // 也不再对 0.22+ 存档依赖「splash 先 loadAllDefs 再 init」的隐式启动顺序
        // 契约(GameRepository.isLoaded)。仅 <0.22.0 旧档需重建,且仍要 isLoaded
        // (未加载时跳过,玩家重打 Boss 时重建)。
        if (_compareVersion(fromVersion, '0.22.0') < 0 &&
            GameRepository.isLoaded) {
          final defs = GameRepository.instance.stageDefs;
          final cKeys = List<String>.of(mp.clearedChapterCycleKeys);
          for (final k in keys) {
            final parts = k.split('#');
            if (parts.length != 2) continue;
            final def = defs[parts[0]];
            if (def == null || !def.isBossStage) continue;
            final chapterKey =
                (def.stageType == StageType.mainline &&
                    def.chapterIndex != null)
                ? 'ch${def.chapterIndex}'
                : def.stageType.name;
            final chKey = '$chapterKey#${parts[1]}';
            if (!cKeys.contains(chKey)) cKeys.add(chKey);
          }
          mp.clearedChapterCycleKeys = cKeys;
        }
        await isar.mainlineProgress.put(mp);
      }
      // tower 周目字段 0.21.0 引入 → 仅对 0.21.0 之前的旧档做一次性初始化。
      // 0.21+ 存档的周目字段已是真实进度,不得重置(H1 数据丢失修复)。
      if (_compareVersion(fromVersion, '0.21.0') < 0) {
        for (final tp in towerRows) {
          tp.currentCycleIndex = 1;
          tp.maxClearedCycle = tp.highestClearedFloor >= 30 ? 1 : 0;
          await isar.towerProgress.put(tp);
        }
      }

      // --- 段 4(0.25.0 队伍成长):命名弟子 role 重映射 + 拜入防重预填 ---
      // 老档(<0.25.0)均由旧 onboarding 种满队,故:
      //   a) founder.discipleIds 顺序前 2 位 disciple → senior/junior
      //      (通用收徒弟子,即不在 discipleIds 里的,不动;仅 role==disciple 时改,
      //       已 senior/junior 不回写 → 幂等);
      //   b) 预填全部 join stage id(弟子已在,disciple-join hook 不再触发、不重建)。
      if (_compareVersion(fromVersion, '0.25.0') < 0) {
        // 先按 founderCharacterId 取 founder,缺失则扫 isFounder(防御性)。
        Character? founder;
        if (save.founderCharacterId != null) {
          founder = await isar.characters.get(save.founderCharacterId!);
        }
        if (founder == null) {
          final all = await isar.characters.where().findAll();
          for (final c in all) {
            if (c.isFounder) {
              founder = c;
              break;
            }
          }
        }
        if (founder != null) {
          // i<2:命名弟子只有 senior+junior 两位,余者(若有)保持原 role,不重映射。
          for (var i = 0; i < founder.discipleIds.length && i < 2; i++) {
            final d = await isar.characters.get(founder.discipleIds[i]);
            if (d == null || d.lineageRole != LineageRole.disciple) continue;
            d.lineageRole = i == 0 ? LineageRole.senior : LineageRole.junior;
            await isar.characters.put(d);
          }
        }
        // GameRepository 未加载(理论不会:splash 先 loadAllDefs 再 init)→ 跳过预填,
        // 弟子仍在故 hook 不会重建,只是 triggered 集合保持空(不影响正确性)。
        if (GameRepository.isLoaded) {
          final joinIds =
              GameRepository.instance.numbers.lineageOnboarding.joinStageIds;
          final cur = List<String>.of(save.triggeredDiscipleJoinStageIds);
          for (final id in joinIds) {
            if (!cur.contains(id)) cur.add(id);
          }
          save.triggeredDiscipleJoinStageIds = cur;
        }
      }

      // --- 段 5(0.35.0 开放式闭关):active session 固化境界快照 ---
      if (_compareVersion(fromVersion, '0.35.0') < 0) {
        for (final session in activeRetreats) {
          if (session.realmTierAtStart != null) continue;
          Character? linked;
          for (final character in characters) {
            if (character.currentRetreatSessionId == session.id) {
              linked = character;
              break;
            }
          }
          if (linked == null && save.founderCharacterId != null) {
            for (final character in characters) {
              if (character.id == save.founderCharacterId) {
                linked = character;
                break;
              }
            }
          }
          session.realmTierAtStart = linked?.realmTier ?? RealmTier.xueTu;
          await isar.retreatSessions.put(session);
        }
      }

      // --- 段 6(0.36.0 内力/真气拆分)---
      if (_compareVersion(fromVersion, '0.36.0') < 0) {
        for (final character in characters) {
          // 前置迁移段可能已写回同一角色（如 0.25 师徒 role 重映射），
          // 必须重读当前行，避免用事务前快照覆盖前置迁移结果。
          final current = await isar.characters.get(character.id) ?? character;
          current.internalForce = current.internalForceMax;
          if (current.innerDemonResidueHoursRemaining >
              current.innerBreathDisorderHoursRemaining) {
            current.innerBreathDisorderHoursRemaining =
                current.innerDemonResidueHoursRemaining;
          }
          current.innerDemonResidueHoursRemaining = 0;
          await isar.characters.put(current);
        }
      }

      // --- 段 7(0.37.0 江湖远行)---
      // SaveData 新字段为可加性(List/bool/DateTime? 均有默认),旧档 load 时 Isar
      // 自动取 Dart 字段初值,无需显式回填;两新 collection 旧档初始为空。此段仅作
      // 幂等占位与版本文档锚,真正落版本号由本函数尾部统一执行。
      if (_compareVersion(fromVersion, '0.37.0') < 0) {
        // 无显式迁移动作(纯可加)。
      }

      save.saveVersion = _currentSaveVersion;
      await isar.saveDatas.put(save);
    });
  }

  /// 语义化版本比较(major.minor.patch)。a<b 返 -1,a==b 返 0,a>b 返 1。
  /// 用于迁移分段的版本门(字符串比较对 '0.9'/'0.21' 会错序,故按数值比)。
  static int _compareVersion(String a, String b) {
    final pa = a.split('.');
    final pb = b.split('.');
    for (var i = 0; i < 3; i++) {
      final na = i < pa.length ? int.tryParse(pa[i]) ?? 0 : 0;
      final nb = i < pb.length ? int.tryParse(pb[i]) ?? 0 : 0;
      final c = na.compareTo(nb);
      if (c != 0) return c;
    }
    return 0;
  }

  static Future<void> close() async {
    await _instance?.close();
    _instance = null;
  }

  /// 校验恢复候选副本。候选是历史备份的临时副本，校验可升级其 Isar schema，
  /// 但不会修改原始备份文件。
  static Future<void> validateRestoreCandidate({
    required String candidatePath,
    required int expectedSlotId,
  }) async {
    final file = File(candidatePath);
    if (!await file.exists() || await file.length() == 0) {
      throw StateError('恢复候选文件不存在或为空');
    }
    final fileName = file.uri.pathSegments.last;
    if (!fileName.endsWith('.isar')) {
      throw StateError('恢复候选文件扩展名无效');
    }
    final name = fileName.substring(0, fileName.length - '.isar'.length);
    if (Isar.getInstance(name) != null) {
      throw StateError('恢复候选数据库已打开');
    }

    Isar? candidate;
    try {
      candidate = await Isar.open(
        _allSchemas,
        directory: file.parent.path,
        name: name,
        inspector: false,
      );
      final save = await candidate.saveDatas.get(0);
      if (save == null) throw StateError('恢复候选缺少 SaveData');
      if (save.slotId != expectedSlotId) {
        throw StateError('恢复候选槽位不匹配');
      }
      if (_compareVersion(save.saveVersion, _currentSaveVersion) > 0) {
        throw StateError('恢复候选版本高于当前程序');
      }
      final founderId = save.founderCharacterId;
      final founder = founderId == null
          ? null
          : await candidate.characters.get(founderId);
      if (founder == null || !founder.isFounder) {
        throw StateError('恢复候选缺少祖师记录');
      }
    } finally {
      await candidate?.close();
      final lock = File('$candidatePath.lock');
      if (await lock.exists()) await lock.delete();
    }
  }

  /// 启动前修复被进程中断的恢复现场。正式档存在时以正式档为准；正式档缺失
  /// 时优先回滚到恢复前版本，只有没有 rollback 才提升完整 candidate。
  static Future<void> recoverInterruptedRestoreFiles(
    Directory directory,
    int slotId,
  ) async {
    final paths = IsarRestorePaths(directory, slotId);
    await _deleteIfExists(paths.partial);

    if (await paths.current.exists()) {
      await _deleteIfExists(paths.candidate);
      await _deleteIfExists(paths.rollback);
    } else if (await paths.rollback.exists()) {
      await _deleteIfExists(paths.candidate);
      await paths.rollback.rename(paths.current.path);
    } else if (await paths.candidate.exists()) {
      await paths.candidate.rename(paths.current.path);
    }

    await _deleteIfExists(File('${paths.candidate.path}.lock'));
    await _deleteIfExists(File('${paths.rollback.path}.lock'));
  }

  static Future<void> _deleteIfExists(File file) async {
    if (await file.exists()) await file.delete();
  }

  // ── 多存档槽(1.0 spec B · 固定 3 槽 · 多 db 方案)───────────────────────

  /// 解析存档目录(记忆优先,生产兜底 path_provider)。
  static Future<Directory> _resolveDir(Directory? directory) async =>
      directory ?? _directory ?? await getApplicationDocumentsDirectory();

  /// 原子切档:flush 当前(结算离线基准)→ close → open 新槽 → set currentSlotId。
  /// provider 刷新由调用点 `ref.invalidate(isarProvider)` 负责(本方法 static 无 ref)。
  static Future<void> switchSlot(int n, {Directory? directory}) async {
    assert(n >= 1 && n <= 3, 'slotId 必须是 1/2/3');
    if (_instance != null) {
      await touchOnlineNow(); // flush:落最后在线时间,结算离线计时基准
      await close();
    }
    await init(slotId: n, directory: await _resolveDir(directory));
  }

  /// 该槽是否有存档(db 文件存在且含 founder)。当前已打开槽直接读不重开。
  static Future<bool> slotHasSave(int n, {Directory? directory}) async {
    final dir = await _resolveDir(directory);
    final name = 'wuxia_save_slot$n';
    if (!await File('${dir.path}/$name.isar').exists()) return false;
    final already = Isar.getInstance(name);
    final isar =
        already ??
        await Isar.open(
          _allSchemas,
          directory: dir.path,
          name: name,
          inspector: false,
        );
    try {
      return await isar.characters.filter().isFounderEqualTo(true).count() > 0;
    } finally {
      if (already == null) await isar.close(); // 只关临时开的,不关当前槽
    }
  }

  /// 遍历 1..3 槽读轻量摘要(选择屏用)。当前已打开槽直接读不重开;临时只读
  /// 实例读完即 close(spec §4 防句柄泄漏)。
  static Future<List<SlotSummary>> listSlots({Directory? directory}) async {
    final dir = await _resolveDir(directory);
    final out = <SlotSummary>[];
    for (var n = 1; n <= 3; n++) {
      final name = 'wuxia_save_slot$n';
      if (!await File('${dir.path}/$name.isar').exists()) {
        out.add(SlotSummary.empty(n));
        continue;
      }
      final already = Isar.getInstance(name);
      final isar =
          already ??
          await Isar.open(
            _allSchemas,
            directory: dir.path,
            name: name,
            inspector: false,
          );
      try {
        out.add(await _readSummary(isar, n));
      } finally {
        if (already == null) await isar.close();
      }
    }
    DateTime? mostRecent;
    for (final s in out) {
      if (s.isEmpty || s.lastPlayed == null) continue;
      if (mostRecent == null || s.lastPlayed!.isAfter(mostRecent)) {
        mostRecent = s.lastPlayed;
      }
    }
    if (mostRecent == null) return out;
    return [
      for (final s in out)
        s.copyWith(isMostRecent: !s.isEmpty && s.lastPlayed == mostRecent),
    ];
  }

  static Future<SlotSummary> _readSummary(Isar isar, int n) async {
    final save = await isar.saveDatas.get(0);
    final founderId = save?.founderCharacterId;
    final founder = founderId == null
        ? null
        : await isar.characters.get(founderId);
    if (founder == null) return SlotSummary.empty(n);
    final mp = await isar.mainlineProgress
        .filter()
        .saveDataIdEqualTo(n)
        .findFirst();
    final tp = await isar.towerProgress
        .filter()
        .saveDataIdEqualTo(n)
        .findFirst();
    return SlotSummary(
      slotId: n,
      isEmpty: false,
      slotName: save?.slotName?.trim().isEmpty == true
          ? null
          : save?.slotName?.trim(),
      founderName: founder.name,
      realmDisplay: EnumL10n.realm(founder.realmTier, founder.realmLayer),
      chapterIndex: mp?.currentChapterIndex ?? 1,
      clearedStageCount: mp?.clearedStageIds.length ?? 0,
      completedFirstCycle:
          mp?.clearedStageCycleKeys.contains('stage_06_05#1') == true ||
          mp?.clearedStageIds.contains('stage_06_05') == true,
      highestTowerFloor:
          tp?.highestClearedFloor ?? save?.highestTowerLayer ?? 0,
      lastPlayed: save?.lastOnlineAt,
    );
  }

  /// 重命名存档槽。复用 SaveData.slotName 既有字段,空白视为清除自定义名。
  static Future<void> renameSlot(
    int n,
    String rawName, {
    Directory? directory,
  }) async {
    assert(n >= 1 && n <= 3, 'slotId 必须是 1/2/3');
    final dir = await _resolveDir(directory);
    final name = 'wuxia_save_slot$n';
    if (!await File('${dir.path}/$name.isar').exists()) return;
    final already = Isar.getInstance(name);
    final isar =
        already ??
        await Isar.open(
          _allSchemas,
          directory: dir.path,
          name: name,
          inspector: false,
        );
    try {
      final save = await isar.saveDatas.get(0);
      if (save == null) return;
      final trimmed = rawName.trim();
      await isar.writeTxn(() async {
        save.slotName = trimmed.isEmpty ? null : trimmed;
        save.lastSavedAt = DateTime.now();
        await isar.saveDatas.put(save);
      });
    } finally {
      if (already == null) await isar.close();
    }
  }

  /// 删除指定槽 db(若为当前槽先 close → 实例置空)+ 删 .isar/.isar.lock 文件。
  /// 删当前档后 [instanceOrNull] 变 null,调用点须回选择屏(spec §4)。
  static Future<void> deleteSlot(int n, {Directory? directory}) async {
    final dir = await _resolveDir(directory);
    final name = 'wuxia_save_slot$n';
    if (currentSlotId == n && _instance != null) {
      await close();
    } else {
      final open = Isar.getInstance(name);
      if (open != null) await open.close();
    }
    for (final ext in ['.isar', '.isar.lock']) {
      final f = File('${dir.path}/$name$ext');
      if (await f.exists()) await f.delete();
    }
  }

  /// 测试复位:清实例 + 目录记忆 + currentSlotId(各测 setUp/tearDown 纯净起点)。
  @visibleForTesting
  static void resetForTest() {
    _instance = null;
    _directory = null;
    currentSlotId = 1;
  }
}
