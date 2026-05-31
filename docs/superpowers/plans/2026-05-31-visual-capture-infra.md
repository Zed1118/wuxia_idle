# 出版美术视觉验收基建 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 让 app 能用 `--dart-define=VISUAL_ROUTE=<id>` 无人值守直达某验收屏,配 `visual_capture.sh` 批量截图,并新增「武圣满学 7 阶」seed 关闭 cover 多 tier 验收缺口。

**Architecture:** 三层 —— ① `visual_route.dart` 枚举 + parse + env 读取(纯逻辑);② `main.dart` debug-only 启动分流 + `visual_route_host.dart`(route→seed+screen 映射,首帧打 `VISUAL_ROUTE_READY`);③ `visual_capture.sh`(循环启动 app/等就绪/截窗口/退出)。release 与日常零改动。

**Tech Stack:** Flutter Desktop(macOS)、Riverpod、Isar、`String.fromEnvironment`、`kDebugMode`、macOS `screencapture`/`osascript`。

**硬约束(每 Task 沿用):** 改代码用 Bash 带引号 heredoc 直写 main(Edit/Write 被 bg isolation guard 拦);`flutter test`/`flutter analyze` 用 `flutter` 前缀;git add 显式文件列表不用 `-A`;commit message 中文动宾。seed 测用 `test()` 非 `testWidgets()`(避 Isar 死锁)。

---

## File Structure

| 文件 | 责任 | 动作 |
|------|------|------|
| `lib/features/debug/application/visual_route.dart` | VisualRoute 枚举 + `parseVisualRoute` + `visualRouteFromEnv` | Create |
| `lib/features/debug/presentation/visual_route_host.dart` | `VisualRouteApp` 外壳 + `VisualRouteHost`(route→seed+screen 映射,就绪信号) | Create |
| `lib/features/debug/application/phase2_seed_service.dart` | 新增 `seedVisualMasterAllTiers()` 方法 | Modify(末尾追加方法) |
| `lib/main.dart` | debug-only 启动分流 | Modify(`main()` 内,`:7-12`) |
| `tools/visual_capture/visual_capture.sh` | 批量截图脚本 | Create |
| `tools/visual_capture/README.md` | 脚本用法说明 | Create |
| `test/features/debug/visual_route_test.dart` | `parseVisualRoute` 纯函数测 | Create |
| `test/features/debug/visual_master_all_tiers_seed_test.dart` | seed 测(满境界 + 7 tier 合法 + fail-fast) | Create |

**已确认锚点(Explore 核实):**
- `main.dart:7-12` — `main()` = `WidgetsFlutterBinding.ensureInitialized(); runApp(const ProviderScope(child: WuxiaApp()));`,根 widget `ProviderScope > WuxiaApp(MaterialApp, home: SplashScreen)`。
- `Phase2SeedService`(`phase2_seed_service.dart`)= class,构造 `Phase2SeedService(isar: ...)`;helper `_buildCharacter({internalForce, internalForceMax, school})`(造角色)+ `_buildTechnique({defId, tier, school, role, cultivationLayer, cultivationProgress, cultivationProgressToNext})`(`:104` 起);`seedRefineInsight()`(`:158-209`)是体例参照。
- `TechniqueTier` 枚举(`lib/core/domain/enums.dart:72-80`)= `ruMenGong, changLianGong, mingJiaGong, menPaiJueXue, jiangHuMiChuan, shiChuanShenGong, chuanShuoShenGong`(7 值升序)。
- `RealmTier`(`enums.dart:22-30`)= `xueTu, sanLiu, erLiu, yiLiu, jueDing, zongShi, wuSheng`(wuSheng 最高);`RealmLayer.dengFeng` 最高层。
- `Character`(`lib/core/domain/character.dart`)字段:`realmTier`/`realmLayer`/`mainTechniqueId:int?`/`assistTechniqueIds:List<int>`/`school:TechniqueSchool?`/`insightPoints`;`Character.create({name, realmTier, realmLayer, attributes, rarity, lineageRole, createdAt, ...})`。
- 合法性校验:`RealmUtils.techniqueTierCapOf(realmTier)` 返回该境界可学最高 tier(`technique_learning.dart:61`)。武圣 → cap = chuanShuoShenGong(全 7 阶合法)。
- `TechniquePanelScreen({required int characterId})`(`technique_panel_screen.dart:32-35`)。
- `MainMenu({super.key})` 无参(`main_menu.dart:63-64`)。
- 现有 13 seed 各 tier 首本均 gangMeng 流派:`tech_gangmeng_jichu/changlian/mingjia/menpai/jianghu/shichuan/chuanshuo`(techniques.yaml 核实,7 tier × 7 本)。

