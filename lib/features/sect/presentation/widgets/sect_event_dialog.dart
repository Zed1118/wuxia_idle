import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yaml/yaml.dart';

import '../../../../shared/strings.dart';
import '../../../../shared/theme/colors.dart';
import '../../application/sect_providers.dart';
import '../../domain/sect.dart';
import '../../domain/sect_event.dart';
import '../../domain/sect_outcome.dart';
import '../../../../shared/widgets/wuxia_ui/ink_loading.dart';

/// 门派事件弹窗(1.0 P3.4 §12.1,Batch 2.3 nightshift T16 · spec §4+§5)。
///
/// 弹 narrative.opening + 「应战」/「拒绝」按钮:
/// - 「应战」→ 模拟战斗 → BattleResult win/loss → resolve(SectOutcome.win|loss)
/// - 「拒绝」→ resolve(SectOutcome.loss)(spec §4 末段「拒绝 = reputation -5」)
///
/// **挂账 Phase 4**:真 BattleScreen wire(StageBattleSetup + buildMirrorEnemyTeam
/// 镜像同境界 enemy + push BattleScreen 等结算 dialog · 沿 stage_entry_flow 体例)。
/// 当前 Demo 走 [Random.nextBool] 模拟 50/50 结果,「默认 ground strategy 不引入新
/// 数值轴」spec 意图保留(无新数值,数值红线零碰)。
class SectEventDialog extends ConsumerStatefulWidget {
  const SectEventDialog({
    super.key,
    required this.event,
    required this.sect,
    @visibleForTesting this.rng,
    @visibleForTesting this.narrativeLoader,
  });

  final SectEvent event;
  final Sect sect;
  final Random? rng;
  final Future<String> Function(String path)? narrativeLoader;

  @override
  ConsumerState<SectEventDialog> createState() => _SectEventDialogState();
}

class _SectEventDialogState extends ConsumerState<SectEventDialog> {
  late Future<_NarrativeData> _future;

  @override
  void initState() {
    super.initState();
    _future = _loadNarrative();
  }

  Future<_NarrativeData> _loadNarrative() async {
    final loader = widget.narrativeLoader ?? rootBundle.loadString;
    final path = 'data/lore/sect_event/${widget.event.narrativeId}.yaml';
    try {
      final str = await loader(path);
      final yaml = loadYaml(str) as Map;
      return _NarrativeData(
        title: (yaml['title'] as String?) ?? widget.event.narrativeId,
        opening: (yaml['opening'] as String?) ?? UiStrings.sectEventNarrativeFallbackOpening,
        victoryText: (yaml['victory_text'] as String?) ?? UiStrings.sectEventNarrativeFallbackVictory,
        defeatText: (yaml['defeat_text'] as String?) ?? UiStrings.sectEventNarrativeFallbackDefeat,
      );
    } catch (_) {
      return _NarrativeData(
        title: widget.event.narrativeId,
        opening: UiStrings.sectEventNarrativeFallbackOpening,
        victoryText: UiStrings.sectEventNarrativeFallbackVictory,
        defeatText: UiStrings.sectEventNarrativeFallbackDefeat,
      );
    }
  }

  void _handleAccept(_NarrativeData narrative) {
    final rng = widget.rng ?? Random();
    final win = rng.nextBool();
    final outcome = win ? SectOutcome.win : SectOutcome.loss;
    ref.read(resolveSectEventProvider.notifier).resolve(
          sect: widget.sect,
          event: widget.event,
          outcome: outcome,
        );
    if (!mounted) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(win ? narrative.victoryText : narrative.defeatText),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _handleRefuse() {
    ref.read(resolveSectEventProvider.notifier).resolve(
          sect: widget.sect,
          event: widget.event,
          outcome: SectOutcome.loss,
        );
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: WuxiaColors.sidebar,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: WuxiaColors.border),
      ),
      child: FutureBuilder<_NarrativeData>(
        future: _future,
        builder: (ctx, snap) {
          if (!snap.hasData) {
            return const Padding(
              padding: EdgeInsets.all(24),
              child: SizedBox(
                width: 40,
                height: 40,
                child: InkLoadingIndicator(),
              ),
            );
          }
          final n = snap.data!;
          return ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 480,
              // L1(审计):限高 80% 屏,长事件文案在 720p 不再 bottom overflow。
              maxHeight: MediaQuery.of(context).size.height * 0.8,
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    n.title,
                    style: const TextStyle(
                      color: WuxiaColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // L1(审计):opening 为 yaml 自由文案,长文在 720p 会溢出 →
                  // Flexible + 滚动,标题与按钮保持固定可见。
                  Flexible(
                    child: SingleChildScrollView(
                      child: Text(
                        n.opening,
                        style: const TextStyle(
                          color: WuxiaColors.textSecondary,
                          fontSize: 14,
                          height: 1.6,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: _handleRefuse,
                        child: const Text(
                          UiStrings.sectEventRefuseButton,
                          style: TextStyle(color: WuxiaColors.textMuted),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () => _handleAccept(n),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: WuxiaColors.hpHigh,
                          foregroundColor: WuxiaColors.textPrimary,
                        ),
                        child: const Text(UiStrings.sectEventEnterBattle),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _NarrativeData {
  const _NarrativeData({
    required this.title,
    required this.opening,
    required this.victoryText,
    required this.defeatText,
  });
  final String title;
  final String opening;
  final String victoryText;
  final String defeatText;
}
