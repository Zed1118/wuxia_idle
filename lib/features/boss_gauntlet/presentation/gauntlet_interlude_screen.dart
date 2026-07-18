import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/game_repository.dart';
import '../../../shared/strings.dart';
import '../../../shared/theme/colors.dart';
import '../../../shared/widgets/wuxia_ui/wuxia_ui.dart';
import '../application/gauntlet_providers.dart';

/// 断魂庄庄内整备屏（§7.2 · C2.5）。关次间（interlude）显示三名角色生命/真气/阵亡/
/// 冷却、三份托管补给剩余，只提供使用补给、继续闯关、认输离庄。1280×720 与 1440×900
/// 均一屏内完成主要决策——底部动作栏固定，内容超高时仅内容区滚动，继续/认输恒可见。
///
/// 用药/续战/认输写路径经 [GauntletService]（屏内零直接 Isar 写），成功后 invalidate
/// activeGauntlet/interludeView provider。战斗驱动（续战→下一关战斗）wiring 属后续切片。
class GauntletInterludeScreen extends ConsumerWidget {
  const GauntletInterludeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewAsync = ref.watch(gauntletInterludeViewProvider);
    return Scaffold(
      backgroundColor: WuxiaColors.background,
      appBar: AppBar(
        backgroundColor: WuxiaColors.sidebar,
        foregroundColor: WuxiaColors.textPrimary,
        title: const Text(UiStrings.gauntletInterludeTitle),
        leading: Navigator.of(context).canPop()
            ? BackButton(onPressed: () => Navigator.of(context).pop())
            : null,
      ),
      body: SafeArea(
        child: viewAsync.when(
          loading: () => const Center(child: InkLoadingIndicator()),
          error: (e, _) => ErrorFallback(
            error: e,
            onRetry: () => ref.invalidate(gauntletInterludeViewProvider),
          ),
          data: (view) =>
              view == null ? const _NoInterlude() : _Body(view: view),
        ),
      ),
    );
  }
}

class _NoInterlude extends StatelessWidget {
  const _NoInterlude();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          UiStrings.gauntletNoInterludeSupply,
          textAlign: TextAlign.center,
          style: TextStyle(color: WuxiaColors.textMuted, fontSize: 13),
        ),
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.view});

  final GauntletInterludeView view;

  Future<void> _useSupply(
    BuildContext context,
    WidgetRef ref,
    GauntletSupplyRemainView supply,
  ) async {
    final service = ref.read(gauntletServiceProvider);
    if (service == null) return; // 测试旁路
    int? targetId;
    if (supply.isHeal) {
      final alive = view.members.where((m) => !m.downed).toList();
      if (alive.isEmpty) return;
      targetId = await _pickHealTarget(context, alive);
      if (targetId == null || !context.mounted) return;
    }
    try {
      await service.useSupply(index: supply.index, targetCharacterId: targetId);
    } on StateError {
      // 已用尽/相位变化等：静默（下一帧 provider 刷新反映真态）。
    }
    ref.invalidate(gauntletInterludeViewProvider);
    ref.invalidate(activeGauntletProvider);
  }

  Future<int?> _pickHealTarget(
    BuildContext context,
    List<GauntletMemberView> alive,
  ) {
    return PaperDialog.show<int>(
      context,
      title: UiStrings.gauntletHealTargetTitle,
      body: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final m in alive)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: PlaqueButton(
                label:
                    '${m.name}（${UiStrings.gauntletMemberHp(m.currentHp, m.maxHp)}）',
                onTap: () => Navigator.of(context).pop(m.characterId),
              ),
            ),
        ],
      ),
      actions: [
        PlaqueButton(
          label: UiStrings.commonCancel,
          onTap: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }

  Future<void> _continue(BuildContext context, WidgetRef ref) async {
    final service = ref.read(gauntletServiceProvider);
    if (service == null) return; // 测试旁路
    try {
      await service.continueToNextStage();
    } on StateError {
      return;
    }
    if (!context.mounted) return;
    ref.invalidate(gauntletInterludeViewProvider);
    ref.invalidate(activeGauntletProvider);
    Navigator.of(context).maybePop();
  }

  Future<void> _concede(BuildContext context, WidgetRef ref) async {
    // 先弹确认（含结算说明）；确认后再校验 service/config 前置（无则静默 no-op）。
    final confirmed = await PaperDialog.show<bool>(
      context,
      title: UiStrings.gauntletConcedeConfirmTitle,
      body: const Text(
        UiStrings.gauntletConcedeConfirmBody,
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
          label: UiStrings.gauntletConcedeConfirm,
          primary: true,
          onTap: () => Navigator.of(context).pop(true),
        ),
      ],
    );
    if (confirmed != true || !context.mounted) return;
    final service = ref.read(gauntletServiceProvider);
    final config = ref.read(gauntletConfigProvider);
    final numbers = GameRepository.instanceOrNull?.numbers;
    if (service == null || config == null || numbers == null) return;
    await service.settleDefeat(config: config, numbers: numbers);
    if (!context.mounted) return;
    ref.invalidate(gauntletInterludeViewProvider);
    ref.invalidate(activeGauntletProvider);
    ref.invalidate(gauntletCandidatesProvider);
    ref.invalidate(gauntletLoadoutInfoProvider);
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 820),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _SectionLabel(
                      UiStrings.gauntletInterludeSection(view.stage),
                    ),
                    const SizedBox(height: 12),
                    const _SubLabel(UiStrings.gauntletMemberSection),
                    const SizedBox(height: 8),
                    for (final m in view.members) ...[
                      _MemberTile(member: m),
                      const SizedBox(height: 8),
                    ],
                    const SizedBox(height: 10),
                    const _SubLabel(UiStrings.gauntletSupplyRemainSection),
                    const SizedBox(height: 8),
                    if (view.supplies.isEmpty)
                      const Text(
                        UiStrings.gauntletNoInterludeSupply,
                        style: TextStyle(
                          color: WuxiaColors.textMuted,
                          fontSize: 12,
                        ),
                      )
                    else
                      for (final s in view.supplies) ...[
                        _SupplyTile(
                          supply: s,
                          onUse: s.remaining > 0
                              ? () => _useSupply(context, ref, s)
                              : null,
                        ),
                        const SizedBox(height: 8),
                      ],
                  ],
                ),
              ),
            ),
          ),
        ),
        _ActionBar(
          onContinue: () => _continue(context, ref),
          onConcede: () => _concede(context, ref),
        ),
      ],
    );
  }
}

