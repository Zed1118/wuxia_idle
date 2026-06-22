# 奇遇录（baike 第4tab「奇缘」）Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: superpowers:subagent-driven-development。逐 task 实装，checkbox 跟踪。
> spec: `docs/spec/2026-06-22-p4-encounter-codex-design.md`。姊妹参照：`lib/features/baike/presentation/baike_screen.dart`（_LoreTab/_FeedTab/_EmptyHint 体例）+ `lib/features/weapon_codex/presentation/weapon_codex_screen.dart`（剪影/点亮 tile）。

**Goal:** 把已际遇奇遇做成剪影藏名图鉴，挂进江湖见闻录第 4 tab「奇缘」；3 段分组（领悟/奇缘/节庆）+ 进度 + 点已触发卡进详情屏回看 opening 故事 + §5.7 空态保护。

**Architecture:** 纯展示层。新派生 `encounterCodexProvider`（async：拉 triggeredEncounterIds + 全 encounterDefs + 已触发 events 标题）+ `groupEncounters` 纯函数（按 type/festivalRequired 分 3 组、算点亮/剪影）。新 `_EncounterTab`（baike feature 下，沿 _LoreTab 分组列表体例）+ `encounter_detail_screen.dart`（async load event → opening）。baike `length: 3→4`。**零新 collection、零 saveVer、零迁移**。

**Tech Stack:** Flutter + Riverpod codegen(@riverpod) + Isar(只读)。events 文案 async（`EncounterEventLoader.load(id)` rootBundle）。TDD：纯函数 `test()`；UI `testWidgets`。

---

## Phase 0 已确认事实（开工前读，无需重查）

- 全集：`GameRepository.instance.allEncounters`（`List<EncounterDef>`，57 条）/ `GameRepository.instance.encounterDefs`（`Map<String,EncounterDef>` key=id）。`GameRepository.isLoaded` 守卫。
- `EncounterDef`（`encounter_def.dart:157-190`）：`id`(String) / `type`(EncounterType) / `trigger`(EncounterTrigger)。`EncounterTrigger.festivalRequired`(`Festival?`，`encounter_def.dart:106`)。
- `EncounterType`（`encounter_def.dart:7-16`）：`techniqueInsight` / `fortuneEvent` / `trial` / `karma`。**当前内容仅前两类有**（trial/karma 空）。
- 3 段派生规则：**武学领悟** = `type==techniqueInsight`；**节庆** = `trigger.festivalRequired != null`；**奇缘际遇** = 其余（`type==fortuneEvent && festivalRequired==null`，含 trial/karma 若将来有）。
- 已触发：`EncounterProgress.triggeredEncounterIds`（`List<String>`，`encounter_progress.dart:28`）。读取 provider `currentEncounterProgressProvider`（`@riverpod Future<EncounterProgress?>`，`encounter_service_providers.dart:31-39`）。
- 文案：`EncounterEventLoader.load(id)`（`encounter_event_loader.dart:85-102`，**async** rootBundle.loadString `data/events/<id>.yaml`，catch→`EncounterContent.placeholder(id)`）→ `EncounterContent{ title:String?, opening:String }`（`:24-25`）。无同步预载。
- baike 骨架（`baike_screen.dart`）：`DefaultTabController(length:3)`(:30) / `TabBar` 3×`Tab(text:)`(:44-46) / `TabBarView(children:[_FeedTab(),_LoreTab(),CodexTab()])`(:52-54)。`_LoreTab`=StatelessWidget 读 GameRepository 直出分组 ListView（无导航，:142-211）。`_FeedTab`=ConsumerWidget watch `gameEventsFeedProvider`。`_EmptyHint({required text})`(:214-236) 空态。
- UiStrings baike 词条：`baikeTabFeed/Lore/Codex`(`strings.dart:1142-1144`)。
- weapon_codex `_LockedTile`(剪影，:357-407 GestureDetector+showSnackBar `weaponCodexNotObtained`) / `_AcquiredTile`(点亮，:276-353 Navigator.push 详情)。
- baike 测体例：`test/features/baike/presentation/baike_screen_test.dart:15-21` setUpAll `GameRepository.loadAllDefs(loader: (p)=>File(p).readAsString())` + `ProviderScope(overrides:[provider.overrideWith((ref) async => ...)])`。
- 红线：纯展示零数值/yaml/saveVer/@collection 改；文案全 UiStrings/EnumL10n；§5.7 剪影不剧透条件 + 0 触发空态保护。`.g.dart` gitignored，新 @riverpod 后必 build_runner。fresh worktree 先拷 libisar.dylib + build_runner。

