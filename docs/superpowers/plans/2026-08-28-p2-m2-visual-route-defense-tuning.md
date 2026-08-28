# M2 visual route 防御 tuning 修复计划

## 目标

使 `phase0a_battle_playable` 及共用同一 debug fixture 的战斗视觉路由与生产 Phase 0A 一样，从 `numbers.phase0aArena.defense` 映射同一份 `Phase0aDefenseTuning`，同时传入玩家输入和敌方攻击 adapter。

## 分支

`codex/p2-m2-visual-route-defense-20260828`，唯一基线 `274a3b2ec32871bfd3c735fd75bdffa528bdb2e6`。

## 验收标准

- 生产接线：`VisualRoute.phase0aBattlePlayable` 使用的 `Phase0aDebugBattleFixture` 必须经现有 mapper 消费 `numbers.phase0aArena.defense`，玩家 E/F/Z/Space 从真实 `Phase0aBattleScreen` 键盘入口产生对应 `Phase0aDefenseStarted`；敌方攻击携带同一 tuning 的 defense flags，真实护盾能产生 `Phase0aDefenseResolved`。
- 视口：新增 route 真实渲染测试覆盖 1280×720 与 1440×900，无 overflow 或异常块。
- 双向破坏证红：实现 commit 后依次删除 tuning 传递支点、强制 mapper 结果退化为 null，同一 targeted 文件两向均必须红，然后精确反向补丁还原。
- 验证：逐文件 targeted、`flutter analyze --no-pub lib test`、整仓 format、持锁全量、`git diff --check`、代码单 receipt 与持锁 gate 全部通过，分支 tip 为 clean `[READY]`。
- 红线：不改数值、schema、存档、玩家可见文案/键位语义；不触碰禁区文件、在线=离线、三系锁死或反主流清单。
- 残留风险：本单只恢复 debug visual route 的已有防御机制，不变更手感、数值或 G2 主观结论；G2 仍须用户真人签字。

## 任务切片

1. 完成宪法/代码/gate 实况审计并修正宪法漂移。
2. 新增 debug visual route 真实键盘与防御结算红测。
3. 在 fixture 中单次映射 tuning，传给玩家与敌方 adapter。
4. 实现 commit 后做两向破坏证红与精确还原。
5. 完成九步验证、receipt、gate、合并、main 回归、push 与 CI 字段核验。

## 当前恢复点

- 状态：WIP，实现与首轮完整验证已通过，待冻结最终 READY tip、重跑 tip-bound 双向破坏证红和 gate。
- 最后完成：同一 `Phase0aDefenseTuningMapper` 结果已传入玩家与敌人 debug adapter；真实键盘入口和护盾结算测试已新增。
- 下一步：提交本证据更新、打 `[READY]` 空 commit，在该最终 tip 再做两向破坏证红，写 external receipt 并持锁跑 gate。
- 已跑验证：
  - `remove_implementation`：完整移除玩家/敌人 tuning 传递后，同一 targeted 尾行 `00:00 +0 -3: Some tests failed.`，3 个 `[E]`；精确还原后 `git diff --quiet` rc=0、状态空。
  - `force_degenerate_value`：强制 mapper 结果为 null 后，同一 targeted 尾行 `00:00 +0 -3: Some tests failed.`，3 个 `[E]`；精确还原后 `git diff --quiet` rc=0、状态空。
  - 逐文件 targeted：visual route `00:00 +3: All tests passed!`；debug fixture `00:01 +8: All tests passed!`；defense keyboard `00:00 +3: All tests passed!`；三者 `[E]=0`。
  - analyze：`No issues found! (ran in 16.4s)`。
  - format：`Formatted 1628 files (0 changed) in 3.73 seconds.`。
  - 持锁全量：`06:06 +5653: All tests passed!`，`[E]=0`，锁已释放。
  - `git diff --check 274a3b2ec32871bfd3c735fd75bdffa528bdb2e6..b923244d64469969de6e9d30daeec3a783597329` rc=0，工作树 clean。
- 阻塞项：无。
