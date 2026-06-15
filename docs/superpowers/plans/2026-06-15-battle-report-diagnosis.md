# 战报失败诊断系统 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 把战斗败北的单条硬编码提示升级为 §7.2 三段式失败复盘（1 主因 + 2 数据 + ≤2 跳转建议），由 §11.4 风格的 data 驱动诊断规则（全 5 类）产出。

**Architecture:** 纯函数 `BattleDiagnosis.from(BattleState, BattleReportConfig)` 镜像现有 `BattleStatsSummary.from`，按 priority 高→低逐条试 5 规则、首条命中即止、胜利返回 null；阈值进 numbers.yaml `battle_report` 段；文案进 UiStrings；UI 增强现有 `VictoryOverlay` 败北路径，不新建 screen；跳转按钮叠 overlay 走 `Navigator.push`，不打断「继续」。

**Tech Stack:** Flutter Desktop / Dart 纯函数 / Riverpod（numbersConfigProvider）/ Isar 无关 / flutter_test。

> 上游 spec：`docs/superpowers/specs/2026-06-15-battle-report-diagnosis-design.md`
> **环境前置（fresh worktree）**：本 worktree 缺所有 `.g.dart`（gitignored）。执行第一个测试前先在 worktree 跑 `dart run build_runner build --delete-conflicting-outputs`，否则 analyze/test 报 ~1484 假 error（memory feedback_wuxia_pen_build_runner）。若 `setUpAll` dlopen libisar 失败，从主仓拷 `libisar.dylib`（memory feedback_fresh_worktree_libisar_dylib）。

---

## 文件结构

| 文件 | 责任 | 动作 |
|---|---|---|
| `data/numbers.yaml` | `battle_report` 阈值段 | Modify（加段） |
| `lib/data/numbers_config.dart` | `BattleReportConfig` + `NumbersConfig.battleReport` 字段 + fromYaml wire | Modify |
| `lib/features/battle/domain/battle_diagnosis.dart` | `BattleDiagnosis` / `DiagnosisSuggestion` / `DiagnosisJumpTarget` + 纯函数 `from` + 5 规则 | Create |
| `lib/shared/strings.dart` | 诊断主因/数据行/建议/按钮文案 + 退役 `battleDefeatHintInterrupt` | Modify |
| `lib/features/battle/presentation/victory_overlay.dart` | 败北诊断块 UI + `diagnosis`/`onJump` 入参 | Modify |
| `lib/features/battle/presentation/battle_screen.dart` | 算诊断 + 传入 + `_handleDiagnosisJump` 导航 | Modify |
| `lib/features/debug/presentation/visual_route_host.dart` | VictoryOverlay 败北诊断态预览样例 | Modify |
| `test/data/battle_report_config_test.dart` | config 解析 + 校验测 | Create |
| `test/features/battle/battle_diagnosis_test.dart` | 5 规则 + 优先级 + null + generic + 边界 | Create |
| `test/features/battle/victory_overlay_diagnosis_test.dart` | 诊断块渲染 widget 测 | Create |

---

## Task 1: BattleReportConfig（numbers.yaml 段 + loader + 校验）

**Files:**
- Modify: `data/numbers.yaml`（顶层加 `battle_report:`，紧邻 `passive_idle` 后）
- Modify: `lib/data/numbers_config.dart`（新 class + 字段 + fromYaml wire）
- Test: `test/data/battle_report_config_test.dart`

- [ ] **Step 1: 写失败测试**

Create `test/data/battle_report_config_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/numbers_config.dart';

void main() {
  test('BattleReportConfig.fromYaml 解析 4 阈值', () {
    final cfg = BattleReportConfig.fromYaml(const {
      'internal_wound_pct': 0.30,
      'minion_damage_pct': 0.35,
      'frontline_death_phase_pct': 0.5,
      'survivor_hp_pct': 0.5,
    });
    expect(cfg.internalWoundPct, 0.30);
    expect(cfg.minionDamagePct, 0.35);
    expect(cfg.frontlineDeathPhasePct, 0.5);
    expect(cfg.survivorHpPct, 0.5);
  });

  test('BattleReportConfig.fromYaml 越界(>1 或 <=0)抛错', () {
    expect(
      () => BattleReportConfig.fromYaml(const {
        'internal_wound_pct': 1.5,
        'minion_damage_pct': 0.35,
        'frontline_death_phase_pct': 0.5,
        'survivor_hp_pct': 0.5,
      }),
      throwsArgumentError,
    );
    expect(
      () => BattleReportConfig.fromYaml(const {
        'internal_wound_pct': 0.30,
        'minion_damage_pct': 0.0,
        'frontline_death_phase_pct': 0.5,
        'survivor_hp_pct': 0.5,
      }),
      throwsArgumentError,
    );
  });
}
```

- [ ] **Step 2: 跑测试确认失败**

Run: `flutter test test/data/battle_report_config_test.dart`
Expected: FAIL（`BattleReportConfig` 未定义，编译错误）

- [ ] **Step 3: 实装 config class**

在 `lib/data/numbers_config.dart` 末尾（`PassiveIdleConfig` class 之后）加：

