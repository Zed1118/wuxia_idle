# P2 M6 U05 “武学与行囊”一级 Hub 纵切

## 任务包

- taskId：`P2-M6-U05-MARTIAL-INVENTORY-HUB`
- milestone：M6
- owner：`codex_root`
- baseCommit：`e618f6b2b970609cf0a99189125b2ec2ffc0796f`
- branch：`codex/phase2-m6-u05-martial-inventory-hub-20260825`
- worktree：`/Users/a10506/Desktop/Projects/挂机武侠-phase2-m6-u05-martial-inventory-hub`
- status：`in_progress`

## 已确认生产缺口

二阶段方案 §11.1 冻结第二个一级入口“武学与行囊”，内含技能、主修、装备、物品。
当前主菜单仍把装备仓库、心法面板、藏经阁作为三个散列入口，没有统一 Hub；物品只隐藏
在装备仓库第二 Tab，一级信息架构尚未迁移。

本纵切建立一个生产 Hub，收拢四条既有路由并从主菜单移除上述散列入口；不处理“宗门”、
“江湖纪事”、资源总览角落工具化或其他玩法入口。

## 文件白名单

- `lib/features/main_menu/presentation/main_menu.dart`
- `lib/features/martial_inventory/presentation/martial_inventory_hub_screen.dart`
- `lib/shared/strings.dart`
- `test/features/main_menu/presentation/main_menu_martial_inventory_hub_test.dart`
- `test/features/main_menu/presentation/main_menu_test.dart`
- `docs/superpowers/plans/2026-08-25-p2-m6-u05-martial-inventory-hub.md`
- `docs/audit/phase2_m6_u05_martial_inventory_hub_2026-08-25.md`
- `docs/dispatch/phase0a_overhaul/task_registry.yaml`
- `CLAUDE.md`
- `GDD.md`
- `PROGRESS.md`
- `docs/_archive/GDD_CHANGELOG.md`

## 生产合同

1. 主菜单只显示一个“武学与行囊”入口，不再平铺装备仓库、心法面板、藏经阁。
2. Hub 明确提供招式配置、主修心法、装备、物品四项，并复用现有生产 Screen/API。
3. 装备进入 `InventoryScreen(initialTab: 0)`，物品进入 `InventoryScreen(initialTab: 1)`。
4. 招式与主修继续消费既有 tutorial step 3 门控；装备与物品开局可用。
5. 招式与主修使用当前 active roster 第一位角色，不新造角色身份或默认回退规则。
6. 不改变学习、散功、装备/物品写入、解锁、奖励、数值、schema 或叙事。

## TDD 与验收

- 红测：主菜单应只有统一 Hub 且旧三入口不再平铺；Hub 应能把装备/物品分别路由到正确
  Tab，并将当前 active roster 第一位角色传给招式/主修 Screen。现状缺少 Hub 类型与文案。
- 定向：入口唯一性、四路导航、step 0/3 门控、active roster 身份、1280×720 与
  1440×900 无 overflow、既有 main_menu 与相邻导航回归。
- Gate：format、变更范围/root application analyze、`git diff --check`、YAML、白名单、
  独立复核 P0/P1=0、最终一次全量、clean READY。

## 停止边界

若需要改教程步、技能/心法/库存业务规则、资源总览角落工具或其余两个一级 Hub，另立切片。
