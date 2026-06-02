# P0-2 战斗单位可见化 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax.

**Goal:** 把 3v3 自动战斗从「小圆头像+日志侧栏」改造成「第一眼看得出谁在打谁」——动作位骨架（用现有胸像图）。

**Architecture:** 纯表现层。不改 BattleState 战斗逻辑、不引 Flame。放大单位 + 接线玩家立绘 + 弹道/受击表现 + 日志折叠抽屉 + 胜负遮罩不压暗。动画走 `ref.listen` actionLog 边沿驱动，不污染 state。

**Tech Stack:** Flutter / Riverpod / CustomPainter / AnimationController。spec: docs/superpowers/specs/2026-06-02-p0-2-battle-visibility-design.md

---

## 文件结构

- 改 `lib/features/battle/domain/battle_state.dart:286`（玩家 portraitPath 接线）
- 改 `lib/features/battle/presentation/character_avatar.dart`（放大默认 150 + 死亡 grayscale）
- 改 `lib/data/numbers_config.dart`（AnimationNumbers 加 projectileMs/hitFlashMs）+ `data/numbers.yaml`
- 新 `lib/features/battle/presentation/projectile_trail.dart`（弹道 CustomPainter widget）
- 新 `lib/features/battle/presentation/hit_flash.dart`（受击闪 widget）
- 改 `lib/features/battle/presentation/battle_screen.dart`（删 _LogSidebar + 日志抽屉 + 战场占满宽 + wire 弹道/受击）
- 改 `lib/features/battle/presentation/victory_overlay.dart`（vignette 不压暗）

Phase 0 已验：无测断言日志侧栏文案（删侧栏安全）；CharacterAvatar 死亡 opacity 0.3 已存在（只需叠 grayscale）；avatar 测只断言边框色/宽（放大不破）。baseline 1677 测 / 0 analyze。

---

### Task 1: 玩家 battle 立绘接线

**Files:**
- Modify: `lib/features/battle/domain/battle_state.dart:286`
- Test: `test/combat/battle_state_test.dart`（复用 `_mkChar/_mkEquip/_mkTech`）

- [ ] **Step 1: 写失败测**（加到 battle_state_test.dart `fromCharacter 派生属性` group 内）

```dart
test('玩家方 iconPath 接线到 character.portraitPath（P0-2）', () {
  final c = _mkChar(
    tier: RealmTier.erLiu, layer: RealmLayer.yuanShu, internalForce: 3000,
    school: TechniqueSchool.gangMeng, constitution: 8, agility: 6,
  )..portraitPath = 'assets/characters/founder.png';
  final tech = _mkTech(defId: 'tech_gangmeng_mingjia',
      tier: TechniqueTier.mingJiaGong, school: TechniqueSchool.gangMeng);
  final bc = BattleCharacter.fromCharacter(
    character: c, equipped: const [], mainTechnique: tech,
    numbers: GameRepository.instance.numbers, teamSide: 0, slotIndex: 0,
  );
  expect(bc.iconPath, 'assets/characters/founder.png');
});

test('玩家无立绘 → iconPath null（兜底首字）', () {
  final c = _mkChar(tier: RealmTier.erLiu, layer: RealmLayer.yuanShu,
      internalForce: 3000, school: TechniqueSchool.gangMeng,
      constitution: 8, agility: 6); // portraitPath 默认 null
  final tech = _mkTech(defId: 'tech_gangmeng_mingjia',
      tier: TechniqueTier.mingJiaGong, school: TechniqueSchool.gangMeng);
  final bc = BattleCharacter.fromCharacter(character: c, equipped: const [],
      mainTechnique: tech, numbers: GameRepository.instance.numbers,
      teamSide: 0, slotIndex: 0);
  expect(bc.iconPath, isNull);
});
```

- [ ] **Step 2: 跑测验证失败**

Run: `flutter test test/combat/battle_state_test.dart`
Expected: FAIL（首个 expect 'founder.png' 但实际 null）

- [ ] **Step 3: 改 battle_state.dart:286**

