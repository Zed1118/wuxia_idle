# sect 立绘 portraitPath wiring 实装计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 让 sect 立绘在生产 UI 真正呈现(成员行 / 确认 dialog / 强制招募 debug 列表 + L3 一键验收 route),关闭 Codex B 段验收缺口。

**Architecture:** `Character.portraitPath` 新字段为成员立绘单一真相源,创建时写入(祖师 ← MasterDef / NPC ← SectCandidateDef),成员行统一读。3 个新渲染位用一个共享 `PortraitFrame` widget(DRY · 新代码不动既有 lineage/recruitment 内联体例)。

**Tech Stack:** Flutter Desktop · Riverpod · Isar(`isar_community`)· build_runner codegen。

**前置环境注意(fresh worktree):**
- 改 `Character` schema 后必跑 `dart run build_runner build --delete-conflicting-outputs` 重生 `character.g.dart`(`.g.dart` gitignored,memory `feedback_wuxia_pen_build_runner`)。
- Isar 单测在 fresh worktree 可能 `libisar.dylib` 截断 → 从主仓 `~/Desktop/Projects/挂机武侠/` 拷完整 dylib(memory `feedback_fresh_worktree_libisar_dylib`)。命令见 Task 1 Step 5。
- 所有 flutter 命令在 worktree 根目录跑。git/flutter 已由 PreToolUse hook 清代理,不加 `http_proxy=` 前缀。

---

### Task 1: Character.portraitPath schema + Isar 升版

**Files:**
- Modify: `lib/core/domain/character.dart`(字段 + factory 参数)
- Modify: `lib/data/isar_setup.dart`(saveVersion 0.14.0 → 0.15.0)
- Test: `test/core/domain/character_portrait_test.dart`(新建)

- [ ] **Step 1: 写失败测试**

新建 `test/core/domain/character_portrait_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/attributes.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/enums.dart';

void main() {
  test('Character.create 透传 portraitPath,默认 null', () {
    final withPortrait = Character.create(
      name: '竹影客',
      realmTier: RealmTier.xueTu,
      realmLayer: RealmLayer.qiMeng,
      attributes: Attributes(),
      rarity: RarityTier.biaoZhun,
      lineageRole: LineageRole.disciple,
      createdAt: DateTime(2026, 5, 31),
      portraitPath: 'assets/characters/sect_candidate_bamboo.png',
    );
    expect(withPortrait.portraitPath,
        'assets/characters/sect_candidate_bamboo.png');

    final without = Character.create(
      name: '无图',
      realmTier: RealmTier.xueTu,
      realmLayer: RealmLayer.qiMeng,
      attributes: Attributes(),
      rarity: RarityTier.biaoZhun,
      lineageRole: LineageRole.disciple,
      createdAt: DateTime(2026, 5, 31),
    );
    expect(without.portraitPath, isNull);
  });
}
```

> 注:`RealmTier.xueTu` / `RealmLayer.qiMeng` 为枚举首阶,若名不符以 `lib/core/domain/enums.dart` 实际首值为准(grep `enum RealmTier`)。

- [ ] **Step 2: 跑测试确认失败**

Run: `flutter test test/core/domain/character_portrait_test.dart`
Expected: 编译失败 `The named parameter 'portraitPath' isn't defined`。

- [ ] **Step 3: 加字段 + factory 参数**

`lib/core/domain/character.dart` — 在 `late DateTime createdAt;`(line 94)前加字段:

```dart
  /// sect 成员立绘路径(sect NPC ← SectCandidateDef.portraitPath /
  /// 祖师弟子 ← MasterDef.portraitPath)。成员行统一读此字段渲染。
  /// 默认 null → 无立绘位(不破布局)。
  String? portraitPath;
```

在 factory 参数区(`SectRank? sectRank,` 后,line 131 附近)加:

```dart
    String? portraitPath,
```

在 cascade 区(`..sectRank = sectRank;` 改为续接,line 165)加:

```dart
      ..sectRank = sectRank
      ..portraitPath = portraitPath;
```

(即把原 `..sectRank = sectRank;` 的分号去掉,接 `..portraitPath = portraitPath;`)

- [ ] **Step 4: 升 Isar saveVersion**

