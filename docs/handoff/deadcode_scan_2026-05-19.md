# 死代码 dry-run scan · 2026-05-19

> Nightshift T08 audit 产出。**钉死 dry-run 不删**。

## §1 dart fix --dry-run 摘要

- 总 hint 数: **29**（全部 `unused_import`，无 `dead_code` / `unused_local_variable`）
- 主要 hint type: `unused_import` × 29（100%）
- lib/ 7 文件 × 10 hints；test/ 11 文件 × 19 hints

| 排名 | 文件 | hint 数 |
|---|---|---|
| 1 | `test/features/debug/application/phase2_seed_service_test.dart` | 8 |
| 2 | `lib/features/debug/application/phase2_seed_service.dart` | 4 |
| 3 | `test/features/tower/application/tower_progress_service_test.dart` | 2 |
| 4 | `lib/core/application/inventory_providers.dart` | 1 |
| 5 | `lib/features/baike/presentation/baike_screen.dart` | 1 |

> 其余 13 文件各 1 hint。所有 hint 均在 test/ 或 lib/features/debug/，不涉及核心业务路径。

## §2 @riverpod provider 0 引用 candidates

总 provider 数：**35**（`grep -rn "@riverpod\b" lib/` 实测）

| provider name | def file | 外部引用数 | 备注 | 推荐处置 |
|---|---|---|---|---|
| `leftTeamProvider` | `core/application/battle_providers.dart:156` | **0** | BattleState.leftTeam 通过 battleProvider 直接访问，helper provider 闲置 | 删 |
| `rightTeamProvider` | `core/application/battle_providers.dart:160` | **0** | 同上 | 删 |
| `unlockedCodexCountProvider` | `features/codex/application/codex_providers.dart:30` | **0** | 定义注释说供 UI chip 用，但无 widget 引用 | 扩 caller（BaikeScreen/CodexScreen）或删 |
| `gameEventServiceProvider` | `features/event/application/game_event_service.dart:207` | **0** | 注释说 caller 应通过 provider 取，但实际 5 处 caller 均直接 `GameEventService(isar)` 实例化 | 迁 caller 走 provider 或删 provider |

## §3 service / widget class 0 引用 candidates

Service 扫描：**18 个**（`grep -rn "class \w*Service\b" lib/` 实测），无 0 引用孤立项。

Screen/Page 扫描：**18 个**（`grep -rnE "^class \w*Screen extends|^class \w*Page extends" lib/` 实测），无 0 引用孤立项。

| class | type | def file | 引用数 | 推荐处置 |
|---|---|---|---|---|
| — | — | — | — | 无孤立候选 |

## §4 总结 + 推荐处置（优先级排）

- 总扫描：provider 35 / service 18 / widget 18
- 0 引用 candidate：provider **4** / service 0 / widget 0
- `dart fix` hint：29 条，全 `unused_import`，集中在 debug feature + test

推荐处置：

1. **高优·明确删**：`leftTeamProvider` / `rightTeamProvider` — 功能完全由 `battleProvider` 覆盖，helper 层多余，直接删 2 行定义 + 对应 .g.dart 重生成即可
2. **中优·迁 caller 走 provider**：`gameEventServiceProvider` — 5 处 caller 直接 `new GameEventService(isar)`，与 provider 体系脱节；统一迁走 provider 可接 reactive 刷新；若短期不统一则删 provider 留直接实例化
3. **低优·扩 caller**：`unlockedCodexCountProvider` — 逻辑完整（`tutorialStep.clamp(0,8)`），BaikeScreen 顶部「已解锁 X / 8」chip 应消费此 provider；P1 #42 Phase 2 遗留未接线
4. **低优·cleanup**：`unused_import` 29 条 — `dart fix --apply` 一键修，建议下波 task 顺手处理 test/ 和 debug/ 文件，不阻塞主流程

**closeout**：本批仅 scan，删 / 扩 caller 由下波 task 起 spec（类似 W17 T03 follow-up 删 2 死 provider 体例）。
