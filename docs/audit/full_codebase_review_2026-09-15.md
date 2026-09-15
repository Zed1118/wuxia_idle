# 挂机武侠 全量代码审查报告（2026-09-15）

- 审查对象：候选 `6a70e7914eba29dbf8cd020d77e56993f194d533`（`codex/p2-player-flow-20260910` 2026-09-15 18:11 tip；main 仍 `342d19275`）
- 审查方式：只读。快照导出后逐模块通读 `lib/`（689 文件 162,720 行）、`data/`、`docs/dispatch` 两张登记表、抽样 `test/`（966 文件 223,372 行）与 `docs/`（1,849 个 md 207,244 行）；所有数字为本会话脚本实测，行号指向候选快照。
- 触发问题：用户「我感觉进度推不动」。本报告回答三件事：① 为什么正式分子卡在 1/10；② 代码本身健康度；③ 下一步该拍什么板。

---

## 0. 一句话结论

**进度推不动不是工程产能问题，是三件事叠在一起：(a) 第一关对合法新档不可玩的产品缺陷被治理流程「合法地」冻结并埋没；(b) 正式 M0–M9 分子按设计只能由用户本人的真人试玩与 Windows 实机推动，工程再多 READY 也不进分子；(c) 代码里有四处结构病让每一步工程都比应有的贵 2–3 倍。** 三者按顺序处理，先 (a) 后 (b) 再 (c)。

---

## 1. 产品级发现：合法新档打不过第一关

### 1.1 事实

| 来源 | 内容 |
|---|---|
| `docs/audit/phase2_m2_priority_acceptance_2026-09-05.md` :15-22 | 合法新档（4379 HP / 内力 500 / 重兵 / 装备攻 177）在 `stage_01_01 山门之外` **0/9 胜**（5.5–8.0 秒战败），`stage_01_03 黑风岭` **0/9 胜**；`风雨渡口` 9/9 胜 |
| `~/Documents/Codex/2026-09-05/wuxia-priority-acceptance/fresh-save-probe.json` | 第 40/40/51/51/55 拍连吃 5 次 883 伤害 = 4415 > 4379；只杀了 25 敌中的 2 个；两个不同 seed 逐拍完全相同 |
| 同报告 :28 | 在内存把前三关敌血 ×0.5、×0.25、入场宽限改 40 拍，**仍全部战败** |
| `data/combat/encounters/chapter_01_templates.yaml` :3-6 | 第一关模板「25 total, 10 active」；第二关 25/10；第三关黑风岭 **40 敌 / 12 同屏** |
| `data/stages.yaml` :34-51（legacy） | 第一关原设计：**1 个** 1500 HP / 80 攻的流民 |
| `data/numbers.yaml` :1941-1960（`mainline_wave`，v1.49「战斗爽感批」） | 普通关 2+3+4 = 9 敌分三波，敌血 ×0.10 |

同一关「有几个敌人」在仓库里有三份真相：legacy 1 / wave 9 / catalog 25。生产实战走 catalog 25。

### 1.2 根因链（按 git 时间）

1. **2026-08-29 `da99ac9e1` 接通第一章五关四模板**：plan 文件 `docs/superpowers/plans/2026-08-29-p2-m2-ch1-template-production-blocker.md` 明写「推荐将已有 candidate 的四关编排整体冻结并原样生产化」，candidate 来自 `test/fixtures/phase2/combat/ch1_candidate/`（fixture 头注自称「每个数值都是未冻结的评审候选」）。用户逐项批准了一张数字表——**没有任何人打过这一版第一关**。
2. **2026-09-04 M0-R**：`decision_registry.yaml` :736-780 `TUNE-ACTIVE-LIMIT-01 / TUNE-REINFORCEMENT-01 / TUNE-STAGE-COUNT-01` 用户选 C「preserve current production baseline, no new phase2 value or rule」→ 25/10 被锁成基线。
3. **2026-09-05** bot 取证发现 0/36；Codex 依宪法「不得自清闸门、不得新增数值」正确地拒绝改数，挂 blocker `first_stage_and_blackwind_playability_requires_human_strategy_validation_or_new_approved_tuning`。
4. **09-05 → 09-15**：Codex 转做 CI 恢复、Isar 缺字段归位、减少闪光、背景人群、守城 standee 等 8 个外围任务。`PROGRESS.md` :9「前三阻塞」写的是收益覆盖/帧耗/Windows——**第一关不可玩不在列表里**。

### 1.3 为什么验证体系没拦住

