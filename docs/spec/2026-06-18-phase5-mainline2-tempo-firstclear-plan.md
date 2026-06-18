# 主线二 2.3 即放时序 + 2.5 首通门控 实现 Plan

> **For agentic workers:** REQUIRED SUB-SKILL: superpowers:subagent-driven-development(推荐)或 superpowers:executing-plans 逐 task 实现。步骤用 `- [ ]` 勾选跟踪。
> **本项目硬约束**:`flutter build/run -d macos` 禁加 `DEVELOPER_DIR=`(git 命令才用)。Isar 项目验收 `-d macos` 不 chrome。implementer 改动必跑**受影响全套测**(非只自测),防跨文件回归。引用 GDD 章节号前现 grep 核实。

**Goal:** 主线二把玩家拖招从「标记下次出手(pending)」改为「引擎级真插队·立即出手·预支 AP 归零」(2.3),并对每关每周目首通强制 interactive 模式让拖招层在场(2.5)。

**Architecture:** 2.3 在 `BattleStrategy` 加 `interveneNow`(抽象默认降级到 `requestUltimate`/pending 保 LightFoot/MassBattle 零回归;`DefaultGroundStrategy` override 为「借 AP=1000 → 复用单一战斗真相源 `_resolveAction` 结算 → 出手 `-=1000` 自然归零」)。`BattleNotifier.interveneNow` 用同一 `_rng` 委托;`_onSkillCommand` 改调它退掉 C5 rush。2.5 在 `auto_play_mode.dart` 加纯函数 `resolveAutoPlayModeWithFirstClear`,`_StageBattleHostState.initState` 据 `MainlineProgressService.isFirstClear` 算 `_mode`。

**Tech Stack:** Flutter Desktop / Riverpod 3.x / Isar / Dart immutable BattleState。

**确定性约束**:`interveneNow` 仅玩家 interactive 路径触发;auto/挂机无玩家输入 → 永不触发 → 既有 `battle_seed_determinism_test`(auto 无干预路径)天然不变。新增插队确定性测兜底插队路径自身确定。

**源**:`docs/spec/2026-06-18-phase5-mainline2-tempo-firstclear-design.md`。

---

## 文件结构

| 文件 | 责任 | 动作 |
|---|---|---|
| `lib/features/battle/domain/strategy/battle_strategy.dart` | 抽象 `interveneNow`(默认降级 pending) | Modify |
| `lib/features/battle/domain/strategy/default_ground_strategy.dart` | override `interveneNow`(借 AP + `_resolveAction`) | Modify |
| `lib/core/application/battle_providers.dart` | `BattleNotifier.interveneNow`(同 `_rng` 委托) | Modify |
| `lib/features/battle/presentation/battle_screen.dart:671-689` | `_onSkillCommand` 改调 `interveneNow` 退 C5 rush | Modify |
| `lib/features/battle/domain/auto_play_mode.dart` | `resolveAutoPlayModeWithFirstClear` 纯函数 | Modify |
| `lib/features/mainline/application/mainline_progress_service.dart` | `isFirstClear` 静态纯函数 | Modify |
| `lib/features/mainline/presentation/stage_entry_flow.dart:404-412` | initState 据首通算 `_mode` | Modify |
| `test/features/battle/domain/strategy/intervene_now_test.dart` | 纯 strategy 插队单测 | Create |
| `test/features/battle/intervene_determinism_test.dart` | notifier 插队确定性测 | Create |
| `test/features/battle/presentation/battle_drag_skill_test.dart` | 改写:拖招 → interveneNow spy | Modify |
| `test/features/battle/domain/auto_play_first_clear_test.dart` | 2.5 模式纯函数 + isFirstClear 单测 | Create |

---

## Task 1: strategy 层 `interveneNow`(引擎级真插队 · 预支)

**Files:**
- Modify: `lib/features/battle/domain/strategy/battle_strategy.dart`
- Modify: `lib/features/battle/domain/strategy/default_ground_strategy.dart`
- Test: `test/features/battle/domain/strategy/intervene_now_test.dart`

- [ ] **Step 1: 写失败测**

新建 `test/features/battle/domain/strategy/intervene_now_test.dart`:

