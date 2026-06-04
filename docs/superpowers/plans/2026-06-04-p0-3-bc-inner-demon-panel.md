# P0-3 ②③ 主修 hero 化 + 心魔成长瓶颈面板 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 给角色面板加「心魔 X/7 成长瓶颈」常驻面板(③,武圣可见,数据管线 = MainlineProgress.clearedStageIds 派生)+ 把主修心法 tile hero 化(②,宣纸底 + 主修名加大)。

**Architecture:** ③ 拆 3 层纯单元(`InnerDemonProgress` 值对象 + `resolveInnerDemonPanel` 纯解析器 + `InnerDemonProgressPanel` 纯渲染 widget),`@riverpod` provider 从 `mainlineProgressProvider` 派生全局进度,`_BreakthroughBlockerSection` 仅做接线。② 把 `_MainTechniqueTile` 的 data 分支换 `WuxiaPaperPanel` 壳 + 主修名(`techniqueDefs[defId].name`)加大。验收新建独立 seed + route(不动被广泛依赖的 `seedMasterDisciple`)。

**Tech Stack:** Flutter + Riverpod 3(codegen `@riverpod`)+ Isar + flutter_test。

---

## File Structure

- Create `lib/features/inner_demon/domain/inner_demon_progress.dart` — `InnerDemonProgress` 值对象 + `.from()` 纯计算。
- Create `lib/features/inner_demon/domain/inner_demon_panel.dart` — `InnerDemonPanelState` enum + `InnerDemonPanelData` + `resolveInnerDemonPanel` 纯解析器。
- Create `lib/features/inner_demon/application/inner_demon_providers.dart` — `innerDemonProgressProvider`(`@riverpod`)。
- Rewrite `lib/features/inner_demon/presentation/breakthrough_blocker.dart` — `InnerDemonBreakthroughBlocker` → `InnerDemonProgressPanel`(泛化纯渲染,3 状态)。
- Modify `lib/shared/strings.dart` — 新增心魔面板 UiStrings。
- Modify `lib/features/character_panel/presentation/character_panel_screen.dart` — `_BreakthroughBlockerSection` 接线重写(②)+ `_MainTechniqueTile` hero 化(③)。
- Modify `lib/features/debug/application/visual_route.dart` + `lib/features/debug/presentation/visual_route_host.dart` + `lib/features/debug/application/phase2_seed_service.dart` — 新增 `characterPanelGrowth` route + `seedCharacterPanelGrowth` 验收 seed。
- Tests: `test/features/inner_demon/domain/inner_demon_progress_test.dart` / `inner_demon_panel_test.dart` / `test/features/inner_demon/presentation/inner_demon_progress_panel_test.dart` / 扩 `test/features/character_panel/presentation/character_panel_screen_test.dart`。

---

## Task 1: `InnerDemonProgress` 值对象 + 纯计算

**Files:**
- Create: `lib/features/inner_demon/domain/inner_demon_progress.dart`
- Test: `test/features/inner_demon/domain/inner_demon_progress_test.dart`

- [ ] **Step 1: 写失败测试**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/features/inner_demon/domain/inner_demon_def.dart';
import 'package:wuxia_idle/features/inner_demon/domain/inner_demon_progress.dart';

void main() {
  // 7 关 fixture(stage_inner_demon_01..07 → wuSheng 各 layer)。
  InnerDemonDef defWith7() {
    const layers = RealmLayer.values;
    final req = <String, RealmCoord>{};
    for (var i = 0; i < 7; i++) {
      final n = (i + 1).toString().padLeft(2, '0');
      req['stage_inner_demon_$n'] =
          RealmCoord(tier: RealmTier.wuSheng, layer: layers[i]);
    }
    return InnerDemonDef.empty().copyForTest(requiredRealmLayer: req);
  }

  test('全未通 → 0/7,next = _01', () {
    final p = InnerDemonProgress.from(
      innerDemonDef: defWith7(),
      clearedStageIds: const {},
    );
    expect(p.clearedCount, 0);
    expect(p.totalCount, 7);
    expect(p.nextUnclearedStageId, 'stage_inner_demon_01');
  });

  test('部分通(_01,_02)→ 2/7,next = _03', () {
    final p = InnerDemonProgress.from(
      innerDemonDef: defWith7(),
      clearedStageIds: const {
        'stage_06_05',
        'stage_inner_demon_01',
        'stage_inner_demon_02',
      },
    );
    expect(p.clearedCount, 2); // stage_06_05 不计入心魔关
    expect(p.totalCount, 7);
    expect(p.nextUnclearedStageId, 'stage_inner_demon_03');
  });

  test('全通 → 7/7,next = null', () {
    final cleared = {for (var i = 1; i <= 7; i++) 'stage_inner_demon_${i.toString().padLeft(2, '0')}'};
    final p = InnerDemonProgress.from(
      innerDemonDef: defWith7(),
      clearedStageIds: cleared,
    );
    expect(p.clearedCount, 7);
    expect(p.totalCount, 7);
    expect(p.nextUnclearedStageId, isNull);
  });

  test('空 def → 0/0,next null(不崩)', () {
    final p = InnerDemonProgress.from(
      innerDemonDef: InnerDemonDef.empty(),
      clearedStageIds: const {'stage_inner_demon_01'},
    );
    expect(p.totalCount, 0);
    expect(p.clearedCount, 0);
    expect(p.nextUnclearedStageId, isNull);
  });
}
```

> 注:测试用了 `InnerDemonDef.empty().copyForTest(requiredRealmLayer: ...)`。`InnerDemonDef` 现无 copyWith,Step 3 顺手加一个 `copyForTest` 命名构造(仅测试用,真实路径走 fromYaml)。或直接 `InnerDemonDef(...)` 全字段构造 —— 选后者更省,**改测试用全字段构造**:

```dart
  InnerDemonDef defWith7() {
    const layers = RealmLayer.values;
    final req = <String, RealmCoord>{};
    for (var i = 0; i < 7; i++) {
      final n = (i + 1).toString().padLeft(2, '0');
      req['stage_inner_demon_$n'] =
          RealmCoord(tier: RealmTier.wuSheng, layer: layers[i]);
    }
    final base = InnerDemonDef.empty();
    return InnerDemonDef(
      mirrorBuffPerStage: base.mirrorBuffPerStage,
      mirrorCaps: base.mirrorCaps,
      failurePenalty: base.failurePenalty,
      residueDebuff: base.residueDebuff,
      unlockTriggers: base.unlockTriggers,
      requiredRealmLayer: req,
    );
  }