---

## Task 1: VisualRoute 枚举 + 解析(纯逻辑,先 TDD)

**Files:**
- Create: `lib/features/debug/application/visual_route.dart`
- Test: `test/features/debug/visual_route_test.dart`

- [ ] **Step 1: 写失败测试**

heredoc 写 `test/features/debug/visual_route_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/debug/application/visual_route.dart';

void main() {
  group('parseVisualRoute', () {
    test('已知 id → 对应枚举', () {
      expect(parseVisualRoute('main_menu'), VisualRoute.mainMenu);
      expect(parseVisualRoute('technique_panel_tier_all'),
          VisualRoute.techniquePanelTierAll);
      expect(parseVisualRoute('technique_panel_hero'),
          VisualRoute.techniquePanelHero);
    });

    test('未知 id → null', () {
      expect(parseVisualRoute('nope'), isNull);
    });

    test('空串 → null', () {
      expect(parseVisualRoute(''), isNull);
    });

    test('每个枚举 id 往返一致', () {
      for (final r in VisualRoute.values) {
        expect(parseVisualRoute(r.id), r);
      }
    });
  });
}
```

> 注:`import` 包名是 `wuxia_idle`(见 pubspec `name:`);若实际不同,以 pubspec 为准统一替换。

- [ ] **Step 2: 跑测试确认失败**

Run: `flutter test test/features/debug/visual_route_test.dart`
Expected: FAIL —— `visual_route.dart` 不存在 / `VisualRoute` 未定义。

- [ ] **Step 3: 写实现**

heredoc 写 `lib/features/debug/application/visual_route.dart`:

```dart
import 'package:flutter/foundation.dart';

/// 出版美术视觉验收的目标验收点。每个值对应一个 (seed + screen) 组合,
/// 由 `--dart-define=VISUAL_ROUTE=<id>` 在 debug 启动时选中。
enum VisualRoute {
  mainMenu('main_menu', '主菜单(出版美术门面 bg + 题字 + 木牌)'),
  techniquePanelTierAll(
      'technique_panel_tier_all', '心法面板·武圣满学 7 阶 cover 同屏(梯度验收)'),
  techniquePanelHero(
      'technique_panel_hero', '心法面板·主修 hero 打坐内丹态');

  const VisualRoute(this.id, this.label);

  /// dart-define 用的稳定字符串标识。
  final String id;

  /// 人读说明,进 manifest 供读图对照。
  final String label;
}

/// 纯函数:id 字符串 → 枚举,未知/空 → null。便于单测。
VisualRoute? parseVisualRoute(String raw) {
  for (final r in VisualRoute.values) {
    if (r.id == raw) return r;
  }
  return null;
}

/// 读 `--dart-define=VISUAL_ROUTE=<id>`。未传/未知 → null。
VisualRoute? visualRouteFromEnv() {
  const raw = String.fromEnvironment('VISUAL_ROUTE');
  return parseVisualRoute(raw);
}
```

- [ ] **Step 4: 跑测试确认通过**

Run: `flutter test test/features/debug/visual_route_test.dart`
Expected: PASS(4 测)。

- [ ] **Step 5: analyze**

Run: `flutter analyze lib/features/debug/application/visual_route.dart test/features/debug/visual_route_test.dart`
Expected: No issues。

- [ ] **Step 6: commit**

