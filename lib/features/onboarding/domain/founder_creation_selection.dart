import '../../../data/defs/founder_creation_def.dart';
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
