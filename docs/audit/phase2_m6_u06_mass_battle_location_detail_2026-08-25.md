# P2-M6-U06 守城统一地点详情验收审计

## 交付范围

- 基线：`68df70507c0f977fd819498e7e44c819f3d62f13`
- 分支：`codex/phase2-m6-u06-mass-battle-location-detail-20260825`
- 代码/复审候选：`2e3e69b3b0698adafbdb79c1882fd37ddcf49c53`
- 守城入口先展示生产地点详情，再沿既有 `guardBattleEntry` 进入 `MassBattleScreen`。
- 只读既有解锁链、连续进度、下一关 `StageDef`、推荐阵型、波次/敌数、掉落、修为和真实当前掌门；不新增角色选择、派遣、自动化、持久占用或解锁规则。

## 红绿与语义证据

- 红测提交 `208313ba`：补齐新 worktree 的 `.dart_tool` 与忽略生成物后，provider、详情屏、地图和主菜单路由四个目标均因生产实现缺失而编译失败。
- 代码候选 `2e3e69b3`：新增 domain/provider/screen；地图与详情共用有界解锁图校验，拒绝多根、汇合、环、截断与关卡配置不一致。
- CTA 只移动原门禁位置：地图进入详情，详情仍经 `guardBattleEntry` 进入原 `MassBattleScreen`；阵型选择、周目选择、`runStageFlow`、结算与战斗均未改。
- 独立语义复审：P0=0、P1=0、P2=0；复审聚焦与相邻测试 `42/42 PASS`，确认生产数据来源、全通重打和边界声明成立。

## 验证证据

- 聚焦加纸面对比：`37/37 PASS`。
- 相邻域：`test/features/main_menu test/features/jianghu_map test/features/mass_battle`，`200/200 PASS`。
- 双视口：`1280x720`、`1440x900`，`2/2 PASS`。
- scoped analyze：0 issues；根级 `flutter analyze --no-pub lib test tool`：0 issues。
- 全量：`flutter test --no-pub --reporter compact`，`5464/5464 PASS`。
- 真相源守卫：`test/data/truth_source_guard_test.dart`，`9/9 PASS`。
- `git diff --check`、精确 16 文件白名单与 worktree clean 在 READY 前执行。

## 诚实边界

- 只关闭守城统一地点详情首缺口；其他地点详情、U06、U14、M5、M6 与二阶段整体仍开放。
- 零 schema/saveVersion、YAML、TUNING、奖励、经济、战斗、main 或 origin/main 变更；未 push。
- `flutter pub get` 与 `build_runner` 只补齐新 worktree 本地依赖/忽略生成物，未扩张跟踪文件范围。