---

## File Structure

| 文件 | 职责 |
|------|------|
| `lib/features/baike/application/encounter_codex_provider.dart`（新建） | `EncounterCodexEntry`/`EncounterCodexGroup` 模型 + `groupEncounters` 纯函数 + `encounterCodexProvider`（async）|
| `lib/features/baike/presentation/encounter_tab.dart`（新建） | `_EncounterTab` 已抽出为公开 `EncounterTab`（分组列表 + 点亮/剪影 + 空态）|
| `lib/features/baike/presentation/encounter_detail_screen.dart`（新建） | 详情屏（async load event → title + opening + 类型标）|
| `lib/features/baike/presentation/baike_screen.dart`（改） | length 3→4 + Tab + TabBarView child |
| `lib/shared/strings.dart`（改） | UiStrings 词条 |
| `lib/features/debug/application/visual_route.dart` + host（改） | 双路由 |
| `test/features/baike/...`（新建/改） | 纯函数测 + tab widget 测 + 详情测 + 路由 parse 测 |

---

## Task 1: 派生层 — groupEncounters 纯函数 + encounterCodexProvider

**Files:**
- Create: `lib/features/baike/application/encounter_codex_provider.dart`
- Test: `test/features/baike/application/encounter_codex_provider_test.dart`

模型 + 纯函数（可单测，不碰 isar/rootBundle）+ provider（async 拉数据后调纯函数）。

- [ ] **Step 1: 写失败测**（`test()`；构造内存 EncounterDef list 喂纯函数）

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/encounter/domain/encounter_def.dart';
import 'package:wuxia_idle/features/baike/application/encounter_codex_provider.dart';

EncounterDef _def(String id, EncounterType type, {Festival? festival}) => EncounterDef(
      id: id,
      type: type,
      trigger: EncounterTrigger(festivalRequired: festival),
      baseProbability: 0.1,
      outcomeMapping: const {},
    );

void main() {
  group('groupEncounters', () {
    test('3 段分组：领悟/奇缘/节庆', () {
      final defs = [
        _def('a', EncounterType.techniqueInsight),
        _def('b', EncounterType.fortuneEvent),
        _def('c', EncounterType.fortuneEvent, festival: Festival.values.first),
      ];
      final groups = groupEncounters(defs: defs, triggeredIds: {'a'}, titles: {'a': '听雨悟剑'});
      expect(groups.length, 3);
      // 领悟段含 a 且点亮带标题
      final insight = groups.firstWhere((g) => g.kind == EncounterGroupKind.insight);
      expect(insight.entries.single.def.id, 'a');
      expect(insight.entries.single.isTriggered, true);
      expect(insight.entries.single.title, '听雨悟剑');
      // 节庆段含 c(festivalRequired != null 优先于 type)
      final festival = groups.firstWhere((g) => g.kind == EncounterGroupKind.festival);
      expect(festival.entries.single.def.id, 'c');
      // 奇缘段含 b 未触发=剪影(title null)
      final fortune = groups.firstWhere((g) => g.kind == EncounterGroupKind.fortune);
      expect(fortune.entries.single.isTriggered, false);
      expect(fortune.entries.single.title, isNull);
    });

    test('进度计数：总 + 段内', () {
      final defs = [
        _def('a', EncounterType.techniqueInsight),
        _def('b', EncounterType.techniqueInsight),
      ];
      final groups = groupEncounters(defs: defs, triggeredIds: {'a'}, titles: {'a': 'X'});
      final insight = groups.firstWhere((g) => g.kind == EncounterGroupKind.insight);
      expect(insight.triggeredCount, 1);
      expect(insight.entries.length, 2);
    });

    test('空段不产出(无该类奇遇时该段缺省)', () {
      final defs = [_def('a', EncounterType.techniqueInsight)];
      final groups = groupEncounters(defs: defs, triggeredIds: const {}, titles: const {});
      expect(groups.map((g) => g.kind), [EncounterGroupKind.insight]);
    });
  });
}
```

> 实装前 grep 核实：`EncounterDef` / `EncounterTrigger` 构造签名（`encounter_def.dart` factory + const ctor 实际必填字段，按真实签名调 `_def` helper，可能需补 outcomeMapping/baseProbability 之外字段或反之精简）；`Festival` 枚举位置（`enums.dart:329`）。若 `EncounterTrigger` 必填字段多，helper 按真实最小集构造。

- [ ] **Step 2: 跑测确认 FAIL**

Run: `flutter test test/features/baike/application/encounter_codex_provider_test.dart`
Expected: 编译失败（groupEncounters/EncounterCodexEntry/EncounterGroupKind 未定义）。

- [ ] **Step 3: 实装**

```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../data/game_repository.dart';
import '../../../data/isar_provider.dart';
import '../../encounter/domain/encounter_def.dart';
import '../../encounter/domain/encounter_event_loader.dart';
import '../../encounter/application/encounter_service_providers.dart';

