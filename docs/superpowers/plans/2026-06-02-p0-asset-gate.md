# P0 缺图门禁 实现计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 建一个 build-time 资产缺图审计工具（出权威缺图清单 + 防回归 guard）+ debug 缺图角标，让 107+44 缺图可见可追踪，不堵已知 backlog。

**Architecture:** A 纯扫描库 `test/tools/asset_audit.dart`（读 `GameRepository.instance` 收集所有资产引用 → 检查磁盘存在性 → 出报告）；`asset_audit_test.dart` 生成 md 报告 + 2 条 allowlist guard 测；B `lib/shared/widgets/asset_fallback.dart` 共享 errorBuilder 工厂，debug 在原 fallback 上叠「缺图」角标（叠加不替换，release 不变）。

**Tech Stack:** Dart / Flutter test、`GameRepository`（已有 def loader）、`dart:io`（文件存在性 + 报告写入）。

---

## 前置

- [ ] **开 feature 分支**（当前 main）

Run: `git checkout -b feat/p0-asset-gate`

> bg session cwd 非 repo、EnterWorktree 不可用，直接在 repo 内开分支。

---

## Task 1: 扫描库——AssetRef + collectAssetRefs

**Files:**
- Create: `test/tools/asset_audit.dart`
- Test: `test/tools/asset_audit_test.dart`

- [ ] **Step 1: 写扫描库**

Create `test/tools/asset_audit.dart`:

```dart
// 资产缺图审计——纯扫描逻辑（读 GameRepository.instance）。
// 跑法见 asset_audit_test.dart。
import 'dart:io';

import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/mainline/domain/chapter_assets.dart';

enum AssetCategory { equipment, enemy, portrait, scene, chapterCover, narrative }

class AssetRef {
  final String path;
  final AssetCategory category;
  final String sourceId; // 谁引用了它（报告标注用）
  const AssetRef(this.path, this.category, this.sourceId);
}

bool assetExists(String path) => File(path).existsSync();

/// 从生产 def 收集所有被引用的资产路径。
List<AssetRef> collectAssetRefs() {
  final repo = GameRepository.instance;
  final refs = <AssetRef>[];

  // 装备 icon（必填）+ detail（可空）
  for (final e in repo.equipmentDefs.values) {
    refs.add(AssetRef(e.iconPath, AssetCategory.equipment, e.id));
    final d = e.detailPath;
    if (d != null) {
      refs.add(AssetRef(d, AssetCategory.equipment, '${e.id} (detail)'));
    }
  }

  // 主线 stage：敌人 iconPath + 场景背景 + 章节封面 + 剧情背景
  final chapters = <int>{};
  for (final s in repo.stageDefs.values) {
    for (final en in s.enemyTeam) {
      if (en.iconPath.isNotEmpty) {
        refs.add(AssetRef(en.iconPath, AssetCategory.enemy, s.id));
      }
    }
    final sb = s.sceneBackgroundPath;
    if (sb != null) refs.add(AssetRef(sb, AssetCategory.scene, s.id));
    if (s.stageType == StageType.mainline) {
      chapters.add(s.chapterIndex);
      refs.add(AssetRef(stageNarrativePath(s.id), AssetCategory.narrative, s.id));
    }
  }
  for (final c in (chapters.toList()..sort())) {
    refs.add(AssetRef(chapterCoverPath(c), AssetCategory.chapterCover, 'chapter_$c'));
  }

  // 爬塔 floor：敌人 + 场景背景
  for (final f in repo.towerFloors) {
    for (final en in f.enemyTeam) {
      if (en.iconPath.isNotEmpty) {
        refs.add(AssetRef(en.iconPath, AssetCategory.enemy, 'tower_floor_${f.floorIndex}'));
      }
    }
    final sb = f.sceneBackgroundPath;
    if (sb != null) {
      refs.add(AssetRef(sb, AssetCategory.scene, 'tower_floor_${f.floorIndex}'));
    }
  }

  // 立绘 portraitPath（祖师/弟子 + 收徒 + 门派招收）
  repo.masters.asMap().forEach((i, m) {
    final p = m.portraitPath;
    if (p != null) refs.add(AssetRef(p, AssetCategory.portrait, 'master[$i]'));
  });
  repo.recruitCandidates.forEach((k, v) {
    final p = v.portraitPath;
    if (p != null) refs.add(AssetRef(p, AssetCategory.portrait, 'recruit:$k'));
  });
  repo.sectCandidates.forEach((k, v) {
    final p = v.portraitPath;
    if (p != null) refs.add(AssetRef(p, AssetCategory.portrait, 'sect:$k'));
  });

  return refs;
}
```

