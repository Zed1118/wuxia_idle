import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/defs/stage_def.dart';
import '../../data/narrative_loader.dart';
import '../../providers/battle_providers.dart';
import '../../providers/mainline_providers.dart';
import '../../services/mainline_progress_service.dart';
import '../../services/stage_battle_setup.dart';
import '../battle/battle_screen.dart';
import '../narrative/narrative_reader_screen.dart';

/// Phase 3 T37 关卡进入流程串联。
///
/// 状态机（async 串联，无中间 widget）：
///   1. opening：若 [StageDef.narrativeOpeningId] 非空，push NarrativeReaderScreen
///      → wait its pop
///   2. battle：装配 (left, right) 战斗双方 → push BattleScreen → wait
///      onVictory / onDefeat 回调（Completer 转 Future）
///   3a. victory：异步 recordVictory + invalidate progress provider；若
///       narrativeVictoryId 非空 → push 第二段剧情
///   3b. defeat：若 narrativeDefeatId 非空（章末 Boss 关）→ push 战败剧情；
///       不记录进度 / 不掉装备，返回 stage list（Phase 3 Week 5 销账 #29）
///
/// **不嵌套 widget**：每段结束后栈上仅剩 stage_list_screen，避免多层 pop。
Future<void> runStageFlow({
  required BuildContext context,
  required WidgetRef ref,
  required StageDef stage,
}) async {
  // ── opening ──
  if (stage.narrativeOpeningId != null) {
    final opening = await NarrativeLoader.load(stage.narrativeOpeningId!);
    if (!context.mounted) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => NarrativeReaderScreen(
          content: opening,
          fallbackTitle: stage.name,
        ),
      ),
    );
  }

  // ── battle ──
  if (!context.mounted) return;
  final won = await _runBattle(context: context, ref: ref, stage: stage);

  // ── defeat ──
  if (!won) {
    if (stage.narrativeDefeatId != null && context.mounted) {
      final defeat = await NarrativeLoader.load(stage.narrativeDefeatId!);
      if (!context.mounted) return;
      await Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (_) => NarrativeReaderScreen(
            content: defeat,
            fallbackTitle: '${stage.name} · 战败',
          ),
        ),
      );
    }
    return; // 战败不记录、不推 victory 剧情
  }

  // ── victory ──
  await MainlineProgressService.recordVictory(
    stageId: stage.id,
    now: DateTime.now(),
  );
  ref.invalidate(mainlineProgressProvider);

  if (stage.narrativeVictoryId != null) {
    if (!context.mounted) return;
    final victory = await NarrativeLoader.load(stage.narrativeVictoryId!);
    if (!context.mounted) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => NarrativeReaderScreen(
          content: victory,
          fallbackTitle: '${stage.name} · 胜利',
        ),
      ),
    );
  }
}

/// 推 BattleScreen 并 wait 胜/败回调；返回 true=胜，false=败/平。
Future<bool> _runBattle({
  required BuildContext context,
  required WidgetRef ref,
  required StageDef stage,
}) async {
  final completer = Completer<bool>();
  await Navigator.of(context).push<void>(
    MaterialPageRoute(
      builder: (_) => _StageBattleHost(
        stage: stage,
        onVictory: () {
          if (!completer.isCompleted) completer.complete(true);
        },
        onDefeat: () {
          if (!completer.isCompleted) completer.complete(false);
        },
      ),
    ),
  );
  // BattleScreen 通过结算 dialog 关闭按钮自己 pop；此时回调已 complete。
  // 极端兜底：如果用户系统返回键直接 pop，没触发回调，按"未胜"处理。
  if (!completer.isCompleted) completer.complete(false);
  return completer.future;
}

/// BattleScreen 的 setup 容器：initState 装配队伍 + startBattle，
/// 然后渲染 [BattleScreen]。沿用 [BattleDemoLauncher] 的 postFrameCallback 模式。
class _StageBattleHost extends ConsumerStatefulWidget {
  const _StageBattleHost({
    required this.stage,
    required this.onVictory,
    required this.onDefeat,
  });

  final StageDef stage;
  final VoidCallback onVictory;
  final VoidCallback onDefeat;

  @override
  ConsumerState<_StageBattleHost> createState() => _StageBattleHostState();
}

class _StageBattleHostState extends ConsumerState<_StageBattleHost> {
  String? _setupError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      try {
        final (left, right) = await StageBattleSetup.buildTeams(widget.stage);
        if (!mounted) return;
        ref.read(battleProvider.notifier).startBattle(left, right);
      } catch (e) {
        if (!mounted) return;
        setState(() => _setupError = e.toString());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_setupError != null) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.stage.name)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: SelectableText('战斗准备失败：$_setupError'),
          ),
        ),
      );
    }
    return BattleScreen(
      hint: widget.stage.name,
      onVictory: () {
        widget.onVictory();
        // 自己 pop，让 runStageFlow 的 push await 解开
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      },
      onDefeat: () {
        widget.onDefeat();
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      },
    );
  }
}
