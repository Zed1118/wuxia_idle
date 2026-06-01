# 战斗屏出版美术 Phase B2 实装计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 战斗时大招/人剑合一弹水墨题字 overlay(非阻塞自动淡出) + 敌方 Boss 头像专属边框。

**Architecture:** 纯 UI 层，不碰战斗引擎。题字 = 独立 Stack 顶层 overlay(AnimationController 自管 + 覆盖语义)，触发点在 `battle_screen._playAction`。Boss 边框 = `EnemyDef.isBoss` → `BattleCharacter.isBoss` → `CharacterAvatar` 描边。两者纯 Flutter，无 MJ 出图。

**Tech Stack:** Flutter · Riverpod · Isar(本特性不动 Isar schema) · 项目既有测试 harness(`test/widget_test.dart` override notifier)。

**前置事实(已 grep 坐实)：**
- `BattleAction`(`battle_state.dart:26`) 有 `actorId`/`skill`/`attackResult`；`_playAction(a, s)`(`battle_screen.dart:148`) 已 `_findCharacter(actorId, s)` 拿 `actor.teamSide`(左=0 玩家/右=1 敌)。
- `SkillType`(`enums.dart:116`)：`normalAttack/powerSkill/ultimate/jointSkill`。ultimate `requiresManualTrigger=true` → AI 自动播放**不放**；jointSkill AI 自动放。
- `CharacterAvatar` 边框有**两处**：hasIcon Container(`:45`) + `_FirstGlyphAvatar`(`:137`)。
- `BattleCharacter` 可选字段体例：`swordSongResonanceActive`/`iconPath`/`attackPowerMultiplier`(default + ctor 末 + copyWith)。
- worktree 缺 `libisar.dylib`(主仓有) + `.g.dart`(gitignored) → 全量测前必补(Task 0)。
- `stages.yaml` 有 21 处 `isBossStage: true`。

---

## Task 0: worktree Isar 环境补齐

**Files:** 无源码改动(环境)。

- [ ] **Step 1: 拷 libisar.dylib + 跑 build_runner**

Run:
```bash
cd /Users/a10506/Desktop/Projects/挂机武侠/.claude/worktrees/battle-b2
cp /Users/a10506/Desktop/Projects/挂机武侠/libisar.dylib .
dart run build_runner build --delete-conflicting-outputs
```
Expected: dylib 就位(2187120 bytes) + build_runner `Succeeded`，生成 `.g.dart`。

- [ ] **Step 2: 基线全量测确认绿**

Run: `flutter test 2>&1 | tail -5`
Expected: `All tests passed!`(基线 1642 测 / 1 skip)。若红，先停下排查环境，不要继续。

---

## Task 1: BattleCharacter.isBoss 字段(domain)

**Files:**
- Modify: `lib/features/battle/domain/battle_state.dart`(field + ctor + copyWith)
- Test: `test/features/battle/domain/battle_character_is_boss_test.dart`(新建)

- [ ] **Step 1: 写失败测**

Create `test/features/battle/domain/battle_character_is_boss_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/features/battle/domain/battle_state.dart';

BattleCharacter _base({bool isBoss = false}) => BattleCharacter(
      characterId: 1,
      name: '测试',
      realmTier: RealmTier.yiLiu,
      realmLayer: RealmLayer.qiMeng,
      school: TechniqueSchool.gangMeng,
      maxHp: 100,
      currentHp: 100,
      maxInternalForce: 100,
      currentInternalForce: 100,
      speed: 100,
      criticalRate: 0.05,
      evasionRate: 0.05,
      defenseRate: 0.1,
      totalEquipmentAttack: 100,
      mainCultivationLayer: CultivationLayer.daCheng,
      availableSkills: const [],
      skillCooldowns: const {},
      activeBuffs: const [],
      actionPoint: 0,
      isAlive: true,
      teamSide: 0,
      slotIndex: 0,
      isBoss: isBoss,
    );

void main() {
  test('isBoss 默认 false', () {
    expect(_base().isBoss, false);
  });

  test('isBoss=true 可构造', () {
    expect(_base(isBoss: true).isBoss, true);
  });

  test('copyWith 保留 isBoss', () {
    final c = _base(isBoss: true).copyWith(currentHp: 50);
    expect(c.isBoss, true);
    expect(c.currentHp, 50);
  });

  test('copyWith 可改 isBoss', () {
    expect(_base().copyWith(isBoss: true).isBoss, true);
  });
}
```

- [ ] **Step 2: 跑测验证失败**

Run: `flutter test test/features/battle/domain/battle_character_is_boss_test.dart`
Expected: 编译失败(`isBoss` 不是 BattleCharacter 的命名参数)。

- [ ] **Step 3: 加字段 + ctor + copyWith**

