import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/application/system_clock_provider.dart';
import '../../../core/domain/enums.dart';
import '../../../shared/strings.dart';
import '../../../shared/theme/colors.dart';
import '../../../shared/widgets/portrait_frame.dart';
import '../../../shared/widgets/wuxia_ui/wuxia_ui.dart';
import '../../battle/domain/enum_localizations.dart';
import '../application/expedition_providers.dart';
import '../domain/expedition_rules.dart';
import '../domain/expedition_run.dart';
import 'expedition_recap_screen.dart';

/// 江湖远行总览（§7.1 · Phase B2.4）。百草岭卡两态：
/// - 无 active 远征 → **派遣态**（择人 1-3 + 三方针 + 拔营出发）；
/// - 有 active 远征 → **在途态**（深度 / 完成节点 / 下一节点剩余 / 召回）。
///
/// dispatch/recall 是玩家唯一进出百草岭远征的入口。写路径经 [ExpeditionService]
/// 单事务（屏内零直接 Isar 写），成功后 invalidate active/candidates provider；
/// config 经 [expeditionConfigProvider] watch（非构造期读单例，避 async-config-race）。
class ExpeditionOverviewScreen extends ConsumerWidget {
  const ExpeditionOverviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeAsync = ref.watch(activeExpeditionProvider);
    return Scaffold(
      backgroundColor: WuxiaColors.background,
      appBar: AppBar(
        backgroundColor: WuxiaColors.sidebar,
        foregroundColor: WuxiaColors.textPrimary,
        title: const Text(UiStrings.expeditionOverviewTitle),
        leading: Navigator.of(context).canPop()
            ? BackButton(onPressed: () => Navigator.of(context).pop())
            : null,
      ),
      body: SafeArea(
        child: activeAsync.when(
          loading: () => const Center(child: InkLoadingIndicator()),
          error: (e, _) => ErrorFallback(
            error: e,
            onRetry: () => ref.invalidate(activeExpeditionProvider),
          ),
          data: (run) =>
              run == null ? const _DispatchView() : _ActiveView(run: run),
        ),
      ),
    );
  }
}

// ── 派遣态 ────────────────────────────────────────────────────────────────

class _DispatchView extends ConsumerStatefulWidget {
  const _DispatchView();

  @override
  ConsumerState<_DispatchView> createState() => _DispatchViewState();
}

class _DispatchViewState extends ConsumerState<_DispatchView> {
  final Set<int> _selected = {};
  ExpeditionPolicy _policy = ExpeditionPolicy.yanJingCaiYao;
  bool _submitting = false;

  Future<void> _dispatch() async {
    if (_selected.isEmpty || _submitting) return;
    final service = ref.read(expeditionServiceProvider);
    if (service == null) return; // 测试旁路：未 init Isar
    setState(() => _submitting = true);
    try {
      await service.dispatch(characterIds: _selected.toList(), policy: _policy);
      if (!mounted) return;
      ref.invalidate(activeExpeditionProvider);
      ref.invalidate(expeditionCandidatesProvider);
    } on StateError {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(UiStrings.expeditionDispatchFailed)),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final candidatesAsync = ref.watch(expeditionCandidatesProvider);
    return candidatesAsync.when(
      loading: () => const Center(child: InkLoadingIndicator()),
      error: (e, _) => ErrorFallback(
        error: e,
        onRetry: () => ref.invalidate(expeditionCandidatesProvider),
      ),
      data: _buildBody,
    );
  }

