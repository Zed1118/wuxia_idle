# 战斗屏出版美术 Phase B1 design · scrim + 背景接线 + 胜负仪式

**日期**：2026-06-01
**范围**：3 项收口(scrim 暗遮罩 / 战斗背景 yaml 接线 / 胜负仪式 overlay)。
**留 Phase B2**:大招题字(hook actionLog) + Boss 边框(加 isBoss schema)。
**纪律**:只改渲染层 + dialog 形态,不碰战斗数值 / 回放 advance 逻辑。

## 决策锚(用户 2026-06-01 拍板)

- scrim opacity **0.4**(仅 hasScene;视觉验收可微调 0.35-0.45)
- 暗幕 opacity **0.7**
- 胜负仪式 = **全屏 overlay · 纯 Flutter**(不依赖 MJ 出图)
- 爬塔 tower(30 floor 无 biome)→ 复用 **battle_innerrealm**(漂浮虚境台贴试炼抽象感)

## ① scrim 暗遮罩

`battle_screen.dart` build 的 Stack 内,`hasScene` 的 `Image.asset` 之后插一层:
```
if (hasScene)
  const Positioned.fill(child: ColoredBox(color: Color(0x66000000))) // black 0.4
```
- 仅 hasScene 时加(无背景图走 WuxiaColors.background 兜底色本身够暗)
- 在背景图之上、SafeArea(战斗 UI)之下 → 压暗背景保前景可读
- 颜色用 numbers/colors token 或 inline const(scrim 是纯 UI 装饰,inline const 可接受;若 lint 要求走 WuxiaColors.battleSceneScrim)

## ② 战斗背景 yaml 接线

`sceneBackgroundPath` 接线链已 ready(StageDef/TowerFloorDef 字段 + 解析 + stage_entry_flow:334 / tower_entry_flow:600 注入)。本项纯数据:给 stages.yaml 每 stage + towers.yaml 每 floor 填 `sceneBackgroundPath`。

主线 biome → 背景映射(7 直接命中 + 8 长尾近邻):

| biome | 背景 | biome | 背景 |
|---|---|---|---|
| mountainForest | battle_mountainforest | desert | battle_frontier |
| cityWall | battle_citywall | teaHouse/inn/alley | battle_citywall |
| frontier | battle_frontier | smithy | battle_drillground |
| drillGround | battle_drillground | escortRoad | battle_mountainpath |
| dock | battle_dock | cliffWaterfall | battle_mountainpath |
| mountainPath | battle_mountainpath | bambooForest | battle_mountainforest |
| innerRealm | battle_innerrealm | temple | battle_mountainforest |

tower 30 floor → 全部 `assets/scenes/battle_innerrealm.png`。

实装:脚本按 biome 批量加(stages.yaml 从 `biome:` 行正向定位插 sceneBackgroundPath) + 全量 analyze 雷达 + loader test 守。
路径前缀 `assets/scenes/battle_<x>.png`。

## ③ 胜负仪式 overlay(全屏 · 纯 Flutter)

替换 `_showResultDialog` 的 AlertDialog → `showGeneralDialog`(全屏 + 淡入 transition + barrierDismissible false):
- **暗幕** `Container(color black 0.7)` 铺满
- **居中 Column**:
  - 印章符(红方印 Container + 字,纯 Flutter 绘)
  - 大题字「胜」(WuxiaColors.resultHighlight 金) / 「败」(绛红 token)·超大字号 + 描边 shadow
  - 副标题(UiStrings:胜=旗开得胜 / 败=败北)
  - 分隔线
  - 统计(沿现 `UiStrings.battleSummary(totalDamage, critCount, tick)`)
  - 继续按钮(金框 · 触 onBattleEnd + onVictory/onDefeat,逻辑完全不变)
- 文案全走 UiStrings(§5.6 不硬编码中文);新增 2-4 段 string
- 胜/败配色 + 文案由 `result == BattleResult.leftWin` 分支

## 测试(TDD)

- **scrim**:hasScene 时 Stack 含 scrim 层 widget 测;无 scene 时无 scrim
- **背景接线**:loader test — 主线 stage `sceneBackgroundPath` 全非空 + 路径 ∈ 7 battle_*.png + biome 映射抽样正确;tower floor 全 = battle_innerrealm。count 用 baseline+delta 不写死
- **胜负 overlay**:result=leftWin → 显金「胜」+ 统计 + 继续按钮;result!=leftWin → 显绛红「败」;点继续触发对应回调(onVictory/onDefeat)
- ListView 测扩 viewport;Image.asset errorBuilder 已有

## 风险 / 红线

- 不碰 battle_engine / BattleNotifier.advance / actionLog 生成(回放架构)
- 改 battle_screen + 新建 victory_overlay widget + stages/towers.yaml + strings + colors
- 改主仓代码用 Edit(worktree 内)或 Bash(主仓);本批建议 EnterWorktree 隔离
- Mac 本地 build + Codex 视觉验收(scrim 观感 / 背景题材对位 / 胜负仪式金绛红)
