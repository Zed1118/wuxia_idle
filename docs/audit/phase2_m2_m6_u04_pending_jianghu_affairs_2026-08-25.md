# P2 M2/M6 U04 第一章待处理江湖事持久队列审计

## 结论

- 状态：`READY / ready_reviewed`
- 基线：`6c849cccaec85703438bc53e7e4d958e3962d358`
- 代码候选：`96196ac6ce0e1c768e5aab7ec8b0c1361a6af863`
- 作用域：仅第一章连续首通结算后的互动奇遇与 Boss 招降。
- 存档：复用 `0.40.0` `MainlineSettlementJournal` outbox；零 collection/字段/saveVersion 变更，旧 `0.40.0` 空 outbox 兼容。

## 生产合同

1. core settlement 同事务生成严格版本化 `encounterChoice` / `stageBossRecruit` typed refs；包含 settlement identity、canonical source、ordinal 与稳定 resolution seed。
2. journal 列表是唯一 FIFO 权威；严禁越序、重复 effect/source 与字符串猜测类型。
3. dialog 展示期间事项仍 pending，因此崩溃后重现；已 claim 事项重放幂等返回，后续队首不受影响。
4. 奇遇 outcome/trigger/声望、招降角色/门派/阶段标记与 claim 同一 Isar 事务；注入失败全部回滚。
5. 普通互动奇遇在命名弟子/里程碑前排空，Boss 招降在原有产品顺序位排空；返回/下一关动作可先持久，但只在 outbox 空后关闭/交接 receipt。

## 崩溃与幂等矩阵

| 中断点 | 恢复行为 | 重复副作用 |
|---|---|---|
| core 提交前 | U01 语义：同人同关重试 | 无 |
| core 已提交、dialog 前 | 从 typed 队首恢复 | 无 |
| dialog 展示中 | 同事项重现 | 无已落库写入 |
| 选择事务中异常 | 业务写入与 claim 同时回滚 | 无 |
| 旧队首已 claim、后续仍 pending | 旧队首返回 false，后续仍为队首 | 无 |

## 验证证据

- typed service：`8/8 PASS`，含 FIFO、重复源、越序、重启、旧 outbox、幂等重放与真实 Encounter 联合回滚。
- 第一章规划/恢复：`3/3 PASS`，普通/Boss/无事项，Boss 保持“奇遇→招降”。
- 主线目录+迁移回归在代码收口前 `407/407 PASS`；最终全量重放覆盖后续修复。
- 全量首轮：`5313` 通过、`2` 失败，精确捕获 inline seeded `DefaultRng` 不可 override 与新 RealmDef 派生创建 sink 未登记。
- 修复后相关契约/恢复 `17/17 PASS`；最终全量 `5315/5315 PASS`。
- `flutter analyze --no-pub lib test tool`：0 issue。全仓无路径参数 analyze 会扫入独立 nested `tools/phase0minus_probe`，该子包未安装自身依赖，不属根应用验收边界。
- 独立复审两轮：首轮发现并关闭旧队首重放 P1；最终 `P0=0, P1=0`。

## 边界与剩余风险

- 本批不改可见布局，复用既有 dialog/banner/snackbar；未伪造新双视口实拍结论。
- 不覆盖塔、断魂庄或任意非主线来源的全局待处理队列；若扩大到该范围，需另立任务并重新评估 schema。
- U01 听剑与 replay/manual/auto/headless/扫荡一致性、U05、M2/M6 以及 M3-M9 仍开放。
- 零 `TUNE-*` 状态升级，零数值/概率/奖励/解锁/文案修改；main 不动，不 push。
