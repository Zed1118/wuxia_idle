import 'package:flutter/material.dart';

import '../../../data/game_repository.dart';
import '../../../shared/theme/colors.dart';
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
    return Dialog(
      backgroundColor: WuxiaColors.panel,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: WuxiaColors.border),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: AnimatedOpacity(
            opacity: _entered ? 1.0 : 0.0,
            duration: _entryDuration,
            curve: Curves.easeOut,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _TitleBar(title: widget.content.title ?? '机缘'),
                const SizedBox(height: 20),
                AnimatedSwitcher(
                  duration: _switchDuration,
                  switchInCurve: Curves.easeIn,
                  switchOutCurve: Curves.easeOut,
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: child,
                  ),
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
        ...choices.map(
          (c) => _ChoiceButton(text: c.text, onTap: () => onSelect(c)),
        ),
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
        const Icon(Icons.auto_awesome,
            color: WuxiaColors.resultHighlight, size: 18),
        const SizedBox(width: 8),
        const Text(
          '机缘',
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
    final shown = text.isNotEmpty ? text : '此情此景,已铭于心。';
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
          decoration: BoxDecoration(
            color: WuxiaColors.sidebar,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: WuxiaColors.border),
          ),
          child: Row(
            children: [
              const Icon(Icons.chevron_right,
                  color: WuxiaColors.textMuted, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  text,
                  style: const TextStyle(
                    color: WuxiaColors.textPrimary,
                    fontSize: 15,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
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
      child: TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(
          foregroundColor: WuxiaColors.resultHighlight,
          padding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
        child: const Text(
          '行路 →',
          style: TextStyle(fontSize: 15, letterSpacing: 2),
        ),
      ),
    );
  }
}

/// outcome 应用后的摘要呈现(SnackBar,Phase 1 vertical slice 用)。
///
/// caller stage_entry_flow 在 [EncounterService.applyOutcome] 返回后调,
/// SnackBar 在底部弹一句话告知玩家"领悟新招"/"机缘 +1"/"已达生涯上限"。
///
/// W15 C-2 收尾:UnlockSkillApplied 摘要从 raw skillId 升级为 SkillDef.name
/// 中文招名(玩家不再看见 `skill_encounter_xxx`)。GameRepository 未加载或
/// id 未注册时降级回 raw id(test fixture 不全 / yaml race 兜底)。
void showEncounterOutcomeBanner({
  required BuildContext context,
  required OutcomeApplied applied,
}) {
  final message = switch (applied) {
    UnlockSkillApplied(:final skillId) => '领悟新招:${_resolveSkillName(skillId)}',
    AttributeBonusApplied(:final key, :final delta) =>
      '${EnumL10n.attributeKey(key)} +$delta',
    AttributeCapReached(:final cap) => '已达生涯造化极限(总加 $cap)',
    NoneOutcome() => '心中默念,继续前行',
  };
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: WuxiaColors.panel,
      duration: const Duration(seconds: 3),
    ),
  );
}

String _resolveSkillName(String skillId) {
  if (!GameRepository.isLoaded) return skillId;
  return GameRepository.instance.skillDefs[skillId]?.name ?? skillId;
}
