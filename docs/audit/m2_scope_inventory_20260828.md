# 二阶段 M2 范围现状盘点（2026-08-28）

- 审计基线：`1ba913a633beb0fd8f9b47764161f47c54260707`
- 判定口径：只有定义且被生产路径消费才记“已实装”；candidate/test-only 不计生产实装。
- 结果汇总：已实装 `6/9`，部分实装 `2/9`，未实装 `1/9`。

## 1. 山匪四角色生态 — 已实装

- 证据：`data/combat/archetypes/bandits.yaml:2-60` 定义 `ch1_bandits` 族群与 `bandit_blade` / `bandit_crossbow` / `bandit_rope_raider` / `bandit_gong_leader` 四个 role variant；`lib/features/mainline/application/phase0a_mainline_repository_runtime_binding_adapter.dart:83-134` 按 `archetypeId + roleId` 解析 variant，并组装攻击集、外观与令牌绑定。
- 现状：已有“族群 archetype → 角色 variant”抽象且生产消费，不是四份零散 enemy 快照。

## 2. `stage_01_03` 总数/活跃数/攻击令牌 — 已实装

- 证据：`data/combat/encounters/black_wind_ridge.yaml:8-259` 实配刀匪 18 + 弩匪 10 + 索匪 10 + 锣首领 2 = `40` 敌，`active_limit: 12`，四类 token 各1、总额 `4`；`lib/data/validation/combat_encounter_runtime_contract_mapper.dart:29-66` 把字段原样映射到 `SpawnDirector` / `AttackTokenBudgets`。
- 生产消费：`lib/features/battle/domain/phase0a/spawn_director.dart:302-396` 以 `activeLimit` 截止补兵；`lib/features/battle/application/phase0a/phase0a_production_flow_assembler.dart:233-256` 实际装配 `AttackTokenEnforcingBatchGate`，`lib/features/battle/application/phase0a/attack_token_enforcing_batch_gate.dart:33-65` 会过滤未获准的攻击 intent；`lib/features/battle/application/phase0a/attack_token_observe_only_observer.dart:11-47` 另一 observer 确实只记录诊断，但它不是上述生产 enforcing gate。
- 现状：当前生产值为 `40 / 12 / 4`，分别落在 35–45、8–16、2–4 范围内，活跃限制与令牌限制均已 enforcing。

## 3. 第 1 章五关“破路/据点/伏击/斩将/斩将” — 部分实装

- 证据：`data/combat/manifest/stage_assignments.yaml:1-14` 只有 `stage_01_03` 迁移到 `ch1_encounter_03_ambush`，其余四关仍是 legacy；`lib/data/defs/stage_def.dart:100-179` 的 `StageDef`/loader 无 template/pattern 字段；`lib/features/battle/application/phase0a/phase0a_stage_content_mapper.dart:143-250` 的 legacy 主线只按 `ordinary` / `boss` 两种 profile 生成波次。
- 反向核对：`test/fixtures/phase2/combat/ch1_candidate/manifest/stage_assignments.yaml:1-18` 明标 candidate-only，在此才有 roadbreak/stronghold/ambush/commander/commander 五种 encounter 路由；生产 `data`/`lib` 反搜 `roadbreak|stronghold|破路|据点|斩将` 无对应五关配置。
- 现状：五关现由 `prevStageId`、敌人快照、Boss 标记和关联剧情区分；只有第 3 关的伏击 encounter 进入生产 typed encounter 路径。

## 4. 剑形态完整普攻链 — 未实装

- 证据：`lib/features/battle/domain/phase0a/basic_attack_chain.dart:1-5,59-133` 明标 candidate-only，虽定义 `WeaponType.sword` 和 `BasicAttackChain`，但注释明言不执行引用行为；`lib/features/battle/application/phase0a/phase0a_player_input_adapter.dart:147-165` 生产普攻每次只发一个 `Phase0aAttackIntent(moveKind: light)`。
- 反向核对：在 `lib/` 中排除 schema 本文后反搜 `BasicAttackChain|WeaponType|nextSegmentIndex` 无消费点；再以 `segment|combo|chain` 核对生产 input/reducer，无普攻段位状态。
- 现状：“武器形态”和连段算法仅存候选 schema/测试，生产是单段轻普攻。

## 5. 护盾/化解反击/聚怪/绝技 — 已实装

- 护盾：`lib/features/battle/presentation/phase0a/phase0a_battle_screen.dart:632-645` 的 E 键产生 `Phase0aDefenseAction.shield`，`lib/features/battle/domain/phase0a/phase0a_combat_reducer.dart:479-492` 落屏障吸收量与持续 tick。
- 化解/反击：同一输入处 F 键产生 `parry`，`lib/features/battle/domain/phase0a/phase0a_combat_reducer.dart:330-399,493-507` 结算化解窗、反击伤害与反击上限。
- 聚怪：`data/skills.yaml:29-48` 定义含 `pull` 的 `skill_phase0a_gather`，`lib/features/battle/application/phase0a/phase0a_player_input_adapter.dart:166-191` 生产发出 `Phase0aGatherIntent`，`lib/features/battle/domain/phase0a/phase0a_combat_reducer.dart:884-963` 计算拉拽落点并写回。
- 绝技：`data/skills.yaml:107-120` 定义 `SkillType.ultimate`，`lib/shared/battle_shared/player_combatant_snapshot_assembler.dart:214-233` 把角色的 ultimate 装入战斗快照，`lib/features/battle/application/phase0a/phase0a_stage_content_mapper.dart:1087-1119` 接入数字栏，`lib/features/battle/application/phase0a/phase0a_player_input_adapter.dart:222-249` 产生 `Phase0aSkillIntent`，`lib/features/battle/domain/phase0a/phase0a_combat_reducer.dart:1166-1331` 执行结算。
- 现状：四类都有真实输入→typed intent→reducer 生产消费链。

