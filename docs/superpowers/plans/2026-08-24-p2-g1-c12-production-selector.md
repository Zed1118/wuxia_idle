# P2 G1 C12B：三战术生产选择与扫荡消费

## 基线与白名单

- base：`75c2f1f7a4878c56eb00e0e269b9cdaf076067c6`。
- branch：`codex/phase2-g1-c12-production-selector-20260824`。
- 只修改 C12 policy、扫荡 screen/unit/runner、`UiStrings`、对应三份测试与本计划。
- 不修改 C11 冷却、数据 YAML、存档 schema、奖励、扫荡 readiness 或 main/origin main。

## 生产合同

1. 扫荡真正开始前必须显式选择寻隙、强攻或稳守；选择前 runner 调用次数为零。
2. 选择值通过 `SweepScreen → SweepUnit → Phase0aSweepHeadlessRunner → Phase0aPlayerBotAdapter` 原样传递，不允许中途回落默认 `production()`。
3. 三战术继续只生成真人同型 `Phase0aPlayerCommand`，同一 reducer/headless runner 结算；不新增隐藏信息或第二战斗公式。
4. 选择只属于本次运行，不加 save 字段；后续黑风岭可见 bot 复用同一 typed selector/label，不另造枚举。
5. 现有扫荡战备、停止、超时、战败、结算和主线/塔行为保持。

## 验证

- 红测：三战术逐值穿透，选择前零运行；runner 必须消费显式 policy。
- 既有 sweep screen、unit/runner、C12 adapter/headless 测试。
- scoped analyze、format、diff-check、精确白名单。

## 完成证据

- 红测在代码生成产物齐备后精确失败于三项战术文案/选择入口缺失。
- `sweep_screen_test.dart`：6/6，包含选择前零运行与三个 enum 逐值穿透。
- `phase0a_sweep_headless_runner_test.dart` 与
  `phase0a_player_bot_adapter_test.dart`：真实 Ch1/Ch21、cycle 2、代表塔层、双占用拒绝及三 policy 行为通过。
- 七个变更 Dart/测试文件 scoped analyze：0 issue；`git diff --check`：0。

## 恢复点

- 当前状态：实现与定向验证完成，待本分支提交后进入 C11。
- 续作：C11 与 C12 完成后，在 G1 整合态做全量回归与文档终验。
