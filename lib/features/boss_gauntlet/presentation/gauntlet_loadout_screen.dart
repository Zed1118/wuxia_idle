import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/domain/enums.dart';
import '../../../data/defs/stage_def.dart';
import '../../../data/game_repository.dart';
import '../../../shared/strings.dart';
import '../../../shared/theme/colors.dart';
import '../../../shared/widgets/portrait_frame.dart';
import '../../../shared/widgets/wuxia_ui/wuxia_ui.dart';
import '../../../shared/battle_shared/cycle_realm_gate.dart';
import '../../../shared/battle_shared/enum_localizations.dart';
import '../../../shared/widgets/cycle_select_control.dart';
import '../../activity/application/durable_activity_automation_providers.dart';
import '../../activity/domain/durable_activity_combat_run.dart';
import '../../activity/presentation/durable_activity_automation_ui.dart';
import '../application/gauntlet_providers.dart';
import '../application/gauntlet_service.dart';
import '../../../data/defs/boss_gauntlet_config.dart';
import '../domain/boss_gauntlet_run.dart';
import '../domain/gauntlet_automation_policy.dart';
import 'gauntlet_defeat_screen.dart';
import 'gauntlet_entry_flow.dart';

/// 断魂庄装载屏（§7.1 · C2.5）。断魂帖库存 / 庄中三关（三 Boss + 推荐境界）/ 择人
/// 单人（当前掌门或门人·已修主修）/ 补给装载（≤3 份托管）/ 持帖入庄。
///
/// 入庄写路径经 [GauntletService.enter] 单事务（屏内零直接 Isar 写），成功后 invalidate
/// active/candidates/loadoutInfo provider，随即 push [runGauntletFlow] 逐关战斗流
/// （#1 wiring Task 5）；流程终局（选奖 / 离庄 / 认输）返回后 pop 本屏回主菜单。config
/// 经 [gauntletConfigProvider] watch（非构造期读单例，避 async-config-race）。
///
/// 断线续战（§5.6/§10）：已有 active 会话时 [GauntletService.enter] 必抛，故顶部改显
/// 恢复区（第几关 / 当前相位 + 「续战」）并禁用新建交互；续战经 [GauntletService.recover]
/// 判界——resumed 续跑 [runGauntletFlow]（按相位路由）、refundedTicket 提示退帖闭局、
/// concedeRequired 认输结算 + 战败屏（镜像 entry_flow 战败分支）。
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

  /// 批 B：选定挑战周目（null = 未手选，默认已通最高周目；未通过 cycle1 恒 1）。
  int? _cycle;

  int get _loadedTotal => _supplyLoad.values.fold(0, (a, b) => a + b);

  Future<void> _enter(
    int ticketCount,
    int cycleIndex, {
    bool headlessReplay = false,
  }) async {
    if (_selected.length != 1 || _submitting || ticketCount < 1) return;
    final service = ref.read(gauntletServiceProvider);
    if (service == null) return; // 测试旁路：未 init Isar
    final config = ref.read(gauntletConfigProvider);
    final numbers = GameRepository.instanceOrNull?.numbers;
    if (headlessReplay && (config == null || numbers == null)) return;
    final participantId = _selected.single;
    final automationRequest = headlessReplay
        ? gauntletDurableDispatchRequest(characterId: participantId)
        : null;
    setState(() => _submitting = true);
    try {
      final supplies = {
        for (final e in _supplyLoad.entries)
          if (e.value > 0) e.key: e.value,
      };
      final durableStart = headlessReplay
          ? await service.enterDurableDispatch(
              characterIds: [participantId],
              supplies: supplies,
              supplyCap: _supplyCap,
              cycleIndex: cycleIndex,
              request: automationRequest!,
            )
          : null;
      if (!headlessReplay) {
        await service.enter(
          characterIds: [participantId],
          supplies: supplies,
          supplyCap: _supplyCap,
          cycleIndex: cycleIndex,
        );
      }
      if (!mounted) return;
      ref.invalidate(activeGauntletProvider);
      ref.invalidate(gauntletCandidatesProvider);
      ref.invalidate(gauntletLoadoutInfoProvider);
      ref.invalidate(durableActivityRunProvider(DurableActivityKind.gauntlet));
      if (headlessReplay) {
        final result = await service.resumeDurableDispatch(
          durableRunId: durableStart!.durableRunId,
          config: config!,
          numbers: numbers!,
        );
        if (!mounted) return;
        ref.invalidate(activeGauntletProvider);
        ref.invalidate(gauntletCandidatesProvider);
        ref.invalidate(gauntletLoadoutInfoProvider);
        ref.invalidate(
          durableActivityRunProvider(DurableActivityKind.gauntlet),
        );
        switch (result.terminal) {
          case GauntletAutomationDriveTerminal.awaitingRewardChoice:
            // 自动战斗只推进到现有三选一边界，选择权仍由玩家本人处理。
            await runGauntletFlow(context: context, ref: ref);
          case GauntletAutomationDriveTerminal.defeated:
            final summary = result.defeatSummary;
            if (summary == null) {
              throw StateError('Gauntlet automation defeat has no summary');
            }
            await Navigator.of(context).push<void>(
              MaterialPageRoute(
                builder: (_) => GauntletDefeatScreen(summary: summary),
              ),
            );
        }
        await ref
            .read(durableActivityAutomationServiceProvider)
            ?.close(runId: durableStart.durableRunId);
        ref.invalidate(
          durableActivityRunProvider(DurableActivityKind.gauntlet),
        );
      } else {
        // 入庄成功 → 逐关战斗流（#1 wiring Task 5）；终局（选奖 / 离庄 / 认输）
        // 返回后 pop 本屏回主菜单（镜像 tower 花名册 → runTowerFlow）。
        await runGauntletFlow(context: context, ref: ref);
      }
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

  /// 断线续战（§5.6/§10）：[GauntletService.recover] 判界后按结果路由——resumed
  /// 续跑战斗流（尾部完全镜像 [_enter]）、refundedTicket 提示退帖闭局、concedeRequired
  /// 认输结算 + 战败屏（镜像 entry_flow 战败分支）、none 仅刷新 stale 会话态。
  Future<void> _resume() async {
    if (_submitting) return;
    final service = ref.read(gauntletServiceProvider);
    if (service == null) return; // 测试旁路：未 init Isar
    setState(() => _submitting = true);
    try {
      final durable = await ref.read(
        durableActivityRunProvider(DurableActivityKind.gauntlet).future,
      );
      if (durable != null) {
        await _resumeDurable(durable, service);
        return;
      }
      final outcome = await service.recover(
        config: ref.read(gauntletConfigProvider),
      );
      if (!mounted) return;
      switch (outcome) {
        case GauntletRecoveryOutcome.resumed:
          ref.invalidate(activeGauntletProvider);
          ref.invalidate(gauntletCandidatesProvider);
          ref.invalidate(gauntletLoadoutInfoProvider);
          // 会话原样可续 → 按相位路由续跑；终局返回后 pop 本屏回主菜单。
          await runGauntletFlow(context: context, ref: ref);
          if (!mounted) return;
          Navigator.of(context).maybePop();
        case GauntletRecoveryOutcome.refundedTicket:
          // 配置损坏且未开战：服务侧已退帖 + 返还托管 + 删会话，刷新回新建态。
          ref.invalidate(activeGauntletProvider);
          ref.invalidate(gauntletCandidatesProvider);
          ref.invalidate(gauntletLoadoutInfoProvider);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text(UiStrings.gauntletResumeRefunded)),
          );
        case GauntletRecoveryOutcome.concedeRequired:
          // 配置损坏且已开战：认输结算 + 战败屏（镜像 entry_flow 战败分支）。
          final config = ref.read(gauntletConfigProvider);
          final numbers = GameRepository.instanceOrNull?.numbers;
          if (config == null || numbers == null) return; // 配置未加载，不可结算
          final summary = await service.settleDefeat(
            config: config,
            numbers: numbers,
          );
          ref.invalidate(activeGauntletProvider);
          ref.invalidate(gauntletCandidatesProvider);
          ref.invalidate(gauntletLoadoutInfoProvider);
          if (!mounted) return;
          await Navigator.of(context).push<void>(
            MaterialPageRoute(
              builder: (_) => GauntletDefeatScreen(summary: summary),
            ),
          );
        case GauntletRecoveryOutcome.none:
          // 观到时会话已被并发关闭：仅刷新 stale 态。
          ref.invalidate(activeGauntletProvider);
      }
    } on StateError {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(UiStrings.gauntletResumeFailed)),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _resumeDurable(
    DurableActivityCombatRun durable,
    GauntletService service,
  ) async {
    var current = durable;
    GauntletAutomationDriveResult? driveResult;
    if (current.phase == DurableActivityPhase.active) {
      final config = ref.read(gauntletConfigProvider);
      final numbers = GameRepository.instanceOrNull?.numbers;
      if (config == null || numbers == null) return;
      driveResult = await service.resumeDurableDispatch(
        durableRunId: current.id,
        config: config,
        numbers: numbers,
      );
      final persisted = await ref
          .read(durableActivityAutomationServiceProvider)
          ?.runById(current.id);
      if (persisted == null) {
        throw StateError('Gauntlet durable receipt disappeared after resume');
      }
      current = persisted;
    }
    ref.invalidate(activeGauntletProvider);
    ref.invalidate(gauntletCandidatesProvider);
    ref.invalidate(gauntletLoadoutInfoProvider);
    ref.invalidate(durableActivityRunProvider(DurableActivityKind.gauntlet));
    if (!mounted || current.phase != DurableActivityPhase.settlementApplied) {
      return;
    }
    if (current.outcome == DurableActivityOutcome.victory) {
      await runGauntletFlow(context: context, ref: ref);
    } else {
      final summary = driveResult?.defeatSummary;
      if (summary != null) {
        await Navigator.of(context).push<void>(
          MaterialPageRoute(
            builder: (_) => GauntletDefeatScreen(summary: summary),
          ),
        );
      } else {
        await showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) => AlertDialog(
            title: const Text(UiStrings.stageVictoryReportTitle),
            content: Text(
              [
                UiStrings.gauntletName,
                UiStrings.stageReportParticipant(current.participantName),
                UiStrings.mainlineNarrativeDefeatLabel,
              ].join(UiStrings.offlineRecapDetailSeparator),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text(UiStrings.stageVictoryConfirm),
              ),
            ],
          ),
        );
      }
    }
    await ref
        .read(durableActivityAutomationServiceProvider)
        ?.close(runId: current.id);
    ref.invalidate(durableActivityRunProvider(DurableActivityKind.gauntlet));
  }

  @override
  Widget build(BuildContext context) {
    final candidatesAsync = ref.watch(gauntletCandidatesProvider);
    final infoAsync = ref.watch(gauntletLoadoutInfoProvider);
    final activeAsync = ref.watch(activeGauntletProvider);
    final durableAsync = ref.watch(
      durableActivityRunProvider(DurableActivityKind.gauntlet),
    );
    final config = ref.watch(gauntletConfigProvider);

    return Scaffold(
      backgroundColor: WuxiaColors.background,
      appBar: WuxiaTitleBar(
        title: UiStrings.gauntletLoadoutTitle,
        showHome: false,
        onBack: Navigator.of(context).canPop()
            ? () => Navigator.of(context).pop()
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
            data: (info) => _buildBody(
              candidates,
              info,
              config,
              activeAsync.asData?.value,
              durableAsync.asData?.value,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(
    List<GauntletCandidate> candidates,
    GauntletLoadoutInfo info,
    BossGauntletConfig? config,
    BossGauntletRun? activeRun,
    DurableActivityCombatRun? durableRun,
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

    // 断线续战：有 active 会话时 enter 必抛，顶部改显恢复区并禁用新建交互。
    final resuming = activeRun != null || durableRun != null;
    final hasTicket = info.ticketCount >= 1;
    final canEnter =
        !resuming && _selected.length == 1 && hasTicket && !_submitting;

    // ── 批 B 周目选择：可挑战上限 = 顺序解锁 ∩ 配置 cap ∩ 境界门槛。
    // 境界口径 = 当前已选队伍最高（未选人时取可入场候选最高，乐观展示）；
    // enter 侧按实际队伍硬校验兜底。
    final ra =
        GameRepository.instanceOrNull?.numbers.cycleEvolution.realmAdvance;
    final cleared = info.clearedCyclesMax;
    var unlockedCap = 1;
    if (ra != null && config != null) {
      final gateTiers = [
        for (final c in candidates)
          if (_selected.isEmpty
              ? c.selectable
              : _selected.contains(c.character.id))
            c.character.realmTier,
      ];
      final playerMaxTier = gateTiers.isEmpty
          ? RealmTier.xueTu
          : gateTiers.reduce((a, b) => a.index >= b.index ? a : b);
      unlockedCap = CycleRealmGate.unlockedCycleCap(
        clearedCyclesMax: cleared,
        playerMaxTier: playerMaxTier,
        baseEnemyMaxTier: CycleRealmGate.maxEnemyTierOf([
          for (final s in config.stages)
            ...config.enemiesForTeam(s.enemyTeamId),
        ]),
        ra: ra,
      );
    }
    final selectedCycle = (_cycle ?? cleared.clamp(1, unlockedCap)).clamp(
      1,
      unlockedCap,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 860),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (activeRun != null) ...[
                _RecoveryBanner(
                  run: activeRun,
                  submitting: _submitting,
                  onResume: _resume,
                ),
                const SizedBox(height: 14),
              ] else if (durableRun != null) ...[
                DurableActivityRunCard(
                  run: durableRun,
                  stageName: UiStrings.gauntletName,
                  onPressed: _resume,
                ),
                const SizedBox(height: 14),
              ],
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
                    onTap: !resuming && c.selectable
                        ? () => setState(() {
                            final id = c.character.id;
                            if (_selected.contains(id)) {
                              _selected.remove(id);
                            } else if (_selected.isEmpty) {
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
                  onAdd: resuming
                      ? null
                      : () => setState(
                          () => _supplyLoad[s.defId] =
                              (_supplyLoad[s.defId] ?? 0) + 1,
                        ),
                  onRemove: resuming
                      ? null
                      : () => setState(() {
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
              // 批 B：周目选择（已通 cycle1 起显；未通首闯恒 cycle1 不渲染，
              // 沿 CycleSelectControl「highest==0 → 空占位」体例）。
              if (!resuming && cleared >= 1) ...[
                const SizedBox(height: 18),
                CycleSelectLayout(
                  highestCleared: cleared,
                  maxCycle: unlockedCap,
                  atMax: cleared >= unlockedCap,
                  selected: selectedCycle,
                  onChoose: (c) => setState(() => _cycle = c),
                ),
              ],
              const SizedBox(height: 18),
              // 续战态帖已耗，无帖提示无义，仅新建态显。
              if (!hasTicket && !resuming)
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
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 12,
                runSpacing: 8,
                children: [
                  PlaqueButton(
                    label: UiStrings.gauntletEnterButton,
                    primary: true,
                    onTap: canEnter
                        ? () => _enter(info.ticketCount, selectedCycle)
                        : null,
                  ),
                  if (cleared >= 1)
                    PlaqueButton(
                      label: UiStrings.mainlineHeadlessReplayMode,
                      onTap: canEnter
                          ? () => _enter(
                              info.ticketCount,
                              selectedCycle,
                              headlessReplay: true,
                            )
                          : null,
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

// ── 断线续战横幅（§5.6/§10 · 有 active 会话时置顶）──────────────────────────

class _RecoveryBanner extends StatelessWidget {
  const _RecoveryBanner({
    required this.run,
    required this.submitting,
    required this.onResume,
  });

  final BossGauntletRun run;
  final bool submitting;
  final VoidCallback onResume;

  @override
  Widget build(BuildContext context) {
    final phaseText = switch (run.sessionPhase) {
      GauntletPhase.inBattle => UiStrings.gauntletPhaseInBattle,
      GauntletPhase.interlude => UiStrings.gauntletPhaseInterlude,
      GauntletPhase.awaitingRewardChoice =>
        UiStrings.gauntletPhaseAwaitingReward,
      GauntletPhase.settled => UiStrings.gauntletPhaseSettled,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: WuxiaUi.gold.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: WuxiaUi.gold.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.history, color: WuxiaUi.gold, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  UiStrings.gauntletResumeTitle,
                  style: TextStyle(
                    color: WuxiaUi.gold,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  UiStrings.gauntletResumeHint(run.currentStage, phaseText),
                  style: const TextStyle(
                    color: WuxiaColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          PlaqueButton(
            label: UiStrings.gauntletResumeButton,
            primary: true,
            onTap: submitting ? null : onResume,
          ),
        ],
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
    return InkListCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
      child: InkListCard(
        selected: selected,
        enabled: !dim,
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

  /// 续战态传 null → 步进禁用（新建装载交互整体关闭）。
  final VoidCallback? onAdd;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return InkListCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
    return const InkPageHeader(
      title: UiStrings.gauntletName,
      subtitle: UiStrings.gauntletSubtitle,
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
    return InkSectionLabel(text);
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