```dart
/// 战报失败诊断阈值（spec 2026-06-15-battle-report-diagnosis）。
/// 规则 id/priority 写死在 battle_diagnosis.dart；此处只承载可调阈值。
class BattleReportConfig {
  final double internalWoundPct;
  final double minionDamagePct;
  final double frontlineDeathPhasePct;
  final double survivorHpPct;

  const BattleReportConfig({
    required this.internalWoundPct,
    required this.minionDamagePct,
    required this.frontlineDeathPhasePct,
    required this.survivorHpPct,
  });

  factory BattleReportConfig.fromYaml(Map<String, dynamic> y) {
    double pct(String k) => (y[k] as num).toDouble();
    final iw = pct('internal_wound_pct');
    final md = pct('minion_damage_pct');
    final fd = pct('frontline_death_phase_pct');
    final sv = pct('survivor_hp_pct');
    bool ok(double v) => v > 0 && v <= 1;
    if (!ok(iw) || !ok(md) || !ok(fd) || !ok(sv)) {
      throw ArgumentError('battle_report 阈值须在 (0,1]: $y');
    }
    return BattleReportConfig(
      internalWoundPct: iw,
      minionDamagePct: md,
      frontlineDeathPhasePct: fd,
      survivorHpPct: sv,
    );
  }
}
```

- [ ] **Step 4: wire 进 NumbersConfig**

在 `lib/data/numbers_config.dart`：
1. 字段区（`final PassiveIdleConfig passiveIdle;` 之后，约 211 行附近）加：
```dart
  final BattleReportConfig battleReport;
```
2. 构造函数 required 区（`required this.passiveIdle,` 之后，约 259 行）加：
```dart
    required this.battleReport,
```
3. `fromYaml` 返回区（`passiveIdle: PassiveIdleConfig.fromYaml(...)` 之后，约 394 行）加：
```dart
      battleReport: BattleReportConfig.fromYaml(
        y['battle_report'] as Map<String, dynamic>,
      ),
```

- [ ] **Step 5: 加 yaml 段**

在 `data/numbers.yaml` 的 `passive_idle:` 段（约 1050-1055 行）之后、`festivals:` 之前插入：

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

- [ ] **Step 6: 跑测试 + 全量 numbers loader 回归**

Run: `flutter test test/data/battle_report_config_test.dart test/data/`
Expected: PASS（含其它 numbers_config 测不回归——因 NumbersConfig 加了 required 字段，但所有真实加载走 yaml，fromYaml 已 wire；若有手构 NumbersConfig 的测 fixture 报缺字段，Step 7 处理）

- [ ] **Step 7: 修手构 NumbersConfig fixture（若有）**

Run: `grep -rln "NumbersConfig(" test/ lib/ | grep -v numbers_config.dart`
若有手动 `NumbersConfig(...)` 构造（非 fromYaml），补 `battleReport: const BattleReportConfig(internalWoundPct: 0.30, minionDamagePct: 0.35, frontlineDeathPhasePct: 0.5, survivorHpPct: 0.5),`。多数测走 `NumbersConfig.fromYaml(loadNumbersForTest())`，无需改。

- [ ] **Step 8: Commit**

```bash
git add data/numbers.yaml lib/data/numbers_config.dart test/data/battle_report_config_test.dart
git commit -m "feat: BattleReportConfig 战报诊断阈值段(numbers.yaml + loader + 校验)"
```

---

## Task 2: BattleDiagnosis 纯函数 + 5 规则

**Files:**
- Create: `lib/features/battle/domain/battle_diagnosis.dart`
- Test: `test/features/battle/battle_diagnosis_test.dart`

> 文案此 Task 先用 UiStrings 引用（Task 3 才填实际文字）。为 TDD 闭环，Task 3 的 UiStrings 字段在本 Task 一并建占位（返回固定串），Task 3 再定稿文字。**简化**：本 Task 直接在 strings.dart 建最终文案字段（见 Task 3 代码），diagnosis.dart 引用之；Task 3 仅做退役 `battleDefeatHintInterrupt` + 文字润色。先做 Task 3 的 strings 再做本 Task 亦可——但按下列顺序：本 Task Step 3 会引用 `UiStrings.diag*`，故**先执行 Task 3 Step 3（加 strings 字段）**再回本 Task。已在 Task 3 标注。

- [ ] **Step 1: 写失败测试**

