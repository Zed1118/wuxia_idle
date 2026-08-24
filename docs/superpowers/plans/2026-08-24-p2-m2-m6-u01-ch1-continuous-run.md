# P2 M2/M6 U01 第一章连续 Run 生产闭环

## 基线与目标

- base：`1a7bc866ffd11b6032a918363daa4c8d656d81f3`
  (`[READY][CODEX][P2-POST-G2-M5-M6]`)。
- branch：`codex/phase2-m2-m6-u01-ch1-continuous-run-20260824`。
- worktree：`/Users/a10506/Desktop/Projects/挂机武侠-phase2-m2-m6-u01-ch1-continuous-run`。
- 只关闭 U01 第一章首次推进的生产“结算 → 下一关”与连续五关；不关闭 U04、U05、
  M2、M6 或整个二阶段。

## 已核实缺口

1. `showStageVictoryDialog` 只有一个“确认”动作，关闭后固定回关卡列表。
2. `runStageFlow` 只消费单个 `StageDef`，没有外层非递归连续 run。
3. `Phase0aMainlineBattleHost` 每场重新解析当前掌门，无法证明整段锁同一参与者。
4. `MainlineRun`、stage release 与 next-stage admission 纯合同已存在，但尚无生产 UI/宿主读取方。
5. G0 已冻结锁人、关间换装生成版本化快照、仅下一关不再可战才中断；本批不得发明伤势阈值。

## 文件白名单

### 生产

- `lib/features/mainline/application/mainline_run_coordinator.dart`（新建；只做外层非递归组合）
- `lib/features/mainline/application/phase0a_mainline_production_encounter_factory.dart`
- `lib/features/mainline/presentation/stage_entry_flow.dart`
- `lib/features/mainline/presentation/stage_list_screen.dart`
- `lib/features/mainline/presentation/stage_victory_dialog.dart`
- `lib/features/mainline/presentation/phase0a_mainline_battle_host.dart`
- `lib/shared/strings.dart`

### 测试

- `test/features/mainline/application/mainline_run_coordinator_test.dart`（新建）
- `test/features/mainline/presentation/mainline_ch1_continuous_run_test.dart`（新建）
- `test/features/mainline/presentation/stage_entry_flow_test.dart`
- `test/features/mainline/presentation/stage_entry_flow_branches_test.dart`
- `test/features/mainline/presentation/stage_victory_dialog_test.dart`
- `test/features/mainline/presentation/phase0a_mainline_wiring_test.dart`
- `test/features/mainline/application/mainline_next_stage_runtime_admission_test.dart`
- `test/features/mainline/domain/mainline_run_test.dart`

### 治理

- 本计划文件
- `CLAUDE.md`
- `GDD.md`
- `PROGRESS.md`
- `docs/dispatch/phase0a_overhaul/task_registry.yaml`
- `docs/audit/phase2_m2_m6_u01_ch1_continuous_run_2026-08-24.md`

## 禁止范围

- `main` / `origin/main`、push、历史重写。
- `data/**`、数值、奖励公式、解锁表、schema/saveVersion。
- 听剑成长比例/cap、七心魔 AI、渐进解锁或其他 `TUNE-*`。
- U04/U05、M3/M4、特殊模式生产迁移。
- 第二套 reducer、战斗 session、headless 内核、持久 run schema、通用 registry/observer。

## 实现边界

1. 仅关卡列表判定为 cycle 1 首次推进时启用连续 run；重打及特殊模式保持单关旧行为。
2. 外层 coordinator 组合既有 `MainlineRun`，不得递归调用 `runStageFlow`。
3. run 起点只解析一次当前掌门；后续每关用锁定 participantId 重新生成真实不可变
   `CombatantSnapshot`，允许玩家关间换装。
4. 每个新快照生成独立 opaque ID，`MainlineRun` version 单调 +1；宿主直接消费该快照，
   不再自行换成当时的另一位掌门。
5. 只有该关结算、进度及后置 hook 全部成功后，“进入下一关”才返回 coordinator；任一异常、
   退出、失败、不可战均停止，不能提前 admission。
6. “不可战”只消费现有 canonical `Character.isAlive`、角色存在、主修存在及真实装配能否生成；
   重伤仍按既有攻击惩罚可战，不新增阈值。
7. 第一章第 1–4 关提供“进入下一关 / 返回江湖地图”，第 5 关结束连续 run；跨章动作后续另批。

## 红测与验收

1. 红测 A：结果弹层找不到“进入下一关”。
2. 红测 B：协调器无法按 `stage_01_01 → ... → stage_01_05` 非递归推进。
3. 红测 C：关间更换当前掌门时，宿主仍必须消费 run 起点锁定的 participant snapshot。
4. coordinator：五关顺序、同 participant、snapshot version `1..5`、无第六关。
5. fail closed：settlement/action 未成功、next loader 异常、角色缺失/死亡/无主修、snapshot 生成失败，
   均不发布下一关 run。
6. UI：下一关/返回双动作；无 successor、重打、特殊模式仍保持单确认行为。
7. 既有 stage flow、victory dialog、runtime admission、MainlineRun、G2 94 项保护网通过。
8. changed/scoped analyze、format、YAML、diff check、精确白名单、独立语义复核 P0/P1=0。
9. 最终 clean `[READY]`；本批不重复大范围 M7/M8 Profile，也不擅自 merge/push。
