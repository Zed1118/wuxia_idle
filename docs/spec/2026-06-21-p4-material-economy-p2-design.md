# P4 长期档案·子项3 材料经济 P2 — 新材料用途 · 设计 spec

> 2026-06-21 brainstorm 定稿 · opus xhigh · 建在 P1（银两/商店/背包货币位 ✅）之上
> 父 spec：`docs/spec/2026-06-21-p4-material-economy-design.md`（§4.3/§4.4 已锁机制骨架，本 spec 收口内容/红线/UX 决策）

## 1. 背景

P1 已闭环银两货币 + 江湖商店（只卖磨剑石/心血结晶）+ 背包货币位。P2 激活两种占位材料用途，让货架不薄、材料背包有"使用"语义：

- `ItemType.jingYanDan`（经验丹）/ `ItemType.techniqueScroll`（秘籍）现状=纯占位（有 enum + EnumL10n 名，零消费、零掉落）。
- 成长服务现成可接：经验 → `CharacterAdvancementService.applyExperience(ch, delta, isLayerLocked)`（`lib/features/cultivation/application/character_advancement_service.dart:37`，static，返回 `AdvancementResult`）；招式解锁 → `SkillUnlockService.grantManual(skillId)`（`lib/features/cultivation/domain/skill_unlock_service.dart:34`，Future<bool>，markUnlocked 幂等）。

**关键缺口（Phase 0 实证）**：当前**无任何「道具效果」配置层**——`ShopItemDef`（`lib/data/defs/shop_item_def.dart:11`）只映射 `itemDefId`，没有「这颗丹给多少经验 / 这本秘籍解锁哪门招」。且 3 档经验丹共享同一 `ItemType.jingYanDan`，`EnumL10n` 按 enum 给名分不开。→ P2 必须新建道具效果真相源。

## 2. 决策锚点（brainstorm 用户拍板 2026-06-21）

1. **秘籍范围** = 从现有招里 curate（非全部残页/首通、非新作专属招）。最终池 = **全 9 个 `source: fragment` 秘传招**（残页集齐解锁那批；mainline 真解首通必给，不挂秘籍）。
2. **道具来源** = 经验丹小/中档上货架可买 + 大档仅掉落；**秘籍仅掉落不上货架**（守 §5.7「先感受问题再给答案」=保留江湖磨砺中偶得绝学的仪式感，不让银两直接买招）。
3. **经验丹分档** = 小/中/大三档（固定经验值，占位待 balance）。
4. **文案** = 经验丹：凝神丹（小）/ 培元丹（中）/ 大还丹（大）；秘籍：`<招名>·秘籍`（9 本）。

## 3. 组件设计

### 3.1 道具效果配置层 `data/items.yaml`（新）
道具效果真相源。`GameRepository` 加载 + `_enforceRedLines` 校验（经验值上限护栏）。

```yaml
items:
  # 经验丹（3 档，type=jingYanDan，experience 占位待 balance）
  - { defId: item_jingyandan_small, type: jingYanDan, name: 凝神丹, experience: 200 }
  - { defId: item_jingyandan_mid,   type: jingYanDan, name: 培元丹, experience: 600 }
  - { defId: item_jingyandan_large, type: jingYanDan, name: 大还丹, experience: 1800 }
  # 秘籍 ×9（type=techniqueScroll，对应 9 个 fragment 秘传招）
  - { defId: item_scroll_kai_bei_shou,       type: techniqueScroll, name: 开碑手·秘籍,   unlockSkillId: skill_kai_bei_shou }
  - { defId: item_scroll_yan_zi_san_chao,    type: techniqueScroll, name: 燕子三抄·秘籍, unlockSkillId: skill_yan_zi_san_chao }
  - { defId: item_scroll_zhu_ying_yao_hong,  type: techniqueScroll, name: 烛影摇红·秘籍, unlockSkillId: skill_zhu_ying_yao_hong }
  - { defId: item_scroll_jin_gang_fu_mo,     type: techniqueScroll, name: 金刚伏魔·秘籍, unlockSkillId: skill_jin_gang_fu_mo }
  - { defId: item_scroll_jing_hong_zhao_ying,type: techniqueScroll, name: 惊鸿照影·秘籍, unlockSkillId: skill_jing_hong_zhao_ying }
  - { defId: item_scroll_yue_luo_wu_sheng,   type: techniqueScroll, name: 月落无声·秘籍, unlockSkillId: skill_yue_luo_wu_sheng }
  - { defId: item_scroll_guan_shan_ba_ji,    type: techniqueScroll, name: 关山拔戟·秘籍, unlockSkillId: skill_guan_shan_ba_ji }
  - { defId: item_scroll_ma_ta_fei_yan,      type: techniqueScroll, name: 马踏飞燕·秘籍, unlockSkillId: skill_ma_ta_fei_yan }
  - { defId: item_scroll_ye_yu_shi_nian_deng,type: techniqueScroll, name: 夜雨十年灯·秘籍, unlockSkillId: skill_ye_yu_shi_nian_deng }
```

