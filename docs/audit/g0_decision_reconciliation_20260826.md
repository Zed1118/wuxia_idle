# G0 决策清账对账（2026-08-26）

## 口径与结论

- 事实基线：方案 `/Users/a10506/Desktop/二阶段优化方案.md`；registry 为 `docs/dispatch/phase0a_overhaul/decision_registry.yaml`（已实测可解析）；代码实况只读核对本地 `main@1280b15f`，未把本任务分支 `HEAD@07f175e0` 当作当前 main。
- 签字原始源下称 `S`：`/Users/a10506/.codex/archived_sessions/rollout-2026-08-23T16-30-13-01a02dbd-e0b7-7db0-a3dd-645a42c7c2f4.jsonl`。`S:249` 是用户对整份方案的开工授权；`S:11053` 是逐项 G0 推荐原文；`S:11071` 是随后用户原文“按推荐方案执行 G0”。registry/GDD/CLAUDE/测试中“用户拍板”的转述不作为签字原始证据。
- 分母实测：§0.2 的 14 个 ID 覆盖 `14/14`；§23 步骤 4 的五项覆盖 `5/5`。四项与既有 ID 去重；“主线重打/自动/扫荡参与者”在方案明说另立 `PROPOSED` 却未给 ID，故另列 1 行，合计 15 行。
- G0 级处置均有原始签字：方案既有 `FROZEN`/目标规则由 `S:249` 授权推进；五项 G0 推荐由 `S:11053,11071` 明确批准。仍无最终签字的只有听剑比例/每关上限定值、七心魔逐关具体 AI 映射；前者仍为 `TUNING` 且生产不发放，后者已签 C 暂缓并有 `keep_existing_ai` 安全 policy，因此按方案 `:998` 均不阻塞 M2/M5/M6。
- 本结论只表示“没有因未签字触发方案 `:998` 的 M2/M5/M6 禁开条件”，不宣告 G0/M0 整体 Gate 关闭；registry 缺 `INNER-DEMON-LEGACY-01`、听剑仍未接生产等工程/登记缺口继续按表中事实保留。

## 六栏逐条对账