`battle_state.dart`：在 `attackPowerMultiplier` 字段后(约 `:119` 之后)加：
```dart
  /// 出版美术 B2:此角色是否为 Boss(EnemyDef.isBoss 透传)。true 时
  /// CharacterAvatar 走金色加粗描边。玩家方恒 false。
  final bool isBoss;
```
const 构造末尾(`attackPowerMultiplier = 1.0,` 后)加：
```dart
    this.isBoss = false,
```
copyWith 参数列表(`double? attackPowerMultiplier,` 后)加 `bool? isBoss,`，return 体(`attackPowerMultiplier: ... ?? this.attackPowerMultiplier,` 后)加：
```dart
      isBoss: isBoss ?? this.isBoss,
```

- [ ] **Step 4: 跑测验证通过**

Run: `flutter test test/features/battle/domain/battle_character_is_boss_test.dart`
Expected: All tests passed (4 测)。

- [ ] **Step 5: 提交**

```bash
git add lib/features/battle/domain/battle_state.dart test/features/battle/domain/battle_character_is_boss_test.dart
git commit -m "feat: BattleCharacter 加 isBoss 字段(B2 Boss 边框)"
```

---

## Task 2: WuxiaColors.bossFrame + CharacterAvatar Boss 边框

**Files:**
- Modify: `lib/shared/theme/colors.dart`(加 bossFrame 常量)
- Modify: `lib/features/battle/presentation/character_avatar.dart`(border 逻辑)
- Test: `test/features/battle/presentation/character_avatar_test.dart`(新建)

- [ ] **Step 1: 写失败测**

Create `test/features/battle/presentation/character_avatar_test.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/features/battle/domain/battle_state.dart';
import 'package:wuxia_idle/features/battle/presentation/character_avatar.dart';
import 'package:wuxia_idle/shared/theme/colors.dart';

BattleCharacter _char({required bool isBoss}) => BattleCharacter(
      characterId: 1,
      name: '黑风寨主',
      realmTier: RealmTier.yiLiu,
      realmLayer: RealmLayer.qiMeng,
      school: TechniqueSchool.gangMeng,
      maxHp: 100,
      currentHp: 100,
      maxInternalForce: 100,
      currentInternalForce: 100,
      speed: 100,
      criticalRate: 0.05,
      evasionRate: 0.05,
      defenseRate: 0.1,
      totalEquipmentAttack: 100,
      mainCultivationLayer: CultivationLayer.daCheng,
      availableSkills: const [],
      skillCooldowns: const {},
      activeBuffs: const [],
      actionPoint: 0,
      isAlive: true,
      teamSide: 1,
      slotIndex: 0,
      isBoss: isBoss,
    );

  // 取头像圆形容器的 Border(iconPath=null 走 _FirstGlyphAvatar 的 circle Container)
  Border _avatarBorder(WidgetTester tester) {
    final container = tester
        .widgetList<Container>(find.byType(Container))
        .firstWhere((c) =>
            c.decoration is BoxDecoration &&
            (c.decoration as BoxDecoration).shape == BoxShape.circle);
    return (container.decoration as BoxDecoration).border as Border;
  }

void main() {
  Future<void> pump(WidgetTester tester, BattleCharacter c) async {
    await tester.binding.setSurfaceSize(const Size(400, 600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: Center(child: CharacterAvatar(character: c))),
    ));
  }

  testWidgets('普通敌人:流派色 4px 边框', (tester) async {
    await pump(tester, _char(isBoss: false));
    final b = _avatarBorder(tester);
    expect(b.top.color, WuxiaColors.gangMeng); // 刚猛流派色
    expect(b.top.width, 4.0);
  });

  testWidgets('Boss:金色 6px 边框', (tester) async {
    await pump(tester, _char(isBoss: true));
    final b = _avatarBorder(tester);
    expect(b.top.color, WuxiaColors.bossFrame);
    expect(b.top.width, 6.0);
  });
}
```

- [ ] **Step 2: 跑测验证失败**

Run: `flutter test test/features/battle/presentation/character_avatar_test.dart`
Expected: 编译失败(`WuxiaColors.bossFrame` 未定义) + Boss 测断言失败。

- [ ] **Step 3: 加 bossFrame 色**

`lib/shared/theme/colors.dart`：在 `resultHighlight`(`:31`) 后加：
```dart
  /// 出版美术 B2:Boss 头像专属金色描边(深金,区别于 resultHighlight 浅金 + 流派色)。
  static const Color bossFrame = Color(0xFFD4A017);
```

- [ ] **Step 4: 改 CharacterAvatar border 逻辑**

`character_avatar.dart` `build()` 内，在 `final color = WuxiaColors.schoolColor(...)`(`:32`) 后加：
```dart
    final borderColor = character.isBoss ? WuxiaColors.bossFrame : color;
    final borderWidth = character.isBoss ? 6.0 : 4.0;
```
hasIcon Container 的 border(`:45`) 改为：
```dart
              border: Border.all(color: borderColor, width: borderWidth),
```
errorBuilder 的 `_FirstGlyphAvatar`(`:54-58`) 与无图分支的 `_FirstGlyphAvatar`(`:62-66`) 均改为传 `color: borderColor, borderWidth: borderWidth`(去掉原 `color: color`)。
`_FirstGlyphAvatar` 加 `borderWidth` 字段：
```dart
class _FirstGlyphAvatar extends StatelessWidget {
  final double avatarSize;
  final Color color;
  final double borderWidth;
  final String firstGlyph;

  const _FirstGlyphAvatar({
    required this.avatarSize,
    required this.color,
    this.borderWidth = 4,
    required this.firstGlyph,
  });
```
其 Container border(`:137`) 改为：
```dart
        border: Border.all(color: color, width: borderWidth),
```

