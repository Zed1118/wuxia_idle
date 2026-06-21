# 材料经济 balance 校准 — 设计文档

> 2026-06-21 · P4 长期档案·子项3 材料经济 P3(balance)。承接 P1(银两+商店)/P2(经验丹+秘籍用途) 的占位数值校准。
> brainstorm 拍板 5 决策 + 2 处摸排前提更正。数值用 `balance_simulator` 迭代到锚,本 doc 给目标/公式/初值/验证法,不钉死最终数。

## 1. 背景与范围

P1/P2 上层闭环但银两收入/标价/dropChance/经验丹增益全占位。本批校准到可玩节奏。

**摸排更正(防幻觉,已亲查 dropTable 证伪)**:
- ❌「Ch4-6 6 本秘籍无掉落来源」= 摸排幻觉(混淆残页 `dropSkillFragmentId` 与道具 `inventoryItemDefId`)。**真相:9 本秘籍道具全已挂掉落**(主线 3:guan_shan_ba_ji@01_05/ma_ta_fei_yan@02_05/ye_yu_shi_nian_deng@03_05 + 爬塔 6:kai_bei_shou/yan_zi_san_chao/zhu_ying_yao_hong/jin_gang_fu_mo/jing_hong_zhao_ying/yue_luo_wu_sheng)。秘籍布局不动。
- ✅ 真缺口:经验丹道具掉落只有大还丹挂 Ch1-3 Boss(stages 375/722/1090),**Ch4-6+爬塔无经验丹来源** → 本批扩展。

**范围**:① 银两收入校准 ② 标价(经验丹动态) ③ 经验丹随境界缩放(schema+消费层) ④ dropChance 校准 ⑤ 大还丹掉落扩展到后期。**不动**:秘籍掉落布局、强化消耗曲线、磨剑石/心血结晶固定标价。

## 2. 设计决策(brainstorm 拍板)

| # | 决策 | 值 |
|---|------|-----|
| D1 | 经济基调 | 适度规划取舍(银两够单线推进,多线并进需攒;有存在感不焦虑,贴 §5.1) |
| D2 | 核心校准锚 | 强化一件主力装备到 +15(≈35 磨剑石≈1050 银两)= **2–3 天**日常挂机(闭关8h+打本)负担 |
| D3 | 经验丹增益 | **随境界缩放**:增益 = 当前境界单层经验 × layer_fraction;凝神 0.2 / 培元 0.5 / 大还 1.0 层 |
| D4 | 经验丹货架标价 | **随境界动态**(防后期套利);磨剑石/心血结晶固定不动 |
| D5 | 大还丹掉落 | 扩展到 Ch4-6 章末 Boss + 爬塔大 Boss(10/20/30 层) |

## 3. 银两收入设计

**保留机制**:闭关 `silver_per_hour`(base × `realm_scale_per_tier` 1.3/阶,cap 72h) + 关卡/塔 dropTable item_silver。

**闭关 base 校准**(学徒基准,×玩家境界 scale):

| 地图 | 解锁 | 现状 base | 初值 base | 说明 |
|------|------|----------|----------|------|
| 山林 | 学徒 | 5 | 8 | 提早期降门槛 |
| 古剑冢 | 三流 | 10 | 14 | +装备掉率副产 |
| 藏经阁 | 三流 | 12 | 14 | +心法领悟副产 |
| 悬崖瀑布 | 二流 | 20 | 24 | 二流主力收入图 |
| 断崖绝壁 | 宗师 | 50 | 60 | 顶级 |

**校准验证(二流锚)**:悬崖 base24 × 1.3²(1.69) ≈ 40.6/h × 8h ≈ 325 + 关卡掉落补 ~100–150 = ~450/天 ≈ 锚 420(略宽松,适度规划取宽好过紧)。

**关卡/塔 item_silver**:保留现状按章/层递增曲线(5→280),作闭关补充,约占日收入 **25–35%**。整体微调系数让总收入贴锚。具体值 simulator 校准。

## 4. 标价设计

**固定标价(材料绝对价值,不缩放)**:磨剑石 30 / 心血结晶 120(已与强化消耗曲线咬合,不动)。

