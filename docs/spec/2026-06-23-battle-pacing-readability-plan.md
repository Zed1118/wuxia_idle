# 战斗节奏与可读性打磨（A+C）实现计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 留 ATB，常速战斗改「一拍一个行动」+ 关键帧顿一下，治「看不清/太快」四症，快进档不动。

**Architecture:** 新增 `BattleNotifier.advanceOneAction()`（循环 `stepOne` 到 actionLog 恰好 +1）取代常速 Timer 的整 tick `advance()`；确定性逐位不变（同 seed 同 rng 序）。关键帧（`BattleLog.isKeyAction`）复用现有 hit-stop 通道延长顿帧。纯表现层 / 播放循环，0 改引擎/数值规则/重放/GDD。

**Tech Stack:** Flutter + Riverpod 3 Notifier；战斗 domain 纯 Dart；numbers.yaml 配置；flutter_test。

**spec:** `docs/spec/2026-06-23-battle-pacing-readability-design.md`

---

## File Structure

- `lib/core/application/battle_providers.dart` — 加 `advanceOneAction()`（紧接 `advance()` 后，~L145）。
- `lib/data/numbers_config.dart` — `AnimationNumbers` 加 `keyMomentHoldMs` 字段 + fromYaml + defaults；retune `actionIntervalMs`/`damagePopupMs` 默认值。
- `data/numbers.yaml` — `animation` 段加 `key_moment_hold_ms`、调 `action_interval_ms`/`damage_popup_ms`。
- `lib/features/battle/presentation/battle_screen.dart` — 常速 Timer 改驱动 `advanceOneAction()`（快进留 `advance()`）；`_playAction` 关键帧延长 hold；加纯函数 `playbackHoldMs(...)`。
- `test/features/battle/battle_advance_one_action_test.dart`（新）— advanceOneAction 单调性 + 确定性等价。
- `test/data/animation_numbers_test.dart` — 补 `key_moment_hold_ms` fromYaml/默认测。
- `test/features/battle/presentation/playback_hold_test.dart`（新）— `playbackHoldMs` 纯函数测。

---

## Task 1: `BattleNotifier.advanceOneAction()`（逐 actor 单步 + 确定性）

**Files:**
- Modify: `lib/core/application/battle_providers.dart`（紧接 `advance()` 结束的 `}` 后，约 L145）
- Test: `test/features/battle/battle_advance_one_action_test.dart`（新建）

- [ ] **Step 1: 写失败测**

