# 藏经阁2.0（武学收录图鉴）Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 在江湖见闻录(baike)加第5 tab「武学」——205招武学典籍账号级收录图鉴(点亮+剪影藏名+收录进度+详情屏)，对称 encounter_codex 纯派生展示层。

**Architecture:** 纯派生(零Isar collection/零saveVer/零数值改)。`martial_codex_provider.dart` 聚合「收录池205(skillDefs过滤) + 三套点亮口径 + 全队最高熟练度」经纯函数算出分组；`martial_arts_tab.dart` 渲染5组(心法组带小节)；`skill_codex_detail_screen.dart` 同步展示(招式 description 是 SkillDef 同步字段，无需 async)。

**Tech Stack:** Flutter + Riverpod 3.x(codegen `@riverpod`) + Isar(只读) + 既有 `unlockedSkillIdSetProvider`/`activeCharacterIdsProvider`/`characterAllTechniquesProvider`/`SkillProficiency`/`EnumL10n`。

**对称样板**：`lib/features/baike/{application/encounter_codex_provider.dart, presentation/encounter_tab.dart, presentation/encounter_detail_screen.dart}`。

---

## 文件结构

| 文件 | 责任 | 创建/改 |
|---|---|---|
| `lib/features/baike/application/martial_codex_provider.dart` | 类型 + 纯函数(收录过滤/归类/点亮/熟练度/分组) + `@riverpod martialCodex` | 创建 |
| `lib/features/baike/presentation/martial_arts_tab.dart` | baike 第5 tab(5组列表+心法小节+剪影+空态) | 创建 |
| `lib/features/baike/presentation/skill_codex_detail_screen.dart` | 详情屏(同步:类型标+招名+description+数值+来源+所属心法+熟练度) | 创建 |
| `lib/shared/strings.dart` | UiStrings 武学图鉴词条 | 改(追加) |
| `lib/features/baike/presentation/baike_screen.dart` | 4→5 tab | 改(`:30,:44-49,:52-59`) |
| `lib/features/debug/application/visual_route.dart` | 双路由 enum | 改(追加2值) |
| `lib/features/debug/presentation/visual_route_host.dart` | 双路由构造 | 改(追加2 case) |
| `test/features/baike/application/martial_codex_provider_test.dart` | 纯函数单测 | 创建 |
| `test/features/baike/presentation/martial_arts_tab_test.dart` | tab widget 测 | 创建 |
| `test/features/baike/presentation/baike_screen_test.dart` | 补第5 tab 断言 | 改 |

**收录池过滤(单一真相源)**：`source∈{technique,mainlineDrop,fragment,encounter}` 或 `(source==special && canInterrupt)`。排除 special非破招(轻功18+joint1)。
**三套点亮口径**：心法招→active角色学过该心法；稀有招(真解/残页/奇遇)→`unlockedSkillIdSet`；破招(special∩canInterrupt)→active队伍含该style角色。

---

### Task 1: 收录过滤 + 来源归类（纯函数 + 类型）

**Files:**
- Create: `lib/features/baike/application/martial_codex_provider.dart`
- Test: `test/features/baike/application/martial_codex_provider_test.dart`

- [ ] **Step 1: 写失败测试**

```dart
// test/features/baike/application/martial_codex_provider_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/defs/skill_def.dart';
import 'package:wuxia_idle/features/baike/application/martial_codex_provider.dart';

SkillDef _skill(String id, SkillSource? source,
        {bool canInterrupt = false, TechniqueSchool? style}) =>
    SkillDef(
      id: id,
      name: id,
      description: 'd',
      type: SkillType.powerSkill,
      powerMultiplier: 1000,
      internalForceCost: 10,
      cooldownTurns: 2,
      requiresManualTrigger: false,
      visualEffect: 'none',
      source: source,
      canInterrupt: canInterrupt,
      style: style,
    );

void main() {
  group('isMartialCodexSkill', () {
    test('心法/真解/残页/奇遇收录', () {
      expect(isMartialCodexSkill(_skill('a', SkillSource.technique)), isTrue);
      expect(isMartialCodexSkill(_skill('b', SkillSource.mainlineDrop)), isTrue);
      expect(isMartialCodexSkill(_skill('c', SkillSource.fragment)), isTrue);
      expect(isMartialCodexSkill(_skill('d', SkillSource.encounter)), isTrue);
    });
    test('破招(special∩canInterrupt)收录,轻功/joint(special非破招)不收', () {
      expect(
          isMartialCodexSkill(
              _skill('po', SkillSource.special, canInterrupt: true)),
          isTrue);
      expect(isMartialCodexSkill(_skill('lf', SkillSource.special)), isFalse);
    });
    test('source==null 不收', () {
      expect(isMartialCodexSkill(_skill('x', null)), isFalse);
    });
  });

  group('martialSourceKindOf', () {
    test('破招优先于 special 兜底', () {
      expect(
          martialSourceKindOf(
              _skill('po', SkillSource.special, canInterrupt: true)),
          MartialGroupKind.interrupt);
    });
    test('5 类映射', () {
      expect(martialSourceKindOf(_skill('a', SkillSource.technique)),
          MartialGroupKind.heartArt);
      expect(martialSourceKindOf(_skill('b', SkillSource.mainlineDrop)),
          MartialGroupKind.trueSolution);
      expect(martialSourceKindOf(_skill('c', SkillSource.fragment)),
          MartialGroupKind.fragment);
      expect(martialSourceKindOf(_skill('d', SkillSource.encounter)),
          MartialGroupKind.encounter);
    });
  });
}
```

- [ ] **Step 2: 运行验证失败**

Run: `flutter test test/features/baike/application/martial_codex_provider_test.dart`
Expected: FAIL — `martial_codex_provider.dart` 不存在 / 符号未定义。

- [ ] **Step 3: 写最小实现**

