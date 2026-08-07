# 代码路径迁移映射表

> **用途**:仓内历史文档(`docs/handoff/` `docs/sessions/` `docs/superpowers/` 等)大量引用 2026-05 重构前的旧路径。读到"找不到的文件"时先查本表——多数不是失修,是当时的真实路径。
> **来源**:2026-08-07 全表在主工作树逐条实测(`ls`/`find`),非照抄文档。主迁移发生在 2026-05-13~19 Phase 5.3,账本见 `docs/handoff/week15_phase5_3_lib_structure_finalization_2026-05-16.md`(⚠ 该文件记录的是迁移过程本身,**其中的旧路径必须保留**,不可替换)。

## 一、已删除的顶层目录

`lib/ui/` · `lib/providers/` · `lib/services/` · `lib/combat/` · `lib/data/models/` · `test/ui/` · `test/services/` — 全部已 rmdir,成员见下表。

## 二、目录级映射

| 旧 | 新 |
|---|---|
| `lib/ui/theme/` | `lib/shared/theme/` |
| `lib/ui/effects/` | `lib/shared/effects/` |
| `lib/utils/` | `lib/shared/utils/` |
| `lib/ui/battle/` | `lib/features/battle/presentation/` |
| `lib/ui/character_panel/` | `lib/features/character_panel/presentation/` |
| `lib/ui/inventory/` | `lib/features/inventory/presentation/` |
| `lib/ui/enhancement/` | `lib/features/equipment/presentation/`(⚠ 跨 feature) |
| `lib/ui/debug/` | `lib/features/debug/presentation/` |
| `lib/ui/encounter/` | `lib/features/encounter/presentation/` |
| `lib/ui/narrative/` | `lib/features/narrative/presentation/` |
| `lib/ui/seclusion/` | `lib/features/seclusion/presentation/` |
| `lib/ui/tower/` | `lib/features/tower/presentation/` |
| `lib/ui/mainline/` | `lib/features/mainline/presentation/` |
| `lib/features/*/domain/*_def.dart` | `lib/data/defs/*_def.dart` |
| `lib/features/*/domain/*_config.dart` | `lib/data/defs/*_config.dart` |
| `lib/features/battle/presentation/widgets/` | `lib/features/battle/presentation/`(去掉 `widgets/` 一层) |
| `lib/features/sect_management/` | `lib/features/sect/` |

## 三、文件级 1:1 映射

| 旧 | 新 |
|---|---|
| `lib/ui/strings.dart` | `lib/shared/strings.dart` |
| `lib/ui/main_menu.dart` | `lib/features/main_menu/presentation/main_menu.dart` |
| `lib/utils/rng.dart` | `lib/shared/utils/rng.dart` |
| `lib/providers/rng_provider.dart` | `lib/shared/utils/rng_provider.dart` |
| `lib/providers/isar_provider.dart` | `lib/data/isar_provider.dart` |
| `lib/providers/battle_providers.dart` / `lib/core/application/battle_providers.dart` | `lib/features/battle/application/battle_providers.dart` |
| `lib/providers/tower_providers.dart` | `lib/features/tower/application/tower_providers.dart` |
| `lib/services/battle_resolution.dart` | `lib/features/battle/application/battle_resolution.dart` |
| `lib/services/stage_battle_setup.dart` | `lib/features/battle/application/stage_battle_setup.dart` |
| `lib/services/encounter_service.dart` | `lib/features/encounter/application/encounter_service.dart` |
| `lib/services/seclusion_service.dart` | `lib/features/seclusion/application/seclusion_service.dart` |
| `lib/services/drop_service.dart` | `lib/features/equipment/application/drop_service.dart` |
| `lib/services/cultivation_service.dart` | `lib/features/cultivation/application/cultivation_service.dart` |
| `lib/services/dispel_service.dart` | `lib/features/dispel/application/dispel_service.dart` |
| `lib/services/mainline_progress_service.dart` | `lib/features/mainline/application/mainline_progress_service.dart` |
| `lib/services/phase2_seed_service.dart` | `lib/features/debug/application/phase2_seed_service.dart`(⚠ 跨域) |
| `lib/combat/battle_state.dart` | `lib/features/battle/domain/battle_state.dart` |
| `lib/data/models/character.dart` | `lib/core/domain/character.dart` |
| `lib/data/models/enums.dart` | `lib/core/domain/enums.dart` |
| `lib/data/models/lore.dart` | `lib/core/domain/lore.dart` |
| `lib/data/models/skill_usage_entry.dart` | `lib/core/domain/skill_usage_entry.dart` |
| `lib/data/models/encounter_progress.dart` | `lib/features/encounter/domain/encounter_progress.dart` |
| `lib/data/models/retreat_session.dart` | `lib/features/seclusion/domain/retreat_session.dart` |
| `lib/features/stage/stage_entry_flow.dart` | `lib/features/mainline/presentation/stage_entry_flow.dart` |
| `lib/features/equipment/presentation/equipment_detail_screen.dart` | `lib/features/inventory/presentation/equipment_detail_screen.dart` |
| `lib/features/taohua_island/domain/island_building_{type,state}.dart` | `lib/core/domain/island_building_{type,state}.dart`(⚠ 去 core 不是 defs) |
| `lib/core/audio/sound_manager.dart` | `lib/shared/audio/sound_manager.dart` |
| `lib/data/enum_localizations.dart` | `lib/features/battle/domain/enum_localizations.dart` |