```
(删掉上面 4 个测试里对 `copyForTest` 的依赖,统一用这个 helper。)

- [ ] **Step 2: 跑测试确认失败**

Run: `flutter test test/features/inner_demon/domain/inner_demon_progress_test.dart`
Expected: FAIL（`inner_demon_progress.dart` 不存在 / `InnerDemonProgress` undefined）。

- [ ] **Step 3: 实装**

```dart
// lib/features/inner_demon/domain/inner_demon_progress.dart
import 'inner_demon_def.dart';

/// 心魔通关全局进度(P0-3 ③)。数据单一真相源 = MainlineProgress.clearedStageIds,
/// 本类只做派生计算,不另存状态。
class InnerDemonProgress {
  /// 已通关心魔关数(clearedStageIds 中 stage_inner_demon_* 计数)。
  final int clearedCount;

  /// 心魔关总数(派生自 innerDemonDef.requiredRealmLayer,不硬编码 7)。
  final int totalCount;

  /// 已通关 stage id 全集(供解析器复算拦截)。
  final Set<String> clearedStageIds;

  /// 按 stage_inner_demon_01..NN 顺序第一个未通关关(null = 全通)。
  final String? nextUnclearedStageId;

  const InnerDemonProgress({
    required this.clearedCount,
    required this.totalCount,
    required this.clearedStageIds,
    required this.nextUnclearedStageId,
  });

  static const String _prefix = 'stage_inner_demon_';

  factory InnerDemonProgress.from({
    required InnerDemonDef innerDemonDef,
    required Set<String> clearedStageIds,
  }) {
    final demonStages = innerDemonDef.requiredRealmLayer.keys
        .where((k) => k.startsWith(_prefix))
        .toList()
      ..sort();
    final cleared =
        demonStages.where(clearedStageIds.contains).length;
    String? next;
    for (final s in demonStages) {
      if (!clearedStageIds.contains(s)) {
        next = s;
        break;
      }
    }
    return InnerDemonProgress(
      clearedCount: cleared,
      totalCount: demonStages.length,
      clearedStageIds: clearedStageIds,
      nextUnclearedStageId: next,
    );
  }
}
```

- [ ] **Step 4: 跑测试确认通过**

Run: `flutter test test/features/inner_demon/domain/inner_demon_progress_test.dart`
Expected: PASS（4 测）。

- [ ] **Step 5: 提交**

```bash
git add lib/features/inner_demon/domain/inner_demon_progress.dart test/features/inner_demon/domain/inner_demon_progress_test.dart
git commit -m "feat: 心魔进度值对象 InnerDemonProgress + 派生计算"
```

---

## Task 2: `innerDemonProgressProvider`(codegen)

**Files:**
- Create: `lib/features/inner_demon/application/inner_demon_providers.dart`

- [ ] **Step 1: 写 provider**

```dart
// lib/features/inner_demon/application/inner_demon_providers.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../data/game_repository.dart';
import '../../mainline/application/mainline_providers.dart';
import '../domain/inner_demon_progress.dart';

part 'inner_demon_providers.g.dart';