part 'encounter_codex_provider.g.dart';

/// 奇遇录 3 段分类。
enum EncounterGroupKind { insight, fortune, festival }

/// 一条奇遇图鉴条目：def + 是否已际遇 + 标题(仅已触发载入,剪影为 null)。
class EncounterCodexEntry {
  const EncounterCodexEntry({
    required this.def,
    required this.isTriggered,
    this.title,
  });
  final EncounterDef def;
  final bool isTriggered;
  final String? title;
}

/// 一段(领悟/奇缘/节庆) + 段内条目 + 已际遇计数。
class EncounterCodexGroup {
  const EncounterCodexGroup({
    required this.kind,
    required this.entries,
    required this.triggeredCount,
  });
  final EncounterGroupKind kind;
  final List<EncounterCodexEntry> entries;
  final int triggeredCount;
}

/// 纯函数：按 type/festivalRequired 分 3 段(节庆优先于 type),算点亮/剪影 + 计数。
/// 空段不产出。段内保 def 输入顺序。
List<EncounterCodexGroup> groupEncounters({
  required List<EncounterDef> defs,
  required Set<String> triggeredIds,
  required Map<String, String> titles,
}) {
  EncounterGroupKind kindOf(EncounterDef d) {
    if (d.trigger.festivalRequired != null) return EncounterGroupKind.festival;
    if (d.type == EncounterType.techniqueInsight) {
      return EncounterGroupKind.insight;
    }
    return EncounterGroupKind.fortune;
  }

  final buckets = <EncounterGroupKind, List<EncounterCodexEntry>>{};
  for (final d in defs) {
    final triggered = triggeredIds.contains(d.id);
    buckets.putIfAbsent(kindOf(d), () => []).add(EncounterCodexEntry(
          def: d,
          isTriggered: triggered,
          title: triggered ? titles[d.id] : null,
        ));
  }
  // 固定段序：领悟 → 奇缘 → 节庆
  const order = [
    EncounterGroupKind.insight,
    EncounterGroupKind.fortune,
    EncounterGroupKind.festival,
  ];
  return [
    for (final k in order)
      if (buckets[k] != null)
        EncounterCodexGroup(
          kind: k,
          entries: buckets[k]!,
          triggeredCount: buckets[k]!.where((e) => e.isTriggered).length,
        ),
  ];
}

