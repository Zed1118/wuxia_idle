# 战斗结算胜负单一真相源设计

## 背景

`BattleResolutionService.resolve` 同时接收 `finalState.result` 与可选
`isVictory`。调用者可以传入互相矛盾的值，进而让掉落、战败惩罚、伤势等结算
脱离最终战斗状态。历史 v1.32 已出现默认胜负错误，说明该 override 是真实误用面。

当前 4 个生产调用中：

- `BattleNotifier.resolveBattle` 已不传 override；
- 主线胜利、主线战败和爬塔胜利分别重复传 `true/false/true`，均与
  `finalState.result` 一致。

## 目标

- `finalState.result` 成为结算胜负唯一真相源。
- 删除 `isVictory` 参数和所有调用侧重复组装。
- 掉落、Boss/心魔战败惩罚、内息恢复和伤势行为保持不变。

## 非目标

- 不引入新的结算 context 类型；本切片只消除已证实的第二真相源。
- 不改变 RNG、掉落率、修炼度、伤势、数值配置或 Isar 写回事务。
- 不合并主线/爬塔/扫荡的其他上下文查询；留待后续 deletion test 证明收益。

## TDD 策略

1. 测试先删除 `isVictory` 调用并新增源码 API 守卫，生产代码未改时应 RED。
2. service 改为只计算 `finalState.result == BattleResult.leftWin`。
3. 删除 3 个 production override，运行完整 battle resolution 行为测试和三条调用路径回归。