## 6. 新 HUD/聚合伤害/杂兵散墨/屏外提示/结果“下一关” — 部分实装

- 新 HUD — 已实装：`lib/features/battle/presentation/phase0a/phase0a_battle_screen.dart:693-775,1544-1645` 生产 Stack 挂载玩家血/内力/防御态与数字技能、Q/R 技能印。
- 聚合伤害 — 未实装：`lib/features/battle/presentation/phase0a/phase0a_vfx_controller.dart:154-173` 仍对每个伤害事件创建单独 popup，`lib/features/battle/presentation/phase0a/phase0a_battle_screen.dart:383-421` 只淘汰超量 popup 而不合并数值；反搜 `aggregate|coalesce|damage.*sum|聚合|合并伤害` 无表现层消费点。
- 杂兵散墨 — 已实装：`lib/features/battle/presentation/phase0a/phase0a_vfx_controller.dart:274-282` 把敌人死亡映射为 `defeatInk`，`lib/features/battle/presentation/phase0a/phase0a_battle_screen.dart:1735-1742,2784-2824` 按杂兵/精英分支绘制散墨。
- 屏外提示 — 未实装：反搜 `offscreen|off_screen|屏外|边缘提示` 与 `screen edge|indicator arrow|箭头提示` 均无 battle presentation 命中；唯一相关生产逻辑是 `lib/features/battle/domain/phase0a/attack_token_director.dart:239-252` 拒绝屏外高影响攻击，它不产生 UI indicator。
- 结果“下一关” — 已实装：`lib/features/mainline/presentation/stage_victory_dialog.dart:217-246` 在允许时显示并返回 `StageVictoryAction.enterNextStage`，`lib/features/mainline/presentation/stage_entry_flow.dart:205-260` 消费该选择继续 run。
- 现状：五项中 HUD、散墨、下一关已进生产；聚合伤害与屏外提示不存在。

## 7. 关间剧情移除并进入章节卷轴/待处理江湖事 — 已实装

- 证据：`lib/features/mainline/presentation/stage_entry_flow.dart:102-104,757-781,873-890,1041-1058` 对所有 mainline 禁用 opening/defeat/victory 自动阅读；`lib/features/mainline/presentation/stage_list_screen.dart:1243-1344` 按关卡可用/已通关状态提供可选卷轴阅读。
- 待办消费：`lib/features/mainline/application/mainline_pending_jianghu_affair_service.dart:11-47` 从持久结算 journal 读取 FIFO，`lib/features/jianghu_chronicle/presentation/jianghu_chronicle_hub_screen.dart:122-130` 提供“待处理江湖事”生产入口，`lib/features/jianghu_chronicle/presentation/pending_jianghu_affairs_screen.dart:58-87` 读取并恢复原 run。
- 现状：主线关前/战败/胜利剧情已不再阻断连战，阅读和未完江湖事均有生产可达入口。

## 8. 首次推进使用“当前掌门”身份解析 — 已实装

- 证据：`lib/shared/battle_shared/current_leader_resolver.dart:9-25` 从 `SaveData.founderCharacterId` 解析且验证角色存在性；`lib/features/mainline/presentation/stage_entry_flow.dart:483-520,548-574` 首推 bootstrap 消费该 ID，检查存活/主修/占用并以 `human + realtime + firstClear` 解析快照、绑入 `MainlineRun`。
- 政策与续关：`lib/features/mainline/domain/mainline_participation_policy.dart:99-103` 对 `firstClear` 强制返回 current leader，`lib/features/mainline/presentation/stage_entry_flow.dart:524-534` 后续关继续用 run 内同一 participant ID 重装快照。
- 现状：首推不从 active roster 猜测角色，而是 fail-closed 解析当前掌门并跨关锁定。

## 9. 手动首推必须全通 — 已实装

- 生产路径：`lib/features/mainline/presentation/stage_list_screen.dart:239-250,312-322` 把第 1 轮 available 关标为连续首推；`lib/features/mainline/presentation/stage_entry_flow.dart:205-265` 以真实单关战斗/结算作为 executor，`lib/features/mainline/application/mainline_run_coordinator.dart:83-155` 只在胜利且选“下一关”后校验 exact successor 并续关；首推模式被 `lib/features/mainline/application/mainline_participant_snapshot_service.dart:111-129` 限定为 `human + realtime`。
- 测试边界：`test/features/mainline/presentation/mainline_ch1_continuous_run_test.dart:59-123` 用真实第 1 章配置覆盖 `01→02→03→04→05` 协调链且不跨章；同文件 `126-231` 覆盖真实 `StageListScreen` 入口、人控 host 和掌门快照。
- 现状：第 1 章五关手动首推生产路径已连通；现有覆盖是“真实配置协调链 + 真实首关 UI 入口”，没有一条测试实际操作五场战斗到章末。
