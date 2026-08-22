# DeepSeek 子任务：全量普通主线与扫荡扩面

## 文件边界

- `lib/features/mainline/application/phase0a_mainline_gate.dart`
- `lib/features/sweep/application/phase0a_sweep_gate.dart`
- `test/features/mainline/presentation/phase0a_mainline_wiring_test.dart`
- `test/features/sweep/application/phase0a_sweep_headless_runner_test.dart`
- 必要时新增上述 feature 内单一 gate 测试文件

禁止修改 `stage_entry_flow.dart`、mapper/reducer、YAML、schema、特殊玩法文件。

## 要求

1. 默认灰度关闭不变。
2. 灰度开启后，全部 `StageType.mainline` 且非空敌队、合法 cycle（>=1）进入 Phase 0A；不再限制 Ch1。
3. 心魔、轻功、群战继续拒绝，留主 agent 独立迁移。
4. 扫荡普通主线范围与 live 门一致；塔全部合法层继续支持。
5. 用真实 Ch1/Ch21、cycle 1/2 和三类特殊 stage 建正反测试。
6. 跑 targeted test、format、targeted analyze，提交代码 commit 和 `[READY]` 空提交。

## 基线

`b530dc66`
