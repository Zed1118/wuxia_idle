# 二阶段 G0 只读证据决策包（2026-08-23）

## 0. 本包是什么、又不是什么

本包只把待决问题整理成可回答的证据矩阵，**没有批准任何选项**。文中“安全默认/保守候选”仅表示用户尚未回答时如何保持 fail closed；它不是产品决定，也不得据此开启已否方向。

- 事实快照基线：`codex/phase2-g2-batch7-data-contracts-20260823` @ `fcc2730e6d9ccbad0a9dc371aecc4cf3c244eccb`（短哈希 `fcc2730e`）。该快照已含 L01 loader 验收登记；本包收口不再自动 fast-forward。Batch8 整合预检已复核 `fcc2730e`→`1a4e1dd3`：增量只包含 O02 目标引用纯映射、L02 迁移覆盖 Gate、对应测试/fixture 与 Batch7 验收文档，未增加生产数据、host routing、调参或用户产品语义，因此不改变本 G0 结论。
- 取证工作分支：`codex/phase2-g0-decision-packet-20260823`
- 外部方案快照：`/Users/a10506/Desktop/二阶段优化方案.md`，SHA-256 `887eefe07d3cc6afcdfee29ac7f00e7cf6b3a6bb2d634c1cca170c99b9a95217`；下文行号只对该快照有效。
- 权威状态：`docs/dispatch/phase0a_overhaul/decision_registry.yaml:7-12` 规定 `proposed` 必须由用户明确决定，`tuning` 必须经数据/模拟/试玩定标。
- 方案纪律：`/Users/a10506/Desktop/二阶段优化方案.md:29-34` 同样规定每个 `PROPOSED` 在 G0 必须明确“改写/保留/暂缓”，不能把“用户没反对”当冻结。
- 依赖总闸：方案 `:998,1030-1032,1055-1076` 规定参与者、连续 run、听剑、心魔惩罚等若没有签字或安全 policy，相关 M2/M5/M6 生产路径不得接入。

证据标签：

- **【当前生产事实】**：固定基线中的 `lib/`、`data/`、`test/` 或该基线已合入的 closeout。
- **【旧基线审计事实】**：M0 在更早提交上观察到的事实，不能覆盖当前代码。
- **【提案】**：桌面方案或 registry 中的候选，不是生产合同。
- **【旧否决】**：`docs/spec/rejected_task_registry.md` 中仍有效的明确否决；只有用户显式重开才能改变。

## 1. 先纠正 M0 审计漂移

M0 实现差距报告固定在旧提交 `e292d3a0`，并明确 `PROPOSED` 不是决定（`docs/audit/phase2_m0_implementation_gap_evidence_2026-08-23.md:3-8`）。其中“空掌门回退首角色”（`:113-146`）和“心魔失败仍施加物理伤势”（`:156-188`）都是**旧基线事实**。

固定生产基线已经：

1. 对缺失、悬空或不存在的 `founderCharacterId` fail closed：`lib/shared/battle_shared/current_leader_resolver.dart:9-25`；覆盖测试为 `test/shared/battle_shared/current_leader_resolver_test.dart:6-79`。
2. 心魔失败免物理伤势：`lib/features/combat_shared/application/combat_resolution_service.dart:238-283`；生产对照测试为 `test/features/inner_demon/application/inner_demon_failure_resolution_test.dart:75-147`。

G1 closeout 也明确这两项已修、但没有替用户决定 replay、`MainlineRun`、听剑、修炼度或 AI（`docs/audit/phase2_g1_production_batch1_2026-08-23.md:9-23,36-40`）。因此以下矩阵从当前代码重新取证，不照抄 M0 的历史缺口。

## 2. 需要用户回答的总表

| ID | 状态 | 未回答时安全默认 | 主要阻塞 |
|---|---|---|---|
| `MAINLINE-REPLAY-PARTICIPANT-01` | `proposed` | 不改变当前产品路径 | M2，M6；M5 共用参与合同 |
| `MAINLINE-RUN-01 / A` 锁人 | 父项的必答维度 | 不启用连续 run，只保留 policy seam | M2，M6 |
| `MAINLINE-RUN-01 / B` 换装 | 父项的必答维度 | 不启用连续 run，不新增持久装配锁 | M2，M6 |
| `MAINLINE-RUN-01 / C` 伤势中断 | 父项的必答维度 | 不启用连续 run，不猜阈值 | M2，M6 |
| `MENTOR-INSIGHT-OCCUPANCY-01` | `proposed` | 生产路径禁用 | M2，M5 共用占用，M6 |
| `MENTOR-INSIGHT-RATE-01` | `tuning` | 不发成长，等待模拟 | M2，M6 |
| `INNER-DEMON-CULTIVATION-01` | `proposed` | 保持当前 10% 扣减 | M5，M6 |
| `INNER-DEMON-AI-01` | `proposed` | 保持现有通用 AI | M5 |
| `UNREGISTERED-UNLOCK-01` | 方案 `PROPOSED`、registry 缺 ID | 保持现有解锁 | M5，M6；M2 首章相邻入口 |
| `UNREGISTERED-ECOLOGY-01` | 方案 `PROPOSED`、registry 缺 ID | 只做已明确的 Ch1 纵切，不批量铺开 | M2，M5 |
| `UNREGISTERED-GAUNTLET-BOT-01` | 方案写“待 G0”、registry 缺 ID | 不加前台 bot | M5，M6 |
| `REOPEN-*` 六项 | `proposed_reopen` | 分别沿用 registry safe default | 见 §7 |
| `TUNE-*` 二十项 | 数据/模拟/实机待定 | 保持现值，不写生产数值 | M2/M5/M6，见 §8 |

## 3. 主线参与与连续运行

registry 中只有一个父 ID `MAINLINE-RUN-01`（`docs/dispatch/phase0a_overhaul/decision_registry.yaml:45-49`）。下文 `01A/01B/01C` 是本包为避免合并审批而设置的三个必答维度，不是擅自新增的 registry 决策 ID：只有锁人、换装和伤势中断三维都收到明确答案，父项才可汇总为一条用户决定；任一维未答，整个父项继续 `policy_interface_only`，不得只实现已答维度后宣称 `MAINLINE-RUN-01` 已签。

### 3.1 `MAINLINE-REPLAY-PARTICIPANT-01`：重打 / 前台 bot / headless / 扫荡由谁参与

**当前生产事实和精确证据**

- 主线清关与未清关都从同一 timeline 调 `runStageFlow`，没有 replay 参与者参数：`lib/features/mainline/presentation/stage_list_screen.dart:220-233`。
- 可见主线宿主每次用 `CurrentLeaderResolver` 解析当前掌门，再 `loadExactRoster([playerId])`：`lib/features/mainline/presentation/phase0a_mainline_battle_host.dart:145-163`。
- 主线扫荡也在每关固定解析 current leader，然后用真实 `Phase0aHeadlessRunner` + `Phase0aPlayerBotAdapter`：`lib/features/sweep/application/phase0a_sweep_headless_runner.dart:49-61,77-128`；专项测试钉住实际参与者为 founder：`test/features/sweep/application/phase0a_sweep_headless_runner_test.dart:57-117`。
- Sweep 当前自定义占用闸只拒绝 expedition / bossGauntlet，未拒绝 occupancy 枚举中的 retreat：`lib/features/sweep/application/phase0a_sweep_headless_runner.dart:109-124`。这是参与/可用性 policy 的现行缺口，不是本包授权修复的代码项。
- 通用 headless runner 只消费已构造好的 flow 和 bot，不负责选角：`lib/features/battle/application/phase0a/phase0a_headless_runner.dart:29-37,53-79,82-121`。
- 可见主线宿主注入的是人类控制器，没有生产前台 bot 接线：`lib/features/mainline/presentation/phase0a_mainline_battle_host.dart:116-132`。全仓生产消费 `Phase0aPlayerBotAdapter` 的位置是 sweep、远征、断魂庄和 debug，不是可见主线。
- 方案把首通 current leader 与重打/前台 bot/headless/扫荡拆成两个状态；后四者仍是 `PROPOSED`：`/Users/a10506/Desktop/二阶段优化方案.md:43,69,402,468-486`；registry 记录在 `docs/dispatch/phase0a_overhaul/decision_registry.yaml:39-43`。

**旧否决冲突**

无直接 rejected 条目。但不得把“首通固定 current leader”的 frozen 决定外推到首通之外，也不得从通用 bot 能力反推“前台 bot 已批准”。

**互斥选项**

- A：四类首通外路径全部固定当前掌门，个人记录、成长、伤势均归掌门。
- B：四类路径都允许入场时显式选择任意 eligible 空闲角色，归属实际参与者。
- C：逐路径分开：可见重打/前台 bot 可选人，无人值守 headless/扫荡固定当前掌门；每条记录实际参与者。

**推荐安全默认（不是决定）**

沿用 registry 的 `do_not_change_current_product_path`：可见重打与扫荡继续 current leader，前台 bot 不接生产，通用 headless 继续由 caller 负责选角。这个暂停态只用于避免扩面。

**M2 / M5 / M6 影响**

- M2：重打、auto、headless、扫荡整条黑风寨纵切在签字前不得猜参与者（方案 `:1030-1032`）。
- M5：各特殊模式仍需自己的 participation/automation matrix，复用参与请求但不能自动继承主线选择。
- M6：选人、占用冲突、个人记录/成长/伤势归属与报告展示都消费本决定。

