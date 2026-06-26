import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/isar_provider.dart';
import '../domain/save_management_status.dart';
import 'save_management_service.dart';

final saveManagementServiceProvider = Provider<SaveManagementService?>((ref) {
  final isar = ref.watch(isarProvider);
  return isar == null ? null : SaveManagementService(isar: isar);
});

final saveManagementStatusProvider = FutureProvider<SaveManagementStatus>((
  ref,
) async {
  final service = ref.watch(saveManagementServiceProvider);
  if (service == null) {
    throw StateError('Save management requires initialized Isar');
  }
  return service.loadStatus();
});
