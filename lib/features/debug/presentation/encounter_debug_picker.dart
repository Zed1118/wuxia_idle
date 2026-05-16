import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/game_repository.dart';
import '../../../data/isar_setup.dart';
import '../../encounter/application/encounter_service.dart';
import '../../encounter/domain/encounter_def.dart';
import '../../encounter/domain/encounter_event_loader.dart';
import '../../encounter/presentation/encounter_dialog.dart';
import '../../../ui/strings.dart';
import '../../../ui/theme/colors.dart';

/// 奇遇强制触发 debug picker(W14-3 round2 之后追加)。
///
/// 用途:绕过 [EncounterService.evaluateTriggers] 的 fortune 软概率,
/// 让 Codex 视觉验收时直接选 encounter id 触发 dialog + outcome 流。
///
/// 走 `encounter_hook.dart` 同体例(getOrCreate → markTriggered → load content →
/// showDialog → applyOutcome → showBanner),仅省略 recordKill / evaluateTriggers
/// 两步(debug 强制触发,不需 trigger 校验)。
///
/// 副作用:markTriggered 后该 encounter 进 triggeredEncounterIds,正常 hook 不再
/// 重选它;applyOutcome 会落 attribute / unlockSkill 永久记录。VC seed 后整存档
/// 是 throwaway,无需担心污染。
class EncounterDebugPickerScreen extends ConsumerStatefulWidget {
  const EncounterDebugPickerScreen({super.key});

  @override
  ConsumerState<EncounterDebugPickerScreen> createState() =>
      _EncounterDebugPickerScreenState();
}

class _EncounterDebugPickerScreenState
    extends ConsumerState<EncounterDebugPickerScreen> {
  bool _busy = false;

  Future<void> _trigger(EncounterDef def) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final isar = IsarSetup.instanceOrNull;
      if (isar == null) {
        throw StateError('Isar 未初始化(请先跑 Phase2 任一种子)');
      }

      final svc = EncounterService(isar: isar);
      await svc.getOrCreate(saveDataId: IsarSetup.currentSlotId);
      await svc.markTriggered(
        saveDataId: IsarSetup.currentSlotId,
        encounterId: def.id,
      );

      final content = await EncounterEventLoader.load(def.id);
      if (!mounted) return;

      final outcomeId = await showEncounterDialog(
        context: context,
        def: def,
        content: content,
      );
      if (outcomeId == null || !mounted) return;

      final applied = await svc.applyOutcome(
        saveDataId: IsarSetup.currentSlotId,
        encounter: def,
        outcomeId: outcomeId,
      );
      if (!mounted) return;
      showEncounterOutcomeBanner(context: context, applied: applied);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('触发失败:$e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final defs = GameRepository.instance.encounterDefs.values.toList()
      ..sort((a, b) => a.id.compareTo(b.id));
    return Scaffold(
      backgroundColor: WuxiaColors.background,
      appBar: AppBar(
        title: const Text(UiStrings.encounterDebugPickerTitle),
        backgroundColor: WuxiaColors.sidebar,
        foregroundColor: WuxiaColors.textPrimary,
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (_busy)
              const LinearProgressIndicator(minHeight: 2),
            Expanded(
              child: defs.isEmpty
                  ? const Center(
                      child: Text(
                        '无可触发奇遇',
                        style: TextStyle(color: WuxiaColors.textMuted),
                      ),
                    )
                  : ListView.builder(
                      itemCount: defs.length,
                      itemBuilder: (ctx, i) =>
                          _EncounterTile(def: defs[i], onTap: _trigger),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EncounterTile extends StatelessWidget {
  const _EncounterTile({required this.def, required this.onTap});

  final EncounterDef def;
  final Future<void> Function(EncounterDef) onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        onTap: () => onTap(def),
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: WuxiaColors.panel,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: WuxiaColors.border),
          ),
          child: Row(
            children: [
              const Icon(Icons.auto_awesome,
                  color: WuxiaColors.resultHighlight, size: 18),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      def.id,
                      style: const TextStyle(
                        color: WuxiaColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      def.type.name,
                      style: const TextStyle(
                        color: WuxiaColors.textMuted,
                        fontSize: 12,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right,
                  color: WuxiaColors.textMuted, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
