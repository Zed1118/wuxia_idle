# 门派谱 1.1（传承族谱档案）Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: superpowers:subagent-driven-development。逐 task 实装，checkbox 跟踪。
> spec: `docs/spec/2026-06-21-p4-lineage-codex-design.md`。姊妹参照体例：`lib/features/weapon_codex/`（兵器谱，收集图鉴 + VISUAL_ROUTE 全程照体例）。

**Goal:** 把现有「门派谱功能面板」升级成纵向世代卷的「传承族谱档案」——历代祖师/门人/师承遗物按代分段，点角色卡进角色详情屏，屏底保留飞升入口；补齐与战绩册/兵器谱对称的 VISUAL_ROUTE。

**Architecture:** 纯展示层。新增派生 provider `lineageCodexProvider`（查全部 Character 按 `isFounder` 分代）+ `LineageGeneration` 视图模型。原地重写 `lineage_panel_screen.dart` 为世代卷；新建 `lineage_character_detail_screen.dart`。**零新 Isar collection、零 saveVer bump、零迁移**（全派生现有 Character/Equipment/SaveData 字段）。飞升逻辑复用现有 `AscendService`/`AscensionScreen` 零改动。

**Tech Stack:** Flutter + Riverpod codegen(@riverpod) + Isar(只读查询)。TDD：派生 provider 用 `test()`（非 testWidgets，防 Isar 死锁）；UI 用 `testWidgets`。

---

## Phase 0 已确认事实（开工前读，无需重查）

**数据字段**（均现存，零改动）：
- `Character`（`lib/core/domain/character.dart`）：`isFounder`(bool, :92)、`isActive`(bool, :81)、`lineageRole`(LineageRole, :90)、`masterId`(int?, :86)、`discipleIds`(List<int>)、`realmTier`/`realmLayer`、`school`(TechniqueSchool?)、`mainTechniqueId`(int?)、`portraitPath`(String?)、`birthInGameYear`(int, :94)、`createdAt`(DateTime, :119)、`attributes`(Attributes embedded)。
- `Attributes`（`lib/core/domain/attributes.dart:11-14`）：`constitution`/`enlightenment`/`agility`/`fortune`（根骨/悟性/身法/机缘，**无「力/灵」**）。
- `Equipment`：`isLineageHeritage`(bool)、`ownerCharacterId`(int?)、`previousOwnerCharacterIds`(List<int>)、`tier`、`defId`、`enhanceLevel`。
- `LineageRole`(`lib/core/domain/enums.dart:163-169`)：`founder/disciple/senior/junior/grandDisciple`（5 值）。
- `SaveData.founderCharacterId`(int?)、`SaveData.recruitedDiscipleIds`(List<int>)、`SaveData.activeCharacterIds`(List<int>)。

**现成 API**：
- `EnumL10n.realm(realmTier, realmLayer)` / `EnumL10n.school(s)`（`enum_localizations.dart`）。`EnumL10n.lineageRole(...)` **不存在**→ Task 2 新增。
- `GameRepository.instance.techniqueDefs[id]?.name`（主修心法名）；`GameRepository.instance.stageDefs[id]?.name`（关卡名）；`GameRepository.instance.numbers.lineageOnboarding.discipleJoins`(List<DiscipleJoinDef>，字段 `stageId`/`role`/`masterSlotIndex`)；`GameRepository.isLoaded` 守卫。
- `GameRepository.instance.numbers.founderAncestorBuff`（`isActive`/`internalForceMaxPct`/`maxHpPct`/`critRateBonus`）。
- `tierColorForEquipment(tier)`（`shared/theme/tier_colors.dart`）；`WuxiaColors`（`shared/theme/colors.dart`）。
- 飞升入口：`ascensionEligibilityProvider`（`ascension/application/ascend_service_providers.dart`）+ `AscensionScreen`。
- 现有 `lineageInfoProvider`（`character_panel/application/lineage_info_provider.dart`）只看 active+recruited，**不查历代**；当代弟子源 = active 非 founder ∪ (recruitedDiscipleIds ∖ active)。新 provider 沿用这两源保当代零回归。

**红线/约束**：纯展示零数值改动（§5.4/§5.1）；文案全进 UiStrings/EnumL10n（§5.6）；离线无关（§5.5）；无教程弹窗（§5.7）。
- `.g.dart` gitignored，Task 1 新 `@riverpod` 后**必跑 build_runner**。
- fresh worktree 先拷 libisar.dylib + build_runner（memory `feedback_fresh_worktree_libisar_dylib`）。

---

## File Structure

