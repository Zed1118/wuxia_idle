import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../data/isar_provider.dart';
import 'dispel_service.dart';

part 'dispel_service_providers.g.dart';

/// [DispelService] provider(Phase 5 #3 第 5 批 I 任务从 isar_provider 抽离)。
///
/// 沿 nullable propagation 链:isar 为 null 时 service 也为 null,widget 端
/// `service == null` 短路返回。理由参考 equipment_service_providers.dart
/// (基础设施层不反向 import 应用层)。
@riverpod
DispelService? dispelService(Ref ref) {
  final isarInstance = ref.watch(isarProvider);
  return isarInstance == null ? null : DispelService(isar: isarInstance);
}
