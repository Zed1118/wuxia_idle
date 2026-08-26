# N8 · CLAUDE.md 正文 drift 审计

- 审计基线：`07f175e0f68b71e8082ab1421c479d0a3eeabb6a`；范围为 `CLAUDE.md:159-569`（从 `## 1.` 起），跳过头部版本摘要。
- 口径：逐项核对正文中的 Dart 符号、路径、yaml key/字段和“已实装/已激活/已收口”声明；下表只列偏差。`零命中`均为本基线现跑结果，命令/模式写在对应单元格。

| CLAUDE.md | 文档原文（相关摘录） | 实际情况（当前基线证据） | 偏差类型 |
|---|---|---|---|
| `CLAUDE.md:219` | `data/ranks.yaml`（境界配置） | 文件零命中：`rg --files data -g 'ranks.yaml'`；境界配置现位于 `data/numbers.yaml:217` 的 `realms:`。 | 迁位 |
| `CLAUDE.md:237-238` | 命名示例 `equipment_repository.dart` / `EquipmentRepository` | `rg --files lib -g 'equipment_repository.dart'` 与 `git grep -n -F 'EquipmentRepository' -- lib` 均零命中；现有领域实现为 `lib/features/equipment/application/equipment_service.dart:38` 的 `EquipmentService`。 | 不存在 |
| `CLAUDE.md:248` | “境界用 `Realm`，层用 `RealmStratum`，流派用 `Style { rigid, agile, sinister }`” | `git grep -n -F 'RealmStratum' -- lib` 与 `git grep -n -F 'enum Style' -- lib` 均零命中；实际为 `RealmTier`、`RealmLayer`、`TechniqueSchool { gangMeng, lingQiao, yinRou }`（`lib/core/domain/enums.dart:22,33,103`）。 | 不存在 |
| `CLAUDE.md:295` | 机制 Boss 在 floor25/30，floor30 `ward×vuln≈0.03` | 两 Boss 已迁 floor32/49（`data/towers.yaml:1431-1433,2375-2377`）；floor32 窗外乘子为 `0.35`（`:1463-1465`），floor49 为 `0.15×0.10=0.015`（`:2406-2412`，二周目 vuln `0.06` 见 `:2418-2420`）。 | 迁位 + 行为不符 |
| `CLAUDE.md:304` | 集中 sink 为 `enum_localizations.dart`、`battle_log.dart` | 前者已迁至 `lib/shared/battle_shared/enum_localizations.dart:15`；后者零命中：`rg --files lib -g 'battle_log.dart'`。 | 迁位 + 不存在 |
| `CLAUDE.md:316-321` | “最终伤害”只列修炼度、流派、暴击、防御、境界五个乘项 | 当前生产公式还乘 `attackPowerMultiplier`、熟练度、输出状态、守方流派与 ward/vulnerability，并另加刚猛震伤（`lib/features/combat_shared/domain/damage_calculator.dart:249-271`）。 | 行为不符 |
| `CLAUDE.md:324` | `出手速度 = 100 + 身法×8 + 装备速度 + 心法速度加成` | 当前派生公式末端还扣 `lightInjuryStacks × lightSpeedPenaltyPerStack`（`lib/shared/battle_shared/derived_stats.dart:139-168`）。 | 行为不符 |
| `CLAUDE.md:329` | 真气产气倍率、减耗与三流派事件追加产气“已成规则” | `QiCycle.effectiveSkillDelta` / `QiCycle.schoolBonus` 仅有定义（`lib/shared/battle_shared/qi_cycle.dart:62-91`），生产调用检索 `git grep -n -F 'QiCycle.effectiveSkillDelta' -- lib` 与 `git grep -n -F 'QiCycle.schoolBonus' -- lib` 均零命中；Phase 0A reducer 仍直接累加原始 `qiDelta`（`lib/features/battle/domain/phase0a/phase0a_combat_reducer.dart:620-624,746-753`）。 | 行为不符 |
| `CLAUDE.md:344` | 公式集中在 `lib/features/battle/domain/damage_calculator.dart` 与 `derived_stats.dart` | 实际分别迁至 `lib/features/combat_shared/domain/damage_calculator.dart:26`、`lib/shared/battle_shared/derived_stats.dart:97`。 | 迁位 |
| `CLAUDE.md:411` | encounters/events “任一端缺失对应 id 直接抛错” | `_validateEncounterEventReferences` 只从 `encounterDefs` 单向加载同名 event（`lib/data/game_repository.dart:619-637`），未枚举 `data/events/`，因此孤儿 event 不会被该守卫发现。 | 行为不符 |
| `CLAUDE.md:443` | 关卡叙事完整性由 `test/tools/asset_audit.dart` 与 pubspec 声明守卫兜底 | `asset_audit.dart:41-84` 检查的是图片路径（`stageNarrativePath` 生成 PNG），不核对 narrative yaml id；真实完整性守卫已迁至 `test/features/mainline/mainline_narrative_completeness_test.dart:22-55` 与 `test/features/tower/tower_boss_narrative_completeness_test.dart:22-49`。 | 迁位 + 行为不符 |
| `CLAUDE.md:513` | `WuxiaPaperPanel` 滚动 tile 外包 `IntrinsicHeight` | `git grep -n -F 'WuxiaPaperPanel' -- lib` 零命中；现名 `LightPaperPanel`，同一约束写于 `lib/shared/widgets/wuxia_ui/light_paper_panel.dart:8-15`。 | 迁位 |
| `CLAUDE.md:547` | 江湖商店“Phase 5+ 自然实装时再回头” | 商店已进入生产代码：`ShopScreen` 在 `lib/features/shop/presentation/shop_screen.dart:32-45`，`ShopService` 在 `lib/features/shop/application/shop_service.dart:19`；也与同文 `CLAUDE.md:565` 的 P4 已激活声明互相冲突。 | 行为不符 |
| `CLAUDE.md:553` | 枚举显示名见 `lib/features/battle/domain/enum_localizations.dart` | 实际文件为 `lib/shared/battle_shared/enum_localizations.dart:15`；原路径不存在。 | 迁位 |
| `CLAUDE.md:560` | `numbers.yaml combat.resonance.unlocks_joint_skill`；joint skill `cost=250`；`battle_ai` 优先释放 | key 实位于 `equipment.resonance.stages[*].unlocks_joint_skill`（`data/numbers.yaml:724-739`）；技能实际 `qiDelta: -50`、`cooldownTurns: 4`（`data/skills.yaml:1145-1152`）；`rg --files lib -g 'battle_ai.dart'` 零命中，现路径是玩家手动槽 resolver（`lib/features/cultivation/application/skill_loadout_resolver.dart:132-150`），敌方 joint skill 反而被拒绝（`lib/features/mainline/application/phase0a_mainline_repository_runtime_binding_adapter.dart:269-282`）。 | 迁位 + 行为不符 |
| `CLAUDE.md:562` | 阴柔内伤已由 `BattleState internalInjurySlot` / `battle_engine` tick 衰减实装 | 中文领域配置仍被解析（`lib/data/numbers_config.dart:1242-1269`），且存在通用 `TimedStatusType.internalInjury`（`lib/features/battle/domain/phase0a/status_effects.dart:1-2`）；但 `git grep -n -F 'class BattleState' -- lib`、`git grep -n -F 'internalInjurySlot' -- lib`、`rg --files lib -g 'battle_engine.dart'` 均零命中，当前 adapter 明写 `AttackResult.appliedEffects` 无 Phase 0A 消费方且只映射伤害（`lib/features/battle/application/phase0a/phase0a_damage_calculator_adapter.dart:100-112,243-248`）。 | 不存在 + 行为不符 |
| `CLAUDE.md:563` | 传承 4 规则字段“真消费/完整实装”，含 `stackAcrossGenerations=false`、`conflictSlotResolution=auto_swap` | 四个 camelCase 属性仅在 parser/model `lib/data/numbers_config.dart:729-780` 出现；排除该文件后分别对 `transferTrigger`、`multiDiscipleAllocation`、`stackAcrossGenerations`、`conflictSlotResolution` 执行 `git grep -n -F <字段> -- lib ':!lib/data/numbers_config.dart'`，均零命中。生产逻辑直接执行分配/自动换装（`lib/features/ascension/application/ascend_service.dart:157-180,236-269`），叠加则直接按遗物实例数计算（`lib/shared/battle_shared/derived_stats.dart:257-275`），未由这四字段驱动。 | 行为不符 |
| `CLAUDE.md:564` | `_FounderBuffSection` 位于 `lineage_panel_screen.dart` | 符号已迁至 `lib/features/character_panel/presentation/lineage_character_detail_screen.dart:486`。 | 迁位 |
| `CLAUDE.md:565` | 商店“固定标价”“不卖出” | 经验丹已按 ETL 动态标价（`lib/features/shop/application/shop_service.dart:8-28`；`data/shop.yaml:2-5,21-33`）；装备已有出售/分解生产服务（`lib/features/equipment/application/equipment_disposal_service.dart:62-68,80-99`）。 | 行为不符 |

## 疑似红线偏离 `[BLOCKED]`

- `[BLOCKED]` `CLAUDE.md:295,316-324,329,562` 涉及数值红线/战斗结算：机制 Boss 参数与位置已变、公式正文缺少当前乘项、真气倍率/减耗/流派追加未接入 Phase 0A reducer、阴柔内伤配置无生产消费方。
- `[BLOCKED]` `CLAUDE.md:563,565` 涉及成长与经济规则：传承规则字段未驱动生产行为，商店已经动态定价并支持装备出售/分解。这里只登记“文档自称 vs 当前代码”矛盾，不判定应改文档还是代码。