```dart
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/defs/skill_def.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/battle/domain/battle_state.dart';
import 'package:wuxia_idle/features/battle/domain/strategy/default_ground_strategy.dart';

void main() {
  setUpAll(() async {
    await GameRepository.loadAllDefs(loader: (p) => File(p).readAsString());
  });

  const power = SkillDef(
    id: 'skill_iv_power',
    name: '截脉手',
    description: '插队测强力技',
    type: SkillType.powerSkill,
    powerMultiplier: 1500,
    internalForceCost: 100,
    cooldownTurns: 2,
    requiresManualTrigger: false,
    visualEffect: 'stub',
  );
  const normal = SkillDef(
    id: 'skill_iv_normal',
    name: '普攻',
    description: '插队测普攻',
    type: SkillType.normalAttack,
    powerMultiplier: 500,
    internalForceCost: 0,
    cooldownTurns: 0,
    requiresManualTrigger: false,
    visualEffect: 'stub',
  );

  BattleCharacter unit({
    required int charId,
    required int teamSide,
    required int slot,
    int ap = 0,
  }) =>
      BattleCharacter(
        characterId: charId,
        name: '$charId',
        realmTier: RealmTier.yiLiu,
        realmLayer: RealmLayer.qiMeng,
        school: TechniqueSchool.gangMeng,
        maxHp: 12000,
        currentHp: 12000,
        maxInternalForce: 2000,
        currentInternalForce: 2000,
        speed: 120,
        criticalRate: 0.0,
        evasionRate: 0.0,
        defenseRate: 0.1,
        totalEquipmentAttack: 700,
        mainCultivationLayer: CultivationLayer.daCheng,
        availableSkills: const <SkillDef>[power, normal],
        skillCooldowns: const {},
        activeBuffs: const [],
        actionPoint: ap,
        isAlive: true,
        teamSide: teamSide,
        slotIndex: slot,
      );

  test('AP 未满的玩家角色拖招 → 立即出手 + AP 归零 + 命中指定目标', () {
    const strat = DefaultGroundStrategy();
    final n = GameRepository.instance.numbers;
    final state = BattleState.initial(
      leftTeam: [unit(charId: 1, teamSide: 0, slot: 0, ap: 300)],
      rightTeam: [unit(charId: -1, teamSide: 1, slot: 0)],
    );

    final after = strat.interveneNow(
      state, 1, power,
      targetId: -1,
      n: n,
      rng: Random(7),
    );

    // 立即产生一条该角色出手的 action（用拖的招、对指定目标）。
    final acted = after.actionLog.where((a) => a.actorId == 1).toList();
    expect(acted, isNotEmpty, reason: '拖招应立即结算一次行动');
    expect(acted.last.skill?.id, 'skill_iv_power');
    expect(acted.last.targetId, -1);

    // 预支:出手后该角色 AP 归零（借 AP=1000 → _resolveAction -=1000）。
    final actor = after.leftTeam.firstWhere((c) => c.characterId == 1);
    expect(actor.actionPoint, 0, reason: '预支语义:出手后 AP 归零');

    // pending 已被消费，不残留。
    expect(after.pendingUltimates.containsKey(1), isFalse);
    expect(after.pendingTargets.containsKey(1), isFalse);
  });

  test('已死角色拖招 → noop（state 不变）', () {
    const strat = DefaultGroundStrategy();
    final n = GameRepository.instance.numbers;
    final dead = unit(charId: 1, teamSide: 0, slot: 0)
        .copyWith(currentHp: 0, isAlive: false);
    final state = BattleState.initial(
      leftTeam: [dead],
      rightTeam: [unit(charId: -1, teamSide: 1, slot: 0)],
    );
    final after = strat.interveneNow(state, 1, power, targetId: -1, n: n, rng: Random(7));
    expect(after.actionLog, isEmpty);
  });
}
```

- [ ] **Step 2: 跑测看红**

Run: `flutter test test/features/battle/domain/strategy/intervene_now_test.dart`
Expected: FAIL（`interveneNow` 未定义 / The method 'interveneNow' isn't defined）。

- [ ] **Step 3: 抽象类加默认降级**