把 `iconPath: null,` 改为 `iconPath: character.portraitPath,`

- [ ] **Step 4: 跑测验证通过**

Run: `flutter test test/combat/battle_state_test.dart`
Expected: PASS

- [ ] **Step 5: commit**

```bash
git add lib/features/battle/domain/battle_state.dart test/combat/battle_state_test.dart
git commit -m "feat(battle): 玩家方战斗单位接线 portraitPath(P0-2 Task1)"
```

---

### Task 2: CharacterAvatar 放大 + 死亡 grayscale

**Files:**
- Modify: `lib/features/battle/presentation/character_avatar.dart`（默认 avatarSize 80→150；死亡叠 grayscale）
- Test: `test/features/battle/presentation/character_avatar_test.dart`

- [ ] **Step 1: 写失败测**（加到 character_avatar_test.dart）

```dart
testWidgets('默认 avatarSize=150（P0-2 放大）', (tester) async {
  await pump(tester, _char(isBoss: false));
  final av = tester.widget<CharacterAvatar>(find.byType(CharacterAvatar));
  expect(av.avatarSize, 150);
});

testWidgets('死亡单位叠 grayscale ColorFiltered（P0-2）', (tester) async {
  final dead = _char(isBoss: false).copyWith(isAlive: false);
  await pump(tester, dead);
  expect(find.byType(ColorFiltered), findsWidgets);
});

testWidgets('存活单位不灰（无 grayscale ColorFiltered）', (tester) async {
  await pump(tester, _char(isBoss: false)); // isAlive 默认 true
  expect(find.byType(ColorFiltered), findsNothing);
});
```

- [ ] **Step 2: 跑测验证失败**

Run: `flutter test test/features/battle/presentation/character_avatar_test.dart`
Expected: FAIL（avatarSize 默认仍 80；无 ColorFiltered）

- [ ] **Step 3: 改 character_avatar.dart**

构造器默认 `this.avatarSize = 80` → `this.avatarSize = 150`。
build 末尾 return（现 `Opacity(opacity: isAlive?1.0:0.3, child: content)`）改为：

```dart
final dimmed = Opacity(
  opacity: character.isAlive ? 1.0 : 0.45,
  child: content,
);
if (character.isAlive) return dimmed;
return ColorFiltered(
  colorFilter: const ColorFilter.matrix(<double>[
    0.2126, 0.7152, 0.0722, 0, 0,
    0.2126, 0.7152, 0.0722, 0, 0,
    0.2126, 0.7152, 0.0722, 0, 0,
    0,      0,      0,      1, 0,
  ]),
  child: dimmed,
);
```

- [ ] **Step 4: 跑测验证通过**

Run: `flutter test test/features/battle/presentation/character_avatar_test.dart`
Expected: PASS（含原边框测，放大不破）

- [ ] **Step 5: commit**

```bash
git add lib/features/battle/presentation/character_avatar.dart test/features/battle/presentation/character_avatar_test.dart
git commit -m "feat(battle): 战斗单位放大150+死亡灰化(P0-2 Task2)"
```

---

### Task 3: AnimationNumbers 加弹道/受击时长

**Files:**
- Modify: `lib/data/numbers_config.dart`（AnimationNumbers class + defaults + fromYaml）
- Modify: `data/numbers.yaml`（animation 段加 projectile_ms / hit_flash_ms）
- Test: `test/data/animation_numbers_test.dart`（新建）

- [ ] **Step 1: 写失败测**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/numbers_config.dart';