**需要用户回答的一句话**

> 请确认主线首通之外四类路径是 A 全部固定当前掌门、B 全部允许每次选择 eligible 空闲角色，还是 C 可见路径可选而无人值守路径固定掌门，并明确个人记录、成长与伤势归属？

### 3.2 `MAINLINE-RUN-01 / A`：连续进入下一关是否锁参与者

**当前生产事实和精确证据**

- 可复核的不存在性检查 `rg -n --glob '!docs/**' 'MainlineRun|mainlineRun' lib data test` 在固定基线只命中下一条 FailurePolicy 边界注释，没有 `MainlineRun` 领域、持久化或测试类型；当前每关独立启动。
- `FailurePolicyResolver` 明确排除 participant、loadout 和 injury interruption strategy：`lib/shared/battle_shared/failure_policy_resolver.dart:36-40`。
- 现有 occupancy 只有闭关、远征、断魂庄：`lib/features/activity/domain/activity_occupancy.dart:1-25`；聚合 service 也只读这三源：`lib/features/activity/application/character_occupancy_service.dart:9-44`。
- 方案把是否锁 `leaderId` 写成 `PROPOSED`：`/Users/a10506/Desktop/二阶段优化方案.md:44,973`；registry 为 `docs/dispatch/phase0a_overhaul/decision_registry.yaml:45-49`。

**旧否决冲突**

无直接 rejected 条目。潜在冲突是不得借“连续体验”静默发明新的占用类型或角色锁。

**互斥选项**

- A：整段 run 固定入场参与者，直到成功、失败、退出或恢复终止。
- B：每关结束释放，下一关重新选择 eligible 角色；run 只串联关卡，不锁人。
- C：不建设持续 `MainlineRun`，维持每关独立。

**推荐安全默认（不是决定）**

沿用 `policy_interface_only`：暂不启用持续 run，只保留接口 seam，不新增持久化角色锁。

**M2 / M5 / M6 影响**

- M2：结果页“下一关”和连续五关不能接真实产品流。
- M5：没有直接主线实现依赖，但远征/断魂庄等跨场活动不能擅自继承本锁人策略。
- M6：连续流的选人、占用 fail closed、退出/崩溃恢复 UI 依赖本项。

**需要用户回答的一句话**

> 请确认连续进入下一关时，是整段锁定同一参与者、每关释放后重选，还是维持当前每关独立而不建设持续 MainlineRun？

### 3.3 `MAINLINE-RUN-01 / B`：连续 run 关间能否换装

**当前生产事实和精确证据**

- 当前可见战斗宿主每次新建关卡快照，没有 `loadoutSnapshotId` run 合同：`lib/features/mainline/presentation/phase0a_mainline_battle_host.dart:78-132,145-163`。
- 主线扫荡在每关开跑前从 Isar 重载当前掌门，使上一关的伤势、成长和装备自然进入下一场：`lib/features/sweep/application/phase0a_sweep_headless_runner.dart:22-26,109-128`；这不是“锁定整段装配快照”。
- 装备服务只按现有 occupancy 拒绝 equip/unequip：`lib/features/equipment/application/equipment_service.dart:48-72,140-168`；技能装卸没有主线 run 锁：`lib/features/cultivation/application/skill_loadout_service.dart:46-99,129-139`。
- 方案将 `loadoutSnapshotId` 锁定与关间换装并列为 `PROPOSED`：`/Users/a10506/Desktop/二阶段优化方案.md:973`。

**旧否决冲突**

若选项包含“保存两套亲战/差遣 preset”，会碰撞旧否“Build 方案保存”（`docs/spec/rejected_task_registry.md:87`），必须另答 `REOPEN-LOADOUT-PLAN-01`；本项只能决定当前 run 的快照/换装语义。

**互斥选项**

- A：整段锁入场装配快照，关间不可换装备、主修或技能槽。
- B：只锁参与者，关间允许换装；下一关重新生成快照并记版本。
- C：不建设持续 run，维持每关独立生成快照。

**推荐安全默认（不是决定）**

不启用持续 run，也不新增持久化装配锁或 preset；这不等于批准关间换装。

**M2 / M5 / M6 影响**

- M2：下一关按钮、幂等 run/session key 与快照恢复。
- M5：无直接继承；跨场模式需各自定义快照边界。
- M6：关间装备入口、锁定提示、冲突说明。

**需要用户回答的一句话**

> 请确认连续 MainlineRun 是整段锁定入场装配快照、只锁参与者并允许关间换装，还是不建设持续 run 而保持每关独立？

### 3.4 `MAINLINE-RUN-01 / C`：伤势何时中断连续 run

**当前生产事实和精确证据**

- 当前没有连续 run，因此也没有伤势中断阈值或恢复合同。
- Sweep controller 只因用户停止、战败或 timeout 停止，不按伤势阈值停止：`lib/features/sweep/application/sweep_controller.dart:3-26,48-71`；screen 的 stop 判定见 `lib/features/sweep/presentation/sweep_screen.dart:56-104`。
- 每关 sweep 重载角色，伤势会进入下一关快照，但这只是现状行为，不是经签字的连续 run policy：`lib/features/sweep/application/phase0a_sweep_headless_runner.dart:22-26`。
- 方案把 injury threshold 明列 `PROPOSED`：`/Users/a10506/Desktop/二阶段优化方案.md:973`。

**旧否决冲突**

无直接 rejected 条目。不得把现有 Sweep 的“仅失败/timeout 停”误当 `MainlineRun` 决定。

**互斥选项**

- A：一产生新伤势即在本关结算后中断。
- B：仅当伤势导致下一关不再可战时中断；否则提示后继续。
- C：可见连续路径只提示伤势，由玩家在关间主动决定；若同时要开放无人值守连续路径，还必须另答“无人值守按 A 任意新伤即停”或“按 B 不再可战才停”。

若用户只回答 C 而未签无人值守停机规则，`MAINLINE-RUN-01` 仍不完整，整个父项继续 `policy_interface_only`。

**推荐安全默认（不是决定）**

不启用连续 run，不猜伤势阈值；单关仍按现有结算。

**M2 / M5 / M6 影响**

- M2：连续五关的停止条件、幂等结算与恢复点。
- M5：无直接继承；远征/断魂庄的停机策略需分别签。
- M6：伤势提示、继续/退出选择和无人值守摘要。

**需要用户回答的一句话**

> 请确认连续 MainlineRun 是出现任意新伤即中断、仅“不再可战”时中断，还是可见路径只提示并由玩家决定；若选最后一项，请同时确认无人值守路径按“任意新伤即停”还是“不再可战才停”？

## 4. 随行听剑

### 4.1 `MENTOR-INSIGHT-OCCUPANCY-01`：占用边界

**当前生产事实和精确证据**

- `lib/`、`data/`、`test/` 中没有“随行听剑”或 mentor insight 的生产实现、数据与测试；M0 scope 审计也记为无实现：`docs/audit/phase2_m0_scope_and_gap_review_2026-08-23.md:28-30`。
- 现有 `swordSongResonanceActive` / “剑鸣”是装备共鸣战斗效果，不是门人随行：`lib/shared/battle_shared/combatant_snapshot.dart:33,95`、`lib/shared/strings.dart:919-922`。
- 现有 occupancy 枚举没有 mentor：`lib/features/activity/domain/activity_occupancy.dart:1-25`。
- 核心概念与占用必须分开：听剑 core 已 frozen，但占用仍 proposed（`docs/dispatch/phase0a_overhaul/decision_registry.yaml:51-60`；方案 `:45-47,77`）。

**旧否决冲突**

无直接 rejected 条目；但不能由 frozen 核心概念推导占用时长、互斥对象或崩溃释放点。

**互斥选项**

- A：只占用单关；成功、失败、退出或幂等恢复结算后立即释放。
- B：占用整个 `MainlineRun`；run 成功、失败、主动退出或恢复终止才释放。
- C：不持久占用，只在结算发成长时再次校验；接受并发状态变化导致不发奖励。

每个选项还必须逐项回答与闭关、远征、断魂庄、疗伤是否互斥。A/B/C 只回答占用粒度，不代表这四个布尔决定已被签字；任一互斥项未答时，整个决策仍保持 `production_path_disabled`。

**推荐安全默认（不是决定）**

沿用 `production_path_disabled`：用户未签占用和释放语义前不开放生产路径。单关占用只是较窄候选，也不是已选结论。

**M2 / M5 / M6 影响**

- M2：首通样板不能接真实听剑结算。
- M5：占用聚合是共享基础，但各模式不得默认允许听剑。
- M6：门人调度、占用冲突、退出和崩溃恢复显示。

**需要用户回答的一句话**

> 请确认随行听剑是 A 只占用单关、B 锁定整个 MainlineRun，还是 C 不持久占用而只在结算时复核；同时明确退出/中断/崩溃恢复的释放点，并逐项回答与闭关、远征、断魂庄、疗伤是否互斥？

### 4.2 `MENTOR-INSIGHT-RATE-01`：成长对象、比例与上限

**当前生产事实和精确证据**

- 当前无生产发放路径，因此没有“现行比例”可继承。
- 方案仍待确定个人 EXP / 主修熟练、比例、每关 cap（`/Users/a10506/Desktop/二阶段优化方案.md:47,77`）。
- registry 明确标为 `tuning`，安全动作是 `defer_value_to_simulation`：`docs/dispatch/phase0a_overhaul/decision_registry.yaml:62-65`。

