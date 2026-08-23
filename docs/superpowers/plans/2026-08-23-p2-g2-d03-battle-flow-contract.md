# P2-G2-D03 Phase0aBattleFlow 合同

## 目标与分支

- 分支：`codex/phase2-g2-d03-battle-flow-20260823`
- 执行：Pi + DeepSeek `deepseek-v4-flash`
- 目标：抽取最小 `Phase0aBattleFlow`，让 live controller、headless sync/async、retry builder 可消费非 wave flow，而旧 wave 行为与 assembler 公开返回类型完全不变。

## 冻结 API

`Phase0aBattleFlow` 仅含 `state` / `outcome` / `lastOrderedEventRecords` / `advance(deltaSeconds, command)`。不得包含 `waves`、transition policy、session、resolver 或 wave cursor。

## 验收

- `Phase0aWaveBattleFlow implements Phase0aBattleFlow`，不改 `advance` 逻辑。
- controller 构造/_flow/restart、headless sync/async、screen/debug retry builder 改为接口类型。
- `Phase0aProductionFlowAssembler.assemble` 仍返回 `Phase0aWaveBattleFlow`，debug fixture 仍保留 concrete `.waves`。
- 新测试使用最小 non-wave fake 证明 controller/headless sync+async 可消费；不复制 reducer。
- 跑相关 targeted tests、限定 analyze、`git diff --check`。
- 不改 reducer、伤害、RNG、数值、data、UI 布局、存档或奖励。
- 提交中文动宾 commit，最后追加 `[READY][PI][P2-G2-D03]` 空 commit，工作树必须 clean。

## 当前恢复点

- 状态：✅ 已完成并提交（2026-08-23）。
- 基线：`1150c56a`。
- 实现：新建 `lib/features/battle/application/phase0a/phase0a_battle_flow.dart`（抽象 interface，仅 `state`/`outcome`/`lastOrderedEventRecords`/`advance` 四成员）；`Phase0aWaveBattleFlow implements Phase0aBattleFlow`（advance 逻辑零改，仅补 @override）；controller 构造/_flow/restart、headless runToEnd/runToEndAsync、battle_screen 与 visual_route_host 的 retryFlowBuilder 全部改接口类型；`Phase0aProductionFlowAssembler.assemble` 仍返回 `Phase0aWaveBattleFlow`，debug fixture 仍保留 concrete `.waves`。
- 新测试：`test/features/battle/application/phase0a/phase0a_battle_flow_interface_test.dart`（最小 non-wave fake 证明 controller/headless sync+async 可消费；不复制 reducer）+ 冻结 API 源码守卫（接口文件不含波次/session/resolver）。
- 验证：新测试 7/7；headless_kernel+wave_flow+assembler+retry 50/50；sweep/expedition/gauntlet seam 30/30；screen/focus/mechanics/numeric/sfx/embed/mainline/tower 相关集 80 过 5 败（5 败为基线既有 `Phase0aTacticalSkillBinding` 调试 yaml 配置问题，stash 验证同败，与 D03 无关）；`flutter analyze` 1943 == 基线零新增；`git diff --check` 干净。
- 阻塞：无。