Create `test/features/battle/battle_diagnosis_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/features/battle/domain/battle_state.dart';
import 'package:wuxia_idle/features/battle/domain/damage_calculator.dart';
import 'package:wuxia_idle/features/battle/domain/battle_diagnosis.dart';

const _cfg = BattleReportConfig(
  internalWoundPct: 0.30,
  minionDamagePct: 0.35,
  frontlineDeathPhasePct: 0.5,
  survivorHpPct: 0.5,
);

// 玩家方角色（teamSide 0）。
BattleCharacter _player({
  int id = 1,
  int slot = 0,
  int maxHp = 1000,
  int currentHp = 0,
  bool alive = false,
  int curForce = 200,
  int maxForce = 500,
  InternalInjurySlot? injury,
}) => BattleCharacter(
      characterId: id, name: '玩家$id', realmTier: RealmTier.sanLiu,
      realmLayer: RealmLayer.yuanShu, school: TechniqueSchool.gangMeng,
      maxHp: maxHp, currentHp: currentHp, maxInternalForce: maxForce,
      currentInternalForce: curForce, speed: 100, criticalRate: 0,
      evasionRate: 0, defenseRate: 0.1, totalEquipmentAttack: 0,
      mainCultivationLayer: CultivationLayer.daCheng,
      availableSkills: const [], skillCooldowns: const {},
      activeBuffs: const [], actionPoint: 0, isAlive: alive,
      teamSide: 0, slotIndex: slot, internalInjury: injury,
    );

// 敌方角色（teamSide 1）。
BattleCharacter _enemy({
  int id = 100,
  int slot = 0,
  bool boss = false,
  String? chargeSkillId,
  int currentHp = 1000,
  int maxHp = 1000,
  bool alive = true,
}) => BattleCharacter(
      characterId: id, name: '敌$id', realmTier: RealmTier.sanLiu,
      realmLayer: RealmLayer.yuanShu, school: TechniqueSchool.gangMeng,
      maxHp: maxHp, currentHp: currentHp, maxInternalForce: 500,
      currentInternalForce: 500, speed: 100, criticalRate: 0,
      evasionRate: 0, defenseRate: 0.1, totalEquipmentAttack: 0,
      mainCultivationLayer: CultivationLayer.daCheng,
      availableSkills: const [], skillCooldowns: const {},
      activeBuffs: const [], actionPoint: 0, isAlive: alive,
      teamSide: 1, slotIndex: slot, isBoss: boss, chargeSkillId: chargeSkillId,
    );

AttackResult _hit({
  required int damage,
  List<String> effects = const [],
}) => AttackResult(
      finalDamage: damage, mainDamage: damage, quakeDamage: 0,
      isCritical: false, isDodged: false, schoolCounterMultiplier: 1.0,
      realmDiffAttackerMod: 1.0, realmDiffDefenderMod: 1.0,
      cultivationMultiplier: 1.0, criticalMultiplier: 1.0,
      defenseRate: 0.1, evasionRate: 0, appliedEffects: effects,
      formulaBreakdown: 'stub',
    );

const _chargeSkill = SkillDef(
  id: 'skill_boss_charge', name: 'Boss蓄力技', type: SkillType.ultimate,
  powerMultiplier: 5000,
);
const _normalSkill = SkillDef(
  id: 'skill_normal', name: '普攻', type: SkillType.normalAttack,
  powerMultiplier: 500,
);

BattleState _lost({
  required List<BattleCharacter> left,
  required List<BattleCharacter> right,
  required List<BattleAction> log,
  BattleResult result = BattleResult.rightWin,
  int tick = 100,
}) => BattleState(
      leftTeam: left, rightTeam: right, tick: tick, result: result,
      actionLog: log, pendingUltimates: const {}, pendingTargets: const {},
    );

void main() {
  test('胜利返回 null', () {
    final s = _lost(
      left: [_player(alive: true, currentHp: 500)],
      right: [_enemy(alive: false, currentHp: 0)],
      log: const [],
      result: BattleResult.leftWin,
    );
    expect(BattleDiagnosis.from(s, _cfg), isNull);
  });

  test('killed_by_charge: 致命一击是 Boss 蓄力技', () {
    final boss = _enemy(boss: true, chargeSkillId: 'skill_boss_charge');
    final s = _lost(
      left: [_player()],
      right: [boss],
      log: [
        BattleAction(tick: 90, actorId: 100, targetId: 1, skill: _normalSkill,
            attackResult: _hit(damage: 300), description: ''),
        BattleAction(tick: 95, actorId: 100, targetId: 1, skill: _chargeSkill,
            attackResult: _hit(damage: 700), description: ''),
      ],
    );
    final d = BattleDiagnosis.from(s, _cfg)!;
    expect(d.ruleId, 'killed_by_charge');
    expect(d.dataLines.length, 2);
    expect(d.suggestions.first.jump, DiagnosisJumpTarget.skills);
  });

  test('mob_overrun: 小怪伤害占比 ≥ 0.35 且敌 >1', () {
    final boss = _enemy(id: 100, boss: true, chargeSkillId: 'skill_x');
    final mob = _enemy(id: 101, boss: false);
    final s = _lost(
      left: [_player()],
      right: [boss, mob],
      log: [
        BattleAction(tick: 10, actorId: 100, targetId: 1, skill: _normalSkill,
            attackResult: _hit(damage: 600), description: ''),
        BattleAction(tick: 20, actorId: 101, targetId: 1, skill: _normalSkill,
            attackResult: _hit(damage: 400), description: ''),
      ],
    );
    final d = BattleDiagnosis.from(s, _cfg)!;
    expect(d.ruleId, 'mob_overrun'); // 400/1000 = 0.40 ≥ 0.35
  });

  test('mob_overrun 边界: 0.34 不命中 → 落 generic', () {
    final boss = _enemy(id: 100, boss: true, chargeSkillId: 'skill_x');
    final mob = _enemy(id: 101, boss: false);
    final s = _lost(
      left: [_player()],
      right: [boss, mob],
      log: [
        BattleAction(tick: 10, actorId: 100, targetId: 1, skill: _normalSkill,
            attackResult: _hit(damage: 660), description: ''),
        BattleAction(tick: 20, actorId: 101, targetId: 1, skill: _normalSkill,
            attackResult: _hit(damage: 340), description: ''),
      ],
    );
    final d = BattleDiagnosis.from(s, _cfg)!;
    // 340/1000=0.34 < 0.35；非 charge/内伤/前排/超时 → generic
    expect(d.ruleId, 'generic');
  });

  test('killed_by_internal_wound: 内伤占比 ≥ 0.30', () {
    final s = _lost(
      left: [_player()],
      right: [_enemy(id: 100, boss: false)],
      log: [
        BattleAction(tick: 10, actorId: 100, targetId: 1, skill: _normalSkill,
            attackResult: _hit(damage: 600), description: ''),
        BattleAction(tick: 20, actorId: 100, targetId: 1, skill: _normalSkill,
            attackResult: _hit(damage: 400, effects: ['internal_injury']),
            description: ''),
      ],
    );
    final d = BattleDiagnosis.from(s, _cfg)!;
    expect(d.ruleId, 'killed_by_internal_wound'); // 400/1000=0.40
    expect(d.suggestions.first.jump, DiagnosisJumpTarget.cultivation);
  });

  test('优先级: charge 高于 mob_overrun', () {
    // 同时满足 charge(致命=蓄力) 与 mob(小怪占比高)，断言取 charge。
    final boss = _enemy(id: 100, boss: true, chargeSkillId: 'skill_boss_charge');
    final mob = _enemy(id: 101, boss: false);
    final s = _lost(
      left: [_player()],
      right: [boss, mob],
      log: [
        BattleAction(tick: 10, actorId: 101, targetId: 1, skill: _normalSkill,
            attackResult: _hit(damage: 500), description: ''),
        BattleAction(tick: 95, actorId: 100, targetId: 1, skill: _chargeSkill,
            attackResult: _hit(damage: 500), description: ''),
      ],
    );
    expect(BattleDiagnosis.from(s, _cfg)!.ruleId, 'killed_by_charge');
  });

  test('frontline_fragile: 前排(slot0)死在前半程', () {
    // slot0 玩家 maxHp 1000，前 50 tick 内累计伤害 ≥ 1000；总 tick 200。
    final s = _lost(
      left: [_player(id: 1, slot: 0, maxHp: 1000), _player(id: 2, slot: 1, alive: true, currentHp: 800, maxHp: 1000)],
      right: [_enemy(id: 100, boss: false)],
      tick: 200,
      log: [
        BattleAction(tick: 20, actorId: 100, targetId: 1, skill: _normalSkill,
            attackResult: _hit(damage: 600), description: ''),
        BattleAction(tick: 40, actorId: 100, targetId: 1, skill: _normalSkill,
            attackResult: _hit(damage: 500), description: ''), // 累计 1100 ≥ 1000 @tick40, 40/200=0.2 ≤ 0.5
      ],
    );
    final d = BattleDiagnosis.from(s, _cfg)!;
    expect(d.ruleId, 'frontline_fragile');
    expect(d.suggestions.first.jump, DiagnosisJumpTarget.equipment);
  });

  test('dps_too_low: draw(超时)', () {
    final s = _lost(
      left: [_player(alive: true, currentHp: 100)],
      right: [_enemy(id: 100, boss: true, currentHp: 900, maxHp: 1000)],
      result: BattleResult.draw,
      tick: 1000,
      log: const [],
    );
    final d = BattleDiagnosis.from(s, _cfg)!;
    expect(d.ruleId, 'dps_too_low');
    expect(d.suggestions.first.jump, DiagnosisJumpTarget.skills);
  });

  test('generic: 无规则命中', () {
    // rightWin，敌方残血低(打得动)、无蓄力致命、无内伤、无小怪、前排没早死。
    final s = _lost(
      left: [_player(id: 1, slot: 0, maxHp: 1000)],
      right: [_enemy(id: 100, boss: true, chargeSkillId: 'skill_x', currentHp: 50, maxHp: 1000)],
      tick: 100,
      log: [
        BattleAction(tick: 90, actorId: 100, targetId: 1, skill: _normalSkill,
            attackResult: _hit(damage: 1000), description: ''), // 死在 90/100=0.9 > 0.5
      ],
    );
    expect(BattleDiagnosis.from(s, _cfg)!.ruleId, 'generic');
  });
}
```

