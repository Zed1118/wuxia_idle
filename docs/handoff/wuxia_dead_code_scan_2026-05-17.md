# 死代码 / YAGNI scan 报告（2026-05-17）

> Nightshift T03 产出。**只扫描不删代码**，所有候选留用户早上 review。

## 0. 扫描范围

- 工作树：`/Users/a10506/Desktop/wuxia-idle-T03`（基于 main HEAD `4132a13`，branch `nightshift/T03`）
- 全仓 `lib/` + `test/`，排除 `.g.dart` 生成文件

---

## 1. 死 provider 候选（A 类）

扫描方式：`grep -rn "@riverpod" lib/ --include="*.dart" | grep -v ".g.dart"` 拿到 30 个 @riverpod 定义，逐一 grep 全仓 lib/ + test/ 引用（排除定义文件自身、生成文件、import/part 行）。

| # | provider 名 | 定义位置 | lib 引用 | test 引用 | 决策建议 |
|---|---|---|---|---|---|
| A-1 | `gameRepositoryProvider` | `lib/data/isar_provider.dart:41` | **0** | **0** | **可删** |
| A-2 | `chapterCompletedProvider` | `lib/features/mainline/application/mainline_providers.dart:37` | **0** | **0** | **可删** |

### 证据

**A-1 `gameRepositoryProvider`**

```
$ grep -rn "gameRepositoryProvider" lib/ test/ --include="*.dart" | grep -v ".g.dart"
（无输出）
```

- `GameRepository` 本身在全仓以 `GameRepository.instance`（单例）直接访问，provider 包装未被任何 consumer 用过。
- isar_provider.dart 注释已说明本文件为"最终态：基础设施层只装 isar + gameRepository 2 个真基础设施 provider"，但 `gameRepositoryProvider` 自身是 YAGNI——所有现有代码走单例，未走 provider。
- GDD.md 无锚点。

**A-2 `chapterCompletedProvider`**

```
$ grep -rn "chapterCompletedProvider" lib/ test/ --include="*.dart" | grep -v ".g.dart"
（无输出）
```

- `chapterStagesProvider`（同文件）被 `stage_list_screen.dart` 消费，但 `chapterCompletedProvider` 从未被任何 UI 或测试引用。
- GDD.md 无"章节全通"标记锚点（§8.1–§8.3 章节 UI 只提关卡列表，未提"全通勾"标识为必交付）。

### 其余 28 个 provider

所有有 lib 或 test 消费者，无死 provider：

| provider | 消费文件（lib/） |
|---|---|
| `isarProvider` | seclusion/encounter/dispel/equipment service providers |
| `numbersConfigProvider` | battle_providers, battle_screen |
| `dropServiceProvider` | battle_providers（BattleNotifier.resolveBattle 内 ref.read） |
| `battleProvider` | battle_providers（leftTeam/rightTeam/battleResult 派生），battle_screen |
| `leftTeamProvider` / `rightTeamProvider` / `battleResultProvider` | battle_screen, battle_demo, stage/tower entry flow |
| `inventoryQuantityByTypeProvider` | enhance_dialog |
| `allEquipmentsProvider` | inventory_screen, lineage_info_provider |
| `allInventoryItemsProvider` | inventory_screen |
| `characterByIdProvider` | character_panel_screen, lineage_info_provider, technique_panel_screen |
| `equipmentByIdProvider` | character_panel_screen, tower/mainline entry flow (invalidate) |
| `techniqueByIdProvider` | character_panel_screen, technique_panel_screen |
| `activeCharacterIdsProvider` | lineage_info_provider, main_menu（通过 lineageInfoProvider） |
| `characterAllTechniquesProvider` | technique_panel_screen, tower/mainline entry flow (invalidate) |
| `seclusionServiceProvider` | seclusion_map_list_screen, seclusion_setup_screen, active_retreat_screen |
| `encounterServiceProvider` | encounter_hook |
| `currentEncounterProgressProvider` | encounter_skill_section |
| `festivalServiceProvider` | todayFestival provider |
| `debugFestivalOverrideProvider` | todayFestival provider, phase2_test_menu |
| `todayFestivalProvider` | main_menu |
| `dispelServiceProvider` | dispel_dialog |
| `lineageInfoProvider` | lineage_panel_screen |
| `enhancementServiceProvider` | enhance_dialog |
| `forgingServiceProvider` | forging_panel |
| `mainlineProgressProvider` | stage_list_screen, chapter_list_screen, chapterStages/chapterCompleted |
| `chapterStagesProvider` | stage_list_screen |
| `rngProvider` | stage_entry_flow, tower_entry_flow |

---

## 2. 0-lib-consumer Service Class（B 类）

