# 出战编成/换人 UI · design brief(2026-07-05 夜间批 G · 待拍板)

> backlog 四·P2② 遗留:「出战编成/换人 UI(grep 零命中·挂机是否需手动换队=设计决策)」。
> 本 brief 只给现场事实 + 两面论据 + 最小方案 + 推荐,不动代码。

## 现状(现查)

- 出战队 = `SaveData.activeCharacterIds` → `stage_battle_setup.dart:159-229 _buildPlayerTeam`,
  **上限 3 人硬编码**(:115/:217);`Character.isActive`(character.dart:101 @Index)**无任何 UI 改动入口**。
- 入队 = `DiscipleJoinService.joinForClearedStage`(disciple_join_service.dart:23)按通关关卡自动收徒
  (开局单人→渐进扩到 3);character.dart:11 注释「Demo 阶段最多 3 个」;`discipleIds` List 无上限代码。
- 角色战斗差异在 AI 目标选择层:junior 控场分支(battle_ai.dart:76 盯蓄力敌),senior/founder 走
  破绽集火默认链;换人=换 AI 倾向组合,不只是换数值。
- 全仓无「换人/出战」半成品字符串/组件。

## 关键前提(先核这个,决定本项存亡)

**弟子总数会不会 >3?** 若收徒管线终身只产 3 人(自动全员出战),「编成」无选择对象 → 本项
应登记 rejected 收档。若 >3 可达(收徒池 E.1 扩展/多代飞升世代累积/未来内容),编成才有意义。
现状代码上 `discipleIds` 无上限、`activeCharacterIds` 与角色总量解耦——**结构上已为 >3 预留**,
但当前内容管线(joinForClearedStage 固定关卡触发)实际只产 2 徒弟。

## 两面论据

- **做**:多代飞升后世代角色累积是既有系统;若未来收徒扩池,玩家会想按流派克制/AI 倾向组队
  (junior 控场 vs senior 破绽是真策略维度);「只能看不能选」与打磨期"参与感"主旋律相悖。
- **不做**:挂机游戏主旋律是自动;当前内容下无第 4 人,做了=空 UI;§5.7 未解锁系统不该露头;
  增加存档写路径(activeCharacterIds 编辑)= 新校验面(恰 3 人/祖师必在/死亡态?)。

## 最小方案(若拍板做)

门派谱/角色面板成员行加「出战」toggle(写 activeCharacterIds,校验:恰 3 人、founder 必在、
仅在非战斗态可改);不做拖拽阵型/站位(slot 顺序维持现状);中文进 UiStrings。
估算:opus high,spec+impl 半天;触存档写路径,批末全量。

## 推荐

**延后,绑定「收徒扩池」内容批**:编成 UI 单独做=空转(无第 4 人),与扩池同批做才有对象。
本项从 P2 遗留改挂「依赖未解除」(依赖=收徒 >3 内容),符合 backlog 只承载依赖/拍板项原则。

## 拍板点

| # | 问题 | 倾向 |
|---|---|---|
| P1 | 收徒池是否计划扩到 >3? | 用户定(内容规划) |
| P2 | 若扩:编成 UI 与扩池同批 or 先行? | 同批 |
| P3 | 若不扩:本项进 rejected_task_registry? | 是 |