| 文件 | 职责 |
|------|------|
| `lib/features/character_panel/application/lineage_codex_provider.dart`（新建） | `LineageGeneration` 模型 + `lineageCodexProvider`（查全部 Character 按 isFounder 分代 + 遗物分代 + 进度）|
| `lib/features/character_panel/presentation/lineage_panel_screen.dart`（重写） | 主屏世代卷（进度头 + per-代段 + 屏底飞升入口）|
| `lib/features/character_panel/presentation/lineage_character_detail_screen.dart`（新建） | 角色详情屏（祖师/弟子共用两态）|
| `lib/features/battle/domain/enum_localizations.dart`（改） | 新增 `EnumL10n.lineageRole` |
| `lib/shared/strings.dart`（改） | UiStrings 门派谱/详情屏/世代卷文案词条 |
| `lib/features/debug/application/visual_route.dart`（改） | 新增 `lineageCodex`/`lineageCharacterDetail` 枚举 |
| `lib/features/debug/presentation/visual_route_host.dart`（改） | buildVisualTarget 双 case + seed builder |
| `test/features/character_panel/lineage_codex_provider_test.dart`（新建） | 分代派生纯逻辑测 |
| `test/features/character_panel/lineage_panel_screen_test.dart`（新建/改） | 主屏 widget 测 |
| `test/features/character_panel/lineage_character_detail_screen_test.dart`（新建） | 详情屏 widget 测 |
| `test/features/debug/visual_route_test.dart`（改） | 双路由 parse 往返测 |

---

## Task 1: 分代派生 — LineageGeneration 模型 + lineageCodexProvider

**Files:**
- Create: `lib/features/character_panel/application/lineage_codex_provider.dart`
- Test: `test/features/character_panel/lineage_codex_provider_test.dart`

设计：分代为纯函数 `groupGenerations(...)`（可单测），provider 是薄壳拉数据后调它。

- [ ] **Step 1: 写失败测**（用 `test()` 非 testWidgets；构造内存 Character/Equipment list 直接喂纯函数）

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/domain/equipment.dart';
import 'package:wuxia_idle/features/character_panel/application/lineage_codex_provider.dart';

Character _c(int id, {bool founder = false, int? master, LineageRole role = LineageRole.disciple}) =>
    Character(name: 'c$id', realmTier: RealmTier.santliu, lineageRole: role)
      ..id = id
      ..isFounder = founder
      ..masterId = master;

void main() {
  group('groupGenerations', () {
    test('单代：1 祖师 + 2 弟子(masterId 指向祖师)', () {
      final chars = [_c(1, founder: true, role: LineageRole.founder), _c(2, master: 1, role: LineageRole.senior), _c(3, master: 1, role: LineageRole.junior)];
      final gens = groupGenerations(characters: chars, heritage: const [], currentFounderId: 1, activeIds: const [1, 2, 3], recruitedIds: const []);
      expect(gens.length, 1);
      expect(gens[0].founder.id, 1);
      expect(gens[0].disciples.map((c) => c.id), [2, 3]);
      expect(gens[0].isCurrent, true);
    });

    test('多代：按 founder id 升序，太祖在前', () {
      final chars = [_c(1, founder: true, role: LineageRole.founder), _c(2, founder: true, master: 1, role: LineageRole.senior)];
      final gens = groupGenerations(characters: chars, heritage: const [], currentFounderId: 2, activeIds: const [2], recruitedIds: const []);
      expect(gens.map((g) => g.founder.id), [1, 2]);
      expect(gens[1].isCurrent, true);
    });

    test('当代弟子兜底走 active∪recruited(masterId 为空也不漏)', () {
      final chars = [_c(1, founder: true, role: LineageRole.founder), _c(2, master: null, role: LineageRole.senior)];
      final gens = groupGenerations(characters: chars, heritage: const [], currentFounderId: 1, activeIds: const [1, 2], recruitedIds: const []);
      expect(gens[0].disciples.map((c) => c.id), contains(2));
    });

    test('遗物按 owner 归代，背包(null owner)归当代', () {
      final chars = [_c(1, founder: true, role: LineageRole.founder)];
      final relic = Equipment()..id = 9..isLineageHeritage = true..ownerCharacterId = null..tier = EquipmentTier.xunChangHuo;
      final gens = groupGenerations(characters: chars, heritage: [relic], currentFounderId: 1, activeIds: const [1], recruitedIds: const []);
      expect(gens[0].heritageEquipments.map((e) => e.id), [9]);
    });
  });
}
```

- [ ] **Step 2: 跑测确认 FAIL**

Run: `flutter test test/features/character_panel/lineage_codex_provider_test.dart`
Expected: 编译失败（`groupGenerations`/`LineageGeneration` 未定义）。

- [ ] **Step 3: 实装模型 + 纯函数 + provider**

```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/application/character_providers.dart';
import '../../../core/application/inventory_providers.dart';
import '../../../core/domain/character.dart';
import '../../../core/domain/equipment.dart';
import '../../../data/isar_provider.dart';
import '../../../data/save_providers.dart';
import '../../recruitment/application/recruitment_providers.dart';