```dart
// lib/features/baike/application/martial_codex_provider.dart
import '../../../core/domain/enums.dart';
import '../../../data/defs/skill_def.dart';

/// 武学图鉴 5 来源分组(方案 A)。
enum MartialGroupKind { heartArt, trueSolution, fragment, interrupt, encounter }

/// 是否纳入武学典籍收录池(205招)。
/// source∈{technique,mainlineDrop,fragment,encounter} 或 破招(special∩canInterrupt)。
/// 排除 special 非破招(轻功对决18 + joint共鸣1)。
bool isMartialCodexSkill(SkillDef d) {
  switch (d.source) {
    case SkillSource.technique:
    case SkillSource.mainlineDrop:
    case SkillSource.fragment:
    case SkillSource.encounter:
      return true;
    case SkillSource.special:
      return d.canInterrupt; // 破招收,轻功/joint 不收
    case null:
      return false;
  }
}

/// 来源归类(破招优先于 special 兜底)。归类与段标共用,防双份漂移。
/// 前置:仅对收录池(isMartialCodexSkill==true)调用。
MartialGroupKind martialSourceKindOf(SkillDef d) {
  if (d.source == SkillSource.special && d.canInterrupt) {
    return MartialGroupKind.interrupt;
  }
  switch (d.source) {
    case SkillSource.technique:
      return MartialGroupKind.heartArt;
    case SkillSource.mainlineDrop:
      return MartialGroupKind.trueSolution;
    case SkillSource.fragment:
      return MartialGroupKind.fragment;
    case SkillSource.encounter:
      return MartialGroupKind.encounter;
    case SkillSource.special:
    case null:
      throw StateError('非武学典籍招进入归类(应先经 isMartialCodexSkill): ${d.id}');
  }
}
```

- [ ] **Step 4: 运行验证通过**

Run: `flutter test test/features/baike/application/martial_codex_provider_test.dart`
Expected: PASS

- [ ] **Step 5: 提交**

```bash
git add lib/features/baike/application/martial_codex_provider.dart test/features/baike/application/martial_codex_provider_test.dart
git commit -m "feat: 藏经阁2.0 Task1 收录过滤+来源归类纯函数(205池/破招优先)"
```

---

### Task 2: 三套点亮口径 + 全队最高熟练度（纯函数）

**Files:**
- Modify: `lib/features/baike/application/martial_codex_provider.dart`
- Test: `test/features/baike/application/martial_codex_provider_test.dart`

- [ ] **Step 1: 追加失败测试**（在 Task1 测试文件 `main()` 末尾追加，复用 `_skill` helper）

```dart
  group('litSkillIds 三套口径', () {
    final pool = [
      _skill('ha', SkillSource.technique),           // 心法招
      _skill('rare', SkillSource.mainlineDrop),      // 稀有招
      _skill('enc', SkillSource.encounter),          // 稀有招
      _skill('po', SkillSource.special,
          canInterrupt: true, style: TechniqueSchool.gangMeng), // 破招·刚猛
    ];
    test('心法招走 learned 集', () {
      final lit = litSkillIds(
        pool: pool,
        unlockedIds: const {},
        learnedHeartArtSkillIds: const {'ha'},
        activeSchools: const {},
      );
      expect(lit, contains('ha'));
      expect(lit, isNot(contains('rare')));
    });
    test('稀有招走 unlockedIds', () {
      final lit = litSkillIds(
        pool: pool,
        unlockedIds: const {'rare', 'enc'},
        learnedHeartArtSkillIds: const {},
        activeSchools: const {},
      );
      expect(lit, containsAll(['rare', 'enc']));
      expect(lit, isNot(contains('po')));
    });
    test('破招走 activeSchools 含该 style', () {
      final lit = litSkillIds(
        pool: pool,
        unlockedIds: const {},
        learnedHeartArtSkillIds: const {},
        activeSchools: const {TechniqueSchool.gangMeng},
      );
      expect(lit, contains('po'));
    });
    test('破招 style 不在 activeSchools 则不点亮', () {
      final lit = litSkillIds(
        pool: pool,
        unlockedIds: const {},
        learnedHeartArtSkillIds: const {},
        activeSchools: const {TechniqueSchool.yinRou},
      );
      expect(lit, isNot(contains('po')));
    });
  });
```

> `maxUsesOf` 因依赖 Isar 实体 `Technique` 构造复杂，留 Task4 provider 集成 + Task3 分组测试间接覆盖；此处仅测无 Isar 依赖的 `litSkillIds`。

- [ ] **Step 2: 运行验证失败**

Run: `flutter test test/features/baike/application/martial_codex_provider_test.dart`
Expected: FAIL — `litSkillIds` 未定义。

- [ ] **Step 3: 追加实现**（martial_codex_provider.dart，import 段加 `import '../../../core/domain/technique.dart';`）

```dart
/// 三套点亮口径(2026-06-22 spec)。pool 须已过滤为收录池。
/// - 心法招(heartArt): id ∈ learnedHeartArtSkillIds(active角色学过的心法招并集)
/// - 稀有招(trueSolution/fragment/encounter): id ∈ unlockedIds(unlockedSkillIdSet)
/// - 破招(interrupt): style ∈ activeSchools(active角色 school 集)
Set<String> litSkillIds({
  required Iterable<SkillDef> pool,
  required Set<String> unlockedIds,
  required Set<String> learnedHeartArtSkillIds,
  required Set<TechniqueSchool> activeSchools,
}) {
  final lit = <String>{};
  for (final d in pool) {
    switch (martialSourceKindOf(d)) {
      case MartialGroupKind.heartArt:
        if (learnedHeartArtSkillIds.contains(d.id)) lit.add(d.id);
      case MartialGroupKind.interrupt:
        if (d.style != null && activeSchools.contains(d.style)) lit.add(d.id);
      case MartialGroupKind.trueSolution:
      case MartialGroupKind.fragment:
      case MartialGroupKind.encounter:
        if (unlockedIds.contains(d.id)) lit.add(d.id);
    }
  }
  return lit;
}

/// active 角色学过的心法招并集(正向:由 techDef.skillIds 取,对称 1.0 武学库)。
Set<String> learnedHeartArtSkillIds(
  List<Technique> techniques,
  Map<String, dynamic> techDefsById,
) {
  final s = <String>{};
  for (final t in techniques) {
    final def = techDefsById[t.defId];
    if (def != null) s.addAll((def.skillIds as List).cast<String>());
  }
  return s;
}

/// 全队该招最高使用次数(剪影/未练=0)。
int maxUsesOf(String skillId, List<Technique> techniques) {
  var max = 0;
  for (final t in techniques) {
    final c = t.skillUsageCount.countOf(skillId);
    if (c > max) max = c;
  }
  return max;
}
```

> 注：`learnedHeartArtSkillIds` 的 `techDefsById` 用 `Map<String,dynamic>` 接 `repo.techniqueDefs`(避免在纯函数文件 import TechniqueDef 造成测试构造负担)；`.skillIds` 经 cast 取。Task4 provider 传 `GameRepository.instance.techniqueDefs`。

- [ ] **Step 4: 运行验证通过**

Run: `flutter test test/features/baike/application/martial_codex_provider_test.dart`
Expected: PASS

- [ ] **Step 5: 提交**

