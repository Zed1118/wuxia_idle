#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Q2/A1 审计结论锚点表(2026-08-07 报告固化)

本文件不做任何判定,只是把两份报告的主表逐条落成机器可读数据,
供 run_all.py 对当前代码做复验:

  - Q2_ANCHORS:三组计数(8 背离 confirmed / 7 部分背离 / 21 休眠)。
    每条含 properties(强类型配置属性,grep `.prop\b` 业务侧须零读)
    与 anchors(报告列举的硬编码/结构性证据,须仍在)。
  - A1_TABLE_A / A1_TABLE_B:44 只写不读 / 14 仅 debug-test 读字段
    的 (类, 字段, 声明文件) 清单。

判定口径与原报告一致(Q2 §三/四/五判据、A1 §2/§3 判定标准),
run_all.py 只复验"结论是否仍成立",不重新审计。
"""

# ---------------------------------------------------------------------------
# Q2 · 背离(confirmed)主表 · 报告值 8
# holds 判据:properties 全部业务侧零读 AND anchors 全部仍在
# ---------------------------------------------------------------------------
Q2_CONFIRMED = [
    {
        "id": "B1",
        "title": "character.rarity_distribution 六档稀有度概率整段失效",
        "properties": ["rarity"],  # 审计时 .rarity 业务侧零读;稀有度收口后应出现读点
        "anchors": [
            # 三个创角/收徒路径写死 RarityTier.biaoZhun(收口后应改为 rarityForTotalPoints 派生)
            ("lib/features/recruitment/application/recruitment_service.dart",
             r"rarity:\s*RarityTier\.biaoZhun"),
            ("lib/features/sect/presentation/sect_recruit_handler.dart",
             r"rarity:\s*RarityTier\.biaoZhun"),
            ("lib/features/onboarding/application/master_builder.dart",
             r"rarity:\s*RarityTier\.biaoZhun"),
        ],
        "yaml": "data/numbers.yaml:character.rarity_distribution",
    },
    {
        "id": "B2",
        "title": "boss_gauntlets.supply_cap 补给上限双重写死",
        "properties": ["supplyCap"],
        "anchors": [
            ("lib/features/boss_gauntlet/presentation/gauntlet_loadout_screen.dart",
             r"static const int _supplyCap = 3"),
            ("lib/data/defs/boss_gauntlet_config.dart",
             r"if \(supplyCap != 3\)"),
        ],
        "yaml": "data/boss_gauntlets.yaml:supply_cap",
    },
    {
        "id": "B3",
        "title": "sect_recruit.stage_boss_recruit_prob 被 Dart 字面量顶替",
        "properties": ["stageBossRecruitProb"],
        "anchors": [
            ("lib/data/defs/stage_def.dart", r"this\.baseProbability = 0\.40"),
            ("lib/data/defs/stage_def.dart", r"\?\? 0\.40"),
        ],
        "yaml": "data/numbers.yaml:sect_recruit.stage_boss_recruit_prob",
    },
    {
        "id": "B4",
        "title": "masters.enabledInDemo 零读取,按数组下标 seed",
        "properties": ["enabledInDemo"],
        "anchors": [
            ("lib/features/onboarding/application/onboarding_service.dart",
             r"masters\[0\]"),
            ("lib/data/validation/lineage_recruit_red_lines_validator.dart",
             r"masters\.length != 3"),
        ],
        "yaml": "data/masters.yaml:enabledInDemo",
    },
    {
        "id": "B5",
        "title": "inheritance.heritage_items.transfer_trigger 仅飞升触发写死",
        "properties": ["transferTrigger"],
        "anchors": [
            ("lib/features/ascension/application/ascend_service.dart",
             r"inheritFrom\(founderId"),
        ],
        "yaml": "data/numbers.yaml:inheritance.heritage_items.transfer_trigger",
    },
    {
        "id": "B6",
        "title": "inheritance.heritage_items.multi_disciple_allocation player_pick 写死 UI",
        "properties": ["multiDiscipleAllocation"],
        "anchors": [
            ("lib/features/ascension/presentation/ascension_screen.dart",
             r"DropdownButton"),
        ],
        "yaml": "data/numbers.yaml:inheritance.heritage_items.multi_disciple_allocation",
    },
    {
        "id": "B7",
        "title": "inheritance.heritage_items.stack_across_generations 按件数写死",
        "properties": ["stackAcrossGenerations"],
        "anchors": [
            ("lib/features/battle/domain/derived_stats.dart",
             r"isLineageHeritage"),
        ],
        "yaml": "data/numbers.yaml:inheritance.heritage_items.stack_across_generations",
    },
    {
        "id": "B8",
        "title": "inheritance.heritage_items.conflict_slot_resolution auto_swap 无条件",
        "properties": ["conflictSlotResolution"],
        "anchors": [
            ("lib/features/ascension/application/ascend_service.dart",
             r"conflict_slot_resolution"),
        ],
        "yaml": "data/numbers.yaml:inheritance.heritage_items.conflict_slot_resolution",
    },
]

# ---------------------------------------------------------------------------
# Q2 · 部分背离主表 · 报告值 7 字段 / 3 组
# holds 判据:子字段 properties 业务侧零读(配置对象其他子字段仍被读)
# ---------------------------------------------------------------------------
Q2_PARTIAL = [
    {
        "id": "P1",
        "title": "retreat.zhengWu.target_attribute 目标维度写死",
        "properties": ["zhengWuTargetAttribute"],
        "yaml": "data/numbers.yaml:retreat.zheng_wu.target_attribute",
    },
    {
        "id": "P2a",
        "title": "gang_meng_quake.pierces_defense 语义结构性写死",
        "properties": ["piercesDefense"],
        "yaml": "data/numbers.yaml:combat.school_counter.gang_meng_quake.pierces_defense",
    },
    {
        "id": "P2b",
        "title": "gang_meng_quake.pierces_critical 语义结构性写死",
        "properties": ["piercesCritical"],
        "yaml": "data/numbers.yaml:combat.school_counter.gang_meng_quake.pierces_critical",
    },
    {
        "id": "P2c",
        "title": "gang_meng_quake.follows_main_hit 语义结构性写死",
        "properties": ["followsMainHit"],
        "yaml": "data/numbers.yaml:combat.school_counter.gang_meng_quake.follows_main_hit",
    },
    {
        "id": "P3a",
        "title": "yin_rou_internal_injury.pierces_defense dot 直扣写死",
        "properties": ["piercesDefense"],
        "yaml": "data/numbers.yaml:combat.school_counter.yin_rou_internal_injury.pierces_defense",
    },
    {
        "id": "P3b",
        "title": "yin_rou_internal_injury.stack_rule refresh 结构性写死",
        "properties": ["stackRule"],
        "yaml": "data/numbers.yaml:combat.school_counter.yin_rou_internal_injury.stack_rule",
    },
    {
        "id": "P3c",
        "title": "yin_rou_internal_injury.follows_main_hit 写死",
        "properties": ["followsMainHit"],
        "yaml": "data/numbers.yaml:combat.school_counter.yin_rou_internal_injury.follows_main_hit",
    },
]

# ---------------------------------------------------------------------------
# Q2 · 休眠配置(形态 4:loader 解析但零 caller)· 报告值 21(+1 预留不计)
# holds 判据:属性业务侧零读 AND loader 仍解析该属性
# ---------------------------------------------------------------------------
Q2_DORMANT = [
    {"id": "D1",  "prop": "maxDamageMultiplier",          "loader": "lib/data/numbers_config.dart"},
    {"id": "D2",  "prop": "chainRecoveryPct",             "loader": "lib/data/numbers_config.dart"},
    {"id": "D3",  "prop": "internalForceMultiplier",      "loader": "lib/data/defs/inner_demon_def.dart"},
    {"id": "D4",  "prop": "internalForceFloorPct",        "loader": "lib/data/defs/inner_demon_def.dart"},
    {"id": "D5",  "prop": "subCultivationMultiplier",     "loader": "lib/data/defs/inner_demon_def.dart"},
    {"id": "D6",  "prop": "debuffId",                     "loader": "lib/data/defs/inner_demon_def.dart"},
    {"id": "D7",  "prop": "debuffClearViaRetreatHours",   "loader": "lib/data/defs/inner_demon_def.dart"},
    {"id": "D8",  "prop": "encounterBaseProb",            "loader": "lib/data/numbers_config.dart"},
    {"id": "D9",  "prop": "encounterNpcDeltaMin",         "loader": "lib/data/numbers_config.dart"},
    {"id": "D10", "prop": "encounterNpcDeltaMax",         "loader": "lib/data/numbers_config.dart"},
    {"id": "D11", "prop": "enemyAttackPowerMult",         "loader": "lib/data/numbers_config.dart"},
    {"id": "D12", "prop": "demoInitialCount",             "loader": "lib/data/numbers_config.dart"},
    {"id": "D13", "prop": "stageTerrain",                 "loader": "lib/data/defs/light_foot_def.dart"},
    {"id": "D14", "prop": "towerLayer",                   "loader": "lib/data/defs/stage_def.dart"},
    {"id": "D15", "prop": "npcIds",                       "loader": "lib/data/defs/faction_def.dart"},
    {"id": "D16", "prop": "initialOwnerSectId",           "loader": "lib/data/defs/territory_def.dart"},
    {"id": "D17", "prop": "readableVictoryMinMs",         "loader": "lib/data/numbers_config.dart"},
    {"id": "D18", "prop": "shakeOffsetPx",                "loader": "lib/data/numbers_config.dart"},
    {"id": "D19", "prop": "cultivationProgressPct",       "loader": "lib/data/numbers_config.dart"},
    {"id": "D20", "prop": "speedBonus",                   "loader": "lib/data/defs/technique_def.dart"},
    {"id": "D21", "prop": "internalForceGrowthBonus",     "loader": "lib/data/defs/technique_def.dart"},
]
# 报告中的 +1 预留(不计入 21):SectCandidateDef.targetSectId
Q2_DORMANT_RESERVED = {"prop": "targetSectId", "loader": "lib/data/defs/sect_candidate_def.dart"}

# ---------------------------------------------------------------------------
# A1 · 主表 A 只写不读 · 报告值 44
# A1 §A1 口径:全 lib(排除 *.g.dart、features/debug、test)零读取
# ---------------------------------------------------------------------------
A1_TABLE_A = [
    ("Character", "rarity", "lib/core/domain/character.dart"),
    ("Character", "levelExp", "lib/core/domain/character.dart"),
    ("Character", "learnedSkillIds", "lib/core/domain/character.dart"),
    ("Character", "isInRetreat", "lib/core/domain/character.dart"),
    ("Character", "attributeBonusFromAdventure", "lib/core/domain/character.dart"),
    ("Equipment", "customName", "lib/core/domain/equipment.dart"),
    ("GameEvent", "eventType", "lib/core/domain/game_event.dart"),
    ("GameEvent", "relatedCharacterId", "lib/core/domain/game_event.dart"),
    ("GameEvent", "relatedEntityIds", "lib/core/domain/game_event.dart"),
    ("GameEvent", "isRead", "lib/core/domain/game_event.dart"),
    ("InventoryItem", "lastObtainedAt", "lib/core/domain/inventory_item.dart"),
    ("SaveData", "totalPlaySeconds", "lib/core/domain/save_data.dart"),
    ("SaveData", "towerLeaderboardSyncedAt", "lib/core/domain/save_data.dart"),
    ("NpcRelation", "updatedAt", "lib/features/jianghu/domain/npc_relation.dart"),
    ("Reputation", "updatedAt", "lib/features/jianghu/domain/reputation.dart"),
    ("RetreatSession", "durationHours", "lib/features/seclusion/domain/retreat_session.dart"),
    ("PvpRecord", "matchId", "lib/features/pvp/domain/pvp_record.dart"),
    ("PvpRecord", "leftSnapshotId", "lib/features/pvp/domain/pvp_record.dart"),
    ("PvpRecord", "opponentSnapshotId", "lib/features/pvp/domain/pvp_record.dart"),
    ("PvpRecord", "winnerId", "lib/features/pvp/domain/pvp_record.dart"),
    ("PvpRecord", "playerEloBefore", "lib/features/pvp/domain/pvp_record.dart"),
    ("PvpRecord", "playerEloAfter", "lib/features/pvp/domain/pvp_record.dart"),
    ("PvpRecord", "eloDelta", "lib/features/pvp/domain/pvp_record.dart"),
    ("PvpRecord", "timestamp", "lib/features/pvp/domain/pvp_record.dart"),
    ("PvpSnapshot", "snapshotJson", "lib/features/pvp/domain/pvp_snapshot.dart"),
    ("PvpSnapshot", "snapshotElo", "lib/features/pvp/domain/pvp_snapshot.dart"),
    ("PvpSnapshot", "takenAt", "lib/features/pvp/domain/pvp_snapshot.dart"),
    ("AttackResult", "quakeDamage", "lib/features/battle/domain/damage_calculator.dart"),
    ("AttackResult", "realmDiffAttackerMod", "lib/features/battle/domain/damage_calculator.dart"),
    ("AttackResult", "realmDiffDefenderMod", "lib/features/battle/domain/damage_calculator.dart"),
    ("AttackResult", "criticalMultiplier", "lib/features/battle/domain/damage_calculator.dart"),
    ("AttackResult", "formulaBreakdown", "lib/features/battle/domain/damage_calculator.dart"),
    ("AttackContext", "defenderEquipped", "lib/features/battle/domain/damage_calculator.dart"),
    ("ExpeditionNode", "durationMinutes", "lib/features/expedition/domain/expedition_node.dart"),
    ("SweepMaterialHit", "itemId", "lib/features/sweep/domain/sweep_reward_preview.dart"),
    ("ActivityOccupancyEntry", "runId", "lib/features/activity/domain/activity_occupancy.dart"),
    ("SaveManagementStatus", "databasePath", "lib/features/save_management/domain/save_management_status.dart"),
    ("SaveManagementStatus", "backupDirectoryPath", "lib/features/save_management/domain/save_management_status.dart"),
    ("SaveRestoreResult", "selectedBackup", "lib/features/save_management/domain/save_restore.dart"),
    ("StagePreparationSummary", "recommended", "lib/features/loot_preview/domain/stage_difficulty.dart"),
    ("StagePreparationSummary", "playerTier", "lib/features/loot_preview/domain/stage_difficulty.dart"),
    ("ArchiveClue", "category", "lib/features/zangjuange/domain/archive_clue.dart"),
    ("ArchiveClue", "targetKind", "lib/features/zangjuange/domain/archive_clue.dart"),
    ("ArchiveClue", "targetId", "lib/features/zangjuange/domain/archive_clue.dart"),
]

# ---------------------------------------------------------------------------
# A1 · 主表 B 仅 debug/test 读(生产零读)· 报告值 14
# 第 4 项:报告 §3 引证的 debug/test 读取点文件(复验兜底证据)
# ---------------------------------------------------------------------------
A1_TABLE_B = [
    ("AttributeEffectRules", "specialChoiceRequired",
     "lib/core/domain/attribute_effect_policy.dart",
     ["lib/features/debug/presentation/encounter_debug_picker.dart"]),
    ("Character", "experienceToNextLayer", "lib/core/domain/character.dart",
     ["test/support/progression_playtest_fixture.dart",
      "test/support/progression_battle_probe_test.dart"]),
    ("SaveData", "totalPassiveMojianshi", "lib/core/domain/save_data.dart",
     ["test/data/passive_idle_migration_test.dart",
      "test/features/seclusion/application/offline_passive_settle_test.dart"]),
    ("SaveData", "totalPassiveExperience", "lib/core/domain/save_data.dart",
     ["test/data/passive_idle_migration_test.dart",
      "test/features/seclusion/application/offline_passive_settle_test.dart"]),
    ("Technique", "wasMainBeforeReset", "lib/core/domain/technique.dart",
     ["test/core/domain/entities_test.dart",
      "test/features/dispel/application/dispel_service_test.dart",
      "test/features/debug/application/phase2_scenarios_test.dart"]),
    ("Technique", "learnedAt", "lib/core/domain/technique.dart",
     ["test/features/cultivation/application/technique_learning_test.dart"]),
    ("AscensionResult", "founderRetired",
     "lib/features/ascension/domain/ascension_models.dart",
     ["test/features/ascension/application/ascend_service_test.dart"]),
    ("AscensionResult", "heritageEquipmentIds",
     "lib/features/ascension/domain/ascension_models.dart",
     ["test/features/ascension/application/ascend_service_test.dart"]),
    ("AscensionResult", "beneficiaryDiscipleIds",
     "lib/features/ascension/domain/ascension_models.dart",
     ["test/features/ascension/application/ascend_service_test.dart"]),
    ("BattleDiagnosis", "ruleId", "lib/features/battle/domain/battle_diagnosis.dart",
     ["test/features/battle/battle_diagnosis_test.dart"]),
    ("RetreatSession", "completedAt", "lib/features/seclusion/domain/retreat_session.dart",
     ["test/features/seclusion/application/seclusion_service_test.dart"]),
    ("RetreatSession", "actualRewards", "lib/features/seclusion/domain/retreat_session.dart",
     ["test/features/seclusion/application/seclusion_service_test.dart"]),
    ("TowerProgress", "highestClearedAt", "lib/features/tower/domain/tower_progress.dart",
     ["test/features/tower/application/tower_progress_service_test.dart"]),
    ("AttackResult", "mainDamage", "lib/features/battle/domain/damage_calculator.dart",
     ["lib/features/debug/application/redline_audit.dart"]),
]

# A1 · 存疑(不计入 44/14):SaveRestoreException.cause 仅 toString 消费
A1_DOUBTFUL = [("SaveRestoreException", "cause", "lib/features/save_management/domain/save_restore.dart")]