`lib/data/isar_setup.dart` — 在 `_currentSaveVersion` 注释块末加一行,并改值:

```dart
/// sect 立绘 wiring Character 加 portraitPath String?(sect 成员立绘)→ 升 0.15.0。
static const _currentSaveVersion = '0.15.0';
```

- [ ] **Step 5: build_runner 重生 + 拷 dylib**

```bash
cd ~/Desktop/Projects/挂机武侠/.claude/worktrees/sect-portrait-wiring
dart run build_runner build --delete-conflicting-outputs 2>&1 | tail -5
# fresh worktree Isar 单测 dylib(若已存在/非 Isar 测可跳):
[ -f libisar.dylib ] || cp ~/Desktop/Projects/挂机武侠/libisar.dylib ./ 2>/dev/null || true
```

Expected: build_runner `Succeeded`,`character.g.dart` 含 `portraitPath`。

- [ ] **Step 6: 跑测试确认通过**

Run: `flutter test test/core/domain/character_portrait_test.dart`
Expected: PASS(2 expect 全过)。

- [ ] **Step 7: Commit**

```bash
git add lib/core/domain/character.dart lib/data/isar_setup.dart test/core/domain/character_portrait_test.dart
git commit -m "[schema] Character 加 portraitPath + Isar 升 0.15.0"
```

---

### Task 2: PortraitFrame 共享 widget

**Files:**
- Create: `lib/shared/widgets/portrait_frame.dart`
- Test: `test/shared/widgets/portrait_frame_test.dart`(新建)

- [ ] **Step 1: 写失败测试**

新建 `test/shared/widgets/portrait_frame_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/shared/theme/colors.dart';
import 'package:wuxia_idle/shared/widgets/portrait_frame.dart';

void main() {
  testWidgets('portraitPath 非空 → 渲染 Image', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: PortraitFrame(
        portraitPath: 'assets/characters/sect_candidate_bamboo.png',
        size: 48,
        borderColor: WuxiaColors.border,
      ),
    ));
    expect(find.byType(Image), findsOneWidget);
  });

  testWidgets('portraitPath 为 null → 不渲染 Image(SizedBox.shrink)',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: PortraitFrame(
        portraitPath: null,
        size: 48,
        borderColor: WuxiaColors.border,
      ),
    ));
    expect(find.byType(Image), findsNothing);
  });
}
```

- [ ] **Step 2: 跑测试确认失败**

Run: `flutter test test/shared/widgets/portrait_frame_test.dart`
Expected: 编译失败 `Target of URI doesn't exist: '.../portrait_frame.dart'`。

- [ ] **Step 3: 写 PortraitFrame**

新建 `lib/shared/widgets/portrait_frame.dart`:

```dart
import 'package:flutter/material.dart';

import '../theme/colors.dart';

/// 统一立绘框(sect 成员行 / 招募 dialog / debug 列表共用 · DRY)。
///
/// [portraitPath] 为 null 时退 [SizedBox.shrink] 不占位(不破布局)。
/// 加载失败走 errorBuilder → avatarFill 底(memory feedback_image_asset_error_builder)。
class PortraitFrame extends StatelessWidget {
  const PortraitFrame({
    super.key,
    required this.portraitPath,
    required this.size,
    required this.borderColor,
  });

  final String? portraitPath;
  final double size;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        border: Border.all(color: borderColor, width: 1),
        color: WuxiaColors.avatarFill,
      ),
      child: portraitPath == null
          ? const SizedBox.shrink()
          : Image.asset(
              portraitPath!,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) =>
                  Container(color: WuxiaColors.avatarFill),
            ),
    );
  }
}
```

- [ ] **Step 4: 跑测试确认通过**

Run: `flutter test test/shared/widgets/portrait_frame_test.dart`
Expected: PASS(2 testWidgets 全过)。

- [ ] **Step 5: Commit**

```bash
git add lib/shared/widgets/portrait_frame.dart test/shared/widgets/portrait_frame_test.dart
git commit -m "feat: PortraitFrame 共享立绘框 widget"
```

---

### Task 3: 立绘写入(祖师/弟子 + NPC 两条创建路径)

