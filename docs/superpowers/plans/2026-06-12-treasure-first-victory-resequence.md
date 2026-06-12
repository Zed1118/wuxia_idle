# 战斗结束时序重排:爆品当第一高潮 — 实装计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 让战斗胜利后爆品成为第一高潮——把胜利结果反馈从 `BattleScreen` 下放到 flow 层,flow 按已 roll 出的掉落分档(有重器→爆品镜头 / 普通·无掉落→简版勝淡入淡出),统计搬到结算 dialog。

**Architecture:** 纯表现层时序搬移,**不碰** `resolve`/roll/rng/数值/战斗数学。核心:`BattleScreen` 加 `deferVictoryToCaller` 开关,胜利时不弹 `VictoryOverlay` 而直接回调让 flow 接管;新增简版勝 widget `VictorySealFlash` + 共享分档函数 `presentVictoryCeremony`;统计抽纯函数 `BattleStatsSummary` 并搬进 dialog。两条 flow(mainline `stage_entry_flow` / tower `tower_entry_flow`)对称改造。

**Tech Stack:** Flutter Desktop · Riverpod 3.x · Isar · `flutter test` / `flutter analyze`。

**Spec:** `docs/superpowers/specs/2026-06-12-treasure-first-victory-resequence-design.md`

---

## Prerequisites(执行者首次在此 worktree 跑测前)

- [ ] `.g.dart` 是 gitignored,fresh worktree 必须先生成:
  ```bash
  dart run build_runner build --delete-conflicting-outputs
  ```
- [ ] fresh worktree 的 `libisar.dylib` 可能截断(已知坑)。若 setUpAll 批量 dlopen 失败,从主仓拷:
  ```bash
  cp "/Users/a10506/Desktop/Projects/挂机武侠/libisar.dylib" "$(pwd)/libisar.dylib"
  ```
- [ ] 确认基线绿(可选):`flutter analyze` 应 0 issue。

---

## File Structure

| 文件 | 职责 | Task |
|---|---|---|
| `lib/features/battle/domain/battle_stats.dart` **[新建]** | `BattleStatsSummary` 纯函数(总伤害/暴击/回合,从 `BattleState.actionLog` 派生) | 1 |
| `lib/features/battle/presentation/battle_screen.dart` **[改]** | `deferVictoryToCaller` 开关 + `_showResultDialog` 胜利 defer 分支 + 改用 `BattleStatsSummary` | 2 |
| `lib/features/battle/presentation/victory_ceremony.dart` **[新建]** | `VictorySealFlash`(简版勝)+ `showVictorySealFlash` + `presentVictoryCeremony`(分档) | 3, 4 |
| `lib/features/equipment/presentation/treasure_drop_overlay.dart` **[改]** | `playTreasureDropIfAny` 返回 `bool`(是否播了爆品) | 4 |
| `lib/features/mainline/presentation/stage_victory_dialog.dart` **[改]** | `showStageVictoryDialog` + `StageVictoryContent` 加统计段 | 5 |
| `lib/features/mainline/presentation/stage_entry_flow.dart` **[改]** | host 传 `deferVictoryToCaller:true` + victory 分支用 `presentVictoryCeremony` + 传统计 | 6 |
| `lib/features/tower/presentation/tower_entry_flow.dart` **[改]** | host 传 `deferVictoryToCaller:true` + `_showVictoryDialog` 用 `presentVictoryCeremony` + 统计 | 7 |

---

## Task 1: `BattleStatsSummary` 统计纯函数

**Files:**
- Create: `lib/features/battle/domain/battle_stats.dart`
- Test: `test/features/battle/domain/battle_stats_test.dart`

- [ ] **Step 1: 写失败测试**

```dart
// test/features/battle/domain/battle_stats_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/battle/domain/battle_state.dart';
import 'package:wuxia_idle/features/battle/domain/battle_stats.dart';
import 'package:wuxia_idle/features/battle/domain/damage_calculator.dart';

AttackResult _atk({required int dmg, bool crit = false}) => AttackResult(
      finalDamage: dmg,
      mainDamage: dmg,
      quakeDamage: 0,
      isCritical: crit,
      isDodged: false,
      schoolCounterMultiplier: 1.0,
      realmDiffAttackerMod: 1.0,
      realmDiffDefenderMod: 1.0,
      cultivationMultiplier: 1.0,
      criticalMultiplier: crit ? 1.5 : 1.0,
      defenseRate: 0.0,
      evasionRate: 0.0,
      appliedEffects: const [],
      formulaBreakdown: '',
    );

void main() {
  test('BattleStatsSummary.from 汇总伤害/暴击/回合,跳过无 attackResult 的行动', () {
    final state = BattleState(
      leftTeam: const [],
      rightTeam: const [],
      tick: 7,
      result: BattleResult.leftWin,
      actionLog: [
        BattleAction(
            tick: 1, actorId: 1, description: '', attackResult: _atk(dmg: 100, crit: true)),
        BattleAction(
            tick: 2, actorId: 1, description: '', attackResult: _atk(dmg: 50)),
        const BattleAction(tick: 3, actorId: 1, description: ''), // 无 attackResult
      ],
    );

    final stats = BattleStatsSummary.from(state);

    expect(stats.totalDamage, 150);
    expect(stats.critCount, 1);
    expect(stats.totalTicks, 7);
  });

  test('空 actionLog → 全 0', () {
    final state = BattleState.initial(leftTeam: const [], rightTeam: const [])
        .copyWith(tick: 0);
    final stats = BattleStatsSummary.from(state);
    expect(stats.totalDamage, 0);
    expect(stats.critCount, 0);
    expect(stats.totalTicks, 0);
  });
}
```