void main() {
  test('AnimationNumbers.defaults 含 projectileMs/hitFlashMs', () {
    expect(AnimationNumbers.defaults.projectileMs, 260);
    expect(AnimationNumbers.defaults.hitFlashMs, 150);
  });
  test('fromYaml 解析 projectile_ms/hit_flash_ms', () {
    final n = AnimationNumbers.fromYaml(<String, dynamic>{
      'attack_rush_ms': 1, 'attack_hold_ms': 1, 'attack_retreat_ms': 1,
      'damage_popup_ms': 1, 'action_interval_ms': 1,
      'fast_forward_interval_ms': 1, 'shake_duration_ms': 1,
      'shake_offset_px': 1, 'projectile_ms': 300, 'hit_flash_ms': 120,
    });
    expect(n.projectileMs, 300);
    expect(n.hitFlashMs, 120);
  });
}
```

（注：fromYaml 现有键名以 numbers_config.dart:1330-1337 为准，Step 3 补齐缺键；若 fromYaml 对缺键有默认则相应简化测入参。）

- [ ] **Step 2: 跑测验证失败**

Run: `flutter test test/data/animation_numbers_test.dart`
Expected: FAIL（projectileMs getter 不存在 → 编译错）

- [ ] **Step 3: 改 numbers_config.dart + numbers.yaml**

numbers_config.dart AnimationNumbers：加字段 `final int projectileMs;` `final int hitFlashMs;`；构造器加 `required this.projectileMs, required this.hitFlashMs,`；`defaults` 加 `projectileMs: 260, hitFlashMs: 150,`；`fromYaml` 加 `projectileMs: (y['projectile_ms'] as num?)?.toInt() ?? 260,` `hitFlashMs: (y['hit_flash_ms'] as num?)?.toInt() ?? 150,`。
data/numbers.yaml animation 段加（缩进对齐既有键）：`projectile_ms: 260` `hit_flash_ms: 150`。

- [ ] **Step 4: 跑测验证通过**

Run: `flutter test test/data/animation_numbers_test.dart`
Expected: PASS

- [ ] **Step 5: commit**

```bash
git add lib/data/numbers_config.dart data/numbers.yaml test/data/animation_numbers_test.dart
git commit -m "feat(battle): AnimationNumbers 加弹道/受击时长(P0-2 Task3)"
```

---

### Task 4: 弹道 CustomPainter widget

**Files:**
- Create: `lib/features/battle/presentation/projectile_trail.dart`
- Test: `test/features/battle/presentation/projectile_trail_test.dart`

- [ ] **Step 1: 写失败测**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/battle/presentation/projectile_trail.dart';
import 'package:wuxia_idle/shared/theme/colors.dart';

void main() {
  testWidgets('ProjectileTrail 渲染 CustomPaint 且随 animation 推进', (tester) async {
    final ctrl = AnimationController(vsync: const TestVSync(),
        duration: const Duration(milliseconds: 260));
    addTearDown(ctrl.dispose);
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: ProjectileTrail(
      animation: ctrl, color: WuxiaColors.gangMeng, strokeWidth: 3,
      start: const Offset(0, 0), end: const Offset(100, 0)))));
    expect(find.byType(CustomPaint), findsWidgets);
    ctrl.forward();
    await tester.pump(const Duration(milliseconds: 130));
    expect(tester.takeException(), isNull);
  });
}
```

- [ ] **Step 2: 跑测验证失败**

Run: `flutter test test/features/battle/presentation/projectile_trail_test.dart`
Expected: FAIL（projectile_trail.dart 不存在）

- [ ] **Step 3: 写实现**

```dart
import 'package:flutter/material.dart';

/// 水墨笔触弹道线：攻击者→目标的短动画线段(P0-2)。普攻细/大招粗+流派色。
/// 由 battle_screen 在 actionLog 边沿命令式 spawn，纯表现层。
class ProjectileTrail extends StatelessWidget {
  final Animation<double> animation;
  final Color color;
  final double strokeWidth;
  final Offset start;
  final Offset end;

  const ProjectileTrail({
    super.key,
    required this.animation,
    required this.color,
    required this.strokeWidth,
    required this.start,
    required this.end,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: animation,
        builder: (_, _) => CustomPaint(
          painter: _TrailPainter(
            t: animation.value, color: color,
            strokeWidth: strokeWidth, start: start, end: end),
        ),
      ),
    );
  }
}

class _TrailPainter extends CustomPainter {
  final double t;
  final Color color;
  final double strokeWidth;
  final Offset start;
  final Offset end;
  _TrailPainter({required this.t, required this.color,
      required this.strokeWidth, required this.start, required this.end});

  @override
  void paint(Canvas canvas, Size size) {
    if (t <= 0 || t >= 1) return;
    // 头随 t 前进，尾拖 0.3 形成笔触；整体随 t 渐隐。
    final head = Offset.lerp(start, end, t)!;
    final tail = Offset.lerp(start, end, (t - 0.3).clamp(0.0, 1.0))!;
    final paint = Paint()
      ..color = color.withValues(alpha: (1.0 - t) * 0.9)
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(tail, head, paint);
  }

  @override
  bool shouldRepaint(_TrailPainter old) =>
      old.t != t || old.start != start || old.end != end;
}
```