`lib/features/battle/domain/strategy/battle_strategy.dart` 在 `requestUltimate` 声明之后(line 72 `}` 之前最后一个方法后)插入:

```dart
  /// 主线二 2.3 玩家拖招「即放·真插队」入口。
  ///
  /// **默认降级**:非 [DefaultGroundStrategy] 形态(LightFoot/MassBattle)退化为
  /// [requestUltimate](标记 pending 下次出手),零行为回归。[DefaultGroundStrategy]
  /// override 为真·立即插队结算(借 AP=1000 → `_resolveAction` 出手 -=1000 自然归零,
  /// 预支语义,净出手频率近不变 = 非数值杠杆,守 §5.4)。
  ///
  /// 仅玩家 interactive 路径调用;auto/挂机无玩家输入永不触发 → seed 确定性测
  /// (auto 无干预路径)不受影响。
  BattleState interveneNow(
    BattleState state,
    int characterId,
    SkillDef skill, {
    int? targetId,
    required NumbersConfig n,
    required Random rng,
  }) =>
      requestUltimate(state, characterId, skill, targetId: targetId);
```

- [ ] **Step 4: DefaultGroundStrategy override**

`lib/features/battle/domain/strategy/default_ground_strategy.dart` 在 `requestUltimate` 实现之后(line 181 `}` 之后、`// ─── 内部` 注释块之前)插入:

```dart
  /// 主线二 2.3:玩家拖招立即插队结算(预支语义)。
  ///
  /// 1. 该角色(player teamSide=0)不存活 / 战斗已结束 → noop 返原 state。
  /// 2. 置 pending(复用 [requestUltimate]:`BattleAI` 优先消费拖的招 + 指定目标)。
  /// 3. 借 AP:把该角色 actionPoint 设为正好 1000 → [_resolveAction] 内
  ///    `actionPoint -= 1000` 出手后自然归零(预支这一拍,随后等满周期再动)。
  /// 4. 立即调 [_resolveAction](唯一战斗真相源,消费传入的同一 [rng])结算。
  @override
  BattleState interveneNow(
    BattleState state,
    int characterId,
    SkillDef skill, {
    int? targetId,
    required NumbersConfig n,
    required Random rng,
  }) {
    if (state.isFinished) return state;
    final actor0 = _findById(state, characterId, 0);
    if (actor0 == null || !actor0.isAlive) return state;
    // 置 pending(requestUltimate 拒 normalAttack;拖招只发技能,UI 已 gate)。
    final pended = requestUltimate(state, characterId, skill, targetId: targetId);
    // 借 AP=1000:出手后 -=1000 = 0(预支归零)。
    final borrowed =
        _findById(pended, characterId, 0)!.copyWith(actionPoint: 1000);
    final left = pended.leftTeam.toList();
    final right = pended.rightTeam.toList();
    _replaceById(borrowed.teamSide == 0 ? left : right, borrowed);
    final s = pended.copyWith(
      leftTeam: List.unmodifiable(left),
      rightTeam: List.unmodifiable(right),
    );
    return _resolveAction(s, borrowed, n, rng);
  }
```

抽象类需 import `dart:math`(已有 line 1)与 `NumbersConfig`(已有 line 4)。default_ground 已 import 两者(line 1/5)。

- [ ] **Step 5: 跑测看绿**

Run: `flutter test test/features/battle/domain/strategy/intervene_now_test.dart`
Expected: PASS（2 测全绿）。

- [ ] **Step 6: 跑受影响 strategy 全套防回归**

Run: `flutter test test/features/battle/`
Expected: 全绿（既有 tick/stepOne/determinism/drag 不受新方法影响）。

- [ ] **Step 7: commit**

```bash
DEVELOPER_DIR=/Library/Developer/CommandLineTools git add lib/features/battle/domain/strategy/battle_strategy.dart lib/features/battle/domain/strategy/default_ground_strategy.dart test/features/battle/domain/strategy/intervene_now_test.dart
DEVELOPER_DIR=/Library/Developer/CommandLineTools git commit -m "feat(2.3): strategy 层 interveneNow 引擎级真插队(借AP预支归零)"
```

---