- [ ] **Step 2: 跑测试确认失败**

Run: `flutter test test/features/battle/battle_diagnosis_test.dart`
Expected: FAIL（`BattleDiagnosis` / `DiagnosisJumpTarget` 未定义）

- [ ] **Step 3: 实装 battle_diagnosis.dart**

> 先确保 Task 3 Step 3 的 `UiStrings.diag*` 字段已存在（先做 Task 3 Step 3）。

Create `lib/features/battle/domain/battle_diagnosis.dart`:

```dart
import '../../../data/numbers_config.dart';
import '../../../shared/strings.dart';
import 'battle_state.dart';
import 'battle_stats.dart';

/// 失败复盘建议的跳转目标（team 无独立 screen，不做按钮）。
enum DiagnosisJumpTarget { skills, equipment, cultivation }

/// 一条调整建议（文案 + 可选跳转）。
class DiagnosisSuggestion {
  final String text;
  final DiagnosisJumpTarget? jump;
  const DiagnosisSuggestion(this.text, [this.jump]);
}

/// 一场败北的三段式诊断（spec 2026-06-15-battle-report-diagnosis §7.2）。
/// 1 主因 + 2 关键数据 + ≤2 建议。仅败北（rightWin/draw）返回非 null。
class BattleDiagnosis {
  final String ruleId;
  final String primaryCause;
  final List<String> dataLines;
  final List<DiagnosisSuggestion> suggestions;

  const BattleDiagnosis({
    required this.ruleId,
    required this.primaryCause,
    required this.dataLines,
    required this.suggestions,
  });

  /// 按 priority 高→低逐条试，首条命中即止；全不中走 generic。
  static BattleDiagnosis? from(BattleState state, BattleReportConfig config) {
    final lost = state.result == BattleResult.rightWin ||
        state.result == BattleResult.draw;
    if (!lost) return null;

    final left = state.leftTeam;
    final right = state.rightTeam;
    final enemyIds = {for (final e in right) e.characterId};
    final leftIds = {for (final p in left) p.characterId};
    final bossById = {for (final e in right) e.characterId: e};

    // 敌方对玩家的有效伤害动作（顺序保留）。
    final enemyHits = <BattleAction>[];
    for (final a in state.actionLog) {
      final r = a.attackResult;
      if (r == null || r.finalDamage <= 0) continue;
      if (!enemyIds.contains(a.actorId)) continue;
      if (a.targetId == null || !leftIds.contains(a.targetId)) continue;
      enemyHits.add(a);
    }
    final playerDamageTaken =
        enemyHits.fold<int>(0, (s, a) => s + a.attackResult!.finalDamage);
    final minionDamage = enemyHits
        .where((a) => !(bossById[a.actorId]?.isBoss ?? false))
        .fold<int>(0, (s, a) => s + a.attackResult!.finalDamage);
    final internalWoundDamage = enemyHits
        .where((a) => a.attackResult!.appliedEffects.contains('internal_injury'))
        .fold<int>(0, (s, a) => s + a.attackResult!.finalDamage);
    final lastLethalHit = enemyHits.isEmpty ? null : enemyHits.last;

    // 主控玩家角色（slot 最小的存活/全队首个）。
    final player = left.isEmpty
        ? null
        : left.reduce((a, b) => a.slotIndex <= b.slotIndex ? a : b);

    // 规则 1（priority 100）killed_by_charge
    if (lastLethalHit != null) {
      final attacker = bossById[lastLethalHit.actorId];
      final skillId = lastLethalHit.skill?.id;
      if (attacker != null &&
          attacker.chargeSkillId != null &&
          skillId == attacker.chargeSkillId) {
        return BattleDiagnosis(
          ruleId: 'killed_by_charge',
          primaryCause: UiStrings.diagCauseCharge,
          dataLines: [
            UiStrings.diagLethalHit(
                lastLethalHit.skill?.name ?? '', lastLethalHit.attackResult!.finalDamage),
            UiStrings.diagInternalForceLeft(
                player?.currentInternalForce ?? 0, player?.maxInternalForce ?? 0),
          ],
          suggestions: [
            DiagnosisSuggestion(UiStrings.diagSuggestCharge, DiagnosisJumpTarget.skills),
          ],
        );
      }
    }

    // 规则 2（priority 90）killed_by_internal_wound
    final injuredDeath = left.any((p) => !p.isAlive && p.internalInjury != null);
    if ((playerDamageTaken > 0 &&
            internalWoundDamage / playerDamageTaken >= config.internalWoundPct) ||
        injuredDeath) {
      final pct = playerDamageTaken > 0
          ? (internalWoundDamage / playerDamageTaken * 100).round()
          : 0;
      return BattleDiagnosis(
        ruleId: 'killed_by_internal_wound',
        primaryCause: UiStrings.diagCauseInternalWound,
        dataLines: [
          UiStrings.diagInternalWoundRatio(pct),
          UiStrings.diagDamageTaken(playerDamageTaken),
        ],
        suggestions: [
          DiagnosisSuggestion(UiStrings.diagSuggestInternalWound, DiagnosisJumpTarget.cultivation),
        ],
      );
    }

    // 规则 3（priority 80）mob_overrun
    if (right.length > 1 &&
        playerDamageTaken > 0 &&
        minionDamage / playerDamageTaken >= config.minionDamagePct) {
      final pct = (minionDamage / playerDamageTaken * 100).round();
      return BattleDiagnosis(
        ruleId: 'mob_overrun',
        primaryCause: UiStrings.diagCauseMob,
        dataLines: [
          UiStrings.diagMinionRatio(pct),
          UiStrings.diagDamageTaken(playerDamageTaken),
        ],
        suggestions: [
          DiagnosisSuggestion(UiStrings.diagSuggestMob, DiagnosisJumpTarget.skills),
        ],
      );
    }

    // 规则 4（priority 60）frontline_fragile
    final death = _firstFrontlineDeath(left, enemyHits, state.tick);
    if (death != null &&
        state.tick > 0 &&
        death.deathTick / state.tick <= config.frontlineDeathPhasePct) {
      return BattleDiagnosis(
        ruleId: 'frontline_fragile',
        primaryCause: UiStrings.diagCauseFrontline,
        dataLines: [
          UiStrings.diagFrontlineDeath(death.name, death.deathTick),
          UiStrings.diagFrontlineMaxHp(death.maxHp),
        ],
        suggestions: [
          DiagnosisSuggestion(UiStrings.diagSuggestFrontline, DiagnosisJumpTarget.equipment),
        ],
      );
    }

    // 规则 5（priority 40）dps_too_low
    final survivors = right.where((e) => e.isAlive && e.maxHp > 0).toList();
    final avgHpPct = survivors.isEmpty
        ? 0.0
        : survivors.fold<double>(0, (s, e) => s + e.currentHp / e.maxHp) /
            survivors.length;
    if (state.result == BattleResult.draw || avgHpPct >= config.survivorHpPct) {
      return BattleDiagnosis(
        ruleId: 'dps_too_low',
        primaryCause: UiStrings.diagCauseDps,
        dataLines: [
          UiStrings.diagTotalTicks(state.tick),
          UiStrings.diagSurvivorHp((avgHpPct * 100).round()),
        ],
        suggestions: [
          DiagnosisSuggestion(UiStrings.diagSuggestDps, DiagnosisJumpTarget.skills),
        ],
      );
    }

    // 兜底 generic
    final stats = BattleStatsSummary.from(state);
    return BattleDiagnosis(
      ruleId: 'generic',
      primaryCause: UiStrings.diagCauseGeneric,
      dataLines: [
        UiStrings.diagTotalDamage(stats.totalDamage),
        UiStrings.diagTotalTicks(state.tick),
      ],
      suggestions: [
        DiagnosisSuggestion(UiStrings.diagSuggestGeneric, DiagnosisJumpTarget.skills),
      ],
    );
  }

  /// 前排死亡启发式：累计敌方伤害首次 ≥ maxHp 的 tick = 死亡 tick；
  /// 取 slotIndex 0 且最早死亡者（按 actionLog 顺序累计，maxHp 取战中常量）。
  static _FrontlineDeath? _firstFrontlineDeath(
      List<BattleCharacter> left, List<BattleAction> enemyHits, int totalTick) {
    _FrontlineDeath? best;
    for (final p in left) {
      if (p.isAlive || p.slotIndex != 0) continue;
      var cum = 0;
      int? deathTick;
      for (final a in enemyHits) {
        if (a.targetId != p.characterId) continue;
        cum += a.attackResult!.finalDamage;
        if (cum >= p.maxHp) {
          deathTick = a.tick;
          break;
        }
      }
      deathTick ??= totalTick; // 无法定位则记终局
      if (best == null || deathTick < best.deathTick) {
        best = _FrontlineDeath(p.name, deathTick, p.maxHp);
      }
    }
    return best;
  }
}

class _FrontlineDeath {
  final String name;
  final int deathTick;
  final int maxHp;
  const _FrontlineDeath(this.name, this.deathTick, this.maxHp);
}
```