// ── 成员状态 tile ───────────────────────────────────────────────────────────

class _MemberTile extends StatelessWidget {
  const _MemberTile({required this.member});

  final GauntletMemberView member;

  @override
  Widget build(BuildContext context) {
    final downed = member.downed;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: WuxiaColors.panel.withValues(alpha: downed ? 0.55 : 1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: downed
              ? WuxiaColors.internalForce.withValues(alpha: 0.5)
              : WuxiaColors.border,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        member.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: downed
                              ? WuxiaColors.textMuted
                              : WuxiaColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (downed) ...[
                      const SizedBox(width: 8),
                      const _Tag(
                        UiStrings.gauntletMemberDownedTag,
                        color: WuxiaColors.internalForce,
                      ),
                    ],
                    if (member.cooldownCount > 0) ...[
                      const SizedBox(width: 6),
                      _Tag(
                        UiStrings.gauntletMemberCooldownTag(
                          member.cooldownCount,
                        ),
                        color: WuxiaColors.textMuted,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${UiStrings.gauntletMemberHp(member.currentHp, member.maxHp)}    '
                  '${UiStrings.gauntletMemberQi(member.currentQi, member.maxQi)}',
                  style: const TextStyle(
                    color: WuxiaColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── 补给剩余 tile ───────────────────────────────────────────────────────────

class _SupplyTile extends StatelessWidget {
  const _SupplyTile({required this.supply, required this.onUse});

  final GauntletSupplyRemainView supply;
  final VoidCallback? onUse;

  @override
  Widget build(BuildContext context) {
    final exhausted = supply.remaining <= 0;
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
            child: Text(
              UiStrings.gauntletSupplyRemain(supply.name, supply.remaining),
              style: TextStyle(
                color: exhausted
                    ? WuxiaColors.textMuted
                    : WuxiaColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (exhausted)
            const Text(
              UiStrings.gauntletSupplyExhausted,
              style: TextStyle(color: WuxiaColors.textMuted, fontSize: 12),
            )
          else
            PlaqueButton(
              label: UiStrings.gauntletSupplyUseButton,
              onTap: onUse,
            ),
        ],
      ),
    );
  }
}

// ── 底部动作栏（固定·恒可见·§7.2）──────────────────────────────────────────

class _ActionBar extends StatelessWidget {
  const _ActionBar({required this.onContinue, required this.onConcede});

  final VoidCallback onContinue;
  final VoidCallback onConcede;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration: const BoxDecoration(
        color: WuxiaColors.sidebar,
        border: Border(top: BorderSide(color: WuxiaColors.border)),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              PlaqueButton(
                label: UiStrings.gauntletConcedeButton,
                onTap: onConcede,
              ),
              PlaqueButton(
                label: UiStrings.gauntletContinueButton,
                primary: true,
                onTap: onContinue,
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

class _SubLabel extends StatelessWidget {
  const _SubLabel(this.text);

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