```bash
git add lib/features/debug/application/visual_route.dart test/features/debug/visual_route_test.dart
git commit -m "feat: VISUAL_ROUTE 枚举 + parse + env 读取(视觉验收基建第 1 层)"
```

---

## Task 2: 武圣满学 7 阶 seed(TDD,先测后码)

**Files:**
- Modify: `lib/features/debug/application/phase2_seed_service.dart`(末尾追加 `seedVisualMasterAllTiers()` + 私有常量 `_visualTierDefIds`)
- Test: `test/features/debug/visual_master_all_tiers_seed_test.dart`

**机制:** 造 1 个武圣满境界角色,遍历 `TechniqueTier.values`,每 tier 用单源 map `_visualTierDefIds` 取该 tier 的 gangMeng 首本 defId,`_buildTechnique` 造实例并绑定(首个为主修,其余辅修)。若某 tier 在 map 缺失或 yaml 无对应 def → fail-fast 抛 `StateError`。

- [ ] **Step 1: 写失败测试**

heredoc 写 `test/features/debug/visual_master_all_tiers_seed_test.dart`(用 `test()` 非 `testWidgets()`):

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/features/debug/application/phase2_seed_service.dart';

void main() {
  late Isar isar;

  setUpAll(() async {
    await GameRepository.instance.ensureLoaded();
    isar = await IsarSetup.openForTest(); // 见下方 fallback 说明
  });

  tearDownAll(() async {
    await isar.close(deleteFromDisk: true);
  });

  test('武圣满学:造出武圣 + 7 tier 各 1 心法 + 全部合法', () async {
    final svc = Phase2SeedService(isar: isar);
    await svc.seedVisualMasterAllTiers();

    final chars = await isar.characters.where().findAll();
    expect(chars, isNotEmpty);
    final ch = chars.first;
    expect(ch.realmTier, RealmTier.wuSheng);
    expect(ch.mainTechniqueId, isNotNull);

    final techs = await isar.techniques.where().findAll();
    final tiers = techs.map((t) => t.tier).toSet();
    expect(tiers.length, TechniqueTier.values.length,
        reason: '7 个 tier 各至少 1 本');

    // 合法性:武圣可学最高 = chuanShuoShenGong,全部 <= cap
    final cap = RealmUtils.techniqueTierCapOf(ch.realmTier);
    for (final t in techs) {
      expect(t.tier.index <= cap.index, isTrue,
          reason: '${t.tier} 超出武圣可学上限 $cap');
    }
  });
}
```

> **Isar test 打开方式:** 若仓库已有测试用 Isar 打开 helper(grep `openForTest`/`IsarSetup` 测试用法,或参照现有 seed 测如 `test/features/debug/` 下既有文件),沿用之;若无,参照现有 seed 测的 setUp 写法。**实装前先 grep 一个现有 seed 测文件抄 Isar 打开样板**,不要新发明。

- [ ] **Step 2: 跑测试确认失败**

Run: `flutter test test/features/debug/visual_master_all_tiers_seed_test.dart`
Expected: FAIL —— `seedVisualMasterAllTiers` 未定义。

- [ ] **Step 3: 写实现**

用 heredoc 在 `phase2_seed_service.dart` **末尾的类闭合 `}` 之前**追加(先 Read 文件确认最后一个方法与类尾位置,再精确插入):

```dart
  /// 出版美术视觉验收:武圣满境界 + 7 阶各 1 本心法,
  /// 供 technique_panel_tier_all route 一屏看全 7 张 cover 梯度。
  /// 每 tier 取 gangMeng 流派首本(单源 map)。tier 缺失 → fail-fast。
  static const Map<TechniqueTier, String> _visualTierDefIds = {
    TechniqueTier.ruMenGong: 'tech_gangmeng_jichu',
    TechniqueTier.changLianGong: 'tech_gangmeng_changlian',
    TechniqueTier.mingJiaGong: 'tech_gangmeng_mingjia',
    TechniqueTier.menPaiJueXue: 'tech_gangmeng_menpai',
    TechniqueTier.jiangHuMiChuan: 'tech_gangmeng_jianghu',
    TechniqueTier.shiChuanShenGong: 'tech_gangmeng_shichuan',
    TechniqueTier.chuanShuoShenGong: 'tech_gangmeng_chuanshuo',
  };

  Future<void> seedVisualMasterAllTiers() async {
    final numbers = GameRepository.instance.numbers;

    await isar.writeTxn(() async {
      await _clearAll();

      // 武圣满境界角色(合法持有全 7 阶,符 §5.3 锁死)
      final ch = _buildCharacter(
        internalForce: 15000,
        internalForceMax: 15000,
        school: TechniqueSchool.gangMeng,
      );
      ch.realmTier = RealmTier.wuSheng;
      ch.realmLayer = RealmLayer.dengFeng;

      final built = <Technique>[];
      for (final tier in TechniqueTier.values) {
        final defId = _visualTierDefIds[tier];
        if (defId == null) {
          throw StateError('seedVisualMasterAllTiers: tier $tier 无 defId 映射');
        }
        final role = built.isEmpty ? TechniqueRole.main : TechniqueRole.assist;
        final layer = CultivationLayer.yuanMan;
        final t = _buildTechnique(
          defId: defId,
          tier: tier,
          school: TechniqueSchool.gangMeng,
          role: role,
          cultivationLayer: layer,
          cultivationProgress: 0,
          cultivationProgressToNext: numbers.cultivationProgressToNext[layer]!,
        );
        built.add(t);
      }
      await isar.techniques.putAll(built);

      ch.mainTechniqueId = built.first.id;
      ch.assistTechniqueIds = built.skip(1).map((t) => t.id).toList();
      await isar.characters.put(ch);

      for (final t in built) {
        t.ownerCharacterId = ch.id;
      }
      await isar.techniques.putAll(built);

      final save = await isar.saveDatas.get(0) ?? (SaveData()..id = 0);
      save.tutorialStep = 3; // 打开心法面板门控
      save.activeCharacterIds = [ch.id];
      await isar.saveDatas.put(save);

      await seedBasicMaterials(isar, mojianshi: 2000, jieJing: 200);
    });
  }
