# 战斗屏出版美术 Phase B2 设计

**日期：** 2026-06-01
**范围：** 大招题字 overlay + Boss 头像边框
**前置：** B1 已收口(scrim/背景接线/胜负仪式 · `battle_scene` VISUAL_ROUTE 已建)
**关键事实：** 两块改动纯 UI 层，不碰战斗引擎，**不需要 MJ 出图**(题字=动态招式名必须纯 Flutter 文字；Boss 边框=纯 Flutter 描边)。

## 目标

1. 角色释放大招(ultimate)/人剑合一(jointSkill)时，屏幕弹水墨题字招式名，非阻塞自动淡出。
2. 敌方 Boss 头像显示区别于普通敌人的专属边框，提升战斗识别度。

## A. 大招题字 overlay

### 架构
- 新建 `lib/features/battle/presentation/ultimate_caption_overlay.dart`，独立 widget。
- **不复用** VictoryOverlay 的 `showGeneralDialog`(那是 modal 终态)。改 **Stack 顶层 + AnimationController** 自管生命周期。
- 挂载：`battle_screen.dart` 现有 Stack 顶层加 `Positioned.fill`。Z-order：战场 < 飘字 < 大招题字 < 胜负 overlay。

### 触发
- 在 `_playAction(a)`(`battle_screen.dart:313` 附近)加分支：`a.skill?.type` 为 `SkillType.ultimate` 或 `SkillType.jointSkill` 时调 `_showUltimateCaption(a.skill!.name, isEnemy)`。
- **双方触发**(敌方放招制造压迫感)。普攻/powerSkill 不触发。
- 阵营判定：`BattleAction.actorId`(已有字段) → 在 `next` BattleState 左/右队查施法者 → 右队=敌方(isEnemy=true)。`_playAction(a, next)` 已持 next 态，无需改签名。

### 生命周期
- 淡入 ~250ms → 停留 ~1.2s → 淡出 ~350ms。非阻塞，战斗 tick 不暂停。
- **防叠加**：单 overlay 实例 + 一个 caption controller(持 AnimationController)。1.2s 内再来大招 → **覆盖**(重置动画、换文字)，不排队不堆叠。

### 视觉默认(纯 Flutter，Codex 验收微调)
- 屏幕中部偏上，水墨大字招式名(题字字体 + 墨色描边/淡墨团衬底)。
- 玩家方偏暖(流派色调)、敌方偏冷/绛红，呼应水墨克制基调(§5.7)。
- 文案走 skill.name(已在 SkillDef，非硬编码)。

## B. Boss 头像边框

### schema
- `EnemyDef`(`lib/data/defs/stage_def.dart:195`)加 `final bool isBoss`(默认 false)。
- `fromYaml` 解析 `isBoss: true`，缺省 false **向后兼容**。
- **非 Isar 持久化对象，不涉及 saveVersion 升级**。提交标 `[schema]`。

### 传递链
- `BattleCharacter` 加 `final bool isBoss`(默认 false)。
- `_enemyToBattle()`(`stage_battle_setup.dart:288`)签名加 `isBoss`，从 EnemyDef 透传。
- 玩家方构造路径恒 false。

### 渲染
- `character_avatar.dart:45` border 逻辑：`isBoss` 时换 Boss 描边——`WuxiaColors.bossFrame`(新增金色)+ 加粗 6px(可叠外环烫金感)；否则维持现有流派色 4px。纯 Flutter 绘制。

### yaml 标注范围
- 所有 `isBossStage: true` 关卡里**那一个 Boss 敌人**标 `isBoss: true`(小怪不标)。
- 覆盖：主线 6 boss stage(3 小+3 大) + 各章末 Boss + 爬塔 30 层 6 个 boss floor。
- 具体清单实装时 grep `isBossStage: true` 逐个定位标注；每关只标语义上的那个 Boss。

## C. 测试策略(TDD)

### A 大招题字
1. `_showUltimateCaption` 仅 ultimate/jointSkill 触发，普攻/powerSkill 不触发(widget 测，注入含各类 skill 的 actionLog)。
2. 覆盖语义(连续两个大招只显最新)。

### B Boss 边框
1. `EnemyDef.fromYaml` 解析 isBoss(含缺省 false 向后兼容)。
2. `_enemyToBattle` 透传 isBoss。
3. CharacterAvatar isBoss=true 走 Boss 边框分支(widget 测)。
4. yaml 红线：所有标注的 boss 敌人 isBoss 解析正确(production stages.yaml 加载测)。

### 硬约束
- 改 battle_screen 结算/dialog 相关 → **跑全量 `flutter test`**(T16 在 root `widget_test.dart`，scoped 会漏，沿 B1 踩坑)。
- 验收路由自动播放用 `BattleScenarioData.scenarioA-D`，**不能用 BattleDemo.mockTeams**(无普攻招式 AI 崩)。

## D. 验收 + 范围

- **无需 MJ 出图**(纯 Flutter)。
- 复用 B1 `battle_scene` VISUAL_ROUTE(scenarioB 稳胜，左队放大招触发题字)；Boss 边框验收需一个 isBoss=true 的 scenario 或在现有 scenario 标 Boss。
- Codex @ Pen 真机验收题字仪式感 + Boss 边框辨识度，我多模态亲验截图。

### 不做(YAGNI)
- 题字队列堆叠、Boss 专属头像图、题字音效、modal 升级路径。

## 红线对齐
- 不硬编码数值/文案：题字走 skill.name，边框色走 WuxiaColors 新增常量。
- §5.7 克制：题字一闪而过非教程弹窗。
- 不动 numbers.yaml / 战斗公式 / Isar schema。
