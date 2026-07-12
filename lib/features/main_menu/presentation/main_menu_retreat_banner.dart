import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/application/character_providers.dart';
import '../../../data/game_repository.dart';
import '../../../shared/strings.dart';
import '../../../shared/theme/colors.dart';
import '../../../shared/theme/wuxia_tokens.dart';
import '../../seclusion/application/retreat_settlement_calculator.dart';
import '../../seclusion/domain/retreat_session.dart';
import '../../seclusion/domain/seclusion_map_def.dart';
import '../../seclusion/presentation/active_retreat_screen.dart';
import '../../seclusion/presentation/seclusion_gate.dart';

/// 主菜单顶部常驻闭关横幅（L3 闭关非阻塞）。
///
/// 有 active session 时展示已闭关时长与当前结算阶段。
class MainMenuRetreatBanner extends ConsumerWidget {
  const MainMenuRetreatBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref
        .watch(activeRetreatSessionProvider)
        .maybeWhen(data: (s) => s, orElse: () => null);
    if (session == null) return const SizedBox.shrink();

    final mapDef = GameRepository.instance.getSeclusionMap(session.mapType);
    final cap = GameRepository.instance.numbers.retreat.capHours;
    final elapsed =
        DateTime.now().difference(session.startedAt).inSeconds / 3600.0;
    final split = RetreatSettlementCalculator.splitHours(
      elapsedHours: elapsed,
      fullRateHours: cap.toDouble(),
    );
    final safeElapsed = split.retreatHours + split.passiveHours;
    final retreatHours = split.retreatHours;
    final passiveHours = split.passiveHours;
    final phase = passiveHours > 0
        ? UiStrings.mainMenuRetreatPassivePhase(passiveHours.toStringAsFixed(1))
        : UiStrings.mainMenuRetreatFullRatePhase(
            retreatHours.toStringAsFixed(1),
            cap,
          );

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: () => _openActive(context, ref, session, mapDef),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: WuxiaColors.background.withValues(alpha: 0.78),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: WuxiaUi.gold.withValues(alpha: 0.52)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.28),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.self_improvement,
                  color: WuxiaUi.jiang,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    UiStrings.mainMenuRetreatBannerLine(
                      mapDef.mapName,
                      safeElapsed.toStringAsFixed(1),
                      phase,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: WuxiaUi.jiang,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const Icon(Icons.chevron_right, color: WuxiaUi.jiang, size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openActive(
    BuildContext context,
    WidgetRef ref,
    RetreatSession session,
    SeclusionMapDef mapDef,
  ) async {
    final ids = await ref.read(activeCharacterIdsProvider.future);
    final id = ids.isNotEmpty ? ids.first : 1;
    final ch = await ref.read(characterByIdProvider(id).future);
    if (!context.mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ActiveRetreatScreen(
          session: session,
          mapDef: mapDef,
          characterId: ch?.id ?? id,
        ),
      ),
    );
    ref.invalidate(activeRetreatSessionProvider);
  }
}
