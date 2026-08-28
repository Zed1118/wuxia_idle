# P2 F1 战斗操作手感批计划

## 目标

在 Phase 0A 真实战斗屏完成三个固定结果：J 自动瞄准最近存活敌人、Space 与 Z 同路径闪避、守势/化解/闪避分别显示可用或冷却状态。

## 分支

`codex/p2-f1-battle-input-feel-20260828`，唯一基线 `1ba913a633beb0fd8f9b47764161f47c54260707`。

## 验收标准

- J 经 `_handleKey` 与 `_heldCommand` 进入真实 controller/adapter/reducer，不移动即可命中侧后方最近存活敌人；鼠标仍按指针自由瞄准。
- Space 与 Z 均经真实 `sendKeyEvent` 进入同一个 dodge command，并产生一致的防御动作事件与位移状态。
- HUD 在 1280x720 与 1440x900 下分别为守势、化解、闪避显示既有「可用 / 冷却 N.N 秒」体例，无 overflow。
- 实现提交后，`remove_implementation` 与 `force_degenerate_value` 两向破坏均令同一 targeted 文件变红，随后精确还原并保持工作树 clean。
- targeted、`flutter analyze --no-pub lib test`、整仓 format、锁定全量、`git diff --check` 通过；禁区零 diff；代码单 receipt 绑定候选，tip 为 clean `[READY]`。
- 不改数值、schema、存档、姿态/破势、E/F/Z 机制语义、集中字符串或其它禁区文件；READY 只代表执行候选，不代表 Claude 独立验收。

## 任务切片

1. 完成 fresh worktree 预热并盘点真实键盘/HUD 生产路径。
2. 用一个专门的真实屏幕 targeted 文件覆盖 J、鼠标、Space/Z、三项防御状态和双视口。
3. 在 `phase0a_battle_screen.dart` 做最小输入与 HUD 消费改动。
4. 定向绿测后提交实现，按固定顺序做两向破坏证红与精确还原。
5. 完成全套验证，写 receipt，冻结 clean READY tip。

## 当前恢复点

- 状态：实现完成，准备提交后双向破坏证红。
- 最后完成：J 最近敌人瞄准、Space/Z 同路径闪避、三项防御 HUD 状态及专门真实 screen 测试。
- 下一步：提交实现；按固定顺序执行 `remove_implementation`、`force_degenerate_value`，每向精确还原。
- 已跑验证：build runner exit 0；专门 targeted `+7`、最后一行 `00:00 +7: All tests passed!`。
- 阻塞项：无。
