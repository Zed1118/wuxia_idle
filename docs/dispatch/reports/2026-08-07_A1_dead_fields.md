# A1 · 领域实体「只写不读」字段审计报告

- 执行:pi (DeepSeek V4 Flash) · worktree `pi-deadfield` · 分支 `pi/dead-field-audit`
- 日期:2026-08-07 · 性质:只读审计,**零代码改动**
- 派单:docs/dispatch/2026-08-07_A1.md

## 1. TL;DR

| 维度 | 数值 |
|---|---|
| 扫描领域文件数 | 102(`lib/core/domain/` 21 + `lib/features/*/domain/` 81) |
| 扫描类数 | 102(含 `@collection` / `@embedded` / 普通领域类) |
| 提取实例字段数 | 661(排除 getter / static / 方法内局部变量 / `operator` 等) |
| **只写不读** | **44** |
| **仅 debug/test 读** | **14** |
| 存疑(仅 toString 消费) | 1 |
| 消费侧文件数(全 lib 排除 `*.g.dart`) | 523 |

锚点自校验:`Character.rarity` **已扫出**,见 §5。

## 2. 主表 A · 只写不读(生产零读;44 个)

判定标准:有声明 + 有赋值点,全 `lib/`(排除 `*.g.dart`、`lib/features/debug/`、`test/`)零读取。搜证形态覆盖 `.field` 访问、`==`/`!=` 比较、`field:` 命名参数传递、`fieldEqualTo/sortByField` 等 Isar query 方法、cascade、复合赋值、声明文件内裸名读。

### A1. Isar 实体字段(存库后无人消费)

| 类 | 字段 | 声明 | 赋值点 | 这意味着什么 |
|---|---|---|---|---|
| Character | `rarity` | `lib/core/domain/character.dart:64` | factory `:207`;写死 `RarityTier.biaoZhun` ×3(recruitment_service.dart:99 / sect_recruit_handler.dart:110 / master_builder.dart:53) | **锚点案例**。6 档稀有度概率(numbers.yaml:942)完全不生效;稀有度设计只做了声明+写,读端(显示/派生)没做 |
| Character | `levelExp` | `character.dart:53` | factory `:219` | legacy 兼容字段(和 `level` 配套,但 `level` 有读、`levelExp` 无读);经验展示走 `experience` 体系 |
| Character | `learnedSkillIds` | `character.dart:76` | factory `:227` | 技能系统走 Technique 实体,此列表从未被接线;「已学技能 id 冗余副本」 |
| Character | `isInRetreat` | `character.dart:103` | factory `:235`(恒默认 false) | 闭关状态靠 `RetreatSession` 判定,此标记从未接线(lineup_service.dart:49 注释自认「无写点」) |
| Character | `attributeBonusFromAdventure` | `character.dart:119` | factory `:242`;encounter_service.dart:366(`+=`) | 注释自认 **READ-PENDING**(2026-06-24 审计 D4):奇遇属性点读端待接,功能做了一半 |
| Equipment | `customName` | `equipment.dart:21` | factory `:83` | 装备自定义名从未被 UI 读取,重命名功能未实装 |
| GameEvent | `eventType` | `game_event.dart:15` | game_event_service.dart:86/107/133/170/188/219/240/267 | 事件类型写入但百科事件流 UI 只读 title/summary/occurredAt,类型图标/筛选未做 |
| GameEvent | `relatedCharacterId` | `game_event.dart:20` | game_event_service.dart:93/110/136/173/191/225/243/270 | 事件→角色跳转未接线 |
| GameEvent | `relatedEntityIds` | `game_event.dart:21` | game_event_service.dart:111/137/174/192/244/271 | 事件→实体跳转未接线 |
| GameEvent | `isRead` | `game_event.dart:27` | game_event_service.dart:95/113/139/176/194/227/246/273(全部写 false) | 未读角标功能没做;所有事件恒为未读且无读端 |
| InventoryItem | `lastObtainedAt` | `inventory_item.dart:24` | 25+ 掉落路径写(expedition_service.dart:515、gauntlet_service.dart:338、tower_progress_service.dart:257、offline_passive_service.dart:78、shop_service.dart:70 等) | 获得时间戳从未展示/排序,纯埋点 |
| SaveData | `totalPlaySeconds` | `save_data.dart:44` | **零写点** | 累计在线秒数连写都没有,纯死字段 |
| SaveData | `towerLeaderboardSyncedAt` | `save_data.dart:48` | **零写点** | 排行榜同步时间戳,同步功能未接线 |
| NpcRelation | `updatedAt` | `npc_relation.dart:21` | npc_relation_service.dart:42/47、reputation_service.dart:38/42 | 最后互动时间从未展示 |
| Reputation | `updatedAt` | `reputation.dart:23` | 同上 4 点 | 同上 |
| RetreatSession | `durationHours` | `retreat_session.dart:28` | seclusion_service.dart:184(恒写 0);debug visual_route_host.dart:384/415 | 注释明说「仅保留反序列化兼容」,开放式闭关后废弃 |

