# 两段点选替代拖招技能释放 实装计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 把战斗技能介入从「长按拖招到敌头像」改为「点技能→(单体)软暂停点敌 / (AOE)一键即放」的两段点选，保留 `interveneNow` 立即出手语义。

**Architecture:** 纯交互+表现层重构，落在 `battle_screen.dart`。删除拖招四回调 + 引导线 + `_rushToActorId` 快进；技能按钮 `GestureDetector(长按)` → `onTap`；敌头像在待发态可 `onTap` 直传 enemyId（**不再走全局坐标 `hitTestEnemyId`**，tap 模型下头像自身即知 enemyId）；待发态复用现有 `_isPaused` 软暂停基建。底层 `interveneNow` / `battle_ai` / `AutoPlayMode` 零改。

**Tech Stack:** Flutter Desktop, Riverpod 3.x, flutter_test widget test。

**红线（每个 task 守）:** 零碰 numbers.yaml / saveVer / schema / 伤害结算 / 三系锁死 / 在线=离线。中文文案进 `UiStrings`，不散写。

**设计来源:** `docs/superpowers/specs/2026-06-30-tap-skill-cast-replace-drag-design.md`

**实装环境:** 走 EnterWorktree 隔离（feat/tap-skill-cast），fresh worktree 需 `flutter pub get` + 拷 libisar.dylib + `build_runner`（memory `feedback_subagent_driven_fresh_worktree_env_prep`）。

---

## 关键现状锚点（实装前已核 · file:line）

- 状态字段：`battle_screen.dart:325-336`（`_dragSkill/_dragCharId/_dragOrigin/_dragPointer/_hoveredEnemyId/_rushToActorId` + `_enemyAvatarKeys` L327/369）
- 命令层：`_onSkillCommand` L892（门控+ready+`interveneNow`+setState，**复用**）
- 拖招回调：`_onSkillDragStart/Update/End/Cancel` L931-978（**删/改**）
- 命中：`hitTestEnemyId` L126 + `_collectEnemyTargets` L981（tap 模型下**删**，及其 4 个纯函数单测）
- timer/pause：`_startTimer` L436（`rushing = _isFastForward || _rushToActorId != null` L443）/ `_togglePause` L468 / `_isPaused` gate L441
- 快进 C5：`ref.listen` 块 L1190-1214（`_rushToActorId` 消费/兜底/恢复，**删**）
- 技能按钮 widget：`_SkillCommandButton` L2425（字段 `onDragStart/onDragUpdate/onDragEnd/onDragCancel` L2434-2437；`GestureDetector` 长按 L2575-2587）；调用处 L2302-2306
- 队列 widget：`_TeamColumn` L2024（字段 `avatarKeys/hoveredEnemyId/rushActorId` L2037-2039；右队接 `enemyAvatarKeys` L2013）
- 敌头像：`CharacterAvatar`（`character_avatar.dart`，测试用 `w is CharacterAvatar && w.character.characterId==11` 定位）
- 枚举：`TargetType { single, aoe }` `lib/core/domain/enums.dart:135`
- route：`battleDragLive`('battle_drag_live') / `battleDragPreview`('battle_drag_preview') `lib/features/debug/application/visual_route.dart:117-124`
- 现有测试：`test/features/battle/presentation/battle_drag_skill_test.dart`（spy `_TestBattleNotifier` override `interveneNow` 记 `lastInterveneChar/Skill/Target` + `interveneCount`；按钮 key `ValueKey('skill_cmd_<charId>_<skillId>')`）

---

## Task 1: route 改名 battleDrag* → battleTap*

**Files:**
- Modify: `lib/features/debug/application/visual_route.dart:117-124`
- Modify: 所有引用 `battleDragLive`/`battleDragPreview` 的文件（grep 同步）

- [ ] **Step 1: grep 全引用**

Run: `grep -rn "battleDragLive\|battleDragPreview" lib/ test/`
Expected: 列出 enum 定义 + visual_route_host 的 switch 分支 + 任何预置态构造（如 `rushActorId` preview，见 Task 2）。

- [ ] **Step 2: 改 enum 定义 + 描述**

