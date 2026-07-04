# 技能目标快捷选择栏 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 单体技能：只有 1 个存活敌人时点击即放（默认打它），有 ≥2 个敌人时在技能方块正上方冒出敌人选择栏快捷选目标。

**Architecture:** 纯表现层改 `battle_screen.dart`。`_onSkillTap` 按存活敌人数分流（1→立即出手 / ≥2→待发+选择栏）。选择栏用 `LayerLink` + `CompositeTransformFollower` 浮层锚定在被点技能格上方，脱离底栏 124px 布局流避免裁剪。chip 复用现有 `HpBar` + `WuxiaImage` 头像。出手命令路径 `_onSkillCommand`/`interveneNow` 一字不改。

**Tech Stack:** Flutter, Riverpod 3.x（本改动只用 State setState，不碰 provider），widget test。

**Spec:** `docs/superpowers/specs/2026-07-05-skill-target-chip-design.md`

---

## File Structure

- **Modify** `lib/features/battle/presentation/battle_screen.dart`：
  - `_BattleScreenState` 加 `LayerLink _skillTargetLink` 字段。
  - `_onSkillTap` 加存活敌人数分流。
  - 外层 `Stack`（build，约 L1405 附近）加 `CompositeTransformFollower` + `_TargetChipStrip`。
  - `_BottomBar` 加 `layerLink` 参数，待发格包 `CompositeTransformTarget`。
  - 文件尾加 `_TargetChipStrip`、`_TargetChip` 两个私有 widget。
- **Create** `test/features/battle/presentation/battle_screen_target_chip_test.dart`（复用 `battle_tap_skill_test.dart` 的 `_TestBattleNotifier` spy 体例）。

复用组件（已存在，勿重造）：`HpBar`（`lib/features/battle/presentation/hp_bar.dart`）、`WuxiaImage` + `wuxiaAssetErrorBuilder`（`lib/shared/widgets/`）、`WuxiaColors`（`sidebar`/`border`/`schoolColor`/`barTrack`）。

关键事实（来自现有代码）：
- 技能格 key = `ValueKey('skill_cmd_${characterId}_${skillId}')`。
- `BattleDemo.mockTeams()` → 左队 first `characterId==1`，右队 3 敌 `characterId` 11/12/13，全 alive。
- spy：`interveneNow(characterId, skill, {targetId})`；`_onSkillCommand` 内部调它。
- `_onSkillTap` 现址 L953-984；`_onSkillCommand` 现址 L~988 上方；State 字段区 L304-306。

---

## Task 1: `_onSkillTap` 按存活敌人数分流（1 敌立即放）

**Files:**
- Create: `test/features/battle/presentation/battle_screen_target_chip_test.dart`
- Modify: `lib/features/battle/presentation/battle_screen.dart`（`_onSkillTap` L953-984）

- [ ] **Step 1: 写失败测试（1 敌立即放 + aoe 不变）**

新建 `test/features/battle/presentation/battle_screen_target_chip_test.dart`。开头 import + `_testAnim` + `_TestBattleNotifier` + `_single`/`_aoe` **照抄** `battle_tap_skill_test.dart` L1-125（同 harness）。然后：