/// 心魔通关全局进度(P0-3 ③)。从 [mainlineProgressProvider] 派生,
/// recordVictory → invalidate(mainlineProgressProvider) 后级联刷新。
@riverpod
Future<InnerDemonProgress> innerDemonProgress(Ref ref) async {
  final progress = await ref.watch(mainlineProgressProvider.future);
  return InnerDemonProgress.from(
    innerDemonDef: GameRepository.instance.numbers.innerDemon,
    clearedStageIds: progress.clearedStageIds.toSet(),
  );
}
```

- [ ] **Step 2: 跑 build_runner 生成 .g.dart(fail-fast)**

Run: `dart run build_runner build --delete-conflicting-outputs 2>&1 | tail -20`
Expected: `Succeeded` + 生成 `lib/features/inner_demon/application/inner_demon_providers.g.dart`（.g.dart 被 gitignore,不入库,memory feedback_wuxia_pen_build_runner）。若 fail 必停修，不静默继续（memory feedback_nightshift_build_runner_silent_fail）。

- [ ] **Step 3: analyze 确认无错**

Run: `flutter analyze lib/features/inner_demon/`
Expected: No issues。

- [ ] **Step 4: 提交**

```bash
git add lib/features/inner_demon/application/inner_demon_providers.dart
git commit -m "feat: innerDemonProgressProvider 派生全局心魔进度"
```

---

## Task 3: `resolveInnerDemonPanel` 纯解析器 + `InnerDemonPanelData`

**Files:**
- Create: `lib/features/inner_demon/domain/inner_demon_panel.dart`
- Test: `test/features/inner_demon/domain/inner_demon_panel_test.dart`

- [ ] **Step 1: 写失败测试**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/attributes.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/features/inner_demon/domain/inner_demon_def.dart';
import 'package:wuxia_idle/features/inner_demon/domain/inner_demon_panel.dart';
import 'package:wuxia_idle/features/inner_demon/domain/inner_demon_progress.dart';

void main() {
  InnerDemonDef defWith7() {
    const layers = RealmLayer.values;
    final req = <String, RealmCoord>{};
    for (var i = 0; i < 7; i++) {
      final n = (i + 1).toString().padLeft(2, '0');
      req['stage_inner_demon_$n'] =
          RealmCoord(tier: RealmTier.wuSheng, layer: layers[i]);
    }
    final b = InnerDemonDef.empty();
    return InnerDemonDef(
      mirrorBuffPerStage: b.mirrorBuffPerStage,
      mirrorCaps: b.mirrorCaps,
      failurePenalty: b.failurePenalty,
      residueDebuff: b.residueDebuff,
      unlockTriggers: b.unlockTriggers,
      requiredRealmLayer: req,
    );
  }

  Character ch({
    required RealmTier tier,
    RealmLayer layer = RealmLayer.shuLian,
    int experience = 0,
    int experienceToNextLayer = 100,
  }) {
    final c = Character.create(
      name: 't',
      realmTier: tier,
      realmLayer: layer,
      attributes: Attributes()
        ..constitution = 5
        ..enlightenment = 5
        ..agility = 5
        ..fortune = 5,
      rarity: RarityTier.biaoZhun,
      lineageRole: LineageRole.founder,
      createdAt: DateTime(2026, 6, 4),
      internalForce: 100,
      internalForceMax: 500,
      school: TechniqueSchool.gangMeng,
    )..id = 1;
    c.experience = experience;
    c.experienceToNextLayer = experienceToNextLayer;
    return c;
  }

  InnerDemonProgress prog(Set<String> cleared) =>
      InnerDemonProgress.from(innerDemonDef: defWith7(), clearedStageIds: cleared);

  test('非武圣 → null(shrink)', () {
    final r = resolveInnerDemonPanel(
      character: ch(tier: RealmTier.yiLiu),
      progress: prog(const {}),
      innerDemonDef: defWith7(),
    );
    expect(r, isNull);
  });

  test('武圣全通 → cleared 7/7', () {
    final cleared = {for (var i = 1; i <= 7; i++) 'stage_inner_demon_${i.toString().padLeft(2, '0')}'};
    final r = resolveInnerDemonPanel(
      character: ch(tier: RealmTier.wuSheng, layer: RealmLayer.dengFeng),
      progress: prog(cleared),
      innerDemonDef: defWith7(),
    )!;
    expect(r.state, InnerDemonPanelState.cleared);
    expect(r.clearedCount, 7);
    expect(r.totalCount, 7);
  });

  test('武圣 exp满 + 拦截 → blocked,blockingStageId 对应当前 layer', () {
    // layer=shuLian → 升 jingTong,prevLayer=shuLian,blocking=stage_inner_demon_03。
    // cleared 含 _01,_02 不含 _03 → 拦截。
    final r = resolveInnerDemonPanel(
      character: ch(
        tier: RealmTier.wuSheng,
        layer: RealmLayer.shuLian,
        experience: 100,
        experienceToNextLayer: 100,
      ),
      progress: prog(const {'stage_inner_demon_01', 'stage_inner_demon_02'}),
      innerDemonDef: defWith7(),
    )!;
    expect(r.state, InnerDemonPanelState.blocked);
    expect(r.blockingStageId, 'stage_inner_demon_03');
    expect(r.clearedCount, 2);
  });

  test('武圣 exp未满 → inProgress,nextStageId = 首个未通', () {
    final r = resolveInnerDemonPanel(
      character: ch(
        tier: RealmTier.wuSheng,
        layer: RealmLayer.shuLian,
        experience: 10,
        experienceToNextLayer: 100,
      ),
      progress: prog(const {'stage_inner_demon_01'}),
      innerDemonDef: defWith7(),
    )!;
    expect(r.state, InnerDemonPanelState.inProgress);
    expect(r.nextStageId, 'stage_inner_demon_02');
  });
}
```

- [ ] **Step 2: 跑测试确认失败**

Run: `flutter test test/features/inner_demon/domain/inner_demon_panel_test.dart`
Expected: FAIL（`inner_demon_panel.dart` 不存在）。

- [ ] **Step 3: 实装**

```dart
// lib/features/inner_demon/domain/inner_demon_panel.dart
import '../../../core/domain/character.dart';
import '../../../core/domain/enums.dart';
import '../application/inner_demon_service.dart';
import 'inner_demon_def.dart';
import 'inner_demon_progress.dart';

/// 心魔面板渲染态(P0-3 ③)。
enum InnerDemonPanelState { cleared, blocked, inProgress }

/// 解析器产物 —— 渲染所需的纯数据(stage 名由 caller 用 stageDefs 解)。
class InnerDemonPanelData {
  final InnerDemonPanelState state;
  final int clearedCount;
  final int totalCount;

  /// blocked 态:拦截关 stage id(对应当前 layer)。
  final String? blockingStageId;

  /// inProgress 态:下一关 stage id(首个未通)。
  final String? nextStageId;

  const InnerDemonPanelData({
    required this.state,
    required this.clearedCount,
    required this.totalCount,
    this.blockingStageId,
    this.nextStageId,
  });
}

/// 角色 + 全局进度 + 心魔 def → 面板数据(null = 不显示 / shrink)。
///
/// 优先级:非武圣 null > 全通 cleared > exp满且拦截 blocked > 其余 inProgress。
/// 不引新突破机制 —— 进阶仍自动(applyExperience),本解析仅决定展示态。
InnerDemonPanelData? resolveInnerDemonPanel({
  required Character character,
  required InnerDemonProgress progress,
  required InnerDemonDef innerDemonDef,
}) {
  if (character.realmTier != RealmTier.wuSheng) return null;

  final total = progress.totalCount;
  if (total > 0 && progress.clearedCount >= total) {
    return InnerDemonPanelData(
      state: InnerDemonPanelState.cleared,
      clearedCount: progress.clearedCount,
      totalCount: total,
    );
  }

  const layers = RealmLayer.values;
  final idx = layers.indexOf(character.realmLayer);
  final hasNext = idx >= 0 && idx < layers.length - 1;
  final nextLayer = hasNext ? layers[idx + 1] : null;
  final expFull = character.experience >= character.experienceToNextLayer;

  final locked = expFull &&
      nextLayer != null &&
      InnerDemonService.isLayerLocked(
        nextTier: RealmTier.wuSheng,
        nextLayer: nextLayer,
        innerDemonDef: innerDemonDef,
        clearedStageIds: progress.clearedStageIds,
      );

  if (locked) {
    String? blockingStageId;
    for (final e in innerDemonDef.requiredRealmLayer.entries) {
      if (e.value.tier == RealmTier.wuSheng &&
          e.value.layer == character.realmLayer) {
        blockingStageId = e.key;
        break;
      }
    }
    return InnerDemonPanelData(
      state: InnerDemonPanelState.blocked,
      clearedCount: progress.clearedCount,
      totalCount: total,
      blockingStageId: blockingStageId,
    );
  }

  return InnerDemonPanelData(
    state: InnerDemonPanelState.inProgress,
    clearedCount: progress.clearedCount,
    totalCount: total,
    nextStageId: progress.nextUnclearedStageId,
  );
}
```