- [ ] **Step 2: 跑测确认失败**

Run: `flutter test test/features/battle/domain/battle_stats_test.dart`
Expected: FAIL — `Target of URI doesn't exist: '.../battle_stats.dart'`

- [ ] **Step 3: 实现纯函数**

```dart
// lib/features/battle/domain/battle_stats.dart
import 'battle_state.dart';

/// 战斗统计汇总(总伤害 / 暴击数 / 回合数),从 [BattleState.actionLog] 派生。
///
/// 抽出供 [VictoryOverlay](battle_screen 弹)与结算 dialog(stage/tower flow)
/// 共用,避免两处各算一遍 fold 公式(时序重排 spec 2026-06-12)。
class BattleStatsSummary {
  final int totalDamage;
  final int critCount;
  final int totalTicks;

  const BattleStatsSummary({
    required this.totalDamage,
    required this.critCount,
    required this.totalTicks,
  });

  factory BattleStatsSummary.from(BattleState state) {
    var totalDamage = 0;
    var critCount = 0;
    for (final a in state.actionLog) {
      final r = a.attackResult;
      if (r == null) continue;
      totalDamage += r.finalDamage;
      if (r.isCritical) critCount += 1;
    }
    return BattleStatsSummary(
      totalDamage: totalDamage,
      critCount: critCount,
      totalTicks: state.tick,
    );
  }
}
```

- [ ] **Step 4: 跑测确认通过**

Run: `flutter test test/features/battle/domain/battle_stats_test.dart`
Expected: PASS (2 tests)

- [ ] **Step 5: 提交**

```bash
git add lib/features/battle/domain/battle_stats.dart test/features/battle/domain/battle_stats_test.dart
git commit -m "feat: 抽 BattleStatsSummary 战斗统计纯函数(时序重排准备)"
```

---

## Task 2: `BattleScreen.deferVictoryToCaller` + `_showResultDialog` 胜利下放

**Files:**
- Modify: `lib/features/battle/presentation/battle_screen.dart`(字段定义处 + 构造 + `_showResultDialog` ~552-597)
- Test: `test/features/battle/presentation/battle_screen_defer_victory_test.dart`(新建)

**背景:** 现 `_showResultDialog`(battle_screen.dart:552)无条件弹 `VictoryOverlay`。改为:`deferVictoryToCaller==true && result==leftWin` 时不弹,直接 `onBattleEnd`+`onVictory` 回调(停 BGM + victory SFX 仍照常)。败北、以及 `deferVictoryToCaller==false` 的胜利,行为不变。

- [ ] **Step 1: 写失败测试**

先确认 `BattleScreen` 字段定义位置(构造与字段)。用 grep:
```bash
grep -n "deferVictoryToCaller\|this.autoStart\|final bool autoStart\|required this.hint\|BattleScreen({" lib/features/battle/presentation/battle_screen.dart
```

测试(注入一个已结束的 battleProvider,验证 defer 行为)。注:`BattleScreen` 的胜负回调由 `_showResultDialog` 触发;defer=true 时应**立即**回调且不出现 `VictoryOverlay`。

```dart
// test/features/battle/presentation/battle_screen_defer_victory_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wuxia_idle/features/battle/presentation/battle_screen.dart';
import 'package:wuxia_idle/features/battle/presentation/victory_overlay.dart';
import 'package:wuxia_idle/core/application/battle_providers.dart';
import 'package:wuxia_idle/features/battle/domain/battle_state.dart';
// 复用现有 battle widget 测的造队 helper;若无则参考 test/widget_test.dart 的 BattleCharacter fixture。

void main() {
  testWidgets('deferVictoryToCaller=true + leftWin → 不弹 VictoryOverlay,直接 onVictory',
      (tester) async {
    var victoryCalls = 0;
    // 用一个已 startBattle 且 result=leftWin 的 provider override,或直接 pump 后注入 finalState。
    // 关键断言:pump 后 find VictoryOverlay 为空,且 victoryCalls==1。
    await tester.pumpWidget(ProviderScope(
      child: MaterialApp(
        home: BattleScreen(
          hint: 't',
          autoStart: false,
          deferVictoryToCaller: true,
          onVictory: () => victoryCalls++,
        ),
      ),
    ));
    // 注入战斗结束状态(leftWin)触发 ref.listen → _showResultDialog
    final container = ProviderScope.containerOf(
        tester.element(find.byType(BattleScreen)));
    // 通过 notifier 推入一个已结束的 state(见下方实现说明)
    // ...(执行者:参考现有 battle widget 测如何 startBattle + 推进到 result 非空)

    await tester.pumpAndSettle();

    expect(find.byType(VictoryOverlay), findsNothing);
    expect(victoryCalls, 1);
  });

  testWidgets('deferVictoryToCaller=false + leftWin → 仍弹 VictoryOverlay',
      (tester) async {
    await tester.pumpWidget(ProviderScope(
      child: MaterialApp(
        home: BattleScreen(hint: 't', autoStart: false, onVictory: () {}),
      ),
    ));
    // 同上注入 leftWin 结束态
    await tester.pumpAndSettle();
    expect(find.byType(VictoryOverlay), findsOneWidget);
  });
}
```