`visual_route.dart:117-124` 改为：

```dart
  battleTapLive(
    'battle_tap_live',
    '两段点选交互真玩/验收(真战斗·已开干预·高血耐久敌久撑 → 点 single 强力技进待发态(软暂停)点敌头像出手 / 点 aoe 大招一键即对全体触发)',
  ),
  battleTapPreview(
    'battle_tap_preview',
    '两段点选表现层静态验收(冻结画面预置态·Codex 截图:技能按钮高亮待发态 + 敌头像可选标记 + 单体/群体角标)',
  ),
```

- [ ] **Step 3: 同步 host switch + 任何 by-name 引用**

把 Step 1 grep 出的 `battleDragLive`→`battleTapLive`、`battleDragPreview`→`battleTapPreview` 全部改名（含 host 的 `case` 分支与构造 args）。route 字符串 id `battle_drag_live`→`battle_tap_live` 同步。

- [ ] **Step 4: 验证编译**

Run: `flutter analyze lib/features/debug/`
Expected: 0 issue（无 undefined name）。

- [ ] **Step 5: Commit**

```bash
git add lib/features/debug/
git commit -m "refactor: 视觉验收 route battleDrag* 改名 battleTap*"
```

---

## Task 2: 删除 _rushToActorId 拖招快进（C5）

**Files:**
- Modify: `battle_screen.dart`（状态 L336 / `_startTimer` L443 / `ref.listen` L1190-1214 / `_TeamColumn` rushActorId L2015,L2039,L1997 / preview 预置 L374）

- [ ] **Step 1: grep 全引用**

Run: `grep -n "_rushToActorId\|rushActorId\|rushActor" lib/features/battle/presentation/battle_screen.dart`
Expected: 状态字段、`_startTimer` rushing、listen 块、`_TeamColumn` 字段与两处传参、preview 预置（`preview.rushActorId` L374）。

- [ ] **Step 2: 删状态字段**

`battle_screen.dart:335-336` 删 `_rushToActorId` 声明（含注释行）。

- [ ] **Step 3: 简化 _startTimer**

L443 `final rushing = _isFastForward || _rushToActorId != null;` 改为：

```dart
    final rushing = _isFastForward;
```

- [ ] **Step 4: 删 C5 listen 逻辑**

`battle_screen.dart:1190-1214` 块：移除 `wasRushing`、`_rushToActorId` 消费循环、被击杀兜底、`wasRushing && _rushToActorId == null` 恢复分支。保留 `_playAction(a, next)` 循环本体。改写为：

```dart
      if (prev != null && next.actionLog.length > prev.actionLog.length) {
        final newActions = next.actionLog.sublist(prev.actionLog.length);
        for (final a in newActions) {
          _playAction(a, next);
        }
      }
```

- [ ] **Step 5: 清 _TeamColumn rushActorId 参数**

删 `_TeamColumn` 字段 `rushActorId`（L2039）+ 构造参数 + 两处传参（左队 L1997 `rushActorId: rushActorId`、右队 L2015 `rushActorId: null`）+ 该外层 widget 的 `rushActorId` 字段/参数（L1997 来源）。`_TeamColumn` 内部用 `rushActorId` 做「蓄势高亮」的分支一并删（grep `rushActorId` 在 `_TeamColumn` body）。

- [ ] **Step 6: 清 preview 预置**

L374 `_rushToActorId = preview.rushActorId;` 删除。若 `BattleScreenPreview`/预置类型有 `rushActorId` 字段且无其它消费者，一并删字段（grep 确认无其它引用后删）。

- [ ] **Step 7: 验证**

Run: `flutter analyze lib/features/battle/`
Expected: 0 issue。
Run: `flutter test --no-pub test/features/battle/`
Expected: 现有 battle 测试全过（drag 测试此刻仍在，长按拖招逻辑未动，仍应过；若 preview rushActorId 测试存在则同步）。

- [ ] **Step 8: Commit**

```bash
git add lib/features/battle/presentation/battle_screen.dart lib/features/debug/
git commit -m "refactor: 删拖招快进 _rushToActorId(两段点选不需加速跳到出手)"
```

