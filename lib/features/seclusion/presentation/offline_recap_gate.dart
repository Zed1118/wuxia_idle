import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/application/character_providers.dart';
import '../../../core/domain/enums.dart';
import '../../../data/game_repository.dart';
import '../../../data/isar_setup.dart';
import '../application/offline_passive_service.dart';
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

  if (session != null) {
    // —— 范围 A：有 active 闭关,引导收功（原逻辑原样,与被动互斥）——
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
            final mapDef = GameRepository.instance.getSeclusionMap(
              session.mapType,
            );
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
    return;
  }

  // —— 范围 B：无 active 闭关,按 lastOnlineAt 结算被动 ——
  // Isar 未初始化（如 splash 前 / 纯 widget 测无存档）→ 无可结算基准,静默退。
  final isar = IsarSetup.instanceOrNull;
  if (isar == null) return;
  final save = await IsarSetup.currentSaveData();
  if (save == null) return;

  // 旧档首启不回溯：lastOnlineAt == createdAt 视为基准未建立,置 now 不结算。
  if (save.lastOnlineAt == save.createdAt) {
    await IsarSetup.touchOnlineNow(now: now);
    return;
  }

  final cfg = GameRepository.instance.numbers.passiveIdle;
  final nowDt = now ?? DateTime.now();
  final awayHours = nowDt.difference(save.lastOnlineAt).inSeconds / 3600.0;
  if (awayHours <= 0) return;

  final ids = await ref.read(activeCharacterIdsProvider.future);
  final charId = ids.isNotEmpty ? ids.first : 1;
  final yield_ = await OfflinePassiveService.settle(
    saveDataId: save.slotId,
    characterId: charId,
    awayHours: awayHours,
    now: nowDt,
  );

  if (awayHours < cfg.minRecapHours) return; // 已静默入包,不弹卡
  if ((yield_.mojianshi == 0 && yield_.experience == 0) || !context.mounted) {
    return;
  }
  await showDialog<void>(
    context: context,
    builder: (ctx) => Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: OfflineRecapCard.passive(
        mojianshi: yield_.mojianshi,
        experience: yield_.experience,
        awayHours: awayHours,
        settledHours: yield_.settledHours,
        isCapped: yield_.isCapped,
        onDismiss: () => Navigator.of(ctx).pop(),
      ),
    ),
  );
}
