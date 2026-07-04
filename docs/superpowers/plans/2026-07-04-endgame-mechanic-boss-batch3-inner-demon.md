# 终局机制型 Boss 批次3 心魔应用 · Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 让 inner_demon_05/06 心魔镜像带脆弱窗口（削满配秒杀），inner_demon_07 终关加「撑过 N tick 或击败镜像任一即胜」的限时生存胜负条件。

**Architecture:** 两个正交模块。① 复用批次1 已实装的 `BattleCharacter.vulnerabilityMult` + 伤害闸 `vulnerabilityMultOf`，把注入点从 `EnemyDef`（心魔无固定 def）改到 `buildMirrorEnemyTeam` 的镜像 `BattleCharacter`（注入 vulnerabilityMult + chargeSkillId + 蓄力技），开窗靠新注入的心魔蓄力技 CD 复发。② 新 `StageWinCondition`（surviveTicks 型）挂 `StageDef` → 透传进 `BattleState` → strategy 在 `stepOne` tick 边界逐 tick 判定（tick≥N 且左队存活→leftWin），与现有「右队全灭→leftWin」并存。winCondition 默认 null=defeatAll，所有现有战斗零行为变化。

**Tech Stack:** Flutter Desktop / Dart 3 / Isar / Riverpod 3.x / YAML 配置。战斗为纯函数 immutable strategy（`default_ground_strategy.dart`），确定性 seed。测试走 `flutter test --no-pub`。

**关键前提（Phase 0 已核实）：**
- 心魔敌队 = 运行时镜像玩家队（`stage_battle_setup.dart:57` `buildMirrorEnemyTeam`），非 yaml 固定 EnemyDef。
- `BattleCharacter.vulnerabilityMult`（`battle_state.dart:241-243`）+ `vulnerabilityMultOf`（`default_ground_strategy.dart:926-937`）批次1 已实装可复用。
- `BattleState.tick`（:667）在 `stepOne` tick 边界 +1（`default_ground_strategy.dart:90`）；`tick()` 与 notifier `advance()` 都走 `stepOne`。
- `BattleState.initial`（:721）由 `startBattle`（`battle_providers.dart:86`）构造；心魔战斗经 `stage_entry_flow.dart:524/539` 启动。
- 蓄力字段 `chargeSkillId`/`chargingSkill`/`chargeTicksRemaining`（:186-192）+ AI 蓄力触发（`default_ground_strategy.dart:406-429`）批次1/2 已实装。

**红线（每 Task 守）：** 镜像仍 clamp caps（HP≤20000/IF≤15000/攻击≤6000）；蓄力技 powerMultiplier < 全局 ≤8000；vulnerability schema [0.05,1.0] 减伤方向非属性 buff；survive 不改任何伤害数字；守 §5.4 机制型 Boss 例外条款（v1.30 已立）。

**测试节奏：** 纯数据面 Task（1、3）targeted + `flutter analyze`；改核心战斗 Task（2、4、5）批内跑相关 battle 测；Task 6 批末全量。确定性诊断测走 `notifier.advance` + `ProviderContainer` 永久 listener + 固定 seed（memory `battle_determinism_test_via_notifier`），**非** `strategy.tick`。

**环境预热（执行前主窗口已做/实装者确认）：** 本 worktree fresh checkout `.g.dart` gitignored，实装者首个 Task 前须 `flutter pub get` + 从主仓拷 `libisar.dylib` + `dart run build_runner build --delete-conflicting-outputs` + 冒烟 1 个测试文件（memory `subagent_driven_fresh_worktree_env_prep`），否则裸 worktree 0 .g.dart 编译即失败。

---

## Task 1: `StageWinCondition` 数据面 + `StageDef` 字段（纯数据面，不接战斗）

**Files:**
- Create: `lib/data/defs/stage_win_condition.dart`
- Modify: `lib/data/defs/stage_def.dart:14-168`（加字段 + 构造参数 + fromYaml）
- Test: `test/data/defs/stage_win_condition_test.dart`（新建）

- [ ] **Step 1: 写失败测试（StageWinCondition 解析 + 校验）**

`test/data/defs/stage_win_condition_test.dart`：
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/defs/stage_win_condition.dart';

void main() {
  group('StageWinCondition.fromYaml', () {
    test('surviveTicks 型正常解析', () {
      final wc = StageWinCondition.fromYaml({'type': 'surviveTicks', 'ticks': 40});
      expect(wc.type, StageWinConditionType.surviveTicks);
      expect(wc.surviveTicksRequired, 40);
    });

    test('defeatAll 型解析（无 ticks）', () {
      final wc = StageWinCondition.fromYaml({'type': 'defeatAll'});
      expect(wc.type, StageWinConditionType.defeatAll);
      expect(wc.surviveTicksRequired, isNull);
    });

    test('非法 type 启动期抛错', () {
      expect(
        () => StageWinCondition.fromYaml({'type': 'bogus'}),
        throwsA(isA<Object>()),
      );
    });

    test('surviveTicks 缺 ticks 抛错', () {
      expect(
        () => StageWinCondition.fromYaml({'type': 'surviveTicks'}),
        throwsStateError,
      );
    });

    test('surviveTicks ticks<=0 抛错', () {
      expect(
        () => StageWinCondition.fromYaml({'type': 'surviveTicks', 'ticks': 0}),
        throwsStateError,
      );
    });
  });
}
```

- [ ] **Step 2: 跑测试确认失败**

Run: `flutter test --no-pub test/data/defs/stage_win_condition_test.dart`
Expected: FAIL（`stage_win_condition.dart` 不存在 / 编译错误）。

- [ ] **Step 3: 实现 `StageWinCondition`**

`lib/data/defs/stage_win_condition.dart`：
```dart
/// 关卡胜负条件（终局机制型 Boss 批次3）。
///
/// - [StageWinConditionType.defeatAll]（默认）：击败全部敌人即胜（现状语义）。
/// - [StageWinConditionType.surviveTicks]：撑满 [surviveTicksRequired] tick 且我方
///   存活即胜；**且**击败全部敌人也算胜（两通道任一，由 strategy 逐 tick 判定）。
///
/// 挂在 [StageDef.winCondition]（yaml 可选，缺省 null = defeatAll 旧行为），
/// 透传进 [BattleState.winCondition] 供 strategy 消费。
enum StageWinConditionType { defeatAll, surviveTicks }

class StageWinCondition {
  final StageWinConditionType type;

  /// 仅 [StageWinConditionType.surviveTicks] 有效：需撑过的 tick 数（>0）。
  final int? surviveTicksRequired;

  const StageWinCondition({
    required this.type,
    this.surviveTicksRequired,
  });

