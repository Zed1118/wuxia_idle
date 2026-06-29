import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/game_repository.dart';
import '../../../data/isar_setup.dart';
import '../../../core/domain/enums.dart';
import '../application/seclusion_service_providers.dart';
import '../../../shared/strings.dart';
import '../../../shared/theme/colors.dart';
import '../../../shared/widgets/wuxia_ui/wuxia_ui.dart';
import '../../help/domain/help_topic.dart';
import '../../help/presentation/context_help_button.dart';
import '../domain/retreat_session.dart';
import '../domain/seclusion_map_def.dart';
import 'active_retreat_screen.dart';
import 'seclusion_enter_caption.dart';
import 'seclusion_gate.dart';
import 'seclusion_map_visuals.dart';

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
      await showSeclusionEnterCaption(context);
      if (!mounted) return;
      ref.invalidate(activeRetreatSessionProvider);
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
    final compact = MediaQuery.sizeOf(context).height <= 760;

    return Scaffold(
      backgroundColor: WuxiaColors.background,
      appBar: AppBar(
        title: Text(def.mapName),
        backgroundColor: WuxiaColors.sidebar,
        foregroundColor: WuxiaColors.textPrimary,
        actions: const [ContextHelpButton(topic: HelpTopic.seclusion)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(20, compact ? 10 : 16, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _MapHero(def: def, compact: compact),
              SizedBox(height: compact ? 10 : 16),
              PaperPanel(
                padding: EdgeInsets.fromLTRB(
                  16,
                  compact ? 10 : 14,
                  16,
                  compact ? 10 : 14,
                ),
                child: _OutputPreview(def: def, scale: scale),
              ),
              SizedBox(height: compact ? 10 : 18),
              PaperPanel(
                padding: EdgeInsets.fromLTRB(
                  16,
                  compact ? 10 : 14,
                  16,
                  compact ? 8 : 12,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SectionHeader(UiStrings.seclusionSetupTitle),
                    SizedBox(height: compact ? 8 : 12),
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
                                  compact: compact,
                                  mojianshiPerHour: def.mojianshiPerHour,
                                  onTap: () =>
                                      setState(() => _selectedHours = h),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                    SizedBox(height: compact ? 6 : 10),
                    // P1-6:前瞻提示离线最长计入时长(消除「挂久了只算一截」落差)。
                    Text(
                      UiStrings.seclusionCapHint(
                        GameRepository.instance.numbers.retreat.capHours,
                      ),
                      style: const TextStyle(
                        color: WuxiaUi.ink2,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: compact ? 10 : 22),
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
  const _MapHero({required this.def, required this.compact});

  final SeclusionMapDef def;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        height: compact ? 158 : 210,
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
              right: 18,
              top: compact ? 12 : 16,
              child: SeclusionMapTraitIcon(def: def, size: compact ? 40 : 48),
            ),
            Positioned(
              left: 18,
              right: 18,
              bottom: compact ? 12 : 18,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _HeroSeal(text: UiStrings.seclusionMapAtlasTitle),
                  SizedBox(height: compact ? 6 : 8),
                  Text(
                    def.mapName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: WuxiaColors.textPrimary,
                      fontSize: compact ? 24 : 28,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: compact ? 6 : 9),
                  SeclusionMapTraitStrip(def: def),
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
        const SizedBox(height: 6),
        _OutputRow(
          icon: Icons.construction,
          color: WuxiaUi.woodLight,
          label: UiStrings.seclusionOutputMojianshi,
          value: (def.mojianshiPerHour * scale).toStringAsFixed(1),
        ),
        _OutputRow(
          icon: Icons.trending_up,
          color: WuxiaUi.qing,
          label: UiStrings.seclusionOutputExperience,
          value: (def.experiencePerHour * scale).toStringAsFixed(1),
        ),
        if (def.equipmentDropRate > 1.0)
          const _OutputRow(
            icon: Icons.sports_martial_arts,
            color: WuxiaUi.woodLight,
            label: UiStrings.seclusionOutputEquipDrop,
            value: '+50%',
          ),
        if (def.techniqueLearnRate > 1.0)
          const _OutputRow(
            icon: Icons.auto_stories,
            color: WuxiaUi.qing,
            label: UiStrings.seclusionOutputTechniqueLearn,
            value: '+50%',
          ),
        if (def.internalForceGrowth > 1.0)
          const _OutputRow(
            icon: Icons.bolt,
            color: WuxiaColors.internalForce,
            label: UiStrings.seclusionOutputInternalForce,
            value: '+50%',
          ),
      ],
    );
  }
}

class _OutputRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;

  const _OutputRow({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Icon(icon, color: color, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: WuxiaUi.ink2, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
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
  final bool compact;
  final double mojianshiPerHour;
  final VoidCallback onTap;

  const _DurationButton({
    required this.hours,
    required this.selected,
    required this.scale,
    required this.compact,
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
        constraints: BoxConstraints(minHeight: compact ? 76 : 96),
        padding: EdgeInsets.fromLTRB(
          14,
          compact ? 9 : 13,
          14,
          compact ? 9 : 12,
        ),
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
                fontSize: compact ? 15 : 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: compact ? 4 : 8),
            Text(
              UiStrings.seclusionDurationLabel(hours),
              style: TextStyle(
                color: selected ? WuxiaUi.ink : WuxiaUi.muted,
                fontSize: 13,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            SizedBox(height: compact ? 6 : 12),
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
