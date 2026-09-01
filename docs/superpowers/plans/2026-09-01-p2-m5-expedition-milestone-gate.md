# P2 M5 百草岭首次里程碑手动门

## 结果合同

- 单一目标：关闭 M5 固定 `6 × 7 = 42` 分母中百草岭剩余两格，使工程矩阵由 `40/42` 推进到 `42/42`；顶层结论仍须以 exact-tip Gate 为准，真人桌面与 Windows 继续挂账。
- 生产语义：普通节点继续 timed/headless；险关敌队模板 ID 是有限、稳定的 `milestoneId`，与 `routeId=baicao_expedition` 组成宗门级自动化解锁 key。
- 首次门：离线/在途结算遇到尚未亲战通过的险关模板，必须停在该节点前；结清已完成节点、释放参与者并留下可恢复的亲战待办，不得暗中运行该险关。
- 解锁门：只有玩家从百草岭生产入口选择真实可用角色、进入可见 Phase 0A 战斗并获胜，才在奖励与共享战斗账本同一事务中写 `routeId + milestoneId` 已亲战事实；失败不得解锁。
- 后续门：已亲战模板在之后远征中继续走原 headless 节点、原奖励、原伤势和原确定性种子。

## 持久化与迁移

- 新增版本化 `ExpeditionMilestoneRecord` collection，保存 canonical key、待亲战发现事实、原节点 index/seed/cycle 与最终 `manualClearedAt`。
- `saveVersion 0.44.0 → 0.45.0`。旧档最深深度不能证明具体险关模板，迁移保持集合为空，不猜测模板、不补发奖励。
- 不修改 `SaveData` 既有远征深度、奖励金额/概率、节点时长、敌人数值、玩家属性、技能、解锁阈值或战斗 reducer。

## 验收门

1. 未解锁险关：headless combat 不被调用，节点不越门，已完成节点原子返程，pending record 可恢复。
2. 可见亲战：生产入口只允许 exact 当前角色和装配；胜利写手动事实与节点原奖励，失败/装配漂移不写。
3. 已解锁险关：同 `routeId + milestoneId` 后续可 headless；另一个模板仍会停门。
4. 破坏证红至少覆盖：删除首次门、删除胜利记录、绕过生产亲战入口三向。
5. targeted → analyze → `dart format .` → 锁保护全量 → exact-tip Gate；测试删除按契约迁移登记。

## 停止线

- 不新增远征并发、不改变路线方针、周目、奖励、伤势与离线吞吐。
- 不启动 M3/M4；不以 Widget/测试替代真人手感与视觉验收。
