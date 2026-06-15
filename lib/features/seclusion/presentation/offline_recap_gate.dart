import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/application/character_providers.dart';
import '../../../core/domain/enums.dart';
import '../../../data/game_repository.dart';
import '../application/offline_recap_service.dart';
import 'active_retreat_screen.dart';
import 'offline_recap_card.dart';
import 'seclusion_gate.dart';

/// M2 离线收益汇总「归来」卡启动挂钩。
///
/// 重开（进 HomeFeed 首帧）后调用一次。若有 active 闭关且离开 ≥ 阈值,
/// 弹一次 [OfflineRecapCard]:「前去收功」push [ActiveRetreatScreen]、
/// 「稍后再说」关闭。无 active / 离开不足阈值 → 静默不弹（GDD §5.5 红线
/// 无关：仅把已发生的闭关产出可见化,不发放任何资源、不新增挂机机制）。
///
/// [now] 仅供测试注入确定时间;生产传 null 用 DateTime.now()。
Future<void> maybeShowOfflineRecap({
  required BuildContext context,
  required WidgetRef ref,
  DateTime? now,
}) async {
  final session = await ref.read(activeRetreatSessionProvider.future);
  if (session == null) return;

  final ids = await ref.read(activeCharacterIdsProvider.future);
  final id = ids.isNotEmpty ? ids.first : 1;
  final ch = await ref.read(characterByIdProvider(id).future);
  final realmTier = ch?.realmTier ?? RealmTier.xueTu;

  final recap = OfflineRecapService.buildRecap(
    session: session,
    charRealmTier: realmTier,
    config: GameRepository.instance.numbers.retreat,
    maps: GameRepository.instance.seclusionMaps,
    now: now ?? DateTime.now(),
  );
  if (recap == null || !context.mounted) return;

  await showDialog<void>(
    context: context,
    builder: (ctx) => Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: OfflineRecapCard(
        recap: recap,
        onDismiss: () => Navigator.of(ctx).pop(),
        onGoCollect: () {
          Navigator.of(ctx).pop();
          final mapDef =
              GameRepository.instance.getSeclusionMap(session.mapType);
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => ActiveRetreatScreen(
                session: session,
                mapDef: mapDef,
                characterId: ch?.id ?? id,
                charRealmTier: realmTier,
              ),
            ),
          );
        },
      ),
    ),
  );
}
