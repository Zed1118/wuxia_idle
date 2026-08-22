import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../combat_shared/application/combat_content_providers.dart';
import '../../../data/isar_setup.dart';
import '../../../data/defs/sweep_readiness.dart';
import 'sweep_readiness_service.dart';

final sweepReadinessStatusProvider = FutureProvider<SweepReadinessState>((
  ref,
) async {
  final config = ref.watch(numbersConfigProvider).sweepReadiness;
  return SweepReadinessService(
    isar: IsarSetup.instance,
    config: config,
  ).getStatus();
});