---

## Task 3: 待发态状态 + tap 释放主流程（核心 · TDD）

**Files:**
- Modify: `battle_screen.dart`（状态字段 / 新方法 / `_SkillCommandButton` / `_TeamColumn` 敌头像 onTap）
- Test: `test/features/battle/presentation/battle_drag_skill_test.dart`（本 task 临时加 tap case 驱动；Task 8 整体重写改名）

本 task 的状态/按钮/敌头像接线必须一起才能让 tap 测试通过，故含多 step。

- [ ] **Step 1: 写失败测试（AOE 一键即放）**

在 `battle_drag_skill_test.dart` `main()` 内追加：

```dart
  group('两段点选 · tap 释放', () {
    testWidgets('点 aoe 技能按钮 → 立即出手(targetId 空走 AI)', (tester) async {
      final (left, right) = BattleDemo.mockTeams();
      final focus = left.first.copyWith(availableSkills: [_aoe]);
      final notifier = await _pumpWith(tester, [focus, ...left.skip(1)], right);

      await tester.tap(find.byKey(const ValueKey('skill_cmd_1_aoe1')));
      await tester.pump();

      expect(notifier.lastInterveneSkill?.id, 'aoe1');
      expect(notifier.lastInterveneChar, 1);
      expect(notifier.lastInterveneTarget, isNull);
    });

    testWidgets('点 single 技能按钮进待发态(不出手) → 点敌头像出手指向该敌',
        (tester) async {
      final (left, right) = BattleDemo.mockTeams();
      final focus = left.first.copyWith(availableSkills: [_single]);
      final notifier = await _pumpWith(tester, [focus, ...left.skip(1)], right);

      await tester.tap(find.byKey(const ValueKey('skill_cmd_1_single1')));
      await tester.pump();
      expect(notifier.interveneCount, 0, reason: '单体技点按钮只进待发态,不出手');

      final enemy = find.byWidgetPredicate(
        (w) => w is CharacterAvatar && w.character.characterId == 11,
      );
      await tester.tap(enemy);
      await tester.pump();

      expect(notifier.lastInterveneSkill?.id, 'single1');
      expect(notifier.lastInterveneTarget, 11);
    });

    testWidgets('非待发态点敌头像不出手', (tester) async {
      final (left, right) = BattleDemo.mockTeams();
      final focus = left.first.copyWith(availableSkills: [_single]);
      final notifier = await _pumpWith(tester, [focus, ...left.skip(1)], right);

      final enemy = find.byWidgetPredicate(
        (w) => w is CharacterAvatar && w.character.characterId == 11,
      );
      await tester.tap(enemy);
      await tester.pump();

      expect(notifier.interveneCount, 0, reason: '没先点技能,点敌头像无效');
    });
  });
```

- [ ] **Step 2: 跑测试确认失败**

Run: `flutter test --no-pub test/features/battle/presentation/battle_drag_skill_test.dart -n "两段点选"`
Expected: FAIL（当前按钮是长按拖、敌头像无 onTap）。

- [ ] **Step 3: 重构状态字段**

`battle_screen.dart:328-336` 拖招态注释块改为待发态：

```dart
  // 待发态(纯 UI,不写 BattleState):已点选待发的单体技与其拖招者 charId。
  // null = 无待发。AOE 不进待发态(点按钮直接出手)。
  SkillDef? _pendingSkill;
  int? _pendingCharId;
```

删 `_dragSkill/_dragCharId/_dragOrigin/_dragPointer/_hoveredEnemyId`。`_enemyAvatarKeys`（L327/369）保留与否：tap 模型下敌头像 onTap 直传 id，不再需要全局矩形命中——若 Task 5 确认 `_TeamColumn` 改用 onTap 回调，则删 `_enemyAvatarKeys` + `_collectEnemyTargets`(L981) + `hitTestEnemyId`(L126) + 其 4 个纯函数单测（test 文件 group `'hitTestEnemyId 纯函数'`）。

- [ ] **Step 4: 替换命令方法**