/// 奇遇录派生 provider：拉 triggeredIds + 全 defs + 已触发 events 标题,调 [groupEncounters]。
@riverpod
Future<List<EncounterCodexGroup>> encounterCodex(Ref ref) async {
  if (!GameRepository.isLoaded) return const [];
  final defs = GameRepository.instance.allEncounters;
  final progress = await ref.watch(currentEncounterProgressProvider.future);
  final triggered = (progress?.triggeredEncounterIds ?? const <String>[]).toSet();
  // 仅已触发载标题(剪影不载)
  final titles = <String, String>{};
  for (final id in triggered) {
    final content = await EncounterEventLoader.load(id);
    final t = content.title;
    if (t != null && t.isNotEmpty) titles[id] = t;
  }
  return groupEncounters(defs: defs, triggeredIds: triggered, titles: titles);
}
```

> 注：`GameRepository.instance.allEncounters` 若不存在用 `encounterDefs.values.toList()`（grep 核实，Phase 0 见 encounter_hook.dart:38 用 allEncounters）。`currentEncounterProgressProvider` 路径/名以 `encounter_service_providers.dart` 实际为准。

- [ ] **Step 4: build_runner**

Run: `dart run build_runner build --delete-conflicting-outputs 2>&1 | tail -3`
Expected: 生成 `encounter_codex_provider.g.dart`。

- [ ] **Step 5: 测 PASS + analyze**

Run: `flutter test test/features/baike/application/encounter_codex_provider_test.dart && flutter analyze lib/features/baike/application/encounter_codex_provider.dart`
Expected: PASS / 0。

- [ ] **Step 6: 提交**

```bash
git add lib/features/baike/application/encounter_codex_provider.dart test/features/baike/application/encounter_codex_provider_test.dart
git commit -m "feat: 奇遇录 Task1 派生层 groupEncounters 纯函数 + encounterCodexProvider"
```

---

## Task 2: 文案 — UiStrings 词条

**Files:**
- Modify: `lib/shared/strings.dart`
- Test: `test/features/baike/encounter_codex_l10n_test.dart`（新建小）

- [ ] **Step 1: 写失败测**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/shared/strings.dart';

void main() {
  test('奇遇录文案词条存在', () {
    expect(UiStrings.baikeTabEncounter.isNotEmpty, true);
    expect(UiStrings.encounterCodexProgress(3, 57).isNotEmpty, true);
    expect(UiStrings.encounterCodexGroupInsight.isNotEmpty, true);
    expect(UiStrings.encounterCodexEmpty.isNotEmpty, true);
    expect(UiStrings.encounterCodexLocked.isNotEmpty, true);
  });
}
```

- [ ] **Step 2: 跑测 FAIL**

Run: `flutter test test/features/baike/encounter_codex_l10n_test.dart`

- [ ] **Step 3: 加 UiStrings**（`strings.dart`，紧接 `baikeTabCodex` 后，沿体例）

```dart
static const String baikeTabEncounter = '奇缘';
// 奇遇录(江湖见闻录第4tab)
static String encounterCodexProgress(int got, int total) => '已际遇 $got/$total';
static String encounterCodexGroupProgress(int got, int total) => '$got/$total 已际遇';
static const String encounterCodexGroupInsight = '武学领悟';
static const String encounterCodexGroupFortune = '奇缘际遇';
static const String encounterCodexGroupFestival = '节庆';
static const String encounterCodexEmpty = '江湖路远，奇缘未至';
static const String encounterCodexLocked = '？？？';
static const String encounterCodexNotMet = '尚未际遇';
static const String encounterCodexDetailTitle = '奇缘录';
```

- [ ] **Step 4: 测 PASS + analyze**

Run: `flutter test test/features/baike/encounter_codex_l10n_test.dart && flutter analyze lib/shared/strings.dart`

- [ ] **Step 5: 提交**

```bash
git add lib/shared/strings.dart test/features/baike/encounter_codex_l10n_test.dart
git commit -m "feat: 奇遇录 Task2 UiStrings 词条(tab/进度/3段/空态/剪影)"
```

---

## Task 3: 详情屏 encounter_detail_screen

**Files:**
- Create: `lib/features/baike/presentation/encounter_detail_screen.dart`
- Test: `test/features/baike/presentation/encounter_detail_screen_test.dart`

async load event → 标题 + opening + 类型标。构造 `EncounterDetailScreen({required EncounterDef def})`（def 已知类型/id；标题+opening async load）。

- [ ] **Step 1: 写失败 widget 测**（用 `EncounterEventLoader.load` 的可注入 loader 参数 override，或 pump 后 pumpAndSettle 等 placeholder）

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wuxia_idle/features/encounter/domain/encounter_def.dart';
import 'package:wuxia_idle/features/baike/presentation/encounter_detail_screen.dart';

