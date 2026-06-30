import 'dart:async';

import 'package:flutter/material.dart';

import '../../../data/game_repository.dart';
import '../../../shared/strings.dart';
import '../../../shared/theme/colors.dart';
import '../../../shared/widgets/wuxia_ui/wuxia_ui.dart';
import '../../battle/domain/enum_localizations.dart' show EnumL10n;
import '../application/encounter_service.dart';
import '../domain/encounter_def.dart';
import '../domain/encounter_event_loader.dart';

/// 奇遇 / 武学领悟弹窗(Phase 4 W14-1)。
///
/// 三段式:
///   1. opening:title + opening 文字(`events/[id].yaml`)
///   2. choices:按钮列表(choice.text → onTap select)
///   3. outcome:body 文字 + outcome 应用结果摘要(EncounterService 返回值)
///
/// 不引入 Riverpod 弹窗集成 — caller(stage_entry_flow)负责 service 调用,
/// dialog 只负责呈现 + 返回 outcome_id(string)。
///
/// 设计参考 GDD §1 + §5.7:水墨克制色调,不教程化,文字慢节奏。
///
/// 返回值:玩家选的 outcome_id(用于 caller 调 [EncounterService.applyOutcome])。
/// null = 玩家系统返回键关闭(未选,等价 skip 但不写 Isar)。
Future<String?> showEncounterDialog({
  required BuildContext context,
  required EncounterDef def,
  required EncounterContent content,
}) {
  return showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => _EncounterDialog(def: def, content: content),
  );
}

class _EncounterDialog extends StatefulWidget {
  const _EncounterDialog({required this.def, required this.content});

  final EncounterDef def;
  final EncounterContent content;

  @override
  State<_EncounterDialog> createState() => _EncounterDialogState();
}

class _EncounterDialogState extends State<_EncounterDialog> {
  static const _entryDuration = Duration(milliseconds: 500);
  static const _switchDuration = Duration(milliseconds: 420);

  EncounterChoice? _selected;
  bool _entered = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _entered = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selected;
    final size = MediaQuery.sizeOf(context);
    final maxWidth = (size.width - 32).clamp(320.0, 640.0).toDouble();
    final maxHeight = (size.height - 48).clamp(360.0, 720.0).toDouble();
    return Dialog(
      backgroundColor: WuxiaColors.panel,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: WuxiaColors.border),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth, maxHeight: maxHeight),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: AnimatedOpacity(
            opacity: _entered ? 1.0 : 0.0,
            duration: _entryDuration,
            curve: Curves.easeOut,
            child: AnimatedSize(
              duration: _switchDuration,
              curve: Curves.easeOut,
              alignment: Alignment.topCenter,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _TitleBar(
                    title:
                        widget.content.title ??
                        UiStrings.encounterDialogTitleFallback,
                  ),
                  const SizedBox(height: 20),
                  AnimatedSwitcher(
                    duration: _switchDuration,
                    switchInCurve: Curves.easeIn,
                    switchOutCurve: Curves.easeOut,
                    transitionBuilder: (child, animation) =>
                        FadeTransition(opacity: animation, child: child),
                    child: selected == null
                        ? _OpeningStage(
                            key: const ValueKey('opening'),
                            opening: widget.content.opening,
                            choices: widget.content.choices,
                            onSelect: (c) => setState(() => _selected = c),
                          )
                        : _OutcomeStage(
                            key: const ValueKey('outcome'),
                            choice: selected,
                            onConfirm: () =>
                                Navigator.of(context).pop(selected.outcomeId),
                          ),
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

class _OpeningStage extends StatelessWidget {
  const _OpeningStage({
    super.key,
    required this.opening,
    required this.choices,
    required this.onSelect,
  });

  final String opening;
  final List<EncounterChoice> choices;
  final ValueChanged<EncounterChoice> onSelect;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _OpeningText(text: opening),
        const SizedBox(height: 24),
        for (var i = 0; i < choices.length; i++) ...[
          if (i > 0) const SizedBox(height: 10),
          _ChoiceButton(
            text: choices[i].text,
            onTap: () => onSelect(choices[i]),
          ),
        ],
      ],
    );
  }
}

class _OutcomeStage extends StatelessWidget {
  const _OutcomeStage({
    super.key,
    required this.choice,
    required this.onConfirm,
  });

  final EncounterChoice choice;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _OutcomeBody(text: choice.body),
        const SizedBox(height: 24),
        _ConfirmButton(onTap: onConfirm),
      ],
    );
  }
}