**Files:**
- Modify: `lib/features/onboarding/application/master_builder.dart:34-51`(buildMasterCharacter)
- Modify: `lib/features/sect/presentation/sect_recruit_handler.dart:97-115`(runSectRecruitFlow 的 Character.create)
- Test: `test/features/onboarding/master_builder_portrait_test.dart`(新建)

- [ ] **Step 1: 写失败测试(buildMasterCharacter)**

新建 `test/features/onboarding/master_builder_portrait_test.dart`:

```dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/onboarding/application/master_builder.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    if (!GameRepository.isLoaded) {
      await GameRepository.loadAllDefs(
        loader: (p) => File(p).readAsString(),
      );
    }
  });

  test('buildMasterCharacter 透传 MasterDef.portraitPath', () {
    // GameRepository.masters 是 List<MasterDef>,按 slotIndex 0-2 连续唯一(红线保证)
    final founderDef = GameRepository.instance.masters[0]; // slot 0 = 祖师
    final ch = buildMasterCharacter(founderDef, now: DateTime(2026, 5, 31));
    expect(ch.portraitPath, founderDef.portraitPath);
    expect(ch.portraitPath, isNotNull); // masters.yaml founder.png 已配
  });
}
```

- [ ] **Step 2: 跑测试确认失败**

Run: `flutter test test/features/onboarding/master_builder_portrait_test.dart`
Expected: FAIL — `ch.portraitPath` 为 null(尚未透传)。

- [ ] **Step 3: buildMasterCharacter 透传 portraitPath**

`lib/features/onboarding/application/master_builder.dart` — `Character.create(` 内,`isActive: true,`(line 50)前加:

```dart
    portraitPath: def.portraitPath,
```

- [ ] **Step 4: runSectRecruitFlow 透传 portraitPath**

`lib/features/sect/presentation/sect_recruit_handler.dart` — `Character.create(` 内,`experienceToNextLayer: realmDef.experienceToNext,`(line 114)后加:

```dart
      portraitPath: candidate.portraitPath,
```

- [ ] **Step 5: 跑测试确认通过**

Run: `flutter test test/features/onboarding/master_builder_portrait_test.dart`
Expected: PASS。

- [ ] **Step 6: Commit**

```bash
git add lib/features/onboarding/application/master_builder.dart lib/features/sect/presentation/sect_recruit_handler.dart test/features/onboarding/master_builder_portrait_test.dart
git commit -m "feat: 祖师/弟子 + sect NPC 创建时写入 portraitPath"
```

---

### Task 4: sect_screen 成员行 portrait(48×48)

**Files:**
- Modify: `lib/features/sect/presentation/sect_screen.dart`(import + `_MemberRow` 的 Row)

- [ ] **Step 1: 加 import**

`lib/features/sect/presentation/sect_screen.dart` 顶部 import 区加(与既有 shared import 同组):

```dart
import '../../../shared/widgets/portrait_frame.dart';
```

- [ ] **Step 2: 在 _MemberRow 的 Row 最左插 PortraitFrame**

`_MemberRow.build` 内 `Row(`(line 461)的 `children: [` 后、`Expanded(`(line 463)前插:

```dart
          PortraitFrame(
            portraitPath: member.portraitPath,
            size: 48,
            borderColor: member.school == null
                ? WuxiaColors.border
                : WuxiaColors.schoolColor(member.school!),
          ),
          const SizedBox(width: 12),
```

- [ ] **Step 3: analyze 确认无错**

Run: `flutter analyze lib/features/sect/presentation/sect_screen.dart`
Expected: `No issues found!`。

- [ ] **Step 4: Commit**

```bash
git add lib/features/sect/presentation/sect_screen.dart
git commit -m "feat: sect_screen 成员行接入 48x48 立绘"
```

---

### Task 5: sect_recruit 确认 dialog portrait(96×96)

**Files:**
- Modify: `lib/features/encounter/presentation/sect_recruit_confirm_dialog.dart`(import + `_CandidateInfo`)

- [ ] **Step 1: 加 import**

`lib/features/encounter/presentation/sect_recruit_confirm_dialog.dart` 顶部加:

```dart
import '../../../shared/widgets/portrait_frame.dart';
```