```dart
void main() {
  // right 只留 1 个存活敌人（取 mockTeams 右队首个）。
  group('单体技 · 唯一敌人立即放', () {
    testWidgets('1 敌时点单体技 → 立即出手打该敌，不进待发', (tester) async {
      final (left, right) = BattleDemo.mockTeams();
      final focus = left.first.copyWith(availableSkills: [_single]);
      final soloEnemy = right.first; // characterId 11
      final notifier = await _pumpWith(
        tester,
        [focus, ...left.skip(1)],
        [soloEnemy],
      );
      await tester.tap(find.byKey(const ValueKey('skill_cmd_1_single1')));
      await tester.pump();
      expect(notifier.interveneCount, 1, reason: '唯一敌人 → 点击即放');
      expect(notifier.lastInterveneSkill?.id, 'single1');
      expect(notifier.lastInterveneTarget, soloEnemy.characterId);
      expect(find.text(UiStrings.skillPendingStamp), findsNothing,
          reason: '不进待发态');
    });

    testWidgets('1 敌时点 aoe → 立即出手（targetId 空）', (tester) async {
      final (left, right) = BattleDemo.mockTeams();
      final focus = left.first.copyWith(availableSkills: [_aoe]);
      final notifier = await _pumpWith(
        tester,
        [focus, ...left.skip(1)],
        [right.first],
      );
      await tester.tap(find.byKey(const ValueKey('skill_cmd_1_aoe1')));
      await tester.pump();
      expect(notifier.interveneCount, 1);
      expect(notifier.lastInterveneSkill?.id, 'aoe1');
      expect(notifier.lastInterveneTarget, isNull);
    });
  });
}
```

- [ ] **Step 2: 跑测试确认失败**

Run: `flutter test test/features/battle/presentation/battle_screen_target_chip_test.dart --no-pub`
Expected: 「1 敌时点单体技」FAIL —— 现逻辑单体技进待发态，`interveneCount==0`（期望 1）。

- [ ] **Step 3: 改 `_onSkillTap` 加分流**

把 `lib/features/battle/presentation/battle_screen.dart` L976-984（`// single:进待发态 + 软暂停...` 到方法结束的 `_beatCtrl.stop();`）整段替换为：

```dart
    // single:按存活敌人数分流。
    final aliveEnemies = s.rightTeam
        .where((e) => e.isAlive)
        .toList(growable: false);
    if (aliveEnemies.isEmpty) return; // 战斗已结束,守卫。
    if (aliveEnemies.length == 1) {
      // 唯一敌人 → 点击即放:不进待发/不暂停/不选目标。
      if (_pendingSkill != null) _clearPending();
      _onSkillCommand(
        characterId,
        skill,
        targetId: aliveEnemies.first.characterId,
      );
      return;
    }
    // ≥2 敌:进待发态 + 软暂停(选择栏在技能格上方冒出,右侧头像亦可点)。
    setState(() {
      _pendingSkill = skill;
      _pendingCharId = characterId;
      _isPaused = true;
    });
    _playTimer?.cancel();
    _beatCtrl.stop(); // 待发软暂停冻结读秒环节拍。
```

（`s` 已在方法上文 `final s = ref.read(battleProvider);` 定义，直接用。）

- [ ] **Step 4: 跑测试确认通过**

Run: `flutter test test/features/battle/presentation/battle_screen_target_chip_test.dart --no-pub`
Expected: 2 测试 PASS。

- [ ] **Step 5: 跑旧交互测试确认零回归（mockTeams 3 敌仍进待发）**

Run: `flutter test test/features/battle/presentation/battle_tap_skill_test.dart --no-pub`
Expected: 全 PASS（旧测全用 mockTeams=3 敌 → 走 ≥2 分支进待发，行为不变）。

- [ ] **Step 6: Commit**

```bash
git add test/features/battle/presentation/battle_screen_target_chip_test.dart lib/features/battle/presentation/battle_screen.dart
git commit -m "技能目标:唯一敌人时单体技点击即放"
```

---

## Task 2: 多敌选择栏（LayerLink 浮层 + chip 组件）

**Files:**
- Modify: `lib/features/battle/presentation/battle_screen.dart`（State 字段 / 外层 Stack / `_BottomBar` / 文件尾加 widget）
- Modify: `test/features/battle/presentation/battle_screen_target_chip_test.dart`（加 ≥2 敌用例）

- [ ] **Step 1: 写失败测试（≥2 敌 → 选择栏 → 点 chip 出手）**

在测试文件 `main()` 末尾追加 group：