新建 `test/features/battle/battle_advance_one_action_test.dart`。复用 `battle_step_one_test.dart` 的队伍/单位/摘要体例（criticalRate 0.5 制造 rng 分歧）：

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
    await GameRepository.loadAllDefs(
      loader: (path) => File(path).readAsString(),
    );
  });

  const normal = SkillDef(
    id: 'skill_adv1_normal', name: '普攻', description: 'adv1 普攻',
    type: SkillType.normalAttack, powerMultiplier: 500, internalForceCost: 0,
    cooldownTurns: 0, requiresManualTrigger: false, visualEffect: 'stub',
  );
  const power = SkillDef(
    id: 'skill_adv1_power', name: '强力技', description: 'adv1 强力技',
    type: SkillType.powerSkill, powerMultiplier: 1500, internalForceCost: 100,
    cooldownTurns: 2, requiresManualTrigger: false, visualEffect: 'stub',
  );

  BattleCharacter unit({
    required int charId, required int teamSide, required int slot,
    required int speed, required int equipAttack,
  }) =>
      BattleCharacter(
        characterId: charId, name: '$charId', realmTier: RealmTier.yiLiu,
        realmLayer: RealmLayer.qiMeng, school: TechniqueSchool.gangMeng,
        maxHp: 12000, currentHp: 12000, maxInternalForce: 2000,
        currentInternalForce: 2000, speed: speed, criticalRate: 0.5,
        evasionRate: 0.0, defenseRate: 0.1, totalEquipmentAttack: equipAttack,
        mainCultivationLayer: CultivationLayer.daCheng,
        availableSkills: const <SkillDef>[power, normal],
        skillCooldowns: const {}, activeBuffs: const [], actionPoint: 0,
        isAlive: true, teamSide: teamSide, slotIndex: slot,
      );

  List<BattleCharacter> leftTeam() => [
        unit(charId: 1, teamSide: 0, slot: 0, speed: 130, equipAttack: 700),
        unit(charId: 2, teamSide: 0, slot: 1, speed: 120, equipAttack: 700),
        unit(charId: 3, teamSide: 0, slot: 2, speed: 110, equipAttack: 700),
      ];
  List<BattleCharacter> rightTeam() => [
        unit(charId: -1, teamSide: 1, slot: 0, speed: 105, equipAttack: 450),
        unit(charId: -2, teamSide: 1, slot: 1, speed: 100, equipAttack: 450),
        unit(charId: -3, teamSide: 1, slot: 2, speed: 95, equipAttack: 450),
      ];

  String summarize(BattleState s) =>
      '${s.result}#${s.actionLog.map((a) => '${a.tick}|${a.actorId}|${a.targetId}|${a.skill?.id}|${a.attackResult?.finalDamage}|${a.interrupted}').join(';')}';

  String runVia(int seed, {required bool oneAction}) {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final sub = container.listen(battleProvider, (_, _) {}, fireImmediately: true);
    addTearDown(sub.close);
    final notifier = container.read(battleProvider.notifier);
    notifier.startBattle(leftTeam(), rightTeam(), seed: seed);
    var guard = 0;
    while (!container.read(battleProvider).isFinished && guard < 30000) {
      if (oneAction) {
        notifier.advanceOneAction();
      } else {
        notifier.advance();
      }
      guard++;
    }
    return summarize(container.read(battleProvider));
  }

  test('advanceOneAction 每次调用 actionLog 恰好 +1（或战斗已结束）', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final sub = container.listen(battleProvider, (_, _) {}, fireImmediately: true);
    addTearDown(sub.close);
    final notifier = container.read(battleProvider.notifier);
    notifier.startBattle(leftTeam(), rightTeam(), seed: 999);

    var prevLen = container.read(battleProvider).actionLog.length;
    var calls = 0;
    while (!container.read(battleProvider).isFinished && calls < 30000) {
      notifier.advanceOneAction();
      final len = container.read(battleProvider).actionLog.length;
      if (container.read(battleProvider).isFinished && len == prevLen) break;
      expect(len, prevLen + 1,
          reason: '单次 advanceOneAction 只产出一个 action（自动跳过空 tick 边界）');
      prevLen = len;
      calls++;
    }
    expect(calls, greaterThan(10), reason: '防空过：需足够多产出步');
  });

  test('红线：advanceOneAction 逐拍跑完 == advance 整 tick 跑完（同 seed 全等）', () {
    final viaOne = runVia(2468, oneAction: true);
    final viaAdvance = runVia(2468, oneAction: false);
    expect(viaOne.split(';').length, greaterThan(10),
        reason: '防空过：需足够多 action 暴露 rng 顺序不一致');
    expect(viaOne, equals(viaAdvance),
        reason: 'advanceOneAction 与 advance 单一 seeded rng 下复刻同一场战斗');
  });
}
```

- [ ] **Step 2: 跑测确认失败**

Run: `flutter test test/features/battle/battle_advance_one_action_test.dart`
Expected: FAIL —「The method 'advanceOneAction' isn't defined」。

- [ ] **Step 3: 实现 `advanceOneAction`**

在 `battle_providers.dart` 的 `advance()` 方法 `}`（约 L145）之后插入：

```dart
  /// 常速 UI 播放驱动：推进到「下一个 action」即停（区别于 [advance] 排空整
  /// tick）。循环 [BattleStrategy.stepOne] 直到 actionLog 恰好 +1 或战斗结束，
  /// 自动跳过无人出手的 tick 边界空步。复用本场单一 seeded [_rng]，逐 action
  /// rng 消费顺序与 [advance] / [step] 完全一致 → 战斗结果逐位不变
  /// （`battle_advance_one_action_test` 红线锁死）。
  ///
  /// [maxConsecutiveSteps] 兜底：境界差 3+ 近免疫时连续空 tick 也会被
  /// strategy maxTicks 兜住，但单次调用不该卡死 UI 线程，限到 300
  /// （> [advance] 的 100：stepOne 含边界步 + 逐 actor 出队步，粒度更细）。
  void advanceOneAction({int maxConsecutiveSteps = 300}) {
    if (state.isFinished) return;
    final n = ref.read(numbersConfigProvider);
    var s = state;
    final originalLogLen = s.actionLog.length;
    var consumed = 0;
    while (s.actionLog.length == originalLogLen &&
        !s.isFinished &&
        consumed < maxConsecutiveSteps) {
      s = _strategy.stepOne(s, n, rng: _rng);
      consumed++;
    }
    state = s;
  }