- [ ] **Step 2: 写 setUpAll + 收集 smoke 测**

Create `test/tools/asset_audit_test.dart`:

```dart
// 资产缺图审计 + allowlist guard。
// 跑法:flutter test test/tools/asset_audit_test.dart
// 产出:test/tools/output/asset_audit.md + asset_audit_missing.txt
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/game_repository.dart';

import 'asset_audit.dart';

const String _outputDir = 'test/tools/output';

void main() {
  setUpAll(() async {
    if (!GameRepository.isLoaded) {
      await GameRepository.loadAllDefs(
        loader: (path) => File(path).readAsString(),
      );
    }
  });

  test('收集到各类别资产引用', () {
    final refs = collectAssetRefs();
    expect(refs, isNotEmpty);
    expect(refs.any((r) => r.category == AssetCategory.enemy), isTrue);
    expect(refs.any((r) => r.category == AssetCategory.equipment), isTrue);
  });
}
```

- [ ] **Step 3: 跑测，看是否编译通过 + 收集非空**

Run: `flutter test test/tools/asset_audit_test.dart`
Expected: PASS。**若编译报字段名不符**（如 `enemyTeam`/`chapterIndex`/`floorIndex` 等），用 `grep`/codegraph 核对实际字段名后微调 `asset_audit.dart`，再跑直到绿（这些签名按 Explore 捞回写，置信度高，预期一次过）。

- [ ] **Step 4: Commit**

```bash
git add test/tools/asset_audit.dart test/tools/asset_audit_test.dart
git commit -m "feat: 资产缺图审计扫描库 collectAssetRefs"
```

---

## Task 2: 报告生成 + missing 清单输出

**Files:**
- Modify: `test/tools/asset_audit.dart`（加 buildReport）
- Modify: `test/tools/asset_audit_test.dart`（加报告生成 test）

- [ ] **Step 1: 加 buildReport + missing helper 到 asset_audit.dart**

在 `asset_audit.dart` 末尾追加：

```dart
/// 缺图路径（去重排序）。
List<String> missingPaths(List<AssetRef> refs) {
  final s = refs.map((r) => r.path).where((p) => !assetExists(p)).toSet().toList()
    ..sort();
  return s;
}

/// 人看的分类别 md 报告（附引用源）。
String buildReport(List<AssetRef> refs) {
  final buf = StringBuffer();
  buf.writeln('# 资产缺图审计报告');
  buf.writeln();
  buf.writeln('> 工具生成，勿手改。跑法:`flutter test test/tools/asset_audit_test.dart`');
  buf.writeln();
  buf.writeln('## 汇总');
  buf.writeln();
  buf.writeln('| 类别 | 引用(去重) | 存在 | 缺失 |');
  buf.writeln('|---|---|---|---|');
  for (final cat in AssetCategory.values) {
    final paths =
        refs.where((r) => r.category == cat).map((r) => r.path).toSet();
    final miss = paths.where((p) => !assetExists(p)).length;
    buf.writeln('| ${cat.name} | ${paths.length} | ${paths.length - miss} | $miss |');
  }
  final all = refs.map((r) => r.path).toSet();
  final allMiss = all.where((p) => !assetExists(p)).length;
  buf.writeln('| **合计** | ${all.length} | ${all.length - allMiss} | $allMiss |');
  buf.writeln();
  buf.writeln('## 缺图清单');
  for (final cat in AssetCategory.values) {
    final byPath = <String, List<String>>{};
    for (final r in refs.where((r) => r.category == cat && !assetExists(r.path))) {
      byPath.putIfAbsent(r.path, () => []).add(r.sourceId);
    }
    if (byPath.isEmpty) continue;
    buf.writeln();
    buf.writeln('### ${cat.name} (${byPath.length})');
    buf.writeln();
    for (final p in byPath.keys.toList()..sort()) {
      buf.writeln('- `$p` ← ${byPath[p]!.join(', ')}');
    }
  }
  return buf.toString();
}
```

- [ ] **Step 2: 加报告生成 test 到 asset_audit_test.dart**

在 `main()` 内末尾追加：