```dart
  group('单体技 · 多敌选择栏', () {
    testWidgets('≥2 敌时点单体技 → 进待发 + 选择栏显 N 个 chip', (tester) async {
      final (left, right) = BattleDemo.mockTeams(); // 3 敌
      final focus = left.first.copyWith(availableSkills: [_single]);
      final notifier = await _pumpWith(tester, [focus, ...left.skip(1)], right);
      await tester.tap(find.byKey(const ValueKey('skill_cmd_1_single1')));
      await tester.pump();
      expect(notifier.interveneCount, 0, reason: '多敌先进待发,不立即出手');
      for (final e in right) {
        expect(
          find.byKey(ValueKey('target_chip_${e.characterId}')),
          findsOneWidget,
        );
      }
    });

    testWidgets('点选择栏 chip → 对该敌出手并清待发', (tester) async {
      final (left, right) = BattleDemo.mockTeams();
      final focus = left.first.copyWith(availableSkills: [_single]);
      final notifier = await _pumpWith(tester, [focus, ...left.skip(1)], right);
      await tester.tap(find.byKey(const ValueKey('skill_cmd_1_single1')));
      await tester.pump();
      // 点第 2 个敌人的 chip（characterId 12）。
      await tester.tap(find.byKey(const ValueKey('target_chip_12')));
      await tester.pump();
      expect(notifier.lastInterveneSkill?.id, 'single1');
      expect(notifier.lastInterveneTarget, 12);
      expect(find.text(UiStrings.skillPendingStamp), findsNothing,
          reason: '出手后清待发');
    });

    testWidgets('aoe 多敌 → 不显选择栏（立即放）', (tester) async {
      final (left, right) = BattleDemo.mockTeams();
      final focus = left.first.copyWith(availableSkills: [_aoe]);
      await _pumpWith(tester, [focus, ...left.skip(1)], right);
      await tester.tap(find.byKey(const ValueKey('skill_cmd_1_aoe1')));
      await tester.pump();
      expect(find.byKey(const ValueKey('target_chip_11')), findsNothing);
    });
  });
```

- [ ] **Step 2: 跑测试确认失败**

Run: `flutter test test/features/battle/presentation/battle_screen_target_chip_test.dart --no-pub`
Expected: 「显 N 个 chip」「点 chip 出手」FAIL —— `target_chip_*` key 尚不存在。

- [ ] **Step 3: State 加 LayerLink 字段**

`lib/features/battle/presentation/battle_screen.dart` L306（`int? _hoveredPendingEnemyId;` 那行）后加：

```dart
  // 技能目标选择栏锚点:待发单体技的技能格 ↔ 其上方浮出的敌人选择栏。
  final LayerLink _skillTargetLink = LayerLink();
```

- [ ] **Step 4: 文件尾加 `_TargetChipStrip` + `_TargetChip`**

在 `battle_screen.dart` 文件尾（`_FocusChip` 类之后或文件末，任意顶层位置）追加。import 段确认已有 `hp_bar.dart`、`wuxia_image.dart`、`asset_fallback.dart`、`colors.dart`——若缺则补 import（`_BottomBar`/`CharacterAvatar` 已用 `WuxiaColors`，`HpBar`/`WuxiaImage` 需确认 import，见 Step 6 analyze）。