**旧否决冲突**

无直接 rejected 条目。风险不是旧否，而是把未模拟的候选比例硬编码或把 occupancy 与 rate 一票批准。

**互斥选项**

- A：只发个人 EXP。
- B：只发主修熟练。
- C：二者拆分发放；比例和每关 cap 分别配置。

候选值来源还需二选一：用户现在给出候选值，或授权在占用/幂等合同签后经数据与模拟生成候选值。两种来源都不是定标；候选值仍必须经 YAML、经济/红线模拟与真人试玩验证，验证前不得标记 frozen 或接入生产。

**推荐安全默认（不是决定）**

不发成长，不写生产数值；等占用、首通 claim 幂等和经济模拟都有证据再定标。

**M2 / M5 / M6 影响**

- M2：首通奖励 settlement 与 claim 幂等。
- M5：无直接玩法依赖，但共享占用/成长服务不能先假设比例。
- M6：奖励预览与结算报告。

**需要用户回答的一句话**

> 请确认听剑首通成长发个人经验、主修熟练或二者，以及比例与每关上限的候选值是现在提供还是授权模拟生成？无论哪种来源，都仍需完成 YAML、模拟与真人试玩 Gate 后才能定标。

## 5. 心魔

### 5.1 `INNER-DEMON-CULTIVATION-01`：失败是否扣主修修炼度

**当前生产事实和精确证据**

- 当前参数为 `main_cultivation_multiplier: 0.90`：`data/numbers.yaml:1746-1747`。
- typed def 只保留这一个主修扣减字段，并拒绝旧 legacy keys：`lib/data/defs/inner_demon_def.dart:213-243`。
- 生产 `applyFailurePenalty` 保持永久内力不变、施加内息紊乱，并把主修 progress `floor(old × multiplier)`：`lib/features/inner_demon/application/inner_demon_service.dart:65-107`。
- 测试明确钉住扣 10%、不掉层和 disorder cap：`test/features/inner_demon/application/inner_demon_failure_penalty_test.dart:11-15,136-203`。
- 物理伤势已豁免，不能再把它列作当前待修：`lib/features/combat_shared/application/combat_resolution_service.dart:238-283`。
- 是否保留主修扣减仍是 proposed：`docs/dispatch/phase0a_overhaul/decision_registry.yaml:67-77`；方案 `:49,360,442`。

**旧否决冲突**

无直接 rejected 条目。关键冲突是当前生产行为与方案中“是否保留”尚未签字，不能用现状自动封板。

**互斥选项**

- A：保留当前主修进度扣 10%，不掉层。
- B：取消主修进度扣减，只保留内息紊乱。
- C：保留扣减方向但改为分阶段可调；这会另外产生数值 `TUNING`，不能在本题里暗定比例。

**推荐安全默认（不是决定）**

沿用 `preserve_current_behavior`，即在用户回答前继续 10%；这只是避免无授权改变生产行为。

**M2 / M5 / M6 影响**

- M2：仅共享 FailurePolicy seam 受影响，无需扩展黑风寨产品路径。
- M5：心魔生产结算、重试和突破回退直接阻塞。
- M6：失败/归来报告必须显示最终签字结果。

**需要用户回答的一句话**

> 请确认心魔失败继续保留当前主修进度扣 10%，取消扣减而只保留内息紊乱，还是保留扣减方向并另行调参？

### 5.2 `INNER-DEMON-AI-01`：七名、七考验与七套 AI 的映射

**当前生产事实和精确证据**

- 七个 canon 名称和 narrative anchor 已存在：`data/stages.yaml:5251-5369`；enemy team 都为空，由 mapper 动态镜像玩家，07 另有 `surviveTicks: 20`。
- 01–07 的逐关差异首先是镜像 buff：`data/numbers.yaml:1722-1733`。05/06/07 共用蓄力 + 脆弱窗，05/06 另有 output multiplier，07 是生存条件：`data/numbers.yaml:1768-1787`。
- mapper 只有一条 `mapInnerDemon` 路径，按是否有 vulnerability 注入同一 charge mechanic，并未绑定七种人格 AI：`lib/features/battle/application/phase0a/phase0a_stage_content_mapper.dart:235-336`。
- enemy AI 对所有关卡使用同一“靠近 → 选最高倍率可用技能 → 普攻”逻辑：`lib/features/battle/application/phase0a/phase0a_enemy_ai_adapter.dart:27-109`。
- `mechanic_mirror_start_action_point: -2000` 虽能被 typed def 解析，但固定基线运行侧没有消费，敌人仍走通用初始攻击冷却：`lib/features/battle/application/phase0a/phase0a_stage_content_mapper.dart:740-799`。因此它也不能作为七画像已存在的证据。
- 当前专项测试覆盖镜像、05 窗口和 07 生存，不证明七种 AI 已实现：`test/features/mainline/presentation/phase0a_mainline_wiring_test.dart:106-171`。

**旧否决冲突**

无直接 rejected 条目。旧候选映射在方案中明确仍是 `PROPOSED`，不能当 production fact 或自动冻结（方案 `:435-444`）。

**候选映射（提案，不是决定）**

| 心魔 | 叙事锚证据 | 旧候选机制 |
|---|---|---|
| 贪 | 求胜/夺强：`data/narratives/stages/stage_inner_demon_01_opening.yaml:4-9` | 强攻、过度追击 |
| 嗔 | 旧怨/怒意：`data/narratives/stages/stage_inner_demon_02_opening.yaml:4-9` | 受击反击 |
| 痴 | 执著/铜镜：`data/narratives/stages/stage_inner_demon_03_opening.yaml:4-10` | 重复追击 |
| 慢 | 自满/安歇：`data/narratives/stages/stage_inner_demon_04_opening.yaml:4-11` | 护体 |
| 疑 | 疑师/犹疑：`data/narratives/stages/stage_inner_demon_05_opening.yaml:4-12` | 虚招 |
| 空 | 空无/生存压力：`data/narratives/stages/stage_inner_demon_06_opening.yaml:4-12` | 偏生存 |
| 真 | 真我/终局照见：`data/narratives/stages/stage_inner_demon_07_opening.yaml:4-13` | 分阶段综合 |

**互斥选项**

- A：批准上表一一映射，后续仅调参数。
- B：保持当前 01–04 通用镜像、05–07 共同窗口、07 生存条件，不新增七画像。
- C：先补“canon / narrative / 行为原语 / 可测试结果”四列矩阵，再逐名由用户改写和冻结。

**推荐安全默认（不是决定）**

沿用 `keep_existing_ai`。若要继续设计，C 是较安全的审查路径，但它也不是对任何一套行为的批准。

**M2 / M5 / M6 影响**

- M2：只可提供共享 AI 原语，不能提前绑定七画像。
- M5：心魔七关迁移与专项验收直接阻塞。
- M6：只消费入口/说明；不应由 UI 反向决定 AI。

**需要用户回答的一句话**

> 请确认七心魔采用“贪强攻、嗔反击、痴追击、慢护体、疑虚招、空生存、真综合”的候选映射，保持现有通用镜像，还是先逐关补矩阵再另行冻结？

## 6. 方案中的其他未决与登记缺口

### 6.1 `UNREGISTERED-UNLOCK-01`：渐进解锁精确章点

**当前生产事实和精确证据**

- 方案把精确章点列为 `PROPOSED`（`/Users/a10506/Desktop/二阶段优化方案.md:29-30`），并给出建议：Ch1 听到塔、Ch2 轻功、首门人后差遣、约 Ch4 群战、Ch6 + 门人后远征、首 token 后断魂庄、境界阈值后心魔（`:569-580`）。
- 当前生产并未采用该完整矩阵；例如轻功和群战都在 `stage_06_05` 后解锁：`data/numbers.yaml:1828,1915`，专项测试为 `test/features/light_foot/application/light_foot_service_test.dart:24-37`、`test/features/mass_battle/application/mass_battle_service_test.dart:25-36`。
- decision registry 没有本项独立 ID。

**旧否决冲突**

新建一级入口或百科式导航可能碰撞章节回顾/百科旧否；单纯调整既有入口 gate 不自动等同重开，但必须与 `REOPEN-CHRONICLE-01` 分离。

**互斥选项**

- A：整体批准方案 §11.3 的建议章点。
- B：保持当前全部解锁路径。
- C：逐模式另定，先给每个 gate 写 current → target 迁移表。

**推荐安全默认（不是决定）**

保持当前 gate，不新建导航；先在 registry 获得独立 ID 后再迁移。

**M2 / M5 / M6 影响**

- M2：Ch1 纵切及塔的 heard 状态相邻，但不得顺手改其他 gate。
- M5：全部特殊模式生产入口。
- M6：hidden / heard / open 状态与导航展示。

**需要用户回答的一句话**

> 请确认塔、轻功、差遣、群战、远征、断魂庄和心魔采用方案 §11.3 的建议章点、保持当前解锁路径，还是逐模式另定迁移表？

### 6.2 `UNREGISTERED-ECOLOGY-01`：章节/塔生态分配

**当前生产事实和精确证据**