part 'lineage_codex_provider.g.dart';

/// 门派谱·一代传承（祖师 + 该代门人 + 该代师承遗物）。纯派生视图模型。
class LineageGeneration {
  const LineageGeneration({
    required this.founder,
    required this.disciples,
    required this.heritageEquipments,
    required this.isCurrent,
  });

  final Character founder;
  final List<Character> disciples;
  final List<Equipment> heritageEquipments;

  /// 当代标识：founder.id == SaveData.founderCharacterId。
  final bool isCurrent;
}

/// 分代纯函数（可单测，不碰 isar）。
///
/// - 代锚点 = `isFounder==true` 的角色，按 `id` 升序（太祖在前）。
/// - 每代弟子 = `masterId == founder.id` 的非 founder 角色；
///   **当代额外并入 active 非 founder ∪ recruited**（沿现有 lineageInfoProvider
///   信任源，保当代零回归，即便生产 masterId 未填也不漏）。去重按 id。
/// - 遗物按 `ownerCharacterId` 归对应代；null owner（背包）归当代。
List<LineageGeneration> groupGenerations({
  required List<Character> characters,
  required List<Equipment> heritage,
  required int? currentFounderId,
  required List<int> activeIds,
  required List<int> recruitedIds,
}) {
  final founders = characters.where((c) => c.isFounder).toList()
    ..sort((a, b) => a.id.compareTo(b.id));
  if (founders.isEmpty) return const [];

  final byId = {for (final c in characters) c.id: c};
  final founderIds = founders.map((f) => f.id).toSet();
  final activeSet = activeIds.toSet();

  final gens = <LineageGeneration>[];
  for (final f in founders) {
    final isCurrent = currentFounderId != null && f.id == currentFounderId;

    // 弟子：masterId 指向本代祖师的非 founder
    final ids = <int>{
      for (final c in characters)
        if (!c.isFounder && c.masterId == f.id) c.id,
    };
    if (isCurrent) {
      // 当代兜底：active 非 founder ∪ recruited（去 founder 自身）
      for (final id in activeSet) {
        final c = byId[id];
        if (c != null && !c.isFounder) ids.add(id);
      }
      for (final id in recruitedIds) {
        final c = byId[id];
        if (c != null && !c.isFounder) ids.add(id);
      }
    }
    final disciples = ids.map((id) => byId[id]).whereType<Character>().toList()
      ..sort((a, b) => a.id.compareTo(b.id));

    // 遗物：owner 属本代角色集合
    final genCharIds = {f.id, ...disciples.map((c) => c.id)};
    final relics = heritage.where((e) {
      final owner = e.ownerCharacterId;
      if (owner == null) return isCurrent; // 背包遗物归当代
      if (genCharIds.contains(owner)) return true;
      // owner 不属任何 founder 代且非当代 → 不重复挂（兜底归当代）
      if (!founderIds.contains(owner) && isCurrent) {
        return !characters.any((c) => c.id == owner);
      }
      return false;
    }).toList();

    gens.add(LineageGeneration(
      founder: f,
      disciples: disciples,
      heritageEquipments: relics,
      isCurrent: isCurrent,
    ));
  }
  return gens;
}

