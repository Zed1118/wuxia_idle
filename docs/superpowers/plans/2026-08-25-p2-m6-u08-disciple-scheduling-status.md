# P2-M6-U08 门人调度当前态纵切计划

## 基线与缺口

- 基线：`9354ff9521ee469c238226bd29a1702bec7631cb`。
- 宗门 Hub 的“门人调度”和门派谱顶部动作仍打开 `TeamLineupScreen`。
- 该旧屏以三席战场站位为 UI，并经 `LineupService` 改写全局 `activeCharacterIds` / `Character.isActive`；这与二阶段“每个活动入口单独选择参与者、不恢复全局 3v3 阵容”冲突。

## 本切片完成定义

1. 建立只读门人调度摘要：真实当前掌门、当代门人、存活状态、闭关/百草岭/断魂庄占用。
2. 身份悬空、当代成员悬空、重复活动占用或 provider 异常时 fail closed。
3. 宗门 Hub 与门派谱两个生产入口均进入新调度页，不再进入旧三席编成屏。
4. 新页不写 `activeCharacterIds` / `isActive`，明确参与者仍在各玩法入口逐次选择。
5. 保留当前解锁门槛；不实现仍待签字的渐进解锁，不删除兼容字段或 debug 旧屏。
6. 真实红测、聚焦与相邻回归、双视口、两层 analyze、独立语义复核、最终全量一次、clean READY。

## 精确白名单

- `lib/features/lineup/domain/disciple_scheduling_summary.dart`
- `lib/features/lineup/application/disciple_scheduling_provider.dart`
- `lib/features/lineup/presentation/disciple_scheduling_screen.dart`
- `lib/features/sect/presentation/sect_hub_screen.dart`
- `lib/features/character_panel/presentation/lineage_panel_screen.dart`
- `lib/shared/strings.dart`
- `test/features/lineup/application/disciple_scheduling_provider_test.dart`
- `test/features/lineup/presentation/disciple_scheduling_screen_test.dart`
- `test/features/lineup/presentation/disciple_scheduling_production_route_test.dart`
- `test/features/main_menu/presentation/main_menu_sect_hub_test.dart`
- `test/features/character_panel/presentation/lineage_panel_screen_test.dart`
- 本计划、对应 audit、task registry、`CLAUDE.md`、`GDD.md`、`PROGRESS.md`、`docs/_archive/GDD_CHANGELOG.md`

## 明确不做

- 不修改 schema/saveVersion、YAML、数值、奖励、经济、战斗或活动结算。
- 不冻结 `PROGRESSIVE-UNLOCK-01` 或任何 TUNING。
- 不把只读当前态冒充完整 U08；本切片不新增差遣策略，也不替各活动代选参与者。
