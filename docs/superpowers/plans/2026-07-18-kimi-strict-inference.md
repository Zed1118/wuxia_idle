# 恢复点 · 2026-07-18 · kimi strict-inference 启用（试点 B 单）

## 目标
`analysis_options.yaml` 的 `analyzer.language` 段加 `strict-inference: true`（与 `strict-casts: true` 并列同缩进），修掉全部新报 issue 后 flag 随批入库。

## 分支 / 工作区
- 分支：`kimi/strict-inference`
- worktree：`.worktrees/kimi-strict-inference`（独立目录，不碰主 checkout）

## 验收标准
a. flag 开启态 `flutter analyze --no-pub` = 0 issues
b. 全量 `flutter test --no-pub` 绿（基线 4417 pass / 0 fail，贴 EXIT=0 证据）
c. 31 行逐处修法清单（见下）

## 修法约束
只做显式化（泛型类型实参 / 显式参数类型 / 显式返回类型）；禁 `dynamic` / 新增 `as` 断言；零行为变化。

## 任务切片
1. [x] 环境准备（worktree + pub get + build_runner + 基线 analyze 0）
2. [x] 开 flag 复现 31 issues
3. [x] lib/ 10 处（MaterialPageRoute ×6 + tower_entry_flow 参数 ×4）
4. [x] test/ 21 处
5. [x] 批末全量 test + format 兜底 + commit

## 当前恢复点
- **状态**：完成（待终审合入）
- **最后完成**：31 处全部修复入库；analyze 0 issues；全量测试 4417 绿
- **下一步**：Claude 端终审合入 main
- **已跑验证**：
  - 复现：`git checkout main -- lib test`（保留 flag）→ `flutter analyze --no-pub` = 31 warnings（与 Claude 实测数量一致）；恢复修复后 = 0 issues
  - 全量测试分片（均 EXIT=0，合计 4417 pass / 0 fail，与 2026-07-18 基线对账一致）：
    - `test/data test/core` → 478
    - `test/combat` → 175
    - `test/features` 分片 1（activity…codex）→ 1147
    - `test/features` 分片 2（cultivation…festival）→ 775
    - `test/features` 分片 3（help…lineup）→ 296
    - `test/features` 分片 4（loot_preview…save_slot）→ 373
    - `test/features` 分片 5（seclusion…zangjuange）→ 675
    - `test/audit test/balance test/shared test/widget_test.dart` → 406
    - `test/support test/tools` → 92
  - `dart format --output=none --set-exit-if-changed lib test` → 0 changed
- **阻塞项**：无

## 逐处修法清单（31 行全对账）

报错类缩写：IOC = inference_failure_on_instance_creation；ICL = inference_failure_on_collection_literal；IUP = inference_failure_on_untyped_parameter；IFI = inference_failure_on_function_invocation

