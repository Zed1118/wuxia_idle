# P2-M6 九霄塔实际参与者生产纵切计划

## 基线与阻塞

- 基线：`c6c0a6696e68d64efb084f96b9d35cf063d2a711`，继承掌门支线准入 clean READY。
- 冻结方案 §1.2 / §9.2 要求九霄塔可由任意 eligible 空闲角色亲战，成长、伤势和记录归实际参与者。
- 当前地点详情与 `Phase0aTowerBattleHost` 固定当前掌门，入口守卫把任一闭关会话当作全局战斗锁；胜利结算又以 `activeCharacterIds` 过滤 settlement，非 active 门人即使参战也无法获得结算。

## 本纵切完成定义

1. 九霄塔生产层列表逐次展示当前掌门与存活门人，明确标出占用/无主修并只允许 eligible 角色被选择。
2. 玩家选择的同一角色 ID 进入真实 `Phase0aTowerBattleHost`，exact snapshot 与 settlement 均绑定该角色，不回退掌门。
3. 胜负结算中的成长、伤势及既有个人战斗账本（装备 `battleCount`、心法使用）只归 settlement 中的实际选中角色；宗门共享首通奖励保持原语义。
4. 闭关、远征、断魂庄占用、死亡、无主修、历史祖师、悬空身份/装备、重复占用或 provider 异常 fail closed；选择后在 Host 装配前再次复核。
5. 原塔层、周目、进度、战斗、首通奖励、重打、排行榜与胜利仪式不变；完成定向、相邻域、两层 analyze、精确白名单、一次最终全量和 clean READY。

## 非目标

- 不修改扫荡、headless、当值历练、轻功、守城或其他模式参与者。
- 不在本纵切补建“每角色塔层最好成绩”持久模型；冻结方案 §9.2 要求该记录另存，但当前只有存档级 `TowerProgress`，必须在后续获 schema/saveVersion 授权后独立关闭。
- 不新增持久占用、session、reducer、事件或结算真相源。
- 不修改 schema/saveVersion、YAML、调优、奖励、经济、解锁、叙事或战斗规则。
- 不把本纵切冒充 M6 或二阶段完成。

## 精确白名单

- `lib/features/tower/application/tower_providers.dart`
- `lib/features/tower/presentation/tower_floor_list_screen.dart`
- `lib/features/tower/presentation/tower_entry_flow.dart`
- `lib/features/tower/presentation/phase0a_tower_battle_host.dart`
- `lib/features/lineup/application/disciple_scheduling_provider.dart`
- `lib/features/sweep/application/sweep_settlement.dart`
- `lib/features/jianghu_map/domain/tower_location_detail.dart`
- `lib/features/jianghu_map/application/tower_location_detail_provider.dart`
- `lib/features/jianghu_map/presentation/tower_location_detail_screen.dart`
- `lib/shared/strings.dart`
- `test/features/tower/application/tower_participant_selection_test.dart`
- `test/features/tower/presentation/tower_floor_list_screen_test.dart`
- `test/features/tower/presentation/phase0a_tower_wiring_test.dart`
- `test/features/tower/presentation/tower_entry_flow_test.dart`
- `test/features/tower/presentation/apply_tower_victory_resolution_test.dart`
- `test/features/jianghu_map/application/tower_location_detail_provider_test.dart`
- `test/features/jianghu_map/presentation/tower_location_detail_screen_test.dart`
- 本计划、对应 audit、task registry、`CLAUDE.md`、`GDD.md`、`PROGRESS.md`、`docs/_archive/GDD_CHANGELOG.md`
