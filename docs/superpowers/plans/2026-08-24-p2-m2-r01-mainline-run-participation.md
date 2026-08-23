# P2-M2-R01：MainlineRun 与参与者纯合同

日期：2026-08-24
基线：G0 READY `44e42497`（推荐方案决策关闭）
分支 / worktree：`codex/phase2-m2-r01-mainline-run-participation-20260824`

## 目标

把二阶段 G0 已签字的两条主线决议落成纯合同（纯 Dart、不可变、无持久化、不接生产流），供 M2 后续生产切片与 M6 消费：

- `MAINLINE-REPLAY-PARTICIPANT-01`（G0=C，frozen）：仅可见重打（realtime，真人或前台 bot）可选 eligible 空闲角色；无人值守 headless 与扫荡、首通恒固定当前掌门；记录、成长与伤势归实际参与者。
- `MAINLINE-RUN-01`（frozen）：`participant_lock=A` 整段锁同一参与者；`between_stage_loadout=B` 关间允许换装并生成版本化新战斗快照（独立不透明 `loadoutSnapshotId`）；`injury_interruption=B` 仅当参与者下一关不再可战时中断。

## 范围

新增（不动既有文件）：

- `lib/features/mainline/domain/mainline_participation_policy.dart`
  - `MainlineParticipationPolicy.resolveParticipant`：按 `ActivityParticipationRequest` + 注入的当前掌门 ID + 注入的「合格且空闲」外部判定解析实际参与者。仅 `realtime` 重打（真人或前台 bot）接受合格空闲的请求角色，不合格即拒绝、不回退掌门；`headless` 重打恒固定掌门（不受 controller 与 eligibility 影响）、扫荡恒固定掌门、首通恒固定掌门；`offlineResume` 未被决议覆盖，拒绝；非主线内容、差遣参与拒绝。
  - `MainlineParticipantSelection`：参与者 + 来源（`requestedIdleEligible` / `currentLeader`）；`actualParticipantId` 即成长与伤势归属对象。
- `lib/features/mainline/domain/mainline_run.dart`
  - `MainlineRun.begin`：整段锁同一参与者，第一关生成版本 1 快照；值不可变。
  - `proceedToNext(stageId, loadoutSnapshotId, participantBattleEligibleForNextStage)`：推进前强制消费调用方已判定的外部可战事实，内部复用与 `stopReasonForNextStage` 同一决策（无复制漂移）；`false` 时抛 `MainlineRunTransitionRefusedError`（携带 `participantNotBattleEligibleForNextStage`）fail closed，绝不返回新 run/新快照；`true` 才生成下一关版本递增快照并保留历史。调用方无法绕过中断。
  - `MainlineRunLoadoutSnapshot.loadoutSnapshotId`：独立、不透明的 run 战斗快照 ID，trim 规范化后校验非空并携带（不解析、不反查持久装配方案）；与每角色唯一持久装配方案（`REOPEN-LOADOUT-PLAN-01=A`）语义解耦，不保存、不暴露。
  - `stopReasonForNextStage(participantBattleEligibleForNextStage:)`：统一纯决策辅助，消费同一外部事实（`bool`），仅 `false` 时返回 `participantNotBattleEligibleForNextStage`；合同不做查询、不发明阈值。
- 测试：`test/features/mainline/domain/mainline_participation_policy_test.dart`、`test/features/mainline/domain/mainline_run_test.dart`。

## 明确不做（红线对齐）

- 不发明 eligibility / 空闲 / 占用判定；不定义伤势阈值、可战权重或任何 `TUNING` 默认（§17.7 口径：M0/M2 模拟定标前不设 injury 权重）。
- 不新增持久装配锁或亲战 / 差遣双 preset（`REOPEN-LOADOUT-PLAN-01=A`：每角色一套持久装配）；版本化快照只在 run 值对象内且以不透明快照 ID 表达。
- 不改 task / decision registry、GDD / CLAUDE / PROGRESS、生产 host、sweep、`data/`、存档或 UI；不改 `ActivityParticipationRequest`、`CurrentLeaderResolver`、`FailurePolicy`，只消费其类型。
- 不接线：生产接入（选人、占用冲突、报告展示）留给 M2 后续切片与 M6。

## 依赖与前置

- 既有合同件：`ActivityParticipationRequest`（P2-G2-E01）、`CurrentLeaderResolver`、`FailurePolicy`（C13，`FailureClaimKey` 已以参与者为索赔键，归属语义天然兼容）。
- 仓外「二阶段优化方案」Qoder 端不可读（M0 缺口 G1 同因），合同口径以 decision registry + GDD §12.4.2 + G0 决策包为准。

## 验收标准（§8.2 转写）

- [x] 拒绝项核对：已对照 `docs/spec/rejected_task_registry.md:87`「Build 方案保存」旧否，本批不保存任何装配方案、不新增双 preset，快照用不透明 `loadoutSnapshotId`。
- [x] 数值红线：无新增数值；合同不引入任何数值常量（错误消息为英文，不产生玩家可见中文文案）。
- [x] 不硬编码：无中文文案、无数值常量进 Dart。
- [x] 只新增 4 个文件（2 lib + 2 test）与本计划文档，不触碰禁区。
- [x] targeted test 覆盖：可见重打/前台 bot 选人、不合格拒绝无回退、`requestedIdleEligible=false` 时 headless 重打（human/bot）/扫荡/首通仍恒固定掌门且仅 realtime 重打拒绝的对照、`offlineResume` 拒绝、参与者锁定、不透明快照版本递增与不可变、快照 ID trim 规范化与全空白拒绝、外部可战事实为 `true` 才推进、为 `false` 时 `proceedToNext` 抛 `MainlineRunTransitionRefusedError` 且原 run/快照不变、参与者与成长/伤势归属恒等、值相等与校验；主控实跑 36/36 通过。
- [x] 限定验证：两份新测试 + 4 份实现/测试 scoped analyze 0 issue + format + `git diff --check` 通过。

## 验证记录

- Qoder fresh worktree 初次因缺 `.dart_tool` 与会话权限层拦截未取得绿证；主控随后执行 `flutter pub get --enforce-lockfile` 与 `dart run build_runner build` 恢复依赖/生成态。
- 主控 targeted：`flutter test --no-pub --no-test-assets test/features/mainline/domain/mainline_participation_policy_test.dart test/features/mainline/domain/mainline_run_test.dart`，36/36 通过。
- 主控 scoped analyze：2 份实现 + 2 份测试，0 issue；`dart format` 后复跑 targeted/analyze，`git diff --check` 通过。
- 独立 Codex 最终复审：P0/P1/P2 = 0/0/0；确认不可战推进不可绕过、快照与持久装配方案解耦、参与者矩阵完整。
- 主控验证后提交实现，并追加 `[READY][QODER][P2-M2-R01]` 空提交封签。

## 风险与遗留

- 本批是政策缝（policy seam），连续 run 仍未在生产启用；M2 后续切片接「下一关」流程时消费本合同，不得绕过。
- `offlineResume` 参与语义未签字，合同拒绝，待后续决议。
- 生产 host、sweep 与结果展示仍未接线；本 READY 仅证明纯合同，不冒充生产闭环。
