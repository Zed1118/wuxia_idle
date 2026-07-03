import '../../../data/defs/founder_creation_def.dart';
import '../../../data/defs/founder_names_def.dart';
import '../../../shared/utils/rng.dart';

class FounderCreationSelection {
  final FounderSchoolOption school;
  final FounderOriginOption origin;
  final FounderFateOption fate;

  const FounderCreationSelection({
    required this.school,
    required this.origin,
    required this.fate,
  });
}

List<FounderFateOption> generateFounderFateChoices({
  required FounderCreationConfig config,
  required Rng rng,
  int count = 3,
}) {
  if (config.fatePool.length <= count) {
    return config.fatePool.take(count).toList(growable: false);
  }
  final pool = [...config.fatePool];
  final out = <FounderFateOption>[];
  while (out.length < count && pool.isNotEmpty) {
    out.add(pool.removeAt(rng.nextInt(pool.length)));
  }
  return out;
}

/// 随机祖师名（姓 + 名）。空池返回空串，由 UI 侧决定不填。
String generateFounderName(FounderNamesConfig config, Rng rng) {
  if (config.founderSurnames.isEmpty || config.founderGiven.isEmpty) return '';
  final surname =
      config.founderSurnames[rng.nextInt(config.founderSurnames.length)];
  final given = config.founderGiven[rng.nextInt(config.founderGiven.length)];
  return '$surname$given';
}

/// 随机门派名（前缀 + 后缀）。空池返回空串。
String generateSectName(FounderNamesConfig config, Rng rng) {
  if (config.sectPrefixes.isEmpty || config.sectSuffixes.isEmpty) return '';
  final prefix = config.sectPrefixes[rng.nextInt(config.sectPrefixes.length)];
  final suffix = config.sectSuffixes[rng.nextInt(config.sectSuffixes.length)];
  return '$prefix$suffix';
}
