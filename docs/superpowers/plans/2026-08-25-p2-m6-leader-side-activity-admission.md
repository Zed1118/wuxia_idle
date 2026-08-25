# P2-M6 掌门支线准入生产纵切计划

## 基线与阻塞

- 基线：`8d63c62105b9bf35f111259673edaf8fea3fdcd3`，继承 U08 clean READY。
- 二阶段方案 §9.6/§9.7 与 M6 Gate 已确认掌门可参加断魂庄和百草岭；闭关或其他活动占用时必须拒绝。
- 当前两个候选 provider 均过滤 `isFounder`，两个 service 又在事务内硬拒绝祖师，导致空闲掌门无法走真实生产入口。

## 本纵切完成定义

1. 真实当前掌门存活、空闲且有主修时，在百草岭与断魂庄生产候选中可见并可选择。
2. 两个 service 在写事务内允许该掌门建立真实活动会话，参与者快照和占用记录指向其真实角色 ID。
3. 掌门闭关、远征中、断魂庄中、死亡、无主修或当前掌门身份悬空时 fail closed；UI 刷新后清除失效选择。
4. 保持单人、周目、补给、恢复、战斗、结算、召回、奖励和返程原语义。
5. 红绿证据、相邻回归、scoped/root-app analyze、精确白名单、最终全量一次和 clean READY 全部成立。

## 非目标

- 不新增普通差遣策略、前台 bot、headless、扫荡或统一报告。
- 不修改 schema/saveVersion、YAML、调优、奖励、经济、解锁、叙事或战斗。
- 不把本纵切冒充完整 U08、M6 或二阶段完成。

## 精确白名单

- `lib/features/expedition/application/expedition_providers.dart`
- `lib/features/expedition/application/expedition_service.dart`
- `lib/features/boss_gauntlet/application/gauntlet_providers.dart`
- `lib/features/boss_gauntlet/application/gauntlet_service.dart`
- `test/features/expedition/expedition_dispatch_test.dart`
- `test/features/expedition/expedition_providers_test.dart`
- `test/features/expedition/expedition_overview_screen_test.dart`
- `test/features/boss_gauntlet/gauntlet_enter_test.dart`
- `test/features/boss_gauntlet/gauntlet_providers_test.dart`
- `test/features/boss_gauntlet/gauntlet_loadout_screen_test.dart`
- 本计划、对应 audit、task registry、`CLAUDE.md`、`GDD.md`、`PROGRESS.md`、`docs/_archive/GDD_CHANGELOG.md`