- 唯一的「生产验收」测试 `test/.../phase0a_mainline_g2_production_acceptance_test.dart` 用 20000 血 / 15000 内力 / 2000 攻的上限角色（报告 :24 自承「不能解释为普通开局可玩」）。
- 966 个测试文件里，文件名含 production 35 / redline 24 / contract 22 / gate 21 / wiring 21——全是「证明接了线」；**没有一条「新档能通第一关」的守卫**。mutation 双向证红、exact-SHA CI、coverage ratchet 86% 都在证明规则没变，而规则本身错了。
- 关卡情报弹窗 `lib/features/loot_preview/presentation/stage_intel_dialog.dart` :77-80 仍按 `mainlineWave` 给玩家显示「3 波 9 敌」，实战 25 敌；`stage_list_screen.dart` :1220-1233 做了 catalog→wave→enemyTeam 三级 fallback，两处 UI 口径不一。

---

## 2. 治理级发现：分子设计成只有用户能推

`docs/dispatch/phase0a_overhaul/task_registry.yaml`（8,428 行 / 202 任务）实测：

| 状态 | 数量 |
|---|---|
| ready_reviewed | **167（83%）** |
| integrated_origin_main_ci_success | 20 |
| blocked / deferred_by_user / planned | 3 / 2 / 2 |
| 其他（in_progress、verified_local_candidate…） | 8 |

顶层 gate 依赖：M9 ← {M0,M2,M3,M4,M5,M6,M7,M8}；M8 ← M7；M7 正式关闭 ← {M2,M3,M4,M5,M6}。

M2、M3、M4、M5、M6 五个门的 blocker **全部**是 `human_desktop_acceptance: deferred_by_user` + `windows_profile_acceptance: deferred`；M0 blocker 是 `remaining_measurement_playtest_Windows_and_clean_integration_evidence`。

结论：分母 10 里有 6 个门在设计上只接受「用户本人坐下来玩 + Windows 实机」作为关闭证据。工程侧已经把 M3（5/5 武器）、M5（42/42 cell）、M6（1/1）、M7 主线（105/105）做到 engineering-integrated，但都写着 `engineering_completion_does_not_claim_formal_*`。**用户看到 1/10 不动，是因为仪表盘量的是用户自己没做的那件事。** 与此同时 Codex 为了「有事可做」持续产出 READY 单（83%），每单几十个证据文件，形成「活动量极高、分子不动」的假象。

第二层：M2 的 human acceptance 本身又被 §1 的不可玩缺陷卡住——用户即使坐下来玩，第一关也过不去。所以 §1 是 §2 的前置。

---

## 3. 代码级发现：四处结构病

按「让每步工程更贵」的程度排序。每条都给了定位，可独立立项。

### 3.1 结算逻辑写在 presentation 层，headless 自动化反向依赖 UI 文件

- `lib/features/mainline/presentation/stage_entry_flow.dart` **3,085 行**，含 `applyVictoryResolution`（:2066-2628，约 560 行：掉落 / 成长 / 共鸣 / 声望 / Isar writeTxn，全文件 91 处 Isar 引用）与 `applyParticipantDefeatResolution`（:2636-2818）。
- `lib/features/tower/presentation/tower_entry_flow.dart` 1,229 行同样含 `applyTowerVictorySettlement` :490 / `applyTowerCombatResolution` :692。
- **application 层反向 import presentation**：`features/activity/application/durable_activity_automation_coordinator.dart` 与 `features/sweep/application/sweep_settlement.dart`（都是 headless 自动化）从 `stage_entry_flow.dart` import 结算函数。
- 全仓 presentation 层 51 处 `writeTxn`（application 216）。
- 后果：每个「dispatch + playerBot + headless」门都得靠 `WidgetRef? ref` + `dependencies?` 双模参数硬拆（`applyVictoryResolution` :2077-2093、coordinator :1-40 同模式）。这是 M5/M6/U14 各 automation 子门反复难产的直接技术原因。
- 顺带：146 处 `*ForTest` / `seedForTest` 标识符散在 18 个生产文件（stage_entry_flow 41、tower_entry_flow 26、expedition_service 14），生产函数签名被测试需求驱动膨胀。

### 3.2 战斗核心是 1,878 行单函数

- `lib/features/battle/domain/phase0a/phase0a_combat_reducer.dart` `reducePhase0aTick` :119→:1997，内含 7 个嵌套闭包（`executeBasicAttack` 一个闭包约 386 行），闭包捕获可变局部 `var player / var seq / events`。
- 架构意图本身健康（单 reducer + 注入 `Phase0aDamageResolver` + live/headless 共用 flow + `Phase0aProductionFlowAssembler` 唯一装配口），但任何战斗规则改动都落在这一个函数里，review 与回归成本极高。
- 症状：Phase 2 每批都以 13–27 行的 `*_observation.dart / *_gate.dart / *_receipt.dart`（10 个）在外围加 observer/gate 接口**绕着 reducer 走**，不动本体。
- `phase0a_battle_screen.dart` 4,326 行 / 27 个私有 class / 82 方法。

