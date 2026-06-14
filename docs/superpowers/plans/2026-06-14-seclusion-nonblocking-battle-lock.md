# 闭关非阻塞 + 出战锁 + 仪式感 + 快捷键 实现计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 让闭关期间游戏非阻塞(可离开界面做装备/仓库,不能战斗),主菜单常驻横幅可见闭关状态并一键回闭关屏,加开始闭关题字过场 + 桌面快捷键。

**Architecture:** 新增 `seclusion_gate.dart`(plain `FutureProvider.autoDispose` 暴露 active session + `guardBattleEntry` 出战守卫,内部读 provider 判断拦/放,「提前出关」复用既有 `completeRetreat`)。横幅/题字过场为独立 presentation 组件。主菜单 4 战斗入口 onTap 包守卫;闭关屏加返回按钮 + Shortcuts/Actions(Esc/Enter)。状态变更点 `ref.invalidate(activeRetreatSessionProvider)` 刷新横幅。0 改 numbers.yaml/schema/红线。

**Tech Stack:** Flutter Desktop · Riverpod 3.x(plain provider,不走 codegen 免 build_runner)· Isar(只读 getActiveSession)· flutter_test widget 测(provider override,免 Isar 死锁)。

**关键约束:**
- 所有中文走 UiStrings(§5.6 禁硬编码)。
- guard 拦截弹窗只用 UiStrings 常量,**不查 GameRepository 地图名**(免测试依赖 + 保持 guard 纯)。
- 测试用 `activeRetreatSessionProvider.overrideWith` 注入,不碰 Isar writeTxn(memory: testWidgets 内 writeTxn 死锁)。
- 「提前出关」走 `completeRetreat`(按已挂时长发奖),**不是** `abandonRetreat`(清零)。
- 真实境界走 `activeCharacterIdsProvider` → `characterByIdProvider`,fallback `RealmTier.xueTu`。

---

## 待确认(实现前请 reviewer 留意)

- **心魔(inner demon)入口**也是战斗,但用户确认的出战锁范围是「主线/爬塔/群战/轻功」4 个,**本计划不锁心魔**。若需一并锁,在 Task 3 多包一个 onTap(同模式)。

---

### Task 1: 新增 UiStrings 文案

**Files:**
- Modify: `lib/shared/strings.dart`(在文件末尾 `}` 前追加,跟随既有 `static const` / `static String` 体例)

- [ ] **Step 1: 追加文案常量**

在 `lib/shared/strings.dart` 类体末尾追加:

```dart
  // ── 闭关非阻塞 + 出战锁(2026-06-14 L3)──────────────────────────────
  /// 主菜单闭关横幅行:闭关中 · {地图名} · 剩 {时长}
  static String mainMenuRetreatBannerLine(String mapName, String remaining) =>
      '闭关中 · $mapName · 剩 $remaining';

  /// 剩余时长格式:有小时显「N 时 M 分」,否则「M 分」
  static String retreatRemainingText(int hours, int minutes) =>
      hours > 0 ? '$hours 时 $minutes 分' : '$minutes 分';

  /// 出战锁弹窗(闭关进行中点战斗入口)
  static const String seclusionBattleLockTitle = '闭关修行中';
  static const String seclusionBattleLockBody = '正自闭关参修,心神内守,此刻不宜出战。';
  static const String seclusionBattleLockStay = '静心继续';
  static const String seclusionBattleLockEndEarly = '提前出关';

  /// 开始闭关题字过场
  static const String seclusionEnterCaption = '闭关';
```

- [ ] **Step 2: 验证编译**

Run: `DEVELOPER_DIR=/Library/Developer/CommandLineTools flutter analyze lib/shared/strings.dart`
Expected: No issues found

- [ ] **Step 3: Commit**

```bash
git add lib/shared/strings.dart
git commit -m "feat: 闭关非阻塞+出战锁 UiStrings 文案"
```

---

### Task 2: activeRetreatSessionProvider + guardBattleEntry

**Files:**
- Create: `lib/features/seclusion/presentation/seclusion_gate.dart`
- Test: `test/features/seclusion/presentation/seclusion_gate_test.dart`

- [ ] **Step 1: 写失败测试**