- [ ] **Step 4: 跑测试确认通过**

Run: `flutter test test/features/inner_demon/domain/inner_demon_panel_test.dart`
Expected: PASS（5 测）。

- [ ] **Step 5: 提交**

```bash
git add lib/features/inner_demon/domain/inner_demon_panel.dart test/features/inner_demon/domain/inner_demon_panel_test.dart
git commit -m "feat: 心魔面板解析器 resolveInnerDemonPanel(3 态)"
```

---

## Task 4: UiStrings 新增心魔面板文案

**Files:**
- Modify: `lib/shared/strings.dart`（心魔境段 L521 附近 + breakthroughGoToInnerDemon L885 附近）

- [ ] **Step 1: 加文案常量/方法**（在 `breakthroughGoToInnerDemon` 同段后追加）

```dart
  // ─── 心魔成长瓶颈面板(P0-3 ③)──────────────────────────────────────────
  static const String innerDemonPanelTitle = '心魔试炼';
  static String innerDemonPanelProgress(int cleared, int total) =>
      '$cleared / $total';
  static const String innerDemonBlockedTitle = '突破被拦';
  static String innerDemonBlockedBody(String stageName) =>
      '心魔关「$stageName」未通,经验留账';
  static String innerDemonNextLabel(String stageName) => '下一关:$stageName';
  static const String innerDemonClearedLabel = '心魔已尽,更无可破';
  static const String innerDemonBreakthroughCta = '突破';
```

> `breakthroughGoToInnerDemon`（'前往心魔境'）保留,作 inProgress 弱 CTA 复用。

- [ ] **Step 2: analyze 确认**

Run: `flutter analyze lib/shared/strings.dart`
Expected: No issues。

- [ ] **Step 3: 提交**

```bash
git add lib/shared/strings.dart
git commit -m "feat: 心魔成长瓶颈面板 UiStrings"
```

---

## Task 5: `InnerDemonProgressPanel` 纯渲染 widget(泛化旧 blocker)

**Files:**
- Rewrite: `lib/features/inner_demon/presentation/breakthrough_blocker.dart`
- Test: `test/features/inner_demon/presentation/inner_demon_progress_panel_test.dart`

- [ ] **Step 1: 写失败测试（3 状态渲染,无 provider）**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/inner_demon/domain/inner_demon_panel.dart';
import 'package:wuxia_idle/features/inner_demon/presentation/breakthrough_blocker.dart';
import 'package:wuxia_idle/shared/strings.dart';

void main() {
  Future<void> pump(WidgetTester tester, Widget child) async {
    await tester.binding.setSurfaceSize(const Size(1280, 720));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: child)));
    await tester.pump();
  }

  testWidgets('blocked 态:显「突破被拦」+ 进度 + 强 CTA', (tester) async {
    var tapped = false;
    await pump(
      tester,
      InnerDemonProgressPanel(
        state: InnerDemonPanelState.blocked,
        clearedCount: 2,
        totalCount: 7,
        blockingStageName: '心魔·痴',
        onNavigate: () => tapped = true,
      ),
    );
    expect(find.text(UiStrings.innerDemonPanelTitle), findsOneWidget);
    expect(find.text(UiStrings.innerDemonPanelProgress(2, 7)), findsOneWidget);
    expect(find.text(UiStrings.innerDemonBlockedBody('心魔·痴')), findsOneWidget);
    expect(find.text(UiStrings.innerDemonBreakthroughCta), findsOneWidget);
    await tester.tap(find.text(UiStrings.innerDemonBreakthroughCta));
    expect(tapped, isTrue);
  });

  testWidgets('inProgress 态:显进度 + 下一关 + 弱 CTA', (tester) async {
    await pump(
      tester,
      InnerDemonProgressPanel(
        state: InnerDemonPanelState.inProgress,
        clearedCount: 1,
        totalCount: 7,
        nextStageName: '心魔·嗔',
        onNavigate: () {},
      ),
    );
    expect(find.text(UiStrings.innerDemonNextLabel('心魔·嗔')), findsOneWidget);
    expect(find.text(UiStrings.breakthroughGoToInnerDemon), findsOneWidget);
  });

  testWidgets('cleared 态:显「心魔已尽」无 CTA', (tester) async {
    await pump(
      tester,
      const InnerDemonProgressPanel(
        state: InnerDemonPanelState.cleared,
        clearedCount: 7,
        totalCount: 7,
      ),
    );
    expect(find.text(UiStrings.innerDemonClearedLabel), findsOneWidget);
    expect(find.text(UiStrings.innerDemonBreakthroughCta), findsNothing);
    expect(find.text(UiStrings.breakthroughGoToInnerDemon), findsNothing);
  });
}
```

- [ ] **Step 2: 跑测试确认失败**

Run: `flutter test test/features/inner_demon/presentation/inner_demon_progress_panel_test.dart`
Expected: FAIL（`InnerDemonProgressPanel` undefined）。

- [ ] **Step 3: 重写 widget**（整文件替换）

```dart
import 'package:flutter/material.dart';

import '../../../shared/strings.dart';
import '../../../shared/theme/colors.dart';
import '../domain/inner_demon_panel.dart';

