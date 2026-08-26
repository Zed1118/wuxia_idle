# Phase 2 N6 死字段 / 零引用清账（2026-08-26）

- 基线：`6ab440260318100032e484c904cad9f46c4ca6c1`；分支：`codex/p2-n6-deadfield-20260826`。性质：只读审计，本文不执行删除/接线。
- 口径：扫描 `data/**/*.yaml` 677 文件；领域底座 128 文件 / 251 类 / 1,239 实例字段，另扫 getter；运行资产 697 件（排除 `.gitkeep` / `assets/README.md`）。
- 存在性复核：YAML 逐键查真实 `snake_case`、loader `camelCase`、`y['key']` / `Map.entries` / enum `.name` / ID-map / 字符串插值；领域查 `.field`、声明文件裸名读、构造/命名参数、cascade/复合赋值、等值/hash、`fieldEqualTo` / `sortByField`与 test/debug。`git grep -E` 只用 `[[:space:]]`，未用 `\s`。
- 动态路径复核：还原 105 文案、21 章回封面、30 音频、13 物品图，也查了 `chapterCoverPath` / `bgmAssetPath` / `sfxAssetPath` / `battleHitAssetPath` 和 `assets/items/$id.png`。表内每组均单独跑过 `git log -S '<表内标识符>'`并读定义附近注释；组合行对组内各键/字段分别查历史。

## 1. YAML 配置字段（`data/**` 定义，`lib/` 不消费）