**经验丹动态标价(防套利核心)**:
- **原则**:买丹的「银两→经验」兑换率 ≈ 挂机的「银两→经验」隐含兑换率,全程持平 → 用银两买进度 ≈ 把挂机所得换回等量进度,**无套利**(守 §5.5 挂机为主)。
- **公式**:`price(档,境界R) = 单层经验(R) × layer_fraction(档) × 兑换率k`。k 由学徒锚定(凝神 base≈50/培元 base≈150 反推 k≈1.3 银两/经验),simulator 验证后期不破挂机。
- **效果**:经验丹增益与标价同步随境界涨,后期货架丹贵但增益恒定有感;后期经验丹主要靠掉落大还丹(1.0 层),货架小丹是奢侈补充。

## 5. 经验丹缩放实现

- **schema**:items.yaml 经验丹 `experience: 固定值` → `layer_fraction: 0.2/0.5/1.0`。`ItemDef` 加 `layerFraction` 字段,**废除 experience 字段**(items.yaml 是 def 配置非存档,无迁移负担,消双真相源)。
- **消费层**:`ItemUseService.use` / `CharacterAdvancementService.applyExperience` 链路按「当前境界单层所需经验 × layer_fraction」算实际增益,仍守 isLayerLocked(锁层入账不升层)。需暴露「当前境界单层经验」查询(realmLookup 已传入,扩展取单层门槛)。
- **shop**:经验丹标价改运行时按玩家境界 × base 算(动态),ShopItemDef/ShopService 扩展;磨剑石/心血结晶走原固定路径。

## 6. 掉落分布 + dropChance

**大还丹扩展**(对称现状 Ch1-3 Boss):加 Ch4-6 章末 Boss(实装时查 stages.yaml 实际 Ch4-6 章末 Boss 关 id,勿凭记忆) + 爬塔大 Boss 层(10/20/30)。

**dropChance 校准**:

| 道具 | 现状 | 初值 | 理由 |
|------|------|------|------|
| 大还丹(主线章末 Boss) | 0.2 | 0.25 | 珍贵但首通+重刷可期 |
| 大还丹(爬塔大 Boss) | — | 0.20 | 新增,略低于主线 |
| 秘籍(主线真解) | 0.1 | 首通必得(1.0)倾向 | §8.4「mainline 真解首通必给不挂」;重刷不重复给 |
| 秘籍(爬塔残本) | 0.1 | 0.15 | 江湖偶得磨砺感(§5.7) |

> 主线秘籍「首通必得」实装时核实现有 hook 是否已是首通门控(若是概率则改),爬塔保概率。

## 7. 实现清单

- `data/items.yaml`:经验丹 experience→layer_fraction
- `data/numbers.yaml`:silver_per_hour base 5 图 + 经验丹标价 base/兑换率 k
- `data/shop.yaml`:经验丹标价改动态标记(或移 base 到 numbers)
- `data/stages.yaml` / `data/towers.yaml`:大还丹扩展挂点 + dropChance 校准 + item_silver 微调
- `lib/.../item_def.dart`:layerFraction 字段 + schema 校验
- `lib/.../item_use_service.dart` + `character_advancement`:缩放增益
- `lib/.../shop_*`:经验丹动态标价

## 8. 测试 + 红线

- **测试**:schema(layer_fraction 解析/校验) · applyExperience 按境界缩放(学徒 vs 二流同档丹增益不同) · 经验丹动态标价随境界 · 大还丹新挂点 dropTable 接线 · dropChance 边界 · 秘籍首通门控(若改)。
- **红线**:§5.4 不进数值膨胀(银两/经验不爆) · §5.5 经验丹动态标价防套利(测后期 buy 不优于挂机) · §5.6 全走 yaml · §5.7 秘籍仍仅掉落。
- **验证法**:`balance_simulator` 跑「各境界日收入 vs 养成消费」迭代,确认贴 D2 锚(2–3 天/线) + 无套利窗口。

## 9. 不做(YAGNI)

秘籍掉落布局重构(已全挂)、强化消耗曲线、磨剑石/心血结晶动态标价、银两以外货币、丹药新档位。