  factory StageWinCondition.fromYaml(Map<String, dynamic> y) {
    final typeStr = y['type'] as String?;
    if (typeStr == null) {
      throw StateError('winCondition 缺 type');
    }
    final type = StageWinConditionType.values.byName(typeStr);
    if (type == StageWinConditionType.surviveTicks) {
      final ticks = (y['ticks'] as num?)?.toInt();
      if (ticks == null || ticks <= 0) {
        throw StateError('winCondition surviveTicks 须配 ticks>0（实为 $ticks）');
      }
      return StageWinCondition(
        type: type,
        surviveTicksRequired: ticks,
      );
    }
    return StageWinCondition(type: type);
  }

  @override
  String toString() =>
      'StageWinCondition(${type.name}'
      '${surviveTicksRequired != null ? ', ticks=$surviveTicksRequired' : ''})';
}
```

注：`StageWinConditionType.values.byName('bogus')` 对非法值抛 `ArgumentError`（满足「非法 type 抛错」测），surviveTicks 缺/非正 ticks 抛 `StateError`。

- [ ] **Step 4: 跑测试确认通过**

Run: `flutter test --no-pub test/data/defs/stage_win_condition_test.dart`
Expected: PASS（5 测全绿）。

- [ ] **Step 5: `StageDef` 加 `winCondition` 字段 + fromYaml**

`lib/data/defs/stage_def.dart`：
- 顶部 import：`import 'stage_win_condition.dart';`
- 字段区（`dropSkillFragmentId` 后，:92 附近）加：
```dart
  /// 终局机制型 Boss 批次3 · 关卡胜负条件。null = defeatAll（击败全部敌人即胜，
  /// 现状语义，所有旧关零影响）。仅特殊机制关（心魔终关 inner_demon_07）配
  /// surviveTicks 型。透传进 BattleState.winCondition 供 strategy 逐 tick 判定。
  final StageWinCondition? winCondition;
```
- 构造参数（`this.dropSkillFragmentId,` 后，:120 附近）加：`this.winCondition,`
- fromYaml（`bossRecruit:` 项后，:166 附近）加：
```dart
      winCondition: y['winCondition'] == null
          ? null
          : StageWinCondition.fromYaml(
              Map<String, dynamic>.from(y['winCondition'] as Map),
            ),
```

- [ ] **Step 6: StageDef 层测试（winCondition 透传 + 缺省 null）**

追加到 `test/data/defs/stage_win_condition_test.dart`：
```dart
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/defs/stage_def.dart';

// ...在 main() 里追加：
  group('StageDef.winCondition', () {
    Map<String, dynamic> baseStageYaml() => {
          'id': 'stage_x',
          'name': 'X',
          'stageType': 'innerDemon',
          'requiredRealm': 'wuSheng',
          'enemyTeam': <dynamic>[],
          'isBossStage': true,
          'baseExpReward': 0,
          'difficultyMultiplier': 1.0,
        };

    test('缺 winCondition → null（旧关零影响）', () {
      final s = StageDef.fromYaml(baseStageYaml());
      expect(s.winCondition, isNull);
    });

    test('配 surviveTicks → 解析进 StageDef', () {
      final y = baseStageYaml()
        ..['winCondition'] = {'type': 'surviveTicks', 'ticks': 40};
      final s = StageDef.fromYaml(y);
      expect(s.winCondition?.type, StageWinConditionType.surviveTicks);
      expect(s.winCondition?.surviveTicksRequired, 40);
    });
  });
```

- [ ] **Step 7: 跑测试 + analyze**

Run: `flutter test --no-pub test/data/defs/stage_win_condition_test.dart`
Expected: PASS（7 测全绿）。
Run: `flutter analyze lib/ test/`
Expected: No issues。

- [ ] **Step 8: Commit**

```bash
git add lib/data/defs/stage_win_condition.dart lib/data/defs/stage_def.dart test/data/defs/stage_win_condition_test.dart
git commit -m "feat: StageWinCondition 数据面（surviveTicks 型）+ StageDef.winCondition 字段"
```

---

## Task 2: survive 战斗判定（BattleState 字段 + strategy 逐 tick 判定 + 透传）

**Files:**
- Modify: `lib/features/battle/domain/battle_state.dart:664-769`（加字段 + 构造 + initial + copyWith）
- Modify: `lib/features/battle/domain/strategy/default_ground_strategy.dart:76-95`（stepOne 边界 survive 检查）
- Modify: `lib/core/application/battle_providers.dart:78-87`（startBattle 加 winCondition 参 → initial）
- Modify: `lib/features/mainline/presentation/stage_entry_flow.dart:539,552,561`（透传 stage.winCondition）
- Test: `test/features/battle/survive_win_condition_test.dart`（新建·确定性 via notifier）

- [ ] **Step 1: `BattleState` 加 `winCondition` 字段**

`lib/features/battle/domain/battle_state.dart`：
- 顶部 import：`import '../../../data/defs/stage_win_condition.dart';`
- 字段区（`actorQueue` 后，:687 附近）加：
```dart
  /// 本场战斗胜负条件（终局机制型 Boss 批次3）。null = defeatAll（击败全部敌人
  /// 即胜，现状语义）。surviveTicks 型由 strategy 在 tick 边界判定：tick≥N 且
  /// 左队存活 → leftWin（与「右队全灭→leftWin」并存，任一即胜）。
  /// 由 [BattleState.initial] 从 StageDef.winCondition 灌入，全程不变。
  final StageWinCondition? winCondition;
```
- 主构造（`this.actorQueue = const [],` 后，:697 附近）加：`this.winCondition,`
- `BattleState.initial` factory：加可选参 + 透传：
```dart
  factory BattleState.initial({
    required List<BattleCharacter> leftTeam,
    required List<BattleCharacter> rightTeam,
    StageWinCondition? winCondition,
  }) {
    return BattleState(
      leftTeam: List.unmodifiable(leftTeam),
      rightTeam: List.unmodifiable(rightTeam),
      tick: 0,
      result: null,
      actionLog: const [],
      pendingUltimates: const {},
      pendingTargets: const {},
      winCondition: winCondition,
    );
  }
