import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/game_repository.dart';
import '../../../data/defs/sect_candidate_def.dart';
import '../../../data/isar_setup.dart';
import '../../../shared/strings.dart';
import '../../../shared/theme/colors.dart';
import '../../../shared/widgets/portrait_frame.dart';
import '../../sect/presentation/sect_recruit_handler.dart';

class SectRecruitDebugScreen extends ConsumerStatefulWidget {
  const SectRecruitDebugScreen({super.key});

  @override
  ConsumerState<SectRecruitDebugScreen> createState() =>
      _SectRecruitDebugScreenState();
}

class _SectRecruitDebugScreenState
    extends ConsumerState<SectRecruitDebugScreen> {
  bool _busy = false;

  Future<void> _recruit(SectCandidateDef candidate) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final isar = IsarSetup.instanceOrNull;
      if (isar == null) {
        throw StateError('Isar 未初始化');
      }
      if (!mounted) return;
      final result = await runSectRecruitFlow(
        context: context,
        ref: ref,
        isar: isar,
        candidate: candidate,
        onMarkTriggered: () async {},
        onFallback: null,
        successSnackBar: UiStrings.stageBossRecruitSuccess(candidate.name),
        capFullSnackBar: UiStrings.stageBossRecruitCapFull(candidate.name),
        noSectSnackBar: UiStrings.stageBossRecruitNoSect(candidate.name),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('结果: ${result.name}')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('失败: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final candidates =
        GameRepository.instance.sectCandidates.values.toList();
    return Scaffold(
      backgroundColor: WuxiaColors.background,
      appBar: AppBar(
        title: const Text('强制招募 NPC'),
        backgroundColor: WuxiaColors.sidebar,
        foregroundColor: WuxiaColors.textPrimary,
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (_busy) const LinearProgressIndicator(minHeight: 2),
            Expanded(
              child: candidates.isEmpty
                  ? const Center(
                      child: Text('无候选 NPC',
                          style: TextStyle(color: WuxiaColors.textMuted)),
                    )
                  : ListView.builder(
                      itemCount: candidates.length,
                      itemBuilder: (_, i) {
                        final c = candidates[i];
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 6),
                          child: InkWell(
                            onTap: () => _recruit(c),
                            borderRadius: BorderRadius.circular(6),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: WuxiaColors.panel,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: WuxiaColors.border),
                              ),
                              child: Row(
                                children: [
                                  PortraitFrame(
                                    portraitPath: c.portraitPath,
                                    size: 40,
                                    borderColor: c.school == null
                                        ? WuxiaColors.border
                                        : WuxiaColors.schoolColor(c.school!),
                                    placeholderText: c.name,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${c.name} (${c.id})',
                                          style: const TextStyle(
                                            color: WuxiaColors.textPrimary,
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${c.school?.name ?? "无"} · ${c.defaultRealm.name}',
                                          style: const TextStyle(
                                            color: WuxiaColors.textMuted,
                                            fontSize: 12,
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
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