- [ ] **Step 5: 跑测验证通过**

Run: `flutter test test/features/battle/presentation/character_avatar_test.dart`
Expected: All tests passed (2 测)。

- [ ] **Step 6: 提交**

```bash
git add lib/shared/theme/colors.dart lib/features/battle/presentation/character_avatar.dart test/features/battle/presentation/character_avatar_test.dart
git commit -m "feat: CharacterAvatar Boss 金色加粗边框 + WuxiaColors.bossFrame"
```

---

## Task 3: EnemyDef.isBoss + fromYaml

**Files:**
- Modify: `lib/data/defs/stage_def.dart`(EnemyDef field + ctor + fromYaml)
- Test: `test/data/defs/defs_test.dart`(追加 group)

- [ ] **Step 1: 写失败测**

在 `test/data/defs/defs_test.dart` 末尾(最后一个 `}` 前的 main 体内)追加 group：
```dart
  group('EnemyDef.isBoss(B2)', () {
    Map<String, dynamic> base() => {
          'id': 'e1',
          'name': '黑风寨主',
          'realmTier': 'yiLiu',
          'realmLayer': 'qiMeng',
          'school': 'gangMeng',
          'baseHp': 5000,
          'baseAttack': 400,
          'baseSpeed': 200,
          'skillIds': ['s1'],
          'iconPath': 'assets/enemies/x.png',
        };

    test('缺省 isBoss=false(向后兼容)', () {
      expect(EnemyDef.fromYaml(base()).isBoss, false);
    });

    test('isBoss: true 解析', () {
      expect(EnemyDef.fromYaml({...base(), 'isBoss': true}).isBoss, true);
    });
  });
```
(若 `defs_test.dart` 未 import `EnemyDef`，加 `import 'package:wuxia_idle/data/defs/stage_def.dart';`。)

- [ ] **Step 2: 跑测验证失败**

Run: `flutter test test/data/defs/defs_test.dart --plain-name "EnemyDef.isBoss"`
Expected: 编译失败(`isBoss` 不是 EnemyDef 成员)。

- [ ] **Step 3: 加字段 + ctor + fromYaml**

`stage_def.dart` EnemyDef：在 `final String iconPath;`(`:205`) 后加：
```dart
  /// 出版美术 B2:此敌人是否为 Boss。true → 战斗屏头像金色加粗边框。
  /// 缺省 false 向后兼容。仅 isBossStage 关卡的语义 Boss 敌人标 true。
  final bool isBoss;
```
const 构造(`required this.iconPath,` 后)加：
```dart
    this.isBoss = false,
```
fromYaml(`iconPath: y['iconPath'] as String,` 后)加：
```dart
      isBoss: y['isBoss'] as bool? ?? false,
```

- [ ] **Step 4: 跑测验证通过**

Run: `flutter test test/data/defs/defs_test.dart --plain-name "EnemyDef.isBoss"`
Expected: All tests passed (2 测)。

- [ ] **Step 5: 提交**

```bash
git add lib/data/defs/stage_def.dart test/data/defs/defs_test.dart
git commit -m "[schema] feat: EnemyDef 加 isBoss 字段 + fromYaml 解析(B2)"
```

---

## Task 4: _enemyToBattle 透传 isBoss

**Files:**
- Modify: `lib/features/battle/application/stage_battle_setup.dart`(`_enemyToBattle:288`)
- Test: `test/features/battle/application/stage_battle_setup_test.dart`(追加)

- [ ] **Step 1: 写失败测**

先看现有 `stage_battle_setup_test.dart` 如何 setUp(GameRepository.loadAllDefs 等)，沿其 setUp 模式追加 test。若该文件已有 `setUpAll(() async { await GameRepository.loadAllDefs(); })` 则直接追加以下 test：
```dart
  test('_enemyToBattle 透传 EnemyDef.isBoss → BattleCharacter.isBoss', () {
    const bossEnemy = EnemyDef(
      id: 'boss1',
      name: '黑风寨主',
      realmTier: RealmTier.yiLiu,
      realmLayer: RealmLayer.qiMeng,
      school: TechniqueSchool.gangMeng,
      baseHp: 5000,
      baseAttack: 400,
      baseSpeed: 200,
      skillIds: [],
      iconPath: 'assets/enemies/x.png',
      isBoss: true,
    );
    final bc = StageBattleSetup.debugEnemyToBattle(enemy: bossEnemy, slotIndex: 0);
    expect(bc.isBoss, true);

    const mob = EnemyDef(
      id: 'mob1', name: '喽啰',
      realmTier: RealmTier.yiLiu, realmLayer: RealmLayer.qiMeng,
      school: TechniqueSchool.gangMeng,
      baseHp: 100, baseAttack: 50, baseSpeed: 100,
      skillIds: [], iconPath: 'assets/enemies/y.png',
    );
    expect(StageBattleSetup.debugEnemyToBattle(enemy: mob, slotIndex: 1).isBoss, false);
  });
```
注：`_enemyToBattle` 是 private static。为可测，在 `StageBattleSetup` 加薄 debug 包装(Step 3)。若 import 缺 EnemyDef/RealmTier，补 import。