> **执行者注:** 推入「已结束」`BattleState` 的最稳做法是复用现有 battle widget 测的造队 + `startBattle` + tick 推进路径(见 `test/features/battle/presentation/` 下既有测试)。若注入成本高,可改为对 `_showResultDialog` 抽出的分支逻辑做更小粒度测试。核心断言两条:**defer+胜利 → 无 VictoryOverlay + onVictory 触发**;**非 defer 胜利 → 有 VictoryOverlay**。

- [ ] **Step 2: 跑测确认失败**

Run: `flutter test test/features/battle/presentation/battle_screen_defer_victory_test.dart`
Expected: FAIL — `deferVictoryToCaller` 命名参数不存在(编译错)。

- [ ] **Step 3: 实现**

在 `BattleScreen` 字段区加(挨着 `autoStart` 同类布尔字段):
```dart
  /// 时序重排(spec 2026-06-12):flow 路径传 true → 胜利时不弹 VictoryOverlay,
  /// 直接回调让 caller(stage/tower flow)接管,按掉落分档播爆品/简版勝。
  /// 败北不受影响;demo/pvp/debug 等无 flow 路径保持默认 false(仍弹 overlay)。
  final bool deferVictoryToCaller;
```
构造参数列表加(在 `this.autoStart` 附近):
```dart
    this.deferVictoryToCaller = false,
```

改 `_showResultDialog`(battle_screen.dart:552 起),在播完 SFX 之后、算统计/弹 overlay 之前插入 defer 分支,并把统计计算换成纯函数:
```dart
  void _showResultDialog(BattleResult result, BattleState s) {
    if (_resultDialogShown || !mounted) return;
    _resultDialogShown = true;

    SoundManager.instance.stopBgm();
    if (result == BattleResult.leftWin) {
      SoundManager.instance.playSfx(SfxId.victory);
    } else {
      SoundManager.instance.playSfx(SfxId.defeat);
    }

    // 时序重排:胜利且 caller 接管表现 → 不弹 VictoryOverlay,直接回调让 flow
    // roll 后按掉落分档播爆品/简版勝(spec 2026-06-12)。败北不走此分支。
    if (result == BattleResult.leftWin && widget.deferVictoryToCaller) {
      widget.onBattleEnd?.call();
      widget.onVictory?.call();
      return;
    }

    final stats = BattleStatsSummary.from(s);

    showGeneralDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (ctx, _, _) => VictoryOverlay(
        result: result,
        totalDamage: stats.totalDamage,
        critCount: stats.critCount,
        totalTicks: stats.totalTicks,
        onContinue: () {
          Navigator.of(ctx).pop();
          widget.onBattleEnd?.call();
          if (result == BattleResult.leftWin) {
            widget.onVictory?.call();
          } else {
            widget.onDefeat?.call();
          }
        },
      ),
      transitionBuilder: (ctx, anim, _, child) =>
          FadeTransition(opacity: anim, child: child),
    );
  }
```
文件顶部加 import:
```dart
import '../domain/battle_stats.dart';
```

- [ ] **Step 4: 跑测确认通过**

Run: `flutter test test/features/battle/presentation/battle_screen_defer_victory_test.dart`
Expected: PASS (2 tests)

并跑现有 battle screen 测确认无回归:
Run: `flutter test test/features/battle/ test/widget_test.dart`
Expected: PASS（全绿）

- [ ] **Step 5: 提交**

```bash
git add lib/features/battle/presentation/battle_screen.dart test/features/battle/presentation/battle_screen_defer_victory_test.dart
git commit -m "feat: BattleScreen 加 deferVictoryToCaller,胜利结果反馈可下放给 flow"
```

---

## Task 3: `VictorySealFlash` 简版勝 widget

**Files:**
- Create: `lib/features/battle/presentation/victory_ceremony.dart`(本 task 先放 widget + show 函数;Task 4 再补 `presentVictoryCeremony`)
- Test: `test/features/battle/presentation/victory_seal_flash_test.dart`

**设计:** 印章符 + 「勝」题字(复用 `VictoryOverlay` 体例),淡入(0→0.3)→ 停(0.3→0.7)→ 淡出(0.7→1)共 ~800ms,完成自动 `onDone`;点击可提前跳过。无统计、无按钮。