删 `_onSkillDragStart/Update/End/Cancel`(L931-978) 与 `_clearDrag`、`_collectEnemyTargets`(L981)。`_onSkillCommand`(L892) 保留不动。新增：

```dart
  /// 点技能按钮:single → 进待发态(软暂停);aoe → 直接出手。
  void _onSkillTap(int characterId, SkillDef skill) {
    if (!widget.allowPlayerIntervention) return;
    final s = ref.read(battleProvider);
    BattleCharacter? c;
    for (final ch in s.leftTeam) {
      if (ch.characterId == characterId) { c = ch; break; }
    }
    if (c == null || !_isSkillReady(c, skill)) return;
    if (skill.targetType == TargetType.aoe) {
      _onSkillCommand(characterId, skill); // 一键即放,AI 选目标
      return;
    }
    // single:进待发态 + 软暂停。
    setState(() {
      _pendingSkill = skill;
      _pendingCharId = characterId;
      _isPaused = true;
    });
    _playTimer?.cancel(); // 复用 H3 暂停语义,gate 兜重启
  }

  /// 待发态下点敌头像 → 对该敌出手 + 解除待发态 + 恢复 tick。
  void _onEnemyTap(int enemyId) {
    final skill = _pendingSkill;
    final charId = _pendingCharId;
    if (skill == null || charId == null) return;
    _clearPending();
    _onSkillCommand(charId, skill, targetId: enemyId);
  }

  /// 解除待发态并恢复自动播放(取消 / 出手后共用)。
  void _clearPending() {
    setState(() {
      _pendingSkill = null;
      _pendingCharId = null;
      _isPaused = false;
    });
    if (!ref.read(battleProvider).isFinished) _startTimer();
  }
```

- [ ] **Step 5: `_SkillCommandButton` 改 onTap（见 Task 4 完整代码）**

本 step 先把 `_SkillCommandButton` 的 `onDrag*` 四字段 + L2575 `GestureDetector` 换成单一 `onTap` 回调（详细代码在 Task 4，可合并实现）。调用处 L2302-2306 改为 `onTap: () => _onSkillTap(character.characterId, skill)`。

- [ ] **Step 6: 敌头像 onTap 接线（见 Task 5 完整代码）**

`_TeamColumn` 加 `onEnemyTap` 回调（右队透传 `_onEnemyTap`，左队传 null），敌头像 `CharacterAvatar` 外包 `GestureDetector(onTap: enabled ? () => onEnemyTap?.call(enemyId) : null)`，仅 `_pendingSkill != null`（待发态）时可点。

- [ ] **Step 7: 跑测试确认通过**

Run: `flutter test --no-pub test/features/battle/presentation/battle_drag_skill_test.dart -n "两段点选"`
Expected: PASS（3 case）。

- [ ] **Step 8: Commit**

```bash
git add lib/features/battle/presentation/battle_screen.dart test/features/battle/presentation/battle_drag_skill_test.dart
git commit -m "feat: 两段点选 tap 释放主流程(single 待发态软暂停+点敌出手 / aoe 一键)"
```

---

## Task 4: _SkillCommandButton 长按拖 → onTap

**Files:**
- Modify: `battle_screen.dart:2425-2588`（`_SkillCommandButton`）+ 调用处 L2302-2306

- [ ] **Step 1: 改字段**

`_SkillCommandButton`(L2434-2437) 删 `onDragStart/onDragUpdate/onDragEnd/onDragCancel`，加：

```dart
  final VoidCallback onTap;
```

构造参数（L2447-2450）同步：删 4 个 `required this.onDrag*`，加 `required this.onTap`。

- [ ] **Step 2: 改 build 手势**

L2569-2587 段：保留 `button`（含 `onPressed: _showSkillInfo` 弹简介，可改为长按弹简介或保留点击查看；见下注），把 `enabled` 时的 `GestureDetector(onLongPress*...)` 替换为：

```dart
    if (!enabled) return button;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: button,
    );
```

注：原 `button.onPressed` 是「点击弹技能简介」。tap 现用于释放，简介改为**长按**弹出（`onLongPress: () => _showSkillInfo(skill)` 加到该 GestureDetector），保留查看能力且不抢 tap。把 `button` 内部的 `onPressed` 简介触发移除/改为 null，避免双触发。