> **口径说明**:表内 13 个字段标「零写点」(PvpRecord/PvpSnapshot 共 11 + SaveData.totalPlaySeconds/towerLeaderboardSyncedAt 2 个)——它们连赋值点都没有,比标准「只写不读」更死(声明即全部),按同一档收录并在赋值列如实标注。其余 31 个均有明确生产/构造赋值点。

### A2. PVP 实体(整个子系统未接线)

| 类 | 字段 | 声明 | 赋值点 | 这意味着什么 |
|---|---|---|---|---|
| PvpRecord | `matchId` | `pvp_record.dart:26` | 零写点 | 战绩行主键设计好了,PVP 功能未实装 |
| PvpRecord | `leftSnapshotId` | `pvp_record.dart:36` | 零写点 | 同上 |
| PvpRecord | `opponentSnapshotId` | `pvp_record.dart:33` | 零写点 | 同上 |
| PvpRecord | `winnerId` | `pvp_record.dart:39` | 零写点 | 同上 |
| PvpRecord | `playerEloBefore` | `pvp_record.dart:42` | 零写点 | 同上 |
| PvpRecord | `playerEloAfter` | `pvp_record.dart:45` | 零写点 | 同上 |
| PvpRecord | `eloDelta` | `pvp_record.dart:48` | 零写点 | 同上 |
| PvpRecord | `timestamp` | `pvp_record.dart:51` | 零写点 | 同上(仅 `@Index` 注解存在) |
| PvpSnapshot | `snapshotJson` | `pvp_snapshot.dart:17` | 零写点 | 阵容快照 JSON 从未产生 |
| PvpSnapshot | `snapshotElo` | `pvp_snapshot.dart:20` | 零写点 | 同上 |
| PvpSnapshot | `takenAt` | `pvp_snapshot.dart:23` | 零写点 | 同上 |

两个 `@collection` 实体全字段零写零读,仅 isar_setup.dart 注册 collection。整块 schema 是为未实装功能预留。

### A3. 战斗领域(结算中间产物)

| 类 | 字段 | 声明 | 赋值点 | 这意味着什么 |
|---|---|---|---|---|
| AttackResult | `quakeDamage` | `damage_calculator.dart:376` | 构造 `:309`、默认 `:444` | 克制地震伤害细分字段,UI/日志只读 `finalDamage`,细分值零消费 |
| AttackResult | `realmDiffAttackerMod` | `damage_calculator.dart:388` | 构造 `:313`、默认 `:448` | 境界差系数只入结果不消费(公式分解调试遗留) |
| AttackResult | `realmDiffDefenderMod` | `damage_calculator.dart:391` | 构造 `:314`、默认 `:449` | 同上 |
| AttackResult | `criticalMultiplier` | `damage_calculator.dart:397` | 构造 `:316`、默认 `:451` | 暴击倍率结果只写不读(UI 读 `isCritical` 布尔) |
| AttackResult | `formulaBreakdown` | `damage_calculator.dart:412` | 构造 `:320`、默认 `:455` | 公式分解字符串,疑似 debug 遗留,全库零消费 |
| AttackContext | `defenderEquipped` | `damage_calculator.dart:344` | 构造 `:359` | **传入但从未使用**:防御计算走 `ctx.defender.realmTier` 查表,防御方装备列表未参与任何计算——疑似「防御方装备加成」没实装 |

### A4. 普通领域类(UI 模型/配置)

