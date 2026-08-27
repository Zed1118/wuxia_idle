# P2 批一 1.4：VFX 同类渲染短路核查

## 结论

**PASS：未发现第二个因控制器恒缺必需字段而恒不渲染的 VFX kind；不需要追加代码修复。**

本结论基于已完成 N16 的 `eb2909fb [READY] 修复防御特效零像素渲染`。审计分支为 `codex/p2-b1-vfx-short-circuit-audit-20260827`，不修改生产代码或测试。

## 指定短路的生产链

交接单指定的三字段短路位于 `_FeedbackLayerState._gatherPull`，只由 `Phase0aVfxKind.gatherPull` 进入：

1. reducer 对每个真实 pulled outcome 写入非空 `sourcePosition: target.position` 与 `targetPosition: destination`。
2. `Phase0aVfxController` 读取事件坐标；旧手工事件缺坐标时才回退到本拍推进前已 `syncActors` 的 actor 索引。
3. controller 在 `source` 或 `target` 为空时不会创建 entry；成功创建时同时写入非空的 `targetId: outcome.target`、`source`、`vfxTarget`。
4. renderer 因此不会收到“kind 是 gatherPull、但三个必需字段恒为空”的生产 entry。

## 相邻短路复核

| renderer | 进入的 kind | 字段来源 | 结论 |
|---|---|---|---|
| `_guardianMechanicVfx` | `guardIntercepted`、`guardianCoop` | 对应事件的连线端点是 required 非空 `ArenaVector`，controller 原样搬运 | 不存在恒空 |
| `_palmTrail` | `palmTrail` | 玩家 actor 必须存在且目标坐标非空后才创建 entry | 不存在恒空 |
| `_gatherPull` | `gatherPull` | pulled outcome 的目标 id 与拉前/拉后坐标；缺坐标时 controller 先过滤 | 不存在恒空 |
| `_inkVfx` | `meleeSlash`、`gatherVortex`、`clearBurst`、`defeatInk` | 生产事件坐标优先，推进前 actor 快照回退 | 未发现恒空生产路径 |

N16 已把 `defenseStarted` / `defenseResolved` 从依赖零尺寸 `CustomPaint` 的路径改为可见 banner；本审计没有重新打开或改写该实现。

## 验证证据

- `phase0a_event_mapping_test.dart`：44/44 PASS，覆盖 gatherPull 三字段映射、事件坐标优先与旧事件 actor 回退。
- `phase0a_battle_screen_test.dart` 的真实键盘 Q 用例：1/1 PASS；逐个 pulled target 找到实际 `phase0a_gather_pull_<targetId>` `CustomPaint`，并校验连线中点绑定事件快照。
- 审计 worktree 禁区文件 diff 为空。

## 残留边界

本项只回答“是否存在字段契约恒不满足造成的同类短路”。它不替代批二技能特效、破势表现、图层稳定方案的玩家视觉验收，也不对美术强度作产品裁决。
