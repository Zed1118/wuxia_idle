import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/domain/enums.dart';
import '../../../data/defs/stage_def.dart';
import '../../../shared/strings.dart';
import '../../../shared/theme/colors.dart';
import '../../../shared/widgets/portrait_frame.dart';
import '../../../shared/widgets/wuxia_ui/wuxia_ui.dart';
import '../../battle/domain/enum_localizations.dart';
import '../application/gauntlet_providers.dart';
import '../../../data/defs/boss_gauntlet_config.dart';
import 'gauntlet_entry_flow.dart';

/// 断魂庄装载屏（§7.1 · C2.5）。断魂帖库存 / 庄中三关（三 Boss + 推荐境界）/ 择人
/// 1-3（非祖师·已修主修）/ 补给装载（≤3 份托管）/ 持帖入庄。
///
/// 入庄写路径经 [GauntletService.enter] 单事务（屏内零直接 Isar 写），成功后 invalidate
/// active/candidates/loadoutInfo provider，随即 push [runGauntletFlow] 逐关战斗流
/// （#1 wiring Task 5）；流程终局（选奖 / 离庄 / 认输）返回后 pop 本屏回主菜单。config
/// 经 [gauntletConfigProvider] watch（非构造期读单例，避 async-config-race）。
class GauntletLoadoutScreen extends ConsumerStatefulWidget {
  const GauntletLoadoutScreen({super.key});

  @override
  ConsumerState<GauntletLoadoutScreen> createState() =>
      _GauntletLoadoutScreenState();
}

class _GauntletLoadoutScreenState extends ConsumerState<GauntletLoadoutScreen> {
  static const int _supplyCap = 3;

  final Set<int> _selected = {};
  final Map<String, int> _supplyLoad = {}; // defId → 装载份数
  bool _submitting = false;

  int get _loadedTotal => _supplyLoad.values.fold(0, (a, b) => a + b);