### 3.3 配置层双真相源 + 高加字段成本

- `lib/data/numbers_config.dart`（3,862 行 / 72 class / 70 个手写 `fromYaml`）有 **95 处 `?? <数字字面量>` 兜底**，包括红线本身：`playerHpMax ?? 20000` / `bossHpMax ?? 60000` / `skillPowerMultiplierMax ?? 8000` / `damageReadabilityMax ?? 1000000`（:1791-1802），以及公式常量 `realmLevelFactor ?? 156`（:2308）、`stageBossRecruitProb ?? 0.40`（`stage_def.dart` :204 再重复一次）。yaml 删 key 不 fail-fast 而静默回落 Dart 常量——直接违反 CLAUDE §5.6 / §9。同仓 Phase 2 新代码（`phase0a_weapon_mapping_config.dart`、combat catalog loader）已是「no defaults, fail closed」体例，**两套加载哲学并存**。
- `numbers.yaml` 460 个叶子 key 中 74 个在 lib 零引用，含已标 UNUSED 两个月的 `tower.daily_attempts / refresh_at`（§5.1 反主流概念残留）、`leaderboard.sync_to_supabase: true`、`combat.final_damage_formula.apply_*` 五个开关、`validation_examples` 整段。
- `lib/data/isar_missing_field_defaults.dart` 870 行 = isar_community 3.3.2 缺字段读出 minLong/NaN 哨兵的补丁层：63 个 `repairedFields` + 两张 deferred 登记表，每加一个 Isar 字段都要登记 + 写 `_repair*` + 迁移段 + 测试。加上 numbers_config 手写映射，**「加一个配置项 / 加一个持久字段」是全仓最贵的操作**——这解释了为什么需要新持久模型的门（塔层个人最好成绩、durable receipt）一律 BLOCKED，以及 0.50 三个 `pendingPassiveRecap*` 字段（`save_data.dart`）为何未 bump、未打 `[schema]`。
- `isar_setup.dart` :1151 硬编码 `'stage_06_05#1'` 判首周目完成（现实 21 章 105 关）；`openSlotReadProbe` 与 `loader_fallback_log.dart` 靠匹配库内部错误字符串判类型。

### 3.4 死路径与半途重构

| 项 | 定位 | 状态 |
|---|---|---|
| `Phase0aStageContentMapper.mapMainline` + `numbers.mainline_wave` + `enforceMainlineWaveRedLines` | `phase0a_stage_content_mapper.dart` :206；lib 内零生产调用（仅 1 个测试） | 主线 105/105 已走 catalog，此路径已死，但 UI 情报仍读它（§1.3） |
| `phase0a_mainline_battle_host.dart` :139-166 legacy switch、`runtimeKind: 'legacy_waves'` | 生产数据永不触发 | 两套代码/测试并维护 |
| `combat_catalog_migration_gate.dart` legacy 分支 ≥8 个 issue code | `stage_assignments.yaml` 105 migrated / 0 legacy | 只为 fixture 存在 |
| `features/lineup`（1,464 行） | 仅 `debug/visual_route_host.dart` 引用 | v1.81 后僵尸 |
| `features/pvp`（76 行）+ `PvpRecord/PvpSnapshot` schema | 仅 `isar_setup.dart` | v1.24 切除残留 |
| `core/application/system_clock_provider.dart` | 自注「只切 sect」；消费者 3 文件 | lib 内仍 **143 处裸 `DateTime.now()`**（stage_entry_flow 24 / phase2_seed_service 18 / game_event_service 10 / gauntlet_service 8） |
| `data/stages.yaml` 5,983 行 enemyTeam | catalog 经 `sourceEnemyDefId` 回指取数值 | 两套敌人 schema 耦合而非替换 |

其余：`battle/domain` 反向 import `boss_gauntlet/domain/qi_drain_effect.dart`；`data/validation/combat_encounter_catalog_validator.dart` 990 行手写结构校验，allowed-name 集合与运行时 enum 各维护一份；`GameRepository._enforceRedLines` 40+ 个 enforce 调用无统一 schema DSL；`debug` 模块 8,621 行是第三大 feature（比 tower / seclusion 大），被 main.dart、battle_screen、四个 battle_host 导入，`kReleaseMode` 门控。