- [ ] **Step 2: 跑测验证失败**

Run: `flutter test test/features/battle/application/stage_battle_setup_test.dart --plain-name "透传"`
Expected: 编译失败(`debugEnemyToBattle` / `isBoss` 不存在)。

- [ ] **Step 3: 透传 isBoss + 加 debug 包装**

`stage_battle_setup.dart` `_enemyToBattle` return 的 `BattleCharacter(...)` 末尾(`iconPath: enemy.iconPath,` 后)加：
```dart
      isBoss: enemy.isBoss,
```
并在 class 内(`_enemyToBattle` 之后)加薄包装供测：
```dart
  /// @visibleForTesting:暴露 [_enemyToBattle] 供单测(private static 不可直测)。
  @visibleForTesting
  static BattleCharacter debugEnemyToBattle({
    required EnemyDef enemy,
    required int slotIndex,
  }) =>
      _enemyToBattle(enemy: enemy, slotIndex: slotIndex);
```
确保文件顶部 import `package:meta/meta.dart`(若已 import flutter 则 `@visibleForTesting` 来自 flutter foundation，可改用 `import 'package:flutter/foundation.dart';`；按文件现有 import 风格选其一)。

- [ ] **Step 4: 跑测验证通过**

Run: `flutter test test/features/battle/application/stage_battle_setup_test.dart --plain-name "透传"`
Expected: All tests passed。

- [ ] **Step 5: 提交**

```bash
git add lib/features/battle/application/stage_battle_setup.dart test/features/battle/application/stage_battle_setup_test.dart
git commit -m "feat: _enemyToBattle 透传 isBoss(B2)"
```

---

## Task 5: stages.yaml 标注 Boss 敌人 + 红线测

**Files:**
- Modify: `data/stages.yaml`(21 个 isBossStage 关卡的语义 Boss 敌人加 `isBoss: true`)
- Test: `test/data/stages_boss_enemy_test.dart`(新建,production yaml 红线)

- [ ] **Step 1: 写失败测(红线:每个 boss stage 至少一个 isBoss 敌人)**

Create `test/data/stages_boss_enemy_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/game_repository.dart';

void main() {
  setUpAll(() async {
    await GameRepository.loadAllDefs();
  });

  test('每个 isBossStage 关卡 enemyTeam 恰有 ≥1 个 isBoss 敌人', () {
    final stages = GameRepository.instance.stages;
    final bossStages = stages.where((s) => s.isBossStage).toList();
    expect(bossStages, isNotEmpty, reason: 'production 应有 boss stage');
    for (final s in bossStages) {
      final bossCount = s.enemyTeam.where((e) => e.isBoss).length;
      expect(bossCount, greaterThanOrEqualTo(1),
          reason: '${s.id} 是 boss stage,但 enemyTeam 无 isBoss 敌人');
    }
  });

  test('非 boss stage 不应有 isBoss 敌人', () {
    final stages = GameRepository.instance.stages;
    for (final s in stages.where((s) => !s.isBossStage)) {
      expect(s.enemyTeam.any((e) => e.isBoss), false,
          reason: '${s.id} 非 boss stage 却标了 isBoss 敌人');
    }
  });
}
```
(若 `GameRepository.instance.stages` 的 getter 名不同，先 grep `List<StageDef>` getter 名并对齐。)

- [ ] **Step 2: 跑测验证失败**

Run: `flutter test test/data/stages_boss_enemy_test.dart`
Expected: 第一个测失败(boss stage 的 enemyTeam 还没标 isBoss)。

- [ ] **Step 3: 标注 21 个 boss stage 的 Boss 敌人**

定位：`grep -n "isBossStage: true" data/stages.yaml`。对每个命中的 stage，向上/向下找其 `enemyTeam:`，给**语义上的那个 Boss 敌人**(单敌人队 → 唯一那个；多敌人队 → 名字/境界最高的主敌，通常是带专属 iconPath 的命名 Boss)加 `isBoss: true`(缩进对齐该 enemy 的其他字段)。示例：
```yaml
    enemyTeam:
      - id: enemy_xueTu_umbrella
        name: 血屠
        realmTier: ...
        iconPath: assets/enemies/umbrella.png
        isBoss: true          # ← 新增
```
逐个标注，不要漏(21 个)。小怪同队的不标。

- [ ] **Step 4: 跑测验证通过**

Run: `flutter test test/data/stages_boss_enemy_test.dart`
Expected: All tests passed (2 测)。

- [ ] **Step 5: 提交**

```bash
git add data/stages.yaml test/data/stages_boss_enemy_test.dart
git commit -m "[schema] feat: stages.yaml 标注 21 boss stage 的 Boss 敌人 isBoss(B2)"
```

---

