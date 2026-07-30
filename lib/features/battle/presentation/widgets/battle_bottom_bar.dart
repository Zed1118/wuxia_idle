import 'package:flutter/material.dart';

import '../../domain/battle_skill_utils.dart';
import '../../domain/battle_state.dart';
import '../../domain/enum_localizations.dart';
import '../../../../core/domain/enums.dart';
import '../../../../data/defs/skill_def.dart';
import '../../../../shared/strings.dart';
import '../../../../shared/theme/colors.dart';
import '../../../../shared/theme/wuxia_tokens.dart';
import '../../../../shared/widgets/wuxia_image.dart';
import '../battle_layout_tokens.dart';
import '../battle_screen_config.dart';
import '../battle_typography_tokens.dart';
import '../countdown_ring.dart';
import 'battle_command_desk.dart';
import 'battle_focus_rail.dart';
import 'battle_pouch_rail.dart';
import 'battle_skill_slip.dart';

/// 纯自动战斗的只读招式轮转谱。
///
/// 不复制 [BattleAI] 或声称精确预测下一招；只把当前真气、冷却与可用门槛
/// 收敛成观察界面。全树无 button/focus 语义，避免自动模式伪装可交互案台。
class AutoRotationBar extends StatelessWidget {
  const AutoRotationBar({super.key, required this.state});

  final BattleState state;

  @override
  Widget build(BuildContext context) {
    final metrics = BattleLayoutMetrics.resolve(MediaQuery.sizeOf(context));
    final enemyCharging = state.rightTeam.any(
      (character) => character.isAlive && character.chargingSkill != null,
    );
    return Container(
      key: const ValueKey('battle_auto_rotation_desk'),
      height: metrics.autoRotationDeskHeight,
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 10),
      decoration: const BoxDecoration(
        color: Color(0xFF211D18),
        image: DecorationImage(
          image: AssetImage(WuxiaUi.paperBg),
          fit: BoxFit.cover,
          opacity: 0.10,
          colorFilter: ColorFilter.mode(Color(0xFF33291F), BlendMode.multiply),
        ),
        border: Border(top: BorderSide(color: Color(0xFF756047), width: 1.2)),
        boxShadow: [
          BoxShadow(color: Colors.black54, blurRadius: 18, spreadRadius: 3),
        ],
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 166,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  UiStrings.battleAutoRotation,
                  style: TextStyle(
                    color: Color(0xFFCBB58C),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2,
                  ),
                ),
                SizedBox(height: 7),
                Text(
                  UiStrings.battleAutoObserve,
                  style: TextStyle(
                    color: WuxiaColors.textMuted,
                    fontSize: 10,
                    letterSpacing: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Row(
              children: [
                for (var i = 0; i < state.leftTeam.length; i++) ...[
                  Expanded(
                    child: _AutoRotationActor(
                      character: state.leftTeam[i],
                      enemyCharging: enemyCharging,
                    ),
                  ),
                  if (i < state.leftTeam.length - 1) const SizedBox(width: 8),
                ],
              ],
            ),
          ),
          const SizedBox(width: 14),
          const BattlePouchRail(compact: true),
        ],
      ),
    );
  }
}

class _AutoRotationActor extends StatelessWidget {
  const _AutoRotationActor({
    required this.character,
    required this.enemyCharging,
  });

  final BattleCharacter character;
  final bool enemyCharging;

