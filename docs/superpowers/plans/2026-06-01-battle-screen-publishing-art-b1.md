# 战斗屏出版美术 Phase B1 实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 战斗屏出版美术收口 3 项 — scrim 暗遮罩 + 47 主线 stage/30 tower floor 背景 yaml 接线 + 胜负仪式全屏 overlay。

**Architecture:** 只改渲染层 + dialog 形态,不碰 battle_engine/BattleNotifier.advance/actionLog(回放架构)。scrim 是 Stack 内一层 ColoredBox;背景接线是纯 yaml 数据(接线链已 ready);胜负仪式是新 VictoryOverlay widget 经 showGeneralDialog 全屏弹出替换旧 AlertDialog。

**Tech Stack:** Flutter + Riverpod + Isar;YAML 数据;flutter_test widget/loader 测试。

设计依据:`docs/superpowers/specs/2026-06-01-battle-screen-publishing-art-design.md`

---

## Task 1: 背景层 + scrim 抽 BattleSceneBackground widget

> 设计变更(self-review):BattleScreen 空 teams 走 placeholder 分支不渲染 Stack,
> 且无现成 widget 测 harness。把背景图+scrim 抽成独立 widget(输入 path,无需 battle
> state),可独立 widget 测 + 符合 isolation。

**Files:**
- Create: `lib/features/battle/presentation/battle_scene_background.dart`
- Modify: `lib/shared/theme/colors.dart`(加 token)
- Modify: `lib/features/battle/presentation/battle_screen.dart:351-364`(用新 widget 替 inline 背景层)
- Test: `test/features/battle/presentation/battle_scene_background_test.dart`(新建)

- [ ] **Step 1: 加 color token**

`lib/shared/theme/colors.dart` 在 `resultHighlight` 行后加:
```dart
  /// 战斗背景图上的压暗遮罩(出版美术 B1):保证偏亮背景不抢前景。
  static const Color battleSceneScrim = Color(0x66000000); // black 40%
```

- [ ] **Step 2: 写失败 widget 测**

`test/features/battle/presentation/battle_scene_background_test.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/battle/presentation/battle_scene_background.dart';
import 'package:wuxia_idle/shared/theme/colors.dart';

Widget _wrap(Widget c) => MaterialApp(home: Scaffold(body: c));

void main() {
  testWidgets('path 非空 → 有背景 Image + scrim 遮罩层', (tester) async {
    await tester.pumpWidget(_wrap(
      const BattleSceneBackground(path: 'assets/scenes/battle_citywall.png')));
    await tester.pump();
    expect(find.byType(Image), findsOneWidget);
    final scrim = find.byWidgetPredicate((w) =>
        w is ColoredBox && w.color == WuxiaColors.battleSceneScrim);
    expect(scrim, findsOneWidget);
  });

  testWidgets('path null → SizedBox.shrink(无 Image 无 scrim)', (tester) async {
    await tester.pumpWidget(_wrap(const BattleSceneBackground(path: null)));
    await tester.pump();
    expect(find.byType(Image), findsNothing);
    final scrim = find.byWidgetPredicate((w) =>
        w is ColoredBox && w.color == WuxiaColors.battleSceneScrim);
    expect(scrim, findsNothing);
  });
}
```

- [ ] **Step 3: 跑测确认 fail**

Run: `flutter test test/features/battle/presentation/battle_scene_background_test.dart`
Expected: FAIL(battle_scene_background.dart 不存在)

- [ ] **Step 4: 实装 BattleSceneBackground**

`lib/features/battle/presentation/battle_scene_background.dart`:
```dart
import 'package:flutter/material.dart';

import '../../../shared/theme/colors.dart';

/// 战斗场景背景层(出版美术 B1):背景图 + scrim 压暗遮罩。
/// path 空 → SizedBox.shrink(降级到 battle_screen 兜底色)。
/// Image.asset 挂 errorBuilder(widget 测不加载 assets,守测不破)。
class BattleSceneBackground extends StatelessWidget {
  final String? path;
  const BattleSceneBackground({super.key, this.path});

  @override
  Widget build(BuildContext context) {
    final p = path;
    if (p == null || p.isEmpty) return const SizedBox.shrink();
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(p, fit: BoxFit.cover,
            errorBuilder: (_, _, _) => const SizedBox.shrink()),
        const ColoredBox(color: WuxiaColors.battleSceneScrim),
      ],
    );
  }
}
```

