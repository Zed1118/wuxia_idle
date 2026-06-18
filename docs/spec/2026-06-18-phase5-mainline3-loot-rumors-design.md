# 第五阶段 · 主线三 · 掉落传闻 UI 设计

> 2026-06-18 brainstorm 收口。源 `docs/spec/phase5_battle_experience_loot_spec_2026-06-17.md` §4。
> **纯展示层**:零 schema 改动、零掉落逻辑改动、零奖励经济改动。只读现有 `dropTable` 派生玩家侧「传闻」分组。

## 0. 已拍板决策(本设计的前提)

- **4.3 首通必得数据源 = B(派生不加字段)**：DropEntry 不加 `firstClearOnly`。「首通必得」纯由「上下文是否首通门控」+ `dropChance == 1.0` 派生。
- **详情入口 = B(info 角标 → PaperDialog)**：关卡卡片加 `info` 角标，点击弹水墨 PaperDialog 显完整分组列；tap 卡片主体行为不变（主线=进战斗，塔层=确认 dialog）。
- **tower 一次性脚注 = 采纳**：塔层 dialog 底部加一行 `UiStrings` 脚注「塔层传闻仅首通可得，错过不补」。

## 1. 现状事实(Phase 0 已核实 · file:line)

- `DropEntry` sealed（`lib/data/defs/drop_entry.dart`）：`EquipmentDrop{equipmentDefId, dropChance}` / `ItemDrop{inventoryItemDefId, quantityMin/Max, dropChance}`，`dropChance: double [0,1]`。
- `StageDef.dropTable` / `TowerFloorDef.dropTable` 已配（`stages.yaml` / `towers.yaml`）。
- **主线掉落每次胜利都 roll**（`battle_resolution.dart:78` `isVictory && stageDef != null`，无首通门控，可反复刷）。
- **塔层 dropTable 只首通发奖**（`tower_progress_service.dart` `isFirstClear` 门控 + `tower_entry_flow.dart:174` 首通才发奖）。
- 关卡 tap → `runStageFlow`（`stage_list_screen.dart:92`，直接进战斗，无详情屏）；塔层 tap → 确认 dialog（`tower_floor_card.dart:93`）。
- 名称/阶解析现成可复用（`stage_victory_dialog.dart`）：
  - 装备名 `GameRepository.instance.getEquipment(defId).name`；阶 `EnumL10n.equipmentTier(def.tier)`；repo 未加载降级 raw defId。
  - 物品名 `EnumL10n.itemType(ItemType.fromDefId(defId))`。
- 三系锁死同源判定 `Equipment.isEquippableAtRealm(RealmTier) => tier.index <= realmTier.index`（`equipment.dart:107`）。

## 2. 桶映射规则(消解 4.2 边界歧义)

集中一处常量（`drop_rumor.dart`，非散写），按以下**顺序**判定（首条命中即返回）：

| 条件 | isFirstClearGated=false（主线） | isFirstClearGated=true（塔层） |
|---|---|---|
| `dropChance == 1.0` | 常可得 | **首通必得** |
| `dropChance >= 0.30` | 偶可得 | 偶可得 |
| `dropChance >= 0.08` | 少有人得 | 少有人得 |
| else | 江湖传闻 | 江湖传闻 |

- 边界明确为闭区间下界：`>= 0.30` → 偶可得；`>= 0.08` → 少有人得（消解原 spec「0.30–0.99 / 0.08–0.30」端点重叠）。
- 4.2 表的 `0.99` 上界仅描述性，实现不判上界（`< 1.0 && >= 0.30` 即偶可得）。
- **禁**显百分比；**禁**网游稀有词（传奇/SSR）。玩家侧词全走 `UiStrings`。

## 3. 组件(新建 `lib/features/loot_preview/`)

> 选址理由：与「禁造平行数据源」一致，只读现有 `dropTable`；独立 feature 便于隔离测试。

### 3.1 `domain/drop_rumor.dart`（纯 Dart，无 Flutter）
- `enum DropRumorBucket { changKeDe, ouKeDe, shaoYouRenDe, jiangHuChuanWen, shouTongBiDe }`（命名锁 GDD 词汇风格，不用网游词）。
- `DropRumorBucket bucketOf(double dropChance, {required bool isFirstClearGated})` — §2 规则。
- `class DropRumorEntry { String defId; bool isEquipment; DropRumorBucket bucket; }`。
- `class DropRumorTable { List<DropRumorEntry> entries; bool isFirstClearGated; bool get isEmpty; }`
  - `factory DropRumorTable.fromDropTable(List<DropEntry> table, {required bool isFirstClearGated})`。
  - `Map<DropRumorBucket, List<DropRumorEntry>> grouped()` — 按桶分组（桶顺序：首通必得/常可得 → 偶可得 → 少有人得 → 江湖传闻）。
  - `List<DropRumorEntry> topRepresentatives(int n)` — 简版取最高桶 n 个代表（默认 3）。