## 四、语义近似(职责也变了,不可机器批替)

| 旧 | 最近似现存物 | 说明 |
|---|---|---|
| `lib/core/combat/formulas.dart` | `lib/features/battle/domain/damage_calculator.dart` | 名与职责皆变 |
| `lib/features/battle/domain/battle_engine.dart` | 无单一继承者 | 拆成 battle_ai / battle_state / damage_calculator / strategy/* |
| `lib/features/cultivation/domain/dispel_cultivation.dart` | `lib/features/dispel/application/dispel_service.dart` | 提升为独立 feature |
| `lib/shared/widgets/wuxia_ui/paper_panel.dart` | `light_paper_panel.dart` / `panel_surface.dart` | 一拆二,按上下文选 |
| `test/data/numbers_config_test.dart` | `numbers_config_{red_lines,skill_unlock,treasure_drop,progression_release_cap,skill_proficiency,sect_event_def}_test.dart` | 一拆六 |

## 五、已彻底不存在(无继承者,引用只能标「已移除」)

**代码**:`lib/features/home_feed/`(空目录) · `lib/features/level/` · `lib/features/pvp/{application,presentation}/` · `lib/features/battle/presentation/camera_shake.dart` · `lib/features/battle/domain/battle_action.dart` · `lib/features/equipment/domain/enhancement_{rules,aid}.dart` · `lib/features/equipment/application/enhancement_context_provider.dart` · `lib/features/equipment/domain/forging_slot_activity.dart` · `lib/features/boss_gauntlet/application/gauntlet_reward_service.dart` · `lib/test_support/`

**测试**:`test/features/battle/presentation/battle_drag_skill_test.dart` · `test/support/def_loading.dart` · `test/tools/floor30_soft_gate_diagnostic_test.dart` · `test/data/{drop_table,enemy_def_vulnerability_validation}_test.dart` · `test/combat/battle_engine_test.dart`

**数据**:`data/{ranks,inventory,chapters,proficiency}.yaml` · `data/models/` · `data/codex/`(实为 `data/narratives/codex/`) · `data/narratives/{techniques,retreat,mainline_test_0*}` · `data/narratives/lore/events/`(实为 `data/lore/` + `data/events/`) · `data/lore/{pvp,masters}/`

**文档**:`docs/UX_GUIDELINES.md` · `docs/legal/` · `docs/progress` · `docs/audits/`

## 六、不是死链的三类(勿"修")

1. **`.gitignore` 声明不入库**:`docs/handoff/**/*.png` · `docs/screenshots/` · `docs/art/` · `test/tools/output/` · `docs/handoff/visual_capture_*/` 等。文件在本地磁盘真实存在,按策略不入库,引用是验收证据索引。
2. **worktree / branch 名**:形如 `docs/equip-baicao-orchestration@25221323`,是 git worktree 命名空间不是文档路径。
3. **build 产物**:`*.g.dart` 已 gitignore,主树跑过 build_runner 后真实存在;在未跑 build_runner 的 fresh worktree 里扫会全判死链(2026-08-07 B1 扫描踩过)。