```

- [ ] **Step 4: 跑测确认通过**

Run: `flutter test test/features/battle/battle_advance_one_action_test.dart`
Expected: PASS（两测全绿）。

- [ ] **Step 5: 提交**

```bash
git add lib/core/application/battle_providers.dart test/features/battle/battle_advance_one_action_test.dart
git commit -m "feat: BattleNotifier.advanceOneAction 逐 actor 单步播放(确定性等价 advance)"
```

---

## Task 2: `AnimationNumbers.keyMomentHoldMs` 配置字段

**Files:**
- Modify: `lib/data/numbers_config.dart`（`AnimationNumbers` 字段 ~L1503 / `defaults` ~L1531 / `fromYaml` ~L1550）
- Modify: `data/numbers.yaml`（`animation` 段 ~L1379）
- Test: `test/data/animation_numbers_test.dart`

- [ ] **Step 1: 写失败测**

在 `test/data/animation_numbers_test.dart` 末尾 `}` 前补：

```dart
  test('AnimationNumbers.defaults 含 keyMomentHoldMs', () {
    expect(AnimationNumbers.defaults.keyMomentHoldMs, 400);
  });

  test('fromYaml 解析 key_moment_hold_ms', () {
    final n = AnimationNumbers.fromYaml(<String, dynamic>{
      'attack_rush_ms': 1, 'attack_hold_ms': 1, 'attack_retreat_ms': 1,
      'attack_rush_offset_px': 1, 'damage_popup_float_px': 1,
      'damage_popup_ms': 1, 'action_interval_ms': 1,
      'fast_forward_interval_ms': 1, 'shake_offset_px': 1,
      'shake_duration_ms': 1, 'critical_font_scale': 1,
      'key_moment_hold_ms': 555,
    });
    expect(n.keyMomentHoldMs, 555);
  });

  test('fromYaml 缺 key_moment_hold_ms 走默认 400', () {
    final n = AnimationNumbers.fromYaml(<String, dynamic>{
      'attack_rush_ms': 1, 'attack_hold_ms': 1, 'attack_retreat_ms': 1,
      'attack_rush_offset_px': 1, 'damage_popup_float_px': 1,
      'damage_popup_ms': 1, 'action_interval_ms': 1,
      'fast_forward_interval_ms': 1, 'shake_offset_px': 1,
      'shake_duration_ms': 1, 'critical_font_scale': 1,
    });
    expect(n.keyMomentHoldMs, 400);
  });
```

- [ ] **Step 2: 跑测确认失败**

Run: `flutter test test/data/animation_numbers_test.dart`
Expected: FAIL —「getter 'keyMomentHoldMs' isn't defined」。

- [ ] **Step 3: 实现字段**

`numbers_config.dart`：

(a) 字段区（`hitFlashMs` 声明后）加：
```dart
  /// 关键帧（暴击/大招/合一/破招/击杀）命中后的额外顿帧时长（ms）。常速播放
  /// 下与 impact_feedback 的 hitStopMs 取大者，给「这一下重要」留读条停顿。
  /// 快进/拖招态不触发（沿 hit-stop 既有跳过约定）。
  final int keyMomentHoldMs;
```

(b) 构造函数参数列表（`required this.hitFlashMs,` 后）加：
```dart
    this.keyMomentHoldMs = 400,
```

(c) `defaults` 常量（`hitFlashMs: 150,` 后）加：
```dart
    keyMomentHoldMs: 400,
```

(d) `fromYaml`（`hitFlashMs: ...` 行后）加：
```dart
      keyMomentHoldMs: (y['key_moment_hold_ms'] as num?)?.toInt() ?? 400,