- [ ] **Step 4: 跑测验证通过**

Run: `flutter test test/features/battle/presentation/projectile_trail_test.dart`
Expected: PASS

- [ ] **Step 5: commit**

```bash
git add lib/features/battle/presentation/projectile_trail.dart test/features/battle/presentation/projectile_trail_test.dart
git commit -m "feat(battle): 弹道笔触 CustomPainter(P0-2 Task4)"
```

---

### Task 5: 受击闪 widget

**Files:**
- Create: `lib/features/battle/presentation/hit_flash.dart`
- Test: `test/features/battle/presentation/hit_flash_test.dart`

- [ ] **Step 1: 写失败测**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/battle/presentation/hit_flash.dart';

void main() {
  testWidgets('HitFlash 命中时叠半透明色块，结束后回调', (tester) async {
    final ctrl = AnimationController(vsync: const TestVSync(),
        duration: const Duration(milliseconds: 150));
    addTearDown(ctrl.dispose);
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: HitFlash(
      animation: ctrl, color: const Color(0xFFFFFFFF),
      child: const SizedBox(width: 50, height: 50)))));
    expect(find.byType(HitFlash), findsOneWidget);
    ctrl.forward();
    await tester.pump(const Duration(milliseconds: 75));
    expect(tester.takeException(), isNull);
  });
}
```

- [ ] **Step 2: 跑测验证失败**

Run: `flutter test test/features/battle/presentation/hit_flash_test.dart`
Expected: FAIL（hit_flash.dart 不存在）

- [ ] **Step 3: 写实现**

```dart
import 'package:flutter/material.dart';