- [ ] **Step 5: battle_screen 用新 widget 替 inline 背景层**

`battle_screen.dart` import 加 `import 'battle_scene_background.dart';`。
build 的 Stack 里,删 `final hasScene = ...` + `if (hasScene) Positioned.fill(Image...)` 整段,改为 Stack children 第一项:
```dart
          Positioned.fill(
            child: BattleSceneBackground(path: widget.sceneBackgroundPath),
          ),
```
(BattleSceneBackground 内部 path 空 → SizedBox.shrink,无需外层 if)

- [ ] **Step 6: 跑测确认 pass + battle 全测族无回归**

Run: `flutter test test/features/battle/presentation/battle_scene_background_test.dart && flutter test test/features/battle/`
Expected: 背景测 2 PASS;battle 全测族 PASS

- [ ] **Step 7: commit**

```bash
git add lib/shared/theme/colors.dart lib/features/battle/presentation/battle_scene_background.dart lib/features/battle/presentation/battle_screen.dart test/features/battle/presentation/battle_scene_background_test.dart
git commit -m "feat: 战斗背景层抽 BattleSceneBackground(背景图+scrim 暗遮罩·可独立测)"
```

---

## Task 2: 胜负仪式 VictoryOverlay widget

**Files:**
- Create: `lib/features/battle/presentation/victory_overlay.dart`
- Modify: `lib/shared/strings.dart`(加文案)
- Test: `test/features/battle/presentation/victory_overlay_test.dart`(新建)

- [ ] **Step 1: 加 UiStrings 文案**

`lib/shared/strings.dart` 在 `backToMenu` 行后加:
```dart
  // ─── 胜负仪式 overlay(出版美术 B1)──────────────────────────────────────
  static const String victoryTitle = '胜';
  static const String defeatTitle = '败';
  static const String victorySubtitle = '旗开得胜';
  static const String defeatSubtitle = '败北';
  static const String battleContinue = '继续';
  static const String sealGlyph = '武'; // 印章符内字
```

- [ ] **Step 2: 写失败 widget 测**

`test/features/battle/presentation/victory_overlay_test.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/battle/domain/battle_state.dart';
import 'package:wuxia_idle/features/battle/presentation/victory_overlay.dart';
import 'package:wuxia_idle/shared/strings.dart';
import 'package:wuxia_idle/shared/theme/colors.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('leftWin 显金「胜」+ 统计 + 继续', (tester) async {
    var tapped = false;
    await tester.pumpWidget(_wrap(VictoryOverlay(
      result: BattleResult.leftWin,
      totalDamage: 12000, critCount: 3, totalTicks: 18,
      onContinue: () => tapped = true,
    )));
    expect(find.text(UiStrings.victoryTitle), findsOneWidget);
    expect(find.text(UiStrings.victorySubtitle), findsOneWidget);
    // 大题字金色
    final title = tester.widget<Text>(find.text(UiStrings.victoryTitle));
    expect(title.style?.color, WuxiaColors.resultHighlight);
    // 统计含总伤
    expect(find.textContaining('12000'), findsOneWidget);
    await tester.tap(find.text(UiStrings.battleContinue));
    expect(tapped, isTrue);
  });

  testWidgets('rightWin 显绛红「败」', (tester) async {
    await tester.pumpWidget(_wrap(VictoryOverlay(
      result: BattleResult.rightWin,
      totalDamage: 5000, critCount: 1, totalTicks: 9,
      onContinue: () {},
    )));
    expect(find.text(UiStrings.defeatTitle), findsOneWidget);
    final title = tester.widget<Text>(find.text(UiStrings.defeatTitle));
    expect(title.style?.color, WuxiaColors.gangMeng);
  });

  testWidgets('draw 也走败样式', (tester) async {
    await tester.pumpWidget(_wrap(VictoryOverlay(
      result: BattleResult.draw,
      totalDamage: 0, critCount: 0, totalTicks: 5,
      onContinue: () {},
    )));
    expect(find.text(UiStrings.defeatTitle), findsOneWidget);
  });
}
```

- [ ] **Step 3: 跑测确认 fail**