/// 门派谱世代卷派生 provider。拉全部 Character（含历代退隐祖师）+ 全部师承遗物，
/// 调 [groupGenerations] 分代。上游 invalidate 自动刷新。
@riverpod
Future<List<LineageGeneration>> lineageCodex(Ref ref) async {
  final isar = ref.watch(isarProvider);
  if (isar == null) return const [];
  final characters = await isar.characters.where().findAll();
  final allEquipments = await ref.watch(allEquipmentsProvider.future);
  final heritage =
      allEquipments.where((e) => e.isLineageHeritage).toList(growable: false);
  final save = await ref.watch(currentSaveDataProvider.future);
  return groupGenerations(
    characters: characters,
    heritage: heritage,
    currentFounderId: save?.founderCharacterId,
    activeIds: save?.activeCharacterIds ?? const [],
    recruitedIds: await ref.watch(recruitedDiscipleIdsProvider.future),
  );
}
```

> 注：`currentSaveDataProvider` / `save_providers.dart` 路径以实际为准——实装前 grep `founderCharacterId` 的 provider 来源（`grep -rn "founderCharacterId" lib/core lib/data`），用其既有读取 provider；若无现成则在 provider 内 `isar` 直接读 save。`isar.characters.where().findAll()` 拉全角色（Demo 量级小，无性能顾虑）。

- [ ] **Step 4: 跑 build_runner**

Run: `dart run build_runner build --delete-conflicting-outputs 2>&1 | tail -3`
Expected: `Succeeded`，生成 `lineage_codex_provider.g.dart`。

- [ ] **Step 5: 跑测确认 PASS + analyze**

Run: `flutter test test/features/character_panel/lineage_codex_provider_test.dart && flutter analyze lib/features/character_panel/application/lineage_codex_provider.dart`
Expected: 全 PASS，analyze 0。

- [ ] **Step 6: 提交**

```bash
git add lib/features/character_panel/application/lineage_codex_provider.dart test/features/character_panel/lineage_codex_provider_test.dart
git commit -m "feat: 门派谱1.1 Task1 分代派生 lineageCodexProvider + groupGenerations 纯函数"
```

---

## Task 2: 文案 — EnumL10n.lineageRole + UiStrings 词条

**Files:**
- Modify: `lib/features/battle/domain/enum_localizations.dart`
- Modify: `lib/shared/strings.dart`
- Test: `test/features/character_panel/lineage_codex_l10n_test.dart`（新建，小）

- [ ] **Step 1: 写失败测**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/features/battle/domain/enum_localizations.dart';
import 'package:wuxia_idle/shared/strings.dart';

void main() {
  test('lineageRole 穷尽 5 值且非空', () {
    for (final r in LineageRole.values) {
      expect(EnumL10n.lineageRole(r).isNotEmpty, true);
    }
    expect(EnumL10n.lineageRole(LineageRole.founder), '祖师');
    expect(EnumL10n.lineageRole(LineageRole.senior), '大弟子');
  });

  test('世代卷文案词条存在', () {
    expect(UiStrings.lineageCodexTitle.isNotEmpty, true);
    expect(UiStrings.lineageCodexGenerationLabel(1), contains('代'));
    expect(UiStrings.lineageCodexProgress(2, 3).isNotEmpty, true);
  });
}
```

- [ ] **Step 2: 跑测确认 FAIL**

Run: `flutter test test/features/character_panel/lineage_codex_l10n_test.dart`
Expected: 编译失败（成员未定义）。

- [ ] **Step 3: 加 EnumL10n.lineageRole**（`enum_localizations.dart`，沿 `school(...)` switch 体例）

```dart
/// 师徒身份（GDD §7.1）。switch 穷尽，增删 enum 值编译期报漏。
static String lineageRole(LineageRole r) {
  return switch (r) {
    LineageRole.founder => '祖师',
    LineageRole.senior => '大弟子',
    LineageRole.junior => '二弟子',
    LineageRole.disciple => '弟子',
    LineageRole.grandDisciple => '徒孙',
  };
}
```

- [ ] **Step 4: 加 UiStrings 词条**（`strings.dart`，沿 `lineagePanel*` 体例；下列为最小集，主屏/详情屏实装时按需补，新增一律进此处不内联）

```dart
// 门派谱世代卷（1.1）
static const String lineageCodexTitle = '门派谱';
static String lineageCodexGenerationLabel(int gen) =>
    gen == 1 ? '第一代 · 太祖' : '第 $gen 代';
static const String lineageCodexCurrentTag = '当代';
static const String lineageCodexRetiredTag = '已退隐';
static String lineageCodexProgress(int gens, int members) =>
    '传承 $gens 代 · 门人 $members 人';
static const String lineageCodexNoDisciples = '孤身一人，传承待续';
static const String lineageCodexNoHeritage = '尚无师承遗物';
static const String lineageCodexHeritageSection = '师承遗物';
static const String lineageCodexDiscipleSection = '门人';
// 角色详情屏
static const String lineageCharacterDetailTitle = '门人档案';
static const String lineageCharacterDetailDeeds = '纪事';
static const String lineageCharacterDetailAttributes = '资质';
static const String lineageCharacterDetailMainTechnique = '主修';
static const String lineageCharacterDetailHeritage = '所持师承遗物';
static const String lineageCharacterDetailFounderBuff = '祖师恩泽';
static String lineageCharacterDetailJoinedAt(int year, String stage) =>
    '江湖 $year 年，过「$stage」拜入';
static String lineageCharacterDetailFounderGen(int gen) =>
    gen == 1 ? '开派太祖' : '第 $gen 代掌门';
```

