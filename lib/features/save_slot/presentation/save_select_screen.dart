import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/isar_provider.dart';
import '../../../data/isar_setup.dart';
import '../../../data/slot_summary.dart';
import '../../../shared/strings.dart';
import '../../../shared/theme/colors.dart';
import '../../../shared/widgets/wuxia_ui/error_fallback.dart';
import '../../main_menu/presentation/main_menu.dart';
import '../../onboarding/application/onboarding_service.dart';
import '../application/slot_list_provider.dart';
import '../../../shared/widgets/wuxia_ui/ink_loading.dart';

/// 存档选择屏(spec B §3.2)。启动 splash 加载 defs 后进此屏,3 固定槽:
/// 有档 → 点入直接 [switchSlot]→主菜单;空槽 → 确认「新开江湖」后同流程开新档;
/// 删档 → 确认 → [deleteSlot] 并刷新列表。切档原子化由 [IsarSetup.switchSlot] 保证,
/// provider 刷新在本屏 `ref.invalidate` 触发。
class SaveSelectScreen extends ConsumerWidget {
  const SaveSelectScreen({super.key});

  Future<void> _enterSlot(BuildContext context, WidgetRef ref, int n) async {
    await IsarSetup.switchSlot(n);
    // 幂等:已有 founder 跳过(老档/已开过的槽);空槽走全新 onboarding。
    await OnboardingService(isar: IsarSetup.instance).ensureFoundingMasters();
    ref.invalidate(isarProvider); // 切档后所有 per-save provider 级联重读新 db
    if (!context.mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const MainMenu()),
    );
  }

  Future<void> _confirmNewGame(
    BuildContext context,
    WidgetRef ref,
    int n,
  ) async {
    final ok = await _confirm(
      context,
      title: UiStrings.slotNewGameTitle,
      body: UiStrings.slotNewGameConfirm,
      action: UiStrings.slotEnter,
    );
    if (ok && context.mounted) await _enterSlot(context, ref, n);
  }

  Future<void> _renameSlot(
    BuildContext context,
    WidgetRef ref,
    SlotSummary summary,
  ) async {
    final name = await _renameDialog(context, summary);
    if (name == null) return;
    await IsarSetup.renameSlot(summary.slotId, name);
    ref.invalidate(slotListProvider);
  }

  Future<void> _deleteSlot(
    BuildContext context,
    WidgetRef ref,
    SlotSummary summary,
  ) async {
    final displayName = _slotDisplayName(summary);
    final ok = await _confirmDelete(
      context,
      title: UiStrings.slotDelete,
      body: UiStrings.slotDeleteConfirmFor(displayName),
      requiredName: displayName,
      action: UiStrings.slotDelete,
    );
    if (!ok) return;
    await IsarSetup.deleteSlot(summary.slotId);
    ref.invalidate(slotListProvider); // 删后刷新槽列表
  }

  Future<bool> _confirm(
    BuildContext context, {
    required String title,
    required String body,
    required String action,
    bool destructive = false,
  }) async {
    final r = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: WuxiaColors.panel,
        title: Text(
          title,
          style: const TextStyle(color: WuxiaColors.resultHighlight),
        ),
        content: Text(
          body,
          style: const TextStyle(color: WuxiaColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text(
              UiStrings.slotCancel,
              style: TextStyle(color: WuxiaColors.textMuted),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            child: Text(
              action,
              style: TextStyle(
                color: destructive
                    ? WuxiaColors.danger
                    : WuxiaColors.resultHighlight,
              ),
            ),
          ),
        ],
      ),
    );
    return r ?? false;
  }

  Future<String?> _renameDialog(
    BuildContext context,
    SlotSummary summary,
  ) async {
    var currentName = summary.slotName ?? '';
    return showDialog<String?>(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: WuxiaColors.panel,
        title: const Text(
          UiStrings.slotRenameTitle,
          style: TextStyle(color: WuxiaColors.resultHighlight),
        ),
        content: TextFormField(
          initialValue: currentName,
          onChanged: (value) => currentName = value,
          autofocus: true,
          style: const TextStyle(color: WuxiaColors.textPrimary),
          decoration: const InputDecoration(
            labelText: UiStrings.slotRenameInputLabel,
            helperText: UiStrings.slotRenameClearHint,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text(
              UiStrings.slotCancel,
              style: TextStyle(color: WuxiaColors.textMuted),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(c, currentName),
            child: const Text(
              UiStrings.slotRenameSave,
              style: TextStyle(color: WuxiaColors.resultHighlight),
            ),
          ),
        ],
      ),
    );
  }

  Future<bool> _confirmDelete(
    BuildContext context, {
    required String title,
    required String body,
    required String requiredName,
    required String action,
  }) async {
    var typedName = '';
    final r = await showDialog<bool>(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (context, setState) {
          final canDelete = typedName.trim() == requiredName;
          return AlertDialog(
            backgroundColor: WuxiaColors.panel,
            title: Text(
              title,
              style: const TextStyle(color: WuxiaColors.resultHighlight),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    body,
                    style: const TextStyle(color: WuxiaColors.textSecondary),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    UiStrings.slotDeleteProtectionValue(requiredName),
                    style: const TextStyle(color: WuxiaColors.textMuted),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    autofocus: true,
                    onChanged: (value) => setState(() => typedName = value),
                    style: const TextStyle(color: WuxiaColors.textPrimary),
                    decoration: const InputDecoration(
                      labelText: UiStrings.slotDeleteInputLabel,
                      helperText: UiStrings.slotDeleteProtectionHint,
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(c, false),
                child: const Text(
                  UiStrings.slotCancel,
                  style: TextStyle(color: WuxiaColors.textMuted),
                ),
              ),
              TextButton(
                onPressed: canDelete ? () => Navigator.pop(c, true) : null,
                child: Text(
                  action,
                  style: TextStyle(
                    color: canDelete
                        ? WuxiaColors.danger
                        : WuxiaColors.textMuted,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
    return r ?? false;
  }

  static String _slotDisplayName(SlotSummary summary) {
    final name = summary.slotName?.trim();
    if (name != null && name.isNotEmpty) return name;
    return UiStrings.slotCardTitle(summary.slotId);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final slotsAsync = ref.watch(slotListProvider);
    return Scaffold(
      backgroundColor: WuxiaColors.background,
      body: SafeArea(
        child: Center(
          child: slotsAsync.when(
            loading: () => const InkLoadingIndicator(),
            error: (e, _) => ErrorFallback(
              error: e,
              onRetry: () => ref.invalidate(slotListProvider),
            ),
            data: (slots) => SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 28),
                    child: Text(
                      UiStrings.slotSelectTitle,
                      style: TextStyle(
                        fontSize: 28,
                        color: WuxiaColors.resultHighlight,
                        letterSpacing: 6,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  for (final s in slots)
                    _SlotCard(
                      summary: s,
                      onTap: () => s.isEmpty
                          ? _confirmNewGame(context, ref, s.slotId)
                          : _enterSlot(context, ref, s.slotId),
                      onRename: s.isEmpty
                          ? null
                          : () => _renameSlot(context, ref, s),
                      onDelete: s.isEmpty
                          ? null
                          : () => _deleteSlot(context, ref, s),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SlotCard extends StatelessWidget {
  const _SlotCard({
    required this.summary,
    required this.onTap,
    this.onRename,
    this.onDelete,
  });

  final SlotSummary summary;
  final VoidCallback onTap;
  final VoidCallback? onRename;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final displayName = SaveSelectScreen._slotDisplayName(summary);
    return Container(
      width: 380,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 24),
      decoration: BoxDecoration(
        color: WuxiaColors.panel,
        border: Border.all(color: WuxiaColors.border),
        borderRadius: BorderRadius.circular(6),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          child: summary.isEmpty
              ? _EmptySlot(title: displayName)
              : _FilledSlot(
                  summary: summary,
                  displayName: displayName,
                  onRename: onRename,
                  onDelete: onDelete,
                ),
        ),
      ),
    );
  }
}

class _EmptySlot extends StatelessWidget {
  const _EmptySlot({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: WuxiaColors.resultHighlight,
                fontSize: 18,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              UiStrings.slotSaveEmpty,
              style: TextStyle(color: WuxiaColors.textSecondary),
            ),
          ],
        ),
      ),
      const Icon(Icons.chevron_right, color: WuxiaColors.textMuted),
    ],
  );
}

class _FilledSlot extends StatelessWidget {
  const _FilledSlot({
    required this.summary,
    required this.displayName,
    this.onRename,
    this.onDelete,
  });

  final SlotSummary summary;
  final String displayName;
  final VoidCallback? onRename;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final lastPlayed = summary.lastPlayed == null
        ? UiStrings.slotLastPlayedNever
        : UiStrings.slotLastPlayed(summary.lastPlayed!);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          displayName,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: WuxiaColors.resultHighlight,
                            fontSize: 18,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                      if (summary.isMostRecent) ...[
                        const SizedBox(width: 8),
                        const _RecentBadge(),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    UiStrings.slotFounderSummary(
                      summary.founderName ?? '',
                      summary.realmDisplay ?? '',
                    ),
                    style: const TextStyle(color: WuxiaColors.textSecondary),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(
                Icons.edit_outlined,
                color: WuxiaColors.textMuted,
              ),
              tooltip: UiStrings.slotRename,
              onPressed: onRename,
            ),
            IconButton(
              icon: const Icon(
                Icons.delete_outline,
                color: WuxiaColors.textMuted,
              ),
              tooltip: UiStrings.slotDelete,
              onPressed: onDelete,
            ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            _MetaPill(
              label: UiStrings.slotMainlineLabel,
              value: UiStrings.slotChapterProgress(
                summary.chapterIndex,
                summary.clearedStageCount,
              ),
            ),
            _MetaPill(
              label: UiStrings.slotTowerLabel,
              value: UiStrings.slotTowerProgress(summary.highestTowerFloor),
            ),
            _MetaPill(
              label: UiStrings.saveManagementLastOnlineAt,
              value: lastPlayed,
            ),
          ],
        ),
      ],
    );
  }
}

class _RecentBadge extends StatelessWidget {
  const _RecentBadge();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
    decoration: BoxDecoration(
      color: WuxiaColors.resultHighlight.withValues(alpha: 0.12),
      border: Border.all(color: WuxiaColors.resultHighlight),
      borderRadius: BorderRadius.circular(999),
    ),
    child: const Text(
      UiStrings.slotRecentBadge,
      style: TextStyle(color: WuxiaColors.resultHighlight, fontSize: 11),
    ),
  );
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
    decoration: BoxDecoration(
      color: WuxiaColors.background,
      border: Border.all(color: WuxiaColors.border),
      borderRadius: BorderRadius.circular(4),
    ),
    child: Text(
      '$label $value',
      style: const TextStyle(color: WuxiaColors.textSecondary, fontSize: 12),
    ),
  );
}