## Task 6: isUltimateCaptionSkill 纯函数 + 新文件骨架

**Files:**
- Create: `lib/features/battle/presentation/ultimate_caption_overlay.dart`
- Test: `test/features/battle/presentation/ultimate_caption_overlay_test.dart`(新建)

- [ ] **Step 1: 写失败测(纯谓词)**

Create `test/features/battle/presentation/ultimate_caption_overlay_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/defs/skill_def.dart';
import 'package:wuxia_idle/features/battle/presentation/ultimate_caption_overlay.dart';

SkillDef _skill(SkillType type) => SkillDef(
      id: 't',
      name: '测试招',
      description: '',
      type: type,
      powerMultiplier: 100,
      internalForceCost: 0,
      cooldownTurns: 0,
      requiresManualTrigger: false,
      parentTechniqueDefId: null,
      visualEffect: '',
    );

void main() {
  test('ultimate / jointSkill → true', () {
    expect(isUltimateCaptionSkill(_skill(SkillType.ultimate)), true);
    expect(isUltimateCaptionSkill(_skill(SkillType.jointSkill)), true);
  });

  test('normalAttack / powerSkill / null → false', () {
    expect(isUltimateCaptionSkill(_skill(SkillType.normalAttack)), false);
    expect(isUltimateCaptionSkill(_skill(SkillType.powerSkill)), false);
    expect(isUltimateCaptionSkill(null), false);
  });
}
```

- [ ] **Step 2: 跑测验证失败**

Run: `flutter test test/features/battle/presentation/ultimate_caption_overlay_test.dart`
Expected: 编译失败(文件/函数不存在)。

- [ ] **Step 3: 建文件 + 谓词**

Create `lib/features/battle/presentation/ultimate_caption_overlay.dart`:
```dart
import 'package:flutter/material.dart';

import '../../../data/defs/skill_def.dart';
import '../../../core/domain/enums.dart';
import '../../../shared/theme/colors.dart';

/// 出版美术 B2:出招是否该弹大招题字(ultimate 或人剑合一)。纯函数便于单测。
bool isUltimateCaptionSkill(SkillDef? skill) =>
    skill != null &&
    (skill.type == SkillType.ultimate || skill.type == SkillType.jointSkill);
```

- [ ] **Step 4: 跑测验证通过**

Run: `flutter test test/features/battle/presentation/ultimate_caption_overlay_test.dart`
Expected: All tests passed (2 测)。

- [ ] **Step 5: 提交**

```bash
git add lib/features/battle/presentation/ultimate_caption_overlay.dart test/features/battle/presentation/ultimate_caption_overlay_test.dart
git commit -m "feat: isUltimateCaptionSkill 谓词 + 题字 overlay 文件骨架(B2)"
```

---

## Task 7: UltimateCaptionContent(视图) + UltimateCaptionOverlay(动画 overlay)

**Files:**
- Modify: `lib/features/battle/presentation/ultimate_caption_overlay.dart`
- Test: `test/features/battle/presentation/ultimate_caption_overlay_test.dart`(追加)

- [ ] **Step 1: 写失败测(视图 + show/覆盖语义)**

在 test 文件追加 import：
```dart
import 'package:flutter/material.dart';
```
并在 `main()` 内追加：
```dart
  testWidgets('UltimateCaptionContent 显示招式名', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: UltimateCaptionContent(name: '山岳崩', isEnemy: false),
      ),
    ));
    expect(find.text('山岳崩'), findsOneWidget);
  });

  testWidgets('overlay show() 显示 + 二次 show() 覆盖前者', (tester) async {
    final key = GlobalKey<UltimateCaptionOverlayState>();
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: UltimateCaptionOverlay(key: key)),
    ));
    // 初始无题字
    expect(find.byType(UltimateCaptionContent), findsNothing);

    key.currentState!.show('天问', isEnemy: false);
    await tester.pump();
    expect(find.text('天问'), findsOneWidget);

    // 二次 show 覆盖:只剩最新
    key.currentState!.show('飞雪', isEnemy: true);
    await tester.pump();
    expect(find.text('飞雪'), findsOneWidget);
    expect(find.text('天问'), findsNothing);

    // 让动画跑完避免 pending timer 报错
    await tester.pumpAndSettle(const Duration(seconds: 3));
  });
```

- [ ] **Step 2: 跑测验证失败**

Run: `flutter test test/features/battle/presentation/ultimate_caption_overlay_test.dart`
Expected: 编译失败(`UltimateCaptionContent`/`UltimateCaptionOverlay`/`UltimateCaptionOverlayState` 未定义)。

- [ ] **Step 3: 实现视图 + overlay**