- [ ] **Step 5: 跑测确认 PASS + analyze**

Run: `flutter test test/features/character_panel/lineage_codex_l10n_test.dart && flutter analyze lib/shared/strings.dart lib/features/battle/domain/enum_localizations.dart`
Expected: PASS，analyze 0。

- [ ] **Step 6: 提交**

```bash
git add lib/features/battle/domain/enum_localizations.dart lib/shared/strings.dart test/features/character_panel/lineage_codex_l10n_test.dart
git commit -m "feat: 门派谱1.1 Task2 EnumL10n.lineageRole + 世代卷/详情屏 UiStrings 词条"
```

---

## Task 3: 角色详情屏 lineage_character_detail_screen

**Files:**
- Create: `lib/features/character_panel/presentation/lineage_character_detail_screen.dart`
- Test: `test/features/character_panel/lineage_character_detail_screen_test.dart`

构造签名：`const LineageCharacterDetailScreen({required this.character})`（直传 Character；遗物/纪事在屏内派生）。祖师/弟子共用，靠 `character.isFounder` 分支「祖师恩泽」「纪事」两态。

- [ ] **Step 1: 写失败 widget 测**（testWidgets；pump 祖师态 + 弟子态，断言关键文案/区块）

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/features/character_panel/presentation/lineage_character_detail_screen.dart';
import 'package:wuxia_idle/shared/strings.dart';

Character _founder() => Character(name: '林青', realmTier: RealmTier.wuSheng, lineageRole: LineageRole.founder)
  ..id = 1..isFounder = true..birthInGameYear = 1..realmLayer = RealmLayer.dengFeng;
Character _disciple() => Character(name: '叶清', realmTier: RealmTier.santliu, lineageRole: LineageRole.senior)
  ..id = 2..birthInGameYear = 5;