- 方案把“部分章节生态分配”列为 `PROPOSED`（方案 `:29-30`）。
- 方案已给山匪、官军、门派、西凉、毒虫和寺院六类地域锚，但明确每个 stage 的最终主包、混入职责与数量仍待冻结：`:636-664`。
- 当前 `StageDef` 仍直接承载逐关 `enemyTeam`：`lib/data/defs/stage_def.dart:15-42,130-150`。L01 已加入由 caller 显式传入 YAML 的 `loadCombatCatalogManifest` 与纯结构 validator：loader 文件头明确是 `No IO, no defaults, no placeholders`：`lib/data/combat_encounter_catalog_loader.dart:1-25`；validator 也明确 pure/fail closed 且无 defaults/placeholders：`lib/data/validation/combat_encounter_catalog_validator.dart:1-8`。验收登记同时锁定“无 `GameRepository` / production IO / production YAML/data / host routing / tuning”：`docs/dispatch/phase0a_overhaul/task_registry.yaml:1055-1080`。
- 可复核检查 `rg --files data | rg 'combat_(catalog|encounter|archetype).*\.ya?ml$'` 仍无输出；现有 catalog YAML 只在 `test/fixtures/phase2/combat/catalog_loader/`，其读取也只见 loader 合同测试：`test/data/combat_encounter_catalog_loader_test.dart:1-45`。因此 typed loader 已存在，但上述六包仍未成为全局生产合同。
- decision registry 没有本项独立 ID。

**旧否决冲突**

无直接 rejected 条目。主要风险是把“地域锚已确认”偷换成“所有逐关分配、数量和刷出职责均已批准”。

**互斥选项**

- A：保持六类地域锚与 M2 Ch1 山匪纵切不变；其余逐 stage 分配先交付一张完整矩阵，经用户整体审核后再冻结与实现。
- B：保持六类地域锚与 M2 Ch1 山匪纵切不变；其余逐 stage 分配按 M7 章节/塔任务包分批审核，只冻结和实现已签批次。
- C：保持六类地域锚与 M2 Ch1 山匪纵切不变；其余所有逐 stage 分配继续暂缓，在完整矩阵获得用户签字前不实现。

**推荐安全默认（不是决定）**

六类已确认地域锚与 Ch1 山匪纵切保持不变；其余逐 stage 主包、混入职责与数量不批量铺开，等待独立 registry ID、分配矩阵和用户签字。

**M2 / M5 / M6 影响**

- M2：黑风寨山匪垂直切片。
- M5：塔、轻功、群战、远征等生态与性能预算。
- M6：无直接产品路径，仅可能展示已签生态名称。

**需要用户回答的一句话**

> 六类地域锚与 M2 Ch1 山匪纵切已确认且不在本题重开；请确认其余逐 stage 分配是 A 整体矩阵一次审核、B 按章节/塔任务包分批审核，还是 C 全部暂缓至完整矩阵签字？

### 6.3 `UNREGISTERED-GAUNTLET-BOT-01`：断魂庄前台 bot

**当前生产事实和精确证据**

- 方案真值表把断魂庄“前台 bot policy 待 G0”，完整首通后允许 headless 重刷：`/Users/a10506/Desktop/二阶段优化方案.md:468-486`。
- 当前断魂庄 headless runner 明确调用 `Phase0aHeadlessRunner` + `Phase0aPlayerBotAdapter`：`lib/features/boss_gauntlet/application/phase0a_gauntlet_stage_runner.dart:70-99`；可见宿主仍直接渲染人控 `Phase0aBattleScreen`：`lib/features/boss_gauntlet/presentation/phase0a_gauntlet_battle_host.dart:112-130`。能力存在不等于前台可见 bot 已批准。
- 本项未在方案顶部 `PROPOSED` 索引或 decision registry 获得独立 ID，属于登记缺口。

**旧否决冲突**

无直接 rejected 条目；风险是把“headless 已有”误推为“前台 bot 允许”。

**互斥选项**

- A：保留完整首通后的 headless 重刷，并另外开放前台可见 bot。
- B：保留完整首通后的 headless 重刷，明确不开放前台 bot。
- C：保留完整首通后的 headless 重刷，前台 bot 决策继续暂缓；未回答期间不开放前台 bot。

**推荐安全默认（不是决定）**

不新增前台 bot；保留现有/已规划 headless 能力边界，但不据此改变产品入口。

**M2 / M5 / M6 影响**

- M2：无直接主线路径。
- M5：断魂庄 automation truth table。
- M6：入口和自动状态展示。

**需要用户回答的一句话**

> 完整首通后的 headless 重刷已确认且不在本题重开；请确认前台可见 bot 是 A 开放、B 明确不开放，还是 C 继续暂缓？

## 7. 六个 `proposed_reopen`

`docs/spec/rejected_task_registry.md:115-120` 规定旧历史不得静默删除；重开必须保留原否决并记录日期与依据。下面的“推荐安全默认”全部逐字遵循 `docs/dispatch/phase0a_overhaul/decision_registry.yaml:128-168`，不构成重开。

### 7.1 `REOPEN-LOADOUT-PLAN-01`：亲战 / 差遣双装配

**当前生产事实和精确证据**

- `ActivityParticipationRequest.loadoutPlanId` 只是纯值对象字段，caller 仍负责 availability/occupancy/policy：`lib/features/battle/domain/phase0a/activity_participation_request.dart:1-5,32-80`。
- 生产 `lib/` 没有该 request 的消费接线，也没有每角色两套方案的存储或 UI；测试只覆盖值对象：`test/features/battle/domain/phase0a/activity_participation_request_test.dart:6-24,26-119`。
- 方案候选见 `:369-374,874-883,940-949`。

**旧否决冲突**

直接碰撞“Build 方案保存”：`docs/spec/rejected_task_registry.md:87`。

**互斥选项**

- A：不重开，继续现有单一装配。
- B：允许一次性活动入场快照，但不保存 preset。
- C：显式重开，持久化每角色亲战/差遣两套 preset。

**推荐安全默认（不是决定）**

`contract_not_enabled`：保留纯字段，不接生产、不新增存储/UI。

**M2 / M5 / M6 影响**

- M2：同装配 live/headless 对照可传 token，但不能声称有双方案。
- M5：各活动 entry/loadout snapshot。
- M6：调度、装配选择与编辑 UI。

**需要用户回答的一句话**

> 是否明确重开已否“Build 方案保存”，允许每角色持久化亲战/差遣两套装配，还是只使用现有单一装配或一次性活动快照？

### 7.2 `REOPEN-CHRONICLE-01`：章节卷轴 / 江湖纪事新导航

**当前生产事实和精确证据**

- 已有 stage list 内的“章节卷轴” timeline：`lib/features/mainline/presentation/stage_list_screen.dart:454-545`。
- 已有百科一级按钮和五个 tab：`lib/features/main_menu/presentation/main_menu.dart:618-624`、`lib/features/baike/presentation/baike_screen.dart:21-97`。
- 这些既有载体不是对新“江湖纪事”一级导航或内容迁移的授权；方案候选见 `:80-104,553-558`。

**旧否决冲突**

直接碰撞“章节回顾入口”和“江湖见闻录收藏百科”：`docs/spec/rejected_task_registry.md:23,85`。

**互斥选项**

- A：不重开，只复用现有 timeline / 百科载体。
- B：允许非一级、可选的章节叙事入口，不建设收藏百科。
- C：显式重开，新建江湖纪事一级导航并迁移章节内容。

**推荐安全默认（不是决定）**

`do_not_build_new_navigation`：保留现有载体，不新建一级入口。

**M2 / M5 / M6 影响**

- M2：关间叙事可用现有载体，不因新导航阻塞战斗纵切。
- M5：无直接路径。
- M6：信息架构和章节叙事搬迁直接受影响。

**需要用户回答的一句话**

> 是否选择 A 不重开并复用现有载体、B 仅允许非一级可选叙事入口，还是 C 明确重开已否“章节回顾入口/江湖见闻录收藏百科”并建设江湖纪事一级导航？

### 7.3 `REOPEN-TELEGRAPH-ICON-01`：Boss / 屏外威胁图标

**当前生产事实和精确证据**

- 当前已有非图标 charge 状态标签/横幅：`lib/features/battle/presentation/phase0a/phase0a_battle_screen.dart:1084-1100,1385-1401`。
- widget 测试验证现有 charge warning：`test/features/battle/presentation/phase0a/phase0a_mechanics_presentation_test.dart:167-186`。
- 方案候选含威胁图标和 Boss 预警：`:254-256,620-623,757-780`。

**旧否决冲突**

直接碰撞“Boss 技能预兆图标”：`docs/spec/rejected_task_registry.md:24`。

**互斥选项**

- A：不重开，继续形状、纹理、音效、文字和现有非图标预警。
- B：仅允许屏外威胁方向 icon，不做 Boss 技能图标。
- C：显式重开，允许全 Boss 技能预兆 icon。

**推荐安全默认（不是决定）**

`retain_existing_non_icon_telegraphs`。

**M2 / M5 / M6 影响**

- M2：黑风寨 HUD 与 Boss 可读性。
- M5：特殊模式 Boss / 屏外威胁呈现。
- M6：无直接路径。

**需要用户回答的一句话**

> 是否选择 A 继续现有非图标预警、B 只允许屏外威胁方向 icon，还是 C 明确重开已否“Boss 技能预兆图标”并允许全 Boss 技能预兆 icon？

### 7.4 `REOPEN-RETURN-SUMMARY-01`：统一归来报告

**当前生产事实和精确证据**

