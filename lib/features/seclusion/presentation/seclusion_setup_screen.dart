import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/game_repository.dart';
import '../../../data/isar_setup.dart';
import '../../../core/domain/enums.dart';
import '../application/seclusion_service_providers.dart';
import '../../../shared/strings.dart';
import '../../../shared/theme/colors.dart';
import '../../../shared/widgets/wuxia_ui/wuxia_ui.dart';
import '../domain/retreat_session.dart';
import '../domain/seclusion_map_def.dart';
import 'active_retreat_screen.dart';

/// 闭关时长选择屏（Phase 3 T49）。
///
/// 显示地图详情（每小时产出估算 × 境界缩放）+ 三档时长按钮。
/// 点击「开始闭关」：abandon 旧 session（若有）→ startRetreat → push ActiveRetreatScreen。
class SeclusionSetupScreen extends ConsumerStatefulWidget {
  final SeclusionMapDef mapDef;
  final RealmTier charRealmTier;
  final int characterId;
  final RetreatSession? existingActiveSession;

  const SeclusionSetupScreen({
    super.key,
    required this.mapDef,
    required this.charRealmTier,
    required this.characterId,
    this.existingActiveSession,
  });

  @override
  ConsumerState<SeclusionSetupScreen> createState() =>
      _SeclusionSetupScreenState();
}

class _SeclusionSetupScreenState extends ConsumerState<SeclusionSetupScreen> {
  int _selectedHours = 4;
  bool _isStarting = false;

  List<int> get _durations =>
      GameRepository.instance.numbers.retreat.durationHours;

  double get _realmScale => GameRepository.instance.numbers.retreat
      .realmScaleFor(widget.charRealmTier);