void main() {
  testWidgets('祖师态显祖师恩泽 + 身份「祖师」', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(ProviderScope(
      child: MaterialApp(home: LineageCharacterDetailScreen(character: _founder())),
    ));
    await tester.pumpAndSettle();
    expect(find.text('林青'), findsOneWidget);
    expect(find.text(UiStrings.lineageCharacterDetailFounderBuff), findsWidgets);
  });

  testWidgets('弟子态不显祖师恩泽', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(ProviderScope(
      child: MaterialApp(home: LineageCharacterDetailScreen(character: _disciple())),
    ));
    await tester.pumpAndSettle();
    expect(find.text('叶清'), findsOneWidget);
    expect(find.text(UiStrings.lineageCharacterDetailFounderBuff), findsNothing);
  });
}
```

- [ ] **Step 2: 跑测确认 FAIL**

Run: `flutter test test/features/character_panel/lineage_character_detail_screen_test.dart`
Expected: 编译失败（screen 未定义）。

- [ ] **Step 3: 实装详情屏**

要点（照 `equipment_catalog_detail_screen.dart` + 现有 `_CharacterChip`/`_FounderBuffSection`/`_HeritageRow` 体例）：
- `ConsumerWidget`，`Scaffold` + AppBar title=`UiStrings.lineageCharacterDetailTitle`，背景 `WuxiaColors.background`，`SingleChildScrollView`。
- 顶部 hero：立绘 80×80（`Image.asset(character.portraitPath!, errorBuilder: (_, _, _) => Container(color: WuxiaColors.avatarFill))`，null path 走 school 色竖条 fallback）+ 名号 + `EnumL10n.lineageRole(character.lineageRole)` + `EnumL10n.realm(...)`。
- 纪事区（`lineageCharacterDetailDeeds`）：
  - 祖师：`lineageCharacterDetailFounderGen(genIndex)`（gen index 暂用 1，多代由调用方未来透传；当代恒显「开派太祖」对单代正确）。
  - 弟子：反查 `discipleJoins.firstWhere((j) => j.role == character.lineageRole, orElse: ...)` 取 stageId → `stageDefs[id]?.name`，配 `birthInGameYear` 拼 `lineageCharacterDetailJoinedAt(year, stage)`；查不到来源则只显「江湖 N 年」（不臆造）。
- 资质区（`lineageCharacterDetailAttributes`）：`character.attributes` 四项，沿 `'${UiStrings.attrConstitution} ${a.constitution}'` 体例（attrConstitution/attrEnlightenment/attrAgility/attrFortune 已存在）。
- 主修区：`GameRepository.instance.techniqueDefs[character.mainTechniqueId]?.name`（null/未加载兜底略过该行）。
- 所持师承遗物区（`lineageCharacterDetailHeritage`）：watch `allEquipmentsProvider`，过滤 `isLineageHeritage && ownerCharacterId == character.id`，复用 `_HeritageRow` 同款行（名 + tier 色点 + 传 N 代 chip，N = previousOwnerCharacterIds.length + 1，仅 len>1 显）。空则略过区块。
- 祖师恩泽区（仅 `character.isFounder` 且 `founderAncestorBuff.isActive`）：复用现有 `_FounderBuffSection` 三行（internalForceMaxPct/maxHpPct/critRateBonus），文案 `lineageCharacterDetailFounderBuff`。
- 守约束：所有 `Image.asset` 带 errorBuilder；唯一色源 tier/ school 既有；零中文内联（全 UiStrings/EnumL10n）。

- [ ] **Step 4: 跑测确认 PASS + 全项目 analyze**

Run: `flutter test test/features/character_panel/lineage_character_detail_screen_test.dart && flutter analyze`
Expected: PASS，analyze 0（全项目，非仅本文件——防跨文件签名回归，memory `feedback_subagent_implementer_full_analyze`）。

- [ ] **Step 5: 提交**

```bash
git add lib/features/character_panel/presentation/lineage_character_detail_screen.dart test/features/character_panel/lineage_character_detail_screen_test.dart
git commit -m "feat: 门派谱1.1 Task3 角色详情屏(祖师/弟子两态)"
```

---

## Task 4: 主屏世代卷 — 重写 lineage_panel_screen

**Files:**
- Modify (重写 body): `lib/features/character_panel/presentation/lineage_panel_screen.dart`
- Test: `test/features/character_panel/lineage_panel_screen_test.dart`

保留：`LineagePanelScreen` 类名/BgmScope/AppBar/`_AscensionSection`（屏底）/`_FounderBuffSection`/`_HeritageRow`/`_PanelCard`/`_SectionTitle`/`_CharacterChip`（卡片加 onTap → push 详情屏）。
改：`_Body` 改 watch `lineageCodexProvider`，渲染进度头 + per-代 `_GenerationSection`（代标题条 + 祖师卡 + 门人卡 + 该代遗物行），末尾 `_AscensionSection`。

- [ ] **Step 1: 写失败 widget 测**（override `lineageCodexProvider` 喂 1 代/空门人；断言进度头 + 代标题 + 点祖师卡进详情屏）

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/features/character_panel/application/lineage_codex_provider.dart';
import 'package:wuxia_idle/features/character_panel/presentation/lineage_panel_screen.dart';
import 'package:wuxia_idle/features/character_panel/presentation/lineage_character_detail_screen.dart';
import 'package:wuxia_idle/shared/strings.dart';

Character _f() => Character(name: '林青', realmTier: RealmTier.wuSheng, lineageRole: LineageRole.founder)
  ..id = 1..isFounder = true..realmLayer = RealmLayer.dengFeng;

void main() {
  testWidgets('单代渲染进度头 + 代标题 + 祖师卡', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final gen = LineageGeneration(founder: _f(), disciples: const [], heritageEquipments: const [], isCurrent: true);
    await tester.pumpWidget(ProviderScope(
      overrides: [lineageCodexProvider.overrideWith((ref) async => [gen])],
      child: const MaterialApp(home: LineagePanelScreen()),
    ));
    await tester.pumpAndSettle();
    expect(find.text(UiStrings.lineageCodexProgress(1, 0)), findsOneWidget);
    expect(find.text(UiStrings.lineageCodexGenerationLabel(1)), findsWidgets);
    expect(find.text('林青'), findsOneWidget);
  });

  testWidgets('点祖师卡 push 角色详情屏', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final gen = LineageGeneration(founder: _f(), disciples: const [], heritageEquipments: const [], isCurrent: true);
    await tester.pumpWidget(ProviderScope(
      overrides: [lineageCodexProvider.overrideWith((ref) async => [gen])],
      child: const MaterialApp(home: LineagePanelScreen()),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.text('林青'));
    await tester.pumpAndSettle();
    expect(find.byType(LineageCharacterDetailScreen), findsOneWidget);
  });
}
```

- [ ] **Step 2: 跑测确认 FAIL**

Run: `flutter test test/features/character_panel/lineage_panel_screen_test.dart`
Expected: FAIL（进度头/代标题未渲染，或点击无导航）。

- [ ] **Step 3: 重写 _Body + 新增 _GenerationSection**