  Future<void> _enter(int ticketCount) async {
    if (_selected.isEmpty || _submitting || ticketCount < 1) return;
    final service = ref.read(gauntletServiceProvider);
    if (service == null) return; // 测试旁路：未 init Isar
    setState(() => _submitting = true);
    try {
      await service.enter(
        characterIds: _selected.toList(),
        supplies: {
          for (final e in _supplyLoad.entries)
            if (e.value > 0) e.key: e.value,
        },
        supplyCap: _supplyCap,
      );
      if (!mounted) return;
      ref.invalidate(activeGauntletProvider);
      ref.invalidate(gauntletCandidatesProvider);
      ref.invalidate(gauntletLoadoutInfoProvider);
      // 入庄成功 → 逐关战斗流（#1 wiring Task 5）；终局（选奖 / 离庄 / 认输）返回后
      // pop 本屏回主菜单（镜像 tower 花名册 → runTowerFlow）。
      await runGauntletFlow(context: context, ref: ref);
      if (!mounted) return;
      Navigator.of(context).maybePop();
    } on StateError {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(UiStrings.gauntletEnterFailed)),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final candidatesAsync = ref.watch(gauntletCandidatesProvider);
    final infoAsync = ref.watch(gauntletLoadoutInfoProvider);
    final config = ref.watch(gauntletConfigProvider);

    return Scaffold(
      backgroundColor: WuxiaColors.background,
      appBar: AppBar(
        backgroundColor: WuxiaColors.sidebar,
        foregroundColor: WuxiaColors.textPrimary,
        title: const Text(UiStrings.gauntletLoadoutTitle),
        leading: Navigator.of(context).canPop()
            ? BackButton(onPressed: () => Navigator.of(context).pop())
            : null,
      ),
      body: SafeArea(
        child: candidatesAsync.when(
          loading: () => const Center(child: InkLoadingIndicator()),
          error: (e, _) => ErrorFallback(
            error: e,
            onRetry: () => ref.invalidate(gauntletCandidatesProvider),
          ),
          data: (candidates) => infoAsync.when(
            loading: () => const Center(child: InkLoadingIndicator()),
            error: (e, _) => ErrorFallback(
              error: e,
              onRetry: () => ref.invalidate(gauntletLoadoutInfoProvider),
            ),
            data: (info) => _buildBody(candidates, info, config),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(
    List<GauntletCandidate> candidates,
    GauntletLoadoutInfo info,
    BossGauntletConfig? config,
  ) {
    // 防御：清掉已不可入庄的旧选择。
    final selectableIds = {
      for (final c in candidates)
        if (c.selectable) c.character.id,
    };
    _selected.removeWhere((id) => !selectableIds.contains(id));
    // 防御：装载不超库存（库存刷新后可能变少）。
    for (final s in info.supplies) {
      final loaded = _supplyLoad[s.defId] ?? 0;
      if (loaded > s.owned) _supplyLoad[s.defId] = s.owned;
    }

    final hasTicket = info.ticketCount >= 1;
    final canEnter = _selected.isNotEmpty && hasTicket && !_submitting;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 860),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _GauntletHeader(),
              const SizedBox(height: 14),
              _TicketBadge(count: info.ticketCount),
              const SizedBox(height: 18),
              const _SectionLabel(UiStrings.gauntletEnemiesSection),
              const SizedBox(height: 8),
              if (config != null) _EnemyList(config: config),
              const SizedBox(height: 18),
              const _SectionLabel(UiStrings.gauntletTeamSection),
              const SizedBox(height: 4),
              const Text(
                UiStrings.gauntletTeamHint,
                style: TextStyle(color: WuxiaColors.textMuted, fontSize: 12),
              ),
              const SizedBox(height: 10),
              if (candidates.isEmpty)
                const _EmptyCandidates()
              else
                for (final c in candidates) ...[
                  _CandidateTile(
                    candidate: c,
                    selected: _selected.contains(c.character.id),
                    onTap: c.selectable
                        ? () => setState(() {
                            final id = c.character.id;
                            if (_selected.contains(id)) {
                              _selected.remove(id);
                            } else if (_selected.length < 3) {
                              _selected.add(id);
                            }
                          })
                        : null,
                  ),
                  const SizedBox(height: 8),
                ],
              const SizedBox(height: 2),
              Text(
                UiStrings.gauntletSelectedCount(_selected.length),
                style: const TextStyle(
                  color: WuxiaColors.textSecondary,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 18),
              const _SectionLabel(UiStrings.gauntletSupplySection),
              const SizedBox(height: 4),
              Text(
                UiStrings.gauntletSupplyHint(_supplyCap),
                style: const TextStyle(
                  color: WuxiaColors.textMuted,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 10),
              for (final s in info.supplies) ...[
                _SupplyStepper(
                  option: s,
                  loaded: _supplyLoad[s.defId] ?? 0,
                  canAdd:
                      _loadedTotal < _supplyCap &&
                      (_supplyLoad[s.defId] ?? 0) < s.owned,
                  onAdd: () => setState(
                    () =>
                        _supplyLoad[s.defId] = (_supplyLoad[s.defId] ?? 0) + 1,
                  ),
                  onRemove: () => setState(() {
                    final v = (_supplyLoad[s.defId] ?? 0) - 1;
                    if (v <= 0) {
                      _supplyLoad.remove(s.defId);
                    } else {
                      _supplyLoad[s.defId] = v;
                    }
                  }),
                ),
                const SizedBox(height: 8),
              ],
              Text(
                UiStrings.gauntletSupplyBudget(_loadedTotal, _supplyCap),
                style: const TextStyle(
                  color: WuxiaColors.textSecondary,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 18),
              if (!hasTicket)
                const Padding(
                  padding: EdgeInsets.only(bottom: 10),
                  child: Text(
                    UiStrings.gauntletNoTicketHint,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: WuxiaColors.internalForce,
                      fontSize: 12,
                    ),
                  ),
                ),
              Align(
                alignment: Alignment.center,
                child: PlaqueButton(
                  label: UiStrings.gauntletEnterButton,
                  primary: true,
                  onTap: canEnter ? () => _enter(info.ticketCount) : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── 敌队展示（三关 Boss + 推荐境界）─────────────────────────────────────────

class _EnemyList extends StatelessWidget {
  const _EnemyList({required this.config});

  final BossGauntletConfig config;

  @override
  Widget build(BuildContext context) {
    final bosses = <EnemyDef>[];
    for (final stage in config.stages) {
      final team = config.enemiesForTeam(stage.enemyTeamId);
      if (team.isEmpty) continue;
      bosses.add(team.firstWhere((e) => e.isBoss, orElse: () => team.first));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < bosses.length; i++) ...[
          _EnemyTile(ordinal: i + 1, enemy: bosses[i]),
          const SizedBox(height: 8),
        ],
        if (bosses.isNotEmpty)
          Text(
            UiStrings.gauntletRecommendedRealm(
              EnumL10n.realm(bosses.last.realmTier, bosses.last.realmLayer),
            ),
            style: const TextStyle(
              color: WuxiaUi.gold,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
      ],
    );
  }
}

class _EnemyTile extends StatelessWidget {
  const _EnemyTile({required this.ordinal, required this.enemy});

  final int ordinal;
  final EnemyDef enemy;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: WuxiaColors.panel,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: WuxiaColors.border),
      ),
      child: Row(
        children: [
          _StageBadge(ordinal: ordinal),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              enemy.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: WuxiaColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            '${EnumL10n.realm(enemy.realmTier, enemy.realmLayer)} · ${EnumL10n.school(enemy.school)}',
            style: const TextStyle(
              color: WuxiaColors.textSecondary,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _StageBadge extends StatelessWidget {
  const _StageBadge({required this.ordinal});

  final int ordinal;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: WuxiaUi.gold.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: WuxiaUi.gold.withValues(alpha: 0.5)),
      ),
      child: Text(
        UiStrings.gauntletStageOrdinal(ordinal),
        style: const TextStyle(
          color: WuxiaUi.gold,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ── 断魂帖徽标 ──────────────────────────────────────────────────────────────

class _TicketBadge extends StatelessWidget {
  const _TicketBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(
          Icons.confirmation_num_outlined,
          color: WuxiaUi.gold,
          size: 18,
        ),
        const SizedBox(width: 8),
        Text(
          UiStrings.gauntletTicket(count),
          style: const TextStyle(
            color: WuxiaColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

// ── 候选门人 tile ───────────────────────────────────────────────────────────

class _CandidateTile extends StatelessWidget {
  const _CandidateTile({
    required this.candidate,
    required this.selected,
    required this.onTap,
  });

  final GauntletCandidate candidate;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = candidate.character;
    final dim = !candidate.selectable;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: WuxiaColors.panel.withValues(alpha: dim ? 0.55 : 1),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: selected
                ? WuxiaUi.gold
                : WuxiaColors.border.withValues(alpha: dim ? 0.5 : 1),
            width: selected ? 1.6 : 1,
          ),
        ),
        child: Row(
          children: [
            PortraitFrame(
              portraitPath: c.portraitPath,
              size: 40,
              borderColor: _schoolColor(c.school),
              placeholderText: c.name,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    c.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: dim
                          ? WuxiaColors.textMuted
                          : WuxiaColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    c.school == null
                        ? EnumL10n.realm(c.realmTier, c.realmLayer)
                        : '${EnumL10n.realm(c.realmTier, c.realmLayer)} · ${EnumL10n.school(c.school!)}',
                    style: const TextStyle(
                      color: WuxiaColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            if (candidate.occupied) ...[
              const SizedBox(width: 8),
              const _Tag(
                UiStrings.gauntletCandidateOccupiedTag,
                color: WuxiaColors.internalForce,
              ),
            ],
            if (!candidate.hasMainTechnique) ...[
              const SizedBox(width: 4),
              const _Tag(
                UiStrings.gauntletCandidateNoMainTag,
                color: WuxiaColors.textMuted,
              ),
            ],
            if (selected) ...[
              const SizedBox(width: 8),
              const Icon(Icons.check_circle, color: WuxiaUi.gold, size: 20),
            ],
          ],
        ),
      ),
    );
  }
}

// ── 补给装载步进 ────────────────────────────────────────────────────────────

class _SupplyStepper extends StatelessWidget {
  const _SupplyStepper({
    required this.option,
    required this.loaded,
    required this.canAdd,
    required this.onAdd,
    required this.onRemove,
  });

  final GauntletSupplyOption option;
  final int loaded;
  final bool canAdd;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: WuxiaColors.panel,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: WuxiaColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  option.name,
                  style: const TextStyle(
                    color: WuxiaColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  UiStrings.gauntletSupplyOwned(option.owned),
                  style: const TextStyle(
                    color: WuxiaColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          _StepButton(icon: Icons.remove, onTap: loaded > 0 ? onRemove : null),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              '$loaded',
              style: const TextStyle(
                color: WuxiaColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          _StepButton(icon: Icons.add, onTap: canAdd ? onAdd : null),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: enabled
                ? WuxiaUi.gold.withValues(alpha: 0.6)
                : WuxiaColors.border,
          ),
        ),
        child: Icon(
          icon,
          size: 18,
          color: enabled ? WuxiaUi.gold : WuxiaColors.textMuted,
        ),
      ),
    );
  }
}

// ── 共用小组件 ──────────────────────────────────────────────────────────────

class _GauntletHeader extends StatelessWidget {
  const _GauntletHeader();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          UiStrings.gauntletName,
          style: TextStyle(
            color: WuxiaColors.textPrimary,
            fontSize: 22,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
          ),
        ),
        SizedBox(height: 2),
        Text(
          UiStrings.gauntletSubtitle,
          style: TextStyle(color: WuxiaColors.textMuted, fontSize: 12),
        ),
      ],
    );
  }
}

class _EmptyCandidates extends StatelessWidget {
  const _EmptyCandidates();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 20),
      child: Text(
        UiStrings.gauntletNoCandidates,
        textAlign: TextAlign.center,
        style: TextStyle(color: WuxiaColors.textMuted, fontSize: 13),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: WuxiaUi.gold,
        fontSize: 14,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag(this.text, {required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

Color _schoolColor(TechniqueSchool? school) => switch (school) {
  TechniqueSchool.gangMeng => WuxiaColors.gangMeng,
  TechniqueSchool.lingQiao => WuxiaColors.lingQiao,
  TechniqueSchool.yinRou => WuxiaColors.yinRou,
  null => WuxiaColors.textMuted,
};