Run: `flutter test test/features/battle/presentation/victory_overlay_test.dart`
Expected: FAIL(victory_overlay.dart 不存在)

- [ ] **Step 4: 实装 VictoryOverlay**

`lib/features/battle/presentation/victory_overlay.dart`:
```dart
import 'package:flutter/material.dart';

import '../domain/battle_state.dart';
import '../../../shared/strings.dart';
import '../../../shared/theme/colors.dart';

/// 胜负仪式全屏 overlay(出版美术 B1)。
/// 暗幕 + 印章符 + 金「胜」/绛红「败」大题字 + 副标题 + 统计 + 继续按钮。
/// 纯展示 widget;弹出由 battle_screen 的 showGeneralDialog 负责。
class VictoryOverlay extends StatelessWidget {
  final BattleResult result;
  final int totalDamage;
  final int critCount;
  final int totalTicks;
  final VoidCallback onContinue;

  const VictoryOverlay({
    super.key,
    required this.result,
    required this.totalDamage,
    required this.critCount,
    required this.totalTicks,
    required this.onContinue,
  });

  bool get _isVictory => result == BattleResult.leftWin;

  @override
  Widget build(BuildContext context) {
    final accent = _isVictory ? WuxiaColors.resultHighlight : WuxiaColors.gangMeng;
    final title = _isVictory ? UiStrings.victoryTitle : UiStrings.defeatTitle;
    final subtitle = _isVictory ? UiStrings.victorySubtitle : UiStrings.defeatSubtitle;

    return Container(
      color: const Color(0xB3000000), // 暗幕 black 70%
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 印章符
          Transform.rotate(
            angle: -0.08,
            child: Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: WuxiaColors.gangMeng,
                borderRadius: BorderRadius.circular(6),
              ),
              alignment: Alignment.center,
              child: const Text(UiStrings.sealGlyph,
                style: TextStyle(color: WuxiaColors.textPrimary,
                  fontSize: 22, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 20),
          // 大题字
          Text(title, style: TextStyle(
            color: accent, fontSize: 96, fontWeight: FontWeight.bold,
            shadows: const [Shadow(blurRadius: 12, color: Color(0xCC000000), offset: Offset(2, 3))],
          )),
          const SizedBox(height: 8),
          Text(subtitle, style: TextStyle(color: accent, fontSize: 22, fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          Container(width: 180, height: 1, color: WuxiaColors.border),
          const SizedBox(height: 16),
          Text(UiStrings.battleSummary(totalDamage, critCount, totalTicks),
            style: const TextStyle(color: WuxiaColors.textSecondary, fontSize: 14)),
          const SizedBox(height: 28),
          // 继续按钮(金框)
          OutlinedButton(
            onPressed: onContinue,
            style: OutlinedButton.styleFrom(
              foregroundColor: accent,
              side: BorderSide(color: accent, width: 1.5),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
            child: const Text(UiStrings.battleContinue,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 5: 跑测确认 pass**

Run: `flutter test test/features/battle/presentation/victory_overlay_test.dart`
Expected: PASS(3 测)

- [ ] **Step 6: commit**

```bash
git add lib/features/battle/presentation/victory_overlay.dart lib/shared/strings.dart test/features/battle/presentation/victory_overlay_test.dart
git commit -m "feat: 胜负仪式 VictoryOverlay widget(金胜/绛红败+印章+统计)"
```

---

## Task 3: battle_screen 接 VictoryOverlay(替换 AlertDialog)

**Files:**
- Modify: `lib/features/battle/presentation/battle_screen.dart:237-288`(_showResultDialog)
- Test: `test/features/battle/presentation/battle_screen_result_overlay_test.dart`(新建,或并入现有 battle_screen 测)

> **验证策略(self-review):无现成 BattleScreen widget 测 harness,驱动真战斗到
> result 成本高。VictoryOverlay 渲染逻辑已在 Task 2 全测;本 task 只验「接线」——
> 靠 (a) 编译通过 (b) 全量 test 不回归(原 AlertDialog 断言若有需同步改) (c) Codex
> 视觉验收弹出仪式。不强写脆弱集成测(feedback_strategy_immutable_vs_ui_tick:
> 没 harness 硬测条件渲染易写假测)。**

- [ ] **Step 1: 改 _showResultDialog 用 showGeneralDialog + VictoryOverlay**

`battle_screen.dart` import 加 `import 'victory_overlay.dart';`。
`_showResultDialog` body 的 `showDialog<void>(...AlertDialog...)` 整段替换为:
```dart
    final totalDamage = s.actionLog
        .map((a) => a.attackResult?.finalDamage ?? 0)
        .fold<int>(0, (sum, d) => sum + d);
    final critCount = s.actionLog
        .where((a) => a.attackResult?.isCritical ?? false)
        .length;

    showGeneralDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.transparent, // overlay 自带暗幕
      transitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (ctx, _, _) => VictoryOverlay(
        result: result,
        totalDamage: totalDamage,
        critCount: critCount,
        totalTicks: s.tick,
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
```
(保留方法头部 `if (_resultDialogShown || !mounted) return; _resultDialogShown = true;`)

- [ ] **Step 2: 跑战斗相关全测族 + analyze 确认无回归**

Run: `flutter test test/features/battle/ && flutter analyze lib/features/battle/`
Expected: 全 PASS(原 AlertDialog/backToMenu 相关断言若有需同步改 VictoryOverlay);analyze 0 error

- [ ] **Step 3: commit**

```bash
git add lib/features/battle/presentation/battle_screen.dart
git commit -m "feat: 战斗结算改胜负仪式 overlay(showGeneralDialog 全屏替换 AlertDialog)"
```

---

## Task 4: 战斗背景 yaml 接线(47 stage + 30 floor)+ loader test

**Files:**
- Modify: `data/stages.yaml`(47 stage 加 sceneBackgroundPath)
- Modify: `data/towers.yaml`(30 floor 加 sceneBackgroundPath)
- Test: `test/data/battle_scene_wiring_test.dart`(新建)

- [ ] **Step 1: 写失败 loader test**

`test/data/battle_scene_wiring_test.dart`:
```dart
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/game_repository.dart';

// biome → 背景文件名(与 design 映射表一致)
const _map = {
  EncounterBiome.mountainForest: 'battle_mountainforest',
  EncounterBiome.cityWall: 'battle_citywall',
  EncounterBiome.frontier: 'battle_frontier',
  EncounterBiome.drillGround: 'battle_drillground',
  EncounterBiome.dock: 'battle_dock',
  EncounterBiome.mountainPath: 'battle_mountainpath',
  EncounterBiome.innerRealm: 'battle_innerrealm',
  EncounterBiome.desert: 'battle_frontier',
  EncounterBiome.temple: 'battle_mountainforest',
  EncounterBiome.teaHouse: 'battle_citywall',
  EncounterBiome.inn: 'battle_citywall',
  EncounterBiome.alley: 'battle_citywall',
  EncounterBiome.smithy: 'battle_drillground',
  EncounterBiome.escortRoad: 'battle_mountainpath',
  EncounterBiome.cliffWaterfall: 'battle_mountainpath',
  EncounterBiome.bambooForest: 'battle_mountainforest',
};

void main() {
  late GameRepository repo;
  setUpAll(() async {
    repo = await GameRepository.load(loader: (p) => File(p).readAsString());
  });

  test('每个主线 stage 都有 sceneBackgroundPath 且按 biome 映射正确', () {
    for (final s in repo.stageDefs.values) {
      expect(s.sceneBackgroundPath, isNotNull, reason: '${s.id} 缺背景');
      if (s.biome != null) {
        final expected = 'assets/scenes/${_map[s.biome]}.png';
        expect(s.sceneBackgroundPath, expected, reason: '${s.id} 映射错');
      }
    }
  });

  test('所有 stage 背景路径 ∈ 7 张 battle_*.png', () {
    const valid = {
      'battle_mountainforest','battle_citywall','battle_frontier',
      'battle_drillground','battle_dock','battle_mountainpath','battle_innerrealm',
    };
    for (final s in repo.stageDefs.values) {
      final name = s.sceneBackgroundPath!.split('/').last.replaceAll('.png', '');
      expect(valid.contains(name), isTrue, reason: '${s.id}: $name 非法');
    }
  });
}
```
> 执行者:tower floor 加载若有 production loader(GameRepository towerFloorDefs 或类似),补一条 `每个 floor.sceneBackgroundPath == 'assets/scenes/battle_innerrealm.png'`;若 tower 无聚合加载入口,改为直接读 towers.yaml 文本断言每 floor 块有该行。先 grep `towerFloor` 在 game_repository 确认入口。

- [ ] **Step 2: 跑测确认 fail**

Run: `flutter test test/data/battle_scene_wiring_test.dart`
Expected: FAIL(sceneBackgroundPath 全 null)

- [ ] **Step 3: 脚本给 stages.yaml 加 sceneBackgroundPath**

跑 Python 脚本(在 `data/stages.yaml` 每个 `<indent>biome: X` 行后插入同缩进 `sceneBackgroundPath: assets/scenes/battle_<map[X]>.png`):
```python
import re
m = {
  'mountainForest':'battle_mountainforest','cityWall':'battle_citywall',
  'frontier':'battle_frontier','drillGround':'battle_drillground',
  'dock':'battle_dock','mountainPath':'battle_mountainpath',
  'innerRealm':'battle_innerrealm','desert':'battle_frontier',
  'temple':'battle_mountainforest','teaHouse':'battle_citywall',
  'inn':'battle_citywall','alley':'battle_citywall',
  'smithy':'battle_drillground','escortRoad':'battle_mountainpath',
  'cliffWaterfall':'battle_mountainpath','bambooForest':'battle_mountainforest',
}
p='data/stages.yaml'; out=[]; n=0
for line in open(p,encoding='utf-8'):
    out.append(line)
    mt=re.match(r'^(\s*)biome:\s*(\w+)\s*$', line)
    if mt and mt.group(2) in m:
        indent=mt.group(1)
        out.append(f'{indent}sceneBackgroundPath: assets/scenes/{m[mt.group(2)]}.png\n')
        n+=1
open(p,'w',encoding='utf-8').writelines(out)
print('stages 注入',n)  # 期望 47
```

- [ ] **Step 4: 脚本给 towers.yaml 加 sceneBackgroundPath**

```python
import re
p='data/towers.yaml'; out=[]; n=0
for line in open(p,encoding='utf-8'):
    out.append(line)
    mt=re.match(r'^(\s*)floorIndex:\s*\d+\s*$', line)
    if mt:
        out.append(f'{mt.group(1)}sceneBackgroundPath: assets/scenes/battle_innerrealm.png\n')
        n+=1
open(p,'w',encoding='utf-8').writelines(out)
print('floor 注入',n)  # 期望 30
```

- [ ] **Step 5: 跑接线测 + 全量 analyze(批量改 yaml 雷达)**

Run: `flutter test test/data/battle_scene_wiring_test.dart && flutter analyze`
Expected: 接线测 PASS;analyze 0 error(yaml 结构未破)

- [ ] **Step 6: 跑全量测确认无回归**

Run: `flutter test`
Expected: 全 PASS(stage loader 相关测全过,yaml 未破)

- [ ] **Step 7: commit**

```bash
git add data/stages.yaml data/towers.yaml test/data/battle_scene_wiring_test.dart
git commit -m "feat: 战斗背景 yaml 接线(47 stage 按 biome 映射 + 30 tower floor 复用 innerrealm)"
```

---

## 收尾(全部 task 后)

- [ ] 全量 `flutter test` + `flutter analyze` 全绿
- [ ] Mac 本地 build(`flutter build macos --debug --dart-define=VISUAL_ROUTE=<战斗验收route>`)+ 自验 READY
- [ ] 派 Codex 视觉验收:scrim 观感(背景压暗不抢前景)/ 背景题材对位(抽样几个 biome)/ 胜负仪式(金「胜」+绛红「败」+印章+统计+继续)
- [ ] PASS 后 PROGRESS 更新 + 合并 main

## 风险锚

- 不碰 battle_engine/advance/actionLog(回放架构)
- Task 3 改 AlertDialog→overlay,原战斗集成测若断言 AlertDialog/backToMenu 文案需同步改(全量 test 拦)
- Task 4 批量改 yaml:analyze 是漏改雷达(feedback_batch_sed_analyze_radar);脚本只插行不改原行,保留注释
- widget 测 setSurfaceSize 防 overflow;Image.asset errorBuilder 已有(测不破)
