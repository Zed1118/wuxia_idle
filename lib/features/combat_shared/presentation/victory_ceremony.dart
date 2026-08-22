import 'package:flutter/material.dart';

import '../../../core/domain/character.dart';
import '../../../core/domain/enums.dart';
import '../../../shared/battle_shared/enum_localizations.dart' show EnumL10n;
import '../../../shared/strings.dart';
import '../../../shared/theme/colors.dart';
import '../../../shared/widgets/wuxia_image.dart';
import '../../../shared/widgets/wuxia_ui/wuxia_ui.dart';
import '../../equipment/application/drop_service.dart';
import '../../equipment/presentation/treasure_drop_overlay.dart';
import 'hero_camera_overlay.dart';

/// Engine-neutral hero camera derivation for Phase 0A settlement snapshots.
HeroCameraData? deriveHeroCameraDataFromDamageTotals({
  required Map<int, int> damageByCharacterId,
  required List<Character> characters,
  required String bossName,
}) {
  Character? hero;
  var topDamage = -1;
  for (final character in characters) {
    final damage = damageByCharacterId[character.id];
    if (damage == null) continue;
    if (hero == null || damage > topDamage) {
      hero = character;
      topDamage = damage;
    }
  }
  if (hero == null) return null;
  return HeroCameraData(
    portraitPath: hero.portraitPath,
    heroName: hero.name,
    realmLabel: EnumL10n.realmTier(hero.realmTier),
    bossName: bossName,
    topDamage: topDamage,
  );
}

/// 简版「勝」淡入淡出(时序重排 spec 2026-06-12)。
///
/// 普通/无掉落档的胜利仪式:印章符 + 「勝」题字,淡入→停→淡出 ~800ms 自动消失
/// (不拦点击 / 无统计 / 无按钮)。爆品档不走此 widget,走 TreasureDropOverlay。
/// 点击可提前跳过。
class VictorySealFlash extends StatefulWidget {
  final VoidCallback onDone;
  const VictorySealFlash({super.key, required this.onDone});

  @override
  State<VictorySealFlash> createState() => _VictorySealFlashState();
}

class _VictorySealFlashState extends State<VictorySealFlash>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _ctrl =
        AnimationController(
            vsync: this,
            duration: const Duration(milliseconds: 1600),
          )
          ..addStatusListener((s) {
            if (s == AnimationStatus.completed) _finish();
          })
          ..forward();
  }

  void _finish() {
    if (_done) return;
    _done = true;
    widget.onDone();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  double _opacity(double t) {
    if (t < 0.3) return (t / 0.3).clamp(0.0, 1.0);
    if (t > 0.7) return (1 - (t - 0.7) / 0.3).clamp(0.0, 1.0);
    return 1.0;
  }

  @override
  Widget build(BuildContext context) {
    return DismissLayer(
      onDismiss: _finish,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, child) {
          return Opacity(
            opacity: _opacity(_ctrl.value),
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  radius: 0.9,
                  colors: [Color(0x33000000), Color(0xCC000000)],
                  stops: [0.45, 1.0],
                ),
              ),
              alignment: Alignment.center,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Transform.rotate(
                    angle: -0.08,
                    child: SizedBox(
                      width: 38,
                      height: 38,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          WuxiaImage(
                            WuxiaUi.ceremonyRedSeal,
                            fit: BoxFit.contain,
                            errorBuilder: (_, e, s) => DecoratedBox(
                              decoration: BoxDecoration(
                                color: WuxiaColors.gangMeng,
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                          ),
                          const Text(
                            UiStrings.sealGlyph,
                            style: TextStyle(
                              color: WuxiaColors.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    UiStrings.victoryTitle,
                    style: TextStyle(
                      color: Color(0xFFB9974E),
                      fontSize: 76,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          blurRadius: 9,
                          color: Color(0xCC000000),
                          offset: Offset(2, 3),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// 弹简版勝 overlay 并 await 至消失(自动 ~800ms 或点击跳过)。
Future<void> showVictorySealFlash(BuildContext context) async {
  if (!context.mounted) return;
  await showGeneralDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.transparent,
    transitionDuration: Duration.zero,
    pageBuilder: (ctx, a, b) =>
        VictorySealFlash(onDone: () => Navigator.of(ctx).pop()),
  );
}

/// 英雄镜头 gate:仅 Boss 首胜且有出镜数据时弹。
bool shouldShowHeroCamera({
  required bool isBoss,
  required bool isFirstClear,
  required HeroCameraData? data,
}) => isBoss && isFirstClear && data != null;

/// 弹英雄镜头并 await 至消失(numbers hold_seconds 或点击跳过)。Boss 首胜调用。
Future<void> presentHeroCamera(
  BuildContext context,
  HeroCameraData data,
) async {
  if (!context.mounted) return;
  await showGeneralDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.transparent,
    transitionDuration: Duration.zero,
    pageBuilder: (ctx, _, _) => HeroCameraOverlay(
      data: data,
      onDone: () => Navigator.of(ctx).maybePop(),
    ),
  );
}

/// 战斗胜利仪式分档(时序重排 spec 2026-06-12):
/// 有 ≥重器爆品(或 extraDisplayTiers 内首次获得) → 爆品镜头(印章盖落即胜利宣告,含 reward 音);
/// 否则(普通掉落 / 无掉落 / 塔重打) → 简版勝淡入淡出。
/// mainline / tower 两 flow 共用。[treasureGate]=false(塔重打)→ 必走简版勝。
/// [extraDisplayTiers]:额外允许展示的 tier 集合(如利器首次获得,由 flow 层计算传入)。
Future<void> presentVictoryCeremony(
  BuildContext context,
  DropResult drops, {
  required bool treasureGate,
  Set<EquipmentTier> extraDisplayTiers = const {},
}) async {
  final playedTreasure = await playTreasureDropIfAny(
    context,
    drops,
    gate: treasureGate,
    extraDisplayTiers: extraDisplayTiers,
  );
  if (playedTreasure) return;
  if (!context.mounted) return;
  await showVictorySealFlash(context);
}
