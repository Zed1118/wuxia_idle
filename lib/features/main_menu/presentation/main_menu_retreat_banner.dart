import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/application/character_providers.dart';
import '../../../core/domain/enums.dart';
import '../../../data/game_repository.dart';
import '../../../shared/strings.dart';
import '../../../shared/theme/wuxia_tokens.dart';
import '../../seclusion/domain/retreat_session.dart';
import '../../seclusion/domain/seclusion_map_def.dart';
import '../../seclusion/presentation/active_retreat_screen.dart';
import '../../seclusion/presentation/seclusion_gate.dart';

/// 主菜单顶部常驻闭关横幅（L3 闭关非阻塞）。
///
/// 有 active session → 显「闭关中 · {地图} · 剩 {时长}」,点击回 ActiveRetreatScreen;
/// 无 → SizedBox.shrink()。剩余时间为打开时快照（无实时 Timer）。
class MainMenuRetreatBanner extends ConsumerWidget {
  const MainMenuRetreatBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref
        .watch(activeRetreatSessionProvider)
        .maybeWhen(data: (s) => s, orElse: () => null);
    if (session == null) return const SizedBox.shrink();

    final mapDef = GameRepository.instance.getSeclusionMap(session.mapType);
    final plannedMin = session.durationHours * 60;
    final capMin = (GameRepository.instance.numbers.retreat.capHours * 60)
        .round();
    final elapsedMin = DateTime.now().difference(session.startedAt).inMinutes;
    final remainingMin = (plannedMin - elapsedMin).clamp(0, plannedMin);
    final remaining = UiStrings.retreatRemainingText(
      remainingMin ~/ 60,
      remainingMin % 60,
    );
    final isCapped = capMin <= plannedMin && elapsedMin >= capMin;

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
              color: WuxiaUi.jiang.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: WuxiaUi.jiang.withValues(alpha: 0.52)),
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
                    isCapped
                        ? UiStrings.mainMenuRetreatBannerCappedLine(
                            mapDef.mapName,
                          )
                        : UiStrings.mainMenuRetreatBannerLine(
                            mapDef.mapName,
                            remaining,
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
          charRealmTier: ch?.realmTier ?? RealmTier.xueTu,
        ),
      ),
    );
    ref.invalidate(activeRetreatSessionProvider);
  }
}