| 类 | 字段 | 声明 | 赋值点 | 这意味着什么 |
|---|---|---|---|---|
| ExpeditionNode | `durationMinutes` | `expedition_node.dart:14` | expedition_rules.dart:96/114/122 | 节点时长只进 UI 模型,远征结算 `_completedNodesBy` 直接读 yaml 配置,此字段零消费 |
| SweepMaterialHit | `itemId` | `sweep_reward_preview.dart:120` | 同文件构造 | UI 只读 `itemName`/`usages`(stage_list_screen.dart:1759+),itemId 冗余 |
| ActivityOccupancyEntry | `runId` | `activity_occupancy.dart:17` | character_occupancy_service.dart:50 | 活动占用子系统**无 presentation**,全链路只有 service 写 |
| SaveManagementStatus | `databasePath` | `save_management_status.dart:54` | save_management_service.dart:44 | 备份状态对象里路径从未展示 |
| SaveManagementStatus | `backupDirectoryPath` | `save_management_status.dart:55` | save_management_service.dart:44 | 同上 |
| SaveRestoreResult | `selectedBackup` | `save_restore.dart:18` | save_management_service.dart:183 | UI(settings_panel.dart:404)只读 `safetyBackup`,所选备份信息零消费 |
| StagePreparationSummary | `recommended` | `stage_difficulty.dart:30` | assess 工厂 `:44` 等 | 评估结果对象携带输入副本,UI 只读派生值 verdict/focus/realmGap |
| StagePreparationSummary | `playerTier` | `stage_difficulty.dart:31` | assess 工厂 `:45` 等 | 同上 |
| ArchiveClue | `category` | `archive_clue.dart:14` | zangjuange_providers.dart:34/45/54 | 线索三分类枚举写入,UI 只读 title/summary,分类筛选/图标未做 |
| ArchiveClue | `targetKind` | `archive_clue.dart:17` | 构造默认 `:10` | 线索→目标跳转(关卡/塔/战绩册)未接线 |
| ArchiveClue | `targetId` | `archive_clue.dart:18` | 构造默认 null | 同上 |

## 3. 主表 B · 仅 debug/test 读(生产零读;14 个)

| 类 | 字段 | 声明 | 赋值点 | debug/test 读取点 | 这意味着什么 |
|---|---|---|---|---|---|
| AttributeEffectRules | `specialChoiceRequired` | `attribute_effect_policy.dart:26` | 构造 `:56` | debug:encounter_debug_picker.dart:70 | 奇遇特殊选择阈值只在调试器读 |
| Character | `experienceToNextLayer` | `character.dart:47` | 生产 5 点(character_advancement_service.dart:99 等)+ debug 5 点 | test:progression_playtest_fixture.dart:63、progression_battle_probe_test.dart:66 | 注释自认 legacy mirror,生产决策从 RealmDef 派生 |
| SaveData | `totalPassiveMojianshi` | `save_data.dart:100` | offline_passive_service.dart:131、seclusion_service.dart:602 | test:passive_idle_migration_test.dart:30 等 3 文件 | 被动挂机累计只被测试断言 |
| SaveData | `totalPassiveExperience` | `save_data.dart:101` | offline_passive_service.dart:132、seclusion_service.dart:603 | test:同上 | 同上 |
| Technique | `wasMainBeforeReset` | `technique.dart:40` | disperse() `:81`、factory `:70` | test:entities_test.dart:191/216、dispel_service_test.dart:404、phase2_scenarios_test.dart:244 | 散功状态标记,恢复主修读端没做 |
| Technique | `learnedAt` | `technique.dart:41` | 生产 5 点(technique_learn_flow_service.dart:106 等)+ debug 2 点 | test:technique_learning_test.dart:178 | 心法学习时间从未在 UI 展示 |
| AscensionResult | `founderRetired` | `ascension_models.dart:83` | ascend_service.dart:327 | test:ascend_service_test.dart:137 | 升迁结果页只读 transferredCount/promotedDiscipleId |
| AscensionResult | `heritageEquipmentIds` | `ascension_models.dart:86` | ascend_service.dart:328 | test:ascend_service_test.dart:138 | 师承装备清单未展示 |
| AscensionResult | `beneficiaryDiscipleIds` | `ascension_models.dart:89` | ascend_service.dart:331 | test:ascend_service_test.dart:139/301/314/327 | 受益弟子清单未展示 |
| BattleDiagnosis | `ruleId` | `battle_diagnosis.dart:24` | 构造 ×10(`:86` 起各规则) | test:battle_diagnosis_test.dart:201 | 诊断规则机器 id,UI 只用文案,ruleId 零生产消费 |
| RetreatSession | `completedAt` | `retreat_session.dart:39` | seclusion_service.dart:176/187/489/494/726 | test:seclusion_service_test.dart:149/868 | 收功时刻存库,UI 剩余时间用 startedAt 算 |
| RetreatSession | `actualRewards` | `retreat_session.dart:46` | seclusion_service.dart:189/491/496 | test:seclusion_service_test.dart:870/991/1357 | 收功奖励存库,结果页走内存 RetreatResult 对象 |
| TowerProgress | `highestClearedAt` | `tower_progress.dart:30` | tower_progress_service.dart:73/165 | test:tower_progress_service_test.dart:56/245/276 | 首通最高层时间戳,UI 只读 highestClearedFloor |
| AttackResult | `mainDamage` | `damage_calculator.dart:373` | 构造 `:308`、默认 `:443` | debug:redline_audit.dart:352(伤害探针) | 主伤害细分字段,生产只读 finalDamage |

