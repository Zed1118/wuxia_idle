# P2 M5：断魂庄自动化准入

## 目标与边界

把 `GAUNTLET-VISIBLE-BOT-01` 接到真实 application 边界：即时 automation endpoint 只允许 `exact gauntlet id + direct + playerBot + headless + replay + exact clearedGauntletIds membership`，其余 31 个 participation/controller/clock/entry 组合及错误 content kind/id 全部 fail-closed。

- 不消费 `MAINLINE-REPLAY-PARTICIPANT-01`，不继承“headless 固定掌门”；参与者恒为 active run 既有唯一 member。
- `fightCurrentStagePhase0a` 必须携带不可伪造 admission，并在战前与结算事务内复核。
- 自动多关胜利只到 `GauntletPhase.awaitingRewardChoice`；不选、不结算、不领取、不重抽奖励。
- 不新增 `rulesVersion`、save migration、完整 automation key、UI、数值、解锁或数据改动。

## 恢复基线

- semantic base：`693ed157071e8242dc44ef81b9bae7d289809e58`
- patch base：`a6a373e137f72a69040199eb9431052f8095d1e1`
- branch：`codex/phase2-m5-gauntlet-automation-admission-20260824`
- implementation commit：`aba4eddef4a6d959516b47d18a07c88600e5bd12`
- defeat settlement fix commit：`a537c0f3fd3c0533c9796b116153e35353e21efd`
- 主控 owned_files 扩展：集成登记 `d8148614` 精确加入 `test/features/boss_gauntlet/phase0a_gauntlet_continuation_test.dart`；禁止保留隐式 admission 默认值。

## 实现结果

- `gauntlet_automation_policy.dart`：纯领域 1/32 白名单 policy；精确 content kind/id 与完整首通证据。
- `gauntlet_automation_admission.dart`：canonical `saveDatas.get(0)`，不可伪造 admission 绑定 save/run/member/stage/phase 与战前 member HP/Qi/max/downed 快照。
- `gauntlet_service.dart`：公开 headless executor 强制 admission；战末单事务核对 expected runId/member/currentStage/sessionPhase/member snapshot 后才写入；多关 orchestrator 穿过 interlude 并在奖励选择态硬停。
- 胜利路径不调用 `chooseReward`、`settleDefeat`、`close`；awaiting 二次调用为纯读并零副作用。败局路径在同一 exact run/stage/phase/member 快照边界调用既有 `settleDefeat`，返回事实性 `defeatSummary`，删除 run 并仅结算一次精英经验、伤势与托管返还，不发奖励。

## Pi + DeepSeek 只读设计审查

- Pi version：`0.84.1`
- selector 核验：`pi --list-models 'deepseek/deepseek-v4-flash'` → provider `deepseek` / model `deepseek-v4-flash` / thinking `yes`
- 精确模型：`deepseek/deepseek-v4-flash`
- thinking：`high`
- 权限：`--tools read,grep,find,ls --print`（`print` 为非交互模式；未开放 bash/edit/write）
- 命令：

```sh
pi --model deepseek/deepseek-v4-flash --thinking high --tools read,grep,find,ls --print --no-session --approve "READ-ONLY pre-implementation design review for P2-M5-GAUNTLET-AUTOMATION-ADMISSION; read CLAUDE/GDD/plan/registry decisions/ActivityParticipationRequest/gauntlet service and tests; assess exact fail-closed policy, public headless bypass, awaitingRewardChoice boundary, TOCTOU, owned_files and adversarial matrix; output Recommended design, P0, P1, P2, test matrix, verdict; do not write code."
```

- exit code：`0`
- P0：1 项——当时非 owned 的 `phase0a_gauntlet_continuation_test.dart` 仍直调 headless 首通，接口收紧会冲突。主控随后以 `d8148614` 将该文件精确加入 owned_files，阻断已解除。
- P1：入口在任何副作用前 fail-closed；每关重验；admission 绑定 active run 唯一 member；结算防 TOCTOU；不 catch/wrap/fallback。
- P2：未来 M6 可进一步收口 live 共用的 `prepare + runner + settle` 组合；本切片不扩张。

## 验证

最终 code tree 同一命令显式列出 5 个定向测试文件：

```sh
flutter test --no-pub \
  test/features/boss_gauntlet/gauntlet_automation_policy_test.dart \
  test/features/boss_gauntlet/gauntlet_automation_admission_test.dart \
  test/features/boss_gauntlet/gauntlet_drive_test.dart \
  test/features/boss_gauntlet/phase0a_gauntlet_continuation_test.dart \
  test/features/boss_gauntlet/gauntlet_failure_test.dart
# 48 passed: policy 7 + admission 6 + drive 17 + continuation 4 + failure 14
```

- targeted tests：`48 passed / 0 failed`
- scoped analyze：7 个 owned Dart 文件，`No issues found`，exit `0`
- format：7 个 owned Dart 文件，`0 changed`，exit `0`
- `git diff --check`：exit `0`
- 生产接线：`GauntletService.fightCurrentStagePhase0a` 与 `driveHeadlessReplayToRewardChoice`
- 红线影响：零数值、三系、在线离线公式、反主流项、UI 文案、schema/saveVersion/data 改动。

## actual-diff P1 修复与旧终审作废