```bash
git add lib/features/baike/application/martial_codex_provider.dart test/features/baike/application/martial_codex_provider_test.dart
git commit -m "feat: 藏经阁2.0 Task2 三套点亮口径+全队最高熟练度纯函数"
```

---

### Task 3: 分组 groupMartialSkills（心法小节 + 计数 + 剪影 + 空段）

**Files:**
- Modify: `lib/features/baike/application/martial_codex_provider.dart`
- Test: `test/features/baike/application/martial_codex_provider_test.dart`

**数据结构**：心法绝学组内按所属心法分小节(正向 `techDef.skillIds` 归集，对称 1.0 武学库)，小节标题 `心法名·tier·school`；其余4组单小节(label=null)平铺。

- [ ] **Step 1: 追加失败测试**

```dart
  group('groupMartialSkills', () {
    test('空段不产出 + 计数 + 剪影 maxStage 为 null', () {
      final pool = [
        _skill('rare1', SkillSource.mainlineDrop),
        _skill('rare2', SkillSource.mainlineDrop),
        _skill('enc1', SkillSource.encounter),
      ];
      final groups = groupMartialSkills(
        pool: pool,
        litIds: const {'rare1'},
        stageById: const {},
        techDefsById: const {},
      );
      // 心法/残页/破招段空 → 不产出;只剩真解 + 奇遇 2 段
      expect(groups.map((g) => g.kind),
          containsAll([MartialGroupKind.trueSolution, MartialGroupKind.encounter]));
      expect(groups.any((g) => g.kind == MartialGroupKind.fragment), isFalse);
      final trueSol =
          groups.firstWhere((g) => g.kind == MartialGroupKind.trueSolution);
      expect(trueSol.litCount, 1);
      expect(trueSol.totalCount, 2);
      // rare2 剪影 → isLit=false
      final allEntries =
          trueSol.subGroups.expand((s) => s.entries).toList();
      expect(allEntries.firstWhere((e) => e.def.id == 'rare2').isLit, isFalse);
    });

    test('组顺序固定:心法→真解→残页→破招→奇遇', () {
      final pool = [
        _skill('enc', SkillSource.encounter),
        _skill('po', SkillSource.special, canInterrupt: true),
        _skill('rare', SkillSource.mainlineDrop),
      ];
      final groups = groupMartialSkills(
        pool: pool,
        litIds: const {},
        stageById: const {},
        techDefsById: const {},
      );
      expect(groups.map((g) => g.kind).toList(),
          [MartialGroupKind.trueSolution, MartialGroupKind.interrupt, MartialGroupKind.encounter]);
    });

    test('心法绝学按所属心法分小节,标题含心法名/tier/流派', () {
      final pool = [
        _skill('s1', SkillSource.technique),
        _skill('s2', SkillSource.technique),
      ];
      final fake = _FakeTechDef(
          name: '太祖长拳',
          tier: TechniqueTier.ruMenGong,
          school: TechniqueSchool.gangMeng,
          skillIds: const ['s1', 's2']);
      final groups = groupMartialSkills(
        pool: pool,
        litIds: const {'s1'},
        stageById: const {},
        techDefsById: {'t1': fake},
      );
      final heart =
          groups.firstWhere((g) => g.kind == MartialGroupKind.heartArt);
      expect(heart.subGroups.first.label, contains('太祖长拳'));
      expect(heart.subGroups.first.entries.length, 2);
      expect(heart.litCount, 1); // s1 点亮,s2 剪影
    });
  });
```

> 测试文件顶部加 `import 'package:wuxia_idle/core/domain/enums.dart';`（TechniqueTier/TechniqueSchool 已在 Task1 import）+ dynamic fake（鸭子类型喂 `techDefsById`，避免构造真 TechniqueDef）：
> ```dart
> class _FakeTechDef {
>   _FakeTechDef({required this.name, required this.tier, required this.school, required this.skillIds});
>   final String name;
>   final TechniqueTier tier;
>   final TechniqueSchool school;
>   final List<String> skillIds;
> }
> ```

- [ ] **Step 2: 运行验证失败**

Run: `flutter test test/features/baike/application/martial_codex_provider_test.dart`
Expected: FAIL — `groupMartialSkills` / `MartialCodexGroup` 等未定义。

- [ ] **Step 3: 追加实现**（martial_codex_provider.dart，import 段加 `import '../../../data/numbers_config.dart';` `import '../../battle/domain/enum_localizations.dart';`）