  @override
  Widget build(BuildContext context) {
    final skills =
        character.availableSkills
            .where(
              (skill) =>
                  skill.type != SkillType.normalAttack &&
                  !skill.requiresManualTrigger,
            )
            .toList()
          ..sort((a, b) => _statusRank(a).compareTo(_statusRank(b)));
    final visibleSkills = skills.take(3).toList();
    final qiFraction = character.maxQi <= 0
        ? 0.0
        : (character.currentQi / character.maxQi).clamp(0.0, 1.0);

    return Semantics(
      container: true,
      label: character.name,
      value: '${character.currentQi}/${character.maxQi}',
      child: Container(
        key: ValueKey('auto_rotation_actor_${character.characterId}'),
        height: 92,
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
        decoration: BoxDecoration(
          color: const Color(0xB3131210),
          border: Border.all(
            color: WuxiaColors.schoolColor(
              character.school,
            ).withValues(alpha: character.isAlive ? 0.72 : 0.28),
          ),
        ),
        child: Opacity(
          opacity: character.isAlive ? 1 : 0.48,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      character.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFFD8C9AC),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    '${character.currentQi}/${character.maxQi}',
                    style: const TextStyle(
                      color: WuxiaUi.qing,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              ExcludeSemantics(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    minHeight: 4,
                    value: qiFraction,
                    color: WuxiaUi.qing,
                    backgroundColor: const Color(0xFF40382E),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              if (!character.isAlive)
                const _AutoSkillStateText(text: UiStrings.battleFallen)
              else if (character.chargingSkill != null)
                const _AutoSkillStateText(text: UiStrings.skillCharging)
              else if (character.staggerTicksRemaining > 0)
                const _AutoSkillStateText(text: UiStrings.skillStaggered)
              else if (visibleSkills.isEmpty)
                const _AutoSkillStateText(
                  text: UiStrings.battleNoEquippedSkills,
                )
              else
                Expanded(
                  child: Row(
                    children: [
                      for (var i = 0; i < visibleSkills.length; i++) ...[
                        Expanded(
                          child: _AutoSkillState(
                            character: character,
                            skill: visibleSkills[i],
                            enemyCharging: enemyCharging,
                          ),
                        ),
                        if (i < visibleSkills.length - 1)
                          const SizedBox(width: 4),
                      ],
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  int _statusRank(SkillDef skill) {
    final cd = character.skillCooldowns[skill.id] ?? 0;
    final effectiveCost = effectiveSkillQiCost(character, skill);
    if (cd <= 0 && character.currentQi >= effectiveCost) {
      if (skill.aiUsePolicy == AiUsePolicy.saveForInterrupt) {
        return enemyCharging ? -10 : 50;
      }
      return 0;
    }
    if (cd > 0) return 100 + cd;
    return 200 + effectiveCost;
  }
}

class _AutoSkillState extends StatelessWidget {
  const _AutoSkillState({
    required this.character,
    required this.skill,
    required this.enemyCharging,
  });

  final BattleCharacter character;
  final SkillDef skill;
  final bool enemyCharging;

  @override
  Widget build(BuildContext context) {
    final cd = character.skillCooldowns[skill.id] ?? 0;
    final ready = isSkillReady(character, skill);
    final reserved =
        ready &&
        skill.aiUsePolicy == AiUsePolicy.saveForInterrupt &&
        !enemyCharging;
    final status = cd > 0
        ? UiStrings.skillCooldownRemaining(cd)
        : ready
        ? reserved
              ? UiStrings.skillReservedForInterrupt
              : UiStrings.skillReady
        : UiStrings.skillGatheringQi;
    final accent = ready && !reserved
        ? const Color(0xFFC3A46A)
        : const Color(0xFF776C5C);

    return Semantics(
      label: skill.name,
      value: status,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF322C24),
          border: Border.all(color: accent.withValues(alpha: 0.72)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              skill.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFFD4C5A7),
                fontSize: 9,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              status,
              style: TextStyle(
                color: ready && !reserved
                    ? const Color(0xFFD7B879)
                    : WuxiaColors.textMuted,
                fontSize: BattleTypography.t5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AutoSkillStateText extends StatelessWidget {
  const _AutoSkillStateText({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: const TextStyle(color: WuxiaColors.textMuted, fontSize: 10),
      ),
    ),
  );
}

/// A 案：自动观战复用可点选模式的名帖、七签、行囊三分区。
///
/// 最近一次我方动作只驱动签面亮起，不预测 AI 的下一步决策。
/// 子树不创建按钮、焦点、长按或拖放入口。
class AutoCommandDesk extends StatelessWidget {
  const AutoCommandDesk({super.key, required this.state, required this.beat});

  final BattleState state;
  final Animation<double> beat;

  @override
  Widget build(BuildContext context) {
    BattleAction? lastPlayerAction;
    for (final action in state.actionLog.reversed) {
      if (state.leftTeam.any((actor) => actor.characterId == action.actorId)) {
        lastPlayerAction = action;
        break;
      }
    }
    final fallbackIndex = state.leftTeam.indexWhere((actor) => actor.isAlive);
    final activeIndex = lastPlayerAction == null
        ? (fallbackIndex < 0 ? 0 : fallbackIndex)
        : state.leftTeam.indexWhere(
            (actor) => actor.characterId == lastPlayerAction!.actorId,
          );
    final activeActor = activeIndex >= 0 && activeIndex < state.leftTeam.length
        ? state.leftTeam[activeIndex]
        : null;
    final skills = <SkillDef>[
      if (activeActor != null)
        for (final skill in activeActor.availableSkills)
          if (skill.type != SkillType.normalAttack &&
              !skill.requiresManualTrigger)
            skill,
    ];

    return BattleCommandDeskSurface(
      builder: (context, metrics) => KeyedSubtree(
        key: const ValueKey('battle_auto_rotation_desk'),
        child: Opacity(
          opacity: 0.92,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FocusSelector(
                team: state.leftTeam,
                focusSlotIndex: activeIndex,
                onSelectFocus: (_) {},
                width: metrics.focusRailWidth,
                height: metrics.sampleSkillSlotHeight,
                interactive: false,
                title: UiStrings.battleAutoRotation,
                activeCharacterId: activeActor?.characterId,
              ),
              const SizedBox(width: BattleLayoutTokens.focusDividerGap),
              Container(
                width: 1,
                height: metrics.sampleSectionDividerHeight,
                color: const Color(0xFF6D5940),
              ),
              const SizedBox(width: BattleLayoutTokens.dividerSkillGap),
              SizedBox(
                key: const ValueKey('battle_desk_skills_region'),
                width: metrics.skillRailWidth,
                child: Padding(
                  padding: const EdgeInsets.only(
                    top: BattleLayoutTokens.sampleSkillSlipTopInset,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      for (var index = 0; index < 7; index++) ...[
                        Flexible(
                          key: ValueKey('battle_skill_slot_$index'),
                          flex: BattleLayoutTokens.sampleSkillFlex[index],
                          child: index < skills.length && activeActor != null
                              ? SkillCommandButton(
                                  character: activeActor,
                                  skill: skills[index],
                                  interventionWindowOpen: true,
                                  isPending: false,
                                  pendingTapEnabled: false,
                                  queuedAnother: false,
                                  highlight:
                                      lastPlayerAction?.skill?.id ==
                                      skills[index].id,
                                  allowPlayerIntervention: false,
                                  readOnly: true,
                                  autoActive:
                                      lastPlayerAction?.skill?.id ==
                                      skills[index].id,
                                  beat: beat,
                                  height: metrics.sampleSkillSlipHeight,
                                  onTap: () {},
                                  onShowInfo: () {},
                                )
                              : EmptySkillSlot(
                                  index: index,
                                  height: metrics.sampleSkillSlipHeight,
                                ),
                        ),
                        if (index < 6)
                          const SizedBox(
                            width: BattleLayoutTokens.skillSlotGap,
                          ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(width: BattleLayoutTokens.skillPouchGap),
              BattlePouchRail(
                width: metrics.pouchRailWidth,
                height: metrics.sampleSkillSlotHeight,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// T1 武学案台：左侧执招者 + 中部 7 个稳定技能签 + 右侧 3 个战备行囊位。
///
/// 旧版每角色只暴露大招/破招两按钮；新版聚焦单个"重点角色"，把它的
/// [BattleCharacter.availableSkills]（除普攻）全摊开成 强力/破招/共鸣/大招 分组按钮，
/// 每按钮带内力消耗 / 冷却 / 待发 状态。点头像切重点角色；敌人蓄力时由
/// 战斗屏的 `_effectiveFocus` 自动切到可破招者。两段点选:点技能按钮 →
/// single 进待发态/aoe 一键出手,走 [BattleNotifier.interveneNow] 立即插队（主线二 2.3）。
class BottomBar extends StatelessWidget {
  final BattleState state;
  final int focusSlotIndex;
  final bool allowPlayerIntervention;
  final void Function(int slotIndex) onSelectFocus;
  // 两段点选:长按技能方块 = 弹简介浮层(直接读 SkillDef 活数据);点击 = 释放(见 onSkillTap)。
  final void Function(SkillDef skill) onShowSkillInfo;
  // 两段点选:点技能按钮(single → 进待发态 / aoe → 一键出手 / 待发态再点同一技能取消)。
  final void Function(int characterId, SkillDef skill) onSkillTap;
  // 两段点选本地待发态:纯 presentation,不写 BattleState.pendingUltimates。
  final int? pendingCharacterId;
  final String? pendingSkillId;
  // 读秒环节拍(供技能 CD 环平滑插值)。
  final Animation<double> beat;
  // 待发单体技的技能格锚点(其上方浮出敌人快捷选择栏)。
  final LayerLink skillTargetLink;
  final List<BattlePouchPreviewItem> previewPouchItems;

  const BottomBar({
    super.key,
    required this.state,
    required this.focusSlotIndex,
    required this.allowPlayerIntervention,
    required this.onSelectFocus,
    required this.onShowSkillInfo,
    required this.onSkillTap,
    required this.pendingCharacterId,
    required this.pendingSkillId,
    required this.beat,
    required this.skillTargetLink,
    this.previewPouchItems = const [],
  });

  @override
  Widget build(BuildContext context) {
    return BattleCommandDeskSurface(
      builder: (context, metrics) {
        final enemyCharging = state.rightTeam.any(
          (e) => e.isAlive && e.chargingSkill != null,
        );
        final hasFocus =
            focusSlotIndex >= 0 && focusSlotIndex < state.leftTeam.length;
        final focus = hasFocus ? state.leftTeam[focusSlotIndex] : null;
        final domainPending = focus == null
            ? null
            : state.pendingUltimates[focus.characterId];
        final localPendingForFocus =
            focus != null && pendingCharacterId == focus.characterId
            ? pendingSkillId
            : null;

        // 签位遵守角色的装配顺序。样板把招式编排当作案台的一部分，类型只由
        // 单字朱印表达，不再把玩家已经排好的顺序二次洗牌。
        final skills = <SkillDef>[
          if (focus != null)
            for (final s in focus.availableSkills)
              if (s.type != SkillType.normalAttack) s,
        ];
        SkillDef? emphasizedInterruptSkill;
        if (enemyCharging) {
          for (final skill in skills) {
            if (skill.canInterrupt) {
              emphasizedInterruptSkill = skill;
              break;
            }
          }
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FocusSelector(
              team: state.leftTeam,
              focusSlotIndex: focusSlotIndex,
              onSelectFocus: onSelectFocus,
              width: metrics.focusRailWidth,
              height: metrics.sampleSkillSlotHeight,
            ),
            const SizedBox(width: BattleLayoutTokens.focusDividerGap),
            Container(
              width: 1,
              height: metrics.sampleSectionDividerHeight,
              color: const Color(0xFF6D5940),
            ),
            const SizedBox(width: BattleLayoutTokens.dividerSkillGap),
            SizedBox(
              key: const ValueKey('battle_desk_skills_region'),
              width: metrics.skillRailWidth,
              child: Padding(
                padding: const EdgeInsets.only(
                  top: BattleLayoutTokens.sampleSkillSlipTopInset,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    for (var index = 0; index < 7; index++) ...[
                      Flexible(
                        key: ValueKey('battle_skill_slot_$index'),
                        flex: BattleLayoutTokens.sampleSkillFlex[index],
                        child: index < skills.length && focus != null
                            ? Builder(
                                builder: (context) {
                                  final skill = skills[index];
                                  final localPendingThis =
                                      localPendingForFocus == skill.id;
                                  final domainPendingThis =
                                      domainPending?.id == skill.id;
                                  final button = SkillCommandButton(
                                    character: focus,
                                    skill: skill,
                                    interventionWindowOpen:
                                        state.actorQueue.isEmpty &&
                                        !state.isFinished,
                                    isPending:
                                        localPendingThis || domainPendingThis,
                                    pendingTapEnabled: localPendingThis,
                                    queuedAnother:
                                        domainPending != null &&
                                        domainPending.id != skill.id,
                                    highlight:
                                        skill.id ==
                                        emphasizedInterruptSkill?.id,
                                    allowPlayerIntervention:
                                        allowPlayerIntervention,
                                    beat: beat,
                                    height: metrics.sampleSkillSlipHeight,
                                    onTap: () =>
                                        onSkillTap(focus.characterId, skill),
                                    onShowInfo: () => onShowSkillInfo(skill),
                                  );
                                  return localPendingThis
                                      ? CompositedTransformTarget(
                                          link: skillTargetLink,
                                          child: button,
                                        )
                                      : button;
                                },
                              )
                            : EmptySkillSlot(
                                index: index,
                                height: metrics.sampleSkillSlipHeight,
                              ),
                      ),
                      if (index < 6)
                        const SizedBox(width: BattleLayoutTokens.skillSlotGap),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(width: BattleLayoutTokens.skillPouchGap),
            BattlePouchRail(
              width: metrics.pouchRailWidth,
              height: metrics.sampleSkillSlotHeight,
              previewItems: previewPouchItems,
            ),
          ],
        );
      },
    );
  }
}

/// 重点角色选择器：我方 3 槽小头像 chip，点选切重点角色。
class FocusSelector extends StatelessWidget {
  final List<BattleCharacter> team;
  final int focusSlotIndex;
  final void Function(int slotIndex) onSelectFocus;
  final double width;
  final double? height;
  final bool interactive;
  final String title;
  final int? activeCharacterId;

  const FocusSelector({
    super.key,
    required this.team,
    required this.focusSlotIndex,
    required this.onSelectFocus,
    required this.width,
    this.height,
    this.interactive = true,
    this.title = UiStrings.battleCommandDesk,
    this.activeCharacterId,
  });

  @override
  Widget build(BuildContext context) {
    final expandedSampleStyle = (height ?? 0) >= 190;
    final summaryIndex = focusSlotIndex >= 0 && focusSlotIndex < team.length
        ? focusSlotIndex
        : team.indexWhere(
            (character) => character.characterId == activeCharacterId,
          );
    final summary = summaryIndex >= 0 && summaryIndex < team.length
        ? team[summaryIndex]
        : null;

    return Semantics(
      container: true,
      label: title,
      child: BattleFocusRailSurface(
        width: width,
        height: height,
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < team.length; i++) ...[
                  FocusChip(
                    key: ValueKey('focus_chip_$i'),
                    character: team[i],
                    selected: i == focusSlotIndex,
                    onTap: interactive ? () => onSelectFocus(i) : null,
                    autoActive: team[i].characterId == activeCharacterId,
                    expandedSampleStyle: expandedSampleStyle,
                  ),
                  if (i < team.length - 1)
                    SizedBox(height: expandedSampleStyle ? 9 : 4),
                ],
              ],
            ),
            if (summary != null)
              Positioned(
                left: expandedSampleStyle ? -6 : 0,
                right: expandedSampleStyle ? -4 : 0,
                bottom: expandedSampleStyle ? 1 : 0,
                child: _FocusQiSummary(
                  character: summary,
                  expandedSampleStyle: expandedSampleStyle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class FocusChip extends StatelessWidget {
  final BattleCharacter character;
  final bool selected;
  final VoidCallback? onTap;
  final bool autoActive;
  final bool expandedSampleStyle;

  const FocusChip({
    super.key,
    required this.character,
    required this.selected,
    required this.onTap,
    this.autoActive = false,
    this.expandedSampleStyle = false,
  });

  @override
  Widget build(BuildContext context) {
    final dim = !character.isAlive;
    final plate = Container(
      key: ValueKey(
        'battle.focusNameplate.${selected ? 'expanded' : 'compact'}.${character.characterId}',
      ),
      height: expandedSampleStyle && selected
          ? BattleLayoutTokens.actorChipHeight
          : expandedSampleStyle
          ? BattleLayoutTokens.actorChipHeight - 4
          : 30,
      decoration: BoxDecoration(
        color: Colors.transparent,
        border: selected
            ? null
            : Border.all(color: const Color(0xFF665744), width: 1),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          if (selected)
            const Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  key: ValueKey('battle.focusSelectedPaper'),
                  painter: _FocusSelectedPaperPainter(),
                ),
              ),
            )
          else
            const Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(painter: _FocusDarkNameplatePainter()),
              ),
            ),
          if (selected)
            Align(
              alignment: Alignment.centerLeft,
              child: Transform.translate(
                offset: const Offset(-3, 0),
                child: CustomPaint(
                  key: const ValueKey('battle.focusSelectedPointer'),
                  size: const Size(14, 20),
                  painter: _FocusPointerPainter(
                    color: dim
                        ? const Color(0xFF8F8574)
                        : const Color(0xFFD8C6A5),
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              character.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: BattleTypography.displayFamily,
                fontFamilyFallback: BattleTypography.displayFallback,
                fontSize: expandedSampleStyle ? (selected ? 20 : 18) : 11,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: dim
                    ? const Color(0xFF8F8574)
                    : selected
                    ? WuxiaUi.ink
                    : const Color(0xFFD4C5A7),
              ),
            ),
          ),
        ],
      ),
    );
    final nameplate = onTap == null
        ? plate
        : InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(2),
            child: plate,
          );
    final keyedNameplate = autoActive
        ? KeyedSubtree(
            key: ValueKey('battle_auto_actor_active_${character.characterId}'),
            child: nameplate,
          )
        : nameplate;
    return dim
        ? Opacity(
            key: ValueKey(
              'battle.focusNameplate.faded.${character.characterId}',
            ),
            opacity: 0.48,
            child: keyedNameplate,
          )
        : keyedNameplate;
  }
}

class _FocusSelectedPaperPainter extends CustomPainter {
  const _FocusSelectedPaperPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(1, 0)
      ..lineTo(size.width * 0.17, 0)
      ..lineTo(size.width * 0.34, 1.2)
      ..lineTo(size.width * 0.56, 0)
      ..lineTo(size.width * 0.77, 0.8)
      ..lineTo(size.width - 1, 0)
      ..lineTo(size.width - 2, size.height * 0.30)
      ..lineTo(size.width - 1, size.height * 0.56)
      ..lineTo(size.width - 2.4, size.height)
      ..lineTo(size.width * 0.78, size.height - 1)
      ..lineTo(size.width * 0.61, size.height)
      ..lineTo(size.width * 0.39, size.height - 1)
      ..lineTo(size.width * 0.19, size.height)
      ..lineTo(1.4, size.height - 1)
      ..lineTo(2.2, size.height * 0.69)
      ..lineTo(1, size.height * 0.43)
      ..close();
    canvas.drawPath(
      path,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFBBA082),
            WuxiaUi.battleFocusPaper,
            Color(0xFFA1886F),
          ],
        ).createShader(Offset.zero & size),
    );

    final dark = Paint()
      ..color = const Color(0xFF4F3D30).withValues(alpha: 0.13)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.4);
    final pale = Paint()
      ..color = const Color(0xFFE5D2AF).withValues(alpha: 0.09)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.4);
    canvas.save();
    canvas.clipPath(path);
    for (var i = 0; i < 16; i++) {
      final x = ((i * 43 + 7) % 127) / 127 * size.width;
      final y = ((i * 29 + 5) % 101) / 101 * size.height;
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(x, y),
          width: 32 + (i % 4) * 15,
          height: 8 + (i % 3) * 7,
        ),
        i.isEven ? dark : pale,
      );
    }
    final fiber = Paint()
      ..color = const Color(0xFF665443).withValues(alpha: 0.15)
      ..strokeWidth = 0.55;
    for (var i = 0; i < 9; i++) {
      final y = 4.0 + i * 4.1;
      final start = ((i * 31) % 67) / 67 * size.width * 0.62;
      canvas.drawLine(
        Offset(start, y),
        Offset(start + 26 + (i % 3) * 13, y + 0.6),
        fiber,
      );
    }
    final grain = Paint()
      ..color = const Color(0xFF534235).withValues(alpha: 0.17);
    for (var i = 0; i < 42; i++) {
      final x = ((i * 61 + 17) % 211) / 211 * size.width;
      final y = ((i * 37 + 9) % 97) / 97 * size.height;
      canvas.drawCircle(Offset(x, y), 0.28 + (i % 3) * 0.18, grain);
    }
    canvas.restore();
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFF756047).withValues(alpha: 0.82)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(covariant _FocusSelectedPaperPainter oldDelegate) => false;
}

class _FocusDarkNameplatePainter extends CustomPainter {
  const _FocusDarkNameplatePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final wash = Paint()
      ..color = const Color(0xFF817767).withValues(alpha: 0.015)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    for (var i = 0; i < 7; i++) {
      final x = ((i * 37 + 11) % 83) / 83 * size.width;
      final y = ((i * 23 + 7) % 59) / 59 * size.height;
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(x, y),
          width: 42 + (i % 3) * 19,
          height: 8 + (i % 2) * 7,
        ),
        wash,
      );
    }
    final fiber = Paint()
      ..color = const Color(0xFFACA08B).withValues(alpha: 0.07)
      ..strokeWidth = 0.45;
    for (var i = 0; i < 5; i++) {
      final y = 5.0 + i * 6.2;
      canvas.drawLine(
        Offset(8 + (i * 29) % 71, y),
        Offset(size.width * (0.46 + (i % 3) * 0.12), y + 0.5),
        fiber,
      );
    }
    final grain = Paint()
      ..color = const Color(0xFFB9AC96).withValues(alpha: 0.075);
    for (var i = 0; i < 30; i++) {
      final x = ((i * 47 + 13) % 127) / 127 * size.width;
      final y = ((i * 31 + 7) % 83) / 83 * size.height;
      canvas.drawCircle(Offset(x, y), 0.25 + (i % 2) * 0.18, grain);
    }
  }

  @override
  bool shouldRepaint(covariant _FocusDarkNameplatePainter oldDelegate) => false;
}

class _FocusQiSummary extends StatelessWidget {
  const _FocusQiSummary({
    required this.character,
    required this.expandedSampleStyle,
  });

  final BattleCharacter character;
  final bool expandedSampleStyle;

  @override
  Widget build(BuildContext context) {
    final fraction = character.maxQi <= 0
        ? 0.0
        : (character.currentQi / character.maxQi).clamp(0.0, 1.0);
    if (expandedSampleStyle) {
      return Semantics(
        label: UiStrings.statQi,
        value: '${character.currentQi}/${character.maxQi}',
        child: SizedBox(
          key: const ValueKey('battle.focusQiSummary'),
          height: 50,
          child: Stack(
            children: [
              Positioned(
                top: 0,
                left: 6,
                right: 4,
                child: Text(
                  '${UiStrings.statQi} ${character.currentQi}/${character.maxQi}',
                  style: const TextStyle(
                    color: Color(0xFFD9C5A0),
                    fontFamily: BattleTypography.displayFamily,
                    fontFamilyFallback: BattleTypography.displayFallback,
                    fontSize: 21,
                    height: 1.1,
                    letterSpacing: 0.6,
                    fontFeatures: BattleTypography.tabularFigures,
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _SampleFocusQiProgress(fraction: fraction),
              ),
            ],
          ),
        ),
      );
    }
    return Semantics(
      label: UiStrings.statQi,
      value: '${character.currentQi}/${character.maxQi}',
      child: Column(
        key: const ValueKey('battle.focusQiSummary'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.zero,
            child: Text(
              '${UiStrings.statQi} ${character.currentQi}/${character.maxQi}',
              style: const TextStyle(
                color: Color(0xFFD9C5A0),
                fontFamily: BattleTypography.displayFamily,
                fontFamilyFallback: BattleTypography.displayFallback,
                fontSize: 11,
                letterSpacing: 0.8,
                fontFeatures: BattleTypography.tabularFigures,
              ),
            ),
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(1),
            child: LinearProgressIndicator(
              key: const ValueKey('battle.focusQiProgress'),
              minHeight: 6,
              value: fraction,
              color: WuxiaUi.qing,
              backgroundColor: const Color(0xFF40382E),
            ),
          ),
        ],
      ),
    );
  }
}

class _SampleFocusQiProgress extends StatelessWidget {
  const _SampleFocusQiProgress({required this.fraction});

  final double fraction;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('battle.focusQiProgress'),
      height: 15,
      padding: const EdgeInsets.all(1),
      decoration: BoxDecoration(
        color: const Color(0xFF282721),
        border: Border.all(color: const Color(0xFF77664F), width: 1),
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: FractionallySizedBox(
          widthFactor: fraction,
          heightFactor: 1,
          child: const ColoredBox(color: Color(0xFF5F8E89)),
        ),
      ),
    );
  }
}

class _FocusPointerPainter extends CustomPainter {
  const _FocusPointerPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, size.height / 2)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _FocusPointerPainter oldDelegate) =>
      oldDelegate.color != color;
}

/// 单个技能指令按钮：分组标签 + 招名 + 状态行（待发 / 冷却 N / 耗 N）。
/// `isPending` 盖"待发"印且禁用；`queuedAnother`（同角色已排别的技能）也禁用；
/// `highlight`（敌人蓄力 + 本技能可破招）换醒目金 + 白边。
class SkillCommandButton extends StatelessWidget {
  final BattleCharacter character;
  final SkillDef skill;
  final bool interventionWindowOpen;
  final bool isPending;
  final bool pendingTapEnabled;
  final bool queuedAnother;
  final bool highlight;
  final bool allowPlayerIntervention;
  final bool readOnly;
  final bool autoActive;
  final double height;
  // 读秒环节拍(供 CD 环平滑插值)。
  final Animation<double> beat;
  // 两段点选:点击 = 释放(single 进待发态 / aoe 一键出手);长按 = 弹简介浮层。
  final VoidCallback onTap;
  final VoidCallback onShowInfo;

  const SkillCommandButton({
    super.key,
    required this.character,
    required this.skill,
    required this.interventionWindowOpen,
    required this.isPending,
    required this.pendingTapEnabled,
    required this.queuedAnother,
    required this.highlight,
    required this.allowPlayerIntervention,
    this.readOnly = false,
    this.autoActive = false,
    this.height = BattleLayoutTokens.skillSlotHeight,
    required this.beat,
    required this.onTap,
    required this.onShowInfo,
  });

  static String _groupLabel(SkillDef s) {
    if (s.canInterrupt) return UiStrings.battleInterruptSkill; // 破招
    return switch (s.type) {
      SkillType.powerSkill => UiStrings.skillGroupPower, // 强力
      SkillType.jointSkill => UiStrings.skillGroupJoint, // 共鸣
      SkillType.ultimate => UiStrings.ultimate, // 大招
      SkillType.normalAttack => '',
    };
  }

  static String _sealLabel(SkillDef skill) {
    if (skill.canInterrupt) return UiStrings.skillSealInterrupt;
    if (skill.targetType == TargetType.aoe) return UiStrings.skillSealGroup;
    if (skill.source == SkillSource.encounter) {
      return UiStrings.skillSealEncounter;
    }
    return switch (skill.type) {
      SkillType.powerSkill => UiStrings.skillSealPower,
      SkillType.jointSkill => UiStrings.skillSealAssist,
      SkillType.ultimate => UiStrings.skillSealUltimate,
      SkillType.normalAttack => '',
    };
  }

  @override
  Widget build(BuildContext context) {
    final expandedSampleStyle = height >= 190;
    final cd = character.skillCooldowns[skill.id] ?? 0;
    final effectiveCost = effectiveSkillQiCost(character, skill);
    final actionReady = character.actionPoint > 0;
    final interventionReady =
        interventionWindowOpen && canInterveneWithSkill(character, skill);
    final enabled =
        interventionReady &&
        (!isPending || pendingTapEnabled) &&
        !queuedAnother &&
        allowPlayerIntervention;

    final onCd = cd > 0 && !isPending;
    final insufficientQi = character.currentQi < effectiveCost;
    final visualState = isPending
        ? BattleSkillSlipVisualState.pending
        : onCd
        ? BattleSkillSlipVisualState.cooldown
        : insufficientQi
        ? BattleSkillSlipVisualState.insufficientQi
        : highlight
        ? BattleSkillSlipVisualState.interrupt
        : BattleSkillSlipVisualState.available;

    Color bgColor;
    if (visualState == BattleSkillSlipVisualState.insufficientQi) {
      bgColor = const Color(0xFFC4B596);
    } else if (visualState == BattleSkillSlipVisualState.interrupt) {
      bgColor = WuxiaUi.battleSkillPaperSelected;
    } else {
      bgColor = WuxiaUi.battleSkillPaper;
    }

    final String blockingStatus;
    if (isPending) {
      blockingStatus = UiStrings.skillPendingStamp; // 待发
    } else if (cd > 0) {
      blockingStatus = ''; // CD 态由读秒环示数。
    } else if (character.currentQi < effectiveCost) {
      blockingStatus = UiStrings.skillInsufficientForce;
    } else if (character.chargingSkill != null) {
      blockingStatus = UiStrings.skillCharging;
    } else if (character.staggerTicksRemaining > 0) {
      blockingStatus = UiStrings.skillStaggered;
    } else if (!actionReady || !interventionWindowOpen) {
      blockingStatus = UiStrings.skillAwaitingAction;
    } else {
      blockingStatus = '';
    }

    final accent = highlight ? WuxiaUi.gold : const Color(0xFF493B2D);
    final skillTitle = _VerticalSkillTitle(
      key: const ValueKey('battle.skillSlipTitle'),
      name: skill.name,
      expandedSampleStyle: expandedSampleStyle,
    );
    final natureSeal = Transform.rotate(
      angle: -0.045,
      child: Container(
        key: const ValueKey('battle.skillSlipNatureSeal'),
        width: expandedSampleStyle ? 28 : 24,
        height: expandedSampleStyle ? 28 : 22,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: expandedSampleStyle
              ? WuxiaUi.battleSkillSeal
              : WuxiaUi.jiang.withValues(alpha: 0.10),
          border: Border.all(
            color: expandedSampleStyle
                ? const Color(0xFF4F211C)
                : WuxiaUi.jiang.withValues(alpha: 0.78),
            width: expandedSampleStyle ? 1.2 : 1,
          ),
          boxShadow: expandedSampleStyle
              ? const [
                  BoxShadow(
                    color: Color(0x66301713),
                    blurRadius: 2,
                    offset: Offset(1, 1),
                  ),
                ]
              : null,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (expandedSampleStyle)
              const Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(painter: _SkillSealTexturePainter()),
                ),
              ),
            Text(
              _sealLabel(skill),
              style: TextStyle(
                color: expandedSampleStyle
                    ? WuxiaUi.battleSkillSealInk
                    : WuxiaUi.jiang,
                fontFamily: BattleTypography.displayFamily,
                fontFamilyFallback: BattleTypography.displayFallback,
                fontSize: expandedSampleStyle ? 15 : 12,
                fontWeight: FontWeight.w700,
                height: 1,
                shadows: expandedSampleStyle
                    ? const [
                        Shadow(
                          color: Color(0x99301916),
                          blurRadius: 1,
                          offset: Offset(0.5, 0.5),
                        ),
                      ]
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
    final button = BattleSkillSlipSurface(
      height: height,
      tiltAngle: battleSkillSlipTilt(skill.id),
      backgroundColor: bgColor,
      foregroundColor: enabled ? WuxiaUi.ink : const Color(0xFF514B42),
      border: highlight && enabled
          ? const BorderSide(color: WuxiaUi.gold, width: 2)
          : BorderSide(
              color: const Color(0xFF6C5A43).withValues(alpha: 0.78),
              width: 1,
            ),
      accent: accent,
      visualState: visualState,
      // 原生按钮在 surface 内承接 focus / keyboard / cursor / semantics。
      onPressed: enabled ? onTap : null,
      onLongPress: readOnly ? null : onShowInfo,
      interactive: !readOnly,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Opacity(
            opacity: onCd ? (expandedSampleStyle ? 0.78 : 0.62) : 1.0,
            child: Column(
              children: [
                const SizedBox(
                  key: ValueKey('battle.skillSlipHeader'),
                  height: 14,
                ),
                Expanded(
                  child: expandedSampleStyle
                      ? Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Positioned(
                              top:
                                  visualState ==
                                      BattleSkillSlipVisualState.interrupt
                                  ? 7
                                  : 6,
                              left: 0,
                              right: 0,
                              child: skillTitle,
                            ),
                            Positioned(
                              top: 93,
                              left: 0,
                              right: 0,
                              child: Center(child: natureSeal),
                            ),
                          ],
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            skillTitle,
                            const SizedBox(height: 8),
                            natureSeal,
                          ],
                        ),
                ),
                Container(
                  key: const ValueKey('battle.skillSlipFooter'),
                  height: expandedSampleStyle ? 34 : 29,
                  margin: EdgeInsets.fromLTRB(
                    5,
                    0,
                    5,
                    expandedSampleStyle ? 18 : 4,
                  ),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: const Color(0xFF79674D).withValues(alpha: 0.10),
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CustomPaint(
                        key: const ValueKey('battle.skillSlipQiSwirl'),
                        size: Size.square(expandedSampleStyle ? 22 : 13),
                        painter: const _QiSwirlPainter(),
                      ),
                      SizedBox(width: expandedSampleStyle ? 5 : 3),
                      Text(
                        '$effectiveCost',
                        key: const ValueKey('battle.skillSlipQiCost'),
                        style: TextStyle(
                          color: expandedSampleStyle
                              ? WuxiaUi.battleSkillQi
                              : WuxiaUi.qing,
                          fontSize: expandedSampleStyle ? 18 : 10,
                          fontWeight: FontWeight.w700,
                          height: 1,
                          fontFeatures: BattleTypography.tabularFigures,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (onCd && expandedSampleStyle)
            Positioned(
              top: height * 0.34,
              right: 8,
              child: Text(
                '$cd',
                key: const ValueKey('battle.skillSlipCooldownCount'),
                style: const TextStyle(
                  color: Color(0xFFE7D8B8),
                  fontSize: 25,
                  fontWeight: FontWeight.w700,
                  height: 1,
                  shadows: [Shadow(color: Colors.black87, blurRadius: 3)],
                ),
              ),
            )
          else if (onCd)
            Positioned(
              top: height * 0.42,
              right: 7,
              child: BeatCountdownRing(
                remaining: cd,
                total: skill.cooldownTurns,
                beat: beat,
                color: WuxiaColors.lingQiao,
                size: 25,
              ),
            ),
          if (isPending)
            const Positioned(top: -7, right: -7, child: PendingStamp()),
        ],
      ),
    );

    final semantics = Semantics(
      key: ValueKey(
        readOnly
            ? 'battle_auto_skill_${character.characterId}_${skill.id}'
            : 'skill_cmd_${character.characterId}_${skill.id}',
      ),
      button: !readOnly,
      enabled: readOnly ? null : enabled,
      readOnly: readOnly,
      label: '${_groupLabel(skill)} ${skill.name}',
      value: blockingStatus.isEmpty ? null : blockingStatus,
      child: button,
    );
    return autoActive
        ? KeyedSubtree(
            key: ValueKey('battle_auto_skill_active_${skill.id}'),
            child: semantics,
          )
        : semantics;
  }
}

class _VerticalSkillTitle extends StatelessWidget {
  const _VerticalSkillTitle({
    super.key,
    required this.name,
    required this.expandedSampleStyle,
  });

  final String name;
  final bool expandedSampleStyle;

  @override
  Widget build(BuildContext context) {
    final fourCharacterSample =
        expandedSampleStyle && name.characters.length >= 4;
    return Text(
      name.characters.take(4).join('\n'),
      maxLines: 4,
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.center,
      style: TextStyle(
        color: WuxiaUi.ink,
        fontFamily: BattleTypography.displayFamily,
        fontFamilyFallback: BattleTypography.displayFallback,
        fontSize: expandedSampleStyle
            ? (fourCharacterSample ? 20 : 21.5)
            : BattleTypography.t2,
        fontWeight: FontWeight.w700,
        height: expandedSampleStyle ? (fourCharacterSample ? 1.0 : 1.10) : 0.92,
        letterSpacing: 0,
      ),
    );
  }
}

class _QiSwirlPainter extends CustomPainter {
  const _QiSwirlPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = size.width >= 20 ? WuxiaUi.battleSkillQi : WuxiaUi.qing
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width >= 20 ? 2.0 : 1.5
      ..strokeCap = StrokeCap.round;
    final center = Offset(size.width / 2, size.height / 2);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: size.width * 0.41),
      -0.6,
      4.9,
      false,
      paint,
    );
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: size.width * 0.24),
      2.2,
      4.1,
      false,
      paint,
    );
    canvas.drawCircle(center, 1.1, paint..style = PaintingStyle.fill);
  }

  @override
  bool shouldRepaint(covariant _QiSwirlPainter oldDelegate) => false;
}

class _SkillSealTexturePainter extends CustomPainter {
  const _SkillSealTexturePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final dark = Paint()
      ..color = const Color(0xFF351713).withValues(alpha: 0.46)
      ..strokeWidth = 0.9
      ..strokeCap = StrokeCap.round;
    final worn = Paint()
      ..color = WuxiaUi.battleSkillSealInk.withValues(alpha: 0.22)
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 13; i++) {
      final x = 2.0 + ((i * 11) % 23) / 23 * (size.width - 4);
      final y = 2.0 + ((i * 17) % 19) / 19 * (size.height - 4);
      canvas.drawCircle(
        Offset(x, y),
        i % 4 == 0 ? 0.8 : 0.45,
        i.isEven ? dark : worn,
      );
    }
    canvas.drawLine(const Offset(1.5, 3), Offset(size.width - 2, 1.5), dark);
    canvas.drawLine(
      Offset(2, size.height - 1.5),
      Offset(size.width - 1.5, size.height - 3),
      dark,
    );
  }

  @override
  bool shouldRepaint(covariant _SkillSealTexturePainter oldDelegate) => false;
}

class EmptySkillSlot extends StatelessWidget {
  const EmptySkillSlot({
    super.key,
    required this.index,
    this.height = BattleLayoutTokens.skillSlotHeight,
  });

  final int index;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: UiStrings.battleEmptySkillSlot,
      child: SizedBox(
        key: ValueKey('battle_skill_empty_$index'),
        height: height,
        child: DecoratedBox(
          key: ValueKey('battle.emptySkillSlot.blankPaper.$index'),
          decoration: BoxDecoration(
            // 空签保留旧纸材质，但必须退入案台。满高亮空纸会在早期关卡形成
            // 六块大面积「空表单」，视觉权重反而高过唯一的真招式签。
            color: WuxiaUi.paper.withValues(
              alpha: BattleLayoutTokens.emptySkillPaperOpacity,
            ),
            image: const DecorationImage(
              image: AssetImage(WuxiaUi.paperBg),
              fit: BoxFit.cover,
              opacity: BattleLayoutTokens.emptySkillTextureOpacity,
            ),
            border: Border.all(color: const Color(0x4D7A6A55)),
            borderRadius: BorderRadius.circular(2),
          ),
          child: Center(
            child: Transform.rotate(
              angle: -0.08,
              child: Container(
                key: ValueKey('battle.emptySkillSlot.emptySeal.$index'),
                width: 22,
                height: 22,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0x0A6E6252),
                  border: Border.all(color: const Color(0x406E6252)),
                ),
                child: Text(
                  UiStrings.battleEmptySkillSlot.characters.first,
                  style: const TextStyle(
                    color: Color(0x596A5E4C),
                    fontSize: 9,
                    height: 1,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class BattlePouchRail extends StatelessWidget {
  const BattlePouchRail({
    super.key,
    this.compact = false,
    this.width,
    this.height,
    this.previewItems = const [],
  });

  final bool compact;
  final double? width;
  final double? height;
  final List<BattlePouchPreviewItem> previewItems;

  @override
  Widget build(BuildContext context) {
    final metrics = BattleLayoutMetrics.resolve(MediaQuery.sizeOf(context));
    final railWidth = width ?? metrics.pouchRailWidth;
    final expandedSampleStyle = !compact && (height ?? 0) >= 190;
    final heightBoundSlotSize = height == null
        ? BattleLayoutTokens.pouchSlotSize
        : height! - (expandedSampleStyle ? 94 : 82);
    final maxSlotSize = heightBoundSlotSize < BattleLayoutTokens.pouchSlotSize
        ? heightBoundSlotSize
        : BattleLayoutTokens.pouchSlotSize;
    final slotSize = compact
        ? 34.0
        : ((railWidth - 31 - BattleLayoutTokens.pouchSlotGap * 2) / 3)
              .clamp(44.0, maxSlotSize)
              .toDouble();
    return BattlePouchRailSurface(
      width: railWidth,
      height: height,
      compact: compact,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Text(
              UiStrings.battlePouch,
              key: const ValueKey('battle.pouch.title'),
              style: TextStyle(
                color: const Color(0xFFCBB58C),
                fontFamily: BattleTypography.displayFamily,
                fontFamilyFallback: BattleTypography.displayFallback,
                fontSize: expandedSampleStyle ? 18 : 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ),
          SizedBox(height: compact ? 4 : (expandedSampleStyle ? 5 : 8)),
          Row(
            children: [
              for (var i = 0; i < 3; i++) ...[
                Semantics(
                  label: '${UiStrings.battlePouch} ${i + 1}',
                  value: i < previewItems.length
                      ? '${previewItems[i].count}'
                      : UiStrings.battlePouchReserved,
                  child: Container(
                    key: ValueKey('battle_pouch_slot_$i'),
                    width: slotSize,
                    height: slotSize,
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF32261C),
                      border: Border.all(color: const Color(0xFF8B6B43)),
                    ),
                    child: DecoratedBox(
                      key: ValueKey('battle.pouch.brocadeSlot.$i'),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            WuxiaUi.battlePouchSlotTop,
                            WuxiaUi.battlePouchSlotBottom,
                          ],
                        ),
                        border: Border.all(color: const Color(0xFF654F3D)),
                        borderRadius: BorderRadius.circular(1),
                      ),
                      // 三格一律空囊纹样。旧版 slot 0/1 无条件写死显示紫金葫芦与
                      // 寻常药囊两张真实道具图,与玩家实际背包毫无关系 —— 那是在
                      // 展示**假的游戏状态**(每个玩家每场战斗行囊里都「有」这两件),
                      // 比中性占位更误导;旁边「待装配」小字字号 9,视觉权重远输于
                      // 42px 实心彩图。改沿技能案台空签的印记体例(见
                      // [EmptySkillSlot]),但用锦囊侧的暖浅色而非宣纸色 —— 行囊格底
                      // 是深褐织锦,套宣纸色会突兀(memory
                      // `feedback_paper_vs_dark_text_color_palette`:两套色板不可混用)。
                      child: i < previewItems.length
                          ? Stack(
                              key: ValueKey('battle.pouch.item.$i'),
                              fit: StackFit.expand,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(2),
                                  child: WuxiaImage(
                                    previewItems[i].assetPath,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                                Positioned(
                                  right: 1,
                                  bottom: 0,
                                  child: Text(
                                    '${previewItems[i].count}',
                                    style: TextStyle(
                                      color: const Color(0xFFE7D7B6),
                                      fontSize: compact ? 10 : 13,
                                      fontWeight: FontWeight.w700,
                                      shadows: const [
                                        Shadow(
                                          color: Colors.black,
                                          blurRadius: 3,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : Center(
                              child: Transform.rotate(
                                angle: -0.08,
                                child: Container(
                                  key: ValueKey('battle.pouch.emptySeal.$i'),
                                  width: compact ? 16 : 22,
                                  height: compact ? 16 : 22,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: const Color(0x14C9B183),
                                    border: Border.all(
                                      color: const Color(0x59BFA97C),
                                    ),
                                  ),
                                  child: Text(
                                    UiStrings
                                        .battlePouchEmptySlot
                                        .characters
                                        .first,
                                    style: TextStyle(
                                      color: const Color(0x8CC9B183),
                                      fontSize: compact ? 9 : 11,
                                      height: 1,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                    ),
                  ),
                ),
                if (i < 2)
                  SizedBox(
                    width: compact ? 6 : BattleLayoutTokens.pouchSlotGap,
                  ),
              ],
            ],
          ),
          SizedBox(height: compact ? 4 : (expandedSampleStyle ? 12 : 8)),
          Align(
            child: FractionallySizedBox(
              widthFactor: compact ? 1 : (expandedSampleStyle ? 0.51 : 0.58),
              child: Semantics(
                readOnly: true,
                label: UiStrings.battlePouch,
                value: UiStrings.battlePouchReserved,
                child: Container(
                  key: const ValueKey('battle.pouch.footerPlaque'),
                  height: compact ? 18 : (expandedSampleStyle ? 30 : 26),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFF211B16).withValues(alpha: 0.72),
                    border: Border.all(color: const Color(0xFF8A6945)),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black38,
                        blurRadius: 2,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Text(
                    UiStrings.battlePouchShort,
                    style: TextStyle(
                      color: const Color(0xFFCBB58C),
                      fontFamily: BattleTypography.displayFamily,
                      fontFamilyFallback: BattleTypography.displayFallback,
                      fontSize: compact ? 9 : (expandedSampleStyle ? 16 : 11),
                      letterSpacing: compact ? 1 : 2,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PendingStamp extends StatelessWidget {
  const PendingStamp({super.key});

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: -0.16,
      child: DecoratedBox(
        key: const ValueKey('skill_pending_stamp_badge'),
        decoration: BoxDecoration(
          color: WuxiaColors.resultHighlight.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(3),
          border: Border.all(color: WuxiaColors.textPrimary, width: 1),
          boxShadow: [
            BoxShadow(
              color: WuxiaColors.resultHighlight.withValues(alpha: 0.34),
              blurRadius: 8,
              spreadRadius: 1,
            ),
          ],
        ),
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 5, vertical: 2),
          child: Text(
            UiStrings.skillPendingStamp,
            style: TextStyle(
              color: WuxiaColors.panel,
              fontSize: 10,
              height: 1,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}

/// 批次 1.3:技能简介浮层正文(直接读 [SkillDef] 活数据)。
/// 描述 + 字段表(类型/目标/威力/真气/冷却/特性)+ 拖招提示。
/// 不走 HelpCatalog/CodexIndex,纯活数据 + [EnumL10n] 枚举显示名。
class SkillInfoBody extends StatelessWidget {
  final SkillDef skill;
  const SkillInfoBody({super.key, required this.skill});

  static String _traitText(SkillDef s) {
    if (s.canInterrupt) return UiStrings.skillTraitInterrupt; // 破招(可打断蓄力)
    return UiStrings.skillTraitNone; // 无
  }

  @override
  Widget build(BuildContext context) {
    final rows = <(String, String)>[
      (UiStrings.skillInfoType, EnumL10n.skillType(skill.type)),
      (UiStrings.skillInfoTarget, EnumL10n.targetType(skill.targetType)),
      (UiStrings.skillInfoPower, '${skill.powerMultiplier}'),
      (UiStrings.skillInfoCost, UiStrings.skillQiChange(skill.qiDelta)),
      (
        UiStrings.skillInfoCooldown,
        UiStrings.skillInfoCooldownTurns(skill.cooldownTurns),
      ),
      (UiStrings.skillInfoTrait, _traitText(skill)),
    ];
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 描述活文本(SkillDef.description)。
        Text(
          skill.description,
          style: const TextStyle(color: WuxiaUi.ink, fontSize: 13, height: 1.5),
        ),
        const SizedBox(height: 14),
        for (final (label, value) in rows)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 56,
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: WuxiaUi.muted,
                      fontSize: 12,
                      letterSpacing: 2,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    value,
                    style: const TextStyle(
                      color: WuxiaUi.ink,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 8),
        const Text(
          UiStrings.skillInfoTapHint,
          style: TextStyle(color: WuxiaUi.qing, fontSize: 11, letterSpacing: 1),
        ),
      ],
    );
  }
}