```
- `copyWith`：加参 `StageWinCondition? winCondition,` + body `winCondition: winCondition ?? this.winCondition,`（winCondition 设一次不回改，`?? this` 自动透传所有现有 copyWith 调用，零改现有调用点）。

- [ ] **Step 2: 写失败测试（survive 双通道 + 边界 + 旧关零影响，via notifier）**

`test/features/battle/survive_win_condition_test.dart`：
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wuxia_idle/core/application/battle_providers.dart';
import 'package:wuxia_idle/data/defs/stage_win_condition.dart';
import 'package:wuxia_idle/features/battle/domain/battle_state.dart';
// 用项目现有战斗测试夹具构造 BattleCharacter（照 battle_determinism 体例）。
import '../../support/battle_test_fixtures.dart'; // 若无则用现有夹具路径

void main() {
  // 确定性走 ProviderContainer + notifier.advance（memory
  // battle_determinism_test_via_notifier）。永久 listener 防 autoDispose。
  late ProviderContainer container;
  setUp(() {
    container = ProviderContainer();
    container.listen(battleProvider, (_, __) {}, fireImmediately: true);
  });
  tearDown(() => container.dispose());

  BattleStateNotifier notifier() => container.read(battleProvider.notifier);

  test('surviveTicks: 强镜像下左队撑到 N tick 存活 → leftWin', () {
    // 构造：左队较弱但不速死、右队较强不速杀，令战斗在 tick N 时双方仍存活。
    final left = buildWeakButDurablePlayerTeam();   // 夹具：能撑过 N tick
    final right = buildStrongMirrorTeam();           // 夹具：强但 N tick 内杀不完左队
    notifier().startBattle(
      left,
      right,
      seed: 12345,
      winCondition: const StageWinCondition(
        type: StageWinConditionType.surviveTicks,
        surviveTicksRequired: 40,
      ),
    );
    var s = container.read(battleProvider);
    var guard = 0;
    while (!s.isFinished && guard++ < 2000) {
      notifier().advance();
      s = container.read(battleProvider);
    }
    expect(s.result, BattleResult.leftWin);
    expect(s.tick, greaterThanOrEqualTo(40));
    expect(s.leftTeam.any((c) => c.isAlive), isTrue);
  });

  test('surviveTicks: 满配秒镜像（tick<N 右队全灭）→ leftWin（击败通道并存）', () {
    final left = buildOverpoweredPlayerTeam();   // 夹具：几 tick 内秒杀镜像
    final right = buildWeakMirrorTeam();
    notifier().startBattle(
      left,
      right,
      seed: 777,
      winCondition: const StageWinCondition(
        type: StageWinConditionType.surviveTicks,
        surviveTicksRequired: 40,
      ),
    );
    var s = container.read(battleProvider);
    var guard = 0;
    while (!s.isFinished && guard++ < 2000) {
      notifier().advance();
      s = container.read(battleProvider);
    }
    expect(s.result, BattleResult.leftWin);
    expect(s.tick, lessThan(40)); // 提前斩镜像
    expect(s.rightTeam.every((c) => !c.isAlive), isTrue);
  });

  test('surviveTicks: 左队 tick<N 全灭 → rightWin（被击败）', () {
    final left = buildGlassPlayerTeam();     // 夹具：N tick 前被杀光
    final right = buildStrongMirrorTeam();
    notifier().startBattle(
      left,
      right,
      seed: 999,
      winCondition: const StageWinCondition(
        type: StageWinConditionType.surviveTicks,
        surviveTicksRequired: 40,
      ),
    );
    var s = container.read(battleProvider);
    var guard = 0;
    while (!s.isFinished && guard++ < 2000) {
      notifier().advance();
      s = container.read(battleProvider);
    }
    expect(s.result, BattleResult.rightWin);
    expect(s.tick, lessThan(40));
  });

  test('winCondition==null: 打平局面走 draw（旧行为零影响）', () {
    final left = buildMutuallyImmuneTeam();   // 夹具：双方近免疫 → 超时 draw
    final right = buildMutuallyImmuneMirror();
    notifier().startBattle(left, right, seed: 1);
    var s = container.read(battleProvider);
    var guard = 0;
    while (!s.isFinished && guard++ < 3000) {
      notifier().advance();
      s = container.read(battleProvider);
    }
    // 无 winCondition → 不会因 tick 数提前判 leftWin；走全灭或超时 draw。
    expect(s.result, isNot(BattleResult.leftWin));
  });
}
```

> **实装者注：** 夹具 `buildWeakButDurablePlayerTeam` 等按项目现有战斗测试夹具体例构造（参照 `test/features/battle/` 下已有确定性测试如 `battle_determinism_*` 的队伍构造）。若无公共夹具，在本文件内用现有 `BattleCharacter` 构造器直接造（弱队=低攻击高血、强队=高攻击、玻璃队=低血）。关键是让 4 个场景的胜负分歧真实发生（非同一队）。

- [ ] **Step 3: 跑测试确认失败**

Run: `flutter test --no-pub test/features/battle/survive_win_condition_test.dart`
Expected: FAIL（startBattle 无 winCondition 参 / survive 未判定，前 3 测挂）。

- [ ] **Step 4: `startBattle` 加 winCondition 参 → initial**

`lib/core/application/battle_providers.dart:78-87`：
```dart
  void startBattle(
    List<BattleCharacter> leftTeam,
    List<BattleCharacter> rightTeam, {
    BattleStrategy? strategy,
    int? seed,
    StageWinCondition? winCondition,
  }) {
    _strategy = strategy ?? const DefaultGroundStrategy();
    _rng = Random(seed ?? Random().nextInt(1 << 32));
    state = BattleState.initial(
      leftTeam: leftTeam,
      rightTeam: rightTeam,
      winCondition: winCondition,
    );
  }
```
顶部补 import：`import '../../data/defs/stage_win_condition.dart';`（若未传递引入）。

- [ ] **Step 5: strategy 在 stepOne tick 边界加 survive 检查**

`lib/features/battle/domain/strategy/default_ground_strategy.dart`，改 stepOne 的 tick 边界分支（现 :86-94），把 `return state.copyWith(...)` 改为先算边界态再判 survive：
```dart
      actors.sort(_actorOrder);
      final boundary = state.copyWith(
        leftTeam: List.unmodifiable(left),
        rightTeam: List.unmodifiable(right),
        tick: state.tick + 1,
        actorQueue: List.unmodifiable(
          actors.map((c) => (charId: c.characterId, teamSide: c.teamSide)),
        ),
      );
      // 终局机制型 Boss 批次3:限时生存胜负条件。tick 边界逐 tick 判定——
      // 撑满 N tick 且左队存活 → leftWin（与「右队全灭→leftWin」并存，任一即胜）。
      // winCondition==null / defeatAll 时零行为变化。
      final wc = boundary.winCondition;
      if (wc != null &&
          wc.type == StageWinConditionType.surviveTicks &&
          boundary.tick >= wc.surviveTicksRequired! &&
          boundary.leftTeam.any((c) => c.isAlive)) {
        return boundary.copyWith(
          result: BattleResult.leftWin,
          actorQueue: const [],
        );
      }
      return boundary;
```
顶部补 import：`import '../../../../data/defs/stage_win_condition.dart';`（确认相对路径层级，`lib/features/battle/domain/strategy/` → `lib/data/defs/` = `../../../../data/defs/`）。