- [ ] **Step 2: 在 _CandidateInfo 的 Column 顶部插 PortraitFrame**

`_CandidateInfo.build` 内 `Column(` 的 `children: [`(line 76)后、`Row(`(line 77)前插:

```dart
          if (candidate.portraitPath != null) ...[
            PortraitFrame(
              portraitPath: candidate.portraitPath,
              size: 96,
              borderColor: schoolColor,
            ),
            const SizedBox(height: 12),
          ],
```

> `schoolColor` 已在 `build` line 67-69 定义,作用域内可直接用。

- [ ] **Step 3: analyze 确认无错**

Run: `flutter analyze lib/features/encounter/presentation/sect_recruit_confirm_dialog.dart`
Expected: `No issues found!`。

- [ ] **Step 4: Commit**

```bash
git add lib/features/encounter/presentation/sect_recruit_confirm_dialog.dart
git commit -m "feat: sect_recruit 确认 dialog 接入 96x96 立绘"
```

---

### Task 6: 强制招募 debug 列表 portrait(40×40)

**Files:**
- Modify: `lib/features/debug/presentation/sect_recruit_debug_screen.dart`(import + list item Row)

- [ ] **Step 1: 加 import**

`lib/features/debug/presentation/sect_recruit_debug_screen.dart` 顶部加:

```dart
import '../../../shared/widgets/portrait_frame.dart';
```

- [ ] **Step 2: 把 person_add Icon 换成 PortraitFrame**

把 list item 内 `Icon(Icons.person_add, ...)`(line 98-100)整段替换为:

```dart
                                  PortraitFrame(
                                    portraitPath: c.portraitPath,
                                    size: 40,
                                    borderColor: c.school == null
                                        ? WuxiaColors.border
                                        : WuxiaColors.schoolColor(c.school!),
                                  ),
```

(后接的 `const SizedBox(width: 12),` line 101 保留。)

- [ ] **Step 3: analyze 确认无错**

Run: `flutter analyze lib/features/debug/presentation/sect_recruit_debug_screen.dart`
Expected: `No issues found!`(若 `Icons` 不再被引用且原 import 仅为它,删冗余 import;analyze 会提示 unused)。

- [ ] **Step 4: Commit**

```bash
git add lib/features/debug/presentation/sect_recruit_debug_screen.dart
git commit -m "feat: 强制招募 debug 列表接入 40x40 立绘缩略图"
```

---

### Task 7: L3 VISUAL_ROUTE + seedSectWithFullNpc

**Files:**
- Modify: `lib/features/debug/application/visual_route.dart`(加枚举)
- Modify: `lib/features/debug/application/phase2_seed_service.dart`(加 seedSectWithFullNpc)
- Modify: `lib/features/debug/presentation/visual_route_host.dart`(加 case)
- Test: `test/features/debug/visual_route_sect_test.dart`(新建)

- [ ] **Step 1: 写失败测试(parseVisualRoute + seed 语义)**

新建 `test/features/debug/visual_route_sect_test.dart`:

```dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/features/debug/application/phase2_seed_service.dart';
import 'package:wuxia_idle/features/debug/application/visual_route.dart';

// Isar setup 体例照搬 test/features/sect/sect_member_service_test.dart
void main() {
  test('parseVisualRoute 识别 sect_screen_npc', () {
    expect(parseVisualRoute('sect_screen_npc'), VisualRoute.sectScreenNpc);
  });

  group('seedSectWithFullNpc', () {
    late Directory tempDir;

    setUpAll(() async {
      await Isar.initializeIsarCore(download: true);
      if (!GameRepository.isLoaded) {
        await GameRepository.loadAllDefs(
          loader: (p) => File(p).readAsString(),
        );
      }
    });

    setUp(() async {
      tempDir =
          await Directory.systemTemp.createTemp('wuxia_sect_portrait_test_');
      await IsarSetup.init(directory: tempDir, inspector: false);
    });

    tearDown(() async {
      await IsarSetup.close();
      if (await tempDir.exists()) await tempDir.delete(recursive: true);
    });

    test('6 sect_candidate NPC 全 isInSect + portraitPath 非空,祖师有 portraitPath',
        () async {
      final isar = IsarSetup.instance;
      await Phase2SeedService(isar: isar).seedSectWithFullNpc();
      final all = await isar.characters.where().findAll();
      final npc = all.where((c) => c.isInSect && !c.isFounder).toList();
      expect(npc.length, greaterThanOrEqualTo(6));
      for (final c in npc) {
        expect(c.portraitPath, isNotNull, reason: '${c.name} 应有立绘');
      }
      final founder = all.firstWhere((c) => c.isFounder);
      expect(founder.portraitPath, isNotNull);
    });
  });
}
```