class _TitleBar extends StatelessWidget {
  const _TitleBar({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(
          Icons.auto_awesome,
          color: WuxiaColors.resultHighlight,
          size: 18,
        ),
        const SizedBox(width: 8),
        const Text(
          UiStrings.encounterDialogTitleLabel,
          style: TextStyle(
            color: WuxiaColors.textMuted,
            fontSize: 13,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: WuxiaColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w500,
              letterSpacing: 1,
            ),
          ),
        ),
      ],
    );
  }
}

class _OpeningText extends StatelessWidget {
  const _OpeningText({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: WuxiaColors.textSecondary,
        fontSize: 15,
        height: 1.8,
      ),
    );
  }
}

class _OutcomeBody extends StatelessWidget {
  const _OutcomeBody({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final shown = text.isNotEmpty
        ? text
        : UiStrings.encounterDialogOutcomeBodyFallback;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: WuxiaColors.background,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: WuxiaColors.border),
      ),
      child: Text(
        shown,
        style: const TextStyle(
          color: WuxiaColors.textPrimary,
          fontSize: 15,
          height: 1.8,
        ),
      ),
    );
  }
}

class _ChoiceButton extends StatelessWidget {
  const _ChoiceButton({required this.text, required this.onTap});
  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        constraints: const BoxConstraints(minHeight: 52),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
        decoration: BoxDecoration(
          color: WuxiaColors.sidebar,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: WuxiaColors.inkPanelEdge),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.chevron_right,
              color: WuxiaColors.resultHighlight,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  color: WuxiaColors.textPrimary,
                  fontSize: 15,
                  height: 1.35,
                  letterSpacing: 1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConfirmButton extends StatelessWidget {
  const _ConfirmButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 112),
        child: PlaqueButton(
          label: UiStrings.encounterDialogConfirmButton,
          primary: true,
          autofocus: true,
          onTap: onTap,
        ),
      ),
    );
  }
}

/// outcome 应用后的「机缘入身」仪式浮层(P_NIGHT_UI 升级)。
///
/// caller(encounter_hook)在 [EncounterService.applyOutcome] 返回后调。
/// 旧形态为底部 3 秒薄条 SnackBar,对「领悟新招」这类奖励大节点仪式感不足;
/// 现升级为 **居中仪式浮层**:放大装帧的 [CeremonyImagePanel](宣纸底 + 仪式
/// 底图 veil + 发光描边 + 投影)+ 淡入轻缩放入场 + 停留 ~3.2s 自动消失 +
/// 轻触任意处提前关闭(不硬阻断挂机流)。投递方式与 skill_treasure_overlay /
/// treasure_drop_overlay 一致:`showGeneralDialog` + 自管 AnimationController。
///
/// W15 C-2 语义保持:UnlockSkillApplied 摘要用 SkillDef.name 中文招名;
/// GameRepository 未加载或 id 未注册时降级回 raw id(test fixture 不全 / race 兜底)。
///
/// fire-and-forget:浮层自管生命周期(auto-dismiss / tap 关闭后 Navigator.pop),
/// caller 无需 await。
void showEncounterOutcomeBanner({
  required BuildContext context,
  required OutcomeApplied applied,
}) {
  final outcome = _EncounterOutcomePresentation.from(applied);
  unawaited(
    showGeneralDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.transparent,
      transitionDuration: Duration.zero,
      pageBuilder: (ctx, _, _) => EncounterOutcomeOverlay(
        title: outcome.title,
        message: outcome.message,
        icon: outcome.icon,
        color: outcome.color,
        onDone: () => Navigator.of(ctx).pop(),
      ),
    ),
  );
}

/// 「机缘入身」居中仪式浮层(动画 + auto-dismiss + 轻触关闭)。
///
/// 结构对齐 [SkillTreasureOverlay]:
/// - AnimationController 420ms 淡入 + 轻微缩放(0.92→1.0)入场
/// - auto-dismiss([_holdDuration] 后,~3.2s)
/// - 轻触任意处提前关闭
/// - once-guard([_done])防 auto + tap 双触发
///
/// 纯展示层:不读写 BattleState / Isar。公开便于 widget test 直接 pump。
class EncounterOutcomeOverlay extends StatefulWidget {
  const EncounterOutcomeOverlay({
    super.key,
    required this.title,
    required this.message,
    required this.icon,
    required this.color,
    required this.onDone,
  });

  final String title;
  final String message;
  final IconData icon;
  final Color color;
  final VoidCallback onDone;

  @override
  State<EncounterOutcomeOverlay> createState() =>
      _EncounterOutcomeOverlayState();
}