/// 心魔成长瓶颈面板(P0-3 ③,泛化自旧 InnerDemonBreakthroughBlocker)。
///
/// 纯渲染职责:按 [state] 显示 cleared / blocked / inProgress 三态。
/// 武圣常驻(由 caller `_BreakthroughBlockerSection` 决定显隐),
/// X/total 进度条数据单一真相源 = MainlineProgress.clearedStageIds。
/// stage 名由 caller 用 stageDefs 解后传入。「突破」CTA = onNavigate(导航至
/// InnerDemonScreen,不引新突破机制,进阶仍自动)。
class InnerDemonProgressPanel extends StatelessWidget {
  const InnerDemonProgressPanel({
    super.key,
    required this.state,
    required this.clearedCount,
    required this.totalCount,
    this.blockingStageName,
    this.nextStageName,
    this.onNavigate,
  });

  final InnerDemonPanelState state;
  final int clearedCount;
  final int totalCount;

  /// blocked 态拦截关名。
  final String? blockingStageName;

  /// inProgress 态下一关名。
  final String? nextStageName;

  /// 「突破」/「前往心魔境」CTA 回调(cleared 态不显 CTA)。
  final VoidCallback? onNavigate;

  @override
  Widget build(BuildContext context) {
    final progress =
        totalCount == 0 ? 0.0 : (clearedCount / totalCount).clamp(0.0, 1.0);
    final isBlocked = state == InnerDemonPanelState.blocked;

    return Material(
      color: WuxiaColors.sidebar,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isBlocked ? Icons.lock_outline : Icons.self_improvement,
                  size: 16,
                  color: isBlocked
                      ? WuxiaColors.resultHighlight
                      : WuxiaColors.textMuted,
                ),
                const SizedBox(width: 6),
                const Text(
                  UiStrings.innerDemonPanelTitle,
                  style: TextStyle(
                    color: WuxiaColors.textPrimary,
                    fontSize: 14,
                  ),
                ),
                const Spacer(),
                Text(
                  UiStrings.innerDemonPanelProgress(clearedCount, totalCount),
                  style: const TextStyle(
                    color: WuxiaColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: progress.toDouble(),
              minHeight: 6,
              backgroundColor: WuxiaColors.barTrack,
              valueColor: AlwaysStoppedAnimation<Color>(
                isBlocked
                    ? WuxiaColors.resultHighlight
                    : WuxiaColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            ..._body(),
          ],
        ),
      ),
    );
  }

  List<Widget> _body() {
    switch (state) {
      case InnerDemonPanelState.cleared:
        return const [
          Text(
            UiStrings.innerDemonClearedLabel,
            style: TextStyle(color: WuxiaColors.textMuted, fontSize: 12),
          ),
        ];
      case InnerDemonPanelState.blocked:
        return [
          Text(
            UiStrings.innerDemonBlockedBody(blockingStageName ?? ''),
            style: const TextStyle(color: WuxiaColors.textMuted, fontSize: 12),
          ),
          if (onNavigate != null) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: onNavigate,
                child: const Text(UiStrings.innerDemonBreakthroughCta),
              ),
            ),
          ],
        ];
      case InnerDemonPanelState.inProgress:
        return [
          if (nextStageName != null)
            Text(
              UiStrings.innerDemonNextLabel(nextStageName!),
              style: const TextStyle(color: WuxiaColors.textMuted, fontSize: 12),
            ),
          if (onNavigate != null) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: onNavigate,
                child: const Text(UiStrings.breakthroughGoToInnerDemon),
              ),
            ),
          ],
        ];
    }
  }
}
```

- [ ] **Step 4: 跑测试确认通过**

Run: `flutter test test/features/inner_demon/presentation/inner_demon_progress_panel_test.dart`
Expected: PASS（3 测）。

- [ ] **Step 5: 提交**

```bash
git add lib/features/inner_demon/presentation/breakthrough_blocker.dart test/features/inner_demon/presentation/inner_demon_progress_panel_test.dart
git commit -m "feat: InnerDemonProgressPanel 三态纯渲染(泛化旧 blocker)"
```

---

## Task 6: `_BreakthroughBlockerSection` 接线重写（③）

**Files:**
- Modify: `lib/features/character_panel/presentation/character_panel_screen.dart`（imports + `_BreakthroughBlockerSection` L355-419 + L408 引用）
- Test: 扩 `test/features/character_panel/presentation/character_panel_screen_test.dart`

- [ ] **Step 1: 写失败测试（接线:非武圣 shrink + 武圣被拦显面板）**

在 `character_panel_screen_test.dart` 末尾追加（`pumpPanel` 已支持 overrides;新增对 `innerDemonProgressProvider` 的 override 入口 —— 见 Step 1b）。

先在文件顶部 import:
```dart
import 'package:wuxia_idle/features/inner_demon/application/inner_demon_providers.dart';
import 'package:wuxia_idle/features/inner_demon/domain/inner_demon_progress.dart';
```

- [ ] **Step 1b: 给 `pumpPanel` 加 `innerDemonProgress` override 参数**

把 `pumpPanel` 签名加可选参数并在 overrides 列表追加:
```dart
  Future<void> pumpPanel(
    WidgetTester tester, {
    required Character character,
    Map<int, Character> extraCharacters = const {},
    List<int>? activeIds,
    Map<int, Equipment> equipments = const {},
    Map<int, Technique> techniques = const {},
    InnerDemonProgress? innerDemonProgress, // ← 新增
  }) async {
    // ...（保持原有 setSurfaceSize / ids）...
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          // ...（原有 overrides）...
          if (innerDemonProgress != null)
            innerDemonProgressProvider.overrideWith(
              (ref) async => innerDemonProgress,
            ),
        ],
        child: MaterialApp(
          home: CharacterPanelScreen(characterId: character.id),
        ),
      ),
    );
    // ...（保持 4×pump）...
  }