## Task 2: `BattleNotifier.interveneNow` + 插队确定性测

**Files:**
- Modify: `lib/core/application/battle_providers.dart:97-102`(在 `requestUltimate` 后)
- Test: `test/features/battle/intervene_determinism_test.dart`

- [ ] **Step 1: 写失败测**

新建 `test/features/battle/intervene_determinism_test.dart`:

```dart
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/application/battle_providers.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/defs/skill_def.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/battle/domain/battle_state.dart';

void main() {
  setUpAll(() async {
    await GameRepository.loadAllDefs(loader: (p) => File(p).readAsString());
  });

  const power = SkillDef(
    id: 'skill_ivd_power',
    name: '强力技',
    description: '插队确定性测',
    type: SkillType.powerSkill,
    powerMultiplier: 1500,
    internalForceCost: 100,
    cooldownTurns: 2,
    requiresManualTrigger: false,
    visualEffect: 'stub',
  );
  const normal = SkillDef(
    id: 'skill_ivd_normal',
    name: '普攻',
    description: '插队确定性测普攻',
    type: SkillType.normalAttack,
    powerMultiplier: 500,
    internalForceCost: 0,
    cooldownTurns: 0,
    requiresManualTrigger: false,
    visualEffect: 'stub',
  );

  BattleCharacter unit(int charId, int teamSide, int slot, int speed, int atk) =>
      BattleCharacter(
        characterId: charId,
        name: '$charId',
        realmTier: RealmTier.yiLiu,
        realmLayer: RealmLayer.qiMeng,
        school: TechniqueSchool.gangMeng,
        maxHp: 12000,
        currentHp: 12000,
        maxInternalForce: 2000,
        currentInternalForce: 2000,
        speed: speed,
        criticalRate: 0.5,
        evasionRate: 0.0,
        defenseRate: 0.1,
        totalEquipmentAttack: atk,
        mainCultivationLayer: CultivationLayer.daCheng,
        availableSkills: const <SkillDef>[power, normal],
        skillCooldowns: const {},
        activeBuffs: const [],
        actionPoint: 0,
        isAlive: true,
        teamSide: teamSide,
        slotIndex: slot,
      );

  String runOnce(int seed) {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final sub = container.listen(battleProvider, (_, _) {}, fireImmediately: true);
    addTearDown(sub.close);
    final notifier = container.read(battleProvider.notifier);
    notifier.startBattle(
      [unit(1, 0, 0, 130, 700), unit(2, 0, 1, 120, 700), unit(3, 0, 2, 110, 700)],
      [unit(-1, 1, 0, 105, 450), unit(-2, 1, 1, 100, 450), unit(-3, 1, 2, 95, 450)],
      seed: seed,
    );
    // 固定时点插队:先 advance 3 次,再对 charId=1 拖 power 打 -1,再跑完。
    for (var i = 0; i < 3 && !container.read(battleProvider).isFinished; i++) {
      notifier.advance();
    }
    notifier.interveneNow(1, power, targetId: -1);
    var guard = 0;
    while (!container.read(battleProvider).isFinished && guard < 3000) {
      notifier.advance();
      guard++;
    }
    final s = container.read(battleProvider);
    return '${s.result}#' +
        s.actionLog
            .map((a) =>
                '${a.tick}|${a.actorId}|${a.targetId}|${a.skill?.id}|${a.attackResult?.finalDamage}')
            .join(';');
  }

  test('红线:同 seed + 同插队时点两跑 actionLog + 胜负全等', () {
    final first = runOnce(20260618);
    final second = runOnce(20260618);
    expect(first.split(';').length, greaterThan(10));
    expect(first, equals(second),
        reason: 'interveneNow 走同一 seeded _rng,插队路径须确定');
  });
}
```

- [ ] **Step 2: 跑测看红**

Run: `flutter test test/features/battle/intervene_determinism_test.dart`
Expected: FAIL（`interveneNow` isn't defined for BattleNotifier）。

- [ ] **Step 3: BattleNotifier 加方法**

`lib/core/application/battle_providers.dart` 在 `requestUltimate`(line 102 `}`)之后插入:

```dart
  /// 主线二 2.3:玩家拖招立即插队出手(委托 strategy,消费本场同一 [_rng])。
  ///
  /// 仅玩家 interactive 路径(`_onSkillCommand` gate 后)调用。委托
  /// [BattleStrategy.interveneNow]:[DefaultGroundStrategy] 立即结算 + 预支归零,
  /// 其它形态降级 pending。战斗已结束则 noop。
  void interveneNow(int characterId, SkillDef skill, {int? targetId}) {
    if (state.isFinished) return;
    state = _strategy.interveneNow(
      state,
      characterId,
      skill,
      targetId: targetId,
      n: ref.read(numbersConfigProvider),
      rng: _rng,
    );
  }
```

- [ ] **Step 4: 跑测看绿**

Run: `flutter test test/features/battle/intervene_determinism_test.dart`
Expected: PASS。

- [ ] **Step 5: 既有确定性测不破**

Run: `flutter test test/features/battle/battle_seed_determinism_test.dart`
Expected: PASS（auto 无干预路径不变）。

- [ ] **Step 6: commit**

```bash
DEVELOPER_DIR=/Library/Developer/CommandLineTools git add lib/core/application/battle_providers.dart test/features/battle/intervene_determinism_test.dart
DEVELOPER_DIR=/Library/Developer/CommandLineTools git commit -m "feat(2.3): BattleNotifier.interveneNow + 插队确定性红线测"
```

---

## Task 3: 拖招 UI 改调 `interveneNow` + 改写 widget 测

**Files:**
- Modify: `lib/features/battle/presentation/battle_screen.dart:671-689`
- Test: `test/features/battle/presentation/battle_drag_skill_test.dart`

- [ ] **Step 1: 改写 widget 测(改前先看现状契约)**

现状 `_TestBattleNotifier`(line 36-48)override `advance`/`step` 为 no-op。新增 override `interveneNow` 作 spy(记录调用,不真结算,避免读 GameRepository 崩):

把 `_TestBattleNotifier` 改为:

```dart
class _TestBattleNotifier extends BattleNotifier {
  final BattleState _initial;
  _TestBattleNotifier(this._initial);

  /// spy:记录最近一次拖招立即出手的入参(不真结算 → 不读 GameRepository)。
  int? lastInterveneChar;
  SkillDef? lastInterveneSkill;
  int? lastInterveneTarget;
  int interveneCount = 0;

  @override
  BattleState build() => _initial;

  @override
  void advance({int maxConsecutiveTicks = 100}) {}

  @override
  void step() {}

  @override
  void interveneNow(int characterId, SkillDef skill, {int? targetId}) {
    lastInterveneChar = characterId;
    lastInterveneSkill = skill;
    lastInterveneTarget = targetId;
    interveneCount++;
  }
}
```

把 group『C4 群体技拖招触发』『C3+C4 单体拖招命中下发 targetId』『门控』里对 `notifier.state.pendingUltimates[1]` / `pendingTargets[1]` 的断言,改为对 spy 断言。逐条替换:

- aoe 拖招松手:
```dart
      expect(notifier.lastInterveneSkill?.id, 'aoe1');
      expect(notifier.lastInterveneChar, 1);
      expect(notifier.lastInterveneTarget, isNull,
          reason: 'aoe 拖招不指定目标，targetId 为空');
```
- 单体拖到敌头像:
```dart
      expect(notifier.lastInterveneSkill?.id, 'single1');
      expect(notifier.lastInterveneTarget, 11);
```
- 单体拖到空白(未命中):
```dart
      expect(notifier.interveneCount, 0, reason: '未命中敌不下发');
```
- 门控 false 点技能 / 拖单体:
```dart
      expect(notifier.interveneCount, 0);
```

- [ ] **Step 2: 跑测看红**

Run: `flutter test test/features/battle/presentation/battle_drag_skill_test.dart`
Expected: FAIL（`_onSkillCommand` 仍调 `requestUltimate`,spy 的 `interveneCount` 恒 0 / `lastInterveneSkill` 为 null）。

- [ ] **Step 3: 改 `_onSkillCommand`**

`lib/features/battle/presentation/battle_screen.dart` 把 `_onSkillCommand`(line 671-689)的 body 改为:

```dart
  void _onSkillCommand(int characterId, SkillDef skill, {int? targetId}) {
    if (!widget.allowPlayerIntervention) return; // 门控:群战/纯自动不接受指令
    final s = ref.read(battleProvider);
    BattleCharacter? c;
    for (final ch in s.leftTeam) {
      if (ch.characterId == characterId) {
        c = ch;
        break;
      }
    }
    if (c == null || !_isSkillReady(c, skill)) return; // CD/内力 pickup 门
    // 主线二 2.3:即放·真插队——立即出手(预支 AP 归零),不再标记 pending+C5 快进。
    ref
        .read(battleProvider.notifier)
        .interveneNow(characterId, skill, targetId: targetId);
    setState(() {}); // 清拖招态 + 反映出手
  }
```

更新该方法上方文档注释(line 660-670):把「走与大招相同的 requestUltimate 路径」「下发后进入立即触发(C5)... `_rushToActorId`」改述为「调 interveneNow 立即插队出手(预支 AP 归零),不再走 pending+C5 快进」。

- [ ] **Step 4: 跑测看绿**

Run: `flutter test test/features/battle/presentation/battle_drag_skill_test.dart`
Expected: PASS。

- [ ] **Step 5: 检查 `_rushToActorId` 是否变死代码**

Run: `grep -n "_rushToActorId" lib/features/battle/presentation/battle_screen.dart`
若除声明外仅剩 auto 观战提速引用 → 保留(留 auto 提速);若 `_onSkillCommand` 是唯一写入点且已删 → 连带删声明 + 读取处避免 analyze 警告。按 grep 结果处理,**不删与拖招无关的既有逻辑**。

- [ ] **Step 6: 跑战斗 presentation 全套防回归**

Run: `flutter test test/features/battle/presentation/`
Expected: 全绿。

- [ ] **Step 7: commit**

```bash
DEVELOPER_DIR=/Library/Developer/CommandLineTools git add lib/features/battle/presentation/battle_screen.dart test/features/battle/presentation/battle_drag_skill_test.dart
DEVELOPER_DIR=/Library/Developer/CommandLineTools git commit -m "feat(2.3): 拖招 UI 改调 interveneNow 即放真插队 + 改写 widget 测"
```

---

## Task 4: 2.5 首通门控(首通强制 interactive)

**Files:**
- Modify: `lib/features/mainline/application/mainline_progress_service.dart`(加 `isFirstClear`)
- Modify: `lib/features/battle/domain/auto_play_mode.dart`(加 `resolveAutoPlayModeWithFirstClear`)
- Modify: `lib/features/mainline/presentation/stage_entry_flow.dart:404-412`
- Test: `test/features/battle/domain/auto_play_first_clear_test.dart`

- [ ] **Step 1: 写失败测**

新建 `test/features/battle/domain/auto_play_first_clear_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/battle/domain/auto_play_mode.dart';
import 'package:wuxia_idle/features/mainline/application/mainline_progress_service.dart';
import 'package:wuxia_idle/features/mainline/domain/mainline_progress.dart';

void main() {
  group('isFirstClear', () {
    test('cycleKey 不在 clearedStageCycleKeys → 首通 true', () {
      final p = MainlineProgress()..clearedStageCycleKeys = ['stage_01_02#1'];
      expect(MainlineProgressService.isFirstClear(p, 'stage_01_03', 1), isTrue);
    });
    test('cycleKey 已在 → 非首通 false', () {
      final p = MainlineProgress()..clearedStageCycleKeys = ['stage_01_03#1'];
      expect(MainlineProgressService.isFirstClear(p, 'stage_01_03', 1), isFalse);
    });
    test('同关不同周目各自独立', () {
      final p = MainlineProgress()..clearedStageCycleKeys = ['stage_01_03#1'];
      expect(MainlineProgressService.isFirstClear(p, 'stage_01_03', 2), isTrue,
          reason: '周目2 未通 → 仍首通');
    });
  });

  group('resolveAutoPlayModeWithFirstClear', () {
    test('首通 → 强制 interactive(无视 global auto)', () {
      final m = resolveAutoPlayModeWithFirstClear(
          isFirstClear: true, override: null, globalDefault: true);
      expect(m, AutoPlayMode.interactive);
    });
    test('已通 + global auto → auto', () {
      final m = resolveAutoPlayModeWithFirstClear(
          isFirstClear: false, override: null, globalDefault: true);
      expect(m, AutoPlayMode.auto);
    });
    test('已通 + per-stage override interactive → interactive', () {
      final m = resolveAutoPlayModeWithFirstClear(
          isFirstClear: false, override: false, globalDefault: true);
      expect(m, AutoPlayMode.interactive);
    });
  });
}
```

