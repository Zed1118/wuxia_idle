# Phase 4 W11 victory 路径接 resolveBattle 双端 + 销账 #32（2026-05-13 xhigh 会话）

> 写给下一会话开局者（Mac Opus 自己）看。
> 用户接力同意继续 W11，开整后未中途介入。
> PROGRESS.md「当前阶段」/「已完成」/「已知偏差 #32」是单一信源；本文档补「为什么这么处理」+「Pen 验收要点」+「下次开局必读」。

---

## 1. 一句话结论

W11 把 W10 自审带出的挂账 #32（victory 路径未接 BattleResolutionService）销了。**主线 + 爬塔双端 victory 路径已镜像 W10 `_applyBossDefeatPenalty` 体例**，装备 battleCount / 心法 skillUsage / 主修升层 / 关卡 drop 全在生产路径落地。`main` HEAD `a2de8a2`，**546/546** 测试，analyze 0 issues，4 文件 +277/-4。

---

## 2. commit（本会话单 commit）

| # | hash | 类型 | 简述 |
|---|---|---|---|
| 1 | `a2de8a2` | feat | phase4-w11 victory 路径接 BattleResolutionService 双端（销账 #32） |

无 tag（W11 尚未 Pen 视觉验收，W7-W11 累积一并打 v0.4.0-w11）。

---

## 3. 关键设计决策

### 3.1 `BattleResolutionService.resolve` 的 `stageDef` 改 nullable

**为什么**：tower victory 路径没有 `StageDef`（只有 `TowerFloorDef`），但需要复用 service 做 battleCount/skillUsage 副作用累积。

**最 minimal 改动**：`required StageDef stageDef` → `StageDef? stageDef`。
- 旧 12 case 全部 required 传值，零破坏
- victory + stageDef==null → dropResult 恒空（caller 自处理 drops）
- defeat + stageDef==null → 不进 Boss 散功分支（语义上 tower 路径就不该触发 stage Boss 散功）

**备选方案搁置**：
- 抽 `List<DropEntry> dropTable + bool isBossStage` 独立参数 → API 破坏面大
- 加 `DropResult? overrideDropResult` → 还需要 stageDef，绕一圈

### 3.2 主线 victory drop 双端处理体例对齐 tower `_persistDrops`

**为什么**：tower victory 已有完整 `_persistDrops` 处理装备 owner=null 入背包 + items 写/更新 `inventoryItems`（含 `getByDefId` 累加 quantity）。主线 victory 新增的 `_applyVictoryResolution` **直接复用同体例**，避免发明新模式。

**实现细节**：
- 装备：`isar.equipments.putAll(result.dropResult.equipments)` —— 装备 ownerCharacterId 来自 `EquipmentFactory.fromDef`，默认 null 即入背包
- items：`isar.inventoryItems.getByDefId(item.defId)` → existing.quantity += / 新建 InventoryItem
- ItemType 推断：`_itemTypeOfMainline` 函数与 tower `_itemTypeOf` 同源逻辑（item_mojianshi / item_xinxuejiejing / fallback miscMaterial）

### 3.3 recordVictory 时序在 `_applyVictoryResolution` 之后

**为什么**：

```dart
await _applyVictoryResolution(ref: ref, stage: stage);  // 1. in-place 副作用 + Isar writeTxn
await MainlineProgressService(isar: ...).recordVictory(...);  // 2. 标记关卡通过
ref.invalidate(mainlineProgressProvider);  // 3. UI 刷新
```

保证装备 battleCount 已 ++、心法 progress 已累 → 玩家点开角色面板看到的数值是真实的。如果 recordVictory 在前，UI 可能在 _applyVictoryResolution 完成前就 invalidate 出去显示旧数值。

### 3.4 tower victory 的 drop 处理保留原路径（不接管）

**为什么**：tower drop 有「isFirstClear 首通才发奖」防刷设计（CLAUDE.md §5.1）。如果把 drop 处理移到 `_applyTowerVictoryResolution` 内，需要再传 isFirstClear、ItemType 推断、_FirstClearContent UI 联动等，**改动面远大于让 service.resolve 不内部 roll**。