```

> **实装注意:**
> - 字段名/方法签名以 Step 1 grep 出的 `_buildCharacter`/`_buildTechnique`/`_clearAll`/`seedBasicMaterials` 实际签名为准;上面参数照 `seedRefineInsight`(`:158-209`)体例,若某参数名不符按实际调整。
> - `assistTechniqueIds` 武圣可挂多本辅修;若 `_buildTechnique` 默认槽位限制致冲突,辅修上限由现有逻辑决定 —— **只要 7 tier 各 ≥1 本心法在 isar 里(test 断言点)即达验收目的**,主辅分配是 cosmetic。
> - 若 `SaveData.activeCharacterIds` 字段名不同(如 `activeIds`),以实际为准。

- [ ] **Step 4: 跑测试确认通过**

Run: `flutter test test/features/debug/visual_master_all_tiers_seed_test.dart`
Expected: PASS。

- [ ] **Step 5: analyze**

Run: `flutter analyze lib/features/debug/application/phase2_seed_service.dart test/features/debug/visual_master_all_tiers_seed_test.dart`
Expected: No issues。

- [ ] **Step 6: commit**

```bash
git add lib/features/debug/application/phase2_seed_service.dart test/features/debug/visual_master_all_tiers_seed_test.dart
git commit -m "feat: seedVisualMasterAllTiers 武圣满学 7 阶(关闭 cover 多 tier 验收缺口)"
```

---

## Task 3: VisualRouteHost + VisualRouteApp(route→seed+screen 映射)

**Files:**
- Create: `lib/features/debug/presentation/visual_route_host.dart`

> 无单元测试(widget+Isar+导航,testWidgets 易 Isar 死锁);靠 Task 5 实跑 `flutter run` 验收。逻辑保持极薄。

- [ ] **Step 1: 写实现**

heredoc 写 `lib/features/debug/presentation/visual_route_host.dart`:

```dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/game_repository.dart';
import '../../../data/isar_setup.dart';
import '../../../shared/strings.dart';
import '../../main_menu/presentation/main_menu.dart';
import '../../technique_panel/presentation/technique_panel_screen.dart';
import '../application/phase2_seed_service.dart';
import '../application/visual_route.dart';