创建 `test/features/seclusion/presentation/seclusion_gate_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/features/seclusion/domain/retreat_session.dart';
import 'package:wuxia_idle/features/seclusion/presentation/seclusion_gate.dart';
import 'package:wuxia_idle/shared/strings.dart';

void main() {
  RetreatSession fakeSession() => RetreatSession()
    ..saveDataId = 1
    ..mapType = RetreatMapType.shanLin
    ..durationHours = 4
    ..startedAt = DateTime(2026, 1, 1)
    ..status = RetreatStatus.active;

  Future<bool> pumpGuard(
    WidgetTester tester, {
    required RetreatSession? session,
  }) async {
    var allowed = false;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          activeRetreatSessionProvider.overrideWith((ref) async => session),
        ],
        child: MaterialApp(
          home: Consumer(
            builder: (context, ref, _) => Scaffold(
              body: ElevatedButton(
                onPressed: () => guardBattleEntry(
                  context: context,
                  ref: ref,
                  onAllowed: () => allowed = true,
                ),
                child: const Text('go'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();
    return allowed;
  }

  testWidgets('无 active session → onAllowed 调用、无拦截弹窗', (tester) async {
    final allowed = await pumpGuard(tester, session: null);
    expect(allowed, isTrue);
    expect(find.text(UiStrings.seclusionBattleLockTitle), findsNothing);
  });

  testWidgets('有 active session → 拦截弹窗、onAllowed 不调用', (tester) async {
    final allowed = await pumpGuard(tester, session: fakeSession());
    expect(allowed, isFalse);
    expect(find.text(UiStrings.seclusionBattleLockTitle), findsOneWidget);
    expect(find.text(UiStrings.seclusionBattleLockEndEarly), findsOneWidget);
  });
}
```

- [ ] **Step 2: 跑测试确认失败**

Run: `DEVELOPER_DIR=/Library/Developer/CommandLineTools flutter test test/features/seclusion/presentation/seclusion_gate_test.dart`
Expected: FAIL(`seclusion_gate.dart` 不存在 / `activeRetreatSessionProvider` 未定义)

- [ ] **Step 3: 写实现**

创建 `lib/features/seclusion/presentation/seclusion_gate.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/application/character_providers.dart';
import '../../../core/domain/enums.dart';
import '../../../data/game_repository.dart';
import '../../../data/isar_setup.dart';
import '../../../shared/strings.dart';
import '../../../shared/theme/colors.dart';
import '../application/seclusion_service_providers.dart';
import '../domain/retreat_session.dart';
import 'active_retreat_screen.dart';
import 'retreat_result_screen.dart';

/// 当前存档的活跃闭关 session(无则 null)。
///
/// plain provider(不走 codegen,免 build_runner)。横幅 watch 它响应式显示;
/// guard 读它的 future 判断拦/放。start / complete / 提前出关后
/// `ref.invalidate(activeRetreatSessionProvider)` 刷新。
final activeRetreatSessionProvider =
    FutureProvider.autoDispose<RetreatSession?>((ref) async {
  final svc = ref.watch(seclusionServiceProvider);
  if (svc == null) return null;
  return svc.getActiveSession(IsarSetup.currentSlotId);
});

/// 出战守卫:闭关进行中拦截战斗入口。
///
/// 无 active session → 直接 [onAllowed]();有 → 弹水墨提示,
/// 「提前出关」走 [completeRetreat](按已挂时长发奖)。
Future<void> guardBattleEntry({
  required BuildContext context,
  required WidgetRef ref,
  required VoidCallback onAllowed,
}) async {
  final session = await ref.read(activeRetreatSessionProvider.future);
  if (session == null) {
    onAllowed();
    return;
  }
  if (!context.mounted) return;
  final endEarly = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: WuxiaColors.panel,
      title: const Text(
        UiStrings.seclusionBattleLockTitle,
        style: TextStyle(color: WuxiaColors.textPrimary),
      ),
      content: const Text(
        UiStrings.seclusionBattleLockBody,
        style: TextStyle(color: WuxiaColors.textSecondary),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text(
            UiStrings.seclusionBattleLockStay,
            style: TextStyle(color: WuxiaColors.textSecondary),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text(
            UiStrings.seclusionBattleLockEndEarly,
            style: TextStyle(color: WuxiaColors.gangMeng),
          ),
        ),
      ],
    ),
  );
  if (endEarly != true || !context.mounted) return;
  await _endRetreatEarly(context, ref, session);
}

/// 提前出关:completeRetreat(按已挂时长发奖)→ 推 RetreatResultScreen。
Future<void> _endRetreatEarly(
  BuildContext context,
  WidgetRef ref,
  RetreatSession session,
) async {
  final svc = ref.read(seclusionServiceProvider);
  if (svc == null) return;
  final ids = await ref.read(activeCharacterIdsProvider.future);
  final id = ids.isNotEmpty ? ids.first : 1;
  final ch = await ref.read(characterByIdProvider(id).future);
  final result = await svc.completeRetreat(
    session: session,
    characterId: ch?.id ?? id,
    charRealmTier: ch?.realmTier ?? RealmTier.xueTu,
    config: GameRepository.instance.numbers.retreat,
    maps: GameRepository.instance.seclusionMaps,
    now: DateTime.now(),
  );
  ref.invalidate(activeRetreatSessionProvider);
  if (!context.mounted) return;
  final mapDef = GameRepository.instance.getSeclusionMap(session.mapType);
  await Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => RetreatResultScreen(mapDef: mapDef, result: result),
    ),
  );
}
```