  Future<void> _startRetreat() async {
    if (_isStarting) return;
    setState(() => _isStarting = true);

    try {
      final svc = ref.read(seclusionServiceProvider);
      if (svc == null) {
        throw StateError('seclusionServiceProvider unavailable (isar null)');
      }
      final session = await svc.startRetreat(
        mapType: widget.mapDef.mapType,
        durationHours: _selectedHours,
        saveDataId: IsarSetup.currentSlotId,
        characterId: widget.characterId,
        charRealmTier: widget.charRealmTier,
        maps: GameRepository.instance.seclusionMaps,
        now: DateTime.now(),
      );

      if (!mounted) return;
      // setup 用 pushReplacement → active 接管路由槽位。后续 active →
      // pushReplacement(result) → result.pop(true) 经 pushReplacement 链
      // 把 true 传回 list 的 push<bool>(setup) future（Flutter Navigator
      // 旧路由 popped 被 chain 到替换路由的 popped）。setup 不能在此处再
      // pop——会误弹 result 让用户看不到结算页。
      await Navigator.of(context).pushReplacement<bool, bool>(
        MaterialPageRoute(
          builder: (_) => ActiveRetreatScreen(
            session: session,
            mapDef: widget.mapDef,
            characterId: widget.characterId,
            charRealmTier: widget.charRealmTier,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(UiStrings.seclusionStartFailed(e))),
      );
      setState(() => _isStarting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final def = widget.mapDef;
    final scale = _realmScale;

    return Scaffold(
      backgroundColor: WuxiaColors.background,
      appBar: AppBar(
        title: Text(def.mapName),
        backgroundColor: WuxiaColors.sidebar,
        foregroundColor: WuxiaColors.textPrimary,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _MapHero(def: def),
              const SizedBox(height: 16),
              PaperPanel(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                child: _OutputPreview(def: def, scale: scale),
              ),
              const SizedBox(height: 18),
              PaperPanel(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SectionHeader(UiStrings.seclusionSetupTitle),
                    const SizedBox(height: 12),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final columns = constraints.maxWidth >= 620 ? 3 : 1;
                        final cardWidth =
                            (constraints.maxWidth - (columns - 1) * 10) /
                            columns;
                        return Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            for (final h in _durations)
                              SizedBox(
                                width: cardWidth,
                                child: _DurationButton(
                                  hours: h,
                                  selected: _selectedHours == h,
                                  scale: scale,
                                  mojianshiPerHour: def.mojianshiPerHour,
                                  onTap: () =>
                                      setState(() => _selectedHours = h),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              Align(
                alignment: Alignment.center,
                child: PlaqueButton(
                  label: _isStarting
                      ? UiStrings.seclusionStarting
                      : UiStrings.seclusionSetupStartButton,
                  primary: true,
                  disabled: _isStarting,
                  onTap: _startRetreat,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MapHero extends StatelessWidget {
  const _MapHero({required this.def});

  final SeclusionMapDef def;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        height: 210,
        child: Stack(
          fit: StackFit.expand,
          children: [
            _MapImage(path: def.imagePath),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.08),
                    Colors.black.withValues(alpha: 0.68),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 18,
              right: 18,
              bottom: 18,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _HeroSeal(text: UiStrings.seclusionMapAtlasTitle),
                  const SizedBox(height: 8),
                  Text(
                    def.mapName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: WuxiaColors.textPrimary,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MapImage extends StatelessWidget {
  const _MapImage({required this.path});

  final String? path;

  @override
  Widget build(BuildContext context) {
    if (path == null) return _fallback();
    return Image(
      image: ExactAssetImage(path!, bundle: DefaultAssetBundle.of(context)),
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => _fallback(),
    );
  }

  Widget _fallback() {
    return Container(
      color: WuxiaColors.background,
      child: const Icon(Icons.landscape, color: WuxiaColors.textMuted),
    );
  }
}

class _OutputPreview extends StatelessWidget {
  const _OutputPreview({required this.def, required this.scale});

  final SeclusionMapDef def;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(UiStrings.seclusionHourlyPreview(scale)),
        const SizedBox(height: 10),
        _OutputRow(
          label: UiStrings.seclusionOutputMojianshi,
          value: (def.mojianshiPerHour * scale).toStringAsFixed(1),
        ),
        _OutputRow(
          label: UiStrings.seclusionOutputExperience,
          value: (def.experiencePerHour * scale).toStringAsFixed(1),
        ),
        if (def.equipmentDropRate > 1.0)
          const _OutputRow(
            label: UiStrings.seclusionOutputEquipDrop,
            value: '+50%',
          ),
        if (def.techniqueLearnRate > 1.0)
          const _OutputRow(
            label: UiStrings.seclusionOutputTechniqueLearn,
            value: '+50%',
          ),
        if (def.internalForceGrowth > 1.0)
          const _OutputRow(
            label: UiStrings.seclusionOutputInternalForce,
            value: '+50%',
          ),
      ],
    );
  }
}

class _OutputRow extends StatelessWidget {
  final String label;
  final String value;

  const _OutputRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: WuxiaUi.ink2, fontSize: 13),
          ),
          Text(
            value,
            style: const TextStyle(
              color: WuxiaUi.ink,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _DurationButton extends StatelessWidget {
  final int hours;
  final bool selected;
  final double scale;
  final double mojianshiPerHour;
  final VoidCallback onTap;

  const _DurationButton({
    required this.hours,
    required this.selected,
    required this.scale,
    required this.mojianshiPerHour,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final expectedMoji = (mojianshiPerHour * hours * scale).floor();
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        constraints: const BoxConstraints(minHeight: 96),
        padding: const EdgeInsets.fromLTRB(14, 13, 14, 12),
        decoration: BoxDecoration(
          color: selected
              ? WuxiaUi.gold.withValues(alpha: 0.22)
              : WuxiaUi.paper.withValues(alpha: 0.38),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: selected
                ? WuxiaUi.gold
                : WuxiaUi.muted.withValues(alpha: 0.45),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              UiStrings.seclusionStayCardTitle(hours),
              style: TextStyle(
                color: selected ? WuxiaUi.ink : WuxiaUi.ink2,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              UiStrings.seclusionDurationLabel(hours),
              style: TextStyle(
                color: selected ? WuxiaUi.ink : WuxiaUi.muted,
                fontSize: 13,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  selected ? Icons.radio_button_checked : Icons.circle_outlined,
                  size: 16,
                  color: selected ? WuxiaUi.gold : WuxiaUi.muted,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    UiStrings.seclusionEstimatedMojianshi(expectedMoji),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: selected ? WuxiaUi.ink : WuxiaUi.ink2,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroSeal extends StatelessWidget {
  const _HeroSeal({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: WuxiaUi.ink.withValues(alpha: 0.66),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: WuxiaUi.gold.withValues(alpha: 0.78)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Text(
          text,
          style: const TextStyle(
            color: WuxiaColors.textPrimary,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