- [ ] **Step 6: 跑测试确认通过**

Run: `flutter test --no-pub test/features/battle/survive_win_condition_test.dart`
Expected: PASS（4 测全绿）。若夹具未令场景分歧真实发生（如「撑到 N」场景其实提前全灭），调夹具队伍强度直到 4 场景各自成立（诊断驱动，非改判定逻辑）。

- [ ] **Step 7: 生产透传 stage.winCondition**

`lib/features/mainline/presentation/stage_entry_flow.dart` 三处 startBattle（:539/552/561），各加 `winCondition: widget.stage.winCondition,`。例（:561 简单式）：
```dart
          ref.read(battleProvider.notifier).startBattle(
                left,
                right,
                winCondition: widget.stage.winCondition,
              );
```
:539/:552 是带 seed/strategy 的多行式，同样追加 `winCondition: widget.stage.winCondition,`。
> 注：其余 startBattle caller（tower/sweep/battle_demo/battle_test_menu）不传 winCondition（默认 null=defeatAll，零影响）。仅主线 stage_entry_flow 透传，因只有 stage（含心魔）经此路径且只有 inner_demon_07 配了 winCondition。

- [ ] **Step 8: 回归 + analyze**

Run: `flutter test --no-pub test/features/battle/`
Expected: 全绿（改核心 stepOne，跑整个 battle 目录防回归；winCondition==null 分支零变化）。
Run: `flutter analyze lib/ test/`
Expected: No issues。

- [ ] **Step 9: Commit**

```bash
git add lib/features/battle/domain/battle_state.dart lib/features/battle/domain/strategy/default_ground_strategy.dart lib/core/application/battle_providers.dart lib/features/mainline/presentation/stage_entry_flow.dart test/features/battle/survive_win_condition_test.dart
git commit -m "feat: survive 限时生存胜负条件（BattleState.winCondition + strategy 逐 tick 判定 + 透传）"
```

---

## Task 3: 心魔蓄力技 + InnerDemonDef 脆弱窗口数据面（不接注入）

**Files:**
- Modify: `data/skills.yaml`（新增 `skill_inner_demon_charge`）
- Modify: `data/numbers.yaml:1572-1627`（innerDemon 段加 `mirror_vulnerability_per_stage` + `mirror_charge_skill_id`）
- Modify: `lib/features/inner_demon/domain/inner_demon_def.dart:15-116`（加两字段 + fromYaml + empty + 跨字段校验）
- Test: `test/features/inner_demon/inner_demon_vulnerability_def_test.dart`（新建）

- [ ] **Step 1: 写失败测试（InnerDemonDef 脆弱字段解析 + 跨字段校验）**

`test/features/inner_demon/inner_demon_vulnerability_def_test.dart`：
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/inner_demon/domain/inner_demon_def.dart';

void main() {
  group('InnerDemonDef 脆弱窗口数据面', () {
    Map<String, dynamic> baseYaml() => {
          'mirror_buff_per_stage': {
            'stage_inner_demon_05': 0.18,
            'stage_inner_demon_06': 0.20,
          },
          'mirror_vulnerability_per_stage': {
            'stage_inner_demon_05': {'outOfWindowDamageMult': 0.12},
            'stage_inner_demon_06': {'outOfWindowDamageMult': 0.10},
          },
          'mirror_charge_skill_id': 'skill_inner_demon_charge',
        };

    test('解析 mirror_vulnerability_per_stage + mirror_charge_skill_id', () {
      final d = InnerDemonDef.fromYaml(baseYaml());
      expect(d.mirrorVulnerabilityPerStage['stage_inner_demon_05']!.outOfWindowDamageMult, 0.12);
      expect(d.mirrorVulnerabilityPerStage['stage_inner_demon_06']!.outOfWindowDamageMult, 0.10);
      expect(d.mirrorChargeSkillId, 'skill_inner_demon_charge');
    });

    test('mult 越界（<0.05）启动期抛错（复用 BossVulnerabilityDef 校验）', () {
      final y = baseYaml();
      (y['mirror_vulnerability_per_stage'] as Map)['stage_inner_demon_05'] =
          {'outOfWindowDamageMult': 0.01};
      expect(() => InnerDemonDef.fromYaml(y), throwsA(isA<Object>()));
    });

    test('配了 vulnerability 但缺 mirror_charge_skill_id → 抛错（永不开窗无解）', () {
      final y = baseYaml()..remove('mirror_charge_skill_id');
      expect(() => InnerDemonDef.fromYaml(y), throwsStateError);
    });

    test('无 vulnerability 段 → 两字段空/null（01-04/旧配置零影响）', () {
      final d = InnerDemonDef.fromYaml({
        'mirror_buff_per_stage': {'stage_inner_demon_01': 0.10},
      });
      expect(d.mirrorVulnerabilityPerStage, isEmpty);
      expect(d.mirrorChargeSkillId, isNull);
    });

    test('empty() 默认无脆弱窗口', () {
      final d = InnerDemonDef.empty();
      expect(d.mirrorVulnerabilityPerStage, isEmpty);
      expect(d.mirrorChargeSkillId, isNull);
    });
  });
}
```

- [ ] **Step 2: 跑测试确认失败**

Run: `flutter test --no-pub test/features/inner_demon/inner_demon_vulnerability_def_test.dart`
Expected: FAIL（`mirrorVulnerabilityPerStage` / `mirrorChargeSkillId` 不存在）。

- [ ] **Step 3: InnerDemonDef 加两字段 + fromYaml + empty + 校验**

`lib/features/inner_demon/domain/inner_demon_def.dart`：
- 顶部 import：`import '../../../data/defs/boss_vulnerability_def.dart';`
- 字段区（`requiredRealmLayer` 后）加：
```dart
  /// 终局机制型 Boss 批次3 · 高层心魔关（05/06）镜像脆弱窗口配置。
  /// stage_id → 承伤乘子 def（窗口外 ×mult 减伤）。空 = 该关镜像无机制（01-04/07）。
  /// 复用批次1 BossVulnerabilityDef（schema [0.05,1.0]）。
  final Map<String, BossVulnerabilityDef> mirrorVulnerabilityPerStage;

  /// 注入配了 vulnerability 的镜像的蓄力技 id（周期性蓄力开窗，CD 复发）。
  /// null = 无机制化心魔关。配了 mirrorVulnerabilityPerStage 必配此项（否则永不
  /// 开窗=永久免疫无解，fromYaml 跨字段校验 fail-fast）。
  final String? mirrorChargeSkillId;
