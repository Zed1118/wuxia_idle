# 战报失败诊断系统 — 设计 spec

> 2026-06-15 · 1.0 长线打磨期 · 可玩性二期 backlog「战报诊断规则（§11.4）」打磨项
> 上游 master spec：`docs/spec/playability_upgrade_master_spec_2026-06-09.md` §7.2 失败复盘 + §11.4 战报诊断规则
> backlog 指针：`docs/spec/playability_phase2_backlog.md` 一 · §11.4 行
> 用户拍板：全 5 类规则 / 增强现有败北 overlay / team 不做跳转按钮 / 内伤·前排启发式口径可接受 / 跳转叠 overlay 不打断「继续」

---

## 0 · 目标与范围

战斗失败后，把当前**单条硬编码提示**（`UiStrings.battleDefeatHintInterrupt`）升级为 master spec §7.2 的**三段式失败复盘**：

```
1 个主要原因
+ 2 条关键数据
+ 最多 2 条调整建议（带界面跳转）
```

诊断规则 data 驱动、优先级有序、首条命中即止（沿用 §11.4 `priority` 语义）。全 5 类失败原因（§7.2 表）：蓄力斩杀 / 内伤拖死 / 小怪围殴 / 前排太脆 / 输出超时 + generic 兜底。

**非目标**：胜利英雄镜头、珍稀掉落展示（§7.1，另 backlog）；队伍编制 screen（无独立路由，team 建议只显文案）；离线/自动战斗的诊断弹窗（仅手动战斗败北弹）。**0 改伤害公式 / 红线**。

---

## 1 · 架构

镜像现有 `BattleStatsSummary.from(BattleState)`（`lib/features/battle/domain/battle_stats.dart`）的纯函数派生模式。

新建 `lib/features/battle/domain/battle_diagnosis.dart`（纯 Dart，无 Flutter 依赖）：

```dart
/// 一条调整建议（文案 + 可选跳转目标）。
enum DiagnosisJumpTarget { skills, equipment, cultivation } // team 不做按钮

class DiagnosisSuggestion {
  final String text;                  // 建议文案（UiStrings）
  final DiagnosisJumpTarget? jump;    // null = 只显文案不给按钮
}

/// 一场败北的诊断结果（三段式）。
class BattleDiagnosis {
  final String ruleId;                // 'killed_by_charge' | ... | 'generic'
  final String primaryCause;          // 1 主因（UiStrings）
  final List<String> dataLines;       // 2 关键数据（已填充数值的 UiStrings 模板）
  final List<DiagnosisSuggestion> suggestions; // 最多 2 条

  /// 仅败北（rightWin / draw）返回非 null；胜利返回 null。
  /// 规则按 priority 高→低逐条试，首条命中即返回；全不中走 generic。
  static BattleDiagnosis? from(BattleState state, BattleReportConfig config);
}
```

`BattleReportConfig` = numbers.yaml `battle_report` 段加载产物（阈值），随 `NumbersConfig` 一起注入（现有 `numbersConfigProvider`）。

**派生量**（`from` 内部一次算好，供各规则复用）：

- 玩家方 = `leftTeam`（teamSide 0），敌方 = `rightTeam`。
- `enemyHits` = `actionLog` 中 `actor ∈ rightTeam && target ∈ leftTeam && attackResult != null && finalDamage > 0` 的动作。
- `playerDamageTaken` = `enemyHits` 的 `finalDamage` 求和。
- `bossDamage` / `minionDamage` = 按施招者 `isBoss` 分桶求和（`bossDamage + minionDamage == playerDamageTaken`）。
- `lastLethalHit` = `enemyHits` 中**最后一条**（致命一击启发式 = 败北前最后一次对玩家的有效伤害）。
- `internalWoundDamage` = `enemyHits` 中 `attackResult.appliedEffects` 含 `internal_injury` 标记动作的伤害 + 终态有玩家 `internalInjury != null && !isAlive`。
  > 内伤 tick 不一定是独立 `BattleAction`，故口径取「敌方阴柔克制命中（appliedEffects 含 internal_injury）造成的伤害」+「带内伤 debuff 阵亡」两路或判定，非逐 tick 精确归因（启发式，文档说明）。
- `firstPlayerDeath` = `leftTeam` 中阵亡者里 `actionLog` 出现「该角色 currentHp→0」最早的；slotIndex / 死亡 tick 用于前排判定。
  > 死亡时刻启发式：取 `actionLog` 中**最后一条以该玩家为 target 且使其 isAlive 转 false 的动作的 tick**。实现时按 target 分组、取该 target 承受的最后致死动作 tick；若无法精确定位则取该角色在终态 `!isAlive` 且回合占比由 `lastLethalHit.tick / state.tick` 近似。

---