- [ ] **Step 3: 改调用处**

L2302-2306：

```dart
                            onTap: () =>
                                onSkillTap(character.characterId, skill),
```

外层 widget（`_TeamColumn` 或其上层）需把 `onSkillTap` 回调透传到 `_SkillCommandButton`（沿用原 `onSkillDrag*` 的透传链，改名 `onSkillTap`，类型 `void Function(int, SkillDef)`）。

- [ ] **Step 4: 验证**

Run: `flutter analyze lib/features/battle/`
Expected: 0 issue。

- [ ] **Step 5: Commit**

```bash
git add lib/features/battle/presentation/battle_screen.dart
git commit -m "refactor: 技能按钮长按拖→onTap,简介改长按弹出"
```

---

## Task 5: 敌头像 onTap 接线 + 待发态高亮

**Files:**
- Modify: `battle_screen.dart`（`_TeamColumn` L2024 + 敌头像渲染 + 上层透传）

- [ ] **Step 1: _TeamColumn 加 onEnemyTap + isPending**

字段（L2037-2039 区）改：删 `hoveredEnemyId`，加：

```dart
  final void Function(int enemyId)? onEnemyTap; // 仅右队(敌方)非空且待发态可点
  final bool pendingActive; // 当前是否待发态(决定敌头像可点 + 高亮)
```

构造参数同步。右队传 `onEnemyTap: _onEnemyTap, pendingActive: _pendingSkill != null`（L2002 区），左队传 `onEnemyTap: null, pendingActive: false`。

- [ ] **Step 2: 敌头像包 GestureDetector**

`_TeamColumn` 内渲染每个 `CharacterAvatar` 处，存活敌头像外包：

```dart
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: (onEnemyTap != null && pendingActive && character.isAlive)
              ? () => onEnemyTap!(character.characterId)
              : null,
          child: avatarWidget, // 原 CharacterAvatar (含 avatarKeys[i] 若仍保留)
        )
```

- [ ] **Step 3: 待发态可选标记（高亮）**

`pendingActive && character.isAlive` 时给敌头像加可选视觉（如浅金描边 / 角标），深底色板用 `WuxiaColors.*`（守 memory `feedback_paper_vs_dark_text_color_palette`，勿用浅底墨色）。具体样式实装时真机迭代，先用细描边占位。

- [ ] **Step 4: 验证 + 跑 Task 3 测试**

Run: `flutter analyze lib/features/battle/` → 0 issue
Run: `flutter test --no-pub test/features/battle/presentation/battle_drag_skill_test.dart`
Expected: 两段点选 case 全过；门控 case（见 Task 8 改写后）。

- [ ] **Step 5: Commit**

```bash
git add lib/features/battle/presentation/battle_screen.dart
git commit -m "feat: 敌头像待发态可点出手 + 可选标记高亮"
```

---

## Task 6: 取消交互（空白点击 + ESC · TDD）

**Files:**
- Modify: `battle_screen.dart`（战斗区外层手势 + 键盘监听）
- Test: `battle_drag_skill_test.dart`

- [ ] **Step 1: 写失败测试**

追加到 `'两段点选 · tap 释放'` group：

```dart
    testWidgets('待发态再点同一技能按钮 → 取消(不出手)', (tester) async {
      final (left, right) = BattleDemo.mockTeams();
      final focus = left.first.copyWith(availableSkills: [_single]);
      final notifier = await _pumpWith(tester, [focus, ...left.skip(1)], right);

      final btn = find.byKey(const ValueKey('skill_cmd_1_single1'));
      await tester.tap(btn);
      await tester.pump();
      await tester.tap(btn); // 再点 = 取消
      await tester.pump();

      final enemy = find.byWidgetPredicate(
        (w) => w is CharacterAvatar && w.character.characterId == 11,
      );
      await tester.tap(enemy);
      await tester.pump();
      expect(notifier.interveneCount, 0, reason: '已取消,点敌不出手');
    });
```