```
- 主构造加：`this.mirrorVulnerabilityPerStage = const {}, this.mirrorChargeSkillId,`
- `empty()` 加：`mirrorVulnerabilityPerStage: const {}, mirrorChargeSkillId: null,`（因加了默认值，empty 可省略；显式写更清晰）
- fromYaml：`return InnerDemonDef(...)` 前解析 + 末尾跨字段校验：
```dart
    final vuln = <String, BossVulnerabilityDef>{};
    final vulnYaml = y['mirror_vulnerability_per_stage'] as Map?;
    if (vulnYaml != null) {
      for (final e in vulnYaml.entries) {
        vuln[e.key as String] = BossVulnerabilityDef.fromYaml(
          Map<String, dynamic>.from(e.value as Map),
        );
      }
    }
    final chargeSkillId = y['mirror_charge_skill_id'] as String?;
    // 跨字段校验:配了脆弱窗口必配蓄力技（对齐批次1「vulnerability 必有 chargeSkillId」）。
    if (vuln.isNotEmpty && chargeSkillId == null) {
      throw StateError(
        'inner_demon: 配了 mirror_vulnerability_per_stage '
        '(${vuln.keys.join(",")}) 但缺 mirror_charge_skill_id（永不开窗=无解）',
      );
    }
```
- fromYaml 的 `return InnerDemonDef(...)` 加：`mirrorVulnerabilityPerStage: vuln, mirrorChargeSkillId: chargeSkillId,`

- [ ] **Step 4: 跑测试确认通过**

Run: `flutter test --no-pub test/features/inner_demon/inner_demon_vulnerability_def_test.dart`
Expected: PASS（5 测全绿）。

- [ ] **Step 5: 新增心魔蓄力技 skills.yaml**

`data/skills.yaml` 末尾（或心魔相关段）加：
```yaml
  # ───────────────────────────────────────────
  # 终局机制型 Boss 批次3 · 心魔镜像蓄力技（不进玩家技能池 / 不进 EnemyDef，
  # 仅 InnerDemonService 注入 inner_demon_05/06 镜像，CD 复发开脆弱窗口）。
  # ───────────────────────────────────────────
  - id: skill_inner_demon_charge
    name: 心魔·运劲
    description: 心魔凝气蓄势,周身破绽毕露,一击既发势不可挡。
    type: powerSkill
    targetType: single
    powerMultiplier: 4000   # 高于镜像继承的多数玩家强力技,保证 AI 选中进蓄力态；<8000 硬线。Task4 诊断校准
    internalForceCost: 200
    cooldownTurns: 4        # 窗口周期 = CD；Task4 诊断校准复发频率
    requiresManualTrigger: false
    parentTechniqueDefId: null
    visualEffect: null
    source: inner_demon_mechanic
    style: gangMeng          # 三系锁死 gate 用（镜像不受 equip gate，取值不影响注入）
    tier: 7                  # wuSheng 阶（镜像为 wuSheng 境）
```
> **实装者注：** 若 `source: inner_demon_mechanic` 非 `SkillDef` 合法枚举/字符串，改用现有合法 source（grep skills.yaml 现有 `source:` 取值，如 `mainline_drop`）。运行 skills 加载 + 全局 ≤8000 红线测（见 Step 7）确认新技合法。

- [ ] **Step 6: numbers.yaml innerDemon 段加脆弱配置**

`data/numbers.yaml` inner_demon 段（:1572-1627 内，`mirror_buff_per_stage` 附近）加：
```yaml
  # 终局机制型 Boss 批次3 · 高层心魔关镜像脆弱窗口（仅 05/06；07 走 survive 不配）。
  mirror_vulnerability_per_stage:
    stage_inner_demon_05:
      outOfWindowDamageMult: 0.12   # schema [0.05,1.0]；Task4 诊断校准
    stage_inner_demon_06:
      outOfWindowDamageMult: 0.10
  mirror_charge_skill_id: skill_inner_demon_charge
```

- [ ] **Step 7: 真实配置加载 + 全局技能红线**

Run: `flutter test --no-pub test/features/inner_demon/inner_demon_vulnerability_def_test.dart`
Expected: PASS。
Run: `flutter test --no-pub test/data/ test/balance/`（含 skills 加载 + 全局 ≤8000 招式倍率红线 + numbers 解析守卫）
Expected: 全绿（新技 4000<8000；新 numbers 段被 InnerDemonDef.fromYaml 消费不误判 unused）。
Run: `flutter analyze lib/ test/`
Expected: No issues。

- [ ] **Step 8: Commit**

```bash
git add data/skills.yaml data/numbers.yaml lib/features/inner_demon/domain/inner_demon_def.dart test/features/inner_demon/inner_demon_vulnerability_def_test.dart
git commit -m "feat: 心魔蓄力技 skill_inner_demon_charge + InnerDemonDef 脆弱窗口数据面（05/06）"
```

---

## Task 4: 镜像注入（vulnerabilityMult + chargeSkillId + 蓄力技）+ 05/06 诊断

**Files:**
- Modify: `lib/features/inner_demon/application/inner_demon_service.dart:103-196`（buildMirrorEnemyTeam / _mirror 注入）
- Modify: `lib/features/battle/application/stage_battle_setup.dart:51-60`（解析蓄力技 SkillDef 传入）
- Test: `test/features/inner_demon/inner_demon_mirror_injection_test.dart`（新建·注入单测）
- Test: `test/tools/inner_demon_vulnerability_diagnostic_test.dart`（新建·05/06 A/B + 跨阶诊断）

- [ ] **Step 1: 写失败测试（分关精确注入）**

`test/features/inner_demon/inner_demon_mirror_injection_test.dart`：
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/inner_demon/application/inner_demon_service.dart';
import 'package:wuxia_idle/features/inner_demon/domain/inner_demon_def.dart';
import 'package:wuxia_idle/data/defs/boss_vulnerability_def.dart';
// 用现有 SkillDef 构造器造一个蓄力技测桩 + 现有 BattleCharacter 夹具。

void main() {
  final def = InnerDemonDef.fromYaml({
    'mirror_buff_per_stage': {
      'stage_inner_demon_05': 0.18,
      'stage_inner_demon_06': 0.20,
      'stage_inner_demon_07': 0.40,
    },
    'mirror_vulnerability_per_stage': {
      'stage_inner_demon_05': {'outOfWindowDamageMult': 0.12},
      'stage_inner_demon_06': {'outOfWindowDamageMult': 0.10},
    },
    'mirror_charge_skill_id': 'skill_inner_demon_charge',
  });
  final chargeSkill = buildChargeSkillStub('skill_inner_demon_charge'); // 夹具

  test('05/06 镜像注入 vulnerabilityMult + chargeSkillId + 蓄力技', () {
    for (final stageId in ['stage_inner_demon_05', 'stage_inner_demon_06']) {
      final mirrors = InnerDemonService.buildMirrorEnemyTeam(
        playerTeam: buildPlayerTeam3(),
        stageId: stageId,
        innerDemonDef: def,
        mirrorChargeSkill: chargeSkill,
      );
      final expected = stageId == 'stage_inner_demon_05' ? 0.12 : 0.10;
      for (final m in mirrors) {
        expect(m.vulnerabilityMult, expected);
        expect(m.chargeSkillId, 'skill_inner_demon_charge');
        expect(m.availableSkills.any((s) => s.id == 'skill_inner_demon_charge'), isTrue);
      }
    }
  });

  test('07 镜像无脆弱窗口注入（纯镜像）', () {
    final mirrors = InnerDemonService.buildMirrorEnemyTeam(
      playerTeam: buildPlayerTeam3(),
      stageId: 'stage_inner_demon_07',
      innerDemonDef: def,
      mirrorChargeSkill: chargeSkill,
    );
    for (final m in mirrors) {
      expect(m.vulnerabilityMult, isNull);
      expect(m.chargeSkillId, isNull);
      expect(m.availableSkills.any((s) => s.id == 'skill_inner_demon_charge'), isFalse);
    }
  });

  test('01 镜像无脆弱窗口注入（低层纯镜像）', () {
    final mirrors = InnerDemonService.buildMirrorEnemyTeam(
      playerTeam: buildPlayerTeam3(),
      stageId: 'stage_inner_demon_01',
      innerDemonDef: def,
      mirrorChargeSkill: chargeSkill,
    );
    expect(mirrors.every((m) => m.vulnerabilityMult == null), isTrue);
  });
}
```
> **实装者注：** `buildChargeSkillStub` 用现有 `SkillDef` 构造器造（type powerSkill, id 传入）；`buildPlayerTeam3` 用现有 BattleCharacter 夹具造 3 人玩家队（照 `inner_demon_service_test.dart:256+` 现有 buildMirrorEnemyTeam 测试的队伍构造体例）。确认 `BattleCharacter` 有 `availableSkills` 字段名（若实际叫别的名，如 `skills`，全测同步）。