| 标识符 | 定义处 | 判定 | 依据 |
|---|---|---|---|
| `meta.{last_updated,notes}` | `data/numbers.yaml:34` | 无法判定 | 元数据未解析；`-S` 见 `13ce2300` / `5e50c7f8`，像文档而非可调参数。 |
| `combat.damage_formula.skill_multiplier_added` + `final_damage_formula.*` | `data/numbers.yaml:106` | 无法判定 | `:106,110-111` 自注“纯文档”；乘子结构在 calculator 固定；`-S` 见 `fb99985a`。 |
| `equipment.tiers[].tier_name` + `enhancement.{max_level_formula,success_curve[].success_formula}` | `data/numbers.yaml:600` | 无法判定 | 显示名/公式字符串未解析，运行时走 enum/算法；三键 `-S` 见 `fb99985a`。 |
| `equipment.resonance.new_owner_retention` | `data/numbers.yaml:756` | 待接线(有 spec 依据) | `-S` 见 `fb99985a`；注释/GDD §6.4 定义换主清零，当前无 owner-change 消费点。 |
| `techniques.tiers[].{tier_name,internal_force_growth_bonus,max_skill_multiplier}` | `data/numbers.yaml:817` | 无法判定 | 三键均无 loader/caller，`:810-813` 是阶位设计指引；`speed_bonus` 有真消费故排除；`-S` 见 `fb99985a` / `cb061649`。 |
| `skills.reference_multipliers.*` | `data/numbers.yaml:979` | 无法判定 | `:972-978` 明说供 `SkillDef` 配置指导，不是运行表；`-S` 见 `be4b4c9e`。 |
| `character.attributes.*` | `data/numbers.yaml:1005` | 无法判定 | 真实键包括 `point_per_attribute_*` / `distribution_*` / `rerollable`；无生成器，角色为手写 profile；各键 `-S` 均回到 `fb99985a`。 |
| `character.rarity_distribution[].probability` | `data/numbers.yaml:1040` | 无法判定 | `:1030-1033` 明说拍板保留为未来程序生成指引；`total_points_range` 已被读故排除；`-S probability` 见 `22686c5a`。 |
| `character.adventure_attribute_bonus.{bonus_per_event_min,bonus_per_event_max,distribution,weights}` | `data/numbers.yaml:1064` | 无法判定 | `:1062-1063` 自注未消费，奇遇真值在 `encounters.yaml outcome.attributeDelta`；四键均查 `-S`，最近见 `c1444c9a`。 |
| `retreat.time_of_day_bonus[].{time_range,effect}` | `data/numbers.yaml:1296` | 无法判定 | loader 只按 `period` 取 multiplier/target/school；`:1290-1293` 说时辰固定且 Dart 硬编码；两键 `-S` 见 `9f59ddc2` / `4016d2c2`。 |
| `retreat.time_of_day_bonus[zhengWu].target_attribute` | `data/numbers.yaml:1304` | 无法判定 | loader 解析但零 caller，结算结构性只乘 `internalForcePoints`；`-S` 见 `9f59ddc2`，改值不生效但是否改为文档须拍板。 |
| `phase0a_arena.moves.{basic_power_multiplier,clear_power_multiplier,clear_qi_delta}` | `data/numbers.yaml:544` | 死字段(建议删) | 生产功率/真气来自 `SkillDef`，`:525-526,547` 仅称 legacy fixture；`907b48f0` / `ce135f73` 删除伪绑定后三属性只剩 loader/test。 |
| `battle_report.{internal_wound_pct,minion_damage_pct,frontline_death_phase_pct,survivor_hp_pct}` | `data/numbers.yaml:1386` | 死字段(建议删) | `91ea3481` 随 `BattleDiagnosis` 引入；`be782281`/`ca548a3a` Route-C 删掉最后诊断消费者，现仅 `BattleReportConfig` 解析/校验。 |
| `tower.{daily_attempts,refresh_at}` | `data/numbers.yaml:1415` | 死字段(建议删) | YAML 注释已漂移；当前 GDD §8.2:606 明确“不做每天 5 次”，两键也未解析；`-S` 见 `93a8687c` / `fb99985a`。 |
| `tower.{difficulty_curve,boss_layers}` | `data/numbers.yaml:1426` | 死字段(建议删) | `:1407-1410` 自注整段 UNUSED，真实 49 层数值源为 `data/towers.yaml`；`-S` 见 `93a8687c` / `fb99985a`。 |
| `tower.leaderboard.*` | `data/numbers.yaml:1472` | 无法判定 | 三键未解析；GDD §8.2:607 只冻结“当前本地榜，云同步为未来方向”，不足以判定接此旧 Supabase 段还是删；`-S` 见 `fb99985a`。 |
| `inheritance.unlock_rules.{can_take_disciple_at,disciple_can_take_grand_disciple_at}` | `data/numbers.yaml:1498` | 无法判定 | `:1486-1492` 明说境界规则与一次性剧情实装分叉；两键 `-S` 见 `13ce2300`，删或改产品规则均需拍板。 |
| `inheritance.unlock_rules.can_pass_legacy_at` | `data/numbers.yaml:1500` | 死字段(建议删) | `:1493-1495` 自注与活的 `ascension.unlock_triggers.required_realm.tier` 重复；`-S` 见 `13ce2300`。 |
| `inheritance.demo_max_characters` | `data/numbers.yaml:1503` | 无法判定 | 无 loader/caller，仅描述旧 Demo 三人；`-S` 见 `fb99985a`，是历史说明还是待恢复 cap 无法从代码判定。 |
| `inheritance.heritage_items.{auto_buff_internal_force_max,resonance_retention}` | `data/numbers.yaml:1514` | 死字段(建议删) | 真实源分别是 `equipment.lineage_heritage.internal_force_max_bonus` 与 `equipment.resonance.inheritance_retention`；两键 `-S` 见 `fb99985a`。 |
| `inheritance.heritage_items.{transfer_trigger,multi_disciple_allocation,stack_across_generations,conflict_slot_resolution}` | `data/numbers.yaml:1516` | 死字段(建议删) | `f2ed4e47` 引入解析，但当前触发/UI/不叠加/auto-swap 都为结构性实装，四属性零分支读取；`:1506-1519` 已记录固定决议。 |
| `inheritance.founder_ancestor_buff.sect_wide_buff.cultivation_progress_pct` | `data/numbers.yaml:1538` | 待接线(有 spec 依据) | `:1535-1538` 明说 Phase 5+ 接修炼度公式；`-S` 见 `eeba0c3b`。 |
| `synergies.effect_values.*` | `data/numbers.yaml:1552` | 死字段(建议删) | `:1546-1548` 自注历史残留，真源是 `data/synergies.yaml`；`-S` 最近见 `93a8687c`。 |
| `validation_examples.*` | `data/numbers.yaml:1590` | 无法判定 | `:1585-1589` 明说纯人工公式校对文档，不进 loader/test；`-S` 见 `13ce2300`。 |
| `animation.*` 除 `sweep_inter_battle_gap_ms` | `data/numbers.yaml:1695` | 死字段(建议删) | 25 个真实键逐一 `-S`（`2fbc6984` / `e91783f8` / `38ad4ab7` 等）；Route-C `be782281` / `ca548a3a` 移除演出消费者，现仅 `sweepInterBattleGapMs` 在 `sweep_screen.dart` 被读。 |
| `combat.{critical.max_damage_multiplier,qi.chain_recovery_pct}` | `data/numbers.yaml:140` / `:83` | 无法判定 | 均被 loader 解析但零 caller；前者注释为信息上限，后者机制不存在；`-S` 见 `fb99985a` / `f416a8e6`。 |
| `combat.school_counter.gang_meng_quake.{pierces_defense,pierces_critical,follows_main_hit}` | `data/numbers.yaml:953` | 无法判定 | `86baac79` 以“全链路落地”引入，当前三语义由 calculator 结构写死，改值不生效；是否作规则文档保留无法判定。 |
| `combat.school_counter.yin_rou_internal_injury.{pierces_defense,stack_rule,follows_main_hit}` | `data/numbers.yaml:965` | 无法判定 | 同为 `86baac79`；穿防/refresh/随主命中是 strategy 结构语义，三属性零 caller，不硬猜删还是接。 |
| `jianghu.enmity_combat_modifier.enemy_attack_power_mult` | `data/numbers.yaml:2032` | 死字段(建议删) | 当前对称设计复用活的 `player_attack_power_mult`，loader 属性零 caller；`-S` 见 `7c88ed2c`。 |
| `sect_management.recruit.encounter_base_prob` | `data/numbers.yaml:2055` | 死字段(建议删) | 每奇遇真实概率源是 `data/encounters.yaml baseProbability`；`-S` 见 `5378c2a3`，本属性仅 loader。 |
| `sect_management.recruit.stage_boss_recruit_prob` | `data/numbers.yaml:2056` | 待接线(有 spec 依据) | 注释指向 `p4_1_q6b`；`-S` 见 `5f2c221a`，当前 `BossRecruitConfig` 回退字面量 `0.40` 而不读此属性。 |
| `sect_management.territory.demo_initial_count` | `data/numbers.yaml:2060` | 死字段(建议删) | 领地数量由 `data/territories.yaml` 实际条目决定，无截断分支；`-S` 见 `5378c2a3`。 |
| `masters[].enabledInDemo` | `data/masters.yaml:31` | 死字段(建议删) | `12d4c5ae` 引入；onboarding 按 `[0]/[1]/[2]` 建角且校验固定 3 条，开关无读点。 |
| `territories[].initialOwnerSectId` | `data/territories.yaml:21` | 待接线(有 spec 依据) | `-S` 见 `5378c2a3`；`TerritoryDef` 注释标注 1.1 初始归属，当前全 null 且无 seeding。 |
| `techniques[].speedBonus` | `data/techniques.yaml:36` | 死字段(建议删) | 实战速度从 `numbers.techniques.tiers[].speed_bonus` 按 tier 派生；per-technique 副本零 caller，`-S` 见 `28d8eff6`。 |
| `techniques[].internalForceGrowthBonus` | `data/techniques.yaml:35` | 无法判定 | `-S` 见 `28d8eff6`；字段注释称文档对照，当前无心法成长公式，无法确定未来接线还是删副本。 |
| `lore/_templates/*.{template_id,trigger_event,placeholders,text}` | `data/lore/_templates/resonance_tier_up.yaml:1` | 无法判定 | 7 个作者模板无 loader；逐键/路径查询及 `-S template_id` 见 `ceadd90d`，像创作辅助而非死运行配置。 |
| `narratives/_archive/techniques/*` 整个字段集 | `data/narratives/_archive/techniques/fu_hu_zhang.yaml:1` | 无法判定 | 66 份归档不进运行 loader；真实键如 `mantra` 及路径均查，`-S mantra` 最近见 `378a4182`，归档保留意图不等于废弃。 |