void main() {
  testWidgets('详情屏显类型标 + opening(占位兜底不崩)', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final def = EncounterDef(
      id: 'missing_event_xyz',
      type: EncounterType.techniqueInsight,
      trigger: EncounterTrigger(),
      baseProbability: 0.1,
      outcomeMapping: const {},
    );
    await tester.pumpWidget(ProviderScope(
      child: MaterialApp(home: EncounterDetailScreen(def: def)),
    ));
    await tester.pumpAndSettle();
    // 类型标(武学领悟)立即可见
    expect(find.text(UiStrings.encounterCodexGroupInsight), findsWidgets);
    // opening 走 placeholder('[文案待补:id]') 不崩
    expect(find.byType(EncounterDetailScreen), findsOneWidget);
  });
}
```

> grep 核实 `EncounterDef`/`EncounterTrigger` 真实构造签名再定 helper；`EncounterEventLoader.load` 默认 rootBundle 在 test 下对缺失文件走 catch→placeholder，不崩。import UiStrings。

- [ ] **Step 2: FAIL**（screen 未定义）

- [ ] **Step 3: 实装**（ConsumerWidget 或 StatefulWidget + FutureBuilder 加载 event）

要点：
- Scaffold + AppBar title=`UiStrings.encounterCodexDetailTitle`，背景 WuxiaColors.background，SingleChildScrollView。
- 类型标：由 def 派生（`festivalRequired!=null`→节庆 / `techniqueInsight`→武学领悟 / else 奇缘际遇，复用与 Task1 `kindOf` 同规则 → 取对应 UiStrings.encounterCodexGroup*）。即时可见（不依赖 async）。
- opening + title：`FutureBuilder<EncounterContent>(future: EncounterEventLoader.load(def.id), ...)`，loading 显 spinner，data 显 `content.title`(标题，null→def.id)+`content.opening`（水墨正文）。
- 无 Image.asset（若加须 errorBuilder）。零内联中文（全 UiStrings）。

- [ ] **Step 4: 测 PASS + 全量 analyze**

Run: `flutter test test/features/baike/presentation/encounter_detail_screen_test.dart && flutter analyze`
Expected: PASS / 0（全项目，防跨文件回归）。

- [ ] **Step 5: 提交**

```bash
git add lib/features/baike/presentation/encounter_detail_screen.dart test/features/baike/presentation/encounter_detail_screen_test.dart
git commit -m "feat: 奇遇录 Task3 详情屏(async load opening 回看故事 + 类型标)"
```

---

## Task 4: EncounterTab + baike 接第 4 tab

**Files:**
- Create: `lib/features/baike/presentation/encounter_tab.dart`
- Modify: `lib/features/baike/presentation/baike_screen.dart`
- Test: `test/features/baike/presentation/encounter_tab_test.dart`

`EncounterTab`=ConsumerWidget watch `encounterCodexProvider`；分组列表（沿 _LoreTab 体例）；空态走 `_EmptyHint` 同款；点亮行 push 详情、剪影行 snackbar。

- [ ] **Step 1: 写失败 widget 测**（override encounterCodexProvider 喂 1 点亮+1 剪影 / 空态）

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wuxia_idle/features/encounter/domain/encounter_def.dart';
import 'package:wuxia_idle/features/baike/application/encounter_codex_provider.dart';
import 'package:wuxia_idle/features/baike/presentation/encounter_tab.dart';
import 'package:wuxia_idle/features/baike/presentation/encounter_detail_screen.dart';
import 'package:wuxia_idle/shared/strings.dart';

EncounterDef _def(String id) => EncounterDef(
      id: id, type: EncounterType.techniqueInsight,
      trigger: EncounterTrigger(), baseProbability: 0.1, outcomeMapping: const {});

void main() {
  testWidgets('点亮+剪影混态渲染 + 进度', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final groups = [
      EncounterCodexGroup(kind: EncounterGroupKind.insight, triggeredCount: 1, entries: [
        EncounterCodexEntry(def: _def('a'), isTriggered: true, title: '听雨悟剑'),
        EncounterCodexEntry(def: _def('b'), isTriggered: false),
      ]),
    ];
    await tester.pumpWidget(ProviderScope(
      overrides: [encounterCodexProvider.overrideWith((ref) async => groups)],
      child: const MaterialApp(home: Scaffold(body: EncounterTab())),
    ));
    await tester.pumpAndSettle();
    expect(find.text('听雨悟剑'), findsOneWidget);
    expect(find.text(UiStrings.encounterCodexLocked), findsWidgets); // 剪影 ???
    expect(find.text(UiStrings.encounterCodexProgress(1, 2)), findsOneWidget);
  });

  testWidgets('空态(全未触发→空提示,不甩剪影墙)', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(ProviderScope(
      overrides: [encounterCodexProvider.overrideWith((ref) async => <EncounterCodexGroup>[])],
      child: const MaterialApp(home: Scaffold(body: EncounterTab())),
    ));
    await tester.pumpAndSettle();
    expect(find.text(UiStrings.encounterCodexEmpty), findsOneWidget);
  });

  testWidgets('点点亮行 push 详情屏', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final groups = [
      EncounterCodexGroup(kind: EncounterGroupKind.insight, triggeredCount: 1, entries: [
        EncounterCodexEntry(def: _def('a'), isTriggered: true, title: '听雨悟剑'),
      ]),
    ];
    await tester.pumpWidget(ProviderScope(
      overrides: [encounterCodexProvider.overrideWith((ref) async => groups)],
      child: const MaterialApp(home: Scaffold(body: EncounterTab())),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.text('听雨悟剑'));
    await tester.pumpAndSettle();
    expect(find.byType(EncounterDetailScreen), findsOneWidget);
  });
}
```