```

`data/numbers.yaml` 的 `animation` 段，`hit_flash_ms: 150` 行后加：
```yaml
  key_moment_hold_ms: 400     # 关键帧(暴击/大招/合一/破招/击杀)额外顿帧
```

- [ ] **Step 4: 跑测确认通过**

Run: `flutter test test/data/animation_numbers_test.dart`
Expected: PASS（全绿）。

- [ ] **Step 5: 提交**

```bash
git add lib/data/numbers_config.dart data/numbers.yaml test/data/animation_numbers_test.dart
git commit -m "feat: AnimationNumbers 加 keyMomentHoldMs(关键帧顿帧时长 · 默认400)"
```

---

## Task 3: `playbackHoldMs` 纯函数（关键帧 hold 计算）

**Files:**
- Modify: `lib/features/battle/presentation/battle_screen.dart`（文件顶层、`class` 外加纯函数）
- Test: `test/features/battle/presentation/playback_hold_test.dart`（新建）

- [ ] **Step 1: 写失败测**

新建 `test/features/battle/presentation/playback_hold_test.dart`：

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/battle/presentation/battle_screen.dart';

void main() {
  test('非关键帧 → 用 profile hitStop', () {
    expect(playbackHoldMs(isKey: false, profileHitStopMs: 120, keyMomentHoldMs: 400), 120);
  });
  test('关键帧 → 取 profile 与 keyMomentHold 的大者', () {
    expect(playbackHoldMs(isKey: true, profileHitStopMs: 120, keyMomentHoldMs: 400), 400);
    expect(playbackHoldMs(isKey: true, profileHitStopMs: 500, keyMomentHoldMs: 400), 500);
  });
}
```

- [ ] **Step 2: 跑测确认失败**

Run: `flutter test test/features/battle/presentation/playback_hold_test.dart`
Expected: FAIL —「'playbackHoldMs' isn't defined」。

- [ ] **Step 3: 实现纯函数**

在 `battle_screen.dart` 顶层（import 之后、第一个 class 之前）加：

```dart
/// 常速播放命中后的顿帧时长：关键帧（暴击/大招/合一/破招/击杀）取
/// `profileHitStopMs` 与 `keyMomentHoldMs` 的大者，否则用 `profileHitStopMs`。
/// 纯函数便于单测（节奏手感本身走真机目检）。
int playbackHoldMs({
  required bool isKey,
  required int profileHitStopMs,
  required int keyMomentHoldMs,
}) =>
    isKey && keyMomentHoldMs > profileHitStopMs
        ? keyMomentHoldMs
        : profileHitStopMs;
```

- [ ] **Step 4: 跑测确认通过**

Run: `flutter test test/features/battle/presentation/playback_hold_test.dart`
Expected: PASS。

- [ ] **Step 5: 提交**

```bash
git add lib/features/battle/presentation/battle_screen.dart test/features/battle/presentation/playback_hold_test.dart
git commit -m "feat: playbackHoldMs 纯函数(关键帧取顿帧大者)"
```

---

## Task 4: battle_screen 接线（常速逐拍 + 关键帧 hold）

**Files:**
- Modify: `lib/features/battle/presentation/battle_screen.dart`（`_startTimer` ~L380 / `_playAction` 顿帧 ~L514-518 / import）

- [ ] **Step 1: 常速 Timer 改驱动 advanceOneAction**

`_startTimer` 内 `Timer.periodic` 回调（约 L380-383）由：
```dart
    _playTimer = Timer.periodic(Duration(milliseconds: interval), (_) {
      if (!mounted) return;
      ref.read(battleProvider.notifier).advance();
    });
```
改为（快进/拖招态保留整 tick drain，常速逐拍）：
```dart
    _playTimer = Timer.periodic(Duration(milliseconds: interval), (_) {
      if (!mounted) return;
      final notifier = ref.read(battleProvider.notifier);
      if (rushing) {
        notifier.advance();
      } else {
        notifier.advanceOneAction();
      }
    });
```
（`rushing` 已在上文 L376 定义，闭包可捕获。）

- [ ] **Step 2: `_playAction` 关键帧延长 hold**