## 2 · 5 条规则（优先级高→低，首条命中即止）

阈值全部进 numbers.yaml `battle_report`，无硬编码常量。priority 决定试探顺序。

### 2.1 `killed_by_charge`（priority 100）

- **条件**：`lastLethalHit != null && lastLethalHit.skill?.id == 施招者(BattleCharacter).chargeSkillId`
  （致命一击是 Boss 招牌蓄力技收尾）。
- **主因**：被 Boss 蓄力大招击溃。
- **数据**：① 致命一击：`{招名} {伤害}`　② 内力余量：`{剩余}/{上限}`（玩家方主控角色终态内力，提示「本可留力破招」）。
- **建议**：装配破招技、看准蓄力时机破招 → jump `skills`。

### 2.2 `killed_by_internal_wound`（priority 90）

- **条件**：`playerDamageTaken > 0 && internalWoundDamage / playerDamageTaken >= internal_wound_pct`
  **或** 终态有玩家 `internalInjury != null && !isAlive`。
- **主因**：被内伤层层拖垮。
- **数据**：① 内伤占比：`{n}%`　② 受到总伤：`{playerDamageTaken}`。
- **建议**：速杀 / 抗性心法 / 回复 → jump `cultivation`。

### 2.3 `mob_overrun`（priority 80，§11.4 原条）

- **条件**：`rightTeam 存活+阵亡总人数 > 1 && playerDamageTaken > 0 && minionDamage / playerDamageTaken >= minion_damage_pct`(0.35)。
- **主因**：被群敌围殴拖死。
- **数据**：① 小怪伤害占比：`{n}%`　② 受到总伤：`{playerDamageTaken}`。
- **建议**：装配群体技、优先清场 → jump `skills`。

### 2.4 `frontline_fragile`（priority 60）

- **条件**：`firstPlayerDeath != null && firstPlayerDeath.slotIndex == 0 && (deathTick / state.tick) <= frontline_death_phase_pct`(0.5)
  （前排角色死在战斗前半程）。
- **主因**：前排太脆，过早倒下。
- **数据**：① 前排 `{名}` 在第 `{tick}` 回合倒下　② 其最大血量：`{maxHp}`。
- **建议**：强化护具、虚弱/回复保前排 → jump `equipment`。

### 2.5 `dps_too_low`（priority 40，超时/输出兜底）

- **条件**：`state.result == BattleResult.draw`（回合上限 1000 耗尽）
  **或** `rightTeam 存活者平均 currentHp/maxHp >= survivor_hp_pct`(0.5)（打不动）。
- **主因**：输出不足，未能速决。
- **数据**：① 总回合：`{state.tick}`　② 敌方残血：存活者平均 HP `{n}%`。
- **建议**：提升技能熟练度、使用破防技 → jump `skills`。

### 2.6 `generic`（兜底，无 priority）

- 上述全不命中时返回。
- **主因**：惜败，调整战术后再战。
- **数据**：① 总伤害：`{BattleStatsSummary.totalDamage}`　② 总回合：`{state.tick}`。
- **建议**：检视技能装配 → jump `skills`。

---

## 3 · 数据与文案落点（守 §5.6）

### 3.1 numbers.yaml 新增段

`data/numbers.yaml` 顶层加 `battle_report:`（建议紧邻 `passive_idle` / `mass_battle` 一带，战斗相关）：

```yaml
battle_report:
  # 失败复盘诊断规则阈值（spec 2026-06-15-battle-report-diagnosis）。
  # 规则 id / priority 写死在 battle_diagnosis.dart（代码顺序即优先级），
  # 此处只承载可调阈值。文案在 UiStrings（§5.6 文案不进 yaml）。
  internal_wound_pct: 0.30          # 内伤占受伤总伤 ≥ 此比例 → killed_by_internal_wound
  minion_damage_pct: 0.35           # 小怪伤害占比 ≥ 此比例 → mob_overrun（§11.4 原值）
  frontline_death_phase_pct: 0.5    # 前排死亡 tick 占总回合 ≤ 此比例 → frontline_fragile
  survivor_hp_pct: 0.5              # 敌方存活者平均 HP ≥ 此比例 → dps_too_low
```

- loader：`NumbersConfig` 解析时填 `BattleReportConfig`（4 个 double 字段）。沿现有 numbers loader 体例。
- schema：纳入 numbers schema 校验（4 字段必填、范围 (0,1]）。
- 不配置而不消费的字段一律不留（memory `feedback_yaml_config_unused_field`）。

### 3.2 UiStrings 文案

`lib/shared/strings.dart` 新增（全中文文案归此，不进 yaml）：

