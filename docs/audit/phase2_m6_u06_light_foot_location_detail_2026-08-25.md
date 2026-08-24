# P2-M6-U06 轻功统一地点详情验收审计

## 交付范围

- 基线：`af71e90b166470d663c338fe62d3d6f7375d2bbe`
- 分支：`codex/phase2-m6-u06-light-foot-location-detail-20260825`
- 代码候选：`de594c89fe4ddecd8a82b373b2ec8ff186e0914c`
- 最终复审候选：`f333f07418d9746190714c5e2b698a9b75705895`
- 轻功入口先展示生产地点详情，再沿既有 `guardBattleEntry` 进入 `LightFootScreen`。
- 只读既有解锁链、连续通关进度、下一关 `StageDef`、掉落、修为和真实当前掌门；不新增角色选择、派遣、自动化、持久占用或解锁规则。

## 红绿与缺陷史

- 红测提交 `98687727`：在补齐新 worktree 的 `.dart_tool` 与忽略的生成文件后，provider、详情屏和地图路由三个目标均因生产实现缺失而编译失败，未把环境缺件当红测。
- 代码候选 `de594c89`：完成 domain/provider/screen 和地图路由。
- 第一轮复审指出详情 provider 使用旧无界链遍历；`90f336fd` 增加多根、汇合、环、截断与不连通图校验。
- 第二轮复审指出地图状态仍会先调用旧无界遍历；`f333f074` 让地图与详情共用有界校验并新增地图环图回归。
- 最终独立语义复审：P0=0、P1=0、P2=0，确认非法图在地图和详情两条生产路径均 fail closed，详情异常时无 CTA。

## 验证证据

- 聚焦：provider、详情屏、地图与主菜单路由共 `31/31 PASS`。
- 相邻域：`test/features/main_menu test/features/jianghu_map test/features/light_foot` 共 `181/181 PASS`。
- 双视口：`1280x720`、`1440x900` 共 `2/2 PASS`。
- scoped analyze：0 issues；根级 `flutter analyze --no-pub lib test tool`：0 issues。
- 全量：`flutter test --no-pub --reporter compact`，`5447/5447 PASS`。
- 真相源守卫：`test/data/truth_source_guard_test.dart`，`9/9 PASS`。
- `git diff --check`、精确白名单与 worktree clean（READY 前执行）。

## 诚实边界

- 只关闭轻功统一地点详情首缺口；其他地点详情、U06、U14、M5、M6 与二阶段整体仍开放。
- 零 schema/saveVersion、YAML、TUNING、数值、奖励、经济、战斗、main 或 origin/main 变更；未 push。
- `flutter pub get` 与 `build_runner` 只补齐新 worktree 本地依赖/忽略生成物，未扩张跟踪文件范围。