**最简洁**：`_applyTowerVictoryResolution(stageDef: null)` 让 service 不 roll drops，drops 仍走原 `rollTowerRewards + _persistDrops + isFirstClear` 流，**仅** 把 battleCount/skillUsage 副作用补上。

### 3.5 widget 集成测试与挂账 #31 同类风险

**同 W10 决策**：service 层 5 case（W10）+ 2 case（W11）覆盖 BattleResolutionService.resolve 所有分支（victory/defeat × stage/tower × ±isBossStage × ±numbersConfig）。UI 端到端集成测试（_applyVictoryResolution 从 Isar 拉数据 → resolve → writeTxn → drop 入背包）**与 #31 同类多 provider+真 Isar 链风险**，未硬塞，留 Pen 视觉验收兜底。

---

## 4. 修改清单

### 4.1 `lib/services/battle_resolution.dart`（API）

```diff
   static BattleResolutionResult resolve({
     required BattleState finalState,
     ...
-    required StageDef stageDef,
     required Rng rng,
     ...
+    StageDef? stageDef,
     bool isVictory = true,
     NumbersConfig? numbersConfig,
   }) {
     ...
-    final dropResult = isVictory
-        ? dropService.rollDrops(stageDef, rng)
+    final dropResult = (isVictory && stageDef != null)
+        ? dropService.rollDrops(stageDef, rng)
         : const DropResult(equipments: [], items: []);

-    if (!isVictory && stageDef.isBossStage) {
+    if (!isVictory && stageDef != null && stageDef.isBossStage) {
```

### 4.2 `lib/ui/mainline/stage_entry_flow.dart`（+ `_applyVictoryResolution` + helpers）

- 新增 import: `enums.dart` / `inventory_item.dart`
- victory 分支前置 `await _applyVictoryResolution(ref: ref, stage: stage)`
- 新函数 100+ 行：拉 character/eq/tech + resolve + writeTxn putAll + drop 入背包 + items 写 inventory
- 新 helper `_itemTypeOfMainline(defId)`（与 tower 同源）

### 4.3 `lib/ui/tower/tower_entry_flow.dart`（+ `_applyTowerVictoryResolution`）

- 新增 import: `isar_community/isar.dart` / `character.dart` / `save_data.dart` / `technique.dart` / `battle_resolution.dart`
- victory 分支 recordClear 之后插 `await _applyTowerVictoryResolution(ref: ref)`
- 新函数 60 行：体例同 _applyVictoryResolution 但 stageDef=null，drop 走外层

### 4.4 `test/services/battle_resolution_test.dart`（+2 case）

- stageDef=null + victory → dropResult 空 + battleCount/skillUsage 仍累
- stageDef=null + defeat → 不触发 Boss 散功（无 isBossStage 信号）

---

## 5. 销账 + 挂账状态

| 挂账 | 本会话后状态 | 备注 |
|---|---|---|
| **#32** victory 路径未接 BattleResolutionService | **✅ 销账** | 主线+爬塔双端 |
| 其他全沿用 W10 后状态 | — | 未触碰 |

---

## 6. Pen 视觉验收 spec（W7+W8+W9+W10+W11 累积一并派）

### 6.1 W11 核心新增（必跑）

**场景 1：主线 victory 后装备 battleCount 真的 ++**

1. P5 入口 → 角色面板 → 记下祖师武器 battleCount（如 5）
2. 主线 → stage_01_01（保证胜利）→ 胜利
3. 回角色面板：祖师武器 battleCount 应为 6
4. 大弟子 / 二弟子参战装备也 ++

**场景 2：主线 victory 后心法 progress 真的累**

1. 角色面板 → 心法 → 记下祖师主修当前 progress（如 30/100）
2. stage_01_01 胜利（含主修 skill 行动）
3. 心法 → progress 应增加（按 skill 行动次数累）

**场景 3：主线关卡 drop 入背包**

1. stage_03_05 章末大 Boss（已有 dropTable 配 ≥1 item）→ 胜利
2. 仓库 → 应见关卡产出装备（owner=null）+ items quantity 累加

**场景 4：爬塔 victory 后装备 battleCount 真的 ++**

1. 爬塔 floor_1 胜利
2. 角色面板 → 参战装备 battleCount ++

**场景 5：爬塔 victory drop 仍走首通防刷**

