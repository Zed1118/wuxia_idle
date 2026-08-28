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

- 状态：`[BLOCKED]`，实现与验证完成，receipt 判据冲突待拍板。
- 最后完成：J 最近敌人瞄准、Space/Z 同路径闪避、三项防御 HUD 状态；既有 J 旧口径测试已改为实时最近敌人期望。
- 下一步：由协调方明确 receipt 采用派单的“tracked + 字符串数组”规范，还是当前不可修改 Gate 的“external/ignored + 结构化 break_red”规范；确定后只补 receipt 与 READY 冻结。
- 已跑验证：
  - `remove_implementation`：同一 targeted `+2 -5`，5 个 `[E]`，精确恢复后 `git diff --quiet` rc 0、状态空。
  - `force_degenerate_value`：同一 targeted `+4 -3`，3 个 `[E]`，精确恢复后 `git diff --quiet` rc 0、状态空。
  - 逐文件 targeted：input feel `+7`、defense keyboard `+3`、battle screen `+28`，三行均为 `All tests passed!`，`[E]=0`。
  - analyze：`No issues found! (ran in 54.4s)`。
  - format：`Formatted 1627 files (0 changed) in 11.94 seconds.`。
  - 锁定全量：`08:27 +5650: All tests passed!`，`[E]=0`；锁已释放。
  - `git diff --check 1ba913a633beb0fd8f9b47764161f47c54260707..HEAD` rc 0；5 个禁区文件零 diff。
- 阻塞项：派单要求 commit `receipt.yaml` 且 `break_red` 为字符串数组；当前 `gate.sh` 只接受 external/ignored receipt 与包含 `direction/mutation/failed_count/conclusion` 的结构化数组，并强校验 receipt `head_sha` 等于被评估 HEAD。执行端被禁止修改 Gate，无法同时满足两套规范。