要点：
- `_Body` 接 `List<LineageGeneration> gens`：
  - 顶部 scroll 装饰图保留（`scroll_vertical.png` + errorBuilder）。
  - 进度头：`UiStrings.lineageCodexProgress(gens.length, gens.fold(0, (n, g) => n + g.disciples.length))`。
  - `for (final g in gens) _GenerationSection(gen: g)`（多代时自上而下；空 gens 显空态 `_EmptyText`）。
  - 末尾 `const _AscensionSection()`（屏底飞升入口，逻辑不动）。
- `_GenerationSection`（新 `_PanelCard`）：
  - 代标题条：`_SectionTitle(lineageCodexGenerationLabel(genIndex))` + 当代/退隐 tag（`isCurrent ? lineageCodexCurrentTag : lineageCodexRetiredTag`；退隐判定 `!founder.isActive`）。genIndex = gens 中下标 + 1。
  - 祖师卡：`_CharacterChip(character: gen.founder, ...)` 包 `GestureDetector`/`InkWell` onTap → `Navigator.push(MaterialPageRoute(builder: (_) => LineageCharacterDetailScreen(character: gen.founder)))`。
  - 门人区：`lineageCodexDiscipleSection`；空 → `_EmptyText(lineageCodexNoDisciples)`；否则逐个 `_CharacterChip` + onTap push 详情。
  - 遗物区：`lineageCodexHeritageSection`；空 → `_EmptyText(lineageCodexNoHeritage)`；否则逐个 `_HeritageRow`。
- `_CharacterChip` 加可选 `onTap`（包 InkWell/GestureDetector），不破现有无参调用。
- 删除现已无引用的 `_FounderSection`/`_DisciplesSection`/`_InactiveDisciplesSection`/`_HeritageSection`（被 `_GenerationSection` 取代）；`_portraitForSlot` 若不再用则删。grep 确认 `lineageInfoProvider` 是否还有别处引用：`grep -rn "lineageInfoProvider\|LineageInfo" lib test`——仅本屏用则可留（不强删，避免连带），但本屏不再 watch 它。

- [ ] **Step 4: 跑测确认 PASS + 全项目 analyze + 全量回归**

Run: `flutter test test/features/character_panel/ && flutter analyze`
Expected: PASS，analyze 0。再跑全量 `flutter test`（基线对比，零回归）。

- [ ] **Step 5: 提交**

```bash
git add lib/features/character_panel/presentation/lineage_panel_screen.dart test/features/character_panel/lineage_panel_screen_test.dart
git commit -m "feat: 门派谱1.1 Task4 主屏世代卷重写(进度头+per-代段+屏底飞升入口+点卡进详情)"
```

---

## Task 5: VISUAL_ROUTE 双路由 — lineage_codex + lineage_character_detail

**Files:**
- Modify: `lib/features/debug/application/visual_route.dart`
- Modify: `lib/features/debug/presentation/visual_route_host.dart`
- Test: `test/features/debug/visual_route_test.dart`

- [ ] **Step 1: 加 parse 往返断言**（沿现有「已知 id → 枚举」测体例追加）

```dart
expect(parseVisualRoute('lineage_codex'), VisualRoute.lineageCodex);
expect(parseVisualRoute('lineage_character_detail'), VisualRoute.lineageCharacterDetail);
```

- [ ] **Step 2: 跑测确认 FAIL**

Run: `flutter test test/features/debug/visual_route_test.dart`
Expected: FAIL（枚举未定义）。

- [ ] **Step 3: 加枚举值**（`visual_route.dart`，沿 `weaponCodex` 体例）

```dart
lineageCodex(
  'lineage_codex',
  '门派谱主屏目检·世代卷(进度头 + 祖师卡 + 门人 + 师承遗物 + 屏底飞升入口)',
),
lineageCharacterDetail(
  'lineage_character_detail',
  '门派谱角色详情屏目检·祖师态(纪事 + 资质四项 + 主修 + 所持遗物 + 祖师恩泽)',
),
```

- [ ] **Step 4: 加 host case + seed builder**（`visual_route_host.dart`，沿 `_buildWeaponCodex*Visual` 体例）

```dart
case VisualRoute.lineageCodex:
  return _buildLineageCodexVisual();
case VisualRoute.lineageCharacterDetail:
  return _buildLineageCharacterDetailVisual();
```