- [ ] **Step 2: 跑确认失败**

Run: `flutter test --no-pub test/features/battle/presentation/battle_drag_skill_test.dart -n "再点同一技能"`
Expected: FAIL（再点又进待发态，敌 tap 仍出手）。

- [ ] **Step 3: 实现「再点取消」**

`_onSkillTap` single 分支开头加：待发态下再点同一技能 → 取消。

```dart
    if (skill.targetType != TargetType.aoe &&
        _pendingSkill?.id == skill.id &&
        _pendingCharId == characterId) {
      _clearPending();
      return;
    }
```

（置于 ready 校验后、setState 待发态前。）

- [ ] **Step 4: 实现「空白点击取消」**

战斗主区根 widget 外包 `GestureDetector(behavior: HitTestBehavior.translucent, onTap: () { if (_pendingSkill != null) _clearPending(); })`。敌头像/技能按钮的 `behavior: opaque` 已拦截各自 tap，空白落到根手势。

- [ ] **Step 5: 实现 ESC 取消**

战斗屏根包 `Focus`（autofocus）+ `onKeyEvent`：

```dart
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.escape &&
            _pendingSkill != null) {
          _clearPending();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
```

import `package:flutter/services.dart`。

- [ ] **Step 6: 跑测试通过**

Run: `flutter test --no-pub test/features/battle/presentation/battle_drag_skill_test.dart`
Expected: PASS（再点取消 case 过；空白/ESC 由真机验，widget 测覆盖再点取消即可）。

- [ ] **Step 7: Commit**

```bash
git add lib/features/battle/presentation/battle_screen.dart test/features/battle/presentation/battle_drag_skill_test.dart
git commit -m "feat: 待发态取消(再点技能/空白点击/ESC)"
```

---

## Task 7: 单体/群体类型角标 + 文案清理

**Files:**
- Modify: `battle_screen.dart`（`_SkillCommandButton` 角标）
- Modify: `lib/shared/strings.dart`（拖招提示文案）

- [ ] **Step 1: 角标**

`_SkillCommandButton` build 内技能按钮加类型角标：`skill.targetType == TargetType.aoe` → 群体图标/字，否则单体图标/字。用 `Icon` 或短字（如「群」/「单」），深底色板配色。样式真机迭代。

- [ ] **Step 2: 文案**

`UiStrings.skillInfoDragHint`（L2658 引用）当前是「拖招提示」。改文案为点选提示（如「点技能选招，单体技再点敌人出手」），或新增 `skillTapHint` 并替换引用。grep `skillInfoDragHint` 确认引用点全改。不在 Dart 散写中文，全进 `UiStrings`。

- [ ] **Step 3: 验证**

Run: `flutter analyze lib/`
Expected: 0 issue。

- [ ] **Step 4: Commit**

```bash
git add lib/features/battle/presentation/battle_screen.dart lib/shared/strings.dart
git commit -m "feat: 技能按钮单体/群体角标 + 点选提示文案"
```

---

## Task 8: 测试改名重写 + 全量验证 + 真机/route 验收

**Files:**
- Rename: `test/.../battle_drag_skill_test.dart` → `battle_tap_skill_test.dart`
- Modify: 该测试文件（清残留 drag helper / hitTest group / 门控 case 改 tap）

- [ ] **Step 1: git mv + 改内容**

```bash
git mv test/features/battle/presentation/battle_drag_skill_test.dart test/features/battle/presentation/battle_tap_skill_test.dart
```

改内容：① 删 `_longPressDragTo` helper（不再用长按拖）；② 删 `'hitTestEnemyId 纯函数'` group（Task 3 已删 hitTest）+ `hitTestEnemyId` import；③ `'C4 群体技拖招触发'`/`'C3+C4 单体拖招命中'` group 删（已被 Task 3 的「两段点选」group 覆盖等价语义）；④ 门控 group 两 case 改 tap：