```dart
/// 一条武学图鉴条目:def + 是否点亮 + 全队最高熟练阶(剪影/未练 null)。
class MartialCodexEntry {
  const MartialCodexEntry({
    required this.def,
    required this.isLit,
    this.maxStage,
  });
  final SkillDef def;
  final bool isLit;
  final SkillProficiencyStageConfig? maxStage;
}

/// 组内小节(心法组按心法分小节带 label;其余组单小节 label=null)。
class MartialCodexSubGroup {
  const MartialCodexSubGroup({this.label, required this.entries});
  final String? label;
  final List<MartialCodexEntry> entries;
}

/// 一个来源大组 + 小节 + 点亮/总数计数。
class MartialCodexGroup {
  const MartialCodexGroup({
    required this.kind,
    required this.subGroups,
    required this.litCount,
    required this.totalCount,
  });
  final MartialGroupKind kind;
  final List<MartialCodexSubGroup> subGroups;
  final int litCount;
  final int totalCount;
}

const _kindOrder = [
  MartialGroupKind.heartArt,
  MartialGroupKind.trueSolution,
  MartialGroupKind.fragment,
  MartialGroupKind.interrupt,
  MartialGroupKind.encounter,
];

MartialCodexEntry _entryOf(
  SkillDef d,
  Set<String> litIds,
  Map<String, SkillProficiencyStageConfig> stageById,
) {
  final lit = litIds.contains(d.id);
  return MartialCodexEntry(
    def: d,
    isLit: lit,
    maxStage: lit ? stageById[d.id] : null,
  );
}

/// 分组:5 来源固定序,空段不产出。心法组按所属心法(正向 techDef.skillIds)分小节。
/// techDefsById 传 GameRepository.instance.techniqueDefs(纯函数侧用 dynamic 接)。
List<MartialCodexGroup> groupMartialSkills({
  required Iterable<SkillDef> pool,
  required Set<String> litIds,
  required Map<String, SkillProficiencyStageConfig> stageById,
  required Map<String, dynamic> techDefsById,
}) {
  final poolById = {for (final d in pool) d.id: d};
  // 按 kind 分桶
  final byKind = <MartialGroupKind, List<SkillDef>>{};
  for (final d in pool) {
    byKind.putIfAbsent(martialSourceKindOf(d), () => []).add(d);
  }

  final result = <MartialCodexGroup>[];
  for (final kind in _kindOrder) {
    final defs = byKind[kind];
    if (defs == null || defs.isEmpty) continue; // 空段不产出

    final List<MartialCodexSubGroup> subGroups;
    if (kind == MartialGroupKind.heartArt) {
      subGroups = _heartArtSubGroups(poolById, litIds, stageById, techDefsById);
    } else {
      subGroups = [
        MartialCodexSubGroup(
          entries: [for (final d in defs) _entryOf(d, litIds, stageById)],
        ),
      ];
    }
    final entries = subGroups.expand((s) => s.entries).toList();
    result.add(MartialCodexGroup(
      kind: kind,
      subGroups: subGroups,
      litCount: entries.where((e) => e.isLit).length,
      totalCount: entries.length,
    ));
  }
  return result;
}

/// 心法绝学组小节:遍历 techDef(按 tier.index→school.index 序),
/// 取其 skillIds 中属收录池&心法招的招,小节标题=心法名·tier·school。
/// 未归入任何心法的心法招(理论无)落「其他」小节兜底。
List<MartialCodexSubGroup> _heartArtSubGroups(
  Map<String, SkillDef> poolById,
  Set<String> litIds,
  Map<String, SkillProficiencyStageConfig> stageById,
  Map<String, dynamic> techDefsById,
) {
  final claimed = <String>{};
  final subs = <MartialCodexSubGroup>[];
  final techDefs = techDefsById.values.toList()
    ..sort((a, b) {
      final t = (a.tier.index as int).compareTo(b.tier.index as int);
      return t != 0 ? t : (a.school.index as int).compareTo(b.school.index as int);
    });
  for (final td in techDefs) {
    final entries = <MartialCodexEntry>[];
    for (final sid in (td.skillIds as List).cast<String>()) {
      final d = poolById[sid];
      if (d == null || d.source != SkillSource.technique) continue;
      claimed.add(sid);
      entries.add(_entryOf(d, litIds, stageById));
    }
    if (entries.isEmpty) continue;
    subs.add(MartialCodexSubGroup(
      label:
          '${td.name} · ${EnumL10n.techniqueTier(td.tier)} · ${EnumL10n.school(td.school)}',
      entries: entries,
    ));
  }
  // 兜底:未被任何心法 claim 的心法招
  final orphans = [
    for (final d in poolById.values)
      if (d.source == SkillSource.technique && !claimed.contains(d.id))
        _entryOf(d, litIds, stageById),
  ];
  if (orphans.isNotEmpty) {
    subs.add(MartialCodexSubGroup(label: null, entries: orphans));
  }
  return subs;
}
```

> 测试里 `techDefsById: const {}` → 心法招全落 orphans 小节，分组逻辑仍成立(测试只校验非心法组)。Task4 provider 传真实 techDefs，心法小节生效。

- [ ] **Step 4: 运行验证通过**

Run: `flutter test test/features/baike/application/martial_codex_provider_test.dart`
Expected: PASS

- [ ] **Step 5: 提交**

```bash
git add lib/features/baike/application/martial_codex_provider.dart test/features/baike/application/martial_codex_provider_test.dart
git commit -m "feat: 藏经阁2.0 Task3 分组(心法小节/计数/剪影/空段不产出)"
```

---

### Task 4: martialCodex provider（@riverpod 聚合）

**Files:**
- Modify: `lib/features/baike/application/martial_codex_provider.dart`
- 生成: `martial_codex_provider.g.dart`(build_runner)

- [ ] **Step 1: 追加 provider 实现**（文件顶部加 part + import）

```dart
// 文件首行 import 段补:
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/application/character_providers.dart';
import '../../../data/game_repository.dart';
import '../../../data/numbers_config.dart' show NumbersConfig; // 已有则合并
import '../../cultivation/domain/skill_proficiency.dart';
import '../../encounter/application/encounter_service_providers.dart';
// 文件顶部(类型定义前)加:
part 'martial_codex_provider.g.dart';
```

```dart
/// 武学收录图鉴派生 provider:聚合 收录池205 + 三套点亮 + 全队最高熟练度 → 5 组。
/// 纯派生(零写库)。numbersConfig 取 skillProficiency cfg 算熟练阶。
@riverpod
Future<List<MartialCodexGroup>> martialCodex(Ref ref) async {
  if (!GameRepository.isLoaded) return const [];
  final repo = GameRepository.instance;
  final pool = repo.skillDefs.values.where(isMartialCodexSkill).toList();

  final cfg = ref.watch(numbersConfigProvider).skillProficiency;
  final unlockedIds = await ref.watch(unlockedSkillIdSetProvider.future);
  final activeIds = await ref.watch(activeCharacterIdsProvider.future);

  final allTechniques = <Technique>[];
  final activeSchools = <TechniqueSchool>{};
  for (final id in activeIds) {
    allTechniques.addAll(
        await ref.watch(characterAllTechniquesProvider(id).future));
    final c = await ref.watch(characterByIdProvider(id).future);
    final s = c?.school;
    if (s != null) activeSchools.add(s);
  }

  final learned = learnedHeartArtSkillIds(allTechniques, repo.techniqueDefs);
  final lit = litSkillIds(
    pool: pool,
    unlockedIds: unlockedIds,
    learnedHeartArtSkillIds: learned,
    activeSchools: activeSchools,
  );
  final stageById = <String, SkillProficiencyStageConfig>{};
  for (final id in lit) {
    final uses = maxUsesOf(id, allTechniques);
    if (uses > 0) stageById[id] = SkillProficiency.stageFor(uses, cfg);
  }
  return groupMartialSkills(
    pool: pool,
    litIds: lit,
    stageById: stageById,
    techDefsById: repo.techniqueDefs,
  );
}
```

> `numbersConfigProvider` 在 `numbers_config.dart`(cangjingge_screen.dart:18,:137 已用)。`character.school` 类型 `TechniqueSchool?`(cangjingge_screen.dart:466 用 `character.school`)。

- [ ] **Step 2: 跑 build_runner 生成 .g.dart**

Run: `dart run build_runner build --delete-conflicting-outputs 2>&1 | tail -5`
Expected: `Succeeded`，生成 `lib/features/baike/application/martial_codex_provider.g.dart`。

- [ ] **Step 3: 全项目 analyze + 既有测试**

Run: `flutter analyze 2>&1 | tail -3 && flutter test test/features/baike/application/martial_codex_provider_test.dart`
Expected: analyze `No issues found` + 测试 PASS。

- [ ] **Step 4: 提交**