```dart
Widget _buildLineageCodexVisual() {
  // 单代 seed：祖师 + 2 门人 + 1 件师承遗物，验世代卷常态。
  final founder = Character(name: '林青崖', realmTier: RealmTier.wuSheng, lineageRole: LineageRole.founder)
    ..id = 1..isFounder = true..isActive = true..realmLayer = RealmLayer.dengFeng..portraitPath = null;
  final d1 = Character(name: '叶清', realmTier: RealmTier.yiLiu, lineageRole: LineageRole.senior)..id = 2..isActive = true;
  final d2 = Character(name: '陆沉', realmTier: RealmTier.erLiu, lineageRole: LineageRole.junior)..id = 3..isActive = true;
  final relic = Equipment()..id = 9..isLineageHeritage = true..ownerCharacterId = 1..tier = EquipmentTier.baoWu..defId = (GameRepository.isLoaded ? GameRepository.instance.equipmentDefs.values.first.id : 'x')..previousOwnerCharacterIds = [0, 1];
  final gen = LineageGeneration(founder: founder, disciples: [d1, d2], heritageEquipments: [relic], isCurrent: true);
  return ProviderScope(
    overrides: [lineageCodexProvider.overrideWith((ref) async => [gen])],
    child: const LineagePanelScreen(),
  );
}

Widget _buildLineageCharacterDetailVisual() {
  final founder = Character(name: '林青崖', realmTier: RealmTier.wuSheng, lineageRole: LineageRole.founder)
    ..id = 1..isFounder = true..isActive = true..realmLayer = RealmLayer.dengFeng;
  return LineageCharacterDetailScreen(character: founder);
}
```

> 注：seed 的 `EquipmentTier.baoWu`/`RealmTier.*` 枚举名实装前以 `enums.dart` 实际值为准；`_AscensionSection` 在 host 下 watch `ascensionEligibilityProvider`，无存档时走 loading/error 兜底（已有 when 分支，不崩）。

- [ ] **Step 5: 跑测确认 PASS + analyze + 真机自检路由可 build**

Run: `flutter test test/features/debug/visual_route_test.dart && flutter analyze`
Expected: PASS，analyze 0。（真机目检留 Task 6 后统一做。）

- [ ] **Step 6: 提交**

```bash
git add lib/features/debug/application/visual_route.dart lib/features/debug/presentation/visual_route_host.dart test/features/debug/visual_route_test.dart
git commit -m "feat: 门派谱1.1 Task5 VISUAL_ROUTE 双路由(lineage_codex + lineage_character_detail)"
```

---

## Task 6: 全量回归 + 收尾

**Files:** 无新增（验证 + 文档）

- [ ] **Step 1: 全量测 + analyze**

Run: `flutter test 2>&1 | tail -5 && flutter analyze 2>&1 | tail -3`
Expected: 全量 PASS（基线 2780 + 本批新增，零回归），analyze 0。**贴实测输出，禁转抄**（memory `feedback_closeout_numbers_grep`）。

- [ ] **Step 2: 红线核对**

确认本批纯展示：`git diff main --stat` 仅触 character_panel/debug/strings/enum_l10n，无 numbers.yaml/伤害/掉落/saveVer 改动。

- [ ] **Step 3: 真机目检（可选，留用户或后续）**

`VISUAL_ROUTE=lineage_codex flutter run -d macos` + `VISUAL_ROUTE=lineage_character_detail flutter run -d macos`，截世代卷/详情屏，验布局无溢出 + 水墨配色 + 立绘/遗物渲染。

- [ ] **Step 4: 合 main + 更新 PROGRESS/session**

主 checkout 合并、更新 PROGRESS.md 顶段 + 写 session 交接（Bash heredoc + python，bg 写守卫）。

---

## Self-Review（写 plan 后自检）

- **spec 覆盖**：spec §二数据来源→Task1；§三主屏世代卷+屏底飞升→Task4；§四角色详情→Task3；§五入口(保持现有)+路由→Task5；§六红线→各 task 守约束 + Task6 核对；§七测试→各 task TDD + Task6 全量。入口「保持现有」无需改 main_menu（现有 `main_menu.dart:313` LineagePanelScreen 入口不动，screen 内部升级即生效）——已在 Task4 隐含覆盖。✅
- **placeholder 扫描**：无 TBD/TODO；provider save 读取处标注「实装前 grep 确认来源」是明确动作非占位。✅
- **类型一致**：`groupGenerations`/`LineageGeneration`/`lineageCodexProvider`(Task1) ↔ Task4/Task5 引用名一致；`EnumL10n.lineageRole`/`UiStrings.lineageCodex*`(Task2) ↔ Task3/Task4 引用一致；`LineageCharacterDetailScreen({required character})`(Task3) ↔ Task4/Task5 push 参数一致。✅