注:`active_retreat_screen.dart` import 是为 Task 4 横幅复用;本 Task 仅 RetreatResultScreen 真用到。若 analyze 报 unused import,Task 4 会消费,可暂留或 Task 4 时加。**为避免 analyze unused 警告,本 Task 先删 `active_retreat_screen.dart` import,Task 4 横幅文件自带。**

- [ ] **Step 4: 跑测试确认通过**

Run: `DEVELOPER_DIR=/Library/Developer/CommandLineTools flutter test test/features/seclusion/presentation/seclusion_gate_test.dart`
Expected: PASS(2 测)

- [ ] **Step 5: Commit**

```bash
git add lib/features/seclusion/presentation/seclusion_gate.dart test/features/seclusion/presentation/seclusion_gate_test.dart
git commit -m "feat: 闭关出战守卫 guardBattleEntry + activeRetreatSessionProvider"
```

---

### Task 3: 主菜单 4 战斗入口包守卫

**Files:**
- Modify: `lib/features/main_menu/presentation/main_menu.dart`(主线 158-165 / 爬塔 214-221 / 轻功 233-243 / 群战 244-254)

- [ ] **Step 1: import 守卫**

在 `main_menu.dart` import 区加:

```dart
import '../../seclusion/presentation/seclusion_gate.dart';
```

- [ ] **Step 2: 包裹 4 入口 onTap**

主线(158-165)`onTap` 改为:

```dart
        onTap: () => guardBattleEntry(
          context: context,
          ref: ref,
          onAllowed: () => _push(context, const ChapterListScreen()),
        ),
```

爬塔(214-221)`onTap` 改为:

```dart
        onTap: () => guardBattleEntry(
          context: context,
          ref: ref,
          onAllowed: () => _push(context, const TowerFloorListScreen()),
        ),
```

轻功(233-243)`onTap`(注意保留 `disabled: lateLocked` — late 锁优先,守卫只在已解锁时生效)改为:

```dart
        onTap: () => guardBattleEntry(
          context: context,
          ref: ref,
          onAllowed: () => _push(context, const LightFootScreen()),
        ),
```

群战(244-254)`onTap` 改为:

```dart
        onTap: () => guardBattleEntry(
          context: context,
          ref: ref,
          onAllowed: () => _push(context, const MassBattleScreen()),
        ),
```

- [ ] **Step 3: 验证 analyze**

Run: `DEVELOPER_DIR=/Library/Developer/CommandLineTools flutter analyze lib/features/main_menu/presentation/main_menu.dart`
Expected: No issues found

- [ ] **Step 4: 跑既有主菜单测试(若有)防回归**

Run: `DEVELOPER_DIR=/Library/Developer/CommandLineTools flutter test test/features/main_menu/`
Expected: PASS(无回归;若目录不存在跳过)

- [ ] **Step 5: Commit**

```bash
git add lib/features/main_menu/presentation/main_menu.dart
git commit -m "feat: 主菜单主线/爬塔/群战/轻功入口接出战守卫"
```

---

### Task 4: 主菜单常驻闭关横幅