> dylib 见 Task 1 Step 5。`IsarSetup.init(directory:, inspector:)` + `IsarSetup.instance` + `IsarSetup.close()` 为既有 sect 测族标准体例。

- [ ] **Step 2: 跑测试确认失败**

Run: `flutter test test/features/debug/visual_route_sect_test.dart`
Expected: 编译失败 `sectScreenNpc isn't defined` / `seedSectWithFullNpc isn't defined`。

- [ ] **Step 3: 加 VisualRoute 枚举**

`lib/features/debug/application/visual_route.dart` — `techniquePanelHero(...)`(line 7)末分号改逗号,后加:

```dart
  techniquePanelHero('technique_panel_hero', '心法面板·主修 hero 打坐内丹态'),
  sectScreenNpc(
      'sect_screen_npc', 'sect_screen·成员立绘验收(祖师 + 6 sect_candidate 完整显)');
```

- [ ] **Step 4: 加 seedSectWithFullNpc**

`lib/features/debug/application/phase2_seed_service.dart` — 在 `seedVisualMasterAllTiers()` 方法(line 1090 闭合 `}`)后、class 闭合 `}`(line 1092)前加:

```dart
  /// L3 sect 立绘验收 seed:祖师(含弟子)+ 招满 6 sect_candidate 入派。
  ///
  /// 直接构造 NPC(sectId=1 + isInSect=true + portraitPath)绕开
  /// SectMemberService cap(sectLevel 1 cap=3 < 6),seed 确定性优先。
  /// 祖师 sectId=1 使其在成员列表呈现(member 列表按 sectIdEqualTo 过滤)。
  Future<void> seedSectWithFullNpc() async {
    final isar = this.isar;
    final repo = GameRepository.instance;
    final now = DateTime(2026, 5, 31);

    // 1. 祖师 + 2 弟子(ensureFoundingMasters · founder id=1,带 portraitPath)
    await OnboardingService(isar: isar).ensureFoundingMasters();

    await isar.writeTxn(() async {
      // 2. Sect lazy-init(沿 runSectRecruitFlow 体例 · sectLevel 3 让 cap 充裕)
      final sect = await isar.sects.get(1) ??
          (Sect()
            ..id = 1
            ..name = '无名宗'
            ..founderId = 1
            ..sectReputation = 50
            ..totalWins = 0
            ..createdAt = now
            ..lastEventAt = null);
      sect.sectLevel = 3;

      // 3. 祖师入派(sectId=1 使其进成员列表)
      final founder = await isar.characters.get(1);
      if (founder != null) {
        founder
          ..isInSect = true
          ..sectId = 1
          ..sectRank = SectRank.elder;
        await isar.characters.put(founder);
      }

      // 4. 6 sect_candidate 直接构造入派(带 portraitPath)
      final candidates = repo.sectCandidates.values.toList();
      var count = 0;
      for (final c in candidates) {
        final realmDef = repo.getRealm(c.defaultRealm, c.defaultLayer);
        final npc = Character.create(
          name: c.name,
          realmTier: c.defaultRealm,
          realmLayer: c.defaultLayer,
          attributes: Attributes()
            ..constitution = c.attributeProfile.constitution
            ..enlightenment = c.attributeProfile.enlightenment
            ..agility = c.attributeProfile.agility
            ..fortune = c.attributeProfile.fortune,
          rarity: RarityTier.biaoZhun,
          lineageRole: LineageRole.disciple,
          isFounder: false,
          isActive: false,
          createdAt: now,
          school: c.school,
          internalForce: realmDef.internalForceMax,
          internalForceMax: realmDef.internalForceMax,
          experienceToNextLayer: realmDef.experienceToNext,
          isInSect: true,
          sectId: 1,
          sectRank: SectRank.initiate,
          portraitPath: c.portraitPath,
        );
        await isar.characters.put(npc);
        count++;
      }
      sect.memberCount = count;
      await isar.sects.put(sect);
    });
  }
```

