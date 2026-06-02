# P0-2 战斗单位可见化 — 设计 spec

日期：2026-06-02
上游：`docs/handoff/wuxia_idle_ui_gap_guidance_2026-06-02.md`（外部 UI 指导）+ `PUBLISHING_ART_PASS_1_0.md §20.6`（执行计划 lock）
目标里程碑：1.0 阻塞（P0）· 实装阶段 xhigh

## 1. 问题

3v3 自动战斗现为「80px 圆头像（玩家走首字占位）+ 血条 + 220px 固定日志侧栏」，第一视觉是日志和背景，**看不出谁在打谁**。指导文件 §4.1 / §P0-2 点名。

证据：`battle_state.dart:286` 玩家 `iconPath: null`；`character_avatar.dart` `avatarSize=80`；`battle_screen.dart:490` 日志侧栏 `width: 220`。

## 2. 方向（用户拍板）

战斗单位用**动作位**方向，**分两段**：
- 本 spec（P0）= 用现有胸像图（敌人 16 已归位 + 角色 portraitPath）搭**动作位骨架**：放大单位 + 接线玩家立绘 + 强化弹道/受击 + 日志折叠 + 遮罩不压暗。
- P1/P2（美术到位后）= 全身动作图 + 逐帧动画换进同一个槽，不返工。

纯表现层改造：**不改 BattleState 战斗逻辑、不引 Flame、不动 data/narratives|lore|events**。

## 3. 设计

### A. 单位形态与放大（`character_avatar.dart`）
- `avatarSize` 默认 80 → **150**（1280×720 两列 3 行放得开）。圆头像（ClipOval）保留 + 放大。
- 流派色粗边框（已有 `schoolColor`）+ Boss 金边（已有 `bossFrame` 6px）。
- **死亡单位**：置灰（ColorFiltered 去饱和）+ 降透明（如 0.45），一眼看出谁倒。
- 缺图仍走现有首字水墨占位（今日 `baa6070` 兜底）。

### B. 玩家立绘接线（`battle_state.dart:286`）
- `iconPath: null` → **`iconPath: character.portraitPath`**（fromCharacter 已持有 character，character.dart:97 有 portraitPath）。师徒有立绘即显，无则首字。敌方已注入 EnemyDef.iconPath，不动。

### C. 战场布局（`battle_screen.dart`）
- 删 `_LogSidebar`（220px）→ 战场 `_BattleField` 占满宽（沿用我方左列 / 敌方右列各 3 行 spaceEvenly，放大单位）。
- 朝向：我方略朝右、敌方略朝左镜像，强化对峙（可用 Transform / 现有 isLeftTeam 参数）。

### D. 弹道 / 受击表现（新增，纯 Flutter）
- 复用已有扑击位移 + 飘字 + 暴击屏震。
- **弹道线**：攻击命中时一条攻击者→目标的水墨笔触短动画（CustomPainter + AnimationController，普攻细 / 大招粗+流派色）。由 `_playAction` 在 actionLog 边沿触发，与现有动画同源。
- **受击闪**：目标命中瞬间白闪 / 暴击绛红闪（~0.15s ColorFilter 或 overlay）。

### E. 日志折叠抽屉（`battle_screen.dart`）
- 顶栏 `_Header` 加「日志」图标按钮 → 点开从侧边滑出**半透明覆盖层**（现有 ListView 历史搬进去）→ 再点收起。默认收起。
- 实时反馈靠单位飘字/动画/弹道，不靠侧栏。

### F. 胜负遮罩不压暗（`victory_overlay.dart`）
- 现整屏压暗 → 改**四周暗角 vignette + 中央「胜/败」题字**，战场单位仍清晰（指导 battle_victory 验收）。保留现有金「胜」/绛红「败」+ 印章语义。

## 4. 涉及文件

- `lib/features/battle/presentation/character_avatar.dart`（放大 + 死亡置灰）
- `lib/features/battle/domain/battle_state.dart`（:286 portraitPath 接线）
- `lib/features/battle/presentation/battle_screen.dart`（删侧栏 + 日志抽屉 + 弹道/受击触发 + 战场占满宽）
- 新增 `lib/features/battle/presentation/projectile_trail.dart`（弹道 CustomPainter）
- `lib/features/battle/presentation/victory_overlay.dart`（vignette 不压暗）
- 可能 `numbers.yaml`（弹道/受击/avatarSize 时长尺寸外置，沿 AnimationNumbers 体例，不硬编码）

## 5. 测试

widget test（注意 `setSurfaceSize` 扩 viewport · memory feedback_listview_widget_test_viewport）：
1. 玩家 portraitPath 接线：有立绘 → Image；无立绘 → 首字。
2. `avatarSize` 默认 150。
3. 日志默认收起（无 ListView 历史在树）；点按钮 → 历史可见；再点 → 收起。
4. 死亡单位 isAlive=false → 置灰/降透明 widget 在场。
5. 胜负遮罩显示后战场单位仍在 widget 树可见（非全压暗）。
6. 弹道/受击：actionLog 边沿触发动画，**不写入 BattleState**（战斗 wiring 维度 · memory feedback_strategy_immutable_vs_ui_tick）。

baseline 1677 测；预计 +6~10 测。`flutter analyze` 0。

## 6. 截图验收（Codex@Pen Windows 实机）

- `07_battle_running.png`：六单位可辨 + 弹道线。
- `battle_skill.png`：大招弹道 + 题字 overlay。
- `08_battle_result.png`：胜利遮罩后战场单位仍可读。

## 7. 不做（守边界）

- 全身动作美术 / 逐帧动作动画（P1/P2 换槽）。
- 不引 Flame；不改战斗逻辑（纯表现层）；不动文案三目录；不突破 §5.4 数值红线（本批无数值改）。

## 8. 风险

- 战斗屏跨组件改（删侧栏 + 抽屉 + 弹道）较大 → xhigh + TDD。
- BattleState immutable vs UI tick：弹道/受击必须走 ref.listen 边沿，不污染 state。
- 删 _LogSidebar 可能波及现有 battle 屏 widget test（断言侧栏文案的需改）→ Phase 0 grep 现有断言。
- avatarSize 放大可能触发布局溢出 → 1280×720 实测 + widget test viewport。