```

测试用例:
```dart
  testWidgets('③ 非武圣 → 心魔面板不显', (tester) async {
    await pumpPanel(
      tester,
      character: mkCharacter(realmTier: RealmTier.xueTu),
      innerDemonProgress: const InnerDemonProgress(
        clearedCount: 0,
        totalCount: 7,
        clearedStageIds: {},
        nextUnclearedStageId: 'stage_inner_demon_01',
      ),
    );
    expect(find.text(UiStrings.innerDemonPanelTitle), findsNothing);
  });

  testWidgets('③ 武圣 exp满被拦 → 显心魔面板 + X/7 + 突破 CTA', (tester) async {
    // shuLian → 升 jingTong,blocking=stage_inner_demon_03;cleared 含 _01,_02。
    final wuSheng = mkCharacter(realmTier: RealmTier.wuSheng)
      ..realmLayer = RealmLayer.shuLian
      ..experience = 999999
      ..experienceToNextLayer = 100;
    await pumpPanel(
      tester,
      character: wuSheng,
      innerDemonProgress: const InnerDemonProgress(
        clearedCount: 2,
        totalCount: 7,
        clearedStageIds: {'stage_inner_demon_01', 'stage_inner_demon_02'},
        nextUnclearedStageId: 'stage_inner_demon_03',
      ),
    );
    expect(find.text(UiStrings.innerDemonPanelTitle), findsOneWidget);
    expect(find.text(UiStrings.innerDemonPanelProgress(2, 7)), findsOneWidget);
    expect(find.text(UiStrings.innerDemonBreakthroughCta), findsOneWidget);
  });
```

> `mkCharacter` 现固定 `realmLayer: RealmLayer.qiMeng`,需在 fixture 后用 `..realmLayer = ...` 覆盖（Character 字段可写）。`experience` / `experienceToNextLayer` 同理可写。若 `mkCharacter` 不暴露这些,直接在返回对象上 `..` 设。

- [ ] **Step 2: 跑测试确认失败**

Run: `flutter test test/features/character_panel/presentation/character_panel_screen_test.dart -n "③"`
Expected: FAIL（武圣用例:现 section 用旧 `InnerDemonBreakthroughBlocker` + 读 mainlineProgressProvider,面板标题文案不匹配 / 或编译失败因 import 未用）。

- [ ] **Step 3: 重写 `_BreakthroughBlockerSection`**

替换 imports（删 `breakthrough_blocker.dart` 旧符号不用改路径,类名已换;加 provider/panel/progress import）:
```dart
import '../../inner_demon/application/inner_demon_providers.dart';
import '../../inner_demon/domain/inner_demon_panel.dart';
// 保留: inner_demon_service.dart / inner_demon_def.dart / breakthrough_blocker.dart / inner_demon_screen.dart / mainline_providers.dart
```

`_BreakthroughBlockerSection.build` 全替换:
```dart
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (character.realmTier != RealmTier.wuSheng) {
      return const SizedBox.shrink();
    }
    final progressAsync = ref.watch(innerDemonProgressProvider);
    final progress = progressAsync.asData?.value;
    if (progress == null) return const SizedBox.shrink(); // loading/err 不闪

    final innerDemonDef = GameRepository.instance.numbers.innerDemon;
    final data = resolveInnerDemonPanel(
      character: character,
      progress: progress,
      innerDemonDef: innerDemonDef,
    );
    if (data == null) return const SizedBox.shrink();

    String? nameFor(String? id) => id == null
        ? null
        : (GameRepository.instance.stageDefs[id]?.name ?? id);

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: InnerDemonProgressPanel(
        state: data.state,
        clearedCount: data.clearedCount,
        totalCount: data.totalCount,
        blockingStageName: nameFor(data.blockingStageId),
        nextStageName: nameFor(data.nextStageId),
        onNavigate: data.state == InnerDemonPanelState.cleared
            ? null
            : () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const InnerDemonScreen(),
                  ),
                ),
      ),
    );
  }
```

> 删掉旧 build 里 `RealmLayer.values` / `isLayerLocked` / `blockingStageId` 反查 / `InnerDemonBreakthroughBlocker` 调用（逻辑已移入 `resolveInnerDemonPanel`）。section 顶部 doc 注释同步更新为「武圣常驻心魔进度面板,解析见 resolveInnerDemonPanel」。

- [ ] **Step 4: 跑测试确认通过 + 回归既有 character_panel 测**

Run: `flutter test test/features/character_panel/presentation/character_panel_screen_test.dart`
Expected: PASS（含新 2 测 + 既有用例不破）。

- [ ] **Step 5: analyze（确认旧符号无残留未用 import）**

Run: `flutter analyze lib/features/character_panel/ lib/features/inner_demon/`
Expected: No issues（若报 `inner_demon_def`/`inner_demon_service` import 未用,删之 —— 逻辑已外移）。

- [ ] **Step 6: 提交**

```bash
git add lib/features/character_panel/presentation/character_panel_screen.dart test/features/character_panel/presentation/character_panel_screen_test.dart
git commit -m "feat: 角色面板心魔成长瓶颈面板接线(武圣常驻 X/7)"
```

---

## Task 7: 主修心法 hero 化（②）

**Files:**
- Modify: `lib/features/character_panel/presentation/character_panel_screen.dart`（`_MainTechniqueTile` L1067-1176 data 分支）
- Test: 扩 `test/features/character_panel/presentation/character_panel_screen_test.dart`

- [ ] **Step 1: 写失败测试（主修名渲染 + 纸底 + 进度条）**

文件顶部 import:
```dart
import 'package:wuxia_idle/shared/widgets/wuxia_paper_panel.dart';
```

```dart
  testWidgets('② 主修 hero:显主修名(真 def name)+ 宣纸底 + 进度条', (tester) async {
    // 用真实 techniqueDef 的 id,使 techniqueDefs[defId].name 命中。
    final realDefId = GameRepository.instance.techniqueDefs.keys.first;
    final realName = GameRepository.instance.techniqueDefs[realDefId]!.name;
    final tech = mkTechnique(
      id: 50,
      ownerId: 1,
      role: TechniqueRole.main,
      defId: realDefId,
      cultivationProgress: 40,
      cultivationProgressToNext: 100,
    );
    await pumpPanel(
      tester,
      character: mkCharacter(mainTechniqueId: 50),
      techniques: {50: tech},
    );
    expect(find.text(realName), findsOneWidget);
    expect(find.byType(WuxiaPaperPanel), findsWidgets);
    expect(find.byType(LinearProgressIndicator), findsWidgets);
    expect(tester.takeException(), isNull); // 宣纸图缺失 errorBuilder 不崩
  });