- [ ] **Step 4: 跑测试确认通过**

Run: `flutter test test/features/battle/battle_diagnosis_test.dart`
Expected: PASS（10 测全绿）

- [ ] **Step 5: Commit**

```bash
git add lib/features/battle/domain/battle_diagnosis.dart test/features/battle/battle_diagnosis_test.dart
git commit -m "feat: BattleDiagnosis 纯函数 + 5 失败诊断规则(§11.4/§7.2)"
```

---

## Task 3: UiStrings 文案 + 退役旧提示

**Files:**
- Modify: `lib/shared/strings.dart`
- Modify: `lib/features/battle/presentation/victory_overlay.dart`（删旧引用，Task 4 重建）

> **执行顺序**：本 Task Step 3（加 strings 字段）需在 Task 2 Step 3 之前完成（diagnosis.dart 引用这些字段）。退役 `battleDefeatHintInterrupt`（Step 4）在 Task 4 重建 UI 时一并处理；本 Task 仅加字段，不删旧字段（避免编译断裂）。

- [ ] **Step 1: 加诊断文案字段**

在 `lib/shared/strings.dart` 的 `battleSummary` 函数（约 77-78 行）之后加：

```dart
  // ── 战报失败诊断（spec 2026-06-15-battle-report-diagnosis）──
  // 主因（1 条）
  static const String diagCauseCharge = '被 Boss 蓄力大招击溃';
  static const String diagCauseInternalWound = '被内伤层层拖垮';
  static const String diagCauseMob = '被群敌围殴拖死';
  static const String diagCauseFrontline = '前排太脆，过早倒下';
  static const String diagCauseDps = '输出不足，未能速决';
  static const String diagCauseGeneric = '惜败，调整战术后再战';

  // 关键数据（2 条/规则）
  static String diagLethalHit(String skill, int dmg) => '致命一击：$skill $dmg';
  static String diagInternalForceLeft(int cur, int max) => '内力余量：$cur/$max';
  static String diagInternalWoundRatio(int pct) => '内伤占比：$pct%';
  static String diagDamageTaken(int dmg) => '受到总伤：$dmg';
  static String diagMinionRatio(int pct) => '小怪伤害占比：$pct%';
  static String diagFrontlineDeath(String name, int tick) => '$name 在第 $tick 回合倒下';
  static String diagFrontlineMaxHp(int hp) => '其最大血量：$hp';
  static String diagTotalTicks(int tick) => '总回合：$tick';
  static String diagSurvivorHp(int pct) => '敌方残血：平均 $pct%';
  static String diagTotalDamage(int dmg) => '总伤害：$dmg';

  // 建议（1 条/规则）
  static const String diagSuggestCharge = '保留内力、装配破招技，看准蓄力时机破招。';
  static const String diagSuggestInternalWound = '速杀或修抗性心法、备回复，化解内伤。';
  static const String diagSuggestMob = '装配群体技，优先清场再攻坚。';
  static const String diagSuggestFrontline = '强化护具、以虚弱/回复护住前排。';
  static const String diagSuggestDps = '提升技能熟练度，使用破防技提速。';
  static const String diagSuggestGeneric = '检视技能装配，调整后再战。';

  // 跳转按钮 label
  static const String diagJumpSkills = '查看技能装配';
  static const String diagJumpEquipment = '查看装备';
  static const String diagJumpCultivation = '查看心法';
```