## 4. 存疑节(不强行归档)

| 类 | 字段 | 声明 | 情况 |
|---|---|---|---|
| SaveRestoreException | `cause` | `save_restore.dart:21` | 仅 `toString()` 里插值(`save_restore.dart:35`)消费,生产无其他读取。按派单 §6 判不准(日志/异常消息算不算消费),单列此处。另两个字段 `phase`/`requiresRestart` 有生产读(settings_panel.dart:411),正常 |

## 5. 自校验闸门

**`Character.rarity` 扫出来了没有:有。** 见主表 A1 第一行(character.dart:64;赋值 factory `:207` + 3 处写死 `RarityTier.biaoZhun`)。补充说明:

- 它出现在「只写不读」档,但 test 里有 3 处**断言读**:entities_test.dart:50(Isar round-trip 序列化验证)、progression_battle_probe_test.dart:63(战斗探针)、attribute_role_sensitivity_diagnostic_test.dart:50(诊断工具输出)。按派单口径「只被 debug 读的字段等同于没被读(玩家侧无感)」,这些断言/工具读不构成功能消费,故归档只写不读;debug 侧(phase2_seed_service.dart:697 等 5 点、redline_audit.dart:311)也全是写。
- 方法侧能扫出它的关键:对字段名做**全形态**引用枚举(含 `rarity:` 命名参数、`RarityTier.biaoZhun` 枚举直写),发现全部引用要么是声明/构造、要么是赋值,没有任何 `.rarity` 读取或 query 方法(如 `rarityEqualTo`——已确认全库不存在)。

## 6. 方法节(脚本在 /tmp/a1_audit/,不入仓)

三步管道,纯正则启发式 + 逐字段人工核验:

1. **字段提取**(extract_fields.py):扫描 102 个领域文件,按大括号深度只认类体顶层 `final/late/const X y = …;` 声明;排除 static/getter/setter/operator/方法签名/方法内局部变量。产出 661 字段 `(类, 字段, file:line)`。
2. **全库引用枚举**(refs.py):对 523 个非 `.g.dart` dart 文件逐行词边界匹配字段名,产出全部引用位置。
3. **读/写形态分类**(classify.py + classify_owned.py):
   - 读形态:`.field`(非赋值)、`==/!=/>=/<=` 比较、`fieldEqualTo/sortByField` 等 Isar query 方法、getter 声明、声明文件内裸名引用
   - 写形态:`= ` 赋值、`+=` 等复合赋值、`..field =` cascade、`field:` 命名参数传递
   - **类上下文归属**:`.field` 前对象名必须能在同文件找到 `ClassName obj` 类型声明,否则视为同名污染剔除(`this.x` 只归属声明文件)
   - 排除注释行、`this.x` 构造初始化
4. **人工核验**:71 个自动候选逐字段读全部引用行,剔除 15 个误报(如 AscensionEligibility 5 字段的 `canAscend` getter 裸名读、QiDrainEffect.pct 的 `applyTo` 方法内读、EncounterProgress.attributeGains* 4 字段的 `attributeGainsTotal` getter 累加、SkillUnlockService._isar 私有字段方法内大量使用等),并补入 2 个因字段名通用被污染漏检的 ArchiveClue.category/targetId。

**已知局限**:同名字段(如 `id`/`name`/`itemId`)跨类污染无法完全程序化区分,靠类上下文归属 + 人工核;字段名引用 ≤7 的低引用「正常」字段全部抽查了读点真实性,无漏网证据;`X Function()` 类型字段声明无法被正则提取(本项目未发现)。

## 7. 修法建议(一句话,不实装)

- **删字段(schema 迁移)**:PvpRecord/PvpSnapshot 全实体(未接线)、totalPlaySeconds、towerLeaderboardSyncedAt、durationHours(已注释废弃)、AttackResult 6 细分、formulaBreakdown——纯死重量。
- **接线(功能做了一半)**:rarity(显示或删)、attributeBonusFromAdventure(读端待接)、GameEvent.eventType/isRead/related*、ArchiveClue.category/targetKind/targetId、Equipment.customName、Character.learnedSkillIds/isInRetreat、AttackContext.defenderEquipped(疑似防御加成漏算,需先确认是 bug 还是冗余)。
- **保留待用**:NpcRelation/Reputation.updatedAt、InventoryItem.lastObtainedAt、Technique.learnedAt 等时间戳埋点(低成本,将来排序/展示可能用)。
- 删 Isar 实体字段涉 schema 升版迁移,按派单约定不在本单动。
