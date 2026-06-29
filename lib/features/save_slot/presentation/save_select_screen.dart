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

  Future<void> _deleteSlot(BuildContext context, WidgetRef ref, int n) async {
    final ok = await _confirm(
      context,
      title: UiStrings.slotDelete,
      body: UiStrings.slotDeleteConfirm,
      action: UiStrings.slotDelete,
      destructive: true,
    );
    if (!ok) return;
    await IsarSetup.deleteSlot(n);
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
        title: Text(title,
            style: const TextStyle(color: WuxiaColors.resultHighlight)),
        content: Text(body,
            style: const TextStyle(color: WuxiaColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text(UiStrings.slotCancel,
                style: TextStyle(color: WuxiaColors.textMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            child: Text(action,
                style: TextStyle(
                    color: destructive
                        ? WuxiaColors.danger
                        : WuxiaColors.resultHighlight)),
          ),
        ],
      ),
    );
    return r ?? false;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final slotsAsync = ref.watch(slotListProvider);
    return Scaffold(
      backgroundColor: WuxiaColors.background,
      body: SafeArea(
        child: Center(
          child: slotsAsync.when(
            loading: () => const CircularProgressIndicator(),
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
                      onDelete: s.isEmpty
                          ? null
                          : () => _deleteSlot(context, ref, s.slotId),
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
    this.onDelete,
  });

  final SlotSummary summary;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final subtitle = summary.isEmpty
        ? UiStrings.slotSaveEmpty
        : '${summary.founderName} · ${summary.realmDisplay}\n'
            '${UiStrings.slotChapterProgress(summary.chapterIndex, summary.clearedStageCount)}';
    return Container(
      width: 380,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 24),
      decoration: BoxDecoration(
        color: WuxiaColors.panel,
        border: Border.all(color: WuxiaColors.border),
        borderRadius: BorderRadius.circular(6),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
        title: Text(
          UiStrings.slotCardTitle(summary.slotId),
          style: const TextStyle(
            color: WuxiaColors.resultHighlight,
            fontSize: 18,
            letterSpacing: 2,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            subtitle,
            style: const TextStyle(
                color: WuxiaColors.textSecondary, height: 1.4),
          ),
        ),
        isThreeLine: !summary.isEmpty,
        onTap: onTap,
        trailing: onDelete == null
            ? const Icon(Icons.chevron_right, color: WuxiaColors.textMuted)
            : IconButton(
                icon: const Icon(Icons.delete_outline,
                    color: WuxiaColors.textMuted),
                tooltip: UiStrings.slotDelete,
                onPressed: onDelete,
              ),
      ),
    );
  }
}