class _EncounterOutcomeOverlayState extends State<EncounterOutcomeOverlay>
    with SingleTickerProviderStateMixin {
  static const _holdDuration = Duration(milliseconds: 3200);

  late final AnimationController _ctrl;
  late final Animation<double> _scale;
  late final Animation<double> _opacity;
  bool _done = false;
  Timer? _autoTimer;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    final curve = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _scale = Tween<double>(begin: 0.92, end: 1.0).animate(curve);
    _opacity = Tween<double>(begin: 0.0, end: 1.0).animate(curve);
    _ctrl.forward();
    _autoTimer = Timer(_holdDuration, _finish);
  }

  void _finish() {
    if (_done) return;
    _done = true;
    widget.onDone();
  }

  @override
  void dispose() {
    _autoTimer?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _finish,
      behavior: HitTestBehavior.opaque,
      child: Container(
        color: const Color(0x99000000),
        alignment: Alignment.center,
        child: FadeTransition(
          opacity: _opacity,
          child: ScaleTransition(
            scale: _scale,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: EncounterOutcomeToast(
                title: widget.title,
                message: widget.message,
                icon: widget.icon,
                color: widget.color,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 「机缘入身」仪式浮层静态内容(放大装帧 · 无动画)。
///
/// 居中竖排:放大图标盒 + 题字标题 + 摘要正文 + 轻触提示。装帧复用
/// [CeremonyImagePanel](宣纸底 / 仪式底图 veil / 发光描边 / 投影),尺度
/// 明显大于旧薄条(图标盒 32→56 / icon 19→32 / 标题 12→16 / 正文 14→20 /
/// padding 12→28)。导出便于 widget test 直接 pump,不依赖 GameRepository。
class EncounterOutcomeToast extends StatelessWidget {
  const EncounterOutcomeToast({
    super.key,
    required this.title,
    required this.message,
    required this.icon,
    required this.color,
  });

  final String title;
  final String message;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 420),
      child: CeremonyImagePanel(
        assetPath: WuxiaUi.ceremonyInsightBamboo,
        padding: const EdgeInsets.fromLTRB(28, 26, 28, 22),
        borderColor: color.withValues(alpha: 0.62),
        imageOpacity: 0.30,
        paperVeilOpacity: 0.74,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: color.withValues(alpha: 0.56),
                  width: 1.4,
                ),
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: WuxiaUi.ink,
                fontSize: 16,
                fontWeight: FontWeight.w900,
                letterSpacing: 4,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: WuxiaUi.ink,
                fontSize: 20,
                fontWeight: FontWeight.w800,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              UiStrings.splashTapToContinue,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: WuxiaUi.muted,
                fontSize: 11,
                letterSpacing: 3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EncounterOutcomePresentation {
  const _EncounterOutcomePresentation({
    required this.title,
    required this.message,
    required this.icon,
    required this.color,
  });

  final String title;
  final String message;
  final IconData icon;
  final Color color;

  factory _EncounterOutcomePresentation.from(OutcomeApplied applied) {
    return switch (applied) {
      UnlockSkillApplied(:final skillId) => _EncounterOutcomePresentation(
        title: UiStrings.encounterOutcomeSkillTitle,
        message: UiStrings.encounterOutcomeSkillUnlocked(
          _resolveSkillName(skillId),
        ),
        icon: Icons.auto_awesome,
        color: WuxiaColors.resultHighlight,
      ),
      AttributeBonusApplied(:final key, :final delta) =>
        _EncounterOutcomePresentation(
          title: UiStrings.encounterOutcomeAttributeTitle,
          message: UiStrings.encounterOutcomeAttributeBonus(
            EnumL10n.attributeKey(key),
            delta,
          ),
          icon: Icons.spa_outlined,
          color: WuxiaColors.gangMeng,
        ),
      AttributeCapReached(:final cap) => _EncounterOutcomePresentation(
        title: UiStrings.encounterOutcomeCapTitle,
        message: UiStrings.encounterOutcomeCapReached(cap),
        icon: Icons.block,
        color: WuxiaColors.textMuted,
      ),
      NoneOutcome() => const _EncounterOutcomePresentation(
        title: UiStrings.encounterOutcomeNoneTitle,
        message: UiStrings.encounterOutcomeNone,
        icon: Icons.local_florist_outlined,
        color: WuxiaColors.textMuted,
      ),
    };
  }
}

String _resolveSkillName(String skillId) {
  if (!GameRepository.isLoaded) return skillId;
  return GameRepository.instance.skillDefs[skillId]?.name ?? skillId;
}