在 `ultimate_caption_overlay.dart` 末尾追加：
```dart
/// 大招题字视觉(纯展示,无动画)。供动画 overlay 与视觉验收路由复用。
/// 玩家方暖金、敌方绛红，水墨大字 + 墨色描边。
class UltimateCaptionContent extends StatelessWidget {
  final String name;
  final bool isEnemy;

  const UltimateCaptionContent({
    super.key,
    required this.name,
    required this.isEnemy,
  });

  @override
  Widget build(BuildContext context) {
    final accent = isEnemy ? WuxiaColors.gangMeng : WuxiaColors.resultHighlight;
    return Align(
      alignment: const Alignment(0, -0.45), // 中部偏上
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 18),
        decoration: BoxDecoration(
          color: const Color(0x99000000), // 淡墨团衬底
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: accent, width: 1.5),
        ),
        child: Text(
          name,
          style: TextStyle(
            color: accent,
            fontSize: 56,
            fontWeight: FontWeight.bold,
            letterSpacing: 6,
            shadows: const [
              Shadow(blurRadius: 14, color: Color(0xCC000000), offset: Offset(2, 3)),
            ],
          ),
        ),
      ),
    );
  }
}

/// 非阻塞大招题字 overlay:Stack 顶层,[show] 触发淡入→停留→淡出,自管生命周期。
/// 1.2s 内再 show 覆盖前者(单实例,latest wins)。idle 时渲染 SizedBox.shrink。
class UltimateCaptionOverlay extends StatefulWidget {
  const UltimateCaptionOverlay({super.key});

  @override
  State<UltimateCaptionOverlay> createState() => UltimateCaptionOverlayState();
}

class UltimateCaptionOverlayState extends State<UltimateCaptionOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  String? _name;
  bool _isEnemy = false;

  // 250ms 淡入 + 1200ms 停留 + 350ms 淡出 = 1800ms 总时长
  static const _total = Duration(milliseconds: 1800);

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: _total)
      ..addStatusListener((s) {
        if (s == AnimationStatus.completed && mounted) {
          setState(() => _name = null);
        }
      });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  /// 触发题字。覆盖语义:重置动画 + 换文字。
  void show(String name, {required bool isEnemy}) {
    setState(() {
      _name = name;
      _isEnemy = isEnemy;
    });
    _ctrl.forward(from: 0.0);
  }

  // 0→0.14 淡入(opacity 0→1) / 0.14→0.80 停留(1) / 0.80→1 淡出(1→0)
  double get _opacity {
    final t = _ctrl.value;
    if (t < 0.14) return t / 0.14;
    if (t > 0.80) return (1.0 - t) / 0.20;
    return 1.0;
  }

  @override
  Widget build(BuildContext context) {
    if (_name == null) return const SizedBox.shrink();
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, _) => Opacity(
          opacity: _opacity.clamp(0.0, 1.0),
          child: UltimateCaptionContent(name: _name!, isEnemy: _isEnemy),
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: 跑测验证通过**

Run: `flutter test test/features/battle/presentation/ultimate_caption_overlay_test.dart`
Expected: All tests passed (4 测)。

- [ ] **Step 5: 提交**

```bash
git add lib/features/battle/presentation/ultimate_caption_overlay.dart test/features/battle/presentation/ultimate_caption_overlay_test.dart
git commit -m "feat: 大招题字 UltimateCaptionContent + 非阻塞 overlay(B2)"
```

---

## Task 8: wire 进 battle_screen(_playAction hook + Stack 挂载)

**Files:**
- Modify: `lib/features/battle/presentation/battle_screen.dart`
- Test: `test/widget_test.dart`(追加 wiring 测)

- [ ] **Step 1: 写失败测**

`test/widget_test.dart` 顶部 import 区补(若缺)：
```dart
import 'package:wuxia_idle/data/defs/skill_def.dart';
import 'package:wuxia_idle/features/battle/presentation/ultimate_caption_overlay.dart';
```
在 `main()` 内 T16 测之后追加：
```dart
  testWidgets('B2 大招 action → 题字 overlay 显示招式名', (tester) async {
    const ultSkill = SkillDef(
      id: 't_ult', name: '山岳崩', description: '',
      type: SkillType.ultimate, powerMultiplier: 5000,
      internalForceCost: 1000, cooldownTurns: 5,
      requiresManualTrigger: true, parentTechniqueDefId: null, visualEffect: '',
    );
    final notifier = await pumpBattle(tester);
    expect(find.byType(UltimateCaptionContent), findsNothing);

    notifier.appendActions(const [
      BattleAction(
        tick: 1, actorId: 1, targetId: 11,
        skill: ultSkill, attackResult: _normalResult,
        description: '萧夜寒大招',
      ),
    ]);
    await tester.pump(); // ref.listen → show()
    await tester.pump(); // build
    expect(find.text('山岳崩'), findsOneWidget);

    await tester.pumpAndSettle(const Duration(seconds: 3)); // 收尾动画
  });

  testWidgets('B2 普攻 action → 不弹题字', (tester) async {
    final notifier = await pumpBattle(tester);
    notifier.appendActions(const [
      BattleAction(
        tick: 1, actorId: 1, targetId: 11,
        attackResult: _normalResult, description: '普攻',
      ),
    ]);
    await tester.pump();
    await tester.pump();
    expect(find.byType(UltimateCaptionContent), findsNothing);
  });
