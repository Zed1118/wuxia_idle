import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/application/battle_providers.dart';
import '../../../core/application/character_providers.dart';
import '../../../core/domain/enums.dart';
import '../../../core/domain/skill_usage_entry.dart';
import '../../../core/domain/technique.dart';
import '../../../data/defs/skill_def.dart';
import '../../../data/game_repository.dart';
import '../../../data/numbers_config.dart';
import '../../battle/domain/enum_localizations.dart';
import '../../cultivation/domain/skill_proficiency.dart';
import '../../encounter/application/encounter_service_providers.dart';

part 'martial_codex_provider.g.dart';

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
