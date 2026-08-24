# P2-M6-U05 心魔入口归位纵切

- taskId: `P2-M6-U05-INNER-DEMON-ENTRY-RELOCATION`
- milestone: `M6`
- owner: `codex_root`
- base: `f6daaa534290e25e6eee0bc0bb686abb500f5823`
- branch: `codex/phase2-m6-u05-inner-demon-entry-relocation-20260825`
- worktree: `/Users/a10506/Desktop/Projects/挂机武侠-phase2-m6-u05-inner-demon-entry-relocation`
- status: `ready_reviewed`
- code candidate: `7d6c2b3a2ceb1fbe6391eeb200b90bbd831ce05c`

## 目标

落实冻结方案 §11.2“心魔不出现在主菜单或地图，入口放到角色突破页面”：删除主菜单
重复心魔入口，保持角色面板突破阻断区的既有心魔 CTA 和 `InnerDemonScreen` 生产路由。

## 非目标

- 不新建或修改江湖地图，不迁移塔、轻功、群战、断魂庄等地点入口。
- 不改变心魔解锁、突破、战斗、失败或奖励语义，不删除 `InnerDemonScreen`。
- 不改 schema/saveVersion、YAML、数值、概率、奖励、经济、解锁或 narrative。
- 不单独宣告 U05、U06、M6 或二阶段完成。

## 精确白名单

- `lib/features/main_menu/presentation/main_menu.dart`
- `test/features/main_menu/presentation/main_menu_inner_demon_entry_relocation_test.dart`
- `test/features/main_menu/presentation/main_menu_test.dart`
- `test/features/character_panel/presentation/character_panel_screen_test.dart`
- `docs/superpowers/plans/2026-08-25-p2-m6-u05-inner-demon-entry-relocation.md`
- `docs/audit/phase2_m6_u05_inner_demon_entry_relocation_2026-08-25.md`
- `docs/dispatch/phase0a_overhaul/task_registry.yaml`
- `CLAUDE.md`
- `GDD.md`
- `PROGRESS.md`
- `docs/_archive/GDD_CHANGELOG.md`

## 红绿与门禁

1. 红测证明主菜单仍存在心魔入口；转绿后主菜单在锁定/解锁进度均无心魔入口。
2. 角色面板达到心魔节点时仍显示突破 CTA，点击进入既有 `InnerDemonScreen`。
3. 运行主菜单、角色面板、心魔相邻回归，format、应用/根 analyze 与最终全量。
4. 独立语义复核 P0/P1/P2；同步 audit/registry/truth sources 后生成 clean READY。

## 停止条件

若删除主菜单入口必须改动心魔业务门控或角色突破入口无法独立承载，记录精确
`BLOCKED`；不以另造临时入口冒充归位完成。

## 完成证据

- 真实红测：锁定态与原 Ch6 解锁态均 `0/2`，证明主菜单重复入口仍存在。
- 转绿：新增迁移测试、主菜单和角色面板联合 `85/85`；相邻主菜单/角色/心魔 `178/178`。
- 角色面板突破 CTA 真实 push 既有 `InnerDemonScreen`，未新增临时入口。
- `flutter analyze --no-pub lib test tool` 与补齐独立子包元数据后的根分析均为 0。
- 全量 `flutter test --no-pub` 为 `5369/5369 PASS`。
- 独立只读复核 P0/P1/P2 均为 0，结论 READY。
- 审计：`docs/audit/phase2_m6_u05_inner_demon_entry_relocation_2026-08-25.md`。