- [ ] **Step 1: 写失败测试**

```dart
// test/features/battle/presentation/victory_seal_flash_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/battle/presentation/victory_ceremony.dart';
import 'package:wuxia_idle/shared/strings.dart';

void main() {
  testWidgets('VictorySealFlash 显「勝」题字,~800ms 后自动 onDone', (tester) async {
    var done = 0;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: VictorySealFlash(onDone: () => done++)),
    ));
    expect(find.text(UiStrings.victoryTitle), findsOneWidget);
    expect(done, 0);

    await tester.pump(const Duration(milliseconds: 900)); // 跨过 800ms
    expect(done, 1);
  });

  testWidgets('点击提前跳过 → 立即 onDone', (tester) async {
    var done = 0;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: VictorySealFlash(onDone: () => done++)),
    ));
    await tester.tap(find.byType(VictorySealFlash));
    await tester.pump();
    expect(done, 1);

    // 再等动画自然结束不应重复回调
    await tester.pump(const Duration(milliseconds: 900));
    expect(done, 1);
  });
}
```

- [ ] **Step 2: 跑测确认失败**

Run: `flutter test test/features/battle/presentation/victory_seal_flash_test.dart`
Expected: FAIL — `victory_ceremony.dart` 不存在。

- [ ] **Step 3: 实现**

```dart
// lib/features/battle/presentation/victory_ceremony.dart
import 'package:flutter/material.dart';

import '../../../shared/strings.dart';
import '../../../shared/theme/colors.dart';
import '../../../shared/widgets/wuxia_ui/wuxia_ui.dart';

/// 简版「勝」淡入淡出(时序重排 spec 2026-06-12)。
///
/// 普通/无掉落档的胜利仪式:印章符 + 「勝」题字,淡入→停→淡出 ~800ms 自动消失
/// (不拦点击 / 无统计 / 无按钮)。爆品档不走此 widget,走 TreasureDropOverlay。
/// 点击可提前跳过。
class VictorySealFlash extends StatefulWidget {
  final VoidCallback onDone;
  const VictorySealFlash({super.key, required this.onDone});

  @override
  State<VictorySealFlash> createState() => _VictorySealFlashState();
}

class _VictorySealFlashState extends State<VictorySealFlash>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800))
      ..addStatusListener((s) {
        if (s == AnimationStatus.completed) _finish();
      })
      ..forward();
  }

  void _finish() {
    if (_done) return;
    _done = true;
    widget.onDone();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  double _opacity(double t) {
    if (t < 0.3) return (t / 0.3).clamp(0.0, 1.0);
    if (t > 0.7) return (1 - (t - 0.7) / 0.3).clamp(0.0, 1.0);
    return 1.0;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _finish,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, _) {
          return Opacity(
            opacity: _opacity(_ctrl.value),
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  radius: 0.9,
                  colors: [Color(0x33000000), Color(0xCC000000)],
                  stops: [0.45, 1.0],
                ),
              ),
              alignment: Alignment.center,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Transform.rotate(
                    angle: -0.08,
                    child: SizedBox(
                      width: 48,
                      height: 48,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Image.asset(
                            WuxiaUi.ceremonyRedSeal,
                            fit: BoxFit.contain,
                            errorBuilder: (_, _, _) => DecoratedBox(
                              decoration: BoxDecoration(
                                color: WuxiaColors.gangMeng,
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                          ),
                          const Text(
                            UiStrings.sealGlyph,
                            style: TextStyle(
                              color: WuxiaColors.textPrimary,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    UiStrings.victoryTitle,
                    style: TextStyle(
                      color: WuxiaColors.resultHighlight,
                      fontSize: 96,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          blurRadius: 12,
                          color: Color(0xCC000000),
                          offset: Offset(2, 3),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// 弹简版勝 overlay 并 await 至消失(自动 ~800ms 或点击跳过)。
Future<void> showVictorySealFlash(BuildContext context) async {
  if (!context.mounted) return;
  await showGeneralDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.transparent,
    transitionDuration: Duration.zero,
    pageBuilder: (ctx, _, _) =>
        VictorySealFlash(onDone: () => Navigator.of(ctx).pop()),
  );
}
```

- [ ] **Step 4: 跑测确认通过**

Run: `flutter test test/features/battle/presentation/victory_seal_flash_test.dart`
Expected: PASS (2 tests)

- [ ] **Step 5: 提交**

```bash
git add lib/features/battle/presentation/victory_ceremony.dart test/features/battle/presentation/victory_seal_flash_test.dart
git commit -m "feat: 新增 VictorySealFlash 简版勝淡入淡出 widget"
```

---

## Task 4: `playTreasureDropIfAny` 返回 bool + `presentVictoryCeremony` 分档

**Files:**
- Modify: `lib/features/equipment/presentation/treasure_drop_overlay.dart`(`playTreasureDropIfAny` ~275-304:返回类型 void→bool)
- Modify: `lib/features/battle/presentation/victory_ceremony.dart`(补 `presentVictoryCeremony`)
- Test: `test/features/battle/presentation/present_victory_ceremony_test.dart`