**Files:**
- Create: `lib/features/main_menu/presentation/main_menu_retreat_banner.dart`
- Test: `test/features/main_menu/main_menu_retreat_banner_test.dart`
- Modify: `lib/features/main_menu/presentation/main_menu.dart`(布局插横幅)

- [ ] **Step 1: 写失败测试**

创建 `test/features/main_menu/main_menu_retreat_banner_test.dart`:

```dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/main_menu/presentation/main_menu_retreat_banner.dart';
import 'package:wuxia_idle/features/seclusion/domain/retreat_session.dart';
import 'package:wuxia_idle/features/seclusion/presentation/seclusion_gate.dart';

void main() {
  setUpAll(() async {
    if (!GameRepository.isLoaded) {
      await GameRepository.loadAllDefs(
        loader: (path) => File(path).readAsString(),
      );
    }
  });

  RetreatSession fakeSession() => RetreatSession()
    ..saveDataId = 1
    ..mapType = RetreatMapType.shanLin
    ..durationHours = 4
    ..startedAt = DateTime.now()
    ..status = RetreatStatus.active;

  Future<void> pumpBanner(
    WidgetTester tester, {
    required RetreatSession? session,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          activeRetreatSessionProvider.overrideWith((ref) async => session),
        ],
        child: const MaterialApp(
          home: Scaffold(body: MainMenuRetreatBanner()),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('有 session → 横幅显示「闭关中」+ 地图名', (tester) async {
    await pumpBanner(tester, session: fakeSession());
    expect(find.textContaining('闭关中'), findsOneWidget);
    expect(find.textContaining('山林'), findsOneWidget);
  });

  testWidgets('无 session → 横幅隐藏', (tester) async {
    await pumpBanner(tester, session: null);
    expect(find.textContaining('闭关中'), findsNothing);
  });
}
```

- [ ] **Step 2: 跑测试确认失败**

Run: `DEVELOPER_DIR=/Library/Developer/CommandLineTools flutter test test/features/main_menu/main_menu_retreat_banner_test.dart`
Expected: FAIL(`main_menu_retreat_banner.dart` 不存在)

- [ ] **Step 3: 写实现**

创建 `lib/features/main_menu/presentation/main_menu_retreat_banner.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/application/character_providers.dart';
import '../../../core/domain/enums.dart';
import '../../../data/game_repository.dart';
import '../../../shared/strings.dart';
import '../../../shared/widgets/wuxia_ui/wuxia_ui.dart';
import '../../seclusion/domain/retreat_session.dart';
import '../../seclusion/presentation/active_retreat_screen.dart';
import '../../seclusion/presentation/seclusion_gate.dart';

/// 主菜单顶部常驻闭关横幅(L3 闭关非阻塞)。
///
/// 有 active session → 显「闭关中 · {地图} · 剩 {时长}」,点击回 ActiveRetreatScreen;
/// 无 → SizedBox.shrink()。剩余时间为打开时快照(无实时 Timer)。
class MainMenuRetreatBanner extends ConsumerWidget {
  const MainMenuRetreatBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref
        .watch(activeRetreatSessionProvider)
        .maybeWhen(data: (s) => s, orElse: () => null);
    if (session == null) return const SizedBox.shrink();

    final mapDef = GameRepository.instance.getSeclusionMap(session.mapType);
    final plannedMin = session.durationHours * 60;
    final elapsedMin = DateTime.now().difference(session.startedAt).inMinutes;
    final remainingMin = (plannedMin - elapsedMin).clamp(0, plannedMin);
    final remaining = UiStrings.retreatRemainingText(
      remainingMin ~/ 60,
      remainingMin % 60,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: () => _openActive(context, ref, session, mapDef),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: WuxiaUi.jiang.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: WuxiaUi.jiang.withValues(alpha: 0.52)),
            ),
            child: Row(
              children: [
                const Icon(Icons.self_improvement, color: WuxiaUi.jiang, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    UiStrings.mainMenuRetreatBannerLine(mapDef.mapName, remaining),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: WuxiaUi.jiang,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const Icon(Icons.chevron_right, color: WuxiaUi.jiang, size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openActive(
    BuildContext context,
    WidgetRef ref,
    RetreatSession session,
    dynamic mapDef,
  ) async {
    final ids = await ref.read(activeCharacterIdsProvider.future);
    final id = ids.isNotEmpty ? ids.first : 1;
    final ch = await ref.read(characterByIdProvider(id).future);
    if (!context.mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ActiveRetreatScreen(
          session: session,
          mapDef: mapDef,
          characterId: ch?.id ?? id,
          charRealmTier: ch?.realmTier ?? RealmTier.xueTu,
        ),
      ),
    );
    ref.invalidate(activeRetreatSessionProvider);
  }
}
```

