import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/application/battle_providers.dart';
import '../../../shared/strings.dart';
import '../../../shared/theme/colors.dart';
import '../../battle/presentation/battle_screen.dart';
import '../application/sweep_controller.dart';
import '../application/sweep_unit.dart';
import '../domain/sweep_recap.dart';
import '../../../shared/widgets/wuxia_ui/ink_loading.dart';

/// 一键挂机扫荡屏：逐关托管真战斗，强制 auto + 快进连播，可中途停、战败 halt。
///
/// 红线：真跑每场战斗（非黑箱秒结）+ 不压缩离线时间 + 不发加速券 → 守 §5.5。
/// 入口门槛（本周目已首通）由 caller 判定，本屏只负责连播执行。
class SweepScreen extends ConsumerStatefulWidget {
  const SweepScreen({
    super.key,
    required this.units,
    required this.unitName,
    required this.cycle,
    this.towerRepeatNote = false,
  });

  /// 有序扫荡单位（主线整章关列表 / 整塔 30 层）。
  final List<SweepUnit> units;

  /// 标题用单位名（章名 / 「问鼎江湖」）。
  final String unitName;

  /// 本次扫荡的周目（全单位同周目，由 caller 的 cycleFor()/currentCycleIndex 决定）。
  /// HUD 与 recap 显「第N周目」，让玩家一眼知道扫的是哪个周目。
  final int cycle;

  /// 爬塔扫荡：顶部显「重打仅掉残页」说明（守 §5.1 防刷）。
  final bool towerRepeatNote;

  @override
  ConsumerState<SweepScreen> createState() => _SweepScreenState();
}

class _SweepScreenState extends ConsumerState<SweepScreen> {
  late final SweepController _controller;
  int _index = 0;
  bool _preparing = true;
  int _battleKey = 0;

  @override
  void initState() {
    super.initState();
    _controller = SweepController(totalUnits: widget.units.length);
    // battleProvider 是 autoDispose:`_preparing` spinner 期间本屏未挂 BattleScreen,
    // 没有 watcher。逐关注入(`startBattle`)若发生在这段无监听窗口,注入的队伍会被
    // autoDispose 回收重置回空团 → 后续挂出的 BattleScreen 拿到空团黑屏。挂一条永久
    // 监听跨本屏整个生命周期保活 provider,使逐关注入不被回收(挂载顺序兜底见
    // BattleScreen.initState 的 postFrame 自启 timer)。
    ref.listenManual(battleProvider, (_, _) {});
    WidgetsBinding.instance.addPostFrameCallback((_) => _startCurrent());
  }

  Future<void> _startCurrent() async {
    if (!mounted) return;
    setState(() => _preparing = true);
    try {
      await widget.units[_index].startBattle(ref);
    } catch (_) {
      // 装配失败 → halt（停在该关）。
      _controller.recordDefeat();
      if (mounted) setState(() => _preparing = false);
      return;
    }
    if (!mounted) return;
    setState(() {
      _preparing = false;
      _battleKey++;
    });
  }

  Future<void> _onVictory() async {
    final outcome = await widget.units[_index].settle(ref);
    // 战斗已胜；settle 异常（Isar 故障等）兜底空账继续，不阻塞连播。
    _controller.recordVictory(outcome ?? const SweepBattleOutcome());
    if (!mounted) return;
    if (_controller.isRunning) {
      _index++;
      final gap = ref
          .read(numbersConfigProvider)
          .animation
          .sweepInterBattleGapMs;
      await Future<void>.delayed(Duration(milliseconds: gap));
      if (!mounted) return;
      await _startCurrent();
    } else {
      setState(() {}); // 收工 → 显 recap
    }
  }

