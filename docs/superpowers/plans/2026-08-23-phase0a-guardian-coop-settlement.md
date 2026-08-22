# Phase 0A 护法合击结算统计兼容计划

## 目标

恢复旧 runner 对护法合击主发起者 `attackResult` 的战后统计语义，避免
Phase 0A 把整次合击从 `totalDamage` / `criticalCount` 中漏掉。只修结算
快照，不改变 reducer 的实际扣血、胜负、掉落、成长或任何 YAML 数值。

## 分支

`main`（用户已授权夜班直接收口、提交并推送）。

## 验收标准

- [x] 生产接线：reducer 事件保存主护法单次伤害/暴击，settlement adapter
      按旧 runner 口径消费；VFX 继续使用双护法合计伤害。
- [x] targeted test：护法 reducer、事件映射、结算适配器相关测试全绿。
- [x] 红线影响：不改玩法数值、三系锁死、在线/离线、文案或 YAML；Dart
      只增加事件事实字段与英文诊断/测试数据。
- [x] 残留风险：旧 runner 本来只把主护法 `attackResult` 纳入统计，搭档伤害
      不计；本批保留该历史口径，不借迁移修复扩大产品统计定义。
- [x] 批末：`flutter analyze --no-pub lib test tool`、`git diff --check`；全量
      已在父提交 `754368b7` 通过 4226/4226，本切片按风险决定是否重跑。

## 任务切片

1. 用历史 `ed05e8c3^` 与当前 reducer/settlement 双向确认兼容口径。
2. 扩充 `Phase0aGuardianCoopStrike` 的主护法统计事实并由 reducer 填充。
3. settlement adapter 消费该事实，补精确回归测试。
4. targeted + analyze + diff check，更新总账，提交并推送。

## 当前恢复点

- 状态：已完成，待提交推送。
- 最后完成：事件保存主护法单次伤害/暴击，settlement 按历史口径恢复统计；
  VFX 继续读取双护法合计伤害，未改实际扣血。
- 下一步：更新总账，提交并推送。
- 已跑验证：application/phase0a 目录 138/138、guardian reducer 4/4、事件
  映射 44/44，共 186/186；analyze 0、diff check 通过。父提交全量
  4226/4226、macOS release 构建成功（174.1MB）。
- 阻塞项：无；不得把统计改成仅玩家输出，该口径与历史事实冲突。