- [ ] **Step 2: 跑测试确认失败**

Run: `flutter test --no-pub test/features/inner_demon/inner_demon_mirror_injection_test.dart`
Expected: FAIL（buildMirrorEnemyTeam 无 `mirrorChargeSkill` 参 / _mirror 未注入）。

- [ ] **Step 3: buildMirrorEnemyTeam / _mirror 加注入**

`lib/features/inner_demon/application/inner_demon_service.dart`：
- `buildMirrorEnemyTeam` 加可选参 + 传入 _mirror：
```dart
  static List<BattleCharacter> buildMirrorEnemyTeam({
    required List<BattleCharacter> playerTeam,
    required String stageId,
    required InnerDemonDef innerDemonDef,
    SkillDef? mirrorChargeSkill,
  }) {
    final buff = innerDemonDef.mirrorBuffPerStage[stageId] ?? 0.0;
    final caps = innerDemonDef.mirrorCaps;
    final vuln = innerDemonDef.mirrorVulnerabilityPerStage[stageId];
    return [
      for (var i = 0; i < playerTeam.length && i < 3; i++)
        _mirror(
          playerTeam[i],
          buff: buff,
          caps: caps,
          slotIndex: i,
          vulnerabilityMult: vuln?.outOfWindowDamageMult,
          chargeSkill: vuln != null ? mirrorChargeSkill : null,
        ),
    ];
  }
```
- `_mirror` 加参 + 注入（现 copyWith 加 vulnerabilityMult + chargeSkillId + availableSkills）：
```dart
  static BattleCharacter _mirror(
    BattleCharacter src, {
    required double buff,
    required InnerDemonMirrorCaps caps,
    required int slotIndex,
    double? vulnerabilityMult,
    SkillDef? chargeSkill,
  }) {
    final maxHp = (src.maxHp * (1 + buff)).round().clamp(1, caps.hpMax);
    final maxIf = (src.maxInternalForce * (1 + buff)).round().clamp(1, caps.internalForceMax);
    final attack = (src.totalEquipmentAttack * (1 + buff)).round().clamp(0, caps.attackPowerMax);
    // 注入蓄力技进 availableSkills（若配了且不在列表）——照 stage_battle_setup 识破体例。
    final skills = (chargeSkill != null &&
            !src.availableSkills.any((s) => s.id == chargeSkill.id))
        ? [...src.availableSkills, chargeSkill]
        : src.availableSkills;
    return src.copyWith(
      characterId: -(slotIndex + 1),
      name: UiStrings.innerDemonMirrorName(src.name),
      maxHp: maxHp,
      currentHp: maxHp,
      maxInternalForce: maxIf,
      currentInternalForce: maxIf,
      totalEquipmentAttack: attack,
      skillCooldowns: const {},
      activeBuffs: const [],
      actionPoint: 0,
      isAlive: true,
      teamSide: 1,
      slotIndex: slotIndex,
      internalInjury: null,
      iconPath: null,
      vulnerabilityMult: vulnerabilityMult,
      chargeSkillId: chargeSkill?.id,
      availableSkills: skills,
    );
  }
```
- 顶部 import：`import '../../../data/defs/skill_def.dart';`（SkillDef 路径，实装者确认实际路径）。
- **更新 `buildMirrorEnemyTeam` docstring**（§3.4）：标注「05/06 注入蓄力技=有意的机制化心魔进阶形态，非纯镜像；01-04/07 维持纯镜像」。

> **注意 copyWith：** `BattleCharacter.copyWith` 须支持 `vulnerabilityMult`（批次1 已加）、`chargeSkillId`（批次1/2 已加）、`availableSkills`。若 `chargeSkillId` copyWith 用 `_unset` sentinel（因 null 有意义），传 `chargeSkill?.id`（05/06 非 null，07/01-04 传 null 即保持基础镜像无 chargeSkillId——实装者确认 copyWith 对 chargeSkillId 的 null 语义：此处 07 应为「无 chargeSkillId」，传 null 若被 sentinel 当「不改」则 OK 因基础镜像本无；保险起见分支处理）。

- [ ] **Step 4: stage_battle_setup 解析蓄力技 SkillDef 传入**