## 2. 领域字段 / getter（生产零读或仅 test 读）

| 标识符 | 定义处 | 判定 | 依据 |
|---|---|---|---|
| `Character.experienceToNextLayer` | `lib/core/domain/character.dart:47` | 死字段(建议删) | `:44-46` 明说只是 `RealmDef` legacy mirror/未来 schema cleanup；仅 test 读；`-S` 最近 `2496dd2f`。 |
| `Character.levelExp` | `lib/core/domain/character.dart:53` | 死字段(建议删) | `:49-51` 明禁生产读写、等待 schema cleanup；`-S` 最近 `ca548a3a`。 |
| `Character.{learnedSkillIds,isInRetreat}` | `lib/core/domain/character.dart:96` | 死字段(建议删) | 技能真源为 `Technique`，闭关真源为 `RetreatSession/currentRetreatSessionId`；`lineup_service.dart` 注释自认无写点；`-S` 见 `549991ec` / `258611ac`。 |
| `Equipment.customName` | `lib/core/domain/equipment.dart:21` | 无法判定 | 只在 factory 写入，UI 名称读 def；`-S` 最近 `ca548a3a`，但无注释能排除未来改名功能。 |
| `GameEvent.{eventType,relatedCharacterId,relatedEntityIds,isRead}` | `lib/core/domain/game_event.dart:15` | 待接线(有 spec 依据) | service 持续写入，事件 UI 只读 title/summary/time；GDD §9.2 保留“昨晚发生的事”，`docs/_archive/ui_structure.md:241-260` 明列 type/未读/跳转消费；四键 `-S` 均查。 |
| `InventoryItem.lastObtainedAt` | `lib/core/domain/inventory_item.dart:24` | 无法判定 | 10 类获得路径写，无展示/排序读；`-S` 最近 `ca81a9fa`，可能是有意时间埋点。 |
| `SaveData.{totalPlaySeconds,towerLeaderboardSyncedAt}` | `lib/core/domain/save_data.dart:44` | 无法判定 | 两者均零生产写读；`:42-43` 明说前者为预留，后者与排行榜同属未接线；`-S` 见 `96196ac6` / `549991ec`。 |
| `SaveData.{totalPassiveMojianshi,totalPassiveExperience}` | `lib/core/domain/save_data.dart:100` | 待接线(有 spec 依据) | 离线/闭关结算在写，仅 test 读；`:99` 明说 M2 汇总卡展示；`-S` 见 `22f7a136` / `6e02bec9`。 |
| `Technique.{wasMainBeforeReset,learnedAt}` | `lib/core/domain/technique.dart:40` | 无法判定 | 两者只有 test 读；前者像散功恢复状态，后者像时间埋点；`-S` 见 `4bb34678` / `c0d6df8d`，无删除注释。 |
| `AscensionResult.{founderRetired,heritageEquipmentIds,beneficiaryDiscipleIds}` | `lib/features/ascension/domain/ascension_models.dart:83` | 待接线(有 spec 依据) | 仅 `ascend_service_test` 读；`:75-89` 明说 caller/snackbar 可展示装备/受益弟子；各字段 `-S` 见 `f60151fc` / `2ff3f858`。 |
| `PvpRecord` 8 字段 + `PvpSnapshot` 3 字段 | `lib/features/pvp/domain/pvp_record.dart:26`<br>`pvp_snapshot.dart:17` | 无法判定 | 全部零业务读写；两文件 `:5-11` 明说 PVP 已切除但为旧 Isar 存档反序列化保留；11 标识符 `-S` 主要见 `2d0dcded`。 |
| `NpcRelation.updatedAt` + `Reputation.updatedAt` | `lib/features/jianghu/domain/npc_relation.dart:21`<br>`reputation.dart:23` | 无法判定 | service 写时间戳但无展示/排序读；分别查 `-S`，最近同见 `a154f8e5`，可能是审计埋点。 |
| `RetreatSession.durationHours` | `lib/features/seclusion/domain/retreat_session.dart:28` | 死字段(建议删) | `:27` 明说新 session 固定写 0、只留反序列化兼容；`seclusion_service` 也标注 deprecated；`-S` 最近 `05298037`。 |
| `RetreatSession.{completedAt,actualRewards}` | `lib/features/seclusion/domain/retreat_session.dart:39` | 无法判定 | 结算写入、仅 test 读，`:38-46` 给出存档语义；`-S` 见 `22f7a136` / `4f2757d2`，不足以判死。 |
| `TowerProgress.highestClearedAt` | `lib/features/tower/domain/tower_progress.dart:30` | 无法判定 | service 写、仅 test 读，注释定义最高层首通时间；`-S` 最近 `e0069f7e`，可能为排行/成就预留。 |
| `SaveManagementStatus.{databasePath,backupDirectoryPath}` + `SaveRestoreResult.selectedBackup` | `lib/features/save_management/domain/save_management_status.dart:54`<br>`save_restore.dart:18` | 无法判定 | 对象构造写入，UI 不读；三字段 `-S` 均见 `acc311eb`，无注释能判定是日志还是死重量。 |
| `StagePreparationSummary.{recommended,playerTier}` | `lib/features/loot_preview/domain/stage_difficulty.dart:30` | 死字段(建议删) | 两字段只回存 `assess` 输入，UI 读 `focus/realmGap/verdict`；`-S` 见 `6f9ab8e6` / `ca548a3a`。 |
| `ExpeditionNode.durationMinutes` | `lib/features/expedition/domain/expedition_node.dart:14` | 死字段(建议删) | 节点对象写入但结算重读 YAML 时长，仅 test 消费；`-S` 最近 `bf6dcfc3`。 |
| `SweepMaterialHit.itemId` | `lib/features/sweep/domain/sweep_reward_preview.dart:120` | 死字段(建议删) | UI 只读 `itemName/usages`，`itemId` 仅 test；`-S` 最近 `1923e4d6`。 |
| `ArchiveClue.targetKind` | `lib/features/zangjuange/domain/archive_clue.dart:17` | 无法判定 | `category/targetId` 已有生产读故排除；唯 `targetKind` 零读，枚举像跳转预留；`-S` 最近 `ab5dbd98`。 |
| `ActivityOccupancyEntry.runId` | `lib/features/activity/domain/activity_occupancy.dart:17` | 无法判定 | occupancy service 写 run id，查询仅读 kind/资源 id；`-S` 最近 `79a7e3ed`，可能为会话导航预留。 |
| `MainlineSettlementJournal.{updatedAt,coreAppliedAt,closedAt}` | `lib/features/mainline/domain/mainline_settlement_journal.dart:137` | 无法判定 | 持久状态机写但无生产读，属恢复/审计元数据；三键 `-S` 见 `6d990260` 等，不建议凭零读删。 |
| `MainlineSettlementJournal.recoveryAction` getter | `lib/features/mainline/domain/mainline_settlement_journal.dart:204` | 无法判定 | 只有 test 读，生产恢复直接 switch phase；`-S` 见 `9712bdc9`，可能是显式领域语义。 |
| `MainlineParticipantSelection.actualParticipantId` + `MainlineRun.growthAndInjuryOwnerId` getters | `lib/features/mainline/domain/mainline_participation_policy.dart:33`<br>`mainline_run.dart:179` | 无法判定 | 仅 test 读，都原样返回 `participantId`；两键 `-S` 均见 `477576f9`，可能是合同语义别名。 |
| `ActionTimeline.{cooldownMarker,cooldownRemainingTicks}` | `lib/features/battle/domain/phase0a/action_timeline.dart:94` | 待接线(有 spec 依据) | 仅 test/tuning 读；`phase2_parked_contract_wiring_delta_20260826.md` 明列 Timeline 尚无生产 consumer；`-S` 见 `0b7f637c` / `d345c3d7`。 |
| `SelfStateScope.{durationSeconds,refreshPolicy,stackingPolicy,cancelWindowSeconds,effects}` | `lib/features/battle/domain/phase0a/combat_geometry.dart:223` | 无法判定 | 候选几何合同只构造/测试，无 production reader；各键 `-S` 见 `fe3a00bb` / `e2b5b6e3`，无冻结接线 spec。 |
| `Phase0a{Move,Attack,EnemySkill}Intent.behaviorProfile` | `lib/features/battle/domain/phase0a/phase0a_combat_intent.dart:64` | 无法判定 | 生产 factory 依 runtime binding 写入，reducer/session 不读，仅 test 读；`-S` 见 G2 提交 `d02bbaaf`，但未找到冻结其消费语义的 spec。 |
| `StatusAdvanceResult.damages` + `TimedStatusLedger.{blocksRegularMovement,allowsAttack,allowsDefense,movementMultiplier}` | `lib/features/battle/domain/phase0a/status_effects.dart:132` | 待接线(有 spec 依据) | 只有 status tests 读；`docs/superpowers/plans/2026-08-23-p2-m1-c06-status.md` 明示“状态固定拍候选”，`-S` 见 `c5409c5f` / `d345c3d7`。 |
| `AttackContext.defenderEquipped` | `lib/features/combat_shared/domain/damage_calculator.dart:344` | 待接线(有 spec 依据) | `:334-336` 明说为后续反伤/破甲等扩展保留，现零读；`-S` 最近 `ca548a3a`。 |
| `AttackResult.{quakeDamage,schoolCounterMultiplier,realmDiffAttackerMod,realmDiffDefenderMod,cultivationMultiplier,criticalMultiplier,defenseRate,evasionRate,formulaBreakdown}` | `lib/features/combat_shared/domain/damage_calculator.dart:376` | 死字段(建议删) | 分解/系数只写输出且无生产读，真结算只取 `finalDamage/isCritical/isDodged`；逐字段 `-S`，Route-C `ca548a3a` 移除最后 legacy 用户。 |
| `AttackResult.{appliedEffects,lifestealHeal}` | `lib/features/combat_shared/domain/damage_calculator.dart:408` | 待接线(有 spec 依据) | 仅 test 读；`phase0a_damage_calculator_adapter.dart:111` 与 `2026-08-16-phase0a-kimi-damage_calculator-adapter.md` 明记未来 reducer 消费；`-S` 最近 `ca548a3a`。 |
| `SpawnDirectorState.removedCount` + `SpawnDirector.{activeFull,hasReserve,needsReinforcement}` | `lib/features/battle/domain/phase0a/spawn_director.dart:181` | 无法判定 | 只有 test 读，底层 `state/advance` 仍在生产组合；各键 `-S` 见 `93ef5c51` / `9555d5d3`，可能是观测面。 |
| `BasicAttackSegment.effectRefs` + `BasicAttackChain.{segments,timelineRefs,geometryRefs}` getters | `lib/features/battle/domain/phase0a/basic_attack_chain.dart:22` | 待接线(有 spec 依据) | 仅 test 读；`docs/superpowers/plans/2026-08-23-p2-m1-c08-basic-chain.md` 明示五武器普攻链候选；各键 `-S` 见 `a528f5a2` 等。 |
| `AttackTokenAllocation.grantedCount` + `AttackTokenObserveOnlyObserver.lastAllocation` getters | `lib/features/battle/domain/phase0a/attack_token_director.dart:160`<br>`lib/features/battle/application/phase0a/attack_token_observe_only_observer.dart:29` | 无法判定 | 仅 test/tuning 读；observer `:11-13` 明说 observe-only 诊断；`-S` 均见 `d345c3d7`。 |
| `QiGainResult.isAlreadyApplied` + `AttackDefenseFlags.isUnblockable` getters | `lib/features/battle/domain/phase0a/qi_resource.dart:23`<br>`defense_resolution.dart:78` | 无法判定 | 均仅 test 读，为便利判定别名；`-S` 见 `33f6a3e6` / `af326685`，无法单凭生产零读判死。 |
| `Phase0aEncounterFlow.{runtimeObservation,spawnState}` + `Phase0aCombatSession.{lastEnemyIntentObservation,attackTokenLeaseSnapshot}` | `lib/features/battle/application/phase0a/phase0a_encounter_flow.dart:125`<br>`phase0a_combat_session.dart:106` | 无法判定 | 四 getter 均仅测试读，注释/提交定位为运行时观测快照；逐个 `-S` 见 `3392bac6` / `9555d5d3` / `b0d7ea4b`。 |
| `Phase0aEncounterMigrationResolver.legacyContentIds` + `Phase0aBattleController.lastEventRecords` getters | `lib/features/battle/application/phase0a/phase0a_encounter_migration_resolver.dart:36`<br>`lib/features/battle/presentation/phase0a/phase0a_battle_controller.dart:50` | 无法判定 | 仅 test 读，内部私有集/事件链仍真消费；`-S` 见 `3514975b` / `97c93d0a`，像验收观测面。 |
| 两个 Mainline prepared admission 的 `{occupancyBase,occupancyNext,occupancyMutations}` getters | `lib/features/mainline/application/mainline_stage_runtime_admission.dart:22`<br>`mainline_next_stage_runtime_admission.dart:22` | 无法判定 | 两类共 6 getter 仅 test 读，生产经 commit 方法消费 successor；各标识符 `-S` 见 `16123fab`。 |
| `MonthlyTickCoordinator.registeredCount` + `OnlinePresenceController.isHeartbeatActive` + `SweepController.currentIndex` getters | `lib/core/game_loop/monthly_tick.dart:16`<br>`lib/features/seclusion/application/online_presence_controller.dart:56`<br>`lib/features/sweep/application/sweep_controller.dart:39` | 无法判定 | 均仅 test 读；前两处分别注明“用于测试”/`@visibleForTesting`；逐键 `-S` 见 `ca548a3a` / `8ebabcaf` / `7743a26d`。 |
| `SweepUnit.{battleHint,sceneBackgroundPath,bgmTrack}` getters | `lib/features/sweep/application/sweep_unit.dart:29` | 死字段(建议删) | 三 getter 全仓零读；`1b4b160a` 将扫荡改为永久 headless，`be782281`/`43ef5b9c` 后仅剩接口与实现。 |
| `IslandProductionReadability.isProducing` getter | `lib/features/taohua_island/application/island_production_readability.dart:33` | 无法判定 | 全仓零读，其他 readability 字段有 UI 消费；`-S` 见 `17df132e`，可能是便利预留。 |
| `SkillDef.generatesQi` getter | `lib/data/defs/skill_def.dart:148` | 无法判定 | 只有 redline tests 读，生产直读 `qiDelta`；`-S` 最近 `ca548a3a`，可能是合法校验面。 |
| `SkillDef.internalForceCost` getter | `lib/data/defs/skill_def.dart:154` | 死字段(建议删) | 已 deprecated 为 `qiCost` 别名，仅 test 读，生产用 `qiDelta`；`-S` 最近 `ca548a3a`。 |
| `ReadableFirstClearConfig.enemyHpMultiplier` getter | `lib/data/numbers_config.dart:1479` | 死字段(建议删) | 全仓零读，生产用紧邻 `hpMultiplierFor(isBoss:)`；`-S` 见 `56967158`。 |
| `CombatRuntimeVerifiedOnlyReferences.hostConsumption` getter | `lib/data/defs/combat_runtime_binding_def.dart:124` | 无法判定 | 全仓零读且恒返回 `none`，但 `:122-124` 明说有意保留以防 consumer 误推断；`-S` 见 `f1c13e39`。 |
| `Phase0aEncounterHostSettlement.{stageId,nextStageId,canAdmitNextStage}` | `lib/features/battle/application/phase0a/phase0a_encounter_host.dart:280` | 无法判定 | `nextStageId` 仅 test 读，其余零读；三标识符 `-S` 见 `79a7e3ed` / `6f9ab8e6` / `bd9fea8e`，结算回执尚可能用作主机边界。 |