/// debug-only 视觉验收 app 入口:跳过 SplashScreen/主菜单,
/// 按 VISUAL_ROUTE 直达目标验收屏。仅 kDebugMode + 有 dart-define 时进入。
class VisualRouteApp extends StatelessWidget {
  const VisualRouteApp({super.key, required this.route});

  final VisualRoute route;

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: MaterialApp(
        title: UiStrings.appTitle,
        theme: ThemeData.dark(useMaterial3: true),
        debugShowCheckedModeBanner: false,
        home: VisualRouteHost(route: route),
      ),
    );
  }
}

class VisualRouteHost extends ConsumerStatefulWidget {
  const VisualRouteHost({super.key, required this.route});

  final VisualRoute route;

  @override
  ConsumerState<VisualRouteHost> createState() => _VisualRouteHostState();
}

class _VisualRouteHostState extends ConsumerState<VisualRouteHost> {
  Widget? _target;
  Object? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _prepare());
  }

  Future<void> _prepare() async {
    try {
      await GameRepository.instance.ensureLoaded();
      final isar = await IsarSetup.instance;
      final svc = Phase2SeedService(isar: isar);

      Widget target;
      switch (widget.route) {
        case VisualRoute.mainMenu:
          // 正常初始存档(幂等)
          await OnboardingService(isar: isar).ensureFoundingMasters();
          target = const MainMenu();
          break;
        case VisualRoute.techniquePanelTierAll:
          await svc.seedVisualMasterAllTiers();
          target = const TechniquePanelScreen(characterId: _seedCharacterId);
          break;
        case VisualRoute.techniquePanelHero:
          await svc.seedRefineInsight();
          target = const TechniquePanelScreen(characterId: _seedCharacterId);
          break;
      }
      if (!mounted) return;
      setState(() => _target = target);
      // 目标屏挂载后下一帧打就绪信号(脚本 grep 它)
      WidgetsBinding.instance.addPostFrameCallback((_) {
        debugPrint('VISUAL_ROUTE_READY: ${widget.route.id}');
      });
    } catch (e, st) {
      if (!mounted) return;
      setState(() => _error = e);
      debugPrint('VISUAL_ROUTE_ERROR: ${widget.route.id} :: $e\n$st');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Scaffold(body: Center(child: Text('VISUAL_ROUTE_ERROR: $_error')));
    }
    return _target ??
        const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

/// seed 造出的角色 id(_buildCharacter 走 autoIncrement,_clearAll 后从 1 起)。
const int _seedCharacterId = 1;
```

> **实装注意(实装前先 grep 核实,这是本 Task 最高风险点):**
> - `IsarSetup.instance` 的实际取法(是 `await IsarSetup.instance` getter?还是 `IsarSetup.openOrInstance()`?)—— grep `class IsarSetup` 确认,以 `splash_screen.dart` 的 bootstrap 取法为准。
> - `OnboardingService` 的 import 路径(`lib/features/onboarding/application/onboarding_service.dart`)+ `ensureFoundingMasters()` 已确认(`:44-114`)。补 import。
> - `_seedCharacterId = 1`:确认 `_clearAll` 后 autoIncrement 是否复位到 1。若不复位,改为 `seedVisualMasterAllTiers`/`seedRefineInsight` 返回 `int characterId`(改 Task 2 返回 `Future<int>` 回传 `ch.id`),host 接住再传 `TechniquePanelScreen(characterId: id)`。**优先用返回 id 的稳妥写法**,别赌 autoIncrement。
> - `seedRefineInsight()` 当前返回 `Future<void>`,若改返回 id 同步调整。
> - 用 `UiStrings.appTitle`(`shared/strings.dart`)与 `main.dart` 主题保持一致。

- [ ] **Step 2: analyze**

Run: `flutter analyze lib/features/debug/presentation/visual_route_host.dart`
Expected: No issues(若报未用 import / 缺 import,按提示修)。

- [ ] **Step 3: commit**

```bash
git add lib/features/debug/presentation/visual_route_host.dart
git commit -m "feat: VisualRouteHost route→seed+screen 映射 + 就绪信号(基建第 2 层)"
```

---

## Task 4: main.dart 启动分流(debug-only)

**Files:**
- Modify: `lib/main.dart:7-12`(`main()` 函数内)

- [ ] **Step 1: 改 main()**

用 heredoc 整体重写 `lib/main.dart`(原文件仅 26 行,整写最稳):

```dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/debug/application/visual_route.dart';
import 'features/debug/presentation/visual_route_host.dart';
import 'features/splash/presentation/splash_screen.dart';
import 'shared/strings.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // debug-only 视觉验收直达:--dart-define=VISUAL_ROUTE=<id>。
  // release / 无参数 → 短路,走下方正常启动,零影响。
  if (kDebugMode) {
    final route = visualRouteFromEnv();
    if (route != null) {
      runApp(VisualRouteApp(route: route));
      return;
    }
  }

  // M4 PoC #46 美术 Stage 2 收官:启动初始化迁入 SplashScreen,
  // 期间显示 landscape_loading.png + 并行跑 GameRepository + IsarSetup。
  runApp(const ProviderScope(child: WuxiaApp()));
}