- 当前闭关/被动收益已有独立 OfflineRecap 启动 gate 与只读卡：`lib/features/seclusion/presentation/offline_recap_gate.dart:13-80`、`lib/features/seclusion/presentation/offline_recap_card.dart:11-65`。
- 远征另有独立 recap：`lib/features/expedition/presentation/expedition_recap_screen.dart:10-18`。
- 当前没有多活动统一归来报告；方案候选见 `:385-393`。

**旧否决冲突**

直接碰撞“闭关归来事件小结”：`docs/spec/rejected_task_registry.md:59`。

**互斥选项**

- A：不重开，保留当前各自摘要。
- B：允许聚合事实结算，但不新增事件小结或统一叙事报告。
- C：显式重开，建设多活动统一归来报告。

**推荐安全默认（不是决定）**

`preserve_current_offline_summary`。

**M2 / M5 / M6 影响**

- M2：扫荡继续独立 recap，不因统一报告阻塞。
- M5：远征等模式的独立返回结果。
- M6：统一报告与入口。

**需要用户回答的一句话**

> 是否选择 A 保留当前各活动独立摘要、B 只聚合事实结算而不做事件小结，还是 C 明确重开已否“闭关归来事件小结”并建设多活动统一归来报告？

### 7.5 `REOPEN-LIGHTFOOT-REWARD-01`：轻功差异化收益

**当前生产事实和精确证据**

- 轻功仍走通用 `runStageFlow`：`lib/features/light_foot/presentation/light_foot_screen.dart:91-109`。
- 奖励来自各 stage 现有 `dropTable` / `baseExp`，例如 `data/stages.yaml:5424-5433,5484-5493`；没有新专属奖励合同。
- 方案候选见 `:425,527`。

**旧否决冲突**

直接碰撞“轻功关卡收益差异化”：`docs/spec/rejected_task_registry.md:51`。

**互斥选项**

- A：不重开，保持现有奖励。
- B：只加无属性个人记录/外观展示，不增加专属经济资源。
- C：显式重开，增加轻功专属收益。

**推荐安全默认（不是决定）**

`keep_existing_rewards`。

**M2 / M5 / M6 影响**

- M2：无直接路径。
- M5：轻功迁移、RewardPolicy 和经济验收。
- M6：奖励展示。

**需要用户回答的一句话**

> 是否明确重开已否“轻功关卡收益差异化”，增加专属收益、只补无属性个人记录，还是保持现有奖励？

### 7.6 `REOPEN-FAILURE-DIAGNOSIS-01`：失败原因展示 / 建议 UI

**当前生产事实和精确证据**

- 已有纯领域 `FailureReason` 四枚举：`lib/shared/battle_shared/failure_policy.dart:1-28`。
- `FailurePolicyResolver` 在生产 `lib/` 只有定义，尚未接通面向玩家的通用诊断 UI；Sweep 只显示固定 defeat/timeout 原因：`lib/features/sweep/presentation/sweep_screen.dart:166-243`。
- 方案候选把失败/返程原因、伤势和建议展示放进统一结果：`:389,969-971,1346`。

**旧否决冲突**

直接碰撞“失败原因诊断”：`docs/spec/rejected_task_registry.md:88`。

**互斥选项**

- A：不重开，domain reason 只用于日志/结算合同，不加新 UI。
- B：显式允许事实性失败/返程原因展示，但不给建议。
- C：显式重开建议型诊断 UI。

**推荐安全默认（不是决定）**

`keep_domain_failure_reason_without_new_advice_ui`。

**M2 / M5 / M6 影响**

- M2：失败结果可保留既有展示，不建建议 UI。
- M5：各模式 failure policy 与 reason 映射。
- M6：统一报告/失败 UI。

**需要用户回答的一句话**

> 是否明确重开已否“失败原因诊断”，允许面向玩家的事实性原因展示或建议型 UI，还是只保留领域 reason？

## 8. 全部广义 `TUNING` 的原子暂停队列

方案把秒数、倍率、数量预算、上限与性能目标定义为 `TUNING`（`/Users/a10506/Desktop/二阶段优化方案.md:29-31`），附录 B 列出十一组待校准参数（`:1526-1540`）。为避免“总体同意”歧义，本节把复合行拆为二十个可测试参数向量；仍含多个独立旋钮的向量另列“原子答复清单”。每个子 ID 继承所在小节的当前证据、旧否决、A/B/C 选项、安全默认和 M2/M5/M6 影响，用户可逐项回答；一句“全按建议值”不构成任何值的批准。它们的方向已 frozen，问题只是在何时、用什么证据定值。听剑 rate 已在 §4.2 单列，不在此重复。

本节所有 A 选项中的“给值”“冻结”“签硬 Gate”都只表示用户提供候选目标，不表示数值已定标，也不能绕过证据 Gate。无论选 A 还是 B，都必须经 YAML、红线验证、自动模拟和对应的真人试玩/双平台实机证据；验证前不得写入生产、不得把 `tuning` 改为 `frozen`。

### 8.1 `TUNE-FORWARD-FAN-01`：前向扇形边界

- **当前生产事实和精确证据**：单目标生产普攻已接 `ForwardFanScope(maxTargets: 1)`，并保留闭区间/严格扇角兼容：`lib/features/battle/domain/phase0a/realtime_combat_rules.dart:22-58`；当前 YAML 是射程 420、半角 0.72、CD 0.55s：`data/numbers.yaml:519-523`。
- **旧否决冲突**：无直接项；校准不得借机重开“武馆试招场”或“开局站位倾向”（`docs/spec/rejected_task_registry.md:19-20`）。
- **互斥选项**：A 用户现在给新边界；B 授权按 M2 五武器 A/B 样本定标；C 保持 420 / 0.72。
- **推荐安全默认（不是决定）**：C。
- **M2 / M5 / M6 影响**：M2 普攻/武器手感；M5 各模式复用命中规则；M6 输入/命中提示。
- **需要用户回答的一句话**：请确认前向扇形边界是 A 现在给新值、B 授权 M2 武器样本定标，还是 C 保持当前射程 420 / 半角 0.72？

### 8.2 `TUNE-OTHER-GEOMETRIES-01`：其余五几何默认边界

- **当前生产事实和精确证据**：六类纯 scope 已有类型与验证：`lib/features/battle/domain/phase0a/combat_geometry.dart:13-20,86-236`；但生产 skill behavior 仍只接受 `radial + caster + radius` 与 damage/pull/stagger/break：`lib/data/defs/phase0a_skill_behavior.dart:1-29,96-139`。自身圆、目标点圆、直线/胶囊、位移轨迹、自身状态尚无生产默认值。
- **旧否决冲突**：无直接项；不得把测试 fixture 数字写成产品合同。
- **互斥选项**：A 用户逐类给边界；B 授权每类先以 M2 样本定标；C 暂缓，继续现有 radial 行为。
- **推荐安全默认（不是决定）**：C。
- **M2 / M5 / M6 影响**：M2 五类 scope 纵切；M5 模式模板差异；M6 落点/预警展示。
- **需要用户回答的一句话**：请确认其余五几何默认边界是 A 现在逐类指定、B 授权 M2 样本定标，还是 C 暂缓并保持现有 radial 行为？

### 8.3 `TUNE-GEOMETRY-TARGET-CAP-01`：各几何目标上限

- **当前生产事实和精确证据**：纯 scope 会按稳定几何顺序与 target ID 排序后截断 `maxTargets`：`lib/features/battle/domain/phase0a/combat_geometry.dart:253-273`；生产普攻显式为 1：`lib/features/battle/domain/phase0a/realtime_combat_rules.dart:38-48`，旧 radial Q/R schema 没有 target cap：`lib/data/defs/phase0a_skill_behavior.dart:7-17,96-123`。
- **旧否决冲突**：无直接项。
- **互斥选项**：A 用户给六类 cap 表；B 授权按 M2/M5 密度样本定标；C 只保持普攻 cap=1，其余不接。
- **推荐安全默认（不是决定）**：C。
- **M2 / M5 / M6 影响**：M2 命中选择；M5 群战/塔目标预算；M6 目标提示。
- **需要用户回答的一句话**：请确认几何目标上限是 A 现在给六类 cap、B 授权密度样本定标，还是 C 只保持普攻 cap=1 而其余暂不接？

### 8.4 `TUNE-GEOMETRY-WALL-01`：墙体与场地边界规则

- **当前生产事实和精确证据**：当前 arena 只有矩形 bounds `[-640,640] × [-260,260]`：`data/numbers.yaml:510-518`；mapper 用它做初始排布（`lib/features/battle/application/phase0a/phase0a_stage_content_mapper.dart:613,738-741`），`lib/features/battle/domain/phase0a/combat_geometry.dart:13-236` 没有 wall/obstacle policy。
- **旧否决冲突**：无直接项；不得借场地规则重开“开局站位倾向”（`docs/spec/rejected_task_registry.md:20`）。
- **互斥选项**：A 全局签 stop/clip/pass-through；B 每几何/技能显式配置；C M2 先按无墙 + arena bounds 现状。
- **推荐安全默认（不是决定）**：C。
- **M2 / M5 / M6 影响**：M2 场地纵切；M5 轻功/群战边界；M6 碰撞/越界反馈。
- **需要用户回答的一句话**：请确认墙体规则是 A 全局签 stop/clip/pass-through、B 每技能显式配置，还是 C 先保持无墙并只受 arena bounds 约束？

### 8.5 `TUNE-WEAPON-TIMELINE-01`：五武器前摇 / 命中 / 收招

