import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/game_repository.dart';
import '../../../data/isar_setup.dart';
import '../../../data/narrative_loader.dart';
import '../../../shared/strings.dart';
import '../../narrative/presentation/narrative_reader_screen.dart';
import '../application/disciple_join_service.dart';
import 'disciple_join_overlay.dart';

/// 第七阶段批三:过 join 触发关后弹拜师叙事 + 最小立绘题字(不显伤害)。
///
/// 仅命中 lineage_onboarding.disciple_joins 且未触发过才执行([DiscipleJoinService]
/// 内 gate;非 join 关 / 已触发 → 返回 null,本 hook no-op)。
/// 纯展示 + 调用已建好的 service;不碰战斗 / 伤害 / 离线挂机(挂机不进 runStageFlow,
/// 天然不触发)。
Future<void> runDiscipleJoinHookAfterVictory({
  required BuildContext context,
  required WidgetRef ref,
  required String stageId,
}) async {
  // Isar 未 ready(纯 DI flow 测 / 早期启动)→ no-op,不阻塞胜利流。
  final isar = IsarSetup.instanceOrNull;
  if (isar == null) return;
  final svc = DiscipleJoinService(isar: isar);
  final joined = await svc.joinForClearedStage(stageId);
  if (joined == null) return;

  // 选对应拜师 narrative:join 配置里 stageId 的次序决定 first/second。
  final joins = GameRepository.instance.numbers.lineageOnboarding.discipleJoins;
  final isFirst = joins.isNotEmpty && joins.first.stageId == stageId;
  final narrativeId =
      isFirst ? 'lineage_first_disciple_join' : 'lineage_second_disciple_join';

  if (context.mounted) {
    final content = await NarrativeLoader.load(narrativeId);
    if (context.mounted) {
      await Navigator.of(context).push<void>(MaterialPageRoute(
        builder: (_) => NarrativeReaderScreen(
          content: content,
          fallbackTitle: UiStrings.discipleJoinCaption(joined.name),
        ),
      ));
    }
  }
  if (context.mounted) {
    await presentDiscipleJoin(
      context,
      // portraitPath 为 String? → 空串走 errorBuilder 纸调兜底。
      portraitPath: joined.portraitPath ?? '',
      caption: UiStrings.discipleJoinCaption(joined.name),
    );
  }
}