  Widget _buildBody(List<ExpeditionCandidate> candidates) {
    // 防御：清掉已不可派遣的旧选择（候选刷新后占用/主修态可能变）。
    final dispatchableIds = {
      for (final c in candidates)
        if (c.dispatchable) c.character.id,
    };
    _selected.removeWhere((id) => !dispatchableIds.contains(id));
    final canDispatch = _selected.isNotEmpty && !_submitting;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 860),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _BaicaoHeader(),
              const SizedBox(height: 18),
              const _SectionLabel(UiStrings.expeditionDispatchTeamSection),
              const SizedBox(height: 4),
              const Text(
                UiStrings.expeditionDispatchTeamHint,
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
                    onTap: c.dispatchable
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
                UiStrings.expeditionSelectedCount(_selected.length),
                style: const TextStyle(
                  color: WuxiaColors.textSecondary,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 16),
              const _SectionLabel(UiStrings.expeditionDispatchPolicySection),
              const SizedBox(height: 8),
              for (final p in ExpeditionPolicy.values) ...[
                _PolicyOption(
                  policy: p,
                  selected: _policy == p,
                  onTap: () => setState(() => _policy = p),
                ),
                const SizedBox(height: 8),
              ],
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.center,
                child: PlaqueButton(
                  label: UiStrings.expeditionDispatchButton,
                  primary: true,
                  onTap: canDispatch ? _dispatch : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CandidateTile extends StatelessWidget {
  const _CandidateTile({
    required this.candidate,
    required this.selected,
    required this.onTap,
  });

  final ExpeditionCandidate candidate;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = candidate.character;
    final dim = !candidate.dispatchable;
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
                UiStrings.expeditionCandidateOccupiedTag,
                color: WuxiaColors.internalForce,
              ),
            ],
            if (!candidate.hasMainTechnique) ...[
              const SizedBox(width: 4),
              const _Tag(
                UiStrings.expeditionCandidateNoMainTag,
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

class _PolicyOption extends StatelessWidget {
  const _PolicyOption({
    required this.policy,
    required this.selected,
    required this.onTap,
  });

  final ExpeditionPolicy policy;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: WuxiaColors.panel,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: selected ? WuxiaUi.gold : WuxiaColors.border,
            width: selected ? 1.6 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: selected ? WuxiaUi.gold : WuxiaColors.textMuted,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    EnumL10n.expeditionPolicy(policy),
                    style: const TextStyle(
                      color: WuxiaColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    EnumL10n.expeditionPolicyHint(policy),
                    style: const TextStyle(
                      color: WuxiaColors.textSecondary,
                      fontSize: 11,
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

class _EmptyCandidates extends StatelessWidget {
  const _EmptyCandidates();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 20),
      child: Text(
        UiStrings.expeditionNoCandidates,
        textAlign: TextAlign.center,
        style: TextStyle(color: WuxiaColors.textMuted, fontSize: 13),
      ),
    );
  }
}

// ── 在途态 ────────────────────────────────────────────────────────────────

class _ActiveView extends ConsumerWidget {
  const _ActiveView({required this.run});

  final ExpeditionRun run;

  Future<void> _recall(BuildContext context, WidgetRef ref) async {
    final service = ref.read(expeditionServiceProvider);
    if (service == null) return; // 测试旁路
    final confirmed = await PaperDialog.show<bool>(
      context,
      title: UiStrings.expeditionRecallConfirmTitle,
      body: const Text(
        UiStrings.expeditionRecallConfirmBody,
        style: TextStyle(
          color: WuxiaUi.ink,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
      actions: [
        PlaqueButton(
          label: UiStrings.commonCancel,
          onTap: () => Navigator.of(context).pop(false),
        ),
        PlaqueButton(
          label: UiStrings.expeditionRecallConfirm,
          primary: true,
          onTap: () => Navigator.of(context).pop(true),
        ),
      ],
    );
    if (confirmed != true || !context.mounted) return;
    final result = await service.recall(defeated: false);
    if (!context.mounted) return;
    ref.invalidate(activeExpeditionProvider);
    ref.invalidate(expeditionCandidatesProvider);
    await Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => ExpeditionRecapScreen(result: result),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(expeditionConfigProvider);
    final now = ref.watch(systemClockProvider).now();

    String? nextText;
    if (config != null) {
      final remaining = ExpeditionRules.nextNodeRemaining(
        departedAt: run.departedAt,
        completedNodes: run.currentNode,
        now: now,
        normalMinutes: config.normalNodeMinutes,
        eliteMinutes: config.eliteNodeMinutes,
      );
      nextText = remaining == Duration.zero
          ? UiStrings.expeditionNextNodeReady
          : UiStrings.expeditionNextNodeIn(
              UiStrings.expeditionRemainingText(
                remaining.inHours,
                remaining.inMinutes % 60,
              ),
            );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 860),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _BaicaoHeader(),
              const SizedBox(height: 16),
              const _SectionLabel(UiStrings.expeditionActiveSection),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: WuxiaColors.panel,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: WuxiaUi.gold.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _StatRow(
                      icon: Icons.terrain,
                      label: UiStrings.expeditionActiveDepth(run.currentNode),
                    ),
                    _StatRow(
                      icon: Icons.flag_outlined,
                      label: UiStrings.expeditionActiveCompleted(
                        run.currentNode,
                      ),
                    ),
                    _StatRow(
                      icon: Icons.explore_outlined,
                      label:
                          '${UiStrings.expeditionActivePolicyLabel}：${EnumL10n.expeditionPolicy(run.policy)}',
                    ),
                    if (nextText != null)
                      _StatRow(icon: Icons.schedule, label: nextText),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Align(
                alignment: Alignment.center,
                child: PlaqueButton(
                  label: UiStrings.expeditionRecallButton,
                  primary: true,
                  onTap: () => _recall(context, ref),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, color: WuxiaUi.gold, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: WuxiaColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── 共用小组件 ──────────────────────────────────────────────────────────────

class _BaicaoHeader extends StatelessWidget {
  const _BaicaoHeader();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          UiStrings.expeditionBaicaoName,
          style: TextStyle(
            color: WuxiaColors.textPrimary,
            fontSize: 22,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
          ),
        ),
        SizedBox(height: 2),
        Text(
          UiStrings.expeditionBaicaoSubtitle,
          style: TextStyle(color: WuxiaColors.textMuted, fontSize: 12),
        ),
      ],
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