- [ ] **Step 1: 写失败测试**

`presentVictoryCeremony` 在 `GameRepository` 未加载(widget test 默认)时,`playTreasureDropIfAny` 早 return false,因此一律走简版勝 `VictorySealFlash`。这给了一个无需 GameRepository 的稳定断言。

```dart
// test/features/battle/presentation/present_victory_ceremony_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/battle/presentation/victory_ceremony.dart';
import 'package:wuxia_idle/features/equipment/application/drop_service.dart';

void main() {
  testWidgets('GameRepository 未加载 → presentVictoryCeremony 走简版勝',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Builder(builder: (context) {
        return Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () => presentVictoryCeremony(
                context,
                const DropResult(equipments: [], items: []),
                treasureGate: true,
              ),
              child: const Text('go'),
            ),
          ),
        );
      }),
    ));
    await tester.tap(find.text('go'));
    await tester.pump(); // 弹出 overlay
    expect(find.byType(VictorySealFlash), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 900)); // 自动消失
    expect(find.byType(VictorySealFlash), findsNothing);
  });

  testWidgets('treasureGate=false 也走简版勝(塔重打档)', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Builder(builder: (context) {
        return Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () => presentVictoryCeremony(
                context,
                const DropResult(equipments: [], items: []),
                treasureGate: false,
              ),
              child: const Text('go'),
            ),
          ),
        );
      }),
    ));
    await tester.tap(find.text('go'));
    await tester.pump();
    expect(find.byType(VictorySealFlash), findsOneWidget);
  });
}
```

- [ ] **Step 2: 跑测确认失败**

Run: `flutter test test/features/battle/presentation/present_victory_ceremony_test.dart`
Expected: FAIL — `presentVictoryCeremony` 未定义。

- [ ] **Step 3: 实现**

**3a.** `treasure_drop_overlay.dart` — `playTreasureDropIfAny` 返回类型 `Future<void>` → `Future<bool>`(返回是否真播了爆品),全部 early-return 改 `return false`,播放后 `return true`:
```dart
/// 公共触发:有 ≥门槛爆品且 [gate] 时,播动画(+reward 音)并 await 至结束。
/// 返回 true=播了爆品镜头;false=无爆品(gate false / 未加载 / 无重器)。
/// 主线传 gate=true;塔传 gate=isFirstClear。
Future<bool> playTreasureDropIfAny(
    BuildContext context, DropResult drops,
    {required bool gate}) async {
  if (!gate || !GameRepository.isLoaded) return false;
  final minTier = GameRepository.instance.numbers.treasureDrop.minTier;
  final candidates = drops.equipments.map((e) {
    final def = GameRepository.instance.getEquipment(e.defId);
    return TreasureHighlight(
        defId: e.defId,
        name: def.name,
        tier: def.tier,
        slot: def.slot,
        iconPath: def.iconPath,
        attack: e.baseAttack,
        health: e.baseHealth,
        speed: e.baseSpeed,
        tagline: def.tagline);
  }).toList();
  final hl = pickTreasureHighlight(candidates, minTier);
  if (hl == null || !context.mounted) return false;
  SoundManager.instance.playSfx(SfxId.reward);
  await showGeneralDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.transparent,
    transitionDuration: Duration.zero,
    pageBuilder: (ctx, _, _) => TreasureDropOverlay(
        highlight: hl, onDone: () => Navigator.of(ctx).pop()),
  );
  return true;
}
```

**3b.** `victory_ceremony.dart` — 文件顶部补 import,文件末尾加分档函数:
```dart
import '../../equipment/application/drop_service.dart';
import '../../equipment/presentation/treasure_drop_overlay.dart';
```
```dart
/// 战斗胜利仪式分档(时序重排 spec 2026-06-12):
/// 有 ≥重器爆品 → 爆品镜头(印章盖落即胜利宣告,含 reward 音);
/// 否则(普通掉落 / 无掉落 / 塔重打) → 简版勝淡入淡出。
/// mainline / tower 两 flow 共用。[treasureGate]=false(塔重打)→ 必走简版勝。
Future<void> presentVictoryCeremony(
  BuildContext context,
  DropResult drops, {
  required bool treasureGate,
}) async {
  final playedTreasure =
      await playTreasureDropIfAny(context, drops, gate: treasureGate);
  if (playedTreasure) return;
  if (!context.mounted) return;
  await showVictorySealFlash(context);
}
```

- [ ] **Step 4: 跑测确认通过**

Run: `flutter test test/features/battle/presentation/present_victory_ceremony_test.dart`
Expected: PASS (2 tests)

确认 `treasure_drop_overlay` 现有测不回归:
Run: `flutter test test/features/equipment/`
Expected: PASS（返回值变 bool 不影响现有 void 用法 / overlay 测试）

- [ ] **Step 5: 提交**

