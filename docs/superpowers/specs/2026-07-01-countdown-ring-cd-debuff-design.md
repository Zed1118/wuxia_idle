# 技能CD与debuff读秒圆环 — 设计

**日期**: 2026-07-01
**分支**: 待开 worktree（feat/countdown-ring）
**状态**: 设计稿，待实装
**类型**: 战斗表现层（零碰数值/结算/saveVer/schema）
**升档**: xhigh（battle_screen 上新增动画节拍控制器 + 与 tick/暂停同步 + 4 处接线，用户拍板升档）

## 1. 背景与动机

真玩反馈：技能 CD 现为文字「冷却 N」、破绽为绛红脉动无数字、蓄力为顶部文字条，都不够直观。用户要把 **技能 CD** 与 **debuff 状态** 做成「方块内/头像上圆环转圈读秒 + 中心剩余数字」。战斗一拍 `action_interval_ms=1000ms`，正常速下一回合≈1 秒，圆环平滑扫天然像时钟秒针。

## 2. 现状（file:line，实装前已核）

- **战斗节拍**：`battle_screen.dart:401` `_playTimer = Timer.periodic(actionIntervalMs)`；`_isPaused` gate 在 `_startTimer`（L387）；待发软暂停复用 `_isPaused`（L908/`_clearPending` L926）。
- **State**：`_BattleScreenState with TickerProviderStateMixin`（L231），已多个 `AnimationController`。
- **CD**：`character.skillCooldowns[skill.id]`（剩余回合，`battle_screen.dart:969`）；total = `skill.cooldownTurns`。渲染点 `_SkillCommandButton`（L2444，现显 `UiStrings.skillCooldownShort`）。
- **蓄力**：`enemy.chargeTicksRemaining`（battle_state.dart:192）；total = `chargeMaxTicks` = `numbers.combat.bossCharge.defaultChargeTicks`（已传入 `_CharacterSlot` L1253/1870）。
- **破绽**：`character.staggerTicksRemaining`（battle_state.dart:195）；开窗时长 = `numbers.combat.defenseBreak.windowTicks`（default_ground_strategy.dart:736）。现为 `_GlowAura` 绛红脉动（L2884）。
- **内伤**：`character.internalInjury`（`InternalInjurySlot{remainingTurns, damagePerTick}`，battle_state.dart:602）；**slot 不存初始 total**；初始 N 来自 `numbers.combat.yin_rou_internal_injury`（N=3，实装确认 key）；按守方自己出手减 1（不规则节奏）。

## 3. 设计

### 3.1 核心组件（可独立测，不知战斗）

- **`CountdownRing`**（StatelessWidget + CustomPainter）：入参 `remaining`(double)/`total`(int)/`color`/`trackColor`/`size`/`strokeWidth`。画：淡墨底 track 整圆 + 剩余比例 `remaining/total` 扫弧（12 点起顺时针消退）+ 中心数字 `remaining.ceil()`。纯绘制，不含动画逻辑。
- **`_SteppedCountdownRing`**（内伤专用小 StatefulWidget）：不接节拍，在 `remainingTurns` 变化时 ~250ms 短过渡扫一段（跳变款），复用同一 `CountdownRing`。

### 3.2 节拍驱动（方案 A · 共享控制器）

`_BattleScreenState` 加 `_beatCtrl`（`AnimationController`，period = 当前 `actionIntervalMs`，`repeat()`）：
- 随 `_startTimer` 起转；`_isPaused` / 待发 / 暂停 / 战斗结束 → `stop()`，冻结当前扫位。
- 速度设置 / 快进（`_isFastForward`）改变实际 interval → 同步 `_beatCtrl.duration`，环扫随节奏自洽。
- 向下暴露 `Animation<double> beat`（本拍内 0→1）。
- **eager-init（非 late 懒初始化）+ 正确 dispose**，守 `_GlowAura` TickerMode 崩溃教训（memory `reference_riverpod_tickermode_pause_assert`）。

### 3.3 各状态接线

| 状态 | 剩余字段 | total | 递减节奏 | 驱动 |
|---|---|---|---|---|
| 技能 CD | `skillCooldowns[skill.id]` | `skill.cooldownTurns` | 每全局拍 | `AnimatedBuilder(beat)` 插值 `整数剩余 − beat.value` |
| 敌蓄力 | `chargeTicksRemaining` | `chargeMaxTicks` | 每全局拍 | 同上 |
| 破绽 | `staggerTicksRemaining` | `defenseBreak.windowTicks` | 每全局拍 | 同上 |
| 内伤/余毒 | `internalInjury.remainingTurns` | config N（缺则 max-seen 回退） | 守方自己出手（不规则） | `_SteppedCountdownRing` 值变过渡 |