```
(`SkillType` 应已随 enums import 可用；若缺，补 `import 'package:wuxia_idle/core/domain/enums.dart';`。)

- [ ] **Step 2: 跑测验证失败**

Run: `flutter test test/widget_test.dart --plain-name "B2 大招"`
Expected: 失败(题字未挂载,`UltimateCaptionContent` 找不到)。

- [ ] **Step 3: wire**

`battle_screen.dart`：
1. 顶部 import 区加：`import 'ultimate_caption_overlay.dart';`
2. `_BattleScreenState` 字段区(`_resultDialogShown` 附近,`:97`)加：
```dart
  // B2 大招题字 overlay 的 key(命令式 show)
  final GlobalKey<UltimateCaptionOverlayState> _ultimateCaptionKey =
      GlobalKey<UltimateCaptionOverlayState>();
```
3. `_playAction`(`:148`) 内,在末尾(`}` 前)加 hook(复用已算的 `actor`)：
```dart
    if (isUltimateCaptionSkill(action.skill)) {
      _ultimateCaptionKey.currentState
          ?.show(action.skill!.name, isEnemy: actor?.teamSide == 1);
    }
```
4. build() 的 Stack `children`(`:338-388`)，在 SafeArea 之后(Stack 末,`],` 前 `:387`)加题字 overlay(Z-order 最顶,仍低于 showGeneralDialog 弹窗)：
```dart
          Positioned.fill(
            child: UltimateCaptionOverlay(key: _ultimateCaptionKey),
          ),
```

- [ ] **Step 4: 跑测验证通过**

Run: `flutter test test/widget_test.dart --plain-name "B2"`
Expected: All tests passed (2 测)。

- [ ] **Step 5: 提交**

```bash
git add lib/features/battle/presentation/battle_screen.dart test/widget_test.dart
git commit -m "feat: battle_screen wire 大招题字 overlay(B2)"
```

---

## Task 9: VISUAL_ROUTE 验收路由(静态题字 + Boss 边框场景)

**Files:**
- Modify: `lib/features/debug/application/visual_route.dart`(2 枚举值)
- Modify: `lib/features/debug/presentation/battle_test_menu.dart`(`_char` 加 isBoss + `scenarioBoss`)
- Modify: `lib/features/debug/presentation/visual_route_host.dart`(2 case + 静态题字预览 widget)
- Test: `test/features/debug/visual_route_test.dart`(追加 parse 断言)

- [ ] **Step 1: 写失败测**

`test/features/debug/visual_route_test.dart` 追加(沿现有 parse 测体例)：
```dart
  test('B2 新路由 parse', () {
    expect(parseVisualRoute('battle_ultimate_caption'),
        VisualRoute.battleUltimateCaption);
    expect(parseVisualRoute('battle_boss_frame'),
        VisualRoute.battleBossFrame);
  });
```

- [ ] **Step 2: 跑测验证失败**

Run: `flutter test test/features/debug/visual_route_test.dart --plain-name "B2"`
Expected: 编译失败(枚举值不存在)。

- [ ] **Step 3a: 加枚举值**

`visual_route.dart`：把 `battleScene(...)` 行末的 `;` 改为 `,`，其后加：
```dart
  battleUltimateCaption('battle_ultimate_caption',
      '战斗屏·大招题字静态验收(玩家暖金 + 敌方绛红 两态)'),
  battleBossFrame('battle_boss_frame',
      '战斗屏·Boss 头像金色加粗边框验收(scenarioBoss 右队首位 Boss)');
```

- [ ] **Step 3b: battle_test_menu 加 isBoss 支持**

`_char`(`:76`) 参数末尾(`required int slotIndex,` 后)加 `bool isBoss = false,`；BattleCharacter ctor 末(`slotIndex: slotIndex,` 后)加 `isBoss: isBoss,`。
在 `scenarioB`(`:198`) 后加 `scenarioBoss`：
```dart
  /// B2 Boss 边框验收:同 scenarioB 但右队首位标 Boss。
  static (List<BattleCharacter>, List<BattleCharacter>) scenarioBoss() {
    BattleCharacter c(int id, String name, TechniqueSchool school, int side,
            int slot, {bool isBoss = false}) =>
        _char(
          id: id, name: name,
          tier: RealmTier.yiLiu, layer: RealmLayer.qiMeng,
          school: school, maxHp: 12000, maxIf: 4000, speed: 200,
          critRate: 0.05, eqAtk: 550, cultivation: CultivationLayer.xiaoCheng,
          skills: [
            _normal('boss_normal_$id', '普攻'),
            _power('boss_power_$id', '重击', pm: 1200, cost: 1000, cd: 3),
          ],
          teamSide: side, slotIndex: slot, isBoss: isBoss,
        );
    return (
      [
        c(21, '刚猛甲', TechniqueSchool.gangMeng, 0, 0),
        c(22, '灵巧乙', TechniqueSchool.lingQiao, 0, 1),
        c(23, '阴柔丙', TechniqueSchool.yinRou, 0, 2),
      ],
      [
        c(31, '魔教教主', TechniqueSchool.yinRou, 1, 0, isBoss: true),
        c(32, '刚猛乙', TechniqueSchool.gangMeng, 1, 1),
        c(33, '灵巧丙', TechniqueSchool.lingQiao, 1, 2),
      ],
    );
  }