```dart
  test('生成 asset_audit.md + asset_audit_missing.txt', () {
    final refs = collectAssetRefs();
    Directory(_outputDir).createSync(recursive: true);
    File('$_outputDir/asset_audit.md').writeAsStringSync(buildReport(refs));
    // allowlist 源:machine 看的缺图清单(每行一路径)
    File('$_outputDir/asset_audit_missing.txt')
        .writeAsStringSync('${missingPaths(refs).join('\n')}\n');
  });
```

- [ ] **Step 3: 跑测生成报告**

Run: `flutter test test/tools/asset_audit_test.dart`
Expected: PASS。

- [ ] **Step 4: 看报告确认量级**

Run: `head -20 test/tools/output/asset_audit.md && echo "--- missing count ---" && wc -l test/tools/output/asset_audit_missing.txt`
Expected: enemy 缺 ~107、equipment 缺 ~44 量级（与 Phase 0 亲验一致）。

- [ ] **Step 5: Commit**

```bash
git add test/tools/asset_audit.dart test/tools/asset_audit_test.dart test/tools/output/asset_audit.md test/tools/output/asset_audit_missing.txt
git commit -m "feat: 资产审计报告 buildReport + 缺图清单输出"
```

---

## Task 3: allowlist 初始化 + guard 1（防新增坏引用）

**Files:**
- Create: `test/fixtures/known_missing_assets.txt`
- Modify: `test/tools/asset_audit.dart`（加 loadAllowlist）
- Modify: `test/tools/asset_audit_test.dart`（加 guard 1）

- [ ] **Step 1: 用真实跑结果初始化 allowlist**

Run:
```bash
mkdir -p test/fixtures
cp test/tools/output/asset_audit_missing.txt test/fixtures/known_missing_assets.txt
wc -l test/fixtures/known_missing_assets.txt
```

> allowlist = 当前权威缺图清单 = MJ 工作队列。补齐后用 Task 5 流程刷新。

- [ ] **Step 2: 加 loadAllowlist 到 asset_audit.dart**

在 `asset_audit.dart` 末尾追加：

```dart
const String allowlistPath = 'test/fixtures/known_missing_assets.txt';

/// 读 allowlist(跳空行 + # 注释)。
Set<String> loadAllowlist([String path = allowlistPath]) {
  final f = File(path);
  if (!f.existsSync()) return <String>{};
  return f
      .readAsLinesSync()
      .map((l) => l.trim())
      .where((l) => l.isNotEmpty && !l.startsWith('#'))
      .toSet();
}
```

- [ ] **Step 3: 加 guard 1 test**

在 `asset_audit_test.dart` 的 `main()` 内追加：

```dart
  test('guard 1: 无 allowlist 外的缺图(防新增坏引用)', () {
    final missing = missingPaths(collectAssetRefs()).toSet();
    final allow = loadAllowlist();
    final offenders = missing.difference(allow).toList()..sort();
    expect(offenders, isEmpty,
        reason: '以下引用指向缺图且不在 allowlist(新增坏引用?):\n${offenders.join('\n')}');
  });
```

- [ ] **Step 4: 跑测——应绿（allowlist 刚由真实缺图填充）**

Run: `flutter test test/tools/asset_audit_test.dart`
Expected: PASS（missing ⊆ allowlist）。

- [ ] **Step 5: Commit**

```bash
git add test/fixtures/known_missing_assets.txt test/tools/asset_audit.dart test/tools/asset_audit_test.dart
git commit -m "feat: allowlist 初始化 + guard 防新增坏引用"
```

---

## Task 4: guard 2（强制补齐后清账）

**Files:**
- Modify: `test/tools/asset_audit_test.dart`

- [ ] **Step 1: 加 guard 2 test**

在 `main()` 内追加：

```dart
  test('guard 2: allowlist 无已补齐残留(补齐即清账)', () {
    final fixed = loadAllowlist().where(assetExists).toList()..sort();
    expect(fixed, isEmpty,
        reason: '以下已存在于磁盘,请从 allowlist 删除:\n${fixed.join('\n')}');
  });
```

- [ ] **Step 2: 跑测——应绿（allowlist 条目当前都不存在）**

Run: `flutter test test/tools/asset_audit_test.dart`
Expected: PASS。

- [ ] **Step 3: 手验 guard 2 会 fail（临时删 allowlist 一行的对应——反向验：临时把一个真实存在的路径加进 allowlist）**

