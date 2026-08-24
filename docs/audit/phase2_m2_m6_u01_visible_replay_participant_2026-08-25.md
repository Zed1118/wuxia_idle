# P2 M2/M6 U01 可见重打参与者归属审计

## 交付身份

- task：`P2-M2-M6-U01-VISIBLE-REPLAY-PARTICIPANT`
- base：`94b5f0e9b4b9bcfd57a4c83a1abb808bdaf47a3c`
- code candidate：`3e46d216d93090f389fd7b9894ee969ad42f7c95`
- branch：`codex/phase2-m2-m6-u01-participant-attribution-parity-20260825`
- schema：保持 `0.40.0`

## 关闭的生产缺口

已通关主线的可见真人重打现在先列出 active roster 中存活、有主修且未被既有
活动占用的角色。选择结果经既有 `MainlineParticipationPolicy` 校验，装配同一角色
快照并传入真实 `Phase0aMainlineBattleHost`；占用、角色/主修/装备悬空或当前领队
指针损坏均拒绝，不回退掌门。

胜利结算继续以 settlement 实际参与者发放经验、熟练度和伤势；本批补齐无主掉落
历史事件的实际参与者归属。founder tutorial 仍只认真实 founder，未偷换语义。

## TDD 与审查

初始红测证明入口缺少选角/快照消费，且无主装备事件错误归 founder。后续损坏主修
与领队指针红测分别捕获原始 `StateError` 泄漏；独立审查又发现悬空装备会被装配器
静默忽略，真实红测先确认返回了可战快照，再以精确装备存在性守卫修复。

独立复审结论：P0=0、P1=0、P2=0，READY。非阻断测试欠账是完整 UI 到真实 Host
身份断言，以及非掌门 Boss 战败伤势专门回归；现有生产参数链和共享结算覆盖未见
语义缺口。

## 验证

- 新增选角/损坏态测试：6/6 PASS。
- 联合定向：57/57 PASS。
- 主线目录：408/408 PASS。
- 根应用 `flutter analyze --no-pub lib test tool`：0 issue。
- 最终全量：5322/5322 PASS。
- `dart format --set-exit-if-changed`、`git diff --check`、任务白名单：PASS。

## 边界

本批只关闭可见 `realtime + human + replay` 纵切。第一周目连续 run、headless、
扫荡和特殊模式合同未改；前台 bot、听剑生产接线及比例/cap、U01/U05、M2/M6、
M3/M4/M7/M8/M9 和整个二阶段仍开放。未改数值、奖励、概率、解锁、叙事、schema
或 saveVersion；未修改 main，未 push，未冻结任何调优值。