```

- [ ] **Step 3c: visual_route_host 加 2 case + 静态题字预览**

`visual_route_host.dart`：
1. import 区加：`import '../../battle/presentation/ultimate_caption_overlay.dart';`
2. switch(`:67`) 在 `battleScene` case 后加：
```dart
        case VisualRoute.battleUltimateCaption:
          target = const _UltimateCaptionPreview();

        case VisualRoute.battleBossFrame:
          target = const ScenarioLauncher(
            teamsFactory: BattleScenarioData.scenarioBoss,
            hint: '出版美术验收·Boss 头像金色加粗边框(右队首位)',
            sceneBackgroundPath: 'assets/scenes/battle_citywall.png',
          );
```
3. 文件末尾(class 外)加静态题字预览 widget：
```dart
/// B2 题字静态验收:玩家暖金(上) + 敌方绛红(下)两态同屏,便于截图。
class _UltimateCaptionPreview extends StatelessWidget {
  const _UltimateCaptionPreview();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF14181D),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: const [
          Expanded(child: UltimateCaptionContent(name: '天问归一', isEnemy: false)),
          Expanded(child: UltimateCaptionContent(name: '血煞噬魂', isEnemy: true)),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: 跑测 + analyze**

Run: `flutter test test/features/debug/visual_route_test.dart && flutter analyze --no-fatal-infos`
Expected: 测过 + analyze 0 error。

- [ ] **Step 5: 提交**

```bash
git add lib/features/debug/ test/features/debug/visual_route_test.dart
git commit -m "feat: B2 验收路由(静态题字 + Boss 边框场景)"
```

---

## Task 10: 全量 verify + 收尾

**Files:** 无源码(验证)。

- [ ] **Step 1: 全量 flutter test(硬约束:改了 battle_screen 必跑全量)**

Run: `flutter test 2>&1 | tail -8`
Expected: `All tests passed!`。基线 1642 + 本批新增(Task1 4 + Task2 2 + Task3 2 + Task4 1 + Task5 2 + Task6 2 + Task7 4 + Task8 2 + Task9 1 ≈ +20)→ ~1662 测。若有红,定位修复(改 battle_screen 易碰 root widget_test.dart 既有 T16,逐一核对)。

- [ ] **Step 2: analyze 0 error**

Run: `flutter analyze --no-fatal-infos 2>&1 | tail -5`
Expected: `No issues found!`(或仅既有 info,0 error/warning)。

- [ ] **Step 3: 真机自验验收路由(debug build+run,不只 flutter test)**

按 `feedback_verify_full_ci_not_scoped_lint` + B1 踩坑:debug-only 路由必须真 build+run 自验(AI 崩溃只在真跑暴露)。三路由各跑一次确认 `VISUAL_ROUTE_READY` 无 `VISUAL_ROUTE_ERROR`：
```bash
flutter run -d macos --dart-define=VISUAL_ROUTE=battle_ultimate_caption  # 静态题字
flutter run -d macos --dart-define=VISUAL_ROUTE=battle_boss_frame        # Boss 边框
flutter run -d macos --dart-define=VISUAL_ROUTE=battle_scene             # B1 回归不破
```
(或用既有 `visual_capture.sh`/截图脚本。grep 日志确认无 ERROR / 无 Bad state。)

- [ ] **Step 4: 派 Codex @ Pen 视觉验收**

沿 `feedback_codex_visual_acceptance_mac`:给已编译 app + 3 路由 + 固定截图清单 + closeout 模板。验收点:① 题字水墨观感 + 玩家暖/敌冷区分 ② Boss 金边辨识度 vs 普通流派色 ③ B1 回归不破。

- [ ] **Step 5: closeout + PROGRESS 更新**

写 `docs/handoff/p_b2_battle_polish_closeout_2026-06-01.md`(≤80 行,沿 feedback_doc_inflation_overnight) + PROGRESS.md 追加 B2 段。最终 commit。

---

## 自查(写完对照 spec)

- [x] spec A(题字:非阻塞/双方 ult+joint/覆盖语义/暖冷)→ Task 6/7/8 覆盖
- [x] spec B(EnemyDef.isBoss/传递链/CharacterAvatar 渲染/yaml 标注)→ Task 1-5 覆盖
- [x] spec C(TDD:谓词/覆盖/fromYaml/透传/avatar 分支/yaml 红线 + 全量测硬约束)→ 各 Task Step + Task 10
- [x] spec D(验收:静态题字路由 + Boss 场景路由 + Codex)→ Task 9 + Task 10
- [x] spec 修正:scenarioB 无 ultimate 且 ult 需手动触发 → 验收题字改**静态路由**(非自动播放),已在 Task 9 落实
- [x] 类型一致:`UltimateCaptionOverlayState`(Task7 公开 state 类)= Task8 GlobalKey 泛型一致;`isBoss` 字段名跨 EnemyDef/BattleCharacter/_char 一致;`bossFrame` 跨 colors/avatar/test 一致
- [x] 无 placeholder:每步含真实代码/命令/期望
