# Fourth Tier Experience Batch Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 推进第 4 梯队 10 个体验增强任务,让既有系统更会解释自己,但不新增任务系统、不做催促、不改收益/概率/核心结算。

**Architecture:** 每个任务由 Codex 单独开 `codex/` 分支和独立 worktree 实现,每个分支必须有自己的详细计划文件和 `CLAUDE.md §8.2` 验收 checklist。Claude 后续只做合并审核。所有任务先读 `docs/spec/rejected_task_registry.md`,确认未踩已否/暂缓方向。

**Tech Stack:** Flutter Desktop, Riverpod 3.x, Isar, YAML data, Wuxia UI, existing feature screens and widget/service tests.

---

## 启动前固定读取

- [ ] `CLAUDE.md §7 / §8.0 / §8.2`
- [ ] `PROGRESS.md` 顶段
- [ ] `docs/spec/rejected_task_registry.md`
- [ ] `docs/spec/playability_phase2_backlog.md` 的「2026-06-29 第 4 梯队待选清单」

## 本批次任务总览

### A 组:资源与经营说明

1. **资源总览页二期**
   - 目标:在现有只读资源总览基础上,增加用途分组 / 近期消耗方向 / 主要来源折叠说明。
   - 生产入口:`lib/features/resource_overview/presentation/resource_overview_screen.dart`
   - 测试锚点:`test/features/resource_overview/resource_overview_screen_test.dart`, `test/features/resource_overview/resource_overview_service_test.dart`
   - 红线:不新增消费入口,不改资源数量、产出、结算。

2. **桃花岛建筑手册**
   - 目标:每个建筑展示「产什么 / 消耗什么 / 协同影响 / 产物去向」。
   - 生产入口:`lib/features/taohua_island/presentation/taohua_island_screen.dart`
   - 数据锚点:`lib/features/taohua_island/domain/taohua_island_config.dart`
   - 测试锚点:`test/features/taohua_island/taohua_island_screen_test.dart`
   - 红线:纯说明层,不改 `settle`,不改产量,守在线=离线。

3. **桃花岛产物去向标签**
   - 目标:产物列表标注用于疗伤 / 开锋 / 强化 / 可出售等去向。
   - 生产入口:桃花岛 screen / resource overview 可复用同一 formatter。
   - 测试锚点:新增 formatter 单测 + 桃花岛 widget test。
   - 红线:只读标签,不新增消费、不自动用药、不引导任务。

### B 组:装备与商店说明

4. **装备掉落后详情强化**
   - 目标:胜利结算里点新装备时展示来源、可用角色、境界门槛、是否值得锁定。
   - 生产入口:`lib/features/mainline/presentation/stage_victory_dialog.dart`, `lib/features/equipment/presentation/treasure_drop_overlay.dart`, `lib/features/inventory/presentation/equipment_detail_screen.dart`
   - 测试锚点:`test/features/mainline/presentation/stage_victory_dialog_test.dart`, equipment detail tests。
   - 红线:延续即时处理,不做装备目标追踪、不新增奖励。

5. **商店货架分层展示二期**
   - 目标:商店按修炼 / 强化 / 开锋 / 疗伤 / 常用材料分组,显示库存已有量。
   - 生产入口:`lib/features/shop/presentation/shop_screen.dart`
   - 服务锚点:`lib/features/shop/application/shop_need_hint_service.dart`
   - 测试锚点:`test/features/shop/shop_screen_test.dart`, `test/features/shop/shop_need_hint_service_test.dart`
   - 红线:固定货架,不做刷新、不做折扣、不做限时库存。

6. **开锋槽 3 专属技展示升级**
   - 目标:装备详情把专属技展示成器物绝招:触发条件、流派、适合谁用。
   - 生产入口:`lib/features/inventory/presentation/equipment_detail_screen.dart`, `lib/features/equipment/presentation/forging_panel.dart`
   - 测试锚点:`test/features/inventory/presentation/equipment_detail_screen_test.dart`, `test/features/equipment/presentation/forging_panel_test.dart`
   - 红线:不改候选数量、不改 `skills.yaml` 数值、不改三系锁死。

### C 组:回归与闭关说明

