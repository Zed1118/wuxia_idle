import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/game_repository.dart';
import '../../../shared/strings.dart';
import '../../../shared/theme/colors.dart';
import '../../../shared/utils/rng.dart';
import '../../../shared/widgets/wuxia_ui/wuxia_ui.dart';
import '../../battle/domain/enum_localizations.dart';
import '../application/gauntlet_providers.dart';

/// 断魂庄通关三选一奖励屏（§6.2 · #1 wiring Task 2）。Boss 终关胜利后
/// （awaitingRewardChoice 相位）展示三件命名装备候选（名/阶/位/属性区间），首通/重复
/// 标；点选一卡弹择取确认 → [GauntletService.chooseReward] 发选中装备入背包 + 参战弟子
/// 经验/领悟（首通另赠秘籍）→ 关会话回主菜单。屏内零直接 Isar 写（经服务）。深底
/// lineup 体例（同整备屏），1280×720/1440×900 一屏无溢出。
///
/// 奖励为闯庄终点、须择一而取，故不设返回（`automaticallyImplyLeading: false`）；
/// 择取写路径经服务后 invalidate reward/active/candidates/loadout provider。
class GauntletRewardScreen extends ConsumerWidget {
  const GauntletRewardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewAsync = ref.watch(gauntletRewardViewProvider);
    return Scaffold(
      backgroundColor: WuxiaColors.background,
      appBar: AppBar(
        backgroundColor: WuxiaColors.sidebar,
        foregroundColor: WuxiaColors.textPrimary,
        title: const Text(UiStrings.gauntletRewardTitle),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: viewAsync.when(
          loading: () => const Center(child: InkLoadingIndicator()),
          error: (e, _) => ErrorFallback(
            error: e,
            onRetry: () => ref.invalidate(gauntletRewardViewProvider),
          ),
          data: (view) => view == null || view.candidates.isEmpty
              ? const _NoReward()
              : _Body(view: view),
        ),
      ),
    );
  }
}

class _NoReward extends StatelessWidget {
  const _NoReward();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          UiStrings.gauntletNoReward,
          textAlign: TextAlign.center,
          style: TextStyle(color: WuxiaColors.textMuted, fontSize: 13),
        ),
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.view});

  final GauntletRewardView view;

  Future<void> _choose(
    BuildContext context,
    WidgetRef ref,
    GauntletRewardCandidate candidate,
  ) async {
    final confirmed = await PaperDialog.show<bool>(
      context,
      title: UiStrings.gauntletRewardConfirmTitle,
      body: Text(
        UiStrings.gauntletRewardConfirmBody(candidate.name),
        style: const TextStyle(
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
          label: UiStrings.gauntletRewardConfirm,
          primary: true,
          onTap: () => Navigator.of(context).pop(true),
        ),
      ],
    );
    if (confirmed != true || !context.mounted) return;
    final service = ref.read(gauntletServiceProvider);
    final config = ref.read(gauntletConfigProvider);
    final numbers = GameRepository.instanceOrNull?.numbers;
    if (service == null || config == null || numbers == null) {
      return; // 测试旁路 / 配置未加载
    }
    try {
      await service.chooseReward(
        chosenEquipmentDefId: candidate.defId,
        config: config,
        numbers: numbers,
        rng: DefaultRng(),
      );
    } on StateError {
      // 相位已变 / 会话已结算 / 候选不合：静默（下一帧 provider 反映真态）。
    }
    if (!context.mounted) return;
    ref.invalidate(gauntletRewardViewProvider);
    ref.invalidate(activeGauntletProvider);
    ref.invalidate(gauntletCandidatesProvider);
    ref.invalidate(gauntletLoadoutInfoProvider);
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: _SectionLabel(UiStrings.gauntletRewardSection),
                  ),
                  _Badge(
                    view.isFirstClear
                        ? UiStrings.gauntletRewardFirstClearBadge
                        : UiStrings.gauntletRewardRepeatBadge,
                    color: view.isFirstClear
                        ? WuxiaUi.gold
                        : WuxiaColors.textMuted,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                view.isFirstClear
                    ? UiStrings.gauntletRewardFirstClearHint
                    : UiStrings.gauntletRewardRepeatHint,
                style: const TextStyle(
                  color: WuxiaColors.textSecondary,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 16),
              LayoutBuilder(
                builder: (context, constraints) {
                  // 宽屏横排三卡（常规桌面视口 ≥720），窄屏竖排（防溢出）。
                  final horizontal = constraints.maxWidth >= 720;
                  final cards = [
                    for (final c in view.candidates)
                      _RewardCard(
                        candidate: c,
                        onTap: () => _choose(context, ref, c),
                      ),
                  ];
                  if (horizontal) {
                    return IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (var i = 0; i < cards.length; i++) ...[
                            if (i > 0) const SizedBox(width: 12),
                            Expanded(child: cards[i]),
                          ],
                        ],
                      ),
                    );
                  }
                  return Column(
                    children: [
                      for (var i = 0; i < cards.length; i++) ...[
                        if (i > 0) const SizedBox(height: 12),
                        cards[i],
                      ],
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── 候选卡（整卡可点·InkWell 带桌面 hover/semantics）─────────────────────────

class _RewardCard extends StatelessWidget {
  const _RewardCard({required this.candidate, required this.onTap});

  final GauntletRewardCandidate candidate;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final statLines = <String>[
      if (candidate.attackMax > 0)
        UiStrings.gauntletRewardAtk(candidate.attackMin, candidate.attackMax),
      if (candidate.healthMax > 0)
        UiStrings.gauntletRewardHp(candidate.healthMin, candidate.healthMax),
      if (candidate.speedMax > 0)
        UiStrings.gauntletRewardSpd(candidate.speedMin, candidate.speedMax),
    ];
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: WuxiaColors.panel,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: WuxiaColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                candidate.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: WuxiaUi.gold,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                UiStrings.gauntletRewardTierSlot(
                  EnumL10n.equipmentTier(candidate.tier),
                  EnumL10n.equipmentSlot(candidate.slot),
                ),
                style: const TextStyle(
                  color: WuxiaColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              for (final line in statLines)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    line,
                    style: const TextStyle(
                      color: WuxiaColors.textPrimary,
                      fontSize: 12,
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              const Row(
                children: [
                  Icon(Icons.touch_app, size: 13, color: WuxiaUi.gold),
                  SizedBox(width: 4),
                  Text(
                    UiStrings.gauntletRewardSelectHint,
                    style: TextStyle(
                      color: WuxiaUi.gold,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── 共用小组件 ──────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: WuxiaColors.textPrimary,
        fontSize: 18,
        fontWeight: FontWeight.w900,
        letterSpacing: 1,
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge(this.text, {required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