```

- [ ] **Step 2: 跑测试确认失败**

Run: `flutter test test/features/character_panel/presentation/character_panel_screen_test.dart -n "② 主修 hero"`
Expected: FAIL（现 `_MainTechniqueTile` 不显技能名 + 无 WuxiaPaperPanel）。

- [ ] **Step 3: 改 `_MainTechniqueTile` data 分支**（L1102-1173 的 `data: (t) {...}` 体内、`t != null` 分支)

替换 `return _TechniqueShell(borderColor: schoolColor, child: Column(...))` 为 WuxiaPaperPanel hero:
```dart
        final schoolColor = WuxiaColors.schoolColor(t.school);
        final techName =
            GameRepository.instance.techniqueDefs[t.defId]?.name ??
                UiStrings.techniqueRoleMain;
        final progress = t.cultivationProgressToNext == 0
            ? 0.0
            : (t.cultivationProgress / t.cultivationProgressToNext)
                .clamp(0.0, 1.0)
                .toDouble();
        return WuxiaPaperPanel(
          padding: const EdgeInsets.all(14),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Text(
                      UiStrings.techniqueRoleMain,
                      style: TextStyle(
                        color: schoolColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      EnumL10n.techniqueTier(t.tier),
                      style: const TextStyle(
                        color: WuxiaColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  techName,
                  style: TextStyle(
                    color: schoolColor,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      EnumL10n.cultivationLayer(t.cultivationLayer),
                      style: const TextStyle(
                        color: WuxiaColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      UiStrings.cultivationProgress(
                        t.cultivationProgress,
                        t.cultivationProgressToNext,
                      ),
                      style: const TextStyle(
                        color: WuxiaColors.textMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  backgroundColor: WuxiaColors.barTrack,
                  valueColor: AlwaysStoppedAnimation<Color>(schoolColor),
                ),
              ],
            ),
          ),
        );
```

> 不动 techniqueId==null / loading / error 三分支（维持 `_TechniqueShell`）。不动 `_AssistTechniqueTile`。

- [ ] **Step 4: 跑测试确认通过 + 回归**

Run: `flutter test test/features/character_panel/presentation/character_panel_screen_test.dart`
Expected: PASS（含 ② 新测 + 既有「修炼度进度条 value」用例仍过 —— 进度条仍在,LinearProgressIndicator 数量可能增减,若既有用例断言 `findsOneWidget` 而新增主修 hero 多一条,需同步既有断言。先跑确认,失败则把既有进度条断言从 `findsOneWidget` 调为 `findsWidgets` 并注明因 hero 化）。

- [ ] **Step 5: analyze**

Run: `flutter analyze lib/features/character_panel/`
Expected: No issues。

- [ ] **Step 6: 提交**

```bash
git add lib/features/character_panel/presentation/character_panel_screen.dart test/features/character_panel/presentation/character_panel_screen_test.dart
git commit -m "feat: 主修心法 tile hero 化(宣纸底 + 主修名加大)"
```

---

## Task 8: 验收 seed + route（③ 武圣被拦态可见）

**Files:**
- Modify: `lib/features/debug/application/visual_route.dart`（加枚举值）
- Modify: `lib/features/debug/presentation/visual_route_host.dart`（加 switch case）
- Modify: `lib/features/debug/application/phase2_seed_service.dart`（加 `seedCharacterPanelGrowth`）
- Test: 扩 `test/features/debug/application/phase2_seed_service_test.dart`

- [ ] **Step 1: 加 VisualRoute 枚举值**（在 `characterPanelProfile` 后）

```dart
  characterPanelGrowth('character_panel_growth',
      '角色页·心魔成长瓶颈(武圣 exp满被拦 → 心魔 2/7 面板 + 突破 CTA + 主修 hero)'),
```

- [ ] **Step 2: 写 seed（失败测试先行）**

`phase2_seed_service_test.dart` 加:
```dart
  test('seedCharacterPanelGrowth → 祖师武圣 + 心魔进度 2/7(被拦)', () async {
    await Phase2SeedService(isar: IsarSetup.instance).seedCharacterPanelGrowth();
    final founder = await IsarSetup.instance.characters.get(1);
    expect(founder, isNotNull);
    expect(founder!.realmTier, RealmTier.wuSheng);
    expect(founder.experience >= founder.experienceToNextLayer, isTrue);
    final progress = await MainlineProgressService(isar: IsarSetup.instance)
        .getOrCreate(saveDataId: IsarSetup.currentSlotId);
    final demonCleared = progress.clearedStageIds
        .where((s) => s.startsWith('stage_inner_demon_'))
        .length;
    expect(demonCleared, 2);
  });
```
（顶部按需 import `MainlineProgressService` / `RealmTier` / `IsarSetup`,沿文件既有 import 体例。）

- [ ] **Step 3: 跑测试确认失败**

Run: `flutter test test/features/debug/application/phase2_seed_service_test.dart -n "seedCharacterPanelGrowth"`
Expected: FAIL（方法不存在）。

- [ ] **Step 4: 实装 `seedCharacterPanelGrowth`**（在 `seedMasterDisciple` 之后,沿 `seedVisualCheckP5Plus` L817 bump-wuSheng 体例）

```dart
  /// 角色面板心魔成长瓶颈验收 seed(P0-3 ③)。
  ///
  /// 在 [seedMasterDisciple] 基础上把祖师(id=1)bump 到 wuSheng·shuLian + exp满,
  /// 并写 MainlineProgress.clearedStageIds = {06_05, 心魔_01, 心魔_02}
  /// → 心魔 2/7 + 当前 layer(shuLian)被 stage_inner_demon_03 拦截。
  /// 不动被广泛依赖的 seedMasterDisciple 本体。
  Future<void> seedCharacterPanelGrowth() async {
    await seedMasterDisciple();
    final repo = GameRepository.instance;
    final realm = repo.getRealm(RealmTier.wuSheng, RealmLayer.shuLian);
    await isar.writeTxn(() async {
      final founder = await isar.characters.get(1);
      if (founder != null) {
        founder.realmTier = RealmTier.wuSheng;
        founder.realmLayer = RealmLayer.shuLian;
        founder.experienceToNextLayer = realm.experienceToNext;
        founder.experience = realm.experienceToNext; // exp 满 → 触发被拦态
        founder.internalForceMax = realm.internalForceMax;
        await isar.characters.put(founder);
      }
    });
    // 写心魔通关进度(2/7,被拦在 _03)。
    final mp = MainlineProgressService(isar: isar);
    final now = DateTime.now();
    await mp.recordVictory(
      saveDataId: IsarSetup.currentSlotId,
      stageId: 'stage_06_05',
      clearedAt: now,
    );
    await mp.recordVictory(
      saveDataId: IsarSetup.currentSlotId,
      stageId: 'stage_inner_demon_01',
      clearedAt: now,
    );
    await mp.recordVictory(
      saveDataId: IsarSetup.currentSlotId,
      stageId: 'stage_inner_demon_02',
      clearedAt: now,
    );
  }
```

> 校验 `MainlineProgressService.recordVictory` 真实签名（grep `recordVictory(` 确认参数名/必填项;若签名不同按实际调整）。`getRealm` / `RealmDef.experienceToNext` / `internalForceMax` 字段名按 `lib/data/...` 实际（grep `experienceToNext` in RealmDef 确认）。若 founder bump 后违 §5.4 内力红线,clamp 到 realm.internalForceMax(已是境界上限,安全)。

- [ ] **Step 5: 加 host switch case**

`buildVisualTarget` 加（`characterPanelProfile` case 后）:
```dart
    case VisualRoute.characterPanelGrowth:
      await Phase2SeedService(isar: isar).seedCharacterPanelGrowth();
      return const CharacterPanelScreen(characterId: 1);
```

- [ ] **Step 6: 跑 seed 测 + analyze**

Run: `flutter test test/features/debug/application/phase2_seed_service_test.dart -n "seedCharacterPanelGrowth"` → PASS
Run: `flutter analyze lib/features/debug/` → No issues

- [ ] **Step 7: 提交**

```bash
git add lib/features/debug/ test/features/debug/application/phase2_seed_service_test.dart
git commit -m "feat: 角色面板心魔成长瓶颈验收 seed + route"
```

---

## Task 9: 全量验证 + 验收包重编 + Codex 派单

**Files:**
- Create: `docs/handoff/codex_vis_char_panel_bc_2026-06-04.md`（验收派单）

- [ ] **Step 1: 全量 analyze + test（CI 真绿,非 scoped）**

Run: `flutter analyze`
Expected: No issues found（memory feedback_verify_full_ci_not_scoped_lint:必跑全仓不只 scoped）。

Run: `flutter test`
Expected: All tests passed（baseline 1697 + 本批新增 ≈ 14 测 → ~1711;确认净增不破既有）。

- [ ] **Step 2: 重编验收 .app（VISUAL_ROUTE 被 kDebugMode 门控,必 debug 档）**

Run: `bash tool/build_acceptance.sh`
Expected: 预编 debug `.app` 生成（Codex `open` 即用)。失败则 build log 排查。

- [ ] **Step 3: 写 Codex 派单 doc**（沿 `codex_vis_rerun_2026-06-04.md` 体例:已编译 app + hub/route + 固定截图清单 + closeout 路径,memory feedback_codex_visual_acceptance_mac）

验收门:
- ② 主修 hero:`VISUAL_ROUTE=character_panel`（或 hub）→ 主修宣纸底 + 主修名加大(20px 校色) + 阶名/段位 + 进度条;辅修不变。
- ③ 心魔面板:`VISUAL_ROUTE=character_panel_growth`（或 hub)→ 武圣祖师显「心魔试炼 2/7」进度条 + 「突破被拦·〔关名〕未通经验留账」+ 强「突破」CTA;1280×720 无 overflow。
- 非武圣弟子 Tab → 心魔面板不显(shrink)。

- [ ] **Step 4: 提交派单 doc**

```bash
git add docs/handoff/codex_vis_char_panel_bc_2026-06-04.md
git commit -m "docs: P0-3 ②③ Codex 视觉验收派单"
```

- [ ] **Step 5: 更新 PROGRESS.md**（顶段加一条 P0-3 ②③ 闭环摘要;总行数控制 ≤100,超出归档)。

---

## Self-Review

**Spec 覆盖:**
- ③ 数据层 `InnerDemonProgress` + provider → Task 1/2 ✅
- ③ 解析器(3 态 + 非武圣) → Task 3 ✅
- ③ 视图泛化 `InnerDemonProgressPanel` + 文案 UiStrings → Task 4/5 ✅
- ③ section 接线(武圣常驻) → Task 6 ✅
- ② 主修 hero 化(宣纸底 + 名加大) → Task 7 ✅
- 验收 seed + route → Task 8 ✅
- 全量验证 + 重编 + 派单 → Task 9 ✅

**Placeholder 扫描:** 无 TBD/TODO;Task 8 标注需 grep 确认 `recordVictory`/`getRealm`/`RealmDef` 真实签名（这是「实装前验证既有 API」的正当指令,非占位）。

**类型一致性:** `InnerDemonProgress`(clearedCount/totalCount/clearedStageIds/nextUnclearedStageId)Task 1 定义,Task 2/3/6 一致引用;`InnerDemonPanelData`(state/clearedCount/totalCount/blockingStageId/nextStageId)Task 3 定义,Task 6 一致消费;`InnerDemonProgressPanel`(state/clearedCount/totalCount/blockingStageName/nextStageName/onNavigate)Task 5 定义,Task 6 一致调用;UiStrings 名 Task 4 定义,Task 5/6 一致引用。

**红线:** totalCount 派生不硬编码(Task 1)、文案全 UiStrings(Task 4)、单一真相源 clearedStageIds(Task 1/2)、不动 isLayerLocked 本体(仅消费)、不动 seedMasterDisciple(Task 8 新建独立 seed)、不动辅修 tile(Task 7)。