> total 一律优先 config；破绽/内伤额外用「激活期见过的最大剩余」作分母兜底（纯表现层记忆，状态清零复位），应对破招二次开窗 / 内伤同源刷新（`remainingTurns` 重置为 N）。

### 3.4 配色（WuxiaColors · 水墨克制）

- CD：淡金 `lingQiao #D4A12C` 弧 + 墨 track `barTrack #3A3A3A`（中性等待）。
- 内伤/余毒：`statDecrease #C27A70`（暗绛红 · 负面）。
- 敌蓄力：`hpLow #B22222`（危险 telegraph，呼应顶部蓄力危险条）。
- 破绽：暖金（机会），叠在现有绛红脉动 rim glow 上（glow 外发光 / ring 描边弧，不打架）。破绽暖金 vs 危险绛红的区分为方向判断，属像素级，实装后截图复核，不满意换绛红。

### 3.5 位置

- **CD**：技能按钮方块内——进 CD 态招名压暗、中心浮现大读秒环 + 数字（主信息=还剩几拍）；CD 完环消失、招名恢复亮；ready 态无环。
- **内伤 / 蓄力 / 破绽**：角色 / 敌头像**右上角小徽章环**（避开 rim 的破绽 glow / hover 强光）。顶部蓄力危险条保留（全局最紧迫敌，与局部环互补）。

## 4. 红线 / 不变性

纯交互表现层，**零碰** numbers.yaml / 结算 / saveVer / schema / 三系锁死 / 在线=离线。只读 state 既有字段，不改 tick 逻辑、不改 CD/charge/stagger/injury 任何递减或数值。中心为纯数字无单位（不散写中文；若加「拍/秒」单位走 `UiStrings`，倾向不加）。性能：环包 `RepaintBoundary`，单一 beat 控制器（非 N 个 timer），每帧仅重绘小环区。

## 5. 范围

### 5.1 In scope
- 新建 `CountdownRing` + `_SteppedCountdownRing`（表现层组件）。
- `_beatCtrl` 节拍驱动 + 暂停/速度/结束同步。
- 4 处接线：技能按钮 CD / 敌蓄力 / 破绽 / 内伤。
- 配色 token 取 `WuxiaColors`；如需单位文案走 `UiStrings`。
- 测试：`CountdownRing` 数字+存在性、beat 同步（tick 递减 / 暂停冻结）、4 wire 点各显环。

### 5.2 Out of scope（YAGNI）
- 不改任何战斗数值 / 结算 / tick 递减逻辑。
- 不做 golden 测（跨平台易碎，守 `feedback_flutter_ci_local_green_red`），改数字断言。
- 不做「一个头像同时多状态」的多环嵌套：一头像按优先级（破绽 > 蓄力 > 内伤）显单环，多环留后议。
- 不改顶部蓄力危险条 / 现有破绽绛红脉动（叠加不替换）。

## 6. 测试

- `CountdownRing`：给定 remaining/total → 断言中心数字文本（'3'/'2'）+ 存在性。
- beat 同步：pump 战斗，tick 推进 → 环数字随 cd 递减；pause/待发 → 数字冻结不变。
- wire 点：CD 态显环 / ready 无环、敌蓄力显环、破绽显环、内伤显环（widget test，viewport 守 `feedback_listview_widget_test_viewport`）。
- 全量 `flutter test --no-pub -j1` 绿 + `flutter analyze lib/ test/` 0。

## 7. 组件隔离

`CountdownRing`(纯 paint) ← `_SteppedCountdownRing`(内伤) / `AnimatedBuilder(beat)`(三个每拍状态) 各自组合数据字段喂比例；beat driver 只在 State 经 `Animation` 下传。四个 wire 点互不知内部，可独立改。

## 8. 决策记录

| 决策点 | 选定 | 出处 |
|---|---|---|
| 读秒动画 | 平滑连续扫（像秒针） | 用户 2026-07-01 |
| debuff 范围 | 内伤 + 敌蓄力 + 破绽 全做 | 用户多选 |
| 中心数字 | 显剩余数字 3→2→1 | 用户 |
| 内伤不规则节奏 | 值变短过渡（非匀速扫），用户同意 | 用户 |
| 驱动方式 | 方案 A 共享节拍控制器 | 设计推荐 · 用户认可 |
| 升档 | xhigh | 用户拍板 |

## 9. 风险

- 破绽/内伤 total 若 config 取不到 → max-seen 回退兜底（已设计）。
- `_beatCtrl` 与 `_playTimer` 双计时器相位：以 `_startTimer`/`_isPaused` 为唯一 gate 同步起停，避免漂移；实装加暂停冻结 widget 测锚定。
- 破绽暖金 vs 绛红的观感 → 实装后真机截图复核（属像素级方向）。