1. floor_1 首通 → drops 入背包（仍走 rollTowerRewards + _persistDrops 原体例）
2. floor_1 重打 → drops 空（重打不发奖）
3. 角色 battleCount 仍 ++（W11 新增,重打也累副作用）

### 6.2 W10 核心新增（已写在 week10 handoff §5.1，沿用）

- Boss 战败 → NarrativeReader 顶部「战败 · 散功代价」红字 banner
- 普通关战败 → 无任何结算 UI（沿用 T60）

### 6.3 W7-W9 累积（沿用 W9 closeout §6 推荐）

- W7：装备 fixture 35 件 / W8：心法 21 本 + 63 招 / W9：爬塔 30 层 UI

---

## 7. Week 12+ 起手指引

### 7.1 候选方向

| 优先级 | 候选 | 阻塞 | 备注 |
|---|---|---|---|
| **高** | **Pen Windows 视觉验收 W7-W11** | 用户在线 | 五周累积，等用户回来一并派 |
| 中 | **Phase 5 收尾** | 无 | #2 DDD / #12 LevelDiff / #28 闭关 e2e |
| 低 | #30 闭关 3 维度 | §12 #7 节气清单 + 农历库 | 需用户决 |
| 低 | C 奇遇 / E 武学领悟 | §12 #6 机缘值规则 | 需用户决 |

### 7.2 推荐顺序

1. **W12**：等 Pen 视觉验收用户在线一并派（5 周累积），同时**自主推进 Phase 5 收尾 #12 LevelDiff**（小范围数值层修复，5-10 行）或 **#28 闭关 e2e widget**（W6 后理论可走 ProviderScope.overrides 注入 tempDir Isar）
2. **W13+**：根据 Pen 验收反馈修问题 / Phase 4 扩展（散功后 buff、装备耐久等）

### 7.3 模型建议

- **Phase 5 #12 LevelDiff**：小范围数值层修复，**high 起步**够用
- **Phase 5 #28 闭关 e2e**：先 high 试，碰真 Isar 注入卡壳再升 xhigh

---

## 8. 数据快照

- main HEAD: `a2de8a2`（push pending 用户决定）
- tag: 无（待 Pen 视觉验收 W7-W11 累积一并打 v0.4.0-w11）
- 测试: **546/546** 全过，analyze 0 issues
- 累计 commit（项目至今）：~77 commits
- 累计 tag：v0.1.0-phase1 / v0.2.0-phase2 / v0.3.0-w1..w6（W7-W11 累积未打）
- Demo 内容量（GDD §7 对照）：主线 15/15 ✅ / 章节 3/3 ✅ / 爬塔 30/30 ✅ / 闭关 5/5 ✅ / 师徒 3/3 ✅ / 装备 35/30-50 ✅ / 心法 21/20-30 ✅ / 奇遇 0/20-30（阻塞）/ 武学领悟 0/30-50（阻塞）
- 关键架构：Riverpod 3.x + Isar community 3.3.2 + nullable propagation（W6）+ Boss 战败被动散功（W10）+ victory 双端接 resolveBattle（W11）

---

## 9. 下次开局必读

1. PROGRESS.md「当前阶段」+「下一步」段（W12 候选）
2. 本文档 §3 关键设计决策（理解 W11 设计哲学），尤其 §3.1 nullable API + §3.4 tower drop 不接管
3. **Pen 视觉验收派单时**：spec 把 §6.1 5 个场景列清楚，**重点验「重打也累副作用」差异点**（爬塔 floor 重打 → 不发 drop 但 battleCount 仍 ++）
4. **写新 widget _persist 时**：沿用 W6 §3.2 模板（ref.read(isarProvider) + null 短路）+ W10/W11 _applyXxxResolution 体例（拉 Isar → resolve → writeTxn putAll）
5. **写 widget test 触发挂账 #31 同类场景**：不要硬上 pumpAndSettle，优先 service 层覆盖（W10+W11 实例：service 21 case + UI 1 case，端到端纯 Pen 验）

CLAUDE.md / GDD.md / numbers.yaml 不动。Mac 端写 `lib/` `data/*.yaml`（顶层）`test/` `docs/handoff/`；DeepSeek 写 `data/narratives/` `data/lore/` `data/events/`。
