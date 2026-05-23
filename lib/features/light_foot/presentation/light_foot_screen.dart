import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/domain/enums.dart';
import '../../../data/defs/stage_def.dart';
import '../../../data/game_repository.dart';
import '../../../shared/theme/colors.dart';
import '../../mainline/application/mainline_providers.dart';
import '../../mainline/presentation/stage_entry_flow.dart';
import '../application/light_foot_service.dart';

/// 轻功试炼 stage list 屏(1.0 P3.1 §12.3,Batch B.3 reactive 三态)。
///
/// 5 轻功关(stage_light_foot_01..05,水面/屋脊/竹海/险崖/长风)按 unlock 链显:
///   - cleared(已通):右侧 ✓ 标识,可重入
///   - available(可挑战):主色显,点击走 [runStageFlow]
///   - locked(未解锁):灰显 + 锁图标,点击 disabled
///
/// **三态判定**(委派 [LightFootService.statusOf]):
///   - stage_06_05 是 light_foot_01 的 prev(Ch6 末关 victory → 自动解 _01)
///   - _01 victory → _02 解;_02 victory → _03 解;... 链式 5 关
///
/// **不接管 wuSheng 突破链**(平行支线 · 沿 inner_demon_screen 体例但不嵌
/// isLayerLocked 路径)。
class LightFootScreen extends ConsumerWidget {
  const LightFootScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stages = GameRepository.instance.stageDefs.values
        .where((s) => s.stageType == StageType.lightFoot)
        .toList()
      ..sort((a, b) => a.id.compareTo(b.id));
    final lightFootDef = GameRepository.instance.numbers.lightFoot;
    final async = ref.watch(mainlineProgressProvider);

    return Scaffold(
      backgroundColor: WuxiaColors.background,
      appBar: AppBar(
        title: const Text('轻功试炼'),
        backgroundColor: WuxiaColors.sidebar,
        foregroundColor: WuxiaColors.textPrimary,
      ),
      body: SafeArea(
        child: async.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: SelectableText(
              '加载失败：$e',
              style: const TextStyle(color: WuxiaColors.hpLow),
            ),
          ),
          data: (progress) {
            if (stages.isEmpty) {
              return const Center(
                child: Text(
                  '轻功五处试炼未启',
                  style: TextStyle(color: WuxiaColors.textMuted),
                ),
              );
            }
            final cleared = progress.clearedStageIds.toSet();
            return ListView.builder(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: stages.length,
              itemBuilder: (ctx, i) {
                final s = stages[i];
                final status = LightFootService.statusOf(
                  stageId: s.id,
                  config: lightFootDef,
                  clearedStageIds: cleared,
                );
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _LightFootRow(
                    def: s,
                    status: status,
                    onTap: status == LightFootStageStatus.locked
                        ? null
                        : () => runStageFlow(
                              context: context,
                              ref: ref,
                              stage: s,
                            ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _LightFootRow extends StatelessWidget {
  const _LightFootRow({
    required this.def,
    required this.status,
    required this.onTap,
  });

  final StageDef def;
  final LightFootStageStatus status;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final locked = status == LightFootStageStatus.locked;
    final cleared = status == LightFootStageStatus.cleared;
    final titleColor =
        locked ? WuxiaColors.textMuted : WuxiaColors.textPrimary;
    final borderColor =
        cleared ? WuxiaColors.hpHigh : WuxiaColors.border;
    final terrainLabel = _terrainLabel(def.terrainBiome);
    return Opacity(
      opacity: locked ? 0.45 : 1.0,
      child: Material(
        color: WuxiaColors.sidebar,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: borderColor),
            ),
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        def.name,
                        style: TextStyle(color: titleColor, fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$terrainLabel · 难度 '
                        '${def.difficultyMultiplier.toStringAsFixed(1)}',
                        style: const TextStyle(
                          color: WuxiaColors.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                _StatusIcon(status: status),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _terrainLabel(TerrainBiome? biome) {
    switch (biome) {
      case TerrainBiome.water:
        return '水面';
      case TerrainBiome.rooftop:
        return '屋脊';
      case TerrainBiome.bamboo:
        return '竹林';
      case null:
        return '平地';
    }
  }
}

class _StatusIcon extends StatelessWidget {
  const _StatusIcon({required this.status});
  final LightFootStageStatus status;

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case LightFootStageStatus.cleared:
        return const Icon(Icons.check_circle,
            size: 20, color: WuxiaColors.hpHigh);
      case LightFootStageStatus.available:
        return const Icon(Icons.chevron_right,
            size: 20, color: WuxiaColors.textMuted);
      case LightFootStageStatus.locked:
        return const Icon(Icons.lock_outline,
            size: 20, color: WuxiaColors.textMuted);
    }
  }
}
