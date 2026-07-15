import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../data/isar_provider.dart';
import '../domain/expedition_run.dart';
import 'expedition_service.dart';

part 'expedition_providers.g.dart';

/// [ExpeditionService] provider（百草岭远征 · B2.4）。
///
/// 沿 nullable propagation 链（`lineup_providers` 体例）：isar 为 null 时 service
/// 也为 null，widget 端 `service == null` 短路。战斗协作者 [ExpeditionCombatRunner]
/// 有跨节点缓存、按结算次创建，不入 provider（避免陈旧缓存）。
@riverpod
ExpeditionService? expeditionService(Ref ref) {
  final isar = ref.watch(isarProvider);
  return isar == null ? null : ExpeditionService(isar);
}

/// 当前 active 远征（总览/派遣中屏 watch；无远征 → null）。派遣/召回/结算写路径
/// 后由 caller `ref.invalidate(activeExpeditionProvider)` 统一失效。
@riverpod
Future<ExpeditionRun?> activeExpedition(Ref ref) async {
  final service = ref.watch(expeditionServiceProvider);
  if (service == null) return null;
  return service.activeRun();
}