- 5 主因 + generic 主因（6 条）
- 数据行模板（带占位：`internalWoundRatio(int pct)`、`minionRatio(int pct)`、`lethalHit(String skill, int dmg)`、`internalForceLeft(int cur, int max)` 等函数式 string）
- 建议文案（每规则 1 条）+ 跳转按钮 label（`查看技能装配` / `查看装备` / `查看心法`）
- **退役** `battleDefeatHintInterrupt`（并入 `killed_by_charge` 建议；grep 确认仅 `victory_overlay.dart` 1 处引用，安全删）。

---

## 4 · UI（增强 `VictoryOverlay` 败北路径，不新建 screen）

### 4.1 `victory_overlay.dart`

- 加可选入参 `final BattleDiagnosis? diagnosis;`（胜利时为 null）。
- 败北分支（`if (!_isVictory)`）：把当前单条硬编码 `Text(battleDefeatHintInterrupt)` 块替换为**诊断块**：
  - 主因标题（绛红 accent，略大）
  - 2 条数据行（墨色小字，行距 1.4，复用现有体例）
  - 最多 2 个跳转按钮（水墨描边 `OutlinedButton` 风格 / `WuxiaUi` token；`jump == null` 的建议只渲染文案不给按钮）
- 跳转按钮回调走新增 `final void Function(DiagnosisJumpTarget target)? onJump;`（overlay 不直接持 Navigator，保持纯展示 widget 体例）。
- 胜利路径完全不变。

### 4.2 `battle_screen.dart`

- `_showResultDialog` 中：败北时 `final diagnosis = BattleDiagnosis.from(s, ref.read(numbersConfigProvider).battleReport);`，传入 `VictoryOverlay(diagnosis: diagnosis, onJump: _handleDiagnosisJump)`。
- `_handleDiagnosisJump(target)`：`Navigator.push` 对应 screen（叠在 overlay 上，返回后玩家仍可按「继续」）：
  - `skills` → `CangJingGeScreen`
  - `equipment` → `InventoryScreen`
  - `cultivation` → `TechniquePanelScreen`
  - 构造参数（如需 characterId）在 plan 阶段对齐各 screen 签名；优先用玩家主控角色 id。
- 胜利且 `deferVictoryToCaller` 分支不受影响（不弹 overlay）。

### 4.3 `visual_route_host.dart`

- 现有 VictoryOverlay 预览补一个**败北诊断态**样例（构造一条 `killed_by_charge` 诊断 fixture），方便 Codex 视觉验收三段式排版（主因/数据/按钮）。

---

## 5 · 测试

- **`test/features/battle/battle_diagnosis_test.dart`**（纯 `test()`，无 widget，避免 Isar 死锁）：
  - 5 类败北终态 fixture，逐条断言命中正确 ruleId。
  - 优先级顺序：构造同时满足 charge + mob 的终态，断言返回 charge（高优先）。
  - 胜利（leftWin）返回 null。
  - generic 兜底：构造不满足任何具体规则的败北。
  - 阈值边界：`minionDamage` 恰好 0.35 命中 / 0.34 不命中。
- **`test/features/battle/victory_overlay_diagnosis_test.dart`**（widget 测）：
  - 传入各诊断，断言渲染主因 / 2 数据行 / 按钮数（含 `jump==null` 不渲按钮）。
  - 胜利态不显诊断块。
  - ListView/viewport：按需 `setSurfaceSize` 扩高（memory `feedback_listview_widget_test_viewport`）。
- **回归**：全量 test + analyze 0。0 改伤害公式，红线测自动不受影响（无需新红线测）。

---

## 6 · 实施顺序（plan 细化）

1. numbers.yaml `battle_report` 段 + `BattleReportConfig` loader + schema 校验（TDD：loader 测）。
2. `BattleDiagnosis` + `battle_diagnosis.dart` 纯函数 + 5 规则（TDD：diagnosis 测先行）。
3. UiStrings 文案 + 退役 `battleDefeatHintInterrupt`。
4. `VictoryOverlay` 诊断块 UI + widget 测。
5. `battle_screen` wiring + 跳转 + `visual_route_host` 预览样例。
6. 全量回归 + analyze。

---

## 7 · 风险与取舍

- **致命一击 / 死亡时刻启发式**：`actionLog` 未必逐 tick 记 HP，故「致命一击」取末条有效伤害、「死亡 tick」取致死动作 tick 近似。诊断是引导性提示非硬机制，启发式误差可接受（用户已拍板）。
- **内伤归因**：取 appliedEffects 标记 + 带 debuff 阵亡两路或判定，非逐 tick 精确。
- **team 跳转缺口**：无独立队伍 screen，涉及 team 的建议只显文案不给按钮（用户拍板）；本 spec 5 规则跳转只用 skills/equipment/cultivation，不触发该缺口。
- **draw 语义**：`maxTicks=1000` 耗尽 = draw = 超时信号，直接喂 `dps_too_low`。