class WuxiaApp extends StatelessWidget {
  const WuxiaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: UiStrings.appTitle,
      theme: ThemeData.dark(useMaterial3: true),
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),
    );
  }
}
```

- [ ] **Step 2: analyze + 全量测试(确认无回归)**

Run: `flutter analyze`
Expected: No issues。

Run: `flutter test`
Expected: PASS,数量 = baseline 1612 + Task1(4)+ Task2(1)= **1617**(以实跑为准,delta 对得上即可)。

- [ ] **Step 3: 正常启动冒烟(确认日常零影响)**

Run: `flutter run -d macos`(不带 dart-define)
Expected: 正常进 SplashScreen → 主菜单,与改动前一致。手动确认后 `q` 退出。

- [ ] **Step 4: 直达冒烟(确认基建通)**

Run: `flutter run -d macos --dart-define=VISUAL_ROUTE=technique_panel_tier_all`
Expected: 跳过主菜单直达心法面板,日志出现 `VISUAL_ROUTE_READY: technique_panel_tier_all`,面板可见 7 阶 cover。手动确认后 `q` 退出。

- [ ] **Step 5: commit**

```bash
git add lib/main.dart
git commit -m "feat: main.dart debug-only VISUAL_ROUTE 启动分流(基建第 2 层收口)"
```

---

## Task 5: visual_capture.sh 截图脚本

**Files:**
- Create: `tools/visual_capture/visual_capture.sh`(可执行)
- Create: `tools/visual_capture/README.md`

- [ ] **Step 1: 写脚本**

heredoc 写 `tools/visual_capture/visual_capture.sh`:

```bash
#!/usr/bin/env bash
# 出版美术视觉验收批量截图:对每个 VISUAL_ROUTE 启动 macOS debug app,
# 等就绪信号 + settle,截 Flutter 窗口,退出。产图到 docs/handoff/。
# 用法:
#   visual_capture.sh                         # 截全部 route
#   visual_capture.sh main_menu tech...       # 只截指定 route id
#   visual_capture.sh --dry-run               # 只打印计划不启 app
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$REPO_ROOT"

ALL_ROUTES=(main_menu technique_panel_tier_all technique_panel_hero)
READY_TIMEOUT=120   # 秒
SETTLE=2            # 截图前等图片加载

DRY_RUN=0
ROUTES=()
for arg in "$@"; do
  if [[ "$arg" == "--dry-run" ]]; then DRY_RUN=1; else ROUTES+=("$arg"); fi