Run:
```bash
echo "assets/ui/mountain_bg.png" >> test/fixtures/known_missing_assets.txt
flutter test test/tools/asset_audit_test.dart --plain-name "guard 2"
```
Expected: FAIL，reason 列出 `assets/ui/mountain_bg.png`。**验完撤销**:
```bash
git checkout test/fixtures/known_missing_assets.txt
```

- [ ] **Step 4: Commit**

```bash
git add test/tools/asset_audit_test.dart
git commit -m "feat: guard 2 强制美术补齐后清账"
```

---

## Task 5: B——缺图角标工厂 + widget 测

**Files:**
- Create: `lib/shared/widgets/asset_fallback.dart`
- Test: `test/shared/widgets/asset_fallback_test.dart`

- [ ] **Step 1: 写失败 widget 测**

Create `test/shared/widgets/asset_fallback_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/shared/widgets/asset_fallback.dart';

void main() {
  testWidgets('debug:缺图叠角标且 fallback 仍在', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Image.asset(
        'assets/__nonexistent__.png',
        errorBuilder: wuxiaAssetErrorBuilder(() => const Text('FB')),
      ),
    ));
    await tester.pump();
    expect(find.text('FB'), findsOneWidget); // 原 fallback 保留
    expect(find.text('缺图'), findsOneWidget); // debug 角标叠加
  });
}
```

- [ ] **Step 2: 跑测验证失败**

Run: `flutter test test/shared/widgets/asset_fallback_test.dart`
Expected: FAIL（`wuxiaAssetErrorBuilder` 未定义）。

- [ ] **Step 3: 写工厂实现**

Create `lib/shared/widgets/asset_fallback.dart`:

```dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../theme/colors.dart';

/// 缺图 errorBuilder 工厂:release 只渲染 [fallback];
/// kDebugMode 在 fallback 上叠一个「缺图」角标(叠加不替换)。
/// 用于 sized-fallback 站点(头像/立绘框/装备详情/章节封面)——
/// 空框才显得像坏图;场景背景的隐形 fallback 不接(by-design 不显坏)。
ImageErrorWidgetBuilder wuxiaAssetErrorBuilder(Widget Function() fallback) {
  return (context, error, stackTrace) {
    final fb = fallback();
    if (!kDebugMode) return fb;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        fb,
        const Positioned(top: 0, right: 0, child: _MissingAssetBadge()),
      ],
    );
  };
}

class _MissingAssetBadge extends StatelessWidget {
  const _MissingAssetBadge();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
        color: WuxiaColors.hpLow,
        child: const Text(
          '缺图',
          style: TextStyle(fontSize: 8, color: Colors.white, height: 1.0),
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: 跑测验证通过**

Run: `flutter test test/shared/widgets/asset_fallback_test.dart`
Expected: PASS。

- [ ] **Step 5: Commit**

```bash
git add lib/shared/widgets/asset_fallback.dart test/shared/widgets/asset_fallback_test.dart
git commit -m "feat: 缺图 errorBuilder 工厂 wuxiaAssetErrorBuilder + debug 角标"
```

---

## Task 6: 接入 4 个 sized-fallback 站点

**Files:**
- Modify: `lib/features/battle/presentation/character_avatar.dart:56`
- Modify: `lib/shared/widgets/portrait_frame.dart:35`
- Modify: `lib/features/inventory/presentation/equipment_detail_screen.dart:130`
- Modify: `lib/features/mainline/presentation/chapter_list_screen.dart:168`

> 每处把 `errorBuilder: (_, _, _) => X` 改为 `errorBuilder: wuxiaAssetErrorBuilder(() => X)` 并加 import。**场景背景 2 处（battle_scene_background / narrative_scene_background）不改**——其 fallback 是 `SizedBox.shrink()`，缺背景只露 scrim 不显坏。

- [ ] **Step 1: character_avatar.dart**

加 import `import '../../../shared/widgets/asset_fallback.dart';`，把 `:56` 的：
```dart
  errorBuilder: (_, _, _) => _FirstGlyphAvatar(
    avatarSize: avatarSize,
    color: borderColor,
    borderWidth: borderWidth,
    firstGlyph: firstGlyph,
  ),
```
改为：
```dart
  errorBuilder: wuxiaAssetErrorBuilder(() => _FirstGlyphAvatar(
    avatarSize: avatarSize,
    color: borderColor,
    borderWidth: borderWidth,
    firstGlyph: firstGlyph,
  )),