### 3.5 守住的部分（如实记录）

- §5.3 三系锁死：`isEquippableAtRealm` 9 个消费点覆盖换装 / 入场 / 飞升 / UI；直接写 `equipped*Id` 的 recruitment / master_builder 由 yaml 层 `enforce*RedLines` 兜底；心法 `techniqueTierCapOf`、奇遇招式 `canEquipAtRealm` 在位。
- §5.5 在线=离线：`OnlinePresenceController` 心跳与关机走同一 passive ledger，`PassiveIdleIntegrator` 同时间线积分，`ExpeditionTimeline` 串行化 elapsed-time 写入。
- §5.6 文案：中文字面量扫描（排除 strings / enum_localizations / battle_log）81 文件 787 行，绝大多数是 `throw StateError('…')` 与 debug 模块；玩家可见违规个位数。
- 注释纪律：TODO/FIXME 6、`// ignore:` 0、`@Deprecated` 4。
- 战斗核心的架构意图（单 reducer、resolver 注入、headless 同核）是仓库里最像产品内核的部分。

---

## 4. 体量与成本

| 项 | 实测 |
|---|---|
| lib | 162,720 行 / 689 文件（battle 24k、mainline 12.6k、**debug 8.6k**、seclusion 5.4k…） |
| test | 223,372 行 / 966 文件（1.37 : 1，分布与 lib 对应，不算病态） |
| docs | **207,244 行 / 1,849 md ≈ lib 体量**：superpowers/plans 556、handoff 421、audit 199、spec 130 |
| 登记表 | task_registry 8,428 行 + decision_registry 868 行 |
| CLAUDE.md | 579 行，头部 60+ 条版本摘要 |
| 每候选固定成本 | 6,574 tests 冷跑 ~14 min + 4 shard CI + coverage ratchet + mutation 双向证红 + format 门 + `~/Documents/Codex/<date>/<task>/` 几十个证据文件 |

测试与 CI 纪律本身不是问题；问题是它们全部在证明「没变」，而 §1 证明「该变的没变」。

---

## 5. 决策菜单

按推荐顺序。A 不拍，B、C 做了也白做。

### A. 先修第一关可玩性（产品，最高优先）

- **A1（推荐）**：重开 M0-R 对前三关的冻结，授权一轮「新档三战术 bot 通关率 ≥ 2/3 且真人 5 分钟内能过」为验收标准的调优——允许改 `chapter_01_templates.yaml` 总数 / 同屏 / 补兵阈值与 `bandits.yaml` 倍率，不动 numbers.yaml 红线。同批把「合法新档 bot 通第一关」写成常驻守卫测试（用真实 `createFreshPhase0aMainlineEncounter` 路径，不用上限角色）。
- A2：保留 25/10，只调新档初始属性 / 起手装备（会连带改成长曲线，不推荐）。
- A3：先由用户本人在候选上真人打一次第一关，看是 bot 弱还是关难（报告 :28 已试过 ×0.25 敌血仍败，倾向关难；但真人 5 分钟即可证伪）。**A3 可与 A1 并行，不互斥。**

### B. 分子口径（治理）

- **B1（推荐）**：正式分子保持 1/10 不动，但 PROGRESS 顶栏改为两行：「正式 x/10」+「工程 y/10（engineering-integrated）」，并把 §1 缺陷列为前三阻塞第一条。不改任何 gate 规则，只改仪表盘让用户看得到工程已到哪、自己欠哪几件。
- B2：把 M3/M5/M6 的 human acceptance 改为「用户抽检 30 分钟即可关」——需要用户改宪法，且仍绕不过 §1。
- B3：维持现状——则分子在用户做完 5 场真人试玩 + Windows 实机前不会动，应明示接受。

### C. 结构整改（工程，A 之后分批）

按 ROI 排序，每项独立成批、独立证红：