done
[[ ${#ROUTES[@]} -eq 0 ]] && ROUTES=("${ALL_ROUTES[@]}")

SHA="$(git rev-parse --short HEAD 2>/dev/null || echo nogit)"
TS="$(date +%Y%m%d_%H%M%S)"
OUT_DIR="docs/handoff/visual_capture_${SHA}_${TS}"
MANIFEST="$OUT_DIR/manifest.txt"

echo "[visual_capture] repo=$REPO_ROOT sha=$SHA"
echo "[visual_capture] routes: ${ROUTES[*]}"
echo "[visual_capture] out: $OUT_DIR"

if [[ $DRY_RUN -eq 1 ]]; then
  echo "[visual_capture] --dry-run,退出。"
  exit 0
fi

mkdir -p "$OUT_DIR"
echo "# visual_capture manifest  sha=$SHA  ts=$TS" > "$MANIFEST"

capture_one() {
  local route="$1"
  local log; log="$(mktemp -t vc_${route}.XXXXXX.log)"
  local png="$OUT_DIR/${route}.png"

  echo "[visual_capture] === $route ==="
  flutter run -d macos --dart-define=VISUAL_ROUTE="$route" >"$log" 2>&1 &
  local run_pid=$!

  # 轮询就绪 / 失败签名 / 进程早退
  local waited=0 ready=0
  while [[ $waited -lt $READY_TIMEOUT ]]; do
    if grep -q "VISUAL_ROUTE_READY: $route" "$log"; then ready=1; break; fi
    if grep -qE "VISUAL_ROUTE_ERROR|Exception|Error:|Failed to|Compilation failed" "$log"; then
      echo "[visual_capture] $route 失败签名,见 $log"; break
    fi
    if ! kill -0 "$run_pid" 2>/dev/null; then
      echo "[visual_capture] $route 进程早退,见 $log"; break
    fi
    sleep 1; waited=$((waited+1))
  done

  if [[ $ready -eq 1 ]]; then
    sleep "$SETTLE"
    # 取 Flutter app 窗口 id 截窗口;失败兜底全屏
    local wid
    wid="$(osascript -e 'tell application "System Events" to tell (first process whose frontmost is true) to id of front window' 2>/dev/null || echo "")"
    if [[ -n "$wid" ]]; then
      screencapture -l"$wid" -o "$png" 2>/dev/null || screencapture -o "$png"
    else
      echo "[visual_capture] $route 窗口 id 取失败,用交互全屏(请框选)"; screencapture -o "$png"
    fi
    echo "$route -> ${route}.png -> READY" >> "$MANIFEST"
    echo "[visual_capture] $route 截图 -> $png"
  else
    echo "$route -> (无图) -> TIMEOUT/FAIL (log: $log)" >> "$MANIFEST"
    echo "[visual_capture] $route 未就绪(${waited}s),跳过截图。"
  fi

  # 精确关本次 app
  kill "$run_pid" 2>/dev/null || true
  wait "$run_pid" 2>/dev/null || true
}

for route in "${ROUTES[@]}"; do
  capture_one "$route"
done

echo "[visual_capture] 完成。manifest: $MANIFEST"
cat "$MANIFEST"
```

- [ ] **Step 2: chmod + dry-run 自检**

```bash
chmod +x tools/visual_capture/visual_capture.sh
tools/visual_capture/visual_capture.sh --dry-run
```
Expected: 打印 routes(main_menu / technique_panel_tier_all / technique_panel_hero)+ out 目录,不启 app,exit 0。

- [ ] **Step 3: 写 README**

heredoc 写 `tools/visual_capture/README.md`:

```markdown
# visual_capture

出版美术视觉验收批量截图。对每个 `VISUAL_ROUTE` 启动 macOS debug app,
等就绪信号截 Flutter 窗口,产图到 `docs/handoff/visual_capture_<sha>_<ts>/`。

## 用法

    tools/visual_capture/visual_capture.sh              # 截全部 route
    tools/visual_capture/visual_capture.sh main_menu    # 只截指定 route id
    tools/visual_capture/visual_capture.sh --dry-run    # 打印计划不启 app

route id 见 `lib/features/debug/application/visual_route.dart` 的 `VisualRoute`。
新增验收屏:加 VisualRoute 枚举值 + VisualRouteHost 映射 + 本脚本 ALL_ROUTES。

## 依赖

macOS `screencapture` / `osascript`;Flutter macOS desktop 已 enable。
窗口 id 取失败时回退交互式全屏(需手动框选)。

## 产物

`<out>/<route>.png` + `manifest.txt`(route→文件→就绪状态),供 Codex / 读图对照。
截图不入 git(随项目惯例留本地),仅脚本与 README 入库。
```

- [ ] **Step 4: 实跑全量截图(人工验收基建闭环)**

```bash
tools/visual_capture/visual_capture.sh
```
Expected: 3 个 route 各产 1 png + manifest;肉眼看 `technique_panel_tier_all.png` 应见 7 阶 cover 梯度同屏。**若窗口 id 取法不稳(截到别的窗口/桌面),调 Step 1 的 osascript 取窗口逻辑**(可改按 app 名 `Runner`/`wuxia_idle` 匹配进程窗口)。

- [ ] **Step 5: commit(只入脚本与 README,不入截图)**

```bash
git add tools/visual_capture/visual_capture.sh tools/visual_capture/README.md
git commit -m "feat: visual_capture.sh 出版美术批量截图脚本(基建第 3 层)"
```

---

## Task 6: 收尾验证 + 文档

- [ ] **Step 1: 全量回归**

Run: `flutter analyze` → No issues。
Run: `flutter test` → baseline+5(~1617),全绿。

- [ ] **Step 2: 更新 PROGRESS.md**

在「当前阶段」段追加一条:出版美术视觉验收基建收口(VISUAL_ROUTE 直达 + 武圣满学 7 阶 seed 关闭 cover 多 tier 缺口 + visual_capture.sh)+ 测试数 delta + commit sha。沿现有体例,总行数控制 100 行内。

- [ ] **Step 3: commit**

```bash
git add PROGRESS.md
git commit -m "docs: PROGRESS 视觉验收基建收口"
```

- [ ] **Step 4: push**

```bash
git push origin main
```
Expected: 全部 commit 推上 origin/main。

---

## 自检(已对 spec 核对)

- **spec §4.1 VisualRoute** → Task 1 ✅
- **spec §4.2 main.dart 分流** → Task 4 ✅
- **spec §4.3 VisualRouteHost** → Task 3 ✅
- **spec §4.4 seedVisualMasterAllTiers** → Task 2 ✅
- **spec §4.5 visual_capture.sh** → Task 5 ✅
- **spec §5 测试边界**(纯函数测 + seed 测) → Task 1 Step1 + Task 2 Step1 ✅
- **spec §6 风险**(就绪信号/失败签名/超时/精确 kill/kDebugMode 守卫/tier fail-fast)→ Task 5 脚本 + Task 3 host + Task 4 守卫 + Task 2 StateError ✅
- **类型一致性**:`seedVisualMasterAllTiers`/`parseVisualRoute`/`visualRouteFromEnv`/`VisualRoute.id`/`_seedCharacterId` 全计划一致。**注:Task 3 Step1 注明 `_seedCharacterId` 优先改为 seed 返回 id 的稳妥写法 → 若采纳,Task 2 的 `seedVisualMasterAllTiers` 与 `seedRefineInsight` 签名改 `Future<int>`,Task 3 同步;执行时二选一,别一半。**
- **最高风险点**(执行者重点 grep 核实):Task 2 `_buildCharacter`/`_buildTechnique`/`_clearAll`/`seedBasicMaterials`/`SaveData` 字段实际签名;Task 3 `IsarSetup` 实例取法;Task 5 osascript 窗口 id 取法。三处均在对应 Task 内标注了 grep 核实指引。
