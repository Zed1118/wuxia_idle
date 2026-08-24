import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/game_repository.dart';
import '../../../data/isar_setup.dart';
import '../../../shared/strings.dart';
import '../../../shared/theme/colors.dart';
import '../../../shared/theme/wuxia_tokens.dart';
import '../../../shared/widgets/wuxia_ink_button.dart';
import '../../../shared/widgets/wuxia_ui/ink_empty_state.dart';
import '../../../shared/widgets/wuxia_ui/ink_loading.dart';
import '../../../shared/widgets/wuxia_ui/light_paper_panel.dart';
import '../../../shared/widgets/wuxia_ui/section_header.dart';
import '../../../shared/widgets/wuxia_ui/wuxia_title_bar.dart';
import '../../mainline/application/mainline_pending_jianghu_affair_service.dart';
import '../../mainline/application/mainline_settlement_journal_service.dart';
import '../../mainline/domain/mainline_pending_jianghu_affair.dart';
import '../../mainline/presentation/stage_entry_flow.dart';

typedef PendingJianghuAffairsLoader =
    Future<MainlinePendingJianghuAffairsSnapshot?> Function();
typedef PendingJianghuAffairsResume =
    Future<void> Function(
      BuildContext context,
      WidgetRef ref,
      MainlinePendingJianghuAffairsSnapshot snapshot,
    );

/// Read-only entry into the existing durable mainline affair recovery flow.
class PendingJianghuAffairsScreen extends ConsumerStatefulWidget {
  const PendingJianghuAffairsScreen({
    super.key,
    @visibleForTesting this.loaderForTest,
    @visibleForTesting this.resumeForTest,
  });

  final PendingJianghuAffairsLoader? loaderForTest;
  final PendingJianghuAffairsResume? resumeForTest;

  @override
  ConsumerState<PendingJianghuAffairsScreen> createState() =>
      _PendingJianghuAffairsScreenState();
}

class _PendingJianghuAffairsScreenState
    extends ConsumerState<PendingJianghuAffairsScreen> {
  late Future<MainlinePendingJianghuAffairsSnapshot?> _pending;
  bool _resuming = false;

  @override
  void initState() {
    super.initState();
    _pending = _load();
  }

  Future<MainlinePendingJianghuAffairsSnapshot?> _load() {
    final loader = widget.loaderForTest;
    if (loader != null) return loader();
    final isar = IsarSetup.instanceOrNull;
    if (isar == null) return Future.value();
    return MainlinePendingJianghuAffairService(
      MainlineSettlementJournalService(isar),
    ).pendingForSave(IsarSetup.currentSlotId);
  }

  Future<void> _resume(MainlinePendingJianghuAffairsSnapshot snapshot) async {
    if (_resuming) return;
    setState(() => _resuming = true);
    try {
      final override = widget.resumeForTest;
      if (override != null) {
        await override(context, ref, snapshot);
      } else {
        final stage =
            GameRepository.instanceOrNull?.stageDefs[snapshot.stageId];
        if (stage == null) {
          throw StateError('Pending affair stage is unavailable');
        }
        await runStageFlow(
          context: context,
          ref: ref,
          stage: stage,
          targetCycle: 1,
          continueFirstClearRun: true,
        );
      }
      if (!mounted) return;
      setState(() {
        _pending = _load();
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _pending = Future<MainlinePendingJianghuAffairsSnapshot?>.error(
          StateError('Pending affair recovery failed'),
        );
      });
    } finally {
      if (mounted) setState(() => _resuming = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WuxiaColors.background,
      appBar: WuxiaTitleBar(
        title: UiStrings.jianghuChroniclePendingAffairs,
        onBack: () => Navigator.of(context).maybePop(),
      ),
      body: SafeArea(
        child: FutureBuilder<MainlinePendingJianghuAffairsSnapshot?>(
          future: _pending,
          builder: (context, state) {
            if (state.connectionState != ConnectionState.done) {
              return const Center(child: InkLoadingIndicator());
            }
            if (state.hasError) {
              return const _PendingState(
                text: UiStrings.pendingJianghuAffairsUnavailable,
              );
            }
            final snapshot = state.data;
            if (snapshot == null) {
              return const _PendingState(
                text: UiStrings.pendingJianghuAffairsEmpty,
              );
            }
            return _PendingList(
              snapshot: snapshot,
              resuming: _resuming,
              onResume: () => unawaited(_resume(snapshot)),
            );
          },
        ),
      ),
    );
  }
}

class _PendingList extends StatelessWidget {
  const _PendingList({
    required this.snapshot,
    required this.resuming,
    required this.onResume,
  });

  final MainlinePendingJianghuAffairsSnapshot snapshot;
  final bool resuming;
  final VoidCallback onResume;

  @override
  Widget build(BuildContext context) {
    final stageName =
        GameRepository.instanceOrNull?.stageDefs[snapshot.stageId]?.name;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            LightPaperPanel(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SectionHeader(UiStrings.pendingJianghuAffairsTitle),
                  const SizedBox(height: 8),
                  Text(
                    UiStrings.pendingJianghuAffairsSource(
                      stageName ?? snapshot.stageId,
                    ),
                    style: const TextStyle(color: WuxiaUi.muted, fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  for (
                    var index = 0;
                    index < snapshot.affairs.length;
                    index++
                  ) ...[
                    _AffairRow(index: index, affair: snapshot.affairs[index]),
                    if (index + 1 < snapshot.affairs.length)
                      const Divider(height: 14, color: WuxiaColors.border),
                  ],
                  const SizedBox(height: 14),
                  WuxiaInkButton(
                    label: UiStrings.pendingJianghuAffairsResume,
                    hint: UiStrings.pendingJianghuAffairsResumeHint,
                    icon: Icons.play_arrow_outlined,
                    disabled: resuming,
                    onTap: resuming ? null : onResume,
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

class _AffairRow extends StatelessWidget {
  const _AffairRow({required this.index, required this.affair});

  final int index;
  final MainlinePendingJianghuAffairRef affair;

  @override
  Widget build(BuildContext context) {
    final label = switch (affair.kind) {
      MainlinePendingJianghuAffairKind.encounterChoice =>
        UiStrings.pendingJianghuAffairEncounterChoice,
      MainlinePendingJianghuAffairKind.stageBossRecruit =>
        UiStrings.pendingJianghuAffairBossRecruit,
    };
    return Row(
      children: [
        SizedBox(
          width: 28,
          child: Text(
            '${index + 1}',
            style: const TextStyle(
              color: WuxiaColors.resultHighlight,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: WuxiaUi.ink,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _PendingState extends StatelessWidget {
  const _PendingState({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: InkEmptyState(
          variant: InkEmptyStateVariant.empty,
          title: UiStrings.pendingJianghuAffairsTitle,
          body: text,
          icon: Icons.mark_unread_chat_alt_outlined,
        ),
      ),
    );
  }
}
