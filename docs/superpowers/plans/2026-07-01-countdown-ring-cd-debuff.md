# CD/debuff 读秒圆环 实装计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 把技能 CD、内伤、敌蓄力、破绽从文字/进度条改成「圆环转圈读秒 + 中心剩余数字」，平滑扫随战斗节拍同步。

**Architecture:** 三个表现层组件——`CountdownRing`(纯 CustomPainter 绘制) / `BeatCountdownRing`(接共享节拍 `beat` 每拍插值，CD/蓄力/破绽用) / `SteppedCountdownRing`(内伤用，max-seen 分母 + 值变短过渡)。`_BattleScreenState` 加一个 `_beatCtrl` 节拍控制器，timer 回调 `forward(from:0)` 精确对齐每拍、暂停 stop，向下经 `Animation<double> beat` 传到技能按钮与头像。环取代现有 `AvatarStatusTags` 内伤/踉跄药丸与 `_ChargeBar`（hover 释义保留、剑鸣 buff 药丸保留）。

**Tech Stack:** Flutter / Riverpod 3 / CustomPainter / AnimationController(TickerProviderStateMixin)。纯表现层，零碰 numbers/结算/saveVer/schema。

**红线（每任务守）:** 只读 `BattleCharacter` 既有字段（`skillCooldowns`/`internalInjury`/`chargeTicksRemaining`/`staggerTicksRemaining`/`chargingSkill`）；不改任何 tick 递减/结算/数值；中心为纯数字无单位（不散写中文）；配色取 `WuxiaColors`；环包 `RepaintBoundary`；不做 golden（改数字+存在性断言，守 `feedback_flutter_ci_local_green_red`）；widget 测 viewport 1280×720（`feedback_listview_widget_test_viewport`）。

---

### Task 1: `CountdownRing` 纯绘制组件

**Files:**
- Create: `lib/features/battle/presentation/countdown_ring.dart`
- Test: `test/features/battle/presentation/countdown_ring_test.dart`

- [ ] **Step 1: 写失败测试**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/battle/presentation/countdown_ring.dart';

void main() {
  Future<void> pump(WidgetTester t, Widget w) async {
    await t.binding.setSurfaceSize(const Size(1280, 720));
    addTearDown(() => t.binding.setSurfaceSize(null));
    await t.pumpWidget(MaterialApp(home: Scaffold(body: Center(child: w))));
  }

  testWidgets('中心数字 = remaining.ceil()', (t) async {
    await pump(t, const CountdownRing(
      remaining: 2.3, total: 3, color: Colors.amber, size: 40));
    expect(find.text('3'), findsOneWidget); // ceil(2.3)=3
  });

  testWidgets('remaining 整数直接显示', (t) async {
    await pump(t, const CountdownRing(
      remaining: 1, total: 3, color: Colors.amber, size: 40));
    expect(find.text('1'), findsOneWidget);
  });

  testWidgets('remaining<=0 不渲染(空)', (t) async {
    await pump(t, const CountdownRing(
      remaining: 0, total: 3, color: Colors.amber, size: 40));
    expect(find.byType(CustomPaint).evaluate().isNotEmpty, isTrue);
    expect(find.text('0'), findsNothing);
  });
}
```

- [ ] **Step 2: 跑测试确认失败** — Run: `flutter test --no-pub test/features/battle/presentation/countdown_ring_test.dart` Expected: FAIL(countdown_ring.dart 不存在)。

- [ ] **Step 3: 实装 `CountdownRing`**

```dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../shared/theme/colors.dart';

/// 读秒圆环(纯绘制)：底 track 整圆 + 剩余比例扫弧(12 点起顺时针消退) + 中心数字。
/// 纯展示，不含动画逻辑——喂什么比例画什么。remaining<=0 时只留空(不显数字)。
class CountdownRing extends StatelessWidget {
  const CountdownRing({
    super.key,
    required this.remaining,
    required this.total,
    required this.color,
    this.size = 40,
    this.strokeWidth = 3.5,
    this.trackColor = WuxiaColors.barTrack,
  });

  final double remaining; // 可小数
  final int total;
  final Color color;
  final double size;
  final double strokeWidth;
  final Color trackColor;

  @override
  Widget build(BuildContext context) {
    final frac = total <= 0 ? 0.0 : (remaining / total).clamp(0.0, 1.0);
    final n = remaining.ceil();
    return RepaintBoundary(
      child: SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: _CountdownRingPainter(
            frac: frac, color: color, trackColor: trackColor, stroke: strokeWidth),
          child: Center(
            child: n > 0
                ? Text('$n',
                    style: TextStyle(
                      fontSize: size * 0.42,
                      height: 1.0,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ))
                : const SizedBox.shrink(),
          ),
        ),
      ),
    );
  }
}