- **当前生产事实和精确证据**：生产 `SkillDef` 只有伤害、真气和 cooldown 字段：`lib/data/defs/skill_def.dart:35-53,114-141`；`ActionTimelineConfig` 虽有 windup/active/recovery ticks，却是纯候选且无生产 consumer：`lib/features/battle/domain/phase0a/action_timeline.dart:1-12,26-72`，可复核 `rg -n 'ActionTimelineConfig' lib` 只命中该定义文件。当前 Phase0A 玩家普攻共用 `attack_cooldown_seconds: 0.55`：`data/numbers.yaml:519-523`。
- **旧否决冲突**：无直接项；定标不得重开“武馆试招场”或敌方连环窗口（`docs/spec/rejected_task_registry.md:19,32`）。
- **互斥选项**：A 用户逐武器给三段值；B 授权 input-latency/同核 harness 后定；C 暂缓，继续现有 cooldown 即时结算。
- **推荐安全默认（不是决定）**：C；纯 timeline contract 不接生产。
- **M2 / M5 / M6 影响**：M2 五武器手感与 live/headless parity；M5 全战斗模式；M6 键位/HUD 只消费最终时序。
- **需要用户回答的一句话**：请确认五武器前摇、命中和收招是 A 现在逐值指定、B 授权 harness 后定标，还是 C 暂缓并维持现有即时结算？

原子答复清单（每行都是独立一句话问题）：

- `TUNE-TIMELINE-SWORD-01`：请确认剑的前摇/生效/收招是 A 现在给值、B 授权 M2 定标，还是 C 维持现状？
- `TUNE-TIMELINE-HEAVY-01`：请确认重兵器的前摇/生效/收招是 A 现在给值、B 授权后续武器样本定标，还是 C 维持现状？
- `TUNE-TIMELINE-FLEXIBLE-01`：请确认软兵器的前摇/生效/收招是 A 现在给值、B 授权后续武器样本定标，还是 C 维持现状？
- `TUNE-TIMELINE-DUAL-01`：请确认双持的前摇/生效/收招是 A 现在给值、B 授权后续武器样本定标，还是 C 维持现状？
- `TUNE-TIMELINE-HIDDEN-01`：请确认暗器的前摇/生效/收招是 A 现在给值、B 授权后续武器样本定标，还是 C 维持现状？

### 8.6 `TUNE-WEAPON-QI-01`：五武器 / 招式真气收支

- **当前生产事实和精确证据**：`SkillDef.qiDelta` 正值产气、负值耗气：`lib/data/defs/skill_def.dart:40-48,143-149`；现有生产技能 YAML 已逐招给值，例如基础三招为 `+20/-30/-60`：`data/skills.yaml:80-107,123-150`。
- **旧否决冲突**：无直接项；必须继续守内力/真气红线。
- **互斥选项**：A 用户给每武器/招式收支；B 授权战斗时长与施放频率模拟后调 YAML；C 保持现值。
- **推荐安全默认（不是决定）**：C；不改 `qiDelta`。
- **M2 / M5 / M6 影响**：M2 五武器循环；M5 全模式续航；M6 真气/技能可用态展示。
- **需要用户回答的一句话**：请确认五武器真气收支是 A 现在逐值指定、B 授权施放频率模拟后定标，还是 C 保持当前 YAML？

### 8.7 `TUNE-WEAPON-MULTIPLIER-01`：五武器 / 招式倍率

- **当前生产事实和精确证据**：生产值来自 `SkillDef.powerMultiplier`：`lib/data/defs/skill_def.dart:35-43`；现有 YAML 逐招给值，且全局硬上限 8000：`data/skills.yaml:80-107,123-150`、`data/numbers.yaml:170-178`。
- **旧否决冲突**：无直接项；不得越过全局倍率/可见伤害红线。
- **互斥选项**：A 用户给逐招倍率；B 授权 damage harness/红线测试后调 YAML；C 保持现值。
- **推荐安全默认（不是决定）**：C。
- **M2 / M5 / M6 影响**：M2 五武器伤害占比；M5 全模式平衡；M6 只展示最终值。
- **需要用户回答的一句话**：请确认五武器招式倍率是 A 现在逐值指定、B 授权 damage harness 后定标，还是 C 保持当前 YAML？

### 8.8 `TUNE-DODGE-WINDOW-01`：闪避无敌窗 / 完美闪避窗

- **当前生产事实和精确证据**：当前生产有基础 evasion rate 与 0.95 rate cap：`data/numbers.yaml:150-178`；纯 defense resolver 只接收 caller 给出的 `dodgeSucceeded`，没有窗口长度：`lib/features/battle/domain/phase0a/defense_resolution.dart:94-142,238-245`。可复核 `rg -n 'perfectDodge|perfect_dodge|dodgeWindow|dodge_window|invulner' lib data` 无生产窗口字段。
- **旧否决冲突**：无直接项。
- **互斥选项**：A 用户给普通/完美窗口；B 授权输入延迟与真人试玩后定；C 暂缓，不接 timing dodge。
- **推荐安全默认（不是决定）**：C；不从 evasion rate 推导时窗。
- **M2 / M5 / M6 影响**：M2 人控防御与同核输入；M5 全模式；M6 输入提示/HUD。
- **需要用户回答的一句话**：请确认闪避无敌窗与完美闪避窗是 A 现在给值、B 授权输入延迟和试玩后定标，还是 C 暂缓不接 timing dodge？

原子答复清单：

- `TUNE-DODGE-IFRAME-01`：请确认主动闪避无敌窗是 A 现在给值、B 授权 M2 输入/试玩定标，还是 C 暂不接生产？
- `TUNE-PERFECT-DODGE-01`：请确认完美闪避窗是 A 现在给值、B 授权 M2 输入/试玩定标，还是 C 暂不做完美层？

### 8.9 `TUNE-DEFENSE-01`：护盾吸收、化解窗口、反伤上限

- **当前生产事实和精确证据**：`lib/features/battle/domain/phase0a/defense_resolution.dart` 顶部明确是“Pure, unconnected candidate”；它接受 caller 提供的 shield absorption、parry 成功与 counter upper bound：`lib/features/battle/domain/phase0a/defense_resolution.dart:1-16,94-142,238-282`，生产 reducer 尚未提供这些数值。
- **旧否决冲突**：无直接项。
- **互斥选项**：A 用户给三类值；B 授权防御矩阵/极值红线模拟后定；C 保持 pure contract 不接生产。
- **推荐安全默认（不是决定）**：C。
- **M2 / M5 / M6 影响**：M2 防御链；M5 Boss/特殊模式；M6 防御反馈展示。
- **需要用户回答的一句话**：请确认护盾吸收、化解窗口和反伤上限是 A 现在逐值指定、B 授权防御矩阵后定标，还是 C 暂不接生产？

原子答复清单：

- `TUNE-SHIELD-ABSORPTION-01`：请确认护盾吸收是 A 现在给值、B 授权防御矩阵定标，还是 C 暂不接生产？
- `TUNE-PARRY-WINDOW-01`：请确认化解窗口是 A 现在给值、B 授权输入/防御矩阵定标，还是 C 暂不接生产？
- `TUNE-COUNTER-CAP-01`：请确认反击单次/每秒上限与 Boss 折算是 A 现在给表、B 授权极值模拟定标，还是 C 先以零伤害反击保持关闭？

### 8.10 `TUNE-POSTURE-01`：姿态容量、恢复、Boss 折算

- **当前生产事实和精确证据**：`lib/features/battle/domain/phase0a/posture.dart` 明确“Pure posture domain candidate”“no production wiring, repositories, or gameplay defaults”；capacity、vulnerability ticks 和恢复 policy 都要求 caller 显式提供：`lib/features/battle/domain/phase0a/posture.dart:1-24,26-61`。`rg -n 'PostureConfig' lib` 只命中该定义文件。
- **旧否决冲突**：无直接项。
- **互斥选项**：A 用户给容量/恢复/Boss 折算；B 授权 M2 破势样本定标；C 保持 pure contract 不接生产。
- **推荐安全默认（不是决定）**：C。
- **M2 / M5 / M6 影响**：M2 破势纵切；M5 各 Boss/群战；M6 姿态条和战报。
- **需要用户回答的一句话**：请确认姿态容量、恢复和 Boss 折算是 A 现在逐值指定、B 授权 M2 样本定标，还是 C 暂不接生产？

原子答复清单：

- `TUNE-POSTURE-CAPACITY-01`：请确认姿态容量是 A 现在给值、B 授权 M2 样本定标，还是 C 暂不接生产？
- `TUNE-POSTURE-RECOVERY-01`：请确认破绽持续与结束后 reset/recover 是 A 现在给合同、B 授权 M2 样本定标，还是 C 暂沿旧 stagger/charge？
- `TUNE-POSTURE-BOSS-01`：请确认 Boss control→posture 折算是 A 现在给值、B 授权 Boss 样本定标，还是 C 暂不接生产？

### 8.11 `TUNE-ACTIVE-LIMIT-01`：各模式同屏 activeLimit