> **空态判定**：spec 是「0 触发显空态」。groups 为空（无任何 def）或 total triggered==0 都应显空态。实装时：若 `groups.isEmpty` 或所有 group 的 triggeredCount 之和==0 → 显 `_EmptyHint(UiStrings.encounterCodexEmpty)`，**不渲染剪影墙**（守 §5.7）。上面空态测用 groups==[] 触发；另可加一条「有 def 但 0 触发也走空态」测（喂全 isTriggered:false 的 group，断言显空态非剪影）。实装务必覆盖「有 def 但 0 触发」分支。

- [ ] **Step 2: FAIL**

- [ ] **Step 3: 实装 EncounterTab**

要点（ConsumerWidget，沿 _LoreTab + weapon_codex tile 体例）：
- watch `encounterCodexProvider` → `.when(loading/error/data)`。
- data：算 `totalTriggered = groups.fold(0,(s,g)=>s+g.triggeredCount)`；若 `groups.isEmpty || totalTriggered==0` → `_EmptyHint`(复用 baike `_EmptyHint` 或本地等价) 显 `encounterCodexEmpty`，return（**§5.7 不甩剪影墙**）。
- 否则 ListView：顶部进度 `encounterCodexProgress(totalTriggered, 所有 entries 总数)`；每段：段标 `encounterCodexGroup{Insight/Fortune/Festival}` + `encounterCodexGroupProgress(g.triggeredCount, g.entries.length)` + 行列表。
- 点亮行：显 `entry.title`（null 兜底 def.id）→ GestureDetector/InkWell onTap push `EncounterDetailScreen(def: entry.def)`。
- 剪影行：显 `encounterCodexLocked`（？？？）muted → onTap showSnackBar `encounterCodexNotMet`。
- 水墨配色 WuxiaColors；零内联中文。
- 抽公开 `EncounterTab`（非 `_`），供 baike + 测 + VISUAL_ROUTE 用。

- [ ] **Step 4: 接 baike 第 4 tab**（`baike_screen.dart`）
- `length: 3` → `length: 4`（:30）
- TabBar 加 `Tab(text: UiStrings.baikeTabEncounter)`（:44-46 区末）
- TabBarView children 加 `EncounterTab()`（:52-54 区末）
- import encounter_tab.dart

- [ ] **Step 5: 测 PASS + 全量 analyze + baike 全测**

Run: `flutter test test/features/baike/ && flutter analyze`
Expected: PASS（含既有 baike 测，4 tab 切换不崩）/ 0。

- [ ] **Step 6: 提交**

```bash
git add lib/features/baike/presentation/encounter_tab.dart lib/features/baike/presentation/baike_screen.dart test/features/baike/presentation/encounter_tab_test.dart
git commit -m "feat: 奇遇录 Task4 EncounterTab(分组列表+点亮/剪影+空态)+baike 接第4tab"
```

---

## Task 5: VISUAL_ROUTE 双路由

**Files:**
- Modify: `lib/features/debug/application/visual_route.dart`
- Modify: `lib/features/debug/presentation/visual_route_host.dart`
- Test: `test/features/debug/visual_route_test.dart`

- [ ] **Step 1: 加 parse 断言**（沿「已知 id → 枚举」体例）

```dart
expect(parseVisualRoute('encounter_codex'), VisualRoute.encounterCodex);
expect(parseVisualRoute('encounter_codex_detail'), VisualRoute.encounterCodexDetail);
```

- [ ] **Step 2: FAIL**

- [ ] **Step 3: 加枚举**（`visual_route.dart`，沿 weaponCodex 体例）