```bash
git add lib/features/equipment/presentation/treasure_drop_overlay.dart lib/features/battle/presentation/victory_ceremony.dart test/features/battle/presentation/present_victory_ceremony_test.dart
git commit -m "feat: playTreasureDropIfAny 返回 bool + presentVictoryCeremony 胜利仪式分档"
```

---

## Task 5: 结算 dialog(mainline)新增统计段

**Files:**
- Modify: `lib/features/mainline/presentation/stage_victory_dialog.dart`(`showStageVictoryDialog` 22-59 + `StageVictoryContent` 62-126)
- Test: `test/features/mainline/presentation/stage_victory_dialog_test.dart`(若已存在则追加 case;否则新建)

- [ ] **Step 1: 写失败测试**

```dart
// test/features/mainline/presentation/stage_victory_dialog_test.dart (追加或新建)
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/battle/domain/battle_stats.dart';
import 'package:wuxia_idle/features/equipment/application/drop_service.dart';
import 'package:wuxia_idle/features/mainline/presentation/stage_victory_dialog.dart';
import 'package:wuxia_idle/shared/strings.dart';

void main() {
  testWidgets('StageVictoryContent 显示战斗统计段', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: StageVictoryContent(
          drops: const DropResult(equipments: [], items: []),
          advancements: const [],
          stats: const BattleStatsSummary(
              totalDamage: 1234, critCount: 3, totalTicks: 9),
        ),
      ),
    ));
    expect(find.text(UiStrings.battleSummary(1234, 3, 9)), findsOneWidget);
  });

  testWidgets('stats=null 时不显统计段(向后兼容)', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: StageVictoryContent(
          drops: DropResult(equipments: [], items: []),
          advancements: [],
        ),
      ),
    ));
    // 仅断言不抛 + 掉落标签在
    expect(find.text(UiStrings.stageVictoryDropLabel), findsOneWidget);
  });
}
```

- [ ] **Step 2: 跑测确认失败**

Run: `flutter test test/features/mainline/presentation/stage_victory_dialog_test.dart`
Expected: FAIL — `stats` 命名参数不存在。

- [ ] **Step 3: 实现**

`stage_victory_dialog.dart` 顶部加 import:
```dart
import '../../battle/domain/battle_stats.dart';
```
`showStageVictoryDialog` 签名加参数并透传:
```dart
Future<void> showStageVictoryDialog({
  required BuildContext context,
  required StageDef stage,
  required DropResult drops,
  required List<AdvancementEntry> advancements,
  List<ResonanceUpgradeNotice> resonanceUpgrades = const [],
  String? firstClearTitle,
  String? firstClearSubtitle,
  BattleStatsSummary? stats,   // ← 新增
}) async {
  // ...(jingle 逻辑不变)...
  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      title: Text('${stage.name} · ${UiStrings.stageVictoryTitle}'),
      content: StageVictoryContent(
        drops: drops,
        advancements: advancements,
        resonanceUpgrades: resonanceUpgrades,
        firstClearTitle: firstClearTitle,
        firstClearSubtitle: firstClearSubtitle,
        stats: stats,             // ← 透传
      ),
      // ...(actions 不变)...
    ),
  );
}
```
`StageVictoryContent` 加字段 + 构造 + 渲染:
```dart
class StageVictoryContent extends StatelessWidget {
  const StageVictoryContent({
    super.key,
    required this.drops,
    required this.advancements,
    this.resonanceUpgrades = const [],
    this.firstClearTitle,
    this.firstClearSubtitle,
    this.stats,                   // ← 新增
  });

  final DropResult drops;
  final List<AdvancementEntry> advancements;
  final List<ResonanceUpgradeNotice> resonanceUpgrades;
  final String? firstClearTitle;
  final String? firstClearSubtitle;
  final BattleStatsSummary? stats; // ← 新增

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ...(firstClearBanner / drop 列 / 升层 / 共鸣 banner 全部不变)...
        if (resonanceUpgrades.isNotEmpty) ...[
          const SizedBox(height: 12),
          ResonanceUpgradeBanner(notices: resonanceUpgrades),
        ],
        if (stats != null) ...[
          const SizedBox(height: 12),
          Text(
            UiStrings.battleSummary(
                stats!.totalDamage, stats!.critCount, stats!.totalTicks),
            style: const TextStyle(
                color: WuxiaColors.textSecondary, fontSize: 13),
          ),
        ],
      ],
    );
  }
}
```
> 执行者:把 `if (stats != null)` 段加在现有 children 列表**末尾**(共鸣 banner 之后),其余 children 原样保留。

- [ ] **Step 4: 跑测确认通过**

Run: `flutter test test/features/mainline/presentation/stage_victory_dialog_test.dart`
Expected: PASS

- [ ] **Step 5: 提交**

```bash
git add lib/features/mainline/presentation/stage_victory_dialog.dart test/features/mainline/presentation/stage_victory_dialog_test.dart
git commit -m "feat: 主线结算 dialog 新增战斗统计段"
```

---

## Task 6: `stage_entry_flow` wiring(主线串联)