```bash
git add lib/features/baike/application/martial_codex_provider.dart lib/features/baike/application/martial_codex_provider.g.dart
git commit -m "feat: 藏经阁2.0 Task4 martialCodex provider(聚合三套点亮+熟练度)"
```

---

### Task 5: UiStrings 词条

**Files:**
- Modify: `lib/shared/strings.dart`（在 `encounterCodexDetailTitle`(`:1155`) 后追加）

- [ ] **Step 1: 追加词条**（照 encounterCodex 体例）

```dart
  // ── 藏经阁2.0 武学收录图鉴(P4 子项6) ──
  static const String baikeTabSkills = '武学';
  static String skillCodexProgress(int got, int total) => '已习 $got/$total';
  static String skillCodexGroupProgress(int got, int total) => '$got/$total 已习';
  static const String skillCodexGroupHeartArt = '心法绝学';
  static const String skillCodexGroupTrueSolution = '真解';
  static const String skillCodexGroupFragment = '残页';
  static const String skillCodexGroupInterrupt = '破招';
  static const String skillCodexGroupEncounter = '奇遇武学';
  static const String skillCodexEmpty = '武学无涯，尚需修习';
  static const String skillCodexLocked = '？？？';
  static const String skillCodexNotMet = '尚未习得';
  static const String skillCodexDetailTitle = '武学';
  static const String skillCodexSource = '来源';
  static const String skillCodexProficiencyPrefix = '造诣';
  static const String skillCodexProficiencyNone = '未曾习练';
  static const String skillCodexBelongTo = '所属';
  static const String skillCodexMultiplier = '倍率';
  static const String skillCodexCost = '内力';
  static const String skillCodexCooldown = '冷却';
```

> `labelForMartialGroupKind` 纯函数(Task6 用)将 switch 这 5 个 group 常量；段标与详情屏共用防漂移。

- [ ] **Step 2: analyze**

Run: `flutter analyze lib/shared/strings.dart 2>&1 | tail -3`
Expected: `No issues found`（未引用的 static const 不报 warning）。

- [ ] **Step 3: 提交**

```bash
git add lib/shared/strings.dart
git commit -m "feat: 藏经阁2.0 Task5 UiStrings 武学图鉴词条"
```

---

### Task 6: martial_arts_tab（第5 tab UI + 心法小节 + 剪影 + 空态）

**Files:**
- Create: `lib/features/baike/presentation/martial_arts_tab.dart`
- Modify: `lib/features/baike/application/martial_codex_provider.dart`（加 `labelForMartialGroupKind` 共享纯函数）
- Test: `test/features/baike/presentation/martial_arts_tab_test.dart`

- [ ] **Step 1: 在 provider 文件加共享段标纯函数**（import 段已有 strings）

```dart
// martial_codex_provider.dart 追加(import '../../../shared/strings.dart';):
/// 来源大组 → 段标显示名。tab 段标与详情屏来源标共用,防双份漂移。
String labelForMartialGroupKind(MartialGroupKind kind) => switch (kind) {
      MartialGroupKind.heartArt => UiStrings.skillCodexGroupHeartArt,
      MartialGroupKind.trueSolution => UiStrings.skillCodexGroupTrueSolution,
      MartialGroupKind.fragment => UiStrings.skillCodexGroupFragment,
      MartialGroupKind.interrupt => UiStrings.skillCodexGroupInterrupt,
      MartialGroupKind.encounter => UiStrings.skillCodexGroupEncounter,
    };
```

- [ ] **Step 2: 写 widget 测（失败）**

```dart
// test/features/baike/presentation/martial_arts_tab_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/defs/skill_def.dart';
import 'package:wuxia_idle/features/baike/application/martial_codex_provider.dart';
import 'package:wuxia_idle/features/baike/presentation/martial_arts_tab.dart';
import 'package:wuxia_idle/shared/strings.dart';

SkillDef _s(String id, SkillSource src, {bool ci = false}) => SkillDef(
      id: id, name: '$id名', description: 'd', type: SkillType.powerSkill,
      powerMultiplier: 1000, internalForceCost: 10, cooldownTurns: 2,
      requiresManualTrigger: false, visualEffect: 'none', source: src,
      canInterrupt: ci);

Widget _host(List<MartialCodexGroup> groups) => ProviderScope(
      overrides: [martialCodexProvider.overrideWith((ref) async => groups)],
      child: const MaterialApp(home: Scaffold(body: MartialArtsTab())),
    );

void main() {
  testWidgets('混态:点亮显名 + 剪影显???+ 进度', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 2000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final groups = [
      MartialCodexGroup(
        kind: MartialGroupKind.trueSolution,
        subGroups: [
          MartialCodexSubGroup(entries: [
            MartialCodexEntry(def: _s('a', SkillSource.mainlineDrop), isLit: true),
            MartialCodexEntry(def: _s('b', SkillSource.mainlineDrop), isLit: false),
          ]),
        ],
        litCount: 1, totalCount: 2,
      ),
    ];
    await tester.pumpWidget(_host(groups));
    await tester.pumpAndSettle();
    expect(find.text('a名'), findsOneWidget);           // 点亮显名
    expect(find.text(UiStrings.skillCodexLocked), findsOneWidget); // 剪影???
    expect(find.text(UiStrings.skillCodexProgress(1, 2)), findsOneWidget);
  });

  testWidgets('空态:全未点亮不甩剪影墙', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 2000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final groups = [
      MartialCodexGroup(
        kind: MartialGroupKind.trueSolution,
        subGroups: [
          MartialCodexSubGroup(entries: [
            MartialCodexEntry(def: _s('b', SkillSource.mainlineDrop), isLit: false),
          ]),
        ],
        litCount: 0, totalCount: 1,
      ),
    ];
    await tester.pumpWidget(_host(groups));
    await tester.pumpAndSettle();
    expect(find.text(UiStrings.skillCodexEmpty), findsOneWidget);
    expect(find.text(UiStrings.skillCodexLocked), findsNothing); // 不甩剪影
  });
}
```

- [ ] **Step 3: 运行验证失败**

Run: `flutter test test/features/baike/presentation/martial_arts_tab_test.dart`
Expected: FAIL — `MartialArtsTab` 不存在。

- [ ] **Step 4: 写 tab 实现**（对称 encounter_tab.dart，差异：心法组渲染小节 label）