```dart
encounterCodex(
  'encounter_codex',
  '奇遇录 tab 目检·混态(点亮+剪影 3 段分组 + 进度)',
),
encounterCodexDetail(
  'encounter_codex_detail',
  '奇遇录详情屏目检·回看 opening 故事 + 类型标',
),
```

- [ ] **Step 4: host case + seed**（`visual_route_host.dart`，沿 _buildWeaponCodex*Visual 体例）

```dart
case VisualRoute.encounterCodex:
  return _buildEncounterCodexVisual();
case VisualRoute.encounterCodexDetail:
  return _buildEncounterCodexDetailVisual();
```
```dart
Widget _buildEncounterCodexVisual() {
  final defs = GameRepository.instance.allEncounters;
  // 取前若干 def seed：2 点亮 + 其余剪影,验混态
  final groups = groupEncounters(
    defs: defs,
    triggeredIds: defs.take(2).map((d) => d.id).toSet(),
    titles: { for (final d in defs.take(2)) d.id: '（已际遇）${d.id}' },
  );
  return ProviderScope(
    overrides: [encounterCodexProvider.overrideWith((ref) async => groups)],
    child: const Scaffold(body: EncounterTab()),
  );
}

Widget _buildEncounterCodexDetailVisual() {
  final def = GameRepository.instance.allEncounters.first;
  return EncounterDetailScreen(def: def);
}
```
> seed 用真 GameRepository defs（host 下已 loaded）；详情屏 async load 真 events 文案。import EncounterTab/EncounterDetailScreen/encounter_codex_provider/groupEncounters/GameRepository/ProviderScope。

- [ ] **Step 5: 测 PASS + 全量 analyze**

Run: `flutter test test/features/debug/visual_route_test.dart && flutter analyze`

- [ ] **Step 6: 提交**

```bash
git add lib/features/debug/application/visual_route.dart lib/features/debug/presentation/visual_route_host.dart test/features/debug/visual_route_test.dart
git commit -m "feat: 奇遇录 Task5 VISUAL_ROUTE 双路由(encounter_codex + encounter_codex_detail)"
```

---

## Task 6: 全量回归 + 收尾

- [ ] **Step 1: 全量测 + analyze**

Run: `flutter test 2>&1 | tail -5 && flutter analyze 2>&1 | tail -3`
Expected: 全量 PASS（基线 2790 + 本批新增，零回归），analyze 0。**贴实测输出，禁转抄**。

- [ ] **Step 2: 红线核对**

`git diff main --stat` 仅触 baike/encounter/debug/strings；无 numbers.yaml/encounters.yaml/saveVer/@collection/伤害掉落改。grep 新文件无内联中文（仅 UiStrings/EnumL10n + /// 注释）。

- [ ] **Step 3: 真机目检（可选，留用户/后续）**

`VISUAL_ROUTE=encounter_codex flutter run -d macos`（点亮+剪影 3 段+进度+空态）+ `=encounter_codex_detail`（opening 回看）。

- [ ] **Step 4: 合 main + 更新 PROGRESS/session**（主 checkout，Bash heredoc + python，bg 写守卫）

---

## Self-Review

- **spec 覆盖**：spec §二数据来源→Task1；§三 tab 结构(3 段/进度/剪影/空态保护)→Task1(分组)+Task4(渲染/空态)；§四详情屏→Task3；§五入口+路由→Task4(接 tab)+Task5(VISUAL_ROUTE)；§六红线→各 task 守+Task6 核对；§七测试→各 task TDD+Task6 全量。无遗漏。✅
- **placeholder 扫描**：无 TBD/TODO；「grep 核实」是明确动作非占位。✅
- **类型一致**：`groupEncounters`/`EncounterCodexEntry`/`EncounterCodexGroup`/`EncounterGroupKind`/`encounterCodexProvider`(Task1) ↔ Task4/Task5 引用一致；`UiStrings.encounterCodex*`/`baikeTabEncounter`(Task2) ↔ Task3/4 一致；`EncounterDetailScreen({required EncounterDef def})`(Task3) ↔ Task4/5 push 一致；`EncounterTab`(Task4) ↔ Task5 一致。✅
- **§5.7 空态保护**：Task4 Step1 测 + Step3 实装明确「有 def 但 0 触发也走空态不甩剪影墙」,双覆盖。✅