```dart
/// 单体技待发态时,在技能格上方冒出的敌人快捷选择栏(存活敌人按 slotIndex 升序)。
class _TargetChipStrip extends StatelessWidget {
  final List<BattleCharacter> enemies;
  final int? hoveredEnemyId;
  final void Function(int enemyId) onSelect;
  final void Function(int enemyId, bool hovering) onHover;

  const _TargetChipStrip({
    required this.enemies,
    required this.hoveredEnemyId,
    required this.onSelect,
    required this.onHover,
  });

  @override
  Widget build(BuildContext context) {
    final sorted = [...enemies]
      ..sort((a, b) => a.slotIndex.compareTo(b.slotIndex));
    return Material(
      color: Colors.transparent,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < sorted.length; i++) ...[
            _TargetChip(
              key: ValueKey('target_chip_${sorted[i].characterId}'),
              enemy: sorted[i],
              hovered: hoveredEnemyId == sorted[i].characterId,
              onTap: () => onSelect(sorted[i].characterId),
              onHover: (h) => onHover(sorted[i].characterId, h),
            ),
            if (i < sorted.length - 1) const SizedBox(width: 6),
          ],
        ],
      ),
    );
  }
}

/// 单个敌人选择 chip:小头像(iconPath,缺图走首字降级) + 细血条。
class _TargetChip extends StatelessWidget {
  final BattleCharacter enemy;
  final bool hovered;
  final VoidCallback onTap;
  final void Function(bool hovering) onHover;

  const _TargetChip({
    super.key,
    required this.enemy,
    required this.hovered,
    required this.onTap,
    required this.onHover,
  });

  @override
  Widget build(BuildContext context) {
    final color = WuxiaColors.schoolColor(enemy.school);
    final firstGlyph = enemy.name.characters.isEmpty
        ? '?'
        : enemy.name.characters.first;
    final hasIcon = enemy.iconPath != null && enemy.iconPath!.isNotEmpty;
    final glyph = Container(
      width: 32,
      height: 32,
      alignment: Alignment.center,
      color: WuxiaColors.avatarFill,
      child: Text(
        firstGlyph,
        style: TextStyle(
          fontSize: 16,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
    return MouseRegion(
      onEnter: (_) => onHover(true),
      onExit: (_) => onHover(false),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 52,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: WuxiaColors.sidebar,
            border: Border.all(
              color: hovered ? color : WuxiaColors.border,
              width: hovered ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(6),
            boxShadow: const [
              BoxShadow(
                color: Color(0x66000000),
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipOval(
                child: SizedBox(
                  width: 32,
                  height: 32,
                  child: hasIcon
                      ? WuxiaImage(
                          enemy.iconPath!,
                          width: 32,
                          height: 32,
                          fit: BoxFit.cover,
                          errorBuilder: wuxiaAssetErrorBuilder(() => glyph),
                        )
                      : glyph,
                ),
              ),
              const SizedBox(height: 3),
              SizedBox(
                width: 40,
                child: HpBar(
                  current: enemy.currentHp,
                  max: enemy.maxHp,
                  height: 4,
                  showLabel: false,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 5: `_BottomBar` 待发格包 `CompositeTransformTarget`**

① `_BottomBar` 加参数。在 `class _BottomBar` 字段区（`final ... beat;` 附近）加 `final LayerLink skillTargetLink;`，构造函数 `required this.skillTargetLink,`。

② 建 `_BottomBar` 处（L1380-1396）加实参：在 `beat: beat,` 前后加 `skillTargetLink: _skillTargetLink,`。

③ 待发格包 Target。在 `_BottomBar.build` 的 skill 循环里（L2441 `return _SkillCommandButton(...)`），把 `return _SkillCommandButton(...)` 改为先建 button 再按待发包裹：

```dart
                              final button = _SkillCommandButton(
                                character: focus,
                                skill: s,
                                isPending:
                                    localPendingThis || domainPendingThis,
                                pendingTapEnabled: localPendingThis,
                                queuedAnother:
                                    domainPending != null &&
                                    domainPending.id != s.id,
                                highlight: enemyCharging && s.canInterrupt,
                                allowPlayerIntervention:
                                    allowPlayerIntervention,
                                beat: beat,
                                onTap: () => onSkillTap(focus.characterId, s),
                                onShowInfo: () => onShowSkillInfo(s),
                              );
                              return localPendingThis
                                  ? CompositeTransformTarget(
                                      link: skillTargetLink,
                                      child: button,
                                    )
                                  : button;