```dart
// lib/features/baike/presentation/martial_arts_tab.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/strings.dart';
import '../../../shared/theme/colors.dart';
import '../application/martial_codex_provider.dart';
import 'skill_codex_detail_screen.dart';

/// 武学收录图鉴 tab(Task6):江湖见闻录第 5 tab「武学」。
///
/// watch [martialCodexProvider] → 5 来源大组(心法组带小节)。点亮行显招名、
/// 点击进 [SkillCodexDetailScreen] 回看;剪影行显「？？？」(不泄来源/解锁条件,守 §5.7),
/// 点击弹「尚未习得」snackbar。
///
/// 空态保护(§5.7):一招未点亮(groups空 或 总点亮0)→「武学无涯，尚需修习」,**不甩剪影墙**。
/// 纯展示层,不写库。
class MartialArtsTab extends ConsumerWidget {
  const MartialArtsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(martialCodexProvider);
    return async.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: WuxiaColors.resultHighlight),
      ),
      error: (e, _) => const _EmptyHint(text: UiStrings.skillCodexEmpty),
      data: (groups) => _buildBody(context, groups),
    );
  }

  Widget _buildBody(BuildContext context, List<MartialCodexGroup> groups) {
    final totalLit = groups.fold<int>(0, (s, g) => s + g.litCount);
    if (groups.isEmpty || totalLit == 0) {
      return const _EmptyHint(text: UiStrings.skillCodexEmpty);
    }
    final totalEntries = groups.fold<int>(0, (s, g) => s + g.totalCount);
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      children: [
        Text(
          UiStrings.skillCodexProgress(totalLit, totalEntries),
          style: const TextStyle(
            color: WuxiaColors.resultHighlight,
            fontSize: 13,
            letterSpacing: 1,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        for (final g in groups) ...[
          _GroupSection(group: g),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _GroupSection extends StatelessWidget {
  const _GroupSection({required this.group});
  final MartialCodexGroup group;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  labelForMartialGroupKind(group.kind),
                  style: const TextStyle(
                    color: WuxiaColors.resultHighlight,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                UiStrings.skillCodexGroupProgress(
                    group.litCount, group.totalCount),
                style: const TextStyle(
                    color: WuxiaColors.textMuted, fontSize: 12),
              ),
            ],
          ),
        ),
        for (final sub in group.subGroups) ...[
          if (sub.label != null)
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 2),
              child: Text(
                sub.label!,
                style: const TextStyle(
                  color: WuxiaColors.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          for (final entry in sub.entries)
            entry.isLit
                ? _LitRow(entry: entry)
                : const _SilhouetteRow(),
        ],
        const SizedBox(height: 8),
        const Divider(height: 1, color: WuxiaColors.border),
      ],
    );
  }
}

/// 点亮行:显招名,点击进详情屏回看。
class _LitRow extends StatelessWidget {
  const _LitRow({required this.entry});
  final MartialCodexEntry entry;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) =>
              SkillCodexDetailScreen(def: entry.def, maxStage: entry.maxStage),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: Text(
                entry.def.name,
                style: const TextStyle(
                    color: WuxiaColors.textSecondary, fontSize: 13),
              ),
            ),
            const Icon(Icons.chevron_right,
                color: WuxiaColors.textMuted, size: 18),
          ],
        ),
      ),
    );
  }
}

/// 剪影行:只显「？？？」,绝不泄来源/解锁条件(§5.7)。点击弹「尚未习得」。
class _SilhouetteRow extends StatelessWidget {
  const _SilhouetteRow();

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(UiStrings.skillCodexNotMet)),
      ),
      child: const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(Icons.help_outline, color: WuxiaColors.textMuted, size: 16),
            SizedBox(width: 8),
            Text(
              UiStrings.skillCodexLocked,
              style: TextStyle(
                  color: WuxiaColors.textMuted, fontSize: 13, letterSpacing: 1),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(
              color: WuxiaColors.textMuted, fontSize: 15, height: 1.6),
        ),
      ),
    );
  }
}
```

- [ ] **Step 5: 运行验证通过 + analyze**

Run: `flutter test test/features/baike/presentation/martial_arts_tab_test.dart && flutter analyze 2>&1 | tail -3`
Expected: 测试 PASS（注：详情屏 Task7 才建，本 step tab 测试不触发导航，可过；若 import 报 `skill_codex_detail_screen` 缺失，先建 Task7 再回跑）。

> 执行顺序提示：Task6 与 Task7 互引(tab→detail)。建议先建 Task7 的 detail 文件骨架或合并执行 Task6+7 后统一 analyze。

- [ ] **Step 6: 提交**

```bash
git add lib/features/baike/presentation/martial_arts_tab.dart lib/features/baike/application/martial_codex_provider.dart test/features/baike/presentation/martial_arts_tab_test.dart
git commit -m "feat: 藏经阁2.0 Task6 martial_arts_tab(心法小节/剪影/空态)+共享段标"
```

---

### Task 7: skill_codex_detail_screen（详情屏 · 同步派生）

**Files:**
- Create: `lib/features/baike/presentation/skill_codex_detail_screen.dart`
- Test: `test/features/baike/presentation/martial_arts_tab_test.dart`（追加详情屏测）

详情屏**纯同步**(招式 description 是 SkillDef 同步字段，无 async)：类型标(skillType) + 招名 + description + 倍率/内力/冷却 + 来源标 + 所属心法 + 全队最高熟练阶。

- [ ] **Step 1: 追加详情屏失败测试**（martial_arts_tab_test.dart `main()` 末尾）

```dart
  testWidgets('详情屏同步显 招名+description+倍率', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 2000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final def = _s('po_shi', SkillSource.special, ci: true);
    await tester.pumpWidget(MaterialApp(
      home: SkillCodexDetailScreen(def: def, maxStage: null),
    ));
    await tester.pumpAndSettle();
    expect(find.text('po_shi名'), findsOneWidget);
    expect(find.text('d'), findsOneWidget); // description
    expect(find.textContaining('1000'), findsWidgets); // 倍率
    expect(find.text(UiStrings.skillCodexProficiencyNone), findsOneWidget); // maxStage null
  });
```

需在该测试文件顶部加 `import 'package:wuxia_idle/features/baike/presentation/skill_codex_detail_screen.dart';` 和 `import 'package:wuxia_idle/data/numbers_config.dart';`（用 SkillProficiencyStageConfig）。

- [ ] **Step 2: 运行验证失败**

Run: `flutter test test/features/baike/presentation/martial_arts_tab_test.dart -n "详情屏"`
Expected: FAIL — `SkillCodexDetailScreen` 不存在。

- [ ] **Step 3: 写详情屏实现**（同步，对称 encounter_detail 的 _TypeTag/PaperPanel 但去 FutureBuilder）