### 3.2 `domain/drop_name_resolver.dart`（薄封装）
- `String equipmentName(String defId)` / `String itemName(String defId)` / `EquipmentTier? equipmentTier(String defId)`，复用 §1 现成解析，repo 未加载/查无 → 降级 raw defId（护轻量 widget 测，参照 `_EquipmentDropRow` 兜底）。
- `bool isAboveRealm(String equipmentDefId, RealmTier currentRealm)` — 装备 `tier.index > currentRealm.index`。

### 3.3 `presentation/loot_rumor_dialog.dart`
- `WuxiaPaperPanel` / PaperDialog 标题「本关传闻」（`UiStrings`）。
- 按桶分组列：每桶一段，桶名 + 该桶物品名（装备带阶色/阶名，物品带名）。
- 越阶装备标「机缘可遇，火候未到」（`UiStrings`）。
- `isFirstClearGated=true` 时底部脚注「塔层传闻仅首通可得，错过不补」（`UiStrings`）。
- 空 dropTable → 「本关无固定收获」（`UiStrings`）。

### 3.4 `presentation/loot_summary_line.dart`
- 一行「可能收获：X · Y · Z」（最高桶代表，最多 3）。defId → 显示名。
- 空 → 「本关无固定收获」。

## 4. 接入

- `stage_list_screen.dart` `_StageRow`：简版行 + info 角标（点击 `showDialog` 弹 `LootRumorDialog`，`isFirstClearGated: false`）。tap 主体仍 `runStageFlow`。
- `tower_floor_card.dart`：简版行 + info 角标（`isFirstClearGated: true`）。tap 主体仍走确认 dialog。
- 当前主修角色 realm 取现有 provider（接入时定位，传给 dialog 做越阶判定）。

## 5. UiStrings 新增词条(集中 sink)

- 桶名 5：`lootBucketChangKeDe`「常可得」/ `lootBucketOuKeDe`「偶可得」/ `lootBucketShaoYouRenDe`「少有人得」/ `lootBucketJiangHuChuanWen`「江湖传闻」/ `lootBucketShouTongBiDe`「首通必得」。
- `lootSummaryPrefix`「可能收获：」/ `lootRumorDialogTitle`「本关传闻」/ `lootNoFixedDrop`「本关无固定收获」/ `lootAboveRealmHint`「机缘可遇，火候未到」/ `lootTowerFirstClearOnlyFooter`「塔层传闻仅首通可得，错过不补」。

## 6. 测试(spec 4.5)

1. **桶映射纯函数测**（`test()`，含 `1.0` / `0.30` / `0.2999` / `0.08` / `0.0799` 边界 × tower/stage 两上下文）。
2. **数据完整性测**：每 mainline 关 + 每塔层 `dropTable` 非空（或显式标注无掉落）。
3. **不越阶守卫测**：每关 `dropTable` 装备项 `tier` ≤ 关卡 `requiredRealm` 对应阶带（防早关掉神物）。
4. **不暴露概率 widget 测**：dialog + 简版行渲染无 `%` 字符。
5. **无网游稀有词白名单测**：桶名/词条不含「传奇/史诗/SSR/legendary/epic」等。
6. **降级 widget 测**：GameRepository 未加载时 dialog/简版行降级 raw defId 不崩（轻量测）。

## 7. 红线守护

- 不动 `dropTable` 数值、不动 `DropService.rollDrops`、不动 `battle_resolution`。
- 文案全进 `UiStrings`（§5.6 不硬编码）。
- 不显百分比、不引网游稀有词（§2.1 反主流）。
- 三系锁死提示复用 §5.3 同源判定，不另立口径。

## 8. 不做(YAGNI)

- 不加 `firstClearOnly` schema（B 决策）。
- 不做掉落概率数值展示。
- 不改塔层「每胜残页」通道（与 dropTable 预览无关）。
- 不为简版做可配代表数（固定 3，需要时再开）。