确认文件顶部已 import：`import '../domain/battle_log.dart';`（无则加）。
`_playAction` 的 hit-stop 块（约 L514-518）由：
```dart
        if (!_isFastForward && _rushToActorId == null) {
          _impactShakeAmplitude = profile.shakeMagnitude;
          _shakeCtrl.forward(from: 0.0);
          _applyHitStop(profile.hitStopMs);
        }
```
改为：
```dart
        if (!_isFastForward && _rushToActorId == null) {
          _impactShakeAmplitude = profile.shakeMagnitude;
          _shakeCtrl.forward(from: 0.0);
          _applyHitStop(playbackHoldMs(
            isKey: BattleLog.isKeyAction(action, s),
            profileHitStopMs: profile.hitStopMs,
            keyMomentHoldMs: widget.animConfig.keyMomentHoldMs,
          ));
        }
```

- [ ] **Step 3: 跑战斗 presentation 测族确认不回归**

Run: `flutter test test/features/battle/presentation/`
Expected: PASS（pause/log/drag/defer_victory 等播放路径测全绿）。

- [ ] **Step 4: 提交**

```bash
git add lib/features/battle/presentation/battle_screen.dart
git commit -m "feat: 常速逐拍播放(advanceOneAction)+关键帧延长顿帧"
```

---

## Task 5: 节奏数值 retune（飘字不跨拍）

**Files:**
- Modify: `data/numbers.yaml`（`animation` 段）/ `lib/data/numbers_config.dart`（`AnimationNumbers.defaults` 同步）

- [ ] **Step 1: 调值（初值，真机校准前的起点）**

`data/numbers.yaml` `animation` 段：
```yaml
  damage_popup_ms: 700         # 飘字总时长（含淡出）；≤ action_interval_ms 防跨拍渗漏
  action_interval_ms: 1000     # 正常速度：单拍给够攻击动画(400)+飘字读完
```
`numbers_config.dart` `AnimationNumbers.defaults` 同步：`damagePopupMs: 700,` / `actionIntervalMs: 1000,`（与 yaml 一致，沿「defaults 与 numbers.yaml 保持一致」契约）。

- [ ] **Step 2: 跑相关 widget 测确认时序不破**

Run: `flutter test test/features/battle/presentation/ test/data/animation_numbers_test.dart`
Expected: PASS（如某 widget 测 hardcode 旧 800 时序导致 pumpAndSettle 偏差，按实际 fail 调该测的等待时长，不改回数值）。

- [ ] **Step 3: 提交**

```bash
git add data/numbers.yaml lib/data/numbers_config.dart
git commit -m "balance: 战斗播放节奏 retune(action_interval 800→1000 / popup→700 防跨拍)"
```

---

## Task 6: 全量验证 + 真机校准

- [ ] **Step 1: analyze + 全量测**

Run: `flutter analyze`（Expected: No issues found）
Run: `flutter test`（Expected: 全绿，仅基线 +1 skip；新增 advanceOneAction/animation/playback_hold 测族绿；战斗确定性/balance 测零回归）

- [ ] **Step 2: 真机目检校准**

Run: `flutter run -d macos`（或 `VISUAL_ROUTE` 战斗路由）。常速跑 3v3，验四症：
① 逐拍单动作不再 burst（同 tick 多人就绪也逐个亮）
② 每拍看清谁→谁·招·伤害（拍长够读）
③ 特效不糊成一团（单拍单命中反馈，飘字不跨拍）
④ 关键帧（暴击/大招/破招/击杀）明显「顿一下+题字」
快进档行为不变（仍秒过）。
据手感微调 `numbers.yaml` 的 `action_interval_ms` / `key_moment_hold_ms` / `damage_popup_ms`（连带同步 `AnimationNumbers.defaults`），再跑 Step 1。

- [ ] **Step 3: 收尾提交（若校准有改值）**

```bash
git add data/numbers.yaml lib/data/numbers_config.dart
git commit -m "balance: 真机校准战斗播放节奏值"
```

---

## 范围外（不做）

- 改 ATB→回合制 / 任何引擎·伤害数值·重放·GDD 战斗模型改动。
- 出战编成 UI。
- 新增战斗机制（破招/协同内容）。
- 拍内特效错峰（症状③主因＝跨行动重叠，A 已治；单命中内 闪/震/飘字 共现合理，不拆）。