| 决策 ID | 方案声明状态 | registry 当前状态 | 当前 main 代码实况 | 签字证据 | 按 M0 Gate 阻塞什么 |
|---|---|---|---|---|---|
| `COMBAT-SCOPE-01` | `FROZEN`（方案 `:40`） | `frozen`（registry `:19-23`） | 六类纯领域 scope 已存在（`lib/features/battle/domain/phase0a/combat_geometry.dart:13-20`）；真实普攻选择只接前向扇形（`lib/features/battle/domain/phase0a/realtime_combat_rules.dart:24-48`），技能 YAML loader 仍只收 `radial+caster`（`lib/data/defs/phase0a_skill_behavior.dart:1-3,96-116`）。 | `S:249`，用户原文“现在读取这个方案，然后规划开始推进二阶段优化方案”。 | 不阻塞 |
| `COMBAT-WAVE-CD-01` | `IMPLEMENTATION-GAP`（方案 `:41`） | `frozen_implemented`（registry `:25-31`） | 生产配置为 `preserve_cooldowns: true`（`data/numbers.yaml:1880-1884`），mapper 映射为不重置技能 CD（`lib/features/battle/application/phase0a/phase0a_stage_content_mapper.dart:241-246`）。 | `S:249`，同上方案级开工授权。 | 不阻塞 |
| `EXP-CONCURRENCY-01` | `FROZEN`（方案 `:42`） | `frozen`（registry `:33-37`） | dispatch 在同一事务内查询全存档 runs，发现同 save 任一 run 即拒绝（`lib/features/expedition/application/expedition_service.dart:118-125`）。 | `S:249`，同上方案级开工授权。 | 不阻塞 |
| `MAINLINE-PARTICIPANT-01` | `FROZEN`（方案 `:43`） | `frozen`（registry `:39-44`） | `founderCharacterId` 缺失/悬空均抛错，无首角色 fallback（`lib/shared/battle_shared/current_leader_resolver.dart:9-25`）；首推入口消费该 resolver（`lib/features/mainline/presentation/stage_entry_flow.dart:483-505`）。 | `S:249`，同上方案级开工授权。 | 不阻塞 |
| `MAINLINE-RUN-01` | `PROPOSED`（方案 `:44`） | `frozen`，A/B/B（registry `:57-69`） | 生产协调器锁 `participantId`、胜利后装配下一关新快照、不可战即停（`lib/features/mainline/application/mainline_run_coordinator.dart:83-158`）；新快照版本递增（`lib/features/mainline/presentation/stage_entry_flow.dart:524-534`）。 | `S:11053` 明列“锁人 A / 换装 B / 伤势中断 B”；`S:11071` 用户原文“按推荐方案执行 G0”。 | 不阻塞 |
| `MENTOR-INSIGHT-CORE-01` | `FROZEN`（方案 `:45`） | `frozen`、`contract_only`（registry `:71-74`） | 0–1 人、不参战、不受伤、不分掉落、仅首通已成纯合同（`lib/features/mainline/domain/mentor_insight_policy.dart:81-97`），但 claim 仍 PARKED、当前生产不得发放（`docs/audit/phase2_testonly_classification_20260826.md:18`）。 | `S:249`，同上方案级开工授权。 | 不阻塞 |
| `MENTOR-INSIGHT-OCCUPANCY-01` | `PROPOSED`（方案 `:46`） | `frozen`，A=单关（registry `:76-93`） | 纯合同为单关占用、四种释放、与闭关/远征/断魂庄/疗伤互斥（`lib/features/mainline/domain/mentor_insight_policy.dart:105-139`）；反向真实入口尚未接线（`docs/audit/phase2_testonly_classification_20260826.md:16-17`）。 | `S:11053` 明列“随行听剑占用 A”；`S:11071` 用户原文“按推荐方案执行 G0”。 | 不阻塞（已签 A；未接线是实现事实，不是未签字） |
| `MENTOR-INSIGHT-RATE-01` | `TUNING`（方案 `:47`） | `frozen_with_tuning_edges`，`rate_status: tuning`、禁止生产改值（registry `:95-105`） | 成长对象仅主修熟练度；比例/每关上限明确不在合同（`lib/features/mainline/domain/mentor_insight_policy.dart:99-103`），claim 生产不得发放（`docs/audit/phase2_testonly_classification_20260826.md:18`）。 | 成长对象 B/候选授权：`S:11053,11071` 有据；**比例/每关上限定值：查无实据**。 | 不阻塞（`TUNING` 且安全默认=不发放） |
| `INNER-DEMON-FAILURE-CORE-01` | `FROZEN`（方案 `:48`） | `frozen`（registry `:107-111`） | 心魔失败只施加有上限内息紊乱（`lib/features/combat_shared/application/combat_resolution_service.dart:239-258`），并显式跳过物理伤势（同文件 `:262-283`）。 | `S:249`，同上方案级开工授权。 | 不阻塞 |
| `INNER-DEMON-CULTIVATION-01` | `PROPOSED`（方案 `:49`） | `frozen`，B=不扣主修（registry `:113-130`） | `applyFailurePenalty` 保持永久内力和主修 progress 不变，只写内息紊乱（`lib/features/inner_demon/application/inner_demon_service.dart:66-95`）。 | `S:11053` 明列“心魔失败扣主修 B”；`S:11071` 用户原文“按推荐方案执行 G0”。 | 不阻塞 |
| `INNER-DEMON-LEGACY-01` | `IMPLEMENTATION-GAP`（方案 `:50`） | **registry 无此条** | `inner_demon.failure_penalty` 已退役，出现即解析失败（`lib/data/defs/inner_demon_def.dart:81-86`）；全 `data/` 现搜无该键。 | `S:249`，同上方案级开工授权。 | 不阻塞 |
| `INNER-DEMON-THEME-CORE-01` | `FROZEN`（方案 `:51`） | `frozen`（registry `:132-135`） | 七关仍为贪嗔痴慢疑空真（`data/stages.yaml:5252-5253,5268-5269,5284-5285,5300-5301,5316-5317,5332-5333,5348-5349`）。 | `S:249`，同上方案级开工授权。 | 不阻塞 |
| `INNER-DEMON-AI-01` | `PROPOSED`（方案 `:52`） | `deferred_pending_matrix`，安全默认 `keep_existing_ai`（registry `:137-150`） | 七关都走镜像 mapper（`lib/features/battle/application/phase0a/phase0a_stage_content_mapper.dart:397-409`）；旧 mapper 构造 AI 时未传逐关 profile（同文件 `:752-759`），故沿默认 `directAdvance`（`lib/features/battle/application/phase0a/phase0a_enemy_ai_adapter.dart:49-54,109-114`）。 | 暂缓 C/保留现状：`S:11053,11071` 有据；**七关逐关具体 AI 映射：查无实据**。 | 不阻塞（已显式暂缓且有安全 policy；该项也不在方案 `:998` 的五项禁开清单） |
| `COLLAB-WIP-01` | `FROZEN`（方案 `:53`） | `frozen`、`active`（registry `:194-197`） | 非运行时代码；当前 main 操作文档仍写 Mac 单端、DeepSeek/Windows AI 全下线（`CLAUDE.md:401-407`）。 | `S:249` 用户原文明确要求“充分利用pi+deepseek（flash模型）、qoder cli+qwen3.8max模型进行派单”。 | 不阻塞 |
| `无 ID·§23 步骤 4 第 1 项`（主线重打/自动/扫荡参与者） | `PROPOSED`（方案 `:30,:69,:1476`） | **registry 无此条**；相关新增 ID `MAINLINE-REPLAY-PARTICIPANT-01` 为 `frozen` C（registry `:46-55`） | 可见真人/前台 bot 重打先选 eligible 人（`lib/features/mainline/presentation/stage_list_screen.dart:247-321`）；headless/扫荡固定当前掌门（`lib/features/sweep/application/phase0a_sweep_headless_runner.dart:239-258`）。 | `S:11053` 明列该项 C；`S:11071` 用户原文“按推荐方案执行 G0”。 | 不阻塞 |

