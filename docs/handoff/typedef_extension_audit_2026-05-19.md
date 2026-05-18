# typedef/extension 死字段周期审计 · 2026-05-19

> Nightshift T07 audit 产出。**只列不删**。memory `feedback_extension_hardcode_audit` 周期清账。

## §1 Isar entity extension 总览

9 个 extension，共 17 method/getter。

| EntityExtension | 所在文件 | method/getter 数 | 0 引用候选 |
|---|---|---|---|
| EquipmentResonance | core/domain/equipment.dart:105 | 3 | `inheritFrom` |
| TechniqueDispersion | core/domain/technique.dart:80 | 1 | — |
| MapLikeOnRewards | core/domain/reward_entry.dart:16 | 1 | `quantityOf` |
| MapLikeOnSkillUsage | core/domain/skill_usage_entry.dart:19 | 2 | — |
| CodexCategoryStep | features/codex/domain/codex_category.dart:34 | 2 | — |
| EncounterServiceCurrentSlot | features/encounter/application/encounter_service.dart:474 | 2 | — |
| MapLikeOnSchoolKill | features/encounter/domain/encounter_progress.dart:93 | 2 | — |
| MapLikeOnBiomeMinutes | features/encounter/domain/encounter_progress.dart:116 | 2 | — |
| MapLikeOnWeatherMinutes | features/encounter/domain/encounter_progress.dart:139 | 2 | — |

**详细 0 引用候选：**

- `EquipmentResonance.inheritFrom`（equipment.dart:128）：Phase 5+ 师承飞升时调用，当前
  Demo 不实装飞升逻辑，`grep -rn "\.inheritFrom\b" lib/` = 0 外部 caller。
  注：enhancement_service.dart:60 和 equipment_detail_screen.dart:157 仅注释提及。
- `MapLikeOnRewards.quantityOf`（reward_entry.dart:18）：`grep -rn "\.quantityOf\b" lib/` = 0
  外部 caller。用途不明，无已知 Phase 5 接入点。

## §2 lib/data/defs/ 0 引用字段候选

8 个 def 文件扫描，共 ~107 字段，6 个外部 caller = 0。

| def file | field | 0 外部 caller | yaml 已落 | 推荐处置 |
|---|---|---|---|---|
| stage_def.dart | `narrativeId` | Y | Y（@Deprecated Phase 3 起） | **删**：已标 Deprecated，无 caller |
| stage_def.dart | `dropEquipmentDefIds` | Y | Y | **删**：doc 注明"当前未被任何 service 使用" |
| stage_def.dart | `dropItemDefIds` | Y | Y | **删**：同上，Phase 1 占位保留 |
| equipment_def.dart | `dropSourceTags` | Y | Y | 扩 caller 或删：无 filter 逻辑消费 |
| technique_def.dart | `acquireSourceTags` | Y | Y | 扩 caller 或删：无 filter 逻辑消费 |
| master_def.dart | `enabledInDemo` | Y | Y | 低：Demo flag，Phase 5 清理时再决 |

> `dropSourceTags` / `acquireSourceTags`：yaml 已有值，def 已解析，但全库无一处读取该字段做
> filter/lookup——典型的"yaml→Dart 到此为止"死管道。

## §3 cross-check 总结

- 总 extension method/getter：17
- 0 引用 method：2（`inheritFrom` / `quantityOf`）— **11.8%**
- 总 def 字段扫描（8 def 文件）：~107
- 0 外部 caller 字段：6 — **5.6%**

## §4 推荐处置（优先级排）

1. **高 · 删**：`StageDef.narrativeId` — @Deprecated 已有 6 个月，无 caller，直接删字段 +
   yaml + fromYaml 一行。
2. **高 · 删**：`StageDef.dropEquipmentDefIds` / `dropItemDefIds` — doc 显式注明无 service
   消费，Phase 5 整理时清（yaml 兼容段同步删）。
3. **高 · 确认后删或留**：`MapLikeOnRewards.quantityOf` — 无 caller，无 Phase 5 规划，确认无
   用途后删。
4. **中 · 扩 caller**：`EquipmentDef.dropSourceTags` / `TechniqueDef.acquireSourceTags` —
   yaml 已配，应在 DropService 或 EncounterService 里接入 tag filter；否则下波直接删。
5. **中 · 留 Phase 5**：`EquipmentResonance.inheritFrom` — 师承飞升时触发，Phase 5 实装时
   补 caller 即可，现阶段保留。
6. **低 · 留 Phase 5**：`MasterDef.enabledInDemo` — Demo 阶段 guard flag，1.0 版移除。

**closeout**：本批仅审计，删/扩 caller 决定由下波 task 起 spec 落。