- **当前生产事实和精确证据**：当前主线普通关是 2/3/4 三波、Boss 是 2/3 铺垫 + 1 Boss，单波最高 4：`data/numbers.yaml:1836-1865`；typed `CombatEncounterSpawnConfig.activeLimit` 要求 caller 显式给值：`lib/data/defs/combat_encounter_def.dart:37-83`。L01 纯结构 validator 验输入，loader 再把 caller-provided 值原样组装进 typed def：`lib/data/validation/combat_encounter_catalog_validator.dart:1-8`、`lib/data/combat_encounter_catalog_loader.dart:228-249`；这两者的验收边界仍明确无 `GameRepository` / production IO / production YAML/data / host routing / tuning：`docs/dispatch/phase0a_overhaul/task_registry.yaml:1076-1080`。方案候选为普通主线 8/12/16、塔 14、群战 18/24 等（`:601-612,1434-1440`）。
- **旧否决冲突**：无直接项；不得靠降低真实敌人数做画质选项。
- **互斥选项**：A 现在冻结各模式 activeLimit 表；B 授权 M2/M5 按档压测后定标；C 保持当前单波最高 4。
- **推荐安全默认（不是决定）**：C；typed 字段不接生产默认。
- **M2 / M5 / M6 影响**：M2 Ch1 8/12/16 压测；M5 塔/群战/特殊模式；M6 HUD 可读性。
- **需要用户回答的一句话**：请确认各模式同屏 activeLimit 是 A 现在冻结、B 授权 M2/M5 分档压测后定标，还是 C 保持当前主线单波最高 4？

### 8.12 `TUNE-REINFORCEMENT-01`：不同模板的补兵阈值

- **当前生产事实和精确证据**：typed `CombatEncounterSpawnConfig` 要求 caller 显式给 `activeLimit` 与 `reinforcementThreshold`，schema 不提供默认值：`lib/data/defs/combat_encounter_def.dart:37-83`；L01 纯结构 validator 验输入，loader 只将两值从 caller-provided YAML 透传到 def：`lib/data/validation/combat_encounter_catalog_validator.dart:1-8`、`lib/data/combat_encounter_catalog_loader.dart:228-249`。其验收边界仍排除 `GameRepository` / production IO / production YAML/data / host routing / tuning：`docs/dispatch/phase0a_overhaul/task_registry.yaml:1076-1080`。方案 20%–30% 只是候选（`:599-612,1533`）。
- **旧否决冲突**：无直接项；不得与未签生态分配合并批准。
- **互斥选项**：A 冻结各模板具体百分比；B 授权 M2/M5 密度压测后定；C 暂缓，继续当前 wave/spawn。
- **推荐安全默认（不是决定）**：C。
- **M2 / M5 / M6 影响**：M2 Ch1 刷出；M5 群战/塔/模式；M6 无直接路径。
- **需要用户回答的一句话**：请确认各模板补兵阈值是 A 现在冻结具体值、B 授权密度压测后定标，还是 C 暂缓并保持当前刷出？

### 8.13 `TUNE-ATTACK-TOKEN-01`：近战与远程 / 冲锋令牌配比

- **当前生产事实和精确证据**：typed token schema 明确四类 melee/ranged/charge/support，所有预算必须 caller 显式提供且默认值为空：`lib/data/defs/combat_encounter_def.dart:10-35`；archetype role 只声明 token kind：`lib/data/defs/combat_enemy_archetype_def.dart:1-50`。当前接缝是 observe-only，不会拦截 enemy intent：`lib/features/battle/application/phase0a/attack_token_observe_only_observer.dart:11-47`；2–4 近战与其他配比尚未进生产。
- **旧否决冲突**：无直接项；不得借令牌重开敌方连环窗口或“敌 AI 集火”（`docs/spec/rejected_task_registry.md:32-33`）。
- **互斥选项**：A 冻结方案配比；B 授权公平性/屏外压力模拟后定；C 保持 observe-only/未接线。
- **推荐安全默认（不是决定）**：C。
- **M2 / M5 / M6 影响**：M2 Ch1 可读性与公平性；M5 高密度模式；M6 威胁反馈。
- **需要用户回答的一句话**：请确认攻击令牌配比是 A 现在冻结、B 授权公平性模拟后定标，还是 C 保持未接生产？

原子答复清单：

- `TUNE-TOKEN-MELEE-01`：请确认 melee 令牌预算是 A 现在给值、B 授权 M2 以 2/3/4 档压测，还是 C 继续 observe-only？
- `TUNE-TOKEN-RANGED-01`：请确认 ranged 令牌预算是 A 现在给值、B 授权屏外压力压测，还是 C 继续 observe-only？
- `TUNE-TOKEN-CHARGE-01`：请确认 charge 令牌预算是 A 现在给值、B 授权预警公平性压测，还是 C 继续 observe-only？
- `TUNE-TOKEN-SUPPORT-01`：请确认 support 令牌预算是 A 现在给值、B 授权组合压测，还是 C 继续 observe-only？

### 8.14 `TUNE-STAGE-COUNT-01`：各关总量区间内的精确编排

- **当前生产事实和精确证据**：当前 `StageDef` 直接读取逐关 `enemyTeam`，群战另读 wave/count 列表：`lib/data/defs/stage_def.dart:15-42,63-71,130-164`；`CombatEncounterDef` 要求显式 spawn entries/config：`lib/data/defs/combat_encounter_def.dart:206-256`。L01 纯结构 validator 验输入，loader 已能把 caller-provided encounter YAML 组装成 typed def：`lib/data/validation/combat_encounter_catalog_validator.dart:1-8`、`lib/data/combat_encounter_catalog_loader.dart:228-316`；但只有 test fixtures，验收边界明确无 `GameRepository` / production IO / production YAML/data / host routing / tuning：`test/data/combat_encounter_catalog_loader_test.dart:10-45`、`docs/dispatch/phase0a_overhaul/task_registry.yaml:1076-1080`。方案总量区间见 `:599-612`，不是逐关定值。
- **旧否决冲突**：无直接项；须与 §6.2 生态分配分开签。
- **互斥选项**：A 现在逐关给精确数量；B 授权每个 M2/M5 纵切压测后定；C 保持当前逐关数据。
- **推荐安全默认（不是决定）**：C。
- **M2 / M5 / M6 影响**：M2 Ch1 五关；M5 每个特殊模式；M6 无直接路径。
- **需要用户回答的一句话**：请确认各关精确敌量是 A 现在逐关指定、B 授权按纵切压测后定标，还是 C 保持当前数据？

### 8.15 `TUNE-INJURY-01`：伤势概率、严重度与恢复时长

- **当前生产事实和精确证据**：现行不是概率模型：每场参与者都累积轻伤；硬仗战败全员重伤，硬仗惨胜按低血阈值重伤：`lib/features/injury/application/injury_service.dart:24-63`。当前 YAML 为轻伤每层速度 -3、最多 5 层，重伤恢复 8h、内力上限 -15%、输出 ×0.85、低血阈值 25%：`data/numbers.yaml:2133-2144`。
- **旧否决冲突**：数值调参无直接冲突；不得把 `MainlineRun` 中断阈值夹带进本题，也不得重开“伤势与疗伤丹说明层”或“失败原因诊断”（`docs/spec/rejected_task_registry.md:69,88`）。
- **互斥选项**：A 用户给概率/严重度/时长；B 授权 failure harness 后改 YAML/规则；C 保持当前确定性规则和值。
- **推荐安全默认（不是决定）**：C。
- **M2 / M5 / M6 影响**：M2 replay/sweep 结算；M5 全活动失败/惨胜；M6 伤势展示。
- **需要用户回答的一句话**：请确认伤势概率、严重度和恢复时长是 A 现在逐值指定、B 授权 failure harness 后定标，还是 C 保持当前确定性规则？

原子答复清单：

- `TUNE-LIGHT-INJURY-01`：请确认轻伤发生频率/每层速度/叠层上限是 A 现在给值、B 授权连续战斗样本定标，还是 C 保持每场 +1、每层 -3、上限 5？
- `TUNE-HEAVY-TRIGGER-01`：请确认重伤触发是 A 现在给权重公式、B 授权 FailurePerformanceSnapshot 样本定标，还是 C 保持硬仗战败全员/惨胜 25% 低血阈值？
- `TUNE-HEAVY-DURATION-01`：请确认重伤恢复时长是 A 现在给值、B 授权可用性模拟定标，还是 C 保持基础 8h？
- `TUNE-HEAVY-SEVERITY-01`：请确认重伤属性严重度是 A 现在给值、B 授权红线模拟定标，还是 C 保持内力上限 -15% / 输出 ×0.85？

### 8.16 `TUNE-ACTIVITY-DURATION-01`：活动占用时间

- **当前生产事实和精确证据**：现行各活动分散定时：闭关开放式进行、完整收益 cap 72h（`data/numbers.yaml:1051-1062,1308-1312`）；远征普通/险关节点为 90/180 分钟（`data/expeditions.yaml:1-8`）；断魂庄是持续 run 而非真实时间项目。没有统一“活动占用时长”参数。
- **旧否决冲突**：无直接项；随行听剑占用语义必须先答 §4.1。
- **互斥选项**：A 用户逐活动给时长；B 授权按收益率/冲突率模拟后定；C 保持现有分散时长。
- **推荐安全默认（不是决定）**：C。
- **M2 / M5 / M6 影响**：M2 听剑只能保持禁用；M5 远征/断魂庄等；M6 调度与剩余时间。
- **需要用户回答的一句话**：请确认活动占用时间是 A 现在逐活动指定、B 授权收益与冲突模拟后定标，还是 C 保持现有分散时长？

### 8.17 `TUNE-REPEAT-REWARD-01`：重复通关奖励量