新建 `ItemDef`（`lib/data/defs/item_def.dart`）：`{ defId, type:ItemType, name, experience:int?, unlockSkillId:String? }` + `fromYaml`。校验：jingYanDan 必有 experience、techniqueScroll 必有 unlockSkillId（缺则加载抛错，沿强校验体例）。

### 3.2 经验丹消费
"使用" → `applyExperience(ch, def.experience, isLayerLocked)` 消费 1 颗。守 `isLayerLocked`（心魔余毒锁层 → 经验入账但暂不升层，与既有语义一致）。货架卖小/中（`shop.yaml` 加 2 条，price 占位），大档仅掉落。

### 3.3 秘籍消费
"使用" → `grantManual(def.unlockSkillId)` 消费 1 本。幂等：已解锁 → 提示「此招已了然于胸」不重复副作用（grantManual 返回 false）。解锁的招仍受 §5.3 境界锁不超阶用（既有约束，秘籍不绕）。仅掉落，不进 shop.yaml。

### 3.4 `ItemUseService`（新 · 单一派发点）
`lib/features/inventory/application/item_use_service.dart`。`use(defId)` → 查 `ItemDef` → 按 type 派发（jingYanDan→applyExperience / techniqueScroll→grantManual）→ 消费 1（InventoryItem.quantity-=1，归 0 删行）→ 返回 `ItemUseResult`（区分：经验入账/升层 N 级 · 招式解锁 · 已解锁无效 · 无库存）。纯 service，UI 只调它。**消费与效果同一 writeTxn 原子**（沿 ShopService.purchase 体例，防扣了没生效）。

### 3.5 背包"使用"入口
`_MaterialTab`（`InventoryScreen`）经验丹/秘籍格子加"使用"按钮（磨剑石/心血结晶/银两纯展示无按钮）。点 → PaperDialog 确认 → `ItemUseService.use` → 结果浮层（三态文案进 UiStrings）。沿 ShopScreen 购买弹窗体例 + Image.asset errorBuilder + 缺图 glyph 降级。

### 3.6 `fromDefId` 前缀匹配（避坑 `feedback_enum_fromdefid_default_swallow`）
新增 12 个 defId（3 丹 + 9 秘籍），逐个 case 冗长易漏静默吞 miscMaterial。→ `ItemType.fromDefId` 改前缀判：`item_scroll_*`→techniqueScroll、`item_jingyandan*`→jingYanDan（保留既有 item_mojianshi/xinxuejiejing/silver 精确 case）。新增前缀映射回归哨兵测。

## 4. 红线护栏

- **§5.1**：秘籍不随机不抽卡不限购；货架固定标价。
- **§5.4**：道具=补课/加速非数值膨胀（经验有上限、不跳境界锁；秘籍解锁的招本就存在）。
- **§5.5**：道具掉落离线=在线，不许在线 buff。
- **§5.6**：数值进 items.yaml/numbers.yaml；文案=items.yaml `name`（道具名）+ UiStrings（按钮/结果/确认文案）。
- **§5.7**：秘籍仅掉落保磨砺感；经验丹作后期补课不破坏前期缓慢积累。
- **§5.3**：秘籍解锁招仍受境界锁，不超阶用。

## 5. 数据 / schema 变更

- 新增 `data/items.yaml` + `ItemDef` + `GameRepository` 加载 + 红线校验。
- `data/shop.yaml` 加经验丹小/中 2 条（price 占位）。
- dropTable（stages.yaml/towers.yaml）加经验丹大档 + 9 秘籍掉落条目（dropChance/来源占位，balance pass 校准）。
- `ItemType.fromDefId` 改前缀匹配。
- **无 SaveData schema 变更、不 bump saveVer**（InventoryItem 复用；skillUnlockProgress 既有字段）。

## 6. 测试要点

- ItemDef：items.yaml 加载 + 缺 experience/unlockSkillId 抛错校验。
- 经验丹：applyExperience 入账 + 升层 + isLayerLocked 边界（锁层时入账不升层）。
- 秘籍：grantManual 解锁 + 幂等（已解锁返 false 不重复）+ §5.3 锁死招不超阶（既有覆盖，断言不被秘籍绕过）。
- ItemUseService：消费扣减 + 归 0 删行 + 原子性（效果与扣减同 txn）+ 无库存拒绝 + 各 ItemUseResult 态。
- fromDefId：item_scroll_*/item_jingyandan* 前缀映射哨兵 + 既有精确 case 不回归。
- 背包 widget：viewport 扩容（`feedback_listview_widget_test_viewport`）+ errorBuilder + 使用按钮仅丹/秘籍出现。
- 红线：商店无随机/限购结构断言；经验丹经验值不变相突破数值红线。

## 7. Deferred / 未决

- 经验丹/秘籍掉落具体 dropChance + 银两标价 + 经验值：本批占位，与 balance pass 一并校准（同 P1 银两数值策略）。
- 秘籍上货架：本批守 §5.7 仅掉落；若后续要卖需单独拍「卖招 ≠ 破坏磨砺」边界。
- 道具立绘美术：缺图走 glyph 降级，cover art 后续 art 缺口。
- 视觉验收：背包"使用"按钮 + 确认弹窗 + 结果浮层静态可截 → 实装后 `flutter run -d macos` 真机目检（沿 P1 体例补 debug 路由）。