```dart
// lib/features/baike/presentation/skill_codex_detail_screen.dart
import 'package:flutter/material.dart';

import '../../../data/defs/skill_def.dart';
import '../../../data/game_repository.dart';
import '../../../data/numbers_config.dart';
import '../../../shared/strings.dart';
import '../../../shared/theme/colors.dart';
import '../../../shared/theme/wuxia_tokens.dart';
import '../../../shared/widgets/wuxia_ui/paper_panel.dart';
import '../../../shared/widgets/wuxia_ui/section_header.dart';
import '../../../shared/widgets/wuxia_ui/wuxia_title_bar.dart';
import '../../battle/domain/enum_localizations.dart';
import '../application/martial_codex_provider.dart';

/// 武学详情屏(Task7)。从武学图鉴 tab 点亮行推入,回看一招已习武学。
///
/// 纯同步展示(招式 name/description 是 [SkillDef] 同步字段,无 async):
/// 类型标(普攻/强力/大招) + 招名 + description + 倍率/内力/冷却 + 来源标 + 所属心法 +
/// 全队最高熟练阶([maxStage] 由 tab 算好传入,null=未曾习练)。
/// 纯只读,不读 provider / 不写库。
class SkillCodexDetailScreen extends StatelessWidget {
  const SkillCodexDetailScreen({
    super.key,
    required this.def,
    required this.maxStage,
  });

  final SkillDef def;
  final SkillProficiencyStageConfig? maxStage;

  /// 所属心法名(正向:遍历 techDefs 找含此招的心法;非心法招 null)。
  String? get _belongTechniqueName {
    if (!GameRepository.isLoaded) return null;
    if (def.source != SkillSource.technique) return null;
    for (final td in GameRepository.instance.techniqueDefs.values) {
      if (td.skillIds.contains(def.id)) return td.name;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final belong = _belongTechniqueName;
    return Scaffold(
      backgroundColor: WuxiaColors.background,
      appBar: WuxiaTitleBar(
        title: UiStrings.skillCodexDetailTitle,
        onBack: () => Navigator.of(context).maybePop(),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
          child: PaperPanel(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _TypeTag(label: EnumL10n.skillType(def.type)),
                const SizedBox(height: 12),
                SectionHeader(def.name),
                const SizedBox(height: 8),
                Text(
                  def.description,
                  style: const TextStyle(
                    color: WuxiaUi.ink,
                    fontSize: 15,
                    height: 1.7,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 16),
                _StatLine(
                    label: UiStrings.skillCodexMultiplier,
                    value: '${def.powerMultiplier}'),
                _StatLine(
                    label: UiStrings.skillCodexCost,
                    value: '${def.internalForceCost}'),
                _StatLine(
                    label: UiStrings.skillCodexCooldown,
                    value: '${def.cooldownTurns}'),
                _StatLine(
                  label: UiStrings.skillCodexSource,
                  value: labelForMartialGroupKind(martialSourceKindOf(def)),
                ),
                if (belong != null)
                  _StatLine(
                      label: UiStrings.skillCodexBelongTo, value: belong),
                _StatLine(
                  label: UiStrings.skillCodexProficiencyPrefix,
                  value: maxStage == null
                      ? UiStrings.skillCodexProficiencyNone
                      : UiStrings.cangjingProficiencyStageName(maxStage!.id),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatLine extends StatelessWidget {
  const _StatLine({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Text(label,
              style: const TextStyle(color: WuxiaUi.muted, fontSize: 13)),
          const SizedBox(width: 12),
          Text(value,
              style: const TextStyle(
                  color: WuxiaUi.ink, fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

/// 类型标(水墨小章):绛红描边 + 墨字。
class _TypeTag extends StatelessWidget {
  const _TypeTag({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          border: Border.all(color: WuxiaUi.jiang, width: 1),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: WuxiaUi.jiang,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
      ),
    );
  }
}
```

> 注：`UiStrings.cangjingProficiencyStageName(String)` 已存在(skill_proficiency_row.dart:64 `UiStrings.cangjingProficiencyStageName(stage.id)`)；来源标复用 `labelForMartialGroupKind(martialSourceKindOf(def))`(与 tab 段标同源,防漂移)。`SkillProficiencyStageConfig` 在 `numbers_config.dart`(已 import)。

- [ ] **Step 4: 运行验证通过 + analyze**

Run: `flutter test test/features/baike/presentation/martial_arts_tab_test.dart && flutter analyze 2>&1 | tail -3`
Expected: 全 PASS + `No issues found`。

- [ ] **Step 5: 提交**

```bash
git add lib/features/baike/presentation/skill_codex_detail_screen.dart test/features/baike/presentation/martial_arts_tab_test.dart
git commit -m "feat: 藏经阁2.0 Task7 详情屏(同步:类型标+description+数值+所属心法+熟练阶)"
```

---

### Task 8: baike 第5 tab 接线 + baike_screen_test

**Files:**
- Modify: `lib/features/baike/presentation/baike_screen.dart`（`:30` length / `:44-49` tabs / `:52-59` children）
- Modify: `test/features/baike/presentation/baike_screen_test.dart`

- [ ] **Step 1: 改 baike_screen.dart 三处**

`:30` `length: 4` → `length: 5`。
import 段加 `import 'martial_arts_tab.dart';`。
`:48` `Tab(text: UiStrings.baikeTabEncounter),` 后加：
```dart
                Tab(text: UiStrings.baikeTabSkills),
```
`:57` `EncounterTab(),` 后加：
```dart
              MartialArtsTab(),
```

- [ ] **Step 2: 改 baike_screen_test 补第5 tab 断言**

在现有「4 tab 渲染」testWidgets 内 `expect(find.text(UiStrings.baikeTabEncounter), findsOneWidget);` 后加：
```dart
    expect(find.text(UiStrings.baikeTabSkills), findsOneWidget);
```
并把测试描述 `4 tab` 改 `5 tab`，`DefaultTabController length` 相关断言(若有)4→5。

- [ ] **Step 3: 运行验证**

Run: `flutter test test/features/baike/presentation/baike_screen_test.dart && flutter analyze 2>&1 | tail -3`
Expected: PASS + `No issues found`。

- [ ] **Step 4: 提交**

```bash
git add lib/features/baike/presentation/baike_screen.dart test/features/baike/presentation/baike_screen_test.dart
git commit -m "feat: 藏经阁2.0 Task8 baike 第5 tab 接线 + 测试断言"
```

---

### Task 9: VISUAL_ROUTE 双路由

**Files:**
- Modify: `lib/features/debug/application/visual_route.dart`（`encounterCodexDetail` 后追加2 enum 值）
- Modify: `lib/features/debug/presentation/visual_route_host.dart`（追加2 case + 2 helper）

