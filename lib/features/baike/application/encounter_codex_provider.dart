import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../data/game_repository.dart';
import '../../../shared/strings.dart';
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

/// 奇遇分组归类(节庆优先于 type)。groupEncounters 与详情屏类型标共用,防双份漂移。
EncounterGroupKind encounterGroupKindOf(EncounterDef d) {
  if (d.trigger.festivalRequired != null) return EncounterGroupKind.festival;
  if (d.type == EncounterType.techniqueInsight) return EncounterGroupKind.insight;
  // trial/karma(Phase 2+,当前内容无)暂落奇缘桶,实装时重分类。
  return EncounterGroupKind.fortune;
}

/// 奇遇分组 → 显示名(领悟/奇缘/节庆)。EncounterTab 段标与详情屏类型标共用,防双份漂移。
String labelForEncounterGroupKind(EncounterGroupKind kind) => switch (kind) {
      EncounterGroupKind.insight => UiStrings.encounterCodexGroupInsight,
      EncounterGroupKind.fortune => UiStrings.encounterCodexGroupFortune,
      EncounterGroupKind.festival => UiStrings.encounterCodexGroupFestival,
    };

/// 纯函数：按 type/festivalRequired 分 3 段(节庆优先于 type),算点亮/剪影 + 计数。
/// 空段不产出。段内保 def 输入顺序。
List<EncounterCodexGroup> groupEncounters({
  required List<EncounterDef> defs,
  required Set<String> triggeredIds,
  required Map<String, String> titles,
}) {
  final buckets = <EncounterGroupKind, List<EncounterCodexEntry>>{};
  for (final d in defs) {
    final triggered = triggeredIds.contains(d.id);
    buckets.putIfAbsent(encounterGroupKindOf(d), () => []).add(EncounterCodexEntry(
          def: d,
          isTriggered: triggered,
          title: triggered ? titles[d.id] : null,
        ));
  }
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
  final triggered =
      (progress?.triggeredEncounterIds ?? const <String>[]).toSet();
  final titles = <String, String>{};
  for (final id in triggered) {
    final content = await EncounterEventLoader.load(id);
    final t = content.title;
    if (t != null && t.isNotEmpty) titles[id] = t;
  }
  return groupEncounters(defs: defs, triggeredIds: triggered, titles: titles);
}