**Files:**
- Modify: `lib/features/mainline/presentation/stage_entry_flow.dart`
  - `_StageBattleHostState.build` 的 `BattleScreen(...)`(~358-379):加 `deferVictoryToCaller: true`
  - `runStageFlow` victory 分支(~186-196):`playTreasureDropIfAny` → `presentVictoryCeremony` + 传 stats
  - import 调整:加 `victory_ceremony.dart` + `battle_stats.dart`;移除不再使用的 `treasure_drop_overlay.dart` import(若 `playTreasureDropIfAny` 不再被本文件直接调用)

- [ ] **Step 1: 改 host 传 defer**

`_StageBattleHostState.build` 里的 `BattleScreen(...)`,在 `bgmTrack:` 之后加一行:
```dart
    return BattleScreen(
      hint: widget.stage.name,
      sceneBackgroundPath: widget.stage.sceneBackgroundPath,
      bgmTrack: bgmTrackForStage(
        widget.stage.stageType,
        isBoss: widget.stage.isBossStage,
      ),
      deferVictoryToCaller: true,   // ← 新增:胜利下放给 runStageFlow 分档
      onVictory: () {
        widget.onVictory();
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      },
      onDefeat: () {
        widget.onDefeat();
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      },
    );
```

- [ ] **Step 2: 改 victory 分支**

把(stage_entry_flow.dart ~186-196):
```dart
  if (outcome != null && context.mounted) {
    await playTreasureDropIfAny(context, outcome.drops, gate: true);
    if (!context.mounted) return;
    await showStageVictoryDialog(
      context: context,
      stage: stage,
      drops: outcome.drops,
      advancements: outcome.advancements,
      resonanceUpgrades: outcome.resonanceUpgrades,
    );
  }
```
改为:
```dart
  if (outcome != null && context.mounted) {
    await presentVictoryCeremony(context, outcome.drops, treasureGate: true);
    if (!context.mounted) return;
    final stats = BattleStatsSummary.from(ref.read(battleProvider));
    await showStageVictoryDialog(
      context: context,
      stage: stage,
      drops: outcome.drops,
      advancements: outcome.advancements,
      resonanceUpgrades: outcome.resonanceUpgrades,
      stats: stats,
    );
  }
```

- [ ] **Step 3: 调 import**

文件顶部 import 区:
- 加:
  ```dart
  import '../../battle/domain/battle_stats.dart';
  import '../../battle/presentation/victory_ceremony.dart';
  ```
- 移除(若全文已无 `playTreasureDropIfAny` 直接调用):
  ```dart
  import '../../equipment/presentation/treasure_drop_overlay.dart';
  ```
  先 grep 确认本文件不再用它:
  ```bash
  grep -n "playTreasureDropIfAny\|TreasureDrop" lib/features/mainline/presentation/stage_entry_flow.dart
  ```
  若仅剩 import 行命中 → 删 import。

- [ ] **Step 4: 跑测 + analyze**

Run: `flutter test test/features/mainline/` 然后 `flutter analyze`
Expected: 现有 mainline flow 测全绿(`battleRunnerForTest`/`victoryRecorderForTest` 注入路径不受表现层改动影响);analyze 0(无 unused import)。

> 若现有 flow 测对 `playTreasureDropIfAny` 有直接断言(grep `playTreasureDropIfAny` 于 test/),改成对 `presentVictoryCeremony` / `VictorySealFlash` 的等价断言。

- [ ] **Step 5: 提交**

```bash
git add lib/features/mainline/presentation/stage_entry_flow.dart
git commit -m "feat: 主线 flow 接入时序重排(胜利下放+爆品分档+统计入 dialog)"
```

---

## Task 7: `tower_entry_flow` wiring(爬塔串联)

**Files:**
- Modify: `lib/features/tower/presentation/tower_entry_flow.dart`
  - `_TowerBattleHostState.build` 的 `BattleScreen(...)`(~633-645):加 `deferVictoryToCaller: true`
  - `_showVictoryDialog`(539-579):`playTreasureDropIfAny` → `presentVictoryCeremony`;dialog content 包一层加统计段;签名加 `BattleStatsSummary? stats`
  - caller `runTowerFlow`(~226-233):传 `stats: BattleStatsSummary.from(ref.read(battleProvider))`
  - import:加 `victory_ceremony.dart` + `battle_stats.dart`;移除直接 `treasure_drop_overlay` import(若无其他用途)

- [ ] **Step 1: 改 host 传 defer**

`_TowerBattleHostState.build` 的 `BattleScreen(...)`,`bgmTrack:` 后加:
```dart
    return BattleScreen(
      hint: UiStrings.towerFloorLabel(widget.floor.floorIndex),
      sceneBackgroundPath: widget.floor.sceneBackgroundPath,
      bgmTrack: BgmTrack.tower,
      deferVictoryToCaller: true,   // ← 新增
      onVictory: () {
        widget.onVictory();
        if (Navigator.of(context).canPop()) Navigator.of(context).pop();
      },
      onDefeat: () {
        widget.onDefeat();
        if (Navigator.of(context).canPop()) Navigator.of(context).pop();
      },
    );
```