- 旧 Pi actual-diff 曾绑定 `aba4eddef4a6d959516b47d18a07c88600e5bd12` 返回 PASS，但随后独立 Codex 审查发现 P1：`leftWin=false` 只返回 `defeated`，未调用既有 `settleDefeat`，run 留在 `inBattle`，二次 drive 可重跑同一败局，且精英经验/伤势/托管返还/删 run 均未结算。
- 旧 PASS 明确作废，不作 READY 证据。
- fix commit `a537c0f3fd3c0533c9796b116153e35353e21efd` 将败局结算收入同一 admission 快照边界，并新增败局一次结算/二次 fail-closed 端到端测试。

## Pi + DeepSeek 最终 actual diff 终审

- 绑定最终 code tree：fix commit `a537c0f3fd3c0533c9796b116153e35353e21efd`
- patch base：`a6a373e137f72a69040199eb9431052f8095d1e1`
- Pi version：`0.84.1`
- selector 核验：`pi --list-models 'deepseek/deepseek-v4-flash'` 唯一命中 provider `deepseek` / model `deepseek-v4-flash`
- 精确模型 / thinking / 权限：`deepseek/deepseek-v4-flash` / `high` / `read,grep,find,ls,print`
- 命令：

```sh
pi --model deepseek/deepseek-v4-flash --thinking high --tools read,grep,find,ls --print --no-session --approve '你是本项目的只读 actual-diff 终审员。审查绑定最终 code commit a537c0f3fd3c0533c9796b116153e35353e21efd，patch base a6a373e137f72a69040199eb9431052f8095d1e1，semantic base 693ed157071e8242dc44ef81b9bae7d289809e58；旧 commit aba4eddef4a6d959516b47d18a07c88600e5bd12 的 PASS 已因独立 P1 作废，不得复用。你只能 read/grep/find/ls，不得写文件或执行 shell。请完整读取 CLAUDE.md、GDD.md 中断魂庄/自动参与相关章节、docs/superpowers/plans/2026-08-24-p2-m5-gauntlet-automation-admission.md 的需求部分，以及当前代码树中的 lib/features/boss_gauntlet/domain/gauntlet_automation_policy.dart、lib/features/boss_gauntlet/application/gauntlet_automation_admission.dart、lib/features/boss_gauntlet/application/gauntlet_service.dart、test/features/boss_gauntlet/gauntlet_automation_policy_test.dart、test/features/boss_gauntlet/gauntlet_automation_admission_test.dart、test/features/boss_gauntlet/gauntlet_drive_test.dart、test/features/boss_gauntlet/phase0a_gauntlet_continuation_test.dart，并用 test/features/boss_gauntlet/gauntlet_failure_test.dart 检查 legacy manual settleDefeat 回归风险。产品合同：唯一允许 tuple 为 exact gauntlet ID + direct/playerBot/headless/replay + SaveData.clearedGauntletIds 精确 membership；拒绝 visible realtime playerBot、headless firstClear、错误 kind/id、未首通 replay 和 public service 绕过；不继承 mainline headless 固定掌门，仅保持 active run 既有唯一 member；自动胜利必须停在 awaitingRewardChoice 且二次调用零副作用；不得自动领奖/结算/重抽；使用 canonical saveDatas.get(0)；runId/member/stage/phase 与战斗前 member snapshot 必须 fail-closed。重点复核此前 P1：leftWin=false 必须在同一已绑定 run/stage/phase/member 安全边界真实调用既有 settleDefeat，删除 run、仅一次结算精英经验/伤势/托管返还、不发奖励，第二次 drive 不得重跑战斗；drive result 应有事实性 defeatSummary；automation path 的严格校验不得破坏 legacy manual settleDefeat 幂等/历史多人路径。已验证 scoped analyze 0 issue，定向 48/48。请逐项给出 Scope、P0、P1、P2、测试缺口与最终 Verdict（只有 P0/P1 均无才可 PASS）。若有问题给出精确文件/符号/触发路径；P2 必须明确是非阻塞改进。'
```

- exit code：`0`
- verdict：`PASS`
- P0：无。
- P1：无；终审确认败局重新 admission 捕获战后快照，`settleDefeat` 事务内按 exact runId 取 run 并重验 policy/save/run/member/stage/phase/member snapshot；结算仅一次，二次 drive 在战斗前拒绝，legacy manual/历史多人路径不受影响。
- P2（非阻断）：一处旧方法名注释漂移；`settled`/双 active run/interlude stale 防御分支可补直接负测；既登记 M6 的公开 `prepare + runner + settle` 组合路径；单存档规模下 `findAll` 微小效率点。
- 最终终审后 code/test 未再修改；仅本计划文件更新证据。

## 当前恢复点

- 状态：完成，等待主控复审/集成。
- 最后完成：fix commit `a537c0f3fd3c0533c9796b116153e35353e21efd` 已经新 Pi actual-diff 终审 PASS；验证 48/48、analyze 0、format/diff check 通过。
- READY tip：本文件所在的 `[READY][CODEX][P2-M5-GAUNTLET-ADMISSION]` 证据提交；主控按 source patch 复审。
- 阻塞项：无。
- 残留风险：仅上述外审 P2，均不阻塞本任务合同。