- [ ] **Step 2: 跑 analyze 确认 strings 编译**

Run: `flutter analyze lib/shared/strings.dart`
Expected: No issues

- [ ] **Step 3: Commit（先落 strings 供 Task 2 引用）**

```bash
git add lib/shared/strings.dart
git commit -m "feat: 战报诊断 UiStrings 文案(6 主因/10 数据/6 建议/3 按钮)"
```

> `battleDefeatHintInterrupt` 退役在 Task 4（UI 重建时删 victory_overlay 引用后再删字段）。

---

## Task 4: VictoryOverlay 诊断块 UI

**Files:**
- Modify: `lib/features/battle/presentation/victory_overlay.dart`
- Test: `test/features/battle/victory_overlay_diagnosis_test.dart`

- [ ] **Step 1: 写失败 widget 测**

Create `test/features/battle/victory_overlay_diagnosis_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/battle/domain/battle_state.dart';
import 'package:wuxia_idle/features/battle/domain/battle_diagnosis.dart';
import 'package:wuxia_idle/features/battle/presentation/victory_overlay.dart';

void main() {
  const diagnosis = BattleDiagnosis(
    ruleId: 'killed_by_charge',
    primaryCause: '被 Boss 蓄力大招击溃',
    dataLines: ['致命一击：蓄力技 700', '内力余量：200/500'],
    suggestions: [
      DiagnosisSuggestion('保留内力、装配破招技。', DiagnosisJumpTarget.skills),
    ],
  );

  Future<void> _pump(WidgetTester t, Widget child) async {
    await t.binding.setSurfaceSize(const Size(800, 1400));
    addTearDown(() => t.binding.setSurfaceSize(null));
    await t.pumpWidget(MaterialApp(home: Scaffold(body: child)));
  }

  testWidgets('败北显诊断主因+数据+按钮', (t) async {
    DiagnosisJumpTarget? jumped;
    await _pump(t, VictoryOverlay(
      result: BattleResult.rightWin,
      totalDamage: 100, critCount: 0, totalTicks: 50,
      diagnosis: diagnosis,
      onJump: (target) => jumped = target,
      onContinue: () {},
    ));
    expect(find.text('被 Boss 蓄力大招击溃'), findsOneWidget);
    expect(find.text('致命一击：蓄力技 700'), findsOneWidget);
    expect(find.text('内力余量：200/500'), findsOneWidget);
    expect(find.text('查看技能装配'), findsOneWidget);
    await t.tap(find.text('查看技能装配'));
    expect(jumped, DiagnosisJumpTarget.skills);
  });

  testWidgets('胜利不显诊断块', (t) async {
    await _pump(t, VictoryOverlay(
      result: BattleResult.leftWin,
      totalDamage: 100, critCount: 0, totalTicks: 50,
      diagnosis: null,
      onContinue: () {},
    ));
    expect(find.text('被 Boss 蓄力大招击溃'), findsNothing);
  });

  testWidgets('jump==null 的建议只显文案不给按钮', (t) async {
    const noJump = BattleDiagnosis(
      ruleId: 'generic', primaryCause: '惜败',
      dataLines: ['总伤害：100', '总回合：50'],
      suggestions: [DiagnosisSuggestion('调整后再战。', null)],
    );
    await _pump(t, VictoryOverlay(
      result: BattleResult.rightWin,
      totalDamage: 100, critCount: 0, totalTicks: 50,
      diagnosis: noJump,
      onContinue: () {},
    ));
    expect(find.text('调整后再战。'), findsOneWidget);
    expect(find.byType(OutlinedButton), findsNothing);
  });
}
```