- **当前生产事实和精确证据**：主线重打继续发 EXP 和普通物料、秘籍仅首通：`lib/features/mainline/presentation/stage_entry_flow.dart:719-763`；断魂庄重复通关经验/领悟取首通一半并乘周目倍率：`lib/features/boss_gauntlet/application/gauntlet_service.dart:489-535`，当前 `reward_bonus_per_cycle` 为 0.25 且注释仍待经济探针：`data/numbers.yaml:2097-2105`。不同模式尚无统一重复奖励比例。
- **旧否决冲突**：若为轻功引入专属重复收益，直接碰撞 `REOPEN-LIGHTFOOT-REWARD-01`；本项不能重开它。
- **互斥选项**：A 用户逐模式给量；B 授权经济模拟后定；C 保持各模式现值。
- **推荐安全默认（不是决定）**：C。
- **M2 / M5 / M6 影响**：M2 replay/sweep；M5 各模式 RewardPolicy；M6 奖励摘要。
- **需要用户回答的一句话**：请确认重复奖励量是 A 现在逐模式指定、B 授权经济模拟后定标，还是 C 保持现值且不重开轻功专属收益？

原子答复清单：

- `TUNE-MAINLINE-REPEAT-REWARD-01`：请确认主线重打奖励是 A 现在给统一倍率、B 授权 M2 经济样本定标，还是 C 保持各关 dropTable/EXP 现状？
- `TUNE-GAUNTLET-REPEAT-REWARD-01`：请确认断魂庄重复奖励是 A 现在给倍率、B 授权 M5 经济样本定标，还是 C 保持经验/领悟取半？
- `TUNE-CYCLE-REWARD-01`：请确认高周目重复奖励倍率是 A 现在给值、B 授权周目经济样本定标，还是 C 保持 `reward_bonus_per_cycle: 0.25`？

### 8.18 `TUNE-ENTRY-TICKET-01`：世界观凭证产出

- **当前生产事实和精确证据**：当前断魂帖在远征每 10 节点固定产 1 张：`lib/features/expedition/domain/expedition_rules.dart:138-195`；塔在 16/33/49 层首通各 1 张且幂等：`lib/features/tower/application/tower_progress_service.dart:33-47,196-269`；断魂庄每次入场消耗 1 张：`lib/features/boss_gauntlet/application/gauntlet_service.dart:119-120,219-222`。
- **旧否决冲突**：无直接项；永久红线禁止把凭证做成每日票/过期票。
- **互斥选项**：A 用户现在改来源/数量；B 授权长期经济模拟后定；C 保持当前固定来源与数量。
- **推荐安全默认（不是决定）**：C。
- **M2 / M5 / M6 影响**：M2 无直接路径；M5 塔/远征/断魂庄；M6 入口库存与结算展示。
- **需要用户回答的一句话**：请确认断魂帖等凭证产出是 A 现在修改来源/数量、B 授权长期经济模拟后定标，还是 C 保持当前里程碑产出？

原子答复清单：

- `TUNE-TOWER-TICKET-01`：请确认塔断魂帖是 A 现在改层数/数量、B 授权 M5 经济样本定标，还是 C 保持 16/33/49 层各 1 张？
- `TUNE-EXPEDITION-TICKET-01`：请确认远征断魂帖是 A 现在改频率/数量、B 授权 M5 经济样本定标，还是 C 保持每 10 节点 1 张？

### 8.19 `TUNE-PERFORMANCE-MATRIX-01`：帧预算、高密度矩阵、headless 吞吐与 RSS

- **当前生产事实和精确证据**：旧 Route C 在提交 `597a243b` 的低密度生产 fixture 上记录 Mac p99 5.349–5.754ms、Windows 3.416–3.573ms，但明确不得外推到新 AOT/commit：`docs/audit/route_c_gate_closeout_2026-08-23.md:13-39`。M0 当前审计确认高密度、RSS、战斗时长、benchmark 自动化仍缺：`docs/audit/phase2_m0_performance_and_test_baseline_2026-08-23.md:112-137`；方案候选矩阵/阈值见 `:1430-1442`。
- **旧否决冲突**：无直接项；不能用旧低密度数字冒签新 Gate。
- **互斥选项**：A 现在把方案矩阵/阈值设为硬 Gate；B 授权 M2/M5 真实内容按矩阵采样后再冻结；C 只守现 Route C 相对回归，不新增高密度硬线。
- **推荐安全默认（不是决定）**：C；旧实测只作历史参考。
- **M2 / M5 / M6 影响**：M2 普通 8/12/16；M5 塔 14、群战 18/24、总量 50/150、headless/RSS；M6 真实 HUD 成本。
- **需要用户回答的一句话**：请确认性能矩阵是 A 现在设为硬 Gate、B 授权 M2/M5 真实内容采样后冻结，还是 C 暂只守现 Route C 相对回归？

原子答复清单：

- `TUNE-FRAME-BUDGET-01`：请确认 p99/严重慢帧与高密度视口矩阵是 A 现在设硬 Gate、B 授权真实内容采样后冻结，还是 C 暂只守现 Route C？
- `TUNE-HEADLESS-THROUGHPUT-01`：请确认 headless tick/场次吞吐阈值是 A 现在给值、B 授权 M2/M5 相对基线后冻结，还是 C 暂不设硬线？
- `TUNE-RSS-01`：请确认长时间群战 RSS/对象池有界阈值是 A 现在给值、B 授权 M5 长跑采样后冻结，还是 C 暂不设硬线？

### 8.20 `TUNE-WINDOWS-PERFORMANCE-01`：性能目标对应的最低 Windows 配置

- **当前生产事实和精确证据**：现有 Route C 脚本合同守 `p99 < 16.6ms`、至少 3000 帧与真实 Windows session，但明确不校验 CPU/GPU/RAM 目标：`test/route_c/route_c_windows_runner_contract_test.dart:5-36`。旧实体机是 Ryzen 7 5800X + RTX 4070 SUPER + 16GB，closeout 明确它不定义最低配置：`docs/audit/route_c_gate_closeout_2026-08-23.md:22-39`。M0 高密度、RSS 与当前提交基线仍缺：`docs/audit/phase2_m0_performance_and_test_baseline_2026-08-23.md:93-108,112-137`。方案目标见 `:1430-1442`。
- **旧否决冲突**：无直接项；不能用降低真实敌人数伪装低配适配。
- **互斥选项**：A 用户现在给最低 CPU/GPU/RAM；B 授权高密度 Mac/Windows Profile 后反推最低配置；C 暂不声明新最低配置，保留现 Gate。
- **推荐安全默认（不是决定）**：C；不把旧硬件数字当当前高密度结论。
- **M2 / M5 / M6 影响**：M2 普通 8/12/16 活跃基线；M5 塔/群战 14/18/24 与总量 50/150；M6 真实 HUD 同场成本。
- **需要用户回答的一句话**：请确认最低 Windows 配置是 A 现在指定、B 授权高密度双平台 Profile 后反推，还是 C 暂不新增声明并保留现 Gate？

## 9. 建议的回答格式（只记录用户决定）

用户可以只回答要先解锁的项，未回答项继续沿用本包的暂停态。例如：

```text
MAINLINE-REPLAY-PARTICIPANT-01 = C，实际参与者承担记录/成长/伤势。
MAINLINE-RUN-01 = 锁人:A；换装:B；伤势中断:B。
MENTOR-INSIGHT-OCCUPANCY-01 = A；RATE = 授权模拟后定标。
INNER-DEMON-CULTIVATION-01 = B。
INNER-DEMON-AI-01 = C。
REOPEN-* = 全部不重开。
```

示例只展示语法，**不代表本包推荐这些答案**。收到用户回答后，下一步应先更新 decision registry / rejected history，再派发对应 M1/M2/M5/M6 实现；不能直接从本包启动被否方向。对 `TUNING` 的回答只记录候选目标或模拟授权，须在 YAML、红线、自动模拟和真人试玩/实机 Gate 全部通过后才可单独冻结与接生产。

## 10. G0 当前可安全得出的唯一结论

在用户回答之前，可以继续的只有不选择未决产品语义的纯合同/证据工作；所有会固定参与者、连续 run、听剑、心魔惩罚、七心魔画像、解锁、未签的逐 stage 生态分配或 `proposed_reopen` 产品行为的路径都应保持上述暂停态。已确认的六类地域锚与 M2 Ch1 山匪纵切不被本闸门回退。本结论是执行闸门，不是对任一未决选项的拍板。

## 11. 本包验收证据边界

- 三路子 agent 分别核对长寿文档/方案、registry/M0、当前代码/测试；主会话交叉审查生产事实并校验引用路径。
- 在资源锁协调更新到达前，代码/测试核对子 agent 已启动三组 `flutter test --no-pub --no-test-assets` 纯合同/策略测试：`test/features/battle/domain/phase0a/activity_participation_request_test.dart` 5 个、`test/shared/battle_shared/failure_policy_resolver_test.dart` 11 个、`test/features/battle/application/phase0a/phase0a_player_bot_adapter_test.dart` 7 个，共 23 个测试用例通过。
- 依赖 Isar 的目标因当前只读 worktree 缺少被忽略的生成文件而未执行相关测试；没有运行 `build_runner`、没有补写生成文件，也没有把未运行的目标写成通过。
- 协调更新到达后没有再启动 Flutter/Dart/build_runner；最终收口只运行 `rg`、路径存在性、白名单、`git diff --check`、`git status` 等静态检查。