class _CountdownRingPainter extends CustomPainter {
  _CountdownRingPainter({
    required this.frac,
    required this.color,
    required this.trackColor,
    required this.stroke,
  });
  final double frac;
  final Color color;
  final Color trackColor;
  final double stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final center = rect.center;
    final radius = (size.shortestSide - stroke) / 2;
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = trackColor.withValues(alpha: 0.55);
    canvas.drawCircle(center, radius, track);
    if (frac <= 0) return;
    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = stroke
      ..color = color;
    // 12 点(-90°)起顺时针，扫 frac 圈(剩余比例)。
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2, 2 * math.pi * frac, false, arc);
  }

  @override
  bool shouldRepaint(_CountdownRingPainter old) =>
      old.frac != frac || old.color != color;
}
```

- [ ] **Step 4: 跑测试确认通过** — Run: 同 Step 2。Expected: PASS(3 tests)。

- [ ] **Step 5: 提交**

```bash
git add lib/features/battle/presentation/countdown_ring.dart test/features/battle/presentation/countdown_ring_test.dart
git commit -m "加 CountdownRing 读秒圆环纯绘制组件"
```

---

### Task 2: `BeatCountdownRing`(每拍插值·CD/蓄力/破绽)

**Files:**
- Modify: `lib/features/battle/presentation/countdown_ring.dart`(追加类)
- Test: `test/features/battle/presentation/countdown_ring_test.dart`(追加)

- [ ] **Step 1: 追加失败测试**

```dart
  testWidgets('BeatCountdownRing: beat=0 显整数剩余', (t) async {
    final ctrl = AnimationController(vsync: const TestVSync(), value: 0.0,
        duration: const Duration(seconds: 1));
    addTearDown(ctrl.dispose);
    await pump(t, BeatCountdownRing(
      remaining: 3, total: 3, beat: ctrl, color: Colors.amber, size: 40));
    expect(find.text('3'), findsOneWidget);
  });

  testWidgets('BeatCountdownRing: beat=0.5 时 remaining3 显 3(ceil 2.5)', (t) async {
    final ctrl = AnimationController(vsync: const TestVSync(), value: 0.5,
        duration: const Duration(seconds: 1));
    addTearDown(ctrl.dispose);
    await pump(t, BeatCountdownRing(
      remaining: 3, total: 3, beat: ctrl, color: Colors.amber, size: 40));
    expect(find.text('3'), findsOneWidget); // 3-0.5=2.5 → ceil 3
  });
```
(测试文件顶部补 `import 'package:flutter/scheduler.dart';` 若需 TestVSync；flutter_test 已带 TestVSync。)

- [ ] **Step 2: 跑测试确认失败** — Expected: FAIL(BeatCountdownRing 未定义)。

- [ ] **Step 3: 追加 `BeatCountdownRing`**

```dart
/// 接共享节拍 [beat](本拍内 0→1)平滑插值：显示剩余 = remaining - beat.value，
/// 每拍 state 里 remaining 减 1 时环无缝续扫。CD/敌蓄力/破绽用(均每全局拍减 1)。
class BeatCountdownRing extends StatelessWidget {
  const BeatCountdownRing({
    super.key,
    required this.remaining,
    required this.total,
    required this.beat,
    required this.color,
    this.size = 40,
    this.strokeWidth = 3.5,
  });
  final int remaining;
  final int total;
  final Animation<double> beat;
  final Color color;
  final double size;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: beat,
      builder: (_, __) {
        final disp = (remaining - beat.value).clamp(0.0, total.toDouble());
        return CountdownRing(
          remaining: disp, total: total, color: color,
          size: size, strokeWidth: strokeWidth);
      },
    );
  }
}
```

- [ ] **Step 4: 跑测试确认通过** — Expected: PASS。
- [ ] **Step 5: 提交** — `git commit -m "加 BeatCountdownRing 接节拍平滑插值"`

---

### Task 3: `SteppedCountdownRing`(内伤·max-seen + 值变过渡)

**Files:**
- Modify: `lib/features/battle/presentation/countdown_ring.dart`(追加类)
- Test: `test/features/battle/presentation/countdown_ring_test.dart`(追加)

- [ ] **Step 1: 追加失败测试**

```dart
  testWidgets('SteppedCountdownRing: 首见 remaining=3 → 显 3, 分母=3', (t) async {
    await pump(t, const SteppedCountdownRing(
      remaining: 3, color: Colors.red, size: 40));
    expect(find.text('3'), findsOneWidget);
  });

  testWidgets('SteppedCountdownRing: remaining=0 不显数字', (t) async {
    await pump(t, const SteppedCountdownRing(
      remaining: 0, color: Colors.red, size: 40));
    expect(find.text('0'), findsNothing);
  });