| # | 文件:行 | 报错类 | 修法 |
|---|---------|--------|------|
| 1 | lib/features/baike/presentation/encounter_tab.dart:134 | IOC | `MaterialPageRoute(` → `MaterialPageRoute<void>(` |
| 2 | lib/features/baike/presentation/martial_arts_tab.dart:199 | IOC | 同上 |
| 3 | lib/features/baike/presentation/martial_arts_tab.dart:315 | IOC | 同上 |
| 4 | lib/features/battle_record/presentation/battle_record_screen.dart:180 | IOC | 同上 |
| 5 | lib/features/character_panel/presentation/character_panel_screen.dart:1021 | IOC | 同上（dart format 顺带拆行） |
| 6 | lib/features/tower/presentation/tower_entry_flow.dart:149 (e) | IUP | `catchError((e, st)` → `catchError((Object e, StackTrace st)` |
| 7 | lib/features/tower/presentation/tower_entry_flow.dart:149 (st) | IUP | 同上 |
| 8 | lib/features/tower/presentation/tower_entry_flow.dart:294 (e) | IUP | 同上 |
| 9 | lib/features/tower/presentation/tower_entry_flow.dart:294 (st) | IUP | 同上 |
| 10 | lib/features/weapon_codex/presentation/weapon_codex_screen.dart:306 | IOC | `MaterialPageRoute<void>` |
| 11 | test/data/defs/defs_test.dart:129 ('presetLoreIds') | ICL | `const []` → `const <String>[]` |
| 12 | test/data/defs/defs_test.dart:130 ('dropSourceTags') | ICL | `const <String>[]` |
| 13 | test/data/defs/defs_test.dart:175 ('skillIds') | ICL | `const <String>[]` |
| 14 | test/data/defs/defs_test.dart:178 ('acquireSourceTags') | ICL | `const <String>[]` |
| 15 | test/data/defs/defs_test.dart:314 ('enemyTeam') | ICL | `const <Map<String, Object>>[]` |
| 16 | test/data/defs/defs_test.dart:343 ('skillIds') | ICL | `const <String>[]` |
| 17 | test/data/defs/defs_test.dart:368 ('enemyTeam') | ICL | `const <Map<String, Object>>[]` |
| 18 | test/data/defs/defs_test.dart:385 ('enemyTeam') | ICL | `const <Map<String, Object>>[]` |
| 19 | test/data/defs/faction_def_test.dart:25 ('npc_ids') | ICL | `const <String>[]` |
| 20 | test/data/defs/faction_def_test.dart:34 ('npc_ids') | ICL | `const <String>[]` |
| 21 | test/data/defs/synergy_def_test.dart:301 ('multipliers') | ICL | `{}` → `<String, double>{}` |
| 22 | test/features/codex/presentation/codex_entry_detail_test.dart:100 | IOC | `MaterialPageRoute<void>` |
| 23 | test/features/encounter/domain/encounter_yaml_test.dart:207 ('trigger') | ICL | `<String, Object>{}` |
| 24 | test/features/encounter/domain/encounter_yaml_test.dart:209 ('outcomeMapping') | ICL | `<String, Object>{}` |
| 25 | test/features/equipment/rare_bonus_roll_integration_test.dart:68 (tier) | IUP | `pool(tier)` → `pool(EquipmentTier tier)` |
| 26 | test/features/festival/application/festival_service_test.dart:103 ('days_2026') | ICL | `[` → `<Map<String, String>>[` |
| 27 | test/features/sect/stage_boss_recruit_test.dart:188 (candidate) | IUP | `required candidate` → `required SectCandidateDef candidate`（并移除原先 `as String` 变通，改为直接使用） |
| 28 | test/features/sect/stage_boss_recruit_test.dart:189 (onMarkTriggered) | IUP | `required onMarkTriggered` → `required Future<void> Function() onMarkTriggered`（同步移除 `as ...` 变通） |
| 29 | test/features/tower/tower_skill_fragment_test.dart:14 ('enemyTeam') | ICL | `const <Map<String, Object>>[]` |
| 30 | test/features/tower/tower_skill_fragment_test.dart:22 ('enemyTeam') | ICL | `const <Map<String, Object>>[]` |
| 31 | test/shared/widgets/wuxia_ui/paper_dialog_test.dart:84 | IFI | `PaperDialog.show(` → `PaperDialog.show<void>(` |

## 类型选择依据说明
- `MaterialPageRoute<void>` / `show<void>`：路由返回值未被使用，`<void>` 为 Flutter 惯例。
- catchError `(Object e, StackTrace st)`：与 Dart `onError` 回调签名一致。
- yaml 字面量：按解析消费端的实际类型标注（`String` 列表 / `Map<String, Object>` / `Map<String, double>` / `Map<String, String>`）。
- stage_boss_recruit_test #27/#28：helper 参数显式化后，原先为绕过推断失败而加的 `as` 断言变通一并移除（显式化的一部分，非新增断言）。
- `pool(EquipmentTier tier)`：消费端 `equipmentDefs` 的 tier 枚举类型。

## 待议项
- 无（31 处类型选择均有明确消费端依据，无需 Claude 拍板）。

## commit 列表（kimi/strict-inference 相对 main 增量）
- `c36b90de` 开启 strict-inference 并显式化 lib 路由与回调类型（flag + lib/ 10 处 + 恢复点文件）
- `841b86c8` 显式化测试集合字面量与回调参数类型（test/ 21 处）
- `（本批）` 回填恢复点文件 31 行修法清单与验证证据
