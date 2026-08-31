import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/isar_setup.dart';
import '../domain/durable_activity_combat_run.dart';
import 'durable_activity_automation_service.dart';

final durableActivityAutomationServiceProvider =
    Provider<DurableActivityAutomationService?>((ref) {
      final isar = IsarSetup.instanceOrNull;
      return isar == null ? null : DurableActivityAutomationService(isar);
    });

final durableActivityRunProvider =
    FutureProvider.family<DurableActivityCombatRun?, DurableActivityKind>((
      ref,
      kind,
    ) async {
      final service = ref.watch(durableActivityAutomationServiceProvider);
      if (service == null) return null;
      return service.outstandingForKind(kind);
    });