7. **离线回归卡叙事化分组**
   - 目标:离线收益卡按闭关所得 / 桃花岛产出 / 战斗积累做更清晰分组和短标题。
   - 生产入口:`lib/features/seclusion/presentation/offline_recap_card.dart`, `lib/features/taohua_island/presentation/island_recap_card.dart`
   - 测试锚点:`test/features/seclusion/presentation/offline_recap_card_test.dart`, `test/features/taohua_island/island_recap_card_test.dart`
   - 红线:不改收益、不加加速、不制造回访压力。

8. **闭关中状态牌**
   - 目标:闭关进行中时,仅在闭关页内部显示地点、已闭关时长、预计收获类型。
   - 生产入口:`lib/features/seclusion/presentation/active_retreat_screen.dart`
   - 服务锚点:`lib/features/seclusion/application/seclusion_service.dart`
   - 测试锚点:`test/features/seclusion/presentation/active_retreat_exit_test.dart` 或新增 active retreat widget test。
   - 红线:不放主菜单催促,不改 cap,不改结算。

### D 组:塔与掉落仪式

9. **问鼎九霄进度条美化**
   - 目标:爬塔页增加小 Boss / 大 Boss / 当前最高层视觉标记,增强楼层段落感。
   - 生产入口:`lib/features/tower/presentation/tower_floor_list_screen.dart`, `lib/features/tower/presentation/tower_floor_card.dart`
   - 测试锚点:`test/features/tower/presentation/tower_floor_list_screen_test.dart`
   - 红线:不改楼层结构、不改奖励、不改难度。

10. **秘籍获得仪式小升级**
    - 目标:获得秘籍/残页时用「得卷」小型展示层,区别于普通物品掉落。
    - 生产入口:`lib/features/cultivation/presentation/skill_treasure_overlay.dart`, `lib/features/mainline/presentation/stage_victory_dialog.dart`
    - 测试锚点:`test/features/cultivation/presentation/skill_treasure_overlay_test.dart`, stage victory tests。
    - 红线:不改掉落概率、不做残页来源聚合、不新增奖励。

## 推荐推进顺序

### 第一批:低冲突说明层

- [ ] 资源总览页二期
- [ ] 桃花岛建筑手册
- [ ] 桃花岛产物去向标签
- [ ] 商店货架分层展示二期

理由:主要是只读说明与分组展示,容易独立验证,且可以共享“用途/来源”文案与 formatter。

### 第二批:装备与回归反馈

- [ ] 装备掉落后详情强化
- [ ] 开锋槽 3 专属技展示升级
- [ ] 离线回归卡叙事化分组
- [ ] 闭关中状态牌

理由:都在既有反馈流里加层级,不新增系统;但入口较多,适合在第一批 formatter 稳定后做。

### 第三批:仪式与路线节奏

- [ ] 问鼎九霄进度条美化
- [ ] 秘籍获得仪式小升级

理由:视觉/仪式感更强,需要常规视口截图,放后面避免和前两批 UI 文案并发冲突。

## 每个子任务必须交付

- [ ] 独立分支 / worktree,分支名前缀 `codex/`。
- [ ] 独立计划文件,路径 `docs/superpowers/plans/YYYY-MM-DD-<task>.md`。
- [ ] 生产接线证据:说明真实入口、provider/service、消费方。
- [ ] Targeted test:至少跑对应 feature widget/service tests。
- [ ] 红线影响说明:明确不改收益、概率、结算、数值红线、在线=离线。
- [ ] UI 任务常规视口验收:至少 `1280x720` 或 `1440x900` visual smoke;无法截图则说明原因和人工目检范围。
- [ ] 残留风险:未目检/信息密度/文案重复/后续 de-dup。

## 不做事项

- [ ] 不做已否清单中的方向。
- [ ] 不做主菜单催促、每日、限时、任务列表、登录压力。
- [ ] 不做装备目标追踪、掉落缺口标记、残页来源聚合。
- [ ] 不改 saveVersion/schema,除非单独用户拍板。
- [ ] 不把说明层升级偷换成新收益、新入口消费或自动化行为。

## 当前恢复点

- 状态:批次候选已由用户选定,本计划已创建。
- 下一步:按推荐顺序从第一批 4 项开始,逐项创建独立分支和详细计划文件后实现。
- 当前未启动代码实现。