| # | 批次 | 解锁什么 | 量级 |
|---|---|---|---|
| C1 | 把 `applyVictoryResolution` / `applyParticipantDefeatResolution` / tower 两个 settlement 从 presentation 迁到 `application/`，`WidgetRef` 只留 UI 薄层；顺手清 146 处 `*ForTest` | 所有 automation 门不再双模硬拆 | 中（约 1,000 行搬迁 + 现有 1,271 行测试跟随） |
| C2 | numbers_config 95 处兜底改 fail-fast（red_lines 段先做）；删 74 个零引用 key 或标注；`stage_intel_dialog` 改读 catalog | 单一真相源；§5.6/§9 合规 | 小（一天） |
| C3 | 删死路径：`mapMainline` / `mainline_wave` / `enforceMainlineWaveRedLines` / legacy switch / migration_gate legacy 分支 / lineup / pvp | 少维护两套 | 小，但需拍板「主线永不回 legacy」 |
| C4 | `reducePhase0aTick` 按阶段拆 5–7 个纯函数（cooldown 推进 / 意图排序 / 普攻 / 技能 / 防御结算 / 事件发射），行为零变、事件序列 golden 守 | 战斗规则可改 | 大（需 golden 事件流测试先行） |
| C5 | `system_clock_provider` 推到 143 处；`Random(` 收口到 rngProvider | 离线/回放确定性 | 中，机械 |
| C6 | Isar 字段登记流程简化：评估升级 isar_community 或改用「显式 nullable + 迁移段」单一模式，废掉 sentinel 登记表 | 加持久字段不再贵 | 需调研，先立项不实装 |

### D. 治理减负（可与 C 并行）

- D1：`task_registry` 的 `ready_reviewed` 167 单做一次分类：已集成 / 已过时 / 待合。过时的归档，不再滚动维护。
- D2：Codex 派单改为「一单一门」：没有能推动 §5A 或 C 表的单不派；外围美术 / 减少闪光 / standee 类先停。
- D3：CLAUDE.md 头部 60 条版本摘要归档到 `docs/_archive/`，只留当前版本一段。

---

## 6. 与前次审查的关系

- `docs/audit/full_project_review_2026-07-02.md`、`full_system_audit_2026-06-24.md` 已指出 numbers.yaml unused 段与文档 drift；本次实测 unused 仍在（74 key），说明「审计发现 → 登记 → 不动」是既有模式。
- 2026-09-15 对 Codex 09-13→09-15 工作的评分 7/10（本会话前段）保持不变：工程纪律高，但 10 天没有一单指向 §1。

---

## 附录 A：模块清单（lib/features，行数 / 文件数）

battle 24,038/85 · mainline 12,646/35 · debug 8,621/17 · seclusion 5,424/19 · character_panel 5,017/9 · tower 5,006/16 · inventory 4,959/11 · boss_gauntlet 4,890/14 · expedition 4,077/16 · equipment 3,727/20 · sect 3,562/18 · taohua_island 3,361/10 · jianghu_map 2,973/19 · cultivation 2,768/23 · technique_panel 2,366/4 · sweep 2,261/11 · baike 2,235/7 · encounter 1,933/6 · main_menu 1,645/6 · combat_shared 1,634/9 · activity 1,592/9 · lineup 1,464/7（僵尸）· onboarding 1,378/4 · cangjingge 1,284/5 · battle_record 1,209/9 · shop 1,180/5 · loot_preview 1,162/9 · ascension 1,144/4 · settings 1,138/12 · inner_demon 998/8 · weapon_codex 932/6 · mass_battle 794/4 · recruitment 757/3 · light_foot 747/4 · save_slot 656/3 · jianghu_chronicle 594/3 · resource_overview 590/4 · jianghu 578/8 · progressive_unlock 525/6 · codex 500/3 · save_management 459/6 · lineage 435/3 · tutorial 390/4 · help 371/3 · dispel 350/2 · zangjuange 328/3 · event 314/2 · reward 301/4 · narrative 285/2 · injury 279/2 · splash 233/1 · martial_inventory 148/1 · inheritance 102/2 · festival 94/2 · pvp 76/2（残留）。

lib/data 10,237 + defs 6,382 + validation 3,591；lib/core 与 lib/shared 13,883。

## 附录 B：最大单文件

strings.dart 4,513 · phase0a_battle_screen.dart 4,326 · numbers_config.dart 3,862 · stage_entry_flow.dart 3,085 · visual_route_host.dart 2,534 · phase0a_combat_reducer.dart 2,506 · character_panel_screen.dart 2,406 · taohua_island_screen.dart 2,133 · stage_list_screen.dart 2,079 · inventory_screen.dart 2,033 · technique_panel_screen.dart 1,989 · phase2_seed_service.dart 1,617 · expedition_service.dart 1,588 · gauntlet_service.dart 1,536 · game_repository.dart 1,439 · phase0a_stage_content_mapper.dart 1,392。

## 附录 C：本次未做

- 未运行 flutter test / build（只读快照，不占用候选环境）；§1 数字全部引用 Codex 09-05 取证文件，未复跑 bot 矩阵。若用户要独立复核，A3 真人 5 分钟即可。
- 未逐行读 presentation 层全部 widget 与 966 个测试文件；测试只做体量与命名分类。
- 未触碰真实存档、主 checkout 四个用户文件、任何在途 worktree。
