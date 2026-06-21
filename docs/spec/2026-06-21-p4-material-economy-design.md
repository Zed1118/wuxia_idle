# P4 长期档案·子项3 — 材料系统 + 银两经济 · 设计 spec

> 2026-06-21 brainstorm 定稿 · opus xhigh · 拆 2 实装 plan（共用本 spec）
> 阶段：P4 长期档案（战绩册✅ + 兵器谱✅ 后第 3 子项）

## 1. 背景与动机

Phase 0 摸排（两轮只读查证，结论均带 file:line）确立事实地基：

- **无任何货币系统**：全仓搜 银两/铜钱/coin/currency/gold 仅命中 UI 色值 `WuxiaUi.gold`，无经济货币。
- **材料已是消耗品骨架**：磨剑石/心血结晶是 `ItemType` enum（`lib/core/domain/enums.dart:19-20`），存于 `InventoryItem` @collection（堆叠式 `defId+quantity`，`lib/core/domain/inventory_item.dart:11-25`），被强化消费（`lib/features/equipment/application/enhancement_service.dart:200-246`）。磨剑石靠闭关被动产出，心血结晶仅强化失败必得 1 颗。
- **经验丹/秘籍是纯占位**：`ItemType.jingYanDan` / `ItemType.techniqueScroll` 有 enum + `EnumL10n` 显示名，但**零消费代码、零掉落配置**。
- **掉落/背包架构已就绪**：`drop_entry.dart` 的 `ItemDrop(inventoryItemDefId+quantity+dropChance)` 已支持材料掉落；`InventoryItem` 支持任意 ItemType。
- **成长服务现成可接**：角色经验 `Character.experience`（`character.dart:32`）→ `CharacterAdvancementService.applyExperience()`（`character_advancement_service.dart:37-94`）推境界升层；心法解锁 `SkillUnlockService`（`skill_unlock_service.dart`）`grantManual()` 首通真解 / `addFragment()` 残页集齐 5 片解锁。

结论：本子项**不是从零造系统**，而是在既有 InventoryItem/掉落/成长架构上补一条货币经济闭环 + 激活两种占位材料用途。

## 2. 经济闭环

```
敌人掉落 / 关卡·爬塔首通 / 闭关产出
        ↓ earn（不卖出，避开 §5.1 装备分解）
     银两（新货币）
        ↓ sink
   江湖商店（固定货架·标价固定·无刷新无限购）
        ↓ 买
  磨剑石 / 心血结晶 / 经验丹 / 秘籍
        ↓ 消费
强化↑ / 境界经验↑ / 解锁心法
```

## 3. 决策锚点（brainstorm 用户拍板）

1. **核心定位** = 经济基础批（货币+商店+材料背包），非纯收集图鉴、非全新合成突破系统。
2. **加货币** = 银两（用户主动要求）。货币必须有 sink，否则死钱包。
3. **银两来源** = 通关掉落为主，**不做卖出**（卖装备贴近 §5.1 装备分解红线，回避）。
4. **商店货架** = 固定货架、卖材料为主、永久可买、标价固定、**无刷新无限购**（守 §5.1 留存焦虑）。
5. **材料展示** = 纯材料背包（当前持有数量+来源/用途），**不做材料图鉴**（消耗品历史足迹收集价值低，复用 InventoryItem 不新建 collection）。
6. **货架填充** = 顺带给经验丹/秘籍定义用途（C 扩展），让货架不薄。
7. **经验丹用途** = 加角色经验推境界升层（`applyExperience()`）。
8. **秘籍用途** = 解锁对应心法（`SkillUnlockService`）。
9. **商店入口解锁** = 首次获得银两即解锁（镜像兵器谱/战绩册"获得即解锁"体例）。
10. **银两存储** = `InventoryItem` 新增 `item_silver`（`ItemType.silver`），复用掉落/库存管线，不新建 SaveData 字段、不 bump saveVer（取证后 2026-06-21 改 spec 原 SaveData.silverTaels 方案）。

## 4. 组件设计

### 4.1 银两货币（新 · 存 InventoryItem）
- 存储：新增 `ItemType.silver` 枚举值 + `item_silver` InventoryItem 行（堆叠 quantity=银两数）。**复用既有 InventoryItem 管线，无 SaveData schema 变更、不 bump saveVer**（`@Enumerated(EnumType.name)` 加枚举值无需迁移）。
- 来源接线（全走 yaml，§5.5 离线=在线）：
  - 敌人掉落 / 关卡 / 爬塔首通：dropTable 加 `inventoryItemDefId: item_silver` 条目，复用 `DropService` → `DropResult.items` → caller `_addInventoryItem`（`seclusion_service.dart:578-599`）。
  - 闭关产出：`seclusion_service` 沿 `mojianshi_per_hour` 体例加 `silver_per_hour`，`computeOutputs` 产出后 `_addInventoryItem(item_silver, ItemType.silver)` 入库。
- UI 把 `item_silver` 特殊渲染为货币（商店/背包顶栏货币位），排除出材料网格。
- 不做卖出。