扫描方式：`grep -rE "^class \w+Service" lib/ --include="*.dart" | grep -v ".g.dart"` 拿到 12 个 Service class，逐一 grep lib/ 引用。

**结论：无 0-lib-consumer 候选。**

| Service | lib 引用（摘要） |
|---|---|
| `BattleResolutionService` | `battle_providers.dart`（BattleNotifier.resolveBattle） |
| `TowerProgressService` | `tower_providers.dart`、`tower_entry_flow.dart` |
| `SeclusionService` | `seclusion_service_providers.dart`、3 个 seclusion screen |
| `DispelService` | `dispel_service_providers.dart`、`dispel_dialog.dart` |
| `EncounterService` | `encounter_service_providers.dart`、`encounter_hook.dart` |
| `CharacterAdvancementService` | `tower_entry_flow.dart`、`stage_entry_flow.dart`、`seclusion_service.dart` |
| `CultivationService` | `battle_resolution.dart`（recordSkillUsage 静态调用） |
| `FestivalService` | `festival_service_providers.dart` |
| `ForgingService` | `equipment_service_providers.dart`、`forging_panel.dart` |
| `EnhancementService` | `equipment_service_providers.dart`、`enhance_dialog.dart` |
| `DropService` | `battle_providers.dart`（dropServiceProvider） |
| `MainlineProgressService` | `mainline_providers.dart`、`stage_entry_flow.dart` |

---

## 3. 未引用 private function/method（C 类）

扫描方式：对 lib/ 全部 109 个 Dart 源文件（排除 .g.dart）提取私有函数/方法（`_` 前缀），检查同文件内引用数。

**结论：247 个私有函数/方法全部有 ≥1 调用点，无死 private function。**

分布：
- 2 引用（定义 + 1 调用点）：80 个
- 3 引用：108 个
- 4 引用：16 个
- 5+ 引用：43 个

---

## 4. extension hardcode 嫌疑（D 类）

扫描方式：`grep -n "^extension.*on " lib/ --include="*.dart"` 拿到 8 个 extension，逐一检查方法体内是否有应从 yaml 读的硬编码领域数值（3 位以上数字）。

**结论：无 hardcode 嫌疑，全部合规。**

| extension | on | 是否 hardcode | 说明 |
|---|---|---|---|
| `EquipmentResonance` | `Equipment` | **否** | `resonanceStage` / `resonanceBonus` / `inheritFrom` 全走 `NumbersConfig n` 参数读 yaml |
| `TechniqueDispersion` | `Technique` | **否** | `cultivationProgress * n.dispersionCultivationPenalty` 走 `NumbersConfig` |
| `MapLikeOnRewards` | `List<RewardEntry>` | **否** | 纯集合 Map 语义工具 |
| `MapLikeOnSkillUsage` | `List<SkillUsageEntry>` | **否** | 纯集合 Map 语义工具 |
| `EncounterServiceCurrentSlot` | `EncounterService` | **否** | 仅包装 `IsarSetup.currentSlotId`（基础设施常量，非领域数值） |
| `MapLikeOnSchoolKill` | `List<SchoolKillCount>` | **否** | 纯集合工具 |
| `MapLikeOnBiomeMinutes` | `List<BiomeMinutes>` | **否** | 纯集合工具 |
| `MapLikeOnWeatherMinutes` | `List<WeatherMinutes>` | **否** | 纯集合工具 |

---

## 5. 总结

| 类别 | 扫描量 | 候选数 | 高置信可删 | 需用户确认 |
|---|---|---|---|---|
| A. 死 provider | 30 | **2** | 2 | 0 |
| B. 0-lib-consumer Service | 12 | **0** | — | — |
| C. 未引用 private function | 247 | **0** | — | — |
| D. extension hardcode | 8 | **0** | — | — |

### 推荐处理（下次 sprint）

**高置信度可删（2 个）**：

1. **`gameRepositoryProvider`**（`lib/data/isar_provider.dart:41`）
   - 原因：全仓无消费者，`GameRepository` 走单例访问，provider 包装是 YAGNI。
   - 删除影响：仅删 1 行定义 + `isar_provider.g.dart` 会重新生成（无需手动改）。

2. **`chapterCompletedProvider`**（`lib/features/mainline/application/mainline_providers.dart:37-46`）
   - 原因：全仓无消费者，GDD §8.1–§8.3 章节列表 UI 未设计"全通勾"标记为 Demo 必交付。
   - 删除影响：仅删 ~10 行定义，`mainline_providers.g.dart` 重新生成。
   - 备注：若后续 W18+ 需要章节全通 badge，届时重新添加。

**健康状态（H）**：B/C/D 三类扫描结果 **0 候选 = healthy**，无 follow-up。