```

- [ ] **Step 2: 跑测试确认失败** — Expected: FAIL(SteppedCountdownRing 未定义)。

- [ ] **Step 3: 追加 `SteppedCountdownRing`**

```dart
/// 内伤专用：state 无初始 total，用「激活期见过的最大剩余」作分母(max-seen)，
/// 状态清零(remaining<=0)复位。remaining 变化时 ~250ms 短过渡扫一段(跳变，不假装匀速)。
class SteppedCountdownRing extends StatefulWidget {
  const SteppedCountdownRing({
    super.key, required this.remaining, required this.color,
    this.size = 40, this.strokeWidth = 3.5,
  });
  final int remaining;
  final Color color;
  final double size;
  final double strokeWidth;

  @override
  State<SteppedCountdownRing> createState() => _SteppedCountdownRingState();
}

class _SteppedCountdownRingState extends State<SteppedCountdownRing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  int _maxSeen = 0;
  double _shownFrom = 0;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 250));
    _sync(widget.remaining, animate: false);
  }

  void _sync(int rem, {required bool animate}) {
    if (rem <= 0) { _maxSeen = 0; _shownFrom = 0; _ctrl.value = 1; return; }
    if (rem > _maxSeen) _maxSeen = rem;
    if (animate) { _shownFrom = _prevShown(); _ctrl.forward(from: 0); }
  }

  double _prevShown() => widget.remaining.toDouble();

  @override
  void didUpdateWidget(SteppedCountdownRing old) {
    super.didUpdateWidget(old);
    if (old.remaining != widget.remaining) {
      _shownFrom = old.remaining.toDouble();
      _sync(widget.remaining, animate: true);
    }
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    if (widget.remaining <= 0) return const SizedBox.shrink();
    final total = _maxSeen <= 0 ? 1 : _maxSeen;
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        final disp = _ctrl.isAnimating
            ? _shownFrom + (widget.remaining - _shownFrom) * _ctrl.value
            : widget.remaining.toDouble();
        return CountdownRing(
          remaining: disp, total: total, color: widget.color,
          size: widget.size, strokeWidth: widget.strokeWidth);
      },
    );
  }
}
```

- [ ] **Step 4: 跑测试确认通过** — Expected: PASS。
- [ ] **Step 5: 提交** — `git commit -m "加 SteppedCountdownRing 内伤读秒环(max-seen)"`

---

### Task 4: `_beatCtrl` 节拍控制器接入 State

**Files:**
- Modify: `lib/features/battle/presentation/battle_screen.dart`(initState ~L305 / dispose ~L365 / `_startTimer` L387-414)

- [ ] **Step 1: initState 建控制器** — 在 initState 现有控制器组末尾加：

```dart
    _beatCtrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: widget.animConfig.actionIntervalMs),
    );