- [ ] **Step 2: 跑测看红**

Run: `flutter test test/features/battle/domain/auto_play_first_clear_test.dart`
Expected: FAIL（`isFirstClear` / `resolveAutoPlayModeWithFirstClear` 未定义）。

- [ ] **Step 3: 加 `isFirstClear` 静态纯函数**

`lib/features/mainline/application/mainline_progress_service.dart` 在 `highestClearedCycle`(line 169-179)之后插入:

```dart
  /// 主线二 2.5 首通门控:该 (stageId, cycle) 是否尚未通关(首通)。
  /// 数据源 [MainlineProgress.clearedStageCycleKeys](cycleKey=`'$stageId#$cycle'`,
  /// recordVictory 各周目幂等写入)。首通=该 cycleKey 不在集合中。
  static bool isFirstClear(MainlineProgress p, String stageId, int cycle) =>
      !p.clearedStageCycleKeys.contains('$stageId#$cycle');
```

- [ ] **Step 4: 加 `resolveAutoPlayModeWithFirstClear`**

`lib/features/battle/domain/auto_play_mode.dart` 在 `resolveAutoPlayMode`(末尾 line 25 `;` 之后)追加:

```dart

/// 主线二 2.5 首通门控:某关某周目**首通强制 [AutoPlayMode.interactive]**(挂拖招
/// 层,无视 auto 设置);首通后退回 [resolveAutoPlayMode] 按 override/global 决策。
///
/// 战斗仍自动连播,门控只决定"拖招层在不在",非速度 buff,守 GDD §5.5 在线=离线。
AutoPlayMode resolveAutoPlayModeWithFirstClear({
  required bool isFirstClear,
  required bool? override,
  required bool globalDefault,
}) =>
    isFirstClear
        ? AutoPlayMode.interactive
        : resolveAutoPlayMode(override: override, globalDefault: globalDefault);
```

- [ ] **Step 5: 跑测看绿**

Run: `flutter test test/features/battle/domain/auto_play_first_clear_test.dart`
Expected: PASS（6 测全绿）。

- [ ] **Step 6: initState 接入首通门控**

`lib/features/mainline/presentation/stage_entry_flow.dart` 把 initState 入口决策段(line 404-413)改为:

```dart
        // ── 入口决策:首通门控(2.5)优先 → 否则 per-stage override + 全局 ──
        final override =
            await ref.read(stageAutoPlayPrefServiceProvider).override(_battleKey);
        if (!mounted) return;
        final global =
            (await ref.read(gameplaySettingsProvider.future)).autoPlayDefault;
        if (!mounted) return;
        // 2.5:本场 (stageId, cycle) 首通前强制 interactive(拖招层在场);
        // 首通后按设置可纯 auto 复刷。GameRepository/Isar 未 ready 时兜底非首通
        // (按设置,零回归,test 注入路径不触发)。
        final progress = await MainlineProgressService(isar: IsarSetup.instance)
            .getOrCreate(saveDataId: IsarSetup.currentSlotId);
        if (!mounted) return;
        final firstClear = MainlineProgressService.isFirstClear(
            progress, widget.stage.id, widget.targetCycle);
        setState(() => _mode = resolveAutoPlayModeWithFirstClear(
              isFirstClear: firstClear,
              override: override,
              globalDefault: global,
            ));
```

确认 import:`stage_entry_flow.dart` 已 import `mainline_progress_service.dart`(line 50)与 `isar_setup.dart`(line 10);`auto_play_mode.dart` 已 import(line 25)。`resolveAutoPlayModeWithFirstClear` 与 `resolveAutoPlayMode` 同文件,无新 import。