- [ ] **Step 1: visual_route.dart 加2 enum 值**（照 `encounterCodex`/`encounterCodexDetail` 体例）

```dart
  skillCodex(
    'skill_codex',
    '武学图鉴 tab 目检·混态(点亮+剪影按来源5组+心法小节+进度)',
  ),
  skillCodexDetail(
    'skill_codex_detail',
    '武学详情屏目检·同步显招名+description+数值+所属心法+熟练阶',
  ),
```

- [ ] **Step 2: visual_route_host.dart 加 case + helper**（先 Read `_buildEncounterCodexVisual` 真实实现照搬结构）

```dart
// switch 内 encounterCodexDetail case 后:
      case VisualRoute.skillCodex:
        return _buildSkillCodexVisual();
      case VisualRoute.skillCodexDetail:
        return _buildSkillCodexDetailVisual();
```

```dart
// helper(混态:收录池前若干招点亮 + 其余剪影,直 override provider):
  Widget _buildSkillCodexVisual() {
    final repo = GameRepository.instance;
    final pool = repo.skillDefs.values.where(isMartialCodexSkill).toList();
    final litIds = pool.take(6).map((d) => d.id).toSet(); // 混态:前6点亮
    final groups = groupMartialSkills(
      pool: pool,
      litIds: litIds,
      stageById: const {},
      techDefsById: repo.techniqueDefs,
    );
    return ProviderScope(
      overrides: [martialCodexProvider.overrideWith((ref) async => groups)],
      child: const Scaffold(body: MartialArtsTab()),
    );
  }

  Widget _buildSkillCodexDetailVisual() {
    final pool = GameRepository.instance.skillDefs.values
        .where(isMartialCodexSkill)
        .toList();
    return SkillCodexDetailScreen(def: pool.first, maxStage: null);
  }
```

visual_route_host.dart import 段加 `martial_codex_provider.dart` + `martial_arts_tab.dart` + `skill_codex_detail_screen.dart`（若 `GameRepository`/`ProviderScope` 未 import 则补）。

- [ ] **Step 3: analyze**

Run: `flutter analyze 2>&1 | tail -3`
Expected: `No issues found`。

- [ ] **Step 4: 提交**

```bash
git add lib/features/debug/application/visual_route.dart lib/features/debug/presentation/visual_route_host.dart
git commit -m "feat: 藏经阁2.0 Task9 VISUAL_ROUTE 双路由(skill_codex + detail)"
```

---

### Task 10: 全量回归 + 红线自检

**Files:** 无新增（验证 + 清理占位）

- [ ] **Step 1: 占位/TODO 扫描**

Run: `grep -rnE "TODO|FIXME|占位|placeholder" lib/features/baike/presentation/martial_arts_tab.dart lib/features/baike/presentation/skill_codex_detail_screen.dart lib/features/baike/application/martial_codex_provider.dart`
Expected: 无输出（本批新文件无遗留占位）。

- [ ] **Step 2: 全量测试 + analyze**

Run: `flutter test 2>&1 | tail -5 && flutter analyze 2>&1 | tail -3`
Expected: 全绿(基线 2800+1skip → 预期净增约 +12~15 测，0 失败) + `No issues found`。

- [ ] **Step 3: 红线自检**（逐条核，不通过则回修）

```
[ ] 零 saveVer 改:grep "_currentSaveVersion" lib/data/isar_setup.dart 仍 '0.27.0'
[ ] 零新 collection:无 @collection 新增(grep 本批 diff 无 @collection)
[ ] 零数值改:无 numbers.yaml / *.yaml 数值改动
[ ] 无散写中文:lib/features/baike/ 新文件中文仅在 UiStrings 引用,详情屏 flavor 走 def.description
[ ] §5.7:剪影行只显 ??? + 「尚未习得」,不泄来源/解锁条件
[ ] 空态守:全未点亮→空提示不甩剪影墙(martial_arts_tab_test 已覆盖)
[ ] DRY:收录过滤 isMartialCodexSkill 单一真相源;段标 labelForMartialGroupKind / 归类 martialSourceKindOf 单一真相源(无双份)
[ ] 收录数验证:运行临时探针确认收录池=205(心法147+真解6+残页9+破招3+奇遇40)
```

收录数探针（临时，验证后删）：
```bash
# 在 martial_codex_provider_test.dart 临时加,确认数后删:
# test('收录池总数=205(配置基线)', () { ... 见下 });
```
或直接 grep 统计：
```bash
echo "收录池预期205 = 心法147+真解6+残页9+破招3+奇遇40"
grep -c 'source: technique' data/skills.yaml   # 期望 147
grep -c 'source: mainline_drop' data/skills.yaml # 期望 6
grep -c 'source: fragment' data/skills.yaml      # 期望 9
grep -cE 'canInterrupt: true' data/skills.yaml   # 期望 3(破招)
grep -cE '^\s*-?\s*id:' data/encounter_skills.yaml # 期望 40
```

- [ ] **Step 4: 更新 PROGRESS.md**（续41 · P4 子项6 闭环 + P4 全6子项达成）

- [ ] **Step 5: 最终提交**

```bash
git add PROGRESS.md
git commit -m "docs: 藏经阁2.0(P4子项6)闭环 PROGRESS 续41 + P4长期档案全6子项达成"
```

---

## 执行顺序提示

- **Task 6 ↔ Task 7 互引**（tab→detail）：建议合并执行或先建 Task7 detail 文件再回跑 Task6 analyze。
- **Task 4 build_runner**：worktree fresh checkout 需先确认 `libisar.dylib` 完整 + `dart run build_runner build`（`.g.dart` gitignored）。
- 每 Task implementer 跑**全项目** `flutter analyze`（不只自己测试文件，防跨文件 required 签名回归）。

## Self-Review 覆盖核对

| spec 要求 | 对应 Task |
|---|---|
| 收录池205(含破招/排轻功joint) | T1 `isMartialCodexSkill` |
| 三套点亮口径 | T2 `litSkillIds` |
| 全队最高熟练度 | T2 `maxUsesOf` + T4 provider |
| 来源分5组+心法小节 | T3 `groupMartialSkills` |
| 防双份漂移(归类/段标共享) | T1 `martialSourceKindOf` + T6 `labelForMartialGroupKind` |
| @riverpod 派生 provider | T4 |
| UiStrings 段标/进度/剪影 | T5 |
| tab 剪影藏名+空态§5.7 | T6 |
| 详情屏同步派生 | T7 |
| baike 第5 tab + 测试 | T8 |
| VISUAL_ROUTE 双路由 | T9 |
| 红线自检(零saveVer/collection/数值) | T10 |