`lib/features/battle/application/stage_battle_setup.dart:51-60`，心魔分支改为先解析蓄力技：
```dart
    final left = await _buildPlayerTeam();
    List<BattleCharacter> right;
    if (stage.stageType == StageType.innerDemon) {
      final idDef = GameRepository.instance.numbers.innerDemon;
      final chargeSkill = idDef.mirrorChargeSkillId != null
          ? GameRepository.instance.getSkill(idDef.mirrorChargeSkillId!)
          : null;
      right = InnerDemonService.buildMirrorEnemyTeam(
        playerTeam: left,
        stageId: stage.id,
        innerDemonDef: idDef,
        mirrorChargeSkill: chargeSkill,
      );
    } else {
      right = buildEnemyTeam(
        stage.enemyTeam,
        cycleIndex: cycleIndex,
        isTower: false,
        stageNpcId: stage.isBossStage ? stage.npcId : null,
      );
    }
```
> 实装者确认 `GameRepository.instance.getSkill(id)` 是正确的 SkillDef 取用 API（grep 现有 getSkill 用法，如 stage_battle_setup.dart:448 识破分支 `GameRepository.instance.getSkill(shipoSkillId)` 已用同一 API）。

- [ ] **Step 5: 跑注入单测确认通过**

Run: `flutter test --no-pub test/features/inner_demon/inner_demon_mirror_injection_test.dart`
Expected: PASS（3 测全绿）。
Run: `flutter test --no-pub test/features/inner_demon/`
Expected: 全绿（现有 buildMirrorEnemyTeam 测不回归——它们不传 mirrorChargeSkill，默认 null，05/06 无 vuln 时也不注入）。

> **注意：** 现有 `inner_demon_service_test.dart` 调 buildMirrorEnemyTeam 不带 mirrorChargeSkill——因是可选参默认 null，且现有测试用的 InnerDemonDef 无 mirror_vulnerability_per_stage（vuln==null）→ 不注入，零回归。若现有测试的 def fixture 恰含 05/06 buff 但无 vuln，仍不注入（vuln==null gate）。

- [ ] **Step 6: 写 05/06 A/B + 跨阶诊断测（确定性 via engine.tick）**

`test/tools/inner_demon_vulnerability_diagnostic_test.dart`（照 `test/tools/cycle2_vulnerability_diagnostic_test.dart` 体例——真实 numbers.yaml + StageBattleSetup 镜像 + 确定性 seed + avg win ticks）：
```dart
// 骨架（实装者照 cycle2_vulnerability_diagnostic_test.dart 精确复刻夹具与驱动）：
// 1. 加载真实 numbers.yaml innerDemon（GameRepository），造满配 wuSheng on-level 玩家队。
// 2. A 臂：真实注入（05/06 mirror 带 vulnerabilityMult+chargeSkillId+蓄力技）。
//    B 臂：copyWith 剥离 vulnerabilityMult（还原全额承伤，隔离窗口效应）。
// 3. 各跑 20 seed，BattleEngine.tick / notifier.advance 到结束，统计 avgWinTicks。
// 断言：
//   - A 臂满配 on-level 全胜（窗口真开，无永久免疫）；
//   - A 臂 avgWinTicks 显著 > B 臂（time-to-kill 被窗口 gate 拉长，证削秒杀非 no-op）；
//   - A 臂镜像血量进度单调下降不摆（每若干 tick 有净掉血，避 ward_noop 那种停滞）；
//   - under-gear 跨阶（造绝顶-1~2 阶低强化满配）有可观败率（软门槛，守 boss_balance_crosstier）。
```
> **实装者：** 本测是 Task4 核心硬闸。**先跑确认镜像真进蓄力态**——加一个子断言：跑若干 tick 后镜像 `chargingSkill != null` 至少出现过一次（证 AI 选中蓄力技开窗）。若从不进蓄力（AI 更爱玩家继承的高倍率技），**调 skills.yaml 蓄力技 powerMultiplier 上调（仍<8000）直到 AI 稳定选中**（这是 §5 校准点，改数值非改逻辑）。

- [ ] **Step 7: 跑诊断 + 校准**

Run: `flutter test --no-pub test/tools/inner_demon_vulnerability_diagnostic_test.dart`
Expected: PASS。若 A/B 无显著差异（窗口没真 gate）或镜像不进蓄力，按 Step 6 注调 powerMultiplier / vulnerability mult 复跑，直到四断言成立。校准定稿的 05/06 mult 与蓄力技 powerMultiplier 写回 numbers.yaml/skills.yaml。

- [ ] **Step 8: analyze + Commit**

Run: `flutter analyze lib/ test/`
Expected: No issues。
```bash
git add lib/features/inner_demon/application/inner_demon_service.dart lib/features/battle/application/stage_battle_setup.dart test/features/inner_demon/inner_demon_mirror_injection_test.dart test/tools/inner_demon_vulnerability_diagnostic_test.dart data/skills.yaml data/numbers.yaml
git commit -m "feat: 心魔镜像脆弱窗口注入（05/06）+ A/B 跨阶诊断测 + 校准"
```

---

## Task 5: inner_demon_07 survive 配置 + 双通道诊断 + N 校准

**Files:**
- Modify: `data/stages.yaml`（stage_inner_demon_07 加 winCondition）
- Test: `test/tools/inner_demon_survive_diagnostic_test.dart`（新建·07 survive 端到端）

- [ ] **Step 1: stages.yaml stage_inner_demon_07 加 winCondition**

`data/stages.yaml` stage_inner_demon_07（:1656 附近）加：
```yaml
    winCondition:
      type: surviveTicks
      ticks: 40            # Task5 诊断校准（满配撑得过但非碾压、欠配有可观败率）
```

- [ ] **Step 2: 写 07 survive 双通道诊断测（确定性 via notifier）**

`test/tools/inner_demon_survive_diagnostic_test.dart`（照 cycle2 诊断体例，走 notifier.advance 或 engine.runToEnd 真实 StageBattleSetup）：
```dart
// 骨架：
// 1. 加载真实 stages.yaml stage_inner_demon_07（GameRepository.getStage），
//    确认 stage.winCondition.type == surviveTicks, surviveTicksRequired == 40。
// 2. 满配 wuSheng on-level 玩家队 vs 07 镜像（+40% buff，无脆弱窗口）。
//    经 StageBattleSetup 构造 + startBattle(winCondition: stage.winCondition)。
// 断言（多 seed 确定性）：
//   (a) 满配足以秒镜像 → result==leftWin 且 tick<40（击败通道）；
//   (b) 造欠配/耐久玩家队撑到 tick>=40 存活 → result==leftWin 且 tick>=40（生存通道）；
//   (c) 造玻璃队 tick<40 全灭 → result==rightWin；
//   (d) 边界：构造正好 tick 39 时左队仍存活但 40 前被杀的场景不误判 leftWin（可选，若难构造则以 tick 计数不变量替代：leftWin 时 tick>=40 或 rightTeam 全灭二者必居其一）。
```
> **实装者：** 关键不变量断言（最稳）：`result==leftWin ⟹ (tick>=40 || rightTeam.every(!isAlive))`——覆盖两通道，避免脆构造。N=40 校准：跑满配 + on-level + under-gear 多档，调 ticks 到「满配轻松（多半提前斩）、on-level 撑得过、跨阶欠配有败率」。