- [ ] **Step 2: 跑测试确认失败**

Run: `flutter test test/features/battle/victory_overlay_diagnosis_test.dart`
Expected: FAIL（`VictoryOverlay` 无 `diagnosis`/`onJump` 入参）

- [ ] **Step 3: 改 VictoryOverlay 入参 + 诊断块**

在 `lib/features/battle/presentation/victory_overlay.dart`：

1. import 加（顶部 import 区）：
```dart
import '../domain/battle_diagnosis.dart';
```

2. 字段 + 构造（`final VoidCallback onContinue;` 前后）：
```dart
  /// 败北诊断（胜利为 null）。null 时退化为无诊断块（仅题字+统计）。
  final BattleDiagnosis? diagnosis;
  /// 诊断建议跳转回调（overlay 保持纯展示，导航交给 caller）。
  final void Function(DiagnosisJumpTarget target)? onJump;
```
构造函数参数加：
```dart
    this.diagnosis,
    this.onJump,
```

3. 替换败北提示块——把现有（约 122-134 行）：
```dart
                  // P0 破招：败北时附破招提示，引导玩家看准蓄力时机。
                  if (!_isVictory) ...[
                    const SizedBox(height: 8),
                    Text(
                      UiStrings.battleDefeatHintInterrupt,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: WuxiaUi.ink.withValues(alpha: 0.82),
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ],
```
替换为：
```dart
                  // 战报失败诊断三段式（spec 2026-06-15-battle-report-diagnosis）。
                  if (!_isVictory && diagnosis != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      diagnosis!.primaryCause,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: accent,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    for (final line in diagnosis!.dataLines)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 1),
                        child: Text(
                          line,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: WuxiaUi.ink.withValues(alpha: 0.82),
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                      ),
                    const SizedBox(height: 6),
                    for (final s in diagnosis!.suggestions)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: s.jump == null
                            ? Text(
                                s.text,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: WuxiaUi.ink.withValues(alpha: 0.78),
                                  fontSize: 13,
                                  height: 1.4,
                                ),
                              )
                            : OutlinedButton(
                                onPressed: () => onJump?.call(s.jump!),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: accent,
                                  side: BorderSide(
                                    color: accent.withValues(alpha: 0.55),
                                  ),
                                ),
                                child: Text(_jumpLabel(s.jump!)),
                              ),
                      ),
                  ],
```

4. 在 class 内加 jump label 辅助（`build` 方法外，class 内）：
```dart
  static String _jumpLabel(DiagnosisJumpTarget t) => switch (t) {
        DiagnosisJumpTarget.skills => UiStrings.diagJumpSkills,
        DiagnosisJumpTarget.equipment => UiStrings.diagJumpEquipment,
        DiagnosisJumpTarget.cultivation => UiStrings.diagJumpCultivation,
      };
```

- [ ] **Step 4: 退役 battleDefeatHintInterrupt**

Run: `grep -rn "battleDefeatHintInterrupt" lib/ test/`
确认仅 `lib/shared/strings.dart:57` 定义处（victory_overlay 引用已删）。删 strings.dart 定义行：
```dart
  static const String battleDefeatHintInterrupt = '蓄力大招难挡——保留内力,看准蓄力时机破招。';
```

- [ ] **Step 5: 跑测试确认通过**

Run: `flutter test test/features/battle/victory_overlay_diagnosis_test.dart`
Expected: PASS（3 测全绿）

- [ ] **Step 6: Commit**

```bash
git add lib/features/battle/presentation/victory_overlay.dart lib/shared/strings.dart test/features/battle/victory_overlay_diagnosis_test.dart
git commit -m "feat: VictoryOverlay 败北诊断块 UI + 退役单条硬编码提示"
```

---

## Task 5: battle_screen wiring + 跳转导航

**Files:**
- Modify: `lib/features/battle/presentation/battle_screen.dart`