确认 `phase2_seed_service.dart` 顶部已 import:`Sect`(`../../sect/domain/sect.dart`)、`SectRank`(`../../sect/domain/sect_rank.dart`)、`OnboardingService`、`Attributes`/`Character`/`enums`、`RealmTier` 等。缺则补 import(analyze 会报)。

- [ ] **Step 5: 加 visual_route_host case**

`lib/features/debug/presentation/visual_route_host.dart` — 先加 import:

```dart
import '../../sect/presentation/sect_screen.dart';
```

在 `switch (widget.route)` 的 `case VisualRoute.techniquePanelHero:` 块(line 72-74)后加:

```dart
        case VisualRoute.sectScreenNpc:
          await Phase2SeedService(isar: isar).seedSectWithFullNpc();
          target = const SectScreen();
```

- [ ] **Step 6: 跑测试确认通过**

```bash
[ -f libisar.dylib ] || cp ~/Desktop/Projects/挂机武侠/libisar.dylib ./ 2>/dev/null || true
flutter test test/features/debug/visual_route_sect_test.dart
```
Expected: PASS(parse + seed 语义断言全过)。

- [ ] **Step 7: Commit**

```bash
git add lib/features/debug/application/visual_route.dart lib/features/debug/application/phase2_seed_service.dart lib/features/debug/presentation/visual_route_host.dart test/features/debug/visual_route_sect_test.dart
git commit -m "feat: VISUAL_ROUTE sect_screen_npc + seedSectWithFullNpc 立绘验收 route"
```

---

### Task 8: 全量 baseline 验收

**Files:** 无(只跑验证)

- [ ] **Step 1: flutter analyze 全量**

Run: `flutter analyze`
Expected: `No issues found!`(0 analyze)。有 unused import 等则修。

- [ ] **Step 2: 全量测试**

Run: `flutter test 2>&1 | tail -15`
Expected: All tests passed。基线 1620 + 本计划新增(Task1 +1 / Task2 +2 / Task3 +1 / Task7 +2 ≈ +6)→ ~1626 测,0 fail。实际新增数以测试文件 test() 计数为准(不写死期望,memory `feedback_nightshift_verify_count_baseline`)。

- [ ] **Step 3: L3 就绪信号自验(可选 · Mac 本地)**

Run: `flutter run -d macos --dart-define=VISUAL_ROUTE=sect_screen_npc`(等 `VISUAL_ROUTE_READY: sect_screen_npc` 日志,Ctrl-C 退)
Expected: 日志出现 `VISUAL_ROUTE_READY: sect_screen_npc`,无 `VISUAL_ROUTE_ERROR`。截图复验派 Codex。

- [ ] **Step 4: 无新增 commit(本 task 仅验证)**

若 Step 1/2 有修复,单独 commit:`git commit -m "fix: 立绘 wiring 全量 analyze/test 收尾"`。

---

## 验收对照(spec)

| spec 改动点 | 实现 task |
|---|---|
| ① Schema(Character.portraitPath + Isar 0.15) | Task 1 |
| ② 立绘写入(buildMasterCharacter + runSectRecruitFlow) | Task 3 |
| ③ sect_screen 成员行 48×48 | Task 4(经 Task 2 PortraitFrame) |
| ④ dialog 96×96 | Task 5(经 Task 2) |
| ⑤ debug 列表 40×40 | Task 6(经 Task 2) |
| ⑥ L3 VISUAL_ROUTE + seed | Task 7 |
| 测试(透传/widget/seed 语义/baseline) | Task 1/2/3/7/8 |

## 偏离 spec 记录

- **新增 `PortraitFrame` 共享 widget**(spec render 体例为内联块):3 个新渲染位本会产生 3 份相同 Container+Image.asset+errorBuilder,抽 1 个共享 widget 消重 + 可单测。只用于新代码,不动既有 lineage/recruitment 内联体例。