## 3. 零引用资产

> PNG 无逻辑行号，以 `:1（文件）` 作定义位置。表内均查完整路径、basename、stem、同名中文领域注释及 `battle_<stem>` 变体；`battle_*` 是不同文件，不算对本图的引用。

| 标识符 | 定义处 | 判定 | 依据 |
|---|---|---|---|
| `assets/enemies/shiye.png` | `assets/enemies/shiye.png:1（文件）` | 死字段(建议删) | `be782281` 删掉最后 exact-path legacy 映射；当前真立绘是 `battle_shiye.png`（专用立绘计划有注释）。 |
| `assets/enemies/fu_zhaizhu.png` | `assets/enemies/fu_zhaizhu.png:1（文件）` | 死字段(建议删) | `f5b71742` 移除塔层旧图引用，`be782281` 清最后 legacy 映射；当前 binding 是 `battle_fu_zhaizhu.png`。 |
| `assets/enemies/shidi_b.png` | `assets/enemies/shidi_b.png:1（文件）` | 死字段(建议删) | `4d895dbf` 将 debug 使用替换为立绘常量，`be782281` 移除最后 legacy path；当前全路径/词边界零引用。 |
| `assets/enemies/killer_a.png` | `assets/enemies/killer_a.png:1（文件）` | 死字段(建议删) | `be782281` 移除最后 legacy 引用；当前刺客路由专用 battle standee 承载，exact/stem 均零命中。 |
| `assets/enemies/killer_b.png` | `assets/enemies/killer_b.png:1（文件）` | 死字段(建议删) | `be782281` 移除最后 legacy 引用；当前刺客路由专用 battle standee 承载，exact/stem 均零命中。 |
| `assets/enemies/wulin_bazhu.png` | `assets/enemies/wulin_bazhu.png:1（文件）` | 死字段(建议删) | `be782281` 删掉最后 exact-path legacy 映射；当前真立绘是 `battle_wulin_bazhu.png`。 |

## 计数

- 按表行/标识符组计：YAML **38 组**，领域字段/getter **45 组**，零引用资产 **6 件**；组内多字段已在标识符列显式展开。
- 本次没有触发 `[BLOCKED]` 出口；三类均全量扫描。“无法判定”包含有意文档/归档/兼容/测试观测面，未将零 grep 直接当废弃证据。
