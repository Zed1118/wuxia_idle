# P2-M6-U05 江湖纪事一级 Hub

- taskId: `P2-M6-U05-JIANGHU-CHRONICLE-HUB`
- milestone: `M6`
- owner: `codex_root`
- base: `062ea6bb5160e1c528ffa3d347a4fdde4a7500da`
- branch: `codex/phase2-m6-u05-jianghu-chronicle-hub-20260825`
- worktree: `/Users/a10506/Desktop/Projects/挂机武侠-phase2-m6-u05-jianghu-chronicle-hub`

## 目标与生产接线

把主菜单平铺的档案入口收拢为“江湖纪事”，提供章节卷轴、人物、已踏足地点、
敌手、装备典故和待处理江湖事六条生产路由。章节、人物、敌手和装备典故复用现有
生产页面；地点只展示按主线真实进度解锁的关卡地点；待处理事项只读取现有
`MainlineSettlementJournal` outbox，并通过既有 `runStageFlow` 恢复消费，不复制
结算、选择或 claim 逻辑。

## 非目标与冻结边界

- 不实现 U06 江湖地图/地点玩法面板，不改变关卡解锁。
- 不扩展 U04 到主线 journal 之外，不新增通用队列或第二真相源。
- 不改 schema、saveVersion、YAML、数值、概率、奖励、经济或 narrative 内容。
- 不把 Boss 战绩、装备典故现有内容深度冒充 M7 全敌人/全内容完成。
- 不修改 main，不 push，不冻结任何 `TUNE-*`。

## 精确白名单

- `lib/features/main_menu/presentation/main_menu.dart`
- `lib/features/mainline/application/mainline_pending_jianghu_affair_service.dart`
- `lib/features/jianghu_chronicle/presentation/jianghu_chronicle_hub_screen.dart`
- `lib/features/jianghu_chronicle/presentation/mainline_location_archive_screen.dart`
- `lib/features/jianghu_chronicle/presentation/pending_jianghu_affairs_screen.dart`
- `lib/shared/strings.dart`
- `test/features/main_menu/presentation/main_menu_jianghu_chronicle_hub_test.dart`
- `test/features/main_menu/presentation/main_menu_test.dart`
- `test/features/baike/presentation/baike_screen_navigation_test.dart`
- `test/features/mainline/application/mainline_pending_jianghu_affair_service_test.dart`
- `test/features/jianghu_chronicle/presentation/mainline_location_archive_screen_test.dart`
- `test/features/jianghu_chronicle/presentation/pending_jianghu_affairs_screen_test.dart`
- `docs/superpowers/plans/2026-08-25-p2-m6-u05-jianghu-chronicle-hub.md`
- `docs/audit/phase2_m6_u05_jianghu_chronicle_hub_2026-08-25.md`
- `docs/dispatch/phase0a_overhaul/task_registry.yaml`
- `CLAUDE.md`
- `GDD.md`
- `PROGRESS.md`
- `docs/_archive/GDD_CHANGELOG.md`

## 实施与验证

1. 先写红测：主菜单单一入口、六路真实 Screen、地点解锁过滤、outbox typed FIFO
   读取、空态/损坏态 fail closed、既有恢复流回调。
2. 最小生产实现；测试 seam 默认关闭，生产始终走 Navigator/Isar/runStageFlow。
3. 运行新增测试、主菜单与相邻档案/主线回归、scoped/root analyze、diff/白名单。
4. 独立语义复核 P0/P1/P2；同步 audit/registry/truth sources。
5. 最终一次全量，clean worktree，tip：
   `[READY][CODEX][P2-M6-U05-JIANGHU-CHRONICLE-HUB] 收口江湖纪事一级 Hub`。

## 停止条件

若证明必须新增 schema、改变未冻结解锁/内容可见性、或目标文件被其他 owner 修改，
记录精确 `BLOCKED`，不绕过合同。