```
并在字段区(与 `_shakeCtrl` 同处)声明 `late final AnimationController _beatCtrl;`。

- [ ] **Step 2: `_startTimer` 同步节拍** — 在 `if (_isPaused) return;` 之前插 `_beatCtrl.stop();`；在设定 `interval` 之后、`_playTimer = Timer.periodic(...)` 里的回调**首行**加 `_beatCtrl..duration = Duration(milliseconds: interval)..forward(from: 0);`（放在 `if (!mounted) return;` 之后、advance 之前，使每拍重启对齐）。同时在 `_playTimer = Timer.periodic` 之前加一次 `_beatCtrl..duration = Duration(milliseconds: interval)..forward(from: 0);`（起手第一拍）。

- [ ] **Step 3: 暂停/待发同步** — 确认 `_togglePause`/`_clearPending`/待发进入路径最终都经 `_startTimer`(其内 `_isPaused` gate 会 `_beatCtrl.stop()`)。若有直接 `_playTimer?.cancel()` 而不过 `_startTimer` 的暂停点，补 `_beatCtrl.stop();`（grep `_playTimer?.cancel()` 逐处核）。

- [ ] **Step 4: dispose 释放** — dispose 内 `_shakeCtrl.dispose();` 旁加 `_beatCtrl.dispose();`。

- [ ] **Step 5: analyze** — Run: `flutter analyze lib/features/battle/presentation/battle_screen.dart` Expected: 0 issue。

- [ ] **Step 6: 提交** — `git commit -m "battle_screen 加 _beatCtrl 节拍控制器(随 timer/暂停同步)"`

---

### Task 5: 把 `beat` + `staggerWindowTicks` 穿到头像与技能按钮

**Files:**
- Modify: `battle_screen.dart`(`_TeamColumn` L1960+ / `_CharacterSlot` L2031 / 技能按钮容器 / 传参链)、`character_avatar.dart`(构造参数)

- [ ] **Step 1: 读破绽窗口配置** — 在 `_BattleScreenState.build` 取 `chargeMaxTicks` 处旁，取 `final staggerWindowTicks = ref.read(numbersConfigProvider)... .combat.defenseBreak.windowTicks;`（对齐现有 `defaultChargeTicks` 读法，L1105 附近模式）。

- [ ] **Step 2: 加构造参数** — 给 `_TeamColumn`/`_CharacterSlot`/`CharacterAvatar`/`_SkillCommandButton`(及其父命令栏 widget)各加 `final Animation<double> beat;` 必填参数；`CharacterAvatar`/`AvatarStatusTags` 再加 `final int staggerWindowTicks;`。沿现有 `chargeMaxTicks` 的传递链逐层透传 `beat`(和 `staggerWindowTicks`)。

- [ ] **Step 3: 顶层传入** — `_BattleScreenState.build` 里构造 `_TeamColumn`/命令栏时传 `beat: _beatCtrl, staggerWindowTicks: staggerWindowTicks`。

- [ ] **Step 4: analyze** — Run: `flutter analyze lib/features/battle/` Expected: 0（此时按钮/头像尚未用 beat，仅透传，编译过）。

- [ ] **Step 5: 提交** — `git commit -m "透传 beat/staggerWindowTicks 到头像与技能按钮"`

---

### Task 6: CD 读秒环接入技能按钮

**Files:**
- Modify: `battle_screen.dart` `_SkillCommandButton.build`(L2480-2580 区)
- Test: `test/features/battle/presentation/battle_tap_skill_test.dart`(追加 or 新 `battle_cd_ring_test.dart`)

- [ ] **Step 1: 写失败测试**(新建 `test/features/battle/presentation/battle_cd_ring_test.dart`；参照 `battle_tap_skill_test.dart` 的战斗 pump 范式，种一个 `skillCooldowns={skillId:2}` 的角色，断言按钮内出现 `BeatCountdownRing` 且中心 `find.text('2')`；ready 态无 `BeatCountdownRing`)。具体 pump 复用现有 tap 测的 harness（含 ProviderContainer/seed）。

- [ ] **Step 2: 跑确认失败** — Expected: FAIL(无 ring)。

- [ ] **Step 3: 接入** — `_SkillCommandButton.build` 的 `child: Stack(...)`(L2541)内、Center Column 之上叠：`if (cd > 0) Positioned.fill(child: Center(child: BeatCountdownRing(remaining: cd, total: skill.cooldownTurns, beat: beat, color: WuxiaColors.lingQiao, size: 44)))`；同时 cd>0 时把 Center Column 包 `Opacity(opacity: 0.35, ...)`（招名让位）；`statusText` 分支中 `cd>0` 一支改为不显文字(环已示数)，保留 pending/内力不足/耗内 文案。

- [ ] **Step 4: 跑确认通过 + analyze** — Expected: PASS + 0 issue。
- [ ] **Step 5: 提交** — `git commit -m "技能按钮 CD 态叠读秒环、招名让位"`

---

### Task 7: 内伤/破绽环取代 `AvatarStatusTags` 药丸

**Files:**
- Modify: `lib/features/battle/presentation/avatar_status_tags.dart`
- Test: `test/features/battle/presentation/avatar_status_tags_test.dart`(改断言)

- [ ] **Step 1: 改测试**(内伤 → 期望出现 `SteppedCountdownRing` + `find.text('3')`，不再期望 `statusInternalInjuryLabel` 文本；破绽 staggerTicksRemaining=2 → 期望 `BeatCountdownRing` + `find.text('2')`；剑鸣仍为 `AvatarStatusTag` 药丸；GlossaryTip 仍在环外层。`AvatarStatusTags` 构造需传 `beat`+`staggerWindowTicks`，测试用 `AnimationController(vsync: TestVSync(), value:0)`)。

- [ ] **Step 2: 跑确认失败** — Expected: FAIL。

- [ ] **Step 3: 改 `AvatarStatusTags`** — 加 `final Animation<double> beat; final int staggerWindowTicks;` 必填。内伤分支 → `GlossaryTip(definition: UiStrings.statusInternalInjuryGloss, child: SteppedCountdownRing(remaining: character.internalInjury!.remainingTurns, color: WuxiaColors.statDecrease, size: 34))`；破绽分支 → `GlossaryTip(definition: UiStrings.statusStaggerGloss, child: BeatCountdownRing(remaining: character.staggerTicksRemaining, total: staggerWindowTicks, beat: beat, color: WuxiaColors.hpLow, size: 34))`；剑鸣仍 `AvatarStatusTag`。仍用现有 `Wrap` 容纳(环+可能的剑鸣药丸)。破绽颜色 `hpLow`(危险语言与踉跄一致)；若采纳 spec 的暖金机会色则用 `WuxiaColors.resultHighlight`——实装先 `hpLow`，真机截图后按 §3.4 定。

- [ ] **Step 4: 跑确认通过 + analyze** — Expected: PASS + 0。
- [ ] **Step 5: 提交** — `git commit -m "内伤/破绽药丸改读秒环、保留 hover 释义与剑鸣药丸"`

---

### Task 8: 蓄力环取代 `_ChargeBar`

**Files:**
- Modify: `lib/features/battle/presentation/character_avatar.dart`(L131-138 `_ChargeBar` 用法；构造加 `beat`)
- Test: `test/features/battle/presentation/avatar_status_tags_test.dart` 或新 `character_avatar_charge_ring_test.dart`

- [ ] **Step 1: 写失败测试** — 种 `chargingSkill!=null` + `chargeTicksRemaining=2` 的敌角色 pump `CharacterAvatar`，断言出现 `BeatCountdownRing` + `find.text('2')`，不再有 `_ChargeBar`(改断言 `find.byType(BeatCountdownRing)` findsWidgets)。`CharacterAvatar` 构造传 `beat`。

- [ ] **Step 2: 跑确认失败** — Expected: FAIL。

- [ ] **Step 3: 替换** — `CharacterAvatar` 加 `final Animation<double> beat;`(必填)与 `staggerWindowTicks`(透传给 AvatarStatusTags)。把 L131-138 的 `_ChargeBar(...)` 换成 `BeatCountdownRing(remaining: character.chargeTicksRemaining, total: chargeMaxTicks, beat: beat, color: WuxiaColors.hpLow, size: 38)` + 旁保留 `Icons.flash_on` 可破招图标(原 `_ChargeBar` 末尾语义)。删 `_ChargeBar` 类(若无他引用，grep 确认)。`AvatarStatusTags(character: character, beat: beat, staggerWindowTicks: staggerWindowTicks)`。

- [ ] **Step 4: 跑确认通过 + analyze** — Expected: PASS + 0。
- [ ] **Step 5: 提交** — `git commit -m "蓄力进度条改读秒环、保留可破招图标"`

---

### Task 9: 节拍同步集成测 + 全量回归

**Files:**
- Test: `test/features/battle/presentation/battle_beat_ring_test.dart`(新)

- [ ] **Step 1: 写集成测试** — pump 真战斗(复用 tap 测 harness)，种一个 `skillCooldowns={id:3}`：① `pump` 后断言环中心 `find.text('3')`；② `tester.pump(interval)` 推进一拍后断言变 `find.text('2')`(cd 递减环随)；③ 暂停(或待发)后再 `pump` 半拍，断言数字不变(`_beatCtrl.stop` 冻结)。

- [ ] **Step 2: 跑确认通过** — Run: `flutter test --no-pub test/features/battle/presentation/battle_beat_ring_test.dart` Expected: PASS。

- [ ] **Step 3: 全量 analyze** — Run: `flutter analyze lib/ test/` Expected: 0 issue。

- [ ] **Step 4: 全量测试** — Run: `flutter test --no-pub -j1` Expected: 全绿(基线 3508 起 + 新测，0 fail；`drop_table_reference_redline_test` 若 flaky 复跑)。

- [ ] **Step 5: 提交** — `git commit -m "加读秒环节拍同步集成测 + 全量回归"`

---

## 真机验收(实装后，本会话 CGEvent 配方)
`flutter run -d macos --dart-define=VISUAL_ROUTE=battle_tap_live`，CGEvent 点击器驱动：CD 环随拍平滑扫 + 中心数字倒数、暂停冻结；蓄力/破绽/内伤环真机观感；破绽 `hpLow` vs 暖金按 §3.4 定。配方见 memory `feedback_flutter_macos_drive_screenshot`。
