# Phase 2 U09 durable reward claim 审计

日期：2026-08-31  
基线：`bdc8c2c5ef8073a5e1a49f06ca5f0a20613cc599`  
候选分支：`codex/p2-m6-u09-reward-claim-receipt-20260831`

## 结论

U09 固定验收门已形成工程候选 `0/1 → 1/1`：七类内容共用 durable `RewardClaimReceipt` 与 v2 canonical `RewardClaimKey`；奖励 effect 和 receipt 位于同一 Isar 写事务；重复领取在 effect 前停止；旧档墓碑只来自可证明的通关事实，不补发奖励。定向、analyze、format 与 full suite 已完成；是否进入 main 仍以测试契约迁移 Gate、总 Gate 和合并态 clean 为准。

这不是 M6 或 Phase 2 整体完成声明。真人试玩与视觉验收仍挂账。

## 生产边界

| 内容 | canonical content kind | 原子 owner | 首通 scope | 迁移墓碑 |
|---|---|---|---|---|
| 主线 | `mainline` | durable journal transaction / shared stage settlement | 宗门 | 已通关关卡 |
| 九霄塔 | `tower` | tower victory settlement transaction | 宗门 | 已通楼层与周目 |
| 轻功 | `lightFoot` | durable activity run transaction | 宗门 | 已通关关卡 |
| 守城 | `massBattle` | durable activity run transaction | 宗门 | 已通关关卡 |
| 心魔 | `innerDemon` | shared stage settlement transaction | 个人 | 不建立，旧档无实际领取者 |
| 断魂庄 | `gauntlet` | gauntlet reward transaction | 宗门 | `clearedGauntletIds` |
| 百草岭 | `expedition` | recall transaction | 无首通层；重复/成长为个人 | 不建立，旧档无 durable run identity |

迁移版本为 `0.42.0`。墓碑只写 `RewardClaimReceipt`，不写奖励 payload，不修改奖励数量、概率、经济、解锁、玩家数值、技能或战斗规则。

## 破坏证红

四个独立破坏点均在精确反向补丁恢复前真实失败：

1. 绕过持久重复查询：重启重复领取用例 `1/1` 失败，报 `Unique index violated`。
2. 将塔崩溃钩子移到事务提交后：塔原子回滚用例 `1/1` 失败，`highestClearedFloor` 实际为 `1`、预期为 `0`。
3. 将心魔首通错误改为宗门共享：个人 scope 用例 `1/1` 失败，实际不再全部为 `personal`。
4. 跳过 0.42.0 墓碑迁移：迁移用例 `1/1` 失败，receipt canonical 集合为空。

## 已完成的定向证据

- key / durable service / claim plan：`32/32`
- mainline / durable activity / milestone：`35/35`
- mainline 补充结算组：`25/25`
- tower combat / progress / flow：`39/39`
- tower 原子结算：`4/4`
- tower sweep 路径：`7/7`
- gauntlet reward / recovery / flow：`20/20`
- expedition recall / settlement / startup：`23/23`
- migration：`9/9`
- 精确恢复后的受影响测试整组：`89/89`
- app scope analyze：`flutter analyze lib test`，`0 issue`
- format：`1683 files / 0 changed`
- 持锁 full suite：`5792/5792`，exit `0`，`[E]=0`，末行 `All tests passed!`，墙钟 `5:24`

整仓 `flutter analyze` 会递归进入独立的 `tools/phase0minus_probe` 子 package，并因其依赖未在 root package 解析而产生非 app 源码错误；app 分析使用项目根的 `lib test` scope，总 Gate 仍按仓库脚本执行。

## 尚待最终收口

- `test_contract_migration_gate.sh` 与总 Gate；
- 合并推送后确认 `main == origin/main` 且 clean。