### 4.2 江湖商店（新 · sink）
- 主菜单入口，解锁条件 = 曾获得银两（`item_silver` 库存行存在且 quantity>0，沿兵器谱 `count>0` 解锁谓词体例）。
- 固定货架，货品+标价走新 `data/shop.yaml`（schema 校验）。
- 购买：校验银两充足 → 扣银两 → `addInventoryItem`（材料）/ 生成 Equipment 实例（若售装备，受 §5.3 锁死，本批 P1 货架只材料）。
- **绝无**随机刷新/限购/抽卡/箱子（§5.1）。

### 4.3 经验丹用途（新消费 · P2）
- 背包"使用" → `CharacterAdvancementService.applyExperience(amount)` 加角色经验。
- 给多少经验走道具 def 配置；有界（不秒升、不跳境界锁，守 §5.7）。
- 注意 `isLayerLocked` hook（心魔余毒可能锁升层，`character_advancement_service.dart:69-73`）——使用经验丹时若被锁，经验入账但暂不升层（与既有语义一致）。

### 4.4 秘籍用途（新消费 · P2）
- 背包"使用" → `SkillUnlockService`：一本秘籍 = 直接解锁对应心法（`grantManual`/`markUnlocked`，整本=教全套）；残页是另一条既有路径（集齐 5 片自动解锁），两者并存不冲突。
- 解锁的心法仍受 §5.3 境界锁不能超阶修炼。
- 幂等：已解锁返回提示不重复副作用（`addFragment` 已内置 `alreadyUnlocked` 短路）。

### 4.5 材料背包 UI（新展示）
- 读 `InventoryItem` 展当前持有数量 + 来源/用途说明（文案进 UiStrings）。
- 经验丹/秘籍带"使用"按钮（P2）；磨剑石/心血结晶纯展示。
- 主菜单入口。

## 5. 红线护栏（全程守）

- **§5.1**：商店固定标价卖、无随机箱/抽卡/限购/刷新；不做卖出。
- **§5.5**：银两离线产出 = 在线，不许在线 buff。
- **§5.3/§5.4**：买的装备/心法受七阶境界锁死（`EquipmentTier` `enums.dart:61-69`）；道具是加速/补课非数值膨胀、不跳锁。
- **§5.7**：道具作后期补课，不破坏"先感受缓慢积累"。
- **§5.6**：数值进 numbers.yaml/shop.yaml，文案进 UiStrings/EnumL10n。
- **GDD §12.2 #12**：江湖商店是"待人类拍板"项 → 用户已拍板激活，实装时同步更新 GDD（标记激活 + 固定标价规则，去掉"Demo 不列"）。

## 6. 拆分（一份 spec，2 个实装 plan，依赖排序）

| Phase | 范围 | 红线风险 | 交付独立性 |
|---|---|---|---|
| **P1 经济核心** | 银两货币（ItemType.silver + item_silver 掉落/闭关来源接线）+ 江湖商店（只卖磨剑石/心血结晶，已有用途）+ 材料背包查看 | 低 | 自洽闭环，无死钱包、无无用货品，可独立 ship |
| **P2 新材料用途** | 经验丹加经验 + 秘籍解锁心法 + 背包"使用"入口 + 经验丹/秘籍上货架 + 配置内容 | 中（碰新消费维度，守 §5.4/§5.7） | 建在 P1 之上 |

P1 先做、独立验收；P2 在 P1 合 main 后另起 plan。

## 7. 数据 / schema 变更

- 新增 `ItemType.silver` 枚举值（`lib/core/domain/enums.dart`）+ `EnumL10n.itemType` 加显示名「银两」。**无 SaveData schema 变更、不 bump saveVer**（@Enumerated(EnumType.name) by name，加枚举值天然兼容老档）。
- 新增 `data/shop.yaml`（货品 id + 标价 + 货架分组）+ `GameRepository` 加载 + `_enforceRedLines` 校验（标价上限）。
- dropTable（stages.yaml/towers.yaml）加 `item_silver` 掉落条目；numbers.yaml 闭关 `retreat.maps[*].base_outputs.silver_per_hour`。
- 经验丹/秘籍 item def（P2）：经验丹给多少经验、秘籍对应哪门心法。

## 8. 测试要点

- 银两：item_silver 入库/扣减确定性；老档无 item_silver 行时数量视为 0（无需迁移）。
- 银两来源：战斗结算/闭关产出加银两确定性测。
- 商店购买：银两充足扣减 + 入库存；银两不足拒绝；解锁谓词（首次得银两）。
- 经验丹（P2）：applyExperience 入账 + 升层 + isLayerLocked 边界。
- 秘籍（P2）：解锁心法 + 幂等 + §5.3 锁死不超阶。
- 红线：商店无随机/限购路径（结构性断言）；银两不变相突破数值红线。
- 背包 widget 测：viewport 扩容（见 memory `feedback_listview_widget_test_viewport`）+ Image.asset errorBuilder。

## 9. Deferred / 未决

- 卖出机制（§5.1 边界）：本批不做，若后续要做需单独拍"卖 ≠ 分解"边界。
- 全新材料合成/突破系统：C 方向更深部分，留 P4 后续子项单独 brainstorm。
- 商店售装备/心法：P1 货架只材料；若后续上装备需补七阶锁死购买校验。
- 材料图鉴（收集足迹）：本批不做，消耗品收集价值低。
