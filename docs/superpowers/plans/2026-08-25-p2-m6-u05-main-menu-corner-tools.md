# P2-M6-U05 主菜单角落工具区纵切

- taskId: `P2-M6-U05-MAIN-MENU-CORNER-TOOLS`
- milestone: `M6`
- owner: `codex_root`
- base: `30d6b1a3e9405e8ea7915803fa6f93b0e8d817e6`
- branch: `codex/phase2-m6-u05-main-menu-corner-tools-20260825`
- worktree: `/Users/a10506/Desktop/Projects/挂机武侠-phase2-m6-u05-main-menu-corner-tools`

## 目标

落实冻结方案 §11.1 的“设置、退出、资源总览放在角落工具区”：资源总览从养成玩法
卡片移出，设置不再占单独玩法分区；两者与既有退出按钮共同进入主菜单右上工具区，
继续路由既有 `ResourceOverviewScreen` 与 `SettingsPanel`。

## 非目标

- 不把现存塔、轻功、群战、心魔等入口擅自搬入尚未实现的 U06 江湖地图。
- 不决定排行榜未来归位，不删除旧 Screen，不改变任何入口业务门控。
- 不改 schema/saveVersion、YAML、数值、概率、奖励、经济、解锁或 narrative 内容。
- 本纵切不单独宣告 U05/M6 或二阶段完成。

## 精确白名单

- `lib/features/main_menu/presentation/main_menu.dart`
- `test/features/main_menu/presentation/main_menu_corner_tools_test.dart`
- `test/features/main_menu/presentation/main_menu_test.dart`
- `docs/superpowers/plans/2026-08-25-p2-m6-u05-main-menu-corner-tools.md`
- `docs/audit/phase2_m6_u05_main_menu_corner_tools_2026-08-25.md`
- `docs/dispatch/phase0a_overhaul/task_registry.yaml`
- `CLAUDE.md`
- `GDD.md`
- `PROGRESS.md`
- `docs/_archive/GDD_CHANGELOG.md`

## 红绿与门禁

1. 红测证明主内容区不再出现资源总览/设置卡片或设置分区，右上角存在两项工具；
   两项仍进入既有生产页面/面板，退出按钮不丢失。
2. 覆盖 1280×720、1440×900 与窄桌面布局，无 overflow/异常。
3. 运行主菜单、资源总览、设置相邻回归，format、应用/根 analyze、最终全量。
4. 独立语义复核 P0/P1/P2；同步 audit/registry/truth sources 后生成 clean READY。

## 停止条件

若角落工具需要新增未冻结交互、改变设置/资源业务语义或与其他 owner 冲突，记录精确
`BLOCKED`；不以保留玩法卡片的兼容方案冒充冻结信息架构完成。