注:`_openActive` 的 `mapDef` 参数类型用 `SeclusionMapDef`(import `../../seclusion/domain/seclusion_map_def.dart`),避免 `dynamic`。实现时把签名改 `SeclusionMapDef mapDef` 并加 import。

- [ ] **Step 4: 跑测试确认通过**

Run: `DEVELOPER_DIR=/Library/Developer/CommandLineTools flutter test test/features/main_menu/main_menu_retreat_banner_test.dart`
Expected: PASS(2 测)

- [ ] **Step 5: 插入主菜单布局**

在 `main_menu.dart` build 返回的主体里,标题下、入口列表上插入 `const MainMenuRetreatBanner()`。定位:找到渲染 coreItems/battleItems 的 Column/ListView,在其顶部插一行。加 import:

```dart
import 'main_menu_retreat_banner.dart';
```

(具体插入点:reviewer 实现时找到主体滚动列的第一个 child 前插入 `const MainMenuRetreatBanner(),`。)

- [ ] **Step 6: analyze + 主菜单测试**

Run: `DEVELOPER_DIR=/Library/Developer/CommandLineTools flutter analyze lib/features/main_menu/`
Expected: No issues found

- [ ] **Step 7: Commit**

```bash
git add lib/features/main_menu/presentation/main_menu_retreat_banner.dart lib/features/main_menu/presentation/main_menu.dart test/features/main_menu/main_menu_retreat_banner_test.dart
git commit -m "feat: 主菜单常驻闭关横幅"
```

---

### Task 5: 闭关屏返回按钮 + Esc/Enter 快捷键 + 收功后刷新

**Files:**
- Modify: `lib/features/seclusion/presentation/active_retreat_screen.dart`
- Test: `test/features/seclusion/presentation/active_retreat_exit_test.dart`

- [ ] **Step 1: 写失败测试**

创建 `test/features/seclusion/presentation/active_retreat_exit_test.dart`:

```dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/seclusion/domain/retreat_session.dart';
import 'package:wuxia_idle/features/seclusion/presentation/active_retreat_screen.dart';

void main() {
  setUpAll(() async {
    if (!GameRepository.isLoaded) {
      await GameRepository.loadAllDefs(
        loader: (path) => File(path).readAsString(),
      );
    }
  });

  RetreatSession fakeSession() => RetreatSession()
    ..saveDataId = 1
    ..mapType = RetreatMapType.shanLin
    ..durationHours = 4
    ..startedAt = DateTime.now()
    ..status = RetreatStatus.active;

  Future<void> pumpActive(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1024, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final mapDef = GameRepository.instance.getSeclusionMap(RetreatMapType.shanLin);
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => ActiveRetreatScreen(
                      session: fakeSession(),
                      mapDef: mapDef,
                      characterId: 1,
                      charRealmTier: RealmTier.xueTu,
                    ),
                  ),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('闭关屏有返回按钮', (tester) async {
    await pumpActive(tester);
    expect(find.byType(ActiveRetreatScreen), findsOneWidget);
    expect(find.byType(BackButton), findsOneWidget);
  });

  testWidgets('Esc 退出闭关屏', (tester) async {
    await pumpActive(tester);
    expect(find.byType(ActiveRetreatScreen), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byType(ActiveRetreatScreen), findsNothing);
  });
}
```

- [ ] **Step 2: 跑测试确认失败**

Run: `DEVELOPER_DIR=/Library/Developer/CommandLineTools flutter test test/features/seclusion/presentation/active_retreat_exit_test.dart`
Expected: FAIL(无 BackButton / Esc 不响应)

- [ ] **Step 3: 改 active_retreat_screen.dart**

(a) import 区加:

```dart
import 'package:flutter/services.dart';
import 'seclusion_gate.dart';
```