- [ ] **Step 2: 改 `_showVictoryDialog`**

签名加 `stats`,`playTreasureDropIfAny` 换 `presentVictoryCeremony`,content 包一层加统计:
```dart
Future<void> _showVictoryDialog({
  required BuildContext context,
  required TowerFloorDef floor,
  required bool isFirstClear,
  required DropResult drops,
  required List<AdvancementEntry> advancements,
  List<ResonanceUpgradeNotice> resonanceUpgrades = const [],
  BattleStatsSummary? stats,    // ← 新增
}) async {
  // 胜利仪式分档:首通有重器→爆品镜头;否则(普通/重打)→简版勝。
  await presentVictoryCeremony(context, drops, treasureGate: isFirstClear);
  if (!context.mounted) return;
  if (isFirstClear && advancements.any((e) => e.result.crossedTier)) {
    SoundManager.instance.playSfx(SfxId.realmAdvance);
  }
  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      title: Text(UiStrings.towerFloorLabel(floor.floorIndex)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          isFirstClear
              ? _FirstClearContent(
                  floor: floor,
                  drops: drops,
                  advancements: advancements,
                  resonanceUpgrades: resonanceUpgrades,
                )
              : const Text(UiStrings.towerReplayNoReward),
          if (stats != null) ...[
            const SizedBox(height: 12),
            Text(
              UiStrings.battleSummary(
                  stats.totalDamage, stats.critCount, stats.totalTicks),
              style: const TextStyle(
                  color: WuxiaColors.textSecondary, fontSize: 13),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          style: TextButton.styleFrom(
            foregroundColor: WuxiaColors.resultHighlight,
          ),
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text(UiStrings.towerVictoryConfirm),
        ),
      ],
    ),
  );
}
```

- [ ] **Step 3: caller 传 stats + import**

`runTowerFlow` 的 `_showVictoryDialog(...)` 调用(~226)加:
```dart
    await _showVictoryDialog(
      context: context,
      floor: floor,
      isFirstClear: clearResult.isFirstClear,
      drops: drops,
      advancements: advancements,
      resonanceUpgrades: resonanceUpgrades,
      stats: BattleStatsSummary.from(ref.read(battleProvider)),
    );
```
import 区加:
```dart
import '../../battle/domain/battle_stats.dart';
import '../../battle/presentation/victory_ceremony.dart';
```
grep 确认是否还需 `treasure_drop_overlay` import:
```bash
grep -n "playTreasureDropIfAny\|TreasureDrop" lib/features/tower/presentation/tower_entry_flow.dart
```
若仅 import 行命中 → 删该 import。

- [ ] **Step 4: 跑测 + analyze**

Run: `flutter test test/features/tower/` 然后 `flutter analyze`
Expected: tower flow 测全绿;analyze 0。

- [ ] **Step 5: 提交**

```bash
git add lib/features/tower/presentation/tower_entry_flow.dart
git commit -m "feat: 爬塔 flow 接入时序重排(胜利下放+爆品分档+重打走简版勝+统计入 dialog)"
```

---

## Task 8: 闸门 — 全量回归 + analyze

**Files:** 无新改动,纯验证。

- [ ] **Step 1: 全量测试**

Run: `flutter test`
Expected: 全绿 / 1 skip(基线 1991 测 + 本批新增:battle_stats 2 + defer 2 + seal_flash 2 + present_ceremony 2 + stage_victory stats 2 ≈ +10 → ~2001 测;以实际为准)。

- [ ] **Step 2: analyze**

Run: `flutter analyze`
Expected: `No issues found!`

- [ ] **Step 3: 回归核对(人工 grep)**

确认无遗漏的旧 `playTreasureDropIfAny` 裸调用(应只剩 `presentVictoryCeremony` 内部一处):
```bash
grep -rn "playTreasureDropIfAny" lib/
```
Expected: 仅 `treasure_drop_overlay.dart`(定义)+ `victory_ceremony.dart`(调用)两处命中。

- [ ] **Step 4: 提交(若 Step 3 有清理)**

```bash
git add -A
git commit -m "chore: 时序重排闸门核对(全量绿 + analyze 0)"
```

---

## 完成标准

- [ ] 三档时序就位:爆品档(印章镜头)/ 普通·无掉落档(简版勝 0.8s 自动)/ 战败(VictoryOverlay「敗」不变)。
- [ ] mainline + tower 两路径对称,塔重打走简版勝。
- [ ] 统计在结算 dialog 显示;VictoryOverlay 保留给 demo/pvp 不动。
- [ ] `flutter test` 全绿 + `flutter analyze` 0。
- [ ] 未碰 `resolve`/roll/rng/numbers.yaml/schema/数值红线。

## 真玩验收(合 main 后,需用户)

- 重编 macos 包,跑一关有高阶掉落 → 看爆品是否成为战斗结束第一画面(无「勝」抢先)。
- 跑一关普通掉落 → 看简版勝是否 0.8s 自动过、直达掉落清单(零点击)。
- 战败一关 → 确认「敗」overlay 行为不变。