```

- [ ] **Step 2: portrait_frame.dart**

加 import `import 'asset_fallback.dart';`（同目录），把 `:35` 的：
```dart
  errorBuilder: (_, _, _) =>
      Container(color: WuxiaColors.avatarFill),
```
改为：
```dart
  errorBuilder: wuxiaAssetErrorBuilder(
      () => Container(color: WuxiaColors.avatarFill)),
```

- [ ] **Step 3: equipment_detail_screen.dart**

加 import `import '../../../shared/widgets/asset_fallback.dart';`，把 `:130` 的：
```dart
  errorBuilder: (_, _, _) =>
      Container(color: WuxiaColors.panel),
```
改为：
```dart
  errorBuilder: wuxiaAssetErrorBuilder(
      () => Container(color: WuxiaColors.panel)),
```

- [ ] **Step 4: chapter_list_screen.dart**

加 import `import '../../../shared/widgets/asset_fallback.dart';`，把 `:168` 的：
```dart
  errorBuilder: (_, _, _) =>
      Container(color: WuxiaColors.avatarFill),
```
改为：
```dart
  errorBuilder: wuxiaAssetErrorBuilder(
      () => Container(color: WuxiaColors.avatarFill)),
```

> import 相对路径以各文件实际深度为准；若报 import 错按 IDE 提示修正。

- [ ] **Step 5: 跑受影响 widget 测 + analyze**

Run: `flutter test test/features/battle test/features/inventory test/features/mainline test/shared && flutter analyze`
Expected: PASS / analyze 0。**若精确 finder 因 Stack 包裹断**（如某测断 `find.byType(Container)` 数量），按「叠加后多了 Stack/Positioned」调整该测的 finder（fallback 内容仍在，语义不变）。

- [ ] **Step 6: Commit**

```bash
git add lib/features/battle/presentation/character_avatar.dart lib/shared/widgets/portrait_frame.dart lib/features/inventory/presentation/equipment_detail_screen.dart lib/features/mainline/presentation/chapter_list_screen.dart
git commit -m "feat: 4 个 sized-fallback 站点接入缺图角标工厂"
```

---

## Task 7: 全量验收 + 收尾

- [ ] **Step 1: 全量测 + analyze**

Run: `flutter test && flutter analyze`
Expected: 全绿 / analyze 0（测数 = baseline + asset_audit 4 测 + asset_fallback 1 测 = +5）。

- [ ] **Step 2: 确认产出**

Run: `ls -la test/tools/output/asset_audit.md test/fixtures/known_missing_assets.txt && grep -c '' test/fixtures/known_missing_assets.txt`
Expected: 两文件在，allowlist 行数 = 当前缺图总数。

- [ ] **Step 3: 更新 §20.4 tracker 勾 P0 第一项**

把 `docs/PUBLISHING_ART_PASS_1_0.md` §20.4 的「缺图 QA manifest 门禁」一项 `[ ]`→`[x]`，加一句「`asset_audit.dart` + allowlist guard + debug 角标，缺图清单见 `test/tools/output/asset_audit.md`」。

- [ ] **Step 4: 最终 commit**

```bash
git add docs/PUBLISHING_ART_PASS_1_0.md
git commit -m "docs: §20.4 勾 P0 缺图门禁完成"
```

---

## 验收 (DoD 回填 spec §7)

- `flutter test` + `flutter analyze` 全绿。
- `asset_audit.md` 生成，enemy/equipment 缺图量级与 Phase 0 亲验一致。
- guard 1 绿（missing ⊆ allowlist）；故意引坏路径 → guard 1 fail（已在 Task 设计中以反向手验覆盖 guard 2，guard 1 的反向由日常新引用自然触发）。
- guard 2 绿；allowlist 加一个真实存在路径 → fail（Task 4 Step 3 已手验）。
- debug run 缺图见角标（widget 测覆盖）；release 分支 `!kDebugMode` 只渲染 fallback；现有 widget 测不破。

## 后续衔接

- `test/tools/output/asset_audit_missing.txt` 的 enemy 段 = Phase D 第一批 MJ prompt 输入单。
- 美术补齐后:重跑审计 → `cp asset_audit_missing.txt known_missing_assets.txt` 刷新 allowlist（guard 2 会催）。
