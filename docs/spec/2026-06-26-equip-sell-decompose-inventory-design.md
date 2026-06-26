# 装备出售/分解 + 仓库改进 + 升级放慢 设计

> 2026-06-26 · 用户实玩反馈驱动批 · brainstorm 定稿
> 状态：设计已确认（用户逐条拍板），待写实现 plan

## 背景与动机

用户实玩反馈：装备仓库缺少处理垃圾装备的途径（出售/回收），物料界面竖列列表不直观，看不出哪件装备穿在身上，升级太快。本批为 6 块改进，核心是**推翻一条核心设计红线**。

## ⚠️ 红线决策史（用户 2026-06-26 拍板推翻）

原设计两条明文红线：
- **GDD §2.1**：「装备分解 → 装备永久保留，作为收藏品」
- **CLAUDE §5.1 / `shop_service.dart`**：「只买不卖（不做卖出/退款）」

用户经 brainstorm AskUserQuestion 明确选「**推翻红线·出售+分解全开**」。本批将：
- GDD §2.1 把「装备分解 / 卖出」从「不做」清单移除，改写为「装备可出售换银两 / 可分解成强化材料」，并标注 2026-06-26 拍板推翻 + 理由（玩家处理垃圾装备的真实痛点）。
- CLAUDE §5.1 同步订正：反主流清单移除「装备分解」「卖出」两项（保留体力/每日/抽卡/VIP 等其余红线不动）。
- `shop_service.dart` 头注「只买不卖」订正。
- §5.1 其余红线、§5.3 境界锁、§5.4 数值红线**全部不动**。

## A. 装备出售（→ 银两）

- **纯函数** `equipmentSellPrice(EquipmentTier tier, int enhanceLevel) → int`：`基价[tier] × (1 + 0.1 × enhanceLevel)` 向下取整。
- **基价表**（numbers.yaml `equipment.sell_price`，**待真机校**）：寻常货 20 / 像样货 50 / 好家伙 120 / 利器 280 / 重器 600 / 宝物 1200 / 神物 2500。
- 数值进 numbers.yaml，不硬编。

## B. 装备分解（→ 强化材料）

- **纯函数** `equipmentDisassembleRewards(EquipmentTier tier, int enhanceLevel) → {mojianshi, xinxuejiejing}`：品阶基础产出（镜像强化成本表 = 部分返还）+ 强化等级额外返磨剑石 `floor(enhanceLevel × tier 系数)`。
- **基础产出表**（numbers.yaml `equipment.disassemble_rewards`，**待真机校**）：
  寻常货 磨剑石1 / 像样货 磨剑石2 / 好家伙 磨剑石4 / 利器 磨剑石7+心血结晶1 / 重器 磨剑石12+心血结晶2 / 宝物 磨剑石18+心血结晶4 / 神物 磨剑石25+心血结晶8。
- 材料走既有 `item_mojianshi` / `item_xinxuejiejing`（ItemType.moJianShi / xinXueJieJing）upsert。

## C. service + 仓储（出售/分解执行）

- 新增 `EquipmentRepository.deleteEquipment(int id)`：`isar.writeTxn(() => isar.equipments.delete(id))`。
- 新增 `EquipmentDisposalService`（或并入既有 service）：
  - `sell(equipmentId)` 原子事务：校验非已装备/非师承 → 算价 → 删装备 + 入银两（复用 ShopService 银两 upsert 路径）。
  - `disassemble(equipmentId)` 原子事务：同上校验 → 算料 → 删装备 + 入材料。
- **守护**：已装备（`ownerCharacterId != null`）/ 师承遗物（`isLineageHeritage`）不可出售/分解（service 层硬拦，UI 层禁用按钮兜底）。

## D. 一键按品级（批量）

- 装备 tab 每个品阶分组头加「一键出售 / 一键分解」按钮。
- 点击弹**确认框**：显「将处理 N 件，预计获得 X 银两」/「将处理 N 件，预计获得 磨剑石×Y 心血结晶×Z」。
- **护栏**：批量**自动排除已装备 + 师承遗物**（不计入 N、不处理）。全品阶（含宝物/神物）允许批量，但都走确认框（用户拍板「用批量」）。
- 批量执行 = 逐件走 service 单件路径（一个 writeTxn 包整批，失败回滚）。

## E. 已装备视觉标记

- 装备格子 tile（`_EquipmentGridTile` / `ItemSlot`）：`ownerCharacterId != null` 时加醒目标记——边框高亮 + 角标「装备中」（中文进 UiStrings）。
- 与既有师承 ★（`Icons.auto_awesome`）、境界锁灰化叠加，层级不冲突（标记在不同角）。

## F. 商店入口

- 仓库屏顶部（物料 tab 货币行旁，或屏级 header）加「进商店」按钮，路由 `ShopScreen`。中文进 UiStrings。

## G. 物料界面格子化

- 物料 tab 从 ExpansionTile 竖列 → 格子网格（复用 `ItemSlot` 风格）：按 ItemType 分组标题 + 格子（图标 + 数量角标）+ 保留「使用」入口（可用类如经验丹/秘籍）。
- 货币行（银两）保留在顶部。

## H. 放慢升级（纯数值）

- 只改 numbers.yaml `level` 段 exp 曲线（**待真机校**）：`exp_to_next_base` 120→200，`exp_to_next_per_level` 40→80（约翻倍，使每级更稀有）。
- **每级属性提升不动**（仍 +15血/+8内力/+1速）——用户选「放慢速度」非「加大属性」。
- 同步全仓硬编码 exp 断言（grep `exp_to_next` / `120` / `40` 相关测试，逐条改）。

## 红线 / 纪律

- 数值全 numbers.yaml；中文全 UiStrings/EnumL10n；出售/分解恒走 service 原子事务。
- §5.3 境界锁、§5.4 数值红线、§5.1 其余项（体力/每日/抽卡/VIP…）**不动**。
- 唯一推翻项 = 装备出售/分解（已拍板，本 spec §红线决策史 记录）。

## 测试策略

- **纯函数测**（`test()`）：sell_price / disassemble_rewards 各品阶×强化等级、真 numbers.yaml 契约。
- **service 测**（`test()`，Isar writeTxn 不嵌 testWidgets）：sell/disassemble 删装备+入银两/料、已装备/师承拒绝、批量排除护栏。
- **widget 测**（`testWidgets`）：已装备标记渲染、一键确认框、物料格子化布局、商店入口路由、批量按钮排除已装备。
- **红线/契约**：exp 曲线值变更后全仓断言同步；分解材料 id 契约（item_mojianshi/item_xinxuejiejing 存在）。

## 验收

headless 测不到的手感项（出售/分解交互、批量确认、格子化观感、已装备标记醒目度、升级节奏）待 `flutter run -d macos` 真机目检。