```dart
  group('门控 allowPlayerIntervention', () {
    testWidgets('false 时点 aoe 不出手', (tester) async {
      final (left, right) = BattleDemo.mockTeams();
      final focus = left.first.copyWith(availableSkills: [_aoe]);
      final notifier = await _pumpWith(
        tester, [focus, ...left.skip(1)], right,
        allowPlayerIntervention: false,
      );
      await tester.tap(find.byKey(const ValueKey('skill_cmd_1_aoe1')),
          warnIfMissed: false);
      await tester.pump();
      expect(notifier.interveneCount, 0);
    });

    testWidgets('false 时点 single 不进待发态、点敌不出手', (tester) async {
      final (left, right) = BattleDemo.mockTeams();
      final focus = left.first.copyWith(availableSkills: [_single]);
      final notifier = await _pumpWith(
        tester, [focus, ...left.skip(1)], right,
        allowPlayerIntervention: false,
      );
      await tester.tap(find.byKey(const ValueKey('skill_cmd_1_single1')),
          warnIfMissed: false);
      await tester.pump();
      final enemy = find.byWidgetPredicate(
        (w) => w is CharacterAvatar && w.character.characterId == 11,
      );
      await tester.tap(enemy);
      await tester.pump();
      expect(notifier.interveneCount, 0);
    });
  });
```

更新文件头注释（Phase 4 拖招 → 两段点选）。

- [ ] **Step 2: 跑该测试文件**

Run: `flutter test --no-pub test/features/battle/presentation/battle_tap_skill_test.dart`
Expected: PASS（全 case）。

- [ ] **Step 3: intervene 两测不变验证**

Run: `flutter test --no-pub test/features/battle/domain/strategy/intervene_now_test.dart test/features/battle/intervene_determinism_test.dart`
Expected: PASS（策略层语义未动）。

- [ ] **Step 4: 全量 analyze + test**

Run: `flutter analyze`
Expected: 0 issue。
Run: `flutter test --no-pub -j1`
Expected: 全绿（基线净增/减按 hitTest 4 测删 + 新 tap 测算；记录 delta，不写死期望数 — memory `feedback_nightshift_verify_count_baseline`）。

- [ ] **Step 5: Commit**

```bash
git add test/features/battle/presentation/
git commit -m "test: 拖招测试重写为两段点选 tap 契约(battle_tap_skill_test)"
```

- [ ] **Step 6: 真机验收**

Run: `flutter run -d macos`（或 build）。验：单体点技能→暂停→点敌出手 / AOE 一键 / 再点技能·空白·ESC 三种取消 / 软暂停顿感可接受 / 角标可读 / 待发态高亮清晰。色板深底勿糊。

- [ ] **Step 7: route 截图验收**

`battleTapLive` / `battleTapPreview` 路由截图（沿用项目视觉验收 SOP，memory `feedback_flutter_macos_drive_screenshot`）。

- [ ] **Step 8: PROGRESS 顶段更新**

四态：已完成 / 已验证（贴 analyze 0 + test 数）/ 已知风险（软暂停顿感·角标视觉真机主观）/ 下批建议。

---

## Self-Review（spec 覆盖核对）

- spec 3.1 交互模型 → Task 3/4/5/6 ✅
- spec 3.2 软暂停 → Task 3（`_isPaused` 复用）✅
- spec 3.3 删 `_rushToActorId`/引导线/拖动态 → Task 2/3 ✅
- spec 3.4 保留 `interveneNow`/AutoPlayMode/门控 → 全 task 不碰 ✅（`hitTestEnemyId`/`_collectEnemyTargets` 改为删除 + 敌头像 onTap，**偏离 spec「复用命中」，理由：tap 模型头像自知 enemyId，全局命中冗余；已在 Architecture 注明**）
- spec 3.5 角标 + 待发态反馈 + ESC → Task 5/6/7 ✅
- spec 3.6 红线 → 每 task 守，结算零碰，确定性测 Task 8 验 ✅
- spec 4.2 非目标（不加默认目标快捷/不改 _isFastForward）→ 计划未引入 ✅
- spec 5 验收 → Task 8 ✅

类型一致性：`_onSkillTap(int,SkillDef)` / `_onEnemyTap(int)` / `_clearPending()` / `onEnemyTap` / `pendingActive` / `onSkillTap` 透传 全文统一。
