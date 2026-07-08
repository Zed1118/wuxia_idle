import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/application/battle_providers.dart';
import '../../../data/isar_setup.dart';
import '../domain/sweep_readiness.dart';
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