## 三方矛盾

以下只登记方案（冻结前稿）/registry（后续登记）/当前 main（实际行为）的冲突，不裁决谁覆盖谁：

1. `COMBAT-SCOPE-01`：方案写“当前仅 radial+caster”；registry 写前向扇形生产已集成；main 同时存在六类纯合同、前向扇形真实普攻与 radial-only 技能 loader。
2. `COMBAT-WAVE-CD-01`、`MAINLINE-PARTICIPANT-01`：方案的“当前证据”分别仍是 `preserve_cooldowns:false`、首角色 fallback；registry 与 main 分别已变成 true/不重置、无效指针 fail closed。
3. `MAINLINE-RUN-01` 与 `无 ID·§23 步骤 4 第 1 项`：方案仍 `PROPOSED`（后者且无 ID）；registry 已冻结 A/B/B 与新增 replay ID=C；main 已接连续 Run、可见选人和掌门 headless/扫荡。
4. `MENTOR-INSIGHT-OCCUPANCY-01`：方案写 `PROPOSED/尚未实装`；registry 写 `frozen`；main 只有单关纯合同/PARKED 接缝，四类真实反向入口未接线。
5. `INNER-DEMON-CULTIVATION-01`：方案写 `PROPOSED/当前仍扣`；registry 写 frozen B；main 已不扣。
6. `INNER-DEMON-LEGACY-01`：方案写 `IMPLEMENTATION-GAP/仍有残留`；registry 无此条；main 对旧键 fail closed 且现有 data 无键。
7. `COLLAB-WIP-01`：方案与 registry 允许 Qoder/DeepSeek 受控参与；当前 main 的 `CLAUDE.md:401-407` 仍声明 Mac 单端、DeepSeek/Windows AI 全下线。

## 可复核搜索边界

- 签字检索同时覆盖 repo 文档/测试与 2026-08-23～24 Codex 原始 `jsonl`；只有顶层 `response_item` 且 `role=user` 的原文计入签字。`S:11053` 仅用于解释 `S:11071` 所指的“推荐方案”。
- `INNER-DEMON-LEGACY-01` 在 registry 现搜 0 命中；`inner_demon.failure_penalty` 在当前 main 的 `data/` 现搜 0 命中。未以代码已实现反推任何签字。