/// 受击闪：命中瞬间在目标上叠一层半透明色块(白/绛红)，随 animation 淡出(P0-2)。
class HitFlash extends StatelessWidget {
  final Animation<double> animation;
  final Color color;
  final Widget child;
  const HitFlash({super.key, required this.animation,
      required this.color, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: animation,
              builder: (_, _) {
                final a = (1.0 - animation.value) * 0.5;
                return ColoredBox(color: color.withValues(alpha: a));
              },
            ),
          ),
        ),
      ],
    );
  }
}
```

- [ ] **Step 4: 跑测验证通过**

Run: `flutter test test/features/battle/presentation/hit_flash_test.dart`
Expected: PASS

- [ ] **Step 5: commit**

```bash
git add lib/features/battle/presentation/hit_flash.dart test/features/battle/presentation/hit_flash_test.dart
git commit -m "feat(battle): 受击闪 widget(P0-2 Task5)"
```

---

### Task 6: 删日志侧栏 + 折叠抽屉 + 战场占满宽

**Files:**
- Modify: `lib/features/battle/presentation/battle_screen.dart`（删 `_LogSidebar`；`_Header` 加日志按钮；加 `_LogDrawer` overlay；build 用本地 `_logOpen` state）
- Test: `test/features/battle/presentation/battle_screen_log_test.dart`（新建，注入短 animConfig + 直接 startBattle seed）

- [ ] **Step 1: 写失败测**

```dart
// 复用现有 battleProvider seed 方式（参照 test/widget_test.dart 如何 pump BattleScreen）。
// 断言：默认无日志历史 ListView 在树；点顶栏日志按钮后历史可见；再点收起。
testWidgets('日志默认收起，点开显历史，再点收起（P0-2）', (tester) async {
  await tester.binding.setSurfaceSize(const Size(1280, 720));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  // ... 用与 test/widget_test.dart 同款 ProviderScope + startBattle seed pump BattleScreen ...
  // 默认：日志抽屉关
  expect(find.byKey(const ValueKey('battle_log_drawer')), findsNothing);
  // 点顶栏日志按钮
  await tester.tap(find.byKey(const ValueKey('battle_log_toggle')));
  await tester.pumpAndSettle();
  expect(find.byKey(const ValueKey('battle_log_drawer')), findsOneWidget);
  // 再点收起
  await tester.tap(find.byKey(const ValueKey('battle_log_toggle')));
  await tester.pumpAndSettle();
  expect(find.byKey(const ValueKey('battle_log_drawer')), findsNothing);
});
```

（注：seed 方式照搬 test/widget_test.dart 现有 BattleScreen pump 模板；实装前先读该文件确认 provider override / startBattle 调用。）

- [ ] **Step 2: 跑测验证失败**

Run: `flutter test test/features/battle/presentation/battle_screen_log_test.dart`
Expected: FAIL（无 battle_log_toggle key）

- [ ] **Step 3: 改 battle_screen.dart**

① `_BattleScreenState` 加 `bool _logOpen = false;`。
② `_Header` 加参数 `final VoidCallback onToggleLog;`，在 `const Spacer()` 后加按钮：
```dart
IconButton(
  key: const ValueKey('battle_log_toggle'),
  icon: const Icon(Icons.list_alt, color: WuxiaColors.textSecondary, size: 20),
  tooltip: UiStrings.battleLog,
  onPressed: onToggleLog,
),
```
③ build：`_Header(state: state)` → `_Header(state: state, onToggleLog: () => setState(() => _logOpen = !_logOpen))`。
④ 删 `Row` 里的 `_LogSidebar(state: state)`，战场 `Expanded(_BattleField(...))` 直接占满（去掉外层 Row 或保留 Row 仅含战场）。
⑤ 删 `_LogSidebar` class，新增 `_LogDrawer`（半透明覆盖层，复用原 ListView.separated 历史，外层 `key: ValueKey('battle_log_drawer')`）；在最外层 Stack 末尾按 `if (_logOpen)` 叠加。

```dart
class _LogDrawer extends StatelessWidget {
  final BattleState state;
  final VoidCallback onClose;
  const _LogDrawer({required this.state, required this.onClose});
  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      key: const ValueKey('battle_log_drawer'),
      child: GestureDetector(
        onTap: onClose,
        child: ColoredBox(
          color: const Color(0x99000000),
          child: Align(
            alignment: Alignment.centerRight,
            child: Container(
              width: 280,
              color: WuxiaColors.sidebar.withValues(alpha: 0.95),
              child: state.actionLog.isEmpty
                  ? const Center(child: Text(UiStrings.emptyLog,
                      style: TextStyle(color: WuxiaColors.textMuted, fontSize: 12)))
                  : ListView.separated(
                      padding: const EdgeInsets.all(8), reverse: true,
                      itemCount: state.actionLog.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 4),
                      itemBuilder: (_, idx) {
                        final i = state.actionLog.length - 1 - idx;
                        return Text(BattleLog.formatAction(state.actionLog[i], state),
                          style: const TextStyle(color: WuxiaColors.textSecondary,
                            fontSize: 12, height: 1.4));
                      }),
            ),
          ),
        ),
      ),
    );
  }
}
```
在最外层 `Stack` children 末尾（UltimateCaptionOverlay 之后）加：
```dart
if (_logOpen)
  _LogDrawer(state: state, onClose: () => setState(() => _logOpen = false)),