- [ ] **Step 3: 跑诊断 + N 校准**

Run: `flutter test --no-pub test/tools/inner_demon_survive_diagnostic_test.dart`
Expected: PASS。按不变量断言 + 手感目标校准 ticks 定稿。

- [ ] **Step 4: 真实关卡加载守卫**

Run: `flutter test --no-pub test/data/`（stages.yaml 加载 + 结构守卫；确认新 winCondition 段被 StageDef.fromYaml 消费不报错）
Expected: 全绿。

- [ ] **Step 5: analyze + Commit**

Run: `flutter analyze lib/ test/`
Expected: No issues。
```bash
git add data/stages.yaml test/tools/inner_demon_survive_diagnostic_test.dart
git commit -m "feat: inner_demon_07 限时生存 winCondition + survive 双通道诊断 + N 校准"
```

---

## Task 6: 红线文档同步 + 批末全量

**Files:**
- Modify: `GDD.md`（§5.4 红线块机制型 Boss 例外追加心魔实例）
- Modify: `CLAUDE.md`（§5.4 + 版本号 bump 追加心魔实例）
- Modify: `PROGRESS.md`（顶段批次3 四态条）

- [ ] **Step 1: GDD §5.4 追加心魔实例**

`GDD.md` §5.2/§5.4 机制型 Boss 例外条款处（批次5 `10b4672d` 已立底座），追加实例句：措辞对齐既有条款——「心魔 05/06 高层关镜像配脆弱窗口（承伤乘子 [0.05,1.0]，运劲蓄力开窗）；心魔终关 07 配限时生存胜负条件（撑满 N tick 或击败镜像任一即胜，DPS 与胜负脱钩）」。**只追加实例，不改条款语义**（减伤方向 / 不膨胀数字 / 不触「不进百万」硬线）。

- [ ] **Step 2: CLAUDE.md §5.4 + 版本 bump**

`CLAUDE.md`：§5.4 机制型 Boss 例外条款追加同一心魔实例句；顶部版本号 bump（现 v1.30 → v1.31）+ 变更摘要一行（「批次3 心魔机制型实例登记：05/06 镜像脆弱窗口 + 07 限时生存；0 改代码红线语义，纯实例追加」）。

- [ ] **Step 3: 批末全量测试**

Run: `flutter analyze lib/ test/`
Expected: No issues（0）。
Run: `flutter test --no-pub`（默认并发，全量）
Expected: 全绿 0 fail。记录 pass 数（基线本批前 3647 + 本批新测数）。**必贴真实输出**（防幻觉：报「全绿」前必跑并贴 tail）。

- [ ] **Step 4: PROGRESS.md 顶段批次3 条（四态）**

`PROGRESS.md` 顶段加批次3 条，区分：已完成（两模块 + 6 Task）/ 已验证（analyze 0 + 全量实测 pass 数）/ 已知风险（模块1 自动效率 < 手动是有意；07 双镜像未动；蓄力技注入使 05/06 非纯镜像）/ 下批（终局机制型 Boss 特性全 5 批完结，无下批；视觉验收待真机可选）。sha 现跑 `git rev-parse` 核实，禁转抄。

- [ ] **Step 5: Commit**

```bash
git add GDD.md CLAUDE.md PROGRESS.md
git commit -m "docs: 批次3 心魔机制型红线实例登记（GDD/CLAUDE §5.4 v1.31）+ PROGRESS 四态"
```

- [ ] **Step 6: 视觉验收（可选·主窗口合并前统一安排）**

心魔 05/06 蓄力题字 + 脆弱窗口减伤反馈 + 07 survive「坚持住」表现层若有改动，真机 `VISUAL_ROUTE` 截图验收（memory `feedback_flutter_macos_drive_screenshot`）。本批表现层复用批次1/2 现成减伤/蓄力题字，可能零表现层新增——若确认零新增则视觉验收免（逐字节复用已验收帧）。

---

## Self-Review 记录（写 plan 后自查）

**Spec 覆盖：** spec §3 模块1 → Task3（数据面）+Task4（注入+诊断）；§4 模块2 → Task1（数据面）+Task2（判定+透传）；§4.2 方案B → Task2 Step5（stepOne 边界判定，附「为何不能上层判」已在 spec §4.2）；§5 数值 → Task4/5 校准；§6 测试五坑 → 各 Task 确定性 via notifier + A/B + schema 红绿 + 分关注入；§7 红线 → Task6 文档 + 各 Task caps/≤8000 守；§8 批次 → Task1-6 一一对应（顺序按依赖重排：数据面 Task1/3 先于消费 Task2/4）。无遗漏。

**Placeholder 扫描：** 诊断测（Task4 Step6 / Task5 Step2）给的是骨架 + 明确断言列表 + 「照 cycle2_vulnerability_diagnostic_test 精确复刻」指引，因夹具与现有诊断测强耦合（真实 numbers.yaml + StageBattleSetup），逐行复刻现有体例比凭空写更准；关键断言不变量已具体给出（非「写个诊断测」）。夹具构造（buildPlayerTeam3 等）指向现有测试体例。可接受。

**类型一致性：** `StageWinCondition{type: StageWinConditionType, surviveTicksRequired: int?}` 全 Task 一致；`InnerDemonDef.mirrorVulnerabilityPerStage: Map<String,BossVulnerabilityDef>` + `mirrorChargeSkillId: String?` 一致；`buildMirrorEnemyTeam(..., SkillDef? mirrorChargeSkill)` / `_mirror(..., double? vulnerabilityMult, SkillDef? chargeSkill)` 一致；`BattleState.winCondition` / `startBattle(winCondition:)` / `BattleState.initial(winCondition:)` 一致。yaml key `ticks` → dart `surviveTicksRequired`（fromYaml 映射）一致。

**待实装者确认的外部符号（plan 已逐处标注）：** `BattleCharacter.availableSkills` 字段名 + copyWith 支持 vulnerabilityMult/chargeSkillId/availableSkills；`GameRepository.instance.getSkill` API；`SkillDef` import 路径 + `source` 合法取值；stage_entry_flow 三处 startBattle 是否覆盖心魔启动路径（若心魔另有入口，同步透传）。
