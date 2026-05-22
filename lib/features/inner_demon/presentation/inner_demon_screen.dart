import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/domain/enums.dart';
import '../../../data/defs/stage_def.dart';
import '../../../data/game_repository.dart';
import '../../../shared/theme/colors.dart';
import '../../mainline/presentation/stage_entry_flow.dart';

/// 心魔关 stage list 屏(1.0 P2.2 §12.1,Batch 2.3 占位 UI)。
///
/// 列 7 心魔关(stage_inner_demon_01..07,贪/嗔/痴/慢/疑/空/真),
/// 点击走 [runStageFlow]。
///
/// **Batch 2.3 范围限定**:本 widget 暂未接入 main_menu / chapter_list 入口
/// (Batch 2.5+ 决议入口方式);unlock 三态(cleared/available/locked 按
/// numbers.yaml `inner_demon.unlock_triggers` 链 + MainlineProgress.cleared
/// 集判定)也留 Batch 2.5。当前全 available 占位渲染,实际 isFirstClear /
/// drops / 升层路径走 [runStageFlow] 现有体例。
class InnerDemonScreen extends ConsumerWidget {
  const InnerDemonScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stages = GameRepository.instance.stageDefs.values
        .where((s) => s.stageType == StageType.innerDemon)
        .toList()
      ..sort((a, b) => a.id.compareTo(b.id));

    return Scaffold(
      backgroundColor: WuxiaColors.background,
      appBar: AppBar(
        title: const Text('心魔'),
        backgroundColor: WuxiaColors.sidebar,
        foregroundColor: WuxiaColors.textPrimary,
      ),
      body: SafeArea(
        child: stages.isEmpty
            ? const Center(
                child: Text(
                  '心魔七关未启',
                  style: TextStyle(color: WuxiaColors.textMuted),
                ),
              )
            : ListView.builder(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                itemCount: stages.length,
                itemBuilder: (ctx, i) {
                  final s = stages[i];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _InnerDemonRow(
                      def: s,
                      onTap: () => runStageFlow(
                        context: context,
                        ref: ref,
                        stage: s,
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}

class _InnerDemonRow extends StatelessWidget {
  const _InnerDemonRow({required this.def, required this.onTap});

  final StageDef def;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: WuxiaColors.sidebar,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      def.name,
                      style: const TextStyle(
                        color: WuxiaColors.textPrimary,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '难度 ${def.difficultyMultiplier.toStringAsFixed(1)}',
                      style: const TextStyle(
                        color: WuxiaColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: WuxiaColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}