```

- [ ] **Step 4: 跑测验证通过**

Run: `flutter test test/features/battle/presentation/battle_screen_log_test.dart`
Expected: PASS

- [ ] **Step 5: commit**

```bash
git add lib/features/battle/presentation/battle_screen.dart test/features/battle/presentation/battle_screen_log_test.dart
git commit -m "feat(battle): 删日志侧栏+折叠抽屉+战场占满宽(P0-2 Task6)"
```

---

### Task 7: wire 弹道 + 受击闪到 _playAction

**Files:**
- Modify: `lib/features/battle/presentation/battle_screen.dart`（`_playAction` 命中时 spawn 弹道 + 在目标 slot 触发受击闪；新增 controller 池 + state；战斗 wiring 维度——只读 actionLog，不写 BattleState）
- Test: `test/features/battle/presentation/battle_screen_log_test.dart`（加断言：actionLog 推进后无异常 + 弹道 widget 出现）

- [ ] **Step 1: 写失败测**

```dart
testWidgets('攻击命中时出现弹道 ProjectileTrail（P0-2 · 不污染 state）', (tester) async {
  await tester.binding.setSurfaceSize(const Size(1280, 720));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  // ... pump BattleScreen 并推进若干 tick 直到有命中 action ...
  await tester.pump(const Duration(milliseconds: 50));
  expect(find.byType(ProjectileTrail), findsWidgets);
  // state 未被表现层污染：actionLog 由引擎产生，UI 不写
  expect(tester.takeException(), isNull);
});
```

- [ ] **Step 2: 跑测验证失败**

Run: `flutter test test/features/battle/presentation/battle_screen_log_test.dart`
Expected: FAIL（无 ProjectileTrail）

- [ ] **Step 3: 改 battle_screen.dart**

① 加 6 个 `_hitFlashControllers`（slotKey 索引，duration=hitFlashMs）+ 1 个共享/池化 `_projectileController`（duration=projectileMs）+ `Map<int,_TrailEntry> _activeTrails`（slotKey→弹道几何）。dispose 同步释放。
② `_playAction`：在 `if (action.attackResult != null && action.targetId != null)` 分支内，除现有 _spawnPopup 外：
- 触发目标 slot 的 `_hitFlashControllers[targetKey].forward(from:0)`（暴击 color=绛红 gangMeng，否则白）。
- spawn 弹道：用攻击者 slot 中心→目标 slot 中心（用 GlobalKey 测 slot RenderBox 中心，或按队列固定坐标近似），`_projectileController.forward(from:0)`，大招 strokeWidth 5+流派色 / 普攻 3。
③ `_CharacterSlot` 用 `HitFlash(animation: hitFlashCtrl, color: flashColor, child: AttackAnimationWidget(...))` 包裹。
④ 弹道层叠在 `_BattleField` 上方（Stack），用 `ProjectileTrail`，end 动画后清。
⑤ **战斗 wiring 红线**：以上全部在 `_BattleScreenState` 本地 state + AnimationController，**不调用任何 notifier 写方法**，只读 `next.actionLog`（沿现有 _disabledUltimateChars 本地 state 体例，spec §16.2）。

（注：slot 坐标方案——实装时优先用每个 _CharacterSlot 的 GlobalKey 取中心；若 widget test 下 RenderBox 不稳，退按 teamSide/slotIndex 的战场布局比例近似坐标，二者都不写 state。）

- [ ] **Step 4: 跑测验证通过**

Run: `flutter test test/features/battle/presentation/battle_screen_log_test.dart`
Expected: PASS

- [ ] **Step 5: commit**

```bash
git add lib/features/battle/presentation/battle_screen.dart test/features/battle/presentation/battle_screen_log_test.dart
git commit -m "feat(battle): wire 弹道+受击闪(actionLog 边沿·不污染 state)(P0-2 Task7)"
```

---

### Task 8: 胜负遮罩 vignette 不压暗

**Files:**
- Modify: `lib/features/battle/presentation/victory_overlay.dart`（整屏暗幕 → 径向 vignette）
- Test: `test/features/battle/presentation/victory_overlay_test.dart`（保留现有断言 + 加 vignette/非全黑断言）

- [ ] **Step 1: 写失败测**（加到 victory_overlay_test.dart）

```dart
testWidgets('遮罩用径向渐变 vignette 而非整屏纯黑（P0-2）', (tester) async {
  await tester.pumpWidget(MaterialApp(home: VictoryOverlay(
    result: BattleResult.leftWin, totalDamage: 1, critCount: 0,
    totalTicks: 1, onContinue: () {})));
  // 顶层背景容器不再是纯黑 0xB3000000 纯色，而是带 RadialGradient
  final deco = tester.widgetList<Container>(find.byType(Container))
      .map((c) => c.decoration).whereType<BoxDecoration>()
      .firstWhere((d) => d.gradient is RadialGradient);
  expect(deco.gradient, isA<RadialGradient>());
});
```

- [ ] **Step 2: 跑测验证失败**

Run: `flutter test test/features/battle/presentation/victory_overlay_test.dart`
Expected: FAIL（现为 `color: 0xB3000000` 纯色，无 RadialGradient）

- [ ] **Step 3: 改 victory_overlay.dart**

最外层 `Container(color: const Color(0xB3000000), ...)` 改为：
```dart
Container(
  decoration: const BoxDecoration(
    gradient: RadialGradient(
      radius: 0.9,
      colors: [Color(0x33000000), Color(0xCC000000)], // 中心淡→四周暗角
      stops: [0.45, 1.0],
    ),
  ),
  alignment: Alignment.center,
  child: Column( ... 保留原题字/印章/统计/按钮不变 ... ),
)
```

- [ ] **Step 4: 跑测验证通过**

Run: `flutter test test/features/battle/presentation/victory_overlay_test.dart`
Expected: PASS（原 胜/败 题字断言仍过）

- [ ] **Step 5: commit**

```bash
git add lib/features/battle/presentation/victory_overlay.dart test/features/battle/presentation/victory_overlay_test.dart
git commit -m "feat(battle): 胜负遮罩 vignette 不压暗(P0-2 Task8)"
```

---

### Task 9: 全量验证 + 截图验收 handoff

**Files:**
- Create: `docs/handoff/codex_visual_battle_p0_2_2026-06-XX.md`（派单 doc，沿既有 codex_visual_* 体例）

- [ ] **Step 1: 全量 analyze**

Run: `flutter analyze`
Expected: No issues found

- [ ] **Step 2: 全量 test**

Run: `flutter test`
Expected: All tests passed（baseline 1677 + 本批新增；记录实际数）

- [ ] **Step 3: 写 Codex@Pen 截图验收派单 doc**

路由：用现有 VISUAL_ROUTE battle 验收屏（battle_scene / battle_boss_frame）。验收门：
- `07_battle_running.png`：我方/敌方各三单位放大可辨（玩家有立绘显立绘/无显首字、敌人显图）+ 弹道线可见 + 日志默认收起。
- `battle_skill.png`：大招弹道粗+流派色 + 题字 overlay。
- `08_battle_result.png`：胜利遮罩为 vignette，战场单位仍清晰可读（非全黑）。
- 死亡单位灰化可辨。

- [ ] **Step 4: commit + push**

```bash
git add docs/handoff/codex_visual_battle_p0_2_2026-06-XX.md
git commit -m "docs: P0-2 战斗可见化 Codex 截图验收派单"
git push origin main
```

- [ ] **Step 5: 用户/ Codex 实机验收后回填 closeout**

---

## Self-Review

- **Spec 覆盖**：A 放大→T2 / B 接线→T1 / C 弹道受击→T3/T4/T5/T7 / D 日志抽屉→T6 / E 遮罩→T8 / F 测试+验收→各 T + T9。全覆盖。
- **占位扫描**：无 TBD；T6/T7 的 seed/坐标方案留「实装前读 widget_test.dart / GlobalKey 优先」注记（非占位，是实装决策点，已给二选一兜底）。
- **类型一致**：ProjectileTrail(animation,color,strokeWidth,start,end) / HitFlash(animation,color,child) / AnimationNumbers.projectileMs/hitFlashMs / ValueKey('battle_log_toggle'|'battle_log_drawer') 跨任务一致。