(b) AppBar(行 146-151)`automaticallyImplyLeading: false` 改为 `automaticallyImplyLeading: true`(默认显返回按钮,pop 回上层 list/主菜单,session 不 abandon)。

(c) `_onCollect` 内 `completeRetreat` 成功后(行 109 `result` 拿到后、行 113 jingle 前)加:

```dart
      ref.invalidate(activeRetreatSessionProvider);
```

(d) `build` 返回的 `Scaffold` 用 Shortcuts/Actions/Focus 包裹。把 `return Scaffold(...)` 改为:

```dart
    return Shortcuts(
      shortcuts: <ShortcutActivator, Intent>{
        LogicalKeySet(LogicalKeyboardKey.escape): const _RetreatBackIntent(),
        LogicalKeySet(LogicalKeyboardKey.enter): const _RetreatCollectIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          _RetreatBackIntent: CallbackAction<_RetreatBackIntent>(
            onInvoke: (_) {
              Navigator.maybePop(context);
              return null;
            },
          ),
          _RetreatCollectIntent: CallbackAction<_RetreatCollectIntent>(
            onInvoke: (_) {
              if (!_isCollecting) _onCollect();
              return null;
            },
          ),
        },
        child: Focus(
          autofocus: true,
          child: Scaffold(
            // ... 原 Scaffold 内容不变 ...
          ),
        ),
      ),
    );
```

(e) 文件末尾(类外)加两个 Intent:

```dart
class _RetreatBackIntent extends Intent {
  const _RetreatBackIntent();
}

class _RetreatCollectIntent extends Intent {
  const _RetreatCollectIntent();
}
```

- [ ] **Step 4: 跑测试确认通过**

Run: `DEVELOPER_DIR=/Library/Developer/CommandLineTools flutter test test/features/seclusion/presentation/active_retreat_exit_test.dart`
Expected: PASS(2 测)

- [ ] **Step 5: 跑既有 active_retreat / seclusion 测试防回归**

Run: `DEVELOPER_DIR=/Library/Developer/CommandLineTools flutter test test/features/seclusion/`
Expected: PASS(无回归)

- [ ] **Step 6: Commit**

```bash
git add lib/features/seclusion/presentation/active_retreat_screen.dart test/features/seclusion/presentation/active_retreat_exit_test.dart
git commit -m "feat: 闭关屏返回按钮 + Esc/Enter 快捷键 + 收功刷新横幅"
```

---

### Task 6: 开始闭关题字过场 + 接线

**Files:**
- Create: `lib/features/seclusion/presentation/seclusion_enter_caption.dart`
- Test: `test/features/seclusion/presentation/seclusion_enter_caption_test.dart`
- Modify: `lib/features/seclusion/presentation/seclusion_setup_screen.dart`

- [ ] **Step 1: 写失败测试**

创建 `test/features/seclusion/presentation/seclusion_enter_caption_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/seclusion/presentation/seclusion_enter_caption.dart';
import 'package:wuxia_idle/shared/strings.dart';

void main() {
  testWidgets('题字过场渲染「闭关」并自动结束', (tester) async {
    var done = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SeclusionEnterCaption(onDone: () => done = true),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text(UiStrings.seclusionEnterCaption), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1700));
    expect(done, isTrue);
  });
}
```

- [ ] **Step 2: 跑测试确认失败**

Run: `DEVELOPER_DIR=/Library/Developer/CommandLineTools flutter test test/features/seclusion/presentation/seclusion_enter_caption_test.dart`
Expected: FAIL(`seclusion_enter_caption.dart` 不存在)

- [ ] **Step 3: 写实现**(镜像 `victory_ceremony.dart` VictorySealFlash 体例)

创建 `lib/features/seclusion/presentation/seclusion_enter_caption.dart`:

```dart
import 'package:flutter/material.dart';

import '../../../shared/strings.dart';
import '../../../shared/theme/colors.dart';

/// 开始闭关题字过场:「闭关」淡入→停→淡出 ~1600ms 自动消失(点击可跳过)。
/// 镜像 battle/presentation/victory_ceremony.dart VictorySealFlash 体例。
class SeclusionEnterCaption extends StatefulWidget {
  final VoidCallback onDone;
  const SeclusionEnterCaption({super.key, required this.onDone});

  @override
  State<SeclusionEnterCaption> createState() => _SeclusionEnterCaptionState();
}

class _SeclusionEnterCaptionState extends State<SeclusionEnterCaption>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )
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
        builder: (_, child) {
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
              child: const Text(
                UiStrings.seclusionEnterCaption,
                style: TextStyle(
                  color: WuxiaColors.textPrimary,
                  fontSize: 88,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 12,
                  shadows: [
                    Shadow(
                      blurRadius: 14,
                      color: Color(0xCC000000),
                      offset: Offset(2, 3),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// 弹题字过场并 await 至消失(自动 ~1600ms 或点击跳过)。
Future<void> showSeclusionEnterCaption(BuildContext context) async {
  if (!context.mounted) return;
  await showGeneralDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.transparent,
    transitionDuration: Duration.zero,
    pageBuilder: (ctx, a, b) =>
        SeclusionEnterCaption(onDone: () => Navigator.of(ctx).pop()),
  );
}
```

- [ ] **Step 4: 跑测试确认通过**

Run: `DEVELOPER_DIR=/Library/Developer/CommandLineTools flutter test test/features/seclusion/presentation/seclusion_enter_caption_test.dart`
Expected: PASS

- [ ] **Step 5: 接入 seclusion_setup_screen `_startRetreat`**

(a) import 区加:

```dart
import 'seclusion_enter_caption.dart';
import 'seclusion_gate.dart';
```

(b) `_startRetreat`(行 49-91)内,`startRetreat` 成功 + `if (!mounted) return;`(行 67)之后、`pushReplacement`(行 73)之前插入:

```dart
      await showSeclusionEnterCaption(context);
      if (!mounted) return;
      ref.invalidate(activeRetreatSessionProvider);
```

- [ ] **Step 6: analyze + seclusion 全测试**

Run: `DEVELOPER_DIR=/Library/Developer/CommandLineTools flutter analyze lib/features/seclusion/ && DEVELOPER_DIR=/Library/Developer/CommandLineTools flutter test test/features/seclusion/`
Expected: No issues found + PASS

- [ ] **Step 7: Commit**

```bash
git add lib/features/seclusion/presentation/seclusion_enter_caption.dart lib/features/seclusion/presentation/seclusion_setup_screen.dart test/features/seclusion/presentation/seclusion_enter_caption_test.dart
git commit -m "feat: 开始闭关题字过场 + 接入 setup"
```

---

### Task 7: 全量闸门

- [ ] **Step 1: 全仓 analyze**

Run: `DEVELOPER_DIR=/Library/Developer/CommandLineTools flutter analyze`
Expected: No issues found

- [ ] **Step 2: 全量测试**

Run: `DEVELOPER_DIR=/Library/Developer/CommandLineTools flutter test`
Expected: All tests pass(基线 2183 + 本计划新增约 8 测 → ~2191,1 skip,零回归)

- [ ] **Step 3: 更新 PROGRESS.md + UX 审查表**

- PROGRESS.md 顶段加「续9」条:L3 闭关非阻塞 + 出战锁 + 题字过场 + 快捷键。
- `docs/reviews/ux_audit_2026-06-14.md` 滚动表 L3 标 ✅。

- [ ] **Step 4: Commit + 收尾**

```bash
git add PROGRESS.md docs/reviews/ux_audit_2026-06-14.md
git commit -m "docs: PROGRESS 续9 + UX 审查 L3 闭关非阻塞收口"
```

---

## Self-Review 结果

- **Spec 覆盖**:闭关屏返回(T5)/ 横幅(T4)/ 出战锁 4 入口(T2+T3)/ 提前出关(T2)/ 题字过场(T6)/ Esc·Enter 快捷键(T5)/ 文案 UiStrings(T1)/ 0 改红线(全程)/ 测试(各 T)— 全覆盖。
- **Placeholder**:无 TBD;两处「reviewer 实现时定位」(主菜单横幅插入点 T4-S5 / dialog 无 mapName)均给了明确定位规则,非代码逻辑空白。
- **类型一致**:`activeRetreatSessionProvider` / `guardBattleEntry({context, ref, onAllowed})` / `RetreatSession` 字段 / `RetreatMapType.shanLin` / `RealmTier.xueTu` 全计划一致。
- **范围**:单一实现计划,聚焦闭关交互,未膨胀。