  void _onDefeat() {
    _controller.recordDefeat();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WuxiaColors.background,
      body: SafeArea(
        // config 仅连播分支需要（读 fastForward/gap）；recap 分支不读，
        // 使「装配失败→战败 recap」路径在无 GameRepository 的轻量测下可达。
        child: _controller.isRunning ? _buildRunning() : _buildRecap(),
      ),
    );
  }

  Widget _buildRunning() {
    final unit = widget.units[_index];
    return Stack(
      children: [
        if (_preparing)
          const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                InkLoadingIndicator(),
                SizedBox(height: 12),
                Text(
                  UiStrings.sweepPreparing,
                  style: TextStyle(color: WuxiaColors.textSecondary),
                ),
              ],
            ),
          )
        else
          // config 仅真正渲染 BattleScreen 时读（preparing spinner 不需要），
          // 避免首帧（GameRepository 未就绪的轻量测）崩。
          BattleScreen(
            key: ValueKey('sweep_battle_$_battleKey'),
            hint: unit.battleHint,
            sceneBackgroundPath: unit.sceneBackgroundPath,
            bgmTrack: unit.bgmTrack,
            animConfig: ref.watch(numbersConfigProvider).animation,
            startFastForward: true,
            // 扫荡「先注入战斗、后挂本屏」:开启挂载后兜底自启,否则错过 startBattle
            // 的 empty→非空边沿 → timer 不起黑屏 hang(配 initState listenManual 保活)。
            autoStartOnMount: true,
            deferVictoryToCaller: true,
            onVictory: _onVictory,
            onDefeat: _onDefeat,
          ),
        // 顶部进度 + 醒目停止按钮 overlay。
        Positioned(
          top: 8,
          left: 12,
          right: 12,
          child: _SweepHud(
            progressLabel: UiStrings.sweepProgress(
              _index + 1,
              widget.units.length,
            ),
            cycleLabel: UiStrings.sweepCycleBadge(widget.cycle),
            towerRepeatNote: widget.towerRepeatNote,
            onStop: _controller.requestStop,
          ),
        ),
      ],
    );
  }

  Widget _buildRecap() {
    final r = _controller.recap;
    final String title;
    final bool defeated = _controller.status == SweepStatus.stoppedByDefeat;
    switch (_controller.status) {
      case SweepStatus.completed:
        title = UiStrings.sweepRecapCompleted;
      case SweepStatus.stoppedByUser:
        title = UiStrings.sweepRecapStopped;
      case SweepStatus.stoppedByDefeat:
        title = UiStrings.sweepRecapDefeated(_index + 1);
      case SweepStatus.running:
        title = '';
    }

    final overviewRows = <String>[
      UiStrings.sweepRecapCycle(widget.cycle),
      UiStrings.sweepRecapStages(r.stagesCleared),
    ];
    final layers = r.resultLayers();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Container(
            padding: const EdgeInsets.fromLTRB(26, 24, 26, 26),
            decoration: BoxDecoration(
              color: WuxiaColors.panel,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: defeated ? WuxiaColors.hpLow : WuxiaColors.bossFrame,
                width: 1.5,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: WuxiaColors.resultHighlight,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (defeated) ...[
                  const SizedBox(height: 8),
                  const Text(
                    UiStrings.sweepDefeatReason,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: WuxiaColors.textMuted,
                      fontSize: 13,
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 10,
                  runSpacing: 8,
                  children: [
                    for (final line in overviewRows)
                      _SweepOverviewPill(text: line),
                  ],
                ),
                const SizedBox(height: 16),
                for (final layer in layers) ...[
                  _SweepResultLayerSection(layer: layer),
                  const SizedBox(height: 8),
                ],
                const SizedBox(height: 20),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: WuxiaColors.bossFrame,
                    foregroundColor: WuxiaColors.background,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () => Navigator.of(context).maybePop(),
                  child: const Text(
                    UiStrings.sweepRecapBack,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SweepOverviewPill extends StatelessWidget {
  const _SweepOverviewPill({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: WuxiaColors.border.withValues(alpha: 0.72)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: WuxiaColors.textSecondary,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _SweepResultLayerSection extends StatelessWidget {
  const _SweepResultLayerSection({required this.layer});

  final SweepResultLayer layer;

  @override
  Widget build(BuildContext context) {
    final borderColor = layer.highlighted
        ? WuxiaColors.resultHighlight
        : WuxiaColors.border;
    final titleColor = layer.highlighted
        ? WuxiaColors.resultHighlight
        : WuxiaColors.textMuted;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: borderColor.withValues(alpha: 0.72)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            layer.title,
            style: TextStyle(
              color: titleColor,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          for (final line in layer.lines)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text(
                line.text,
                style: TextStyle(
                  color: line.highlighted
                      ? WuxiaColors.resultHighlight
                      : WuxiaColors.textSecondary,
                  fontSize: 15,
                  fontWeight: line.highlighted
                      ? FontWeight.w700
                      : FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// 连播中顶部 HUD：进度条文字 + 醒目「停止扫荡」按钮（用户要求做明显）。
class _SweepHud extends StatelessWidget {
  const _SweepHud({
    required this.progressLabel,
    required this.cycleLabel,
    required this.onStop,
    required this.towerRepeatNote,
  });

  final String progressLabel;
  final String cycleLabel;
  final VoidCallback onStop;
  final bool towerRepeatNote;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: WuxiaColors.background.withValues(alpha: 0.58),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: WuxiaColors.border.withValues(alpha: 0.62)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: WuxiaColors.panel.withValues(alpha: 0.88),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: WuxiaColors.border),
                  ),
                  child: Text(
                    progressLabel,
                    style: const TextStyle(
                      color: WuxiaColors.resultHighlight,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                // 周目徽章：连播中也让玩家一眼看到扫的是第几周目。
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: WuxiaColors.panel.withValues(alpha: 0.88),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: WuxiaColors.bossFrame),
                  ),
                  child: Text(
                    cycleLabel,
                    style: const TextStyle(
                      color: WuxiaColors.bossFrame,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: WuxiaColors.sealCrimson,
                    foregroundColor: WuxiaColors.textPrimary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 11,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onPressed: onStop,
                  icon: const Icon(Icons.stop_circle_outlined, size: 20),
                  label: const Text(UiStrings.sweepStopButton),
                ),
              ],
            ),
            if (towerRepeatNote) ...[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: WuxiaColors.panel.withValues(alpha: 0.72),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  UiStrings.sweepTowerRepeatNote,
                  style: TextStyle(color: WuxiaColors.textMuted, fontSize: 12),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
