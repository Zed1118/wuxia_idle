import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/application/character_providers.dart';
import '../../../core/domain/enums.dart';
import '../../../data/game_repository.dart';
import '../../../data/isar_setup.dart';
import '../../../shared/strings.dart';
import '../../../shared/widgets/wuxia_ui/wuxia_ui.dart';
import '../application/seclusion_service_providers.dart';
import '../domain/retreat_session.dart';
import 'retreat_result_screen.dart';

/// 当前存档的活跃闭关 session(无则 null)。
///
/// plain provider(不走 codegen,免 build_runner)。横幅 watch 它响应式显示;
/// guard 读它的 future 判断拦/放。start / complete / 提前出关后
/// `ref.invalidate(activeRetreatSessionProvider)` 刷新。
final activeRetreatSessionProvider =
    FutureProvider.autoDispose<RetreatSession?>((ref) async {
      final svc = ref.watch(seclusionServiceProvider);
      if (svc == null) return null;
      return svc.getActiveSession(IsarSetup.currentSlotId);
    });

/// 出战守卫:闭关进行中拦截战斗入口。
///
/// 无 active session → 直接 [onAllowed]();有 → 弹水墨提示,
/// 「提前出关」走 [completeRetreat](按已挂时长发奖)。
Future<void> guardBattleEntry({
  required BuildContext context,
  required WidgetRef ref,
  required VoidCallback onAllowed,
}) async {
  final session = await ref.read(activeRetreatSessionProvider.future);
  if (session == null) {
    onAllowed();
    return;
  }
  if (!context.mounted) return;
  final endEarly = await showDialog<bool>(
    context: context,
    builder: (ctx) => PaperDialog(
      title: UiStrings.seclusionBattleLockTitle,
      body: const Text(UiStrings.seclusionBattleLockBody),
      actions: [
        PlaqueButton(
          label: UiStrings.seclusionBattleLockStay,
          onTap: () => Navigator.pop(ctx, false),
        ),
        PlaqueButton(
          label: UiStrings.seclusionBattleLockEndEarly,
          primary: true,
          autofocus: true,
          onTap: () => Navigator.pop(ctx, true),
        ),
      ],
    ),
  );
  if (endEarly != true || !context.mounted) return;
  await _endRetreatEarly(context, ref, session);
}

/// 提前出关:completeRetreat(按已挂时长发奖)→ 推 RetreatResultScreen。
Future<void> _endRetreatEarly(
  BuildContext context,
  WidgetRef ref,
  RetreatSession session,
) async {
  final svc = ref.read(seclusionServiceProvider);
  if (svc == null) return;
  final ids = await ref.read(activeCharacterIdsProvider.future);
  final id = ids.isNotEmpty ? ids.first : 1;
  final ch = await ref.read(characterByIdProvider(id).future);
  final result = await svc.completeRetreat(
    session: session,
    characterId: ch?.id ?? id,
    charRealmTier: ch?.realmTier ?? RealmTier.xueTu,
    config: GameRepository.instance.numbers.retreat,
    maps: GameRepository.instance.seclusionMaps,
    now: DateTime.now(),
  );
  ref.invalidate(activeRetreatSessionProvider);
  if (!context.mounted) return;
  final mapDef = GameRepository.instance.getSeclusionMap(session.mapType);
  await Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => RetreatResultScreen(mapDef: mapDef, result: result),
    ),
  );
}