- [ ] **Step 7: 跑 mainline + 受影响 stage_entry 全套**

Run: `flutter test test/features/mainline/`
Expected: 全绿(getOrCreate 路径既有,新增首通分支不破既有 stage flow 测;若有 stage flow widget 测断言 _mode,据新语义更新)。

- [ ] **Step 8: commit**

```bash
DEVELOPER_DIR=/Library/Developer/CommandLineTools git add lib/features/mainline/application/mainline_progress_service.dart lib/features/battle/domain/auto_play_mode.dart lib/features/mainline/presentation/stage_entry_flow.dart test/features/battle/domain/auto_play_first_clear_test.dart
DEVELOPER_DIR=/Library/Developer/CommandLineTools git commit -m "feat(2.5): 首通门控——首通强制 interactive(拖招层在场)"
```

---

## Task 5: 全量验证 + 收尾

- [ ] **Step 1: 全量 analyze**

Run: `flutter analyze`
Expected: `No issues found!`。有 warning/error 必修(尤其 Task 3 Step 5 的 `_rushToActorId` 死代码)。

- [ ] **Step 2: 全量测**

Run: `flutter test`
Expected: 全绿(baseline 2356 测 +1 skip,本批净增 ~11 测:intervene_now 2 + determinism 1 + drag 改写不增量 + auto_play_first_clear 6 + 可能的 stage flow 调整)。**贴出真实通过数,不转抄。**

- [ ] **Step 3: 记 baseline delta**

确认无回归:新增测数 = 通过总数 − 2356。若 < 预期,排查被改写测是否漏断言。

- [ ] **Step 4: 视觉验收(真机)**

`flutter run -d macos`(**禁加 DEVELOPER_DIR**),进一关手动战斗:
- 验 2.3:拖技能松手 → 该角色**立即出手**(不再等下一自然轮),日志即时出现其 action;连拖多角色各自即时出手。
- 验 2.5:进一个**未通**的新关 → 即便全局 auto,拖招层在场(可拖);进**已通**关 → 按设置(global auto 则纯自动无拖招层)。
- 走 memory `feedback_visual_acceptance`:Claude 自截 / 需要时 Codex 派单(写死目标路由 + 控件位)。

- [ ] **Step 5: 更新 PROGRESS.md 续23 + 收尾**

PROGRESS 顶段加续23 一行(commit 区间 + 测数实测 + 关键决策:2.3 借AP预支 / 2.5 首通强制 interactive / 修正 spec 两 stale 前提)。

---

## Self-Review(plan vs spec 覆盖核对)

- **2.3 机制(预支+AP归零)**:Task 1 借 AP=1000 + `_resolveAction` ✅;Task 1 测断言 AP==0 ✅。
- **2.3 仅 interactive 生效 / auto 不碰**:Task 3 `_onSkillCommand` 门 `allowPlayerIntervention` ✅;Task 2 Step 5 既有 determinism 测不破 ✅。
- **2.3 CD/内力 pickup 拦**:Task 3 保留 `_isSkillReady` 门 ✅。
- **2.3 无额外次数拦截**:未加 throttle ✅(用户拍板)。
- **2.3 插队确定性测**:Task 2 新测 ✅。
- **2.5 首通强制 interactive / 首通后按设置**:Task 4 `resolveAutoPlayModeWithFirstClear` + initState ✅;3 模式分支测 ✅。
- **2.5 仅主线**:数据源 `clearedStageCycleKeys`,未碰 tower ✅。
- **红线**:2.3 预支非频率杠杆 + 2.5 模式解锁非速度 buff,均不动伤害公式/数值 ✅。
- **类型一致**:`interveneNow(state, characterId, skill, {targetId, n, rng})` 抽象/override/notifier/UI 四处签名一致;`isFirstClear(p, stageId, cycle)` / `resolveAutoPlayModeWithFirstClear({isFirstClear, override, globalDefault})` 定义与调用一致 ✅。
- **占位扫描**:无 TBD/TODO;Task 3 Step 5 `_rushToActorId` 处理按 grep 结果(条件分支,非占位)✅。