```

（即把原 `return _SkillCommandButton(` 起整块改成 `final button = _SkillCommandButton(` + 结尾 `return localPendingThis ? CompositeTransformTarget(...) : button;`。字段值逐字不变。）

- [ ] **Step 6: 外层 Stack 加浮层选择栏**

在 build 外层 `Stack` 里、`if (_isPaused && !_pendingActive && ...)` 那段（L1420-1424）**之前**，加：

```dart
            // 单体技待发 + ≥2 存活敌人:技能格正上方浮出快捷选择栏。
            if (_pendingActive) _buildTargetChipOverlay(state),
```

并在 `_BattleScreenState` 内（`_onPendingEnemyHover` 方法附近）加 helper：

```dart
  Widget _buildTargetChipOverlay(BattleState state) {
    final aliveEnemies = state.rightTeam
        .where((e) => e.isAlive)
        .toList(growable: false);
    if (aliveEnemies.length < 2) return const SizedBox.shrink();
    return CompositeTransformFollower(
      link: _skillTargetLink,
      showWhenUnlinked: false,
      targetAnchor: Alignment.topCenter,
      followerAnchor: Alignment.bottomCenter,
      offset: const Offset(0, -8),
      child: _TargetChipStrip(
        enemies: aliveEnemies,
        hoveredEnemyId: _hoveredPendingEnemyId,
        onSelect: _onEnemyTap,
        onHover: _onPendingEnemyHover,
      ),
    );
  }
```

- [ ] **Step 7: 跑测试确认通过**

Run: `flutter test test/features/battle/presentation/battle_screen_target_chip_test.dart --no-pub`
Expected: 全 5 测试 PASS。

若「点 chip 出手」miss（浮层被裁剪/命中不到）：确认浮层 `if (_pendingActive) _buildTargetChipOverlay(state)` 在 Stack 内且 `_pendingActive` 为真；chip 用 `GestureDetector` 无 Material 依赖问题。

- [ ] **Step 8: Commit**

```bash
git add lib/features/battle/presentation/battle_screen.dart test/features/battle/presentation/battle_screen_target_chip_test.dart
git commit -m "技能目标:多敌时技能格上方快捷选择栏"
```

---

## Task 3: 收口验证（analyze + 相关全绿）

**Files:** 无新增，仅验证。

- [ ] **Step 1: analyze 零 issue**

Run: `flutter analyze lib/ test/`
Expected: `No issues found!`（若报 `HpBar`/`WuxiaImage`/`wuxiaAssetErrorBuilder` undefined → 在 `battle_screen.dart` import 段补对应 import：`import 'hp_bar.dart';` / `import '../../../shared/widgets/wuxia_image.dart';` / `import '../../../shared/widgets/asset_fallback.dart';`——路径以 analyze 报错为准，改后重跑。）

- [ ] **Step 2: 战斗表现层相关测试全绿**

Run: `flutter test test/features/battle/ --no-pub`
Expected: 全 PASS，零回归（含 `battle_tap_skill_test.dart` 旧两段点选 + 新 target_chip 测）。

- [ ] **Step 3: Commit（若 Step 1 补了 import）**

```bash
git add lib/features/battle/presentation/battle_screen.dart
git commit -m "技能目标:补 chip 组件 import"
```

（无改动则跳过。）

---

## 完成标准

- [ ] 1 敌：单体技点击即放，不进待发。
- [ ] ≥2 敌：技能格上方冒出 N 个敌人 chip（头像+血条），点 chip 出手；右侧头像仍可选（沿用）。
- [ ] aoe：无论几敌立即放，不显选择栏。
- [ ] `flutter analyze lib/ test/` 零 issue。
- [ ] `test/features/battle/` 全绿零回归。
- [ ] 真机 `flutter run -d macos` 目检：1 敌即放 / 多敌选择栏位置贴技能格上方 / chip 血条可读（合并前主窗口安排，可与用户试玩合并）。

## 非目标（YAGNI）

- chip 错峰淡入动画（先静态 Row）。
- AI 推荐目标预高亮。
- 边缘 clamp / 换行（v1 居中,接受轻微溢出）。