- [ ] **Step 1: import 跳转 screen + diagnosis**

在 `lib/features/battle/presentation/battle_screen.dart` import 区加：
```dart
import '../domain/battle_diagnosis.dart';
import '../../cangjingge/presentation/cangjingge_screen.dart';
import '../../inventory/presentation/inventory_screen.dart';
import '../../technique_panel/presentation/technique_panel_screen.dart';
```
（若已 import 其中某个，跳过重复。）

- [ ] **Step 2: 算诊断 + 传入 VictoryOverlay**

在 `_showResultDialog`（约 798 行）`final stats = BattleStatsSummary.from(s);` 之后加：
```dart
    final diagnosis = result == BattleResult.leftWin
        ? null
        : BattleDiagnosis.from(s, ref.read(numbersConfigProvider).battleReport);
```
在 `VictoryOverlay(` 构造（约 805 行）的 `totalTicks: stats.totalTicks,` 之后加：
```dart
        diagnosis: diagnosis,
        onJump: (target) => _handleDiagnosisJump(s, target),
```

- [ ] **Step 3: 实装 _handleDiagnosisJump**

在 `_BattleScreenState` class 内（`_showResultDialog` 方法之后）加：
```dart
  /// 诊断建议跳转：叠在胜负 overlay 之上 push 目标 screen，
  /// 返回后玩家仍可按「继续」。characterId 取玩家主控角色（slot 最小）。
  void _handleDiagnosisJump(BattleState s, DiagnosisJumpTarget target) {
    final playerId = s.leftTeam.isEmpty
        ? 0
        : s.leftTeam
            .reduce((a, b) => a.slotIndex <= b.slotIndex ? a : b)
            .characterId;
    final Widget screen = switch (target) {
      DiagnosisJumpTarget.skills => CangJingGeScreen(characterId: playerId),
      DiagnosisJumpTarget.equipment => const InventoryScreen(),
      DiagnosisJumpTarget.cultivation =>
        TechniquePanelScreen(characterId: playerId),
    };
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));
  }
```

- [ ] **Step 4: 跑 analyze + 相关测试**

Run: `flutter analyze lib/features/battle/presentation/battle_screen.dart`
Expected: No issues
Run: `flutter test test/features/battle/`
Expected: PASS（含 diagnosis + overlay 测）

- [ ] **Step 5: Commit**

```bash
git add lib/features/battle/presentation/battle_screen.dart
git commit -m "feat: battle_screen 算诊断+传 overlay+跳转导航 wiring"
```

---

## Task 6: visual_route_host 预览 + 全量回归

**Files:**
- Modify: `lib/features/debug/presentation/visual_route_host.dart`

- [ ] **Step 1: 给 VictoryOverlay 预览补败北诊断态**

在 `lib/features/debug/presentation/visual_route_host.dart` 现有 `VictoryOverlay(`（约 877 行）处：若该预览是胜利态，再加一个败北诊断态样例（或把现有改为可切换）。最小做法——在该 VictoryOverlay 构造补 diagnosis 参数（若现有是 rightWin 预览）：
```dart
            diagnosis: const BattleDiagnosis(
              ruleId: 'killed_by_charge',
              primaryCause: '被 Boss 蓄力大招击溃',
              dataLines: ['致命一击：摧心掌 720', '内力余量：180/500'],
              suggestions: [
                DiagnosisSuggestion('保留内力、装配破招技。', DiagnosisJumpTarget.skills),
              ],
            ),
            onJump: (_) {},
```
import 加 `import '../../battle/domain/battle_diagnosis.dart';`（若缺）。

- [ ] **Step 2: analyze 该文件**

Run: `flutter analyze lib/features/debug/presentation/visual_route_host.dart`
Expected: No issues

- [ ] **Step 3: 全量 analyze**

Run: `flutter analyze`
Expected: No issues found（0）

- [ ] **Step 4: 全量测试回归**

Run: `flutter test`
Expected: All tests pass（基线 2231 + 1 skip → 预期 2231 + 新增 ~15 测：Task1 2 + Task2 10 + Task4 3 = 2246 上下，零 fail）

- [ ] **Step 5: Commit**

```bash
git add lib/features/debug/presentation/visual_route_host.dart
git commit -m "feat: visual_route_host 补 VictoryOverlay 败北诊断态预览"
```

---

## Self-Review 结果（plan 作者自检）

- **Spec coverage**：§1 架构 → Task2；§2 五规则 → Task2（逐条测）；§3.1 yaml/config → Task1；§3.2 文案 → Task3；§4.1 overlay → Task4；§4.2 battle_screen → Task5；§4.3 visual_route_host → Task6；§5 测试 → Task1/2/4 测 + Task6 全量。无遗漏。
- **Placeholder scan**：无 TBD/TODO；所有代码步给出完整代码。
- **Type consistency**：`BattleDiagnosis` / `DiagnosisSuggestion(text, [jump])` / `DiagnosisJumpTarget{skills,equipment,cultivation}` / `BattleReportConfig` 字段（internalWoundPct/minionDamagePct/frontlineDeathPhasePct/survivorHpPct）跨 Task 一致；`UiStrings.diag*` 在 Task3 定义、Task2/4 引用，签名一致。
- **执行顺序注意**：Task3 Step1-3（加 strings 字段）须先于 Task2 Step3（diagnosis.dart 引用 UiStrings.diag*）。建议执行序：Task1 → Task3 → Task2 → Task4 → Task5 → Task6。

## 红线与回归守卫

- 0 改伤害公式 / numbers 红线值，无需新红线测。
- 全量 test + analyze 0 为合并闸门（Task6）。
- saveVersion 不变（无 Isar schema 改动）。
