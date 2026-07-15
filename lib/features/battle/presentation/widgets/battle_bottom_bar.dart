import 'package:flutter/material.dart';

import '../../domain/battle_skill_utils.dart';
import '../../domain/battle_state.dart';
import '../../domain/enum_localizations.dart';
import '../../../../core/domain/enums.dart';
import '../../../../data/defs/skill_def.dart';
import '../../../../shared/strings.dart';
import '../../../../shared/theme/colors.dart';
import '../../../../shared/theme/wuxia_tokens.dart';
import '../battle_layout_tokens.dart';
import '../countdown_ring.dart';

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
  });

  /// 排序/分组秩：强力 0 → 破招 1 → 共鸣 2 → 大招 3（普攻 4，已被过滤）。
  static int _groupRank(SkillDef s) {
    if (s.canInterrupt) return 1;
    return switch (s.type) {
      SkillType.powerSkill => 0,
      SkillType.jointSkill => 2,
      SkillType.ultimate => 3,
      SkillType.normalAttack => 4,
    };
  }

  @override
  Widget build(BuildContext context) {
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

    final skills = <SkillDef>[
      if (focus != null)
        for (final s in focus.availableSkills)
          if (s.type != SkillType.normalAttack) s,
    ]..sort((a, b) => _groupRank(a).compareTo(_groupRank(b)));

    return Container(
      key: const ValueKey('battle_command_desk'),
      height: BattleLayoutTokens.commandDeskHeight,
      padding: const EdgeInsets.symmetric(
        horizontal: BattleLayoutTokens.commandDeskHorizontalPadding,
        vertical: BattleLayoutTokens.commandDeskVerticalPadding,
      ),
      decoration: const BoxDecoration(
        color: WuxiaColors.panel,
        border: Border(top: BorderSide(color: WuxiaColors.border)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          FocusSelector(
            team: state.leftTeam,
            focusSlotIndex: focusSlotIndex,
            onSelectFocus: onSelectFocus,
          ),
          const SizedBox(width: BattleLayoutTokens.sectionGap),
          Container(
            width: 1,
            height: BattleLayoutTokens.sectionDividerHeight,
            color: WuxiaColors.border,
          ),
          const SizedBox(width: BattleLayoutTokens.sectionGap),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var index = 0; index < 7; index++) ...[
                  Expanded(
                    key: ValueKey('battle_skill_slot_$index'),
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
                                isPending:
                                    localPendingThis || domainPendingThis,
                                pendingTapEnabled: localPendingThis,
                                queuedAnother:
                                    domainPending != null &&
                                    domainPending.id != skill.id,
                                highlight: enemyCharging && skill.canInterrupt,
                                allowPlayerIntervention:
                                    allowPlayerIntervention,
                                beat: beat,
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
                        : EmptySkillSlot(index: index),
                  ),
                  if (index < 6)
                    const SizedBox(width: BattleLayoutTokens.skillSlotGap),
                ],
              ],
            ),
          ),
          const SizedBox(width: BattleLayoutTokens.sectionGap),
          const BattlePouchRail(),
        ],
      ),
    );
  }
}

/// 重点角色选择器：我方 3 槽小头像 chip，点选切重点角色。
class FocusSelector extends StatelessWidget {
  final List<BattleCharacter> team;
  final int focusSlotIndex;
  final void Function(int slotIndex) onSelectFocus;

  const FocusSelector({
    super.key,
    required this.team,
    required this.focusSlotIndex,
    required this.onSelectFocus,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: BattleLayoutTokens.actorRailWidth,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            UiStrings.battleCommandDesk,
            style: TextStyle(
              color: WuxiaColors.textMuted,
              fontSize: 10,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 5),
          for (var i = 0; i < team.length; i++) ...[
            FocusChip(
              key: ValueKey('focus_chip_$i'),
              character: team[i],
              selected: i == focusSlotIndex,
              onTap: () => onSelectFocus(i),
            ),
            if (i < team.length - 1) const SizedBox(height: 4),
          ],
        ],
      ),
    );
  }
}

class FocusChip extends StatelessWidget {
  final BattleCharacter character;
  final bool selected;
  final VoidCallback onTap;

  const FocusChip({
    super.key,
    required this.character,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = WuxiaColors.schoolColor(character.school);
    final dim = !character.isAlive;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        height: BattleLayoutTokens.actorChipHeight,
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.28) : WuxiaColors.sidebar,
          border: Border.all(
            color: selected ? color : WuxiaColors.border,
            width: selected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Center(
          child: Row(
            children: [
              const SizedBox(width: 9),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: dim ? WuxiaColors.textMuted : color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  character.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                    color: dim
                        ? WuxiaColors.textMuted
                        : (selected
                              ? WuxiaColors.textPrimary
                              : WuxiaColors.textSecondary),
                  ),
                ),
              ),
              Text(
                '${character.currentQi}/${character.maxQi}',
                style: const TextStyle(
                  color: WuxiaColors.textMuted,
                  fontSize: 9,
                ),
              ),
              const SizedBox(width: 8),
            ],
          ),
        ),
      ),
    );
  }
}

/// 单个技能指令按钮：分组标签 + 招名 + 状态行（待发 / 冷却 N / 耗 N）。
/// `isPending` 盖"待发"印且禁用；`queuedAnother`（同角色已排别的技能）也禁用；
/// `highlight`（敌人蓄力 + 本技能可破招）换醒目金 + 白边。
class SkillCommandButton extends StatelessWidget {
  final BattleCharacter character;
  final SkillDef skill;
  final bool isPending;
  final bool pendingTapEnabled;
  final bool queuedAnother;
  final bool highlight;
  final bool allowPlayerIntervention;
  // 读秒环节拍(供 CD 环平滑插值)。
  final Animation<double> beat;
  // 两段点选:点击 = 释放(single 进待发态 / aoe 一键出手);长按 = 弹简介浮层。
  final VoidCallback onTap;
  final VoidCallback onShowInfo;

  const SkillCommandButton({
    super.key,
    required this.character,
    required this.skill,
    required this.isPending,
    required this.pendingTapEnabled,
    required this.queuedAnother,
    required this.highlight,
    required this.allowPlayerIntervention,
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

  @override
  Widget build(BuildContext context) {
    final cd = character.skillCooldowns[skill.id] ?? 0;
    final ready = isSkillReady(character, skill);
    final enabled =
        ready &&
        (!isPending || pendingTapEnabled) &&
        !queuedAnother &&
        allowPlayerIntervention;

    Color bgColor;
    final baseSchoolColor = WuxiaColors.schoolColor(character.school);
    if (!ready) {
      bgColor = WuxiaColors.buttonDisabled;
    } else if (highlight) {
      // 破招提示醒目金:原 0.72 上白字仅 ~2.9:1,压暗一档(0.52)让白字可读(~4.6:1)。
      bgColor = Color.lerp(
        WuxiaColors.sidebar,
        WuxiaColors.resultHighlight,
        0.52,
      )!;
    } else {
      bgColor = Color.lerp(WuxiaColors.sidebar, baseSchoolColor, 0.78)!;
    }

    // CD 态(非待发):招名让位,中心浮现读秒环示剩余拍数。
    final onCd = cd > 0 && !isPending;

    final String statusText;
    if (isPending) {
      statusText = UiStrings.skillPendingStamp; // 待发
    } else if (cd > 0) {
      statusText = ''; // CD 态由读秒环示数,不再显「冷却 N」文字。
    } else if (character.currentQi < skill.qiCost) {
      statusText = UiStrings.skillInsufficientForce;
    } else {
      // 耗内 N · CD M
      statusText = UiStrings.skillCostShort(skill.qiCost, skill.cooldownTurns);
    }

    final button = SizedBox(
      height: BattleLayoutTokens.skillSlotHeight,
      child: ElevatedButton(
        // 使用原生按钮同时承接点击释放与长按简介，保留桌面端
        // focus / 键盘激活 / mouse cursor / semantics，不用裸手势容器。
        onPressed: enabled ? onTap : null,
        onLongPress: onShowInfo,
        style: ElevatedButton.styleFrom(
          // 背景已由 bgColor(!ready→buttonDisabled)表达,
          // 前景按 enabled 手动切 muted/primary 保留「不可下发」灰态观感。
          backgroundColor: bgColor,
          disabledBackgroundColor: bgColor,
          foregroundColor: enabled
              ? WuxiaColors.textPrimary
              : WuxiaColors.textMuted,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          side: highlight && enabled
              ? const BorderSide(color: WuxiaColors.textPrimary, width: 2)
              : BorderSide(
                  color: baseSchoolColor.withValues(alpha: 0.46),
                  width: 1,
                ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Opacity(
              opacity: onCd ? 0.32 : 1.0, // CD 态招名让位给读秒环。
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _groupLabel(skill),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      skill.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      statusText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10,
                        height: 1.1,
                        fontWeight: isPending
                            ? FontWeight.bold
                            : FontWeight.w600,
                        color: isPending
                            ? WuxiaColors.resultHighlight
                            : (enabled
                                  ? WuxiaColors.textPrimary
                                  : WuxiaColors.textMuted),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (onCd)
              Positioned.fill(
                child: Center(
                  child: BeatCountdownRing(
                    remaining: cd,
                    total: skill.cooldownTurns,
                    beat: beat,
                    color: WuxiaColors.lingQiao,
                    size: 44,
                  ),
                ),
              ),
            if (isPending)
              const Positioned(top: -7, right: -7, child: PendingStamp()),
          ],
        ),
      ),
    );

    // 单体/群体角标：右上角小 chip，区分目标类型让玩家一眼看出操作语义。
    final badgeText = skill.targetType == TargetType.aoe
        ? UiStrings.skillBadgeAoe
        : UiStrings.skillBadgeSingle;
    final badgeColor = skill.targetType == TargetType.aoe
        ? WuxiaColors
              .resultHighlight // 群体用暖金色，醒目提示一键释放
        : WuxiaColors.textMuted.withValues(alpha: 0.70); // 单体用静默灰，提示需选目标
    final buttonWithBadge = Stack(
      clipBehavior: Clip.none,
      children: [
        button,
        Positioned(
          top: -4,
          right: -4,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: badgeColor,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              badgeText,
              style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: WuxiaColors.textPrimary,
                height: 1.2,
              ),
            ),
          ),
        ),
      ],
    );

    return Semantics(
      key: ValueKey('skill_cmd_${character.characterId}_${skill.id}'),
      button: true,
      enabled: enabled,
      label: '${_groupLabel(skill)} ${skill.name}',
      child: buttonWithBadge,
    );
  }
}

class EmptySkillSlot extends StatelessWidget {
  const EmptySkillSlot({super.key, required this.index});

  final int index;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: UiStrings.battleEmptySkillSlot,
      child: Container(
        key: ValueKey('battle_skill_empty_$index'),
        height: BattleLayoutTokens.skillSlotHeight,
        decoration: BoxDecoration(
          color: WuxiaColors.sidebar.withValues(alpha: 0.42),
          border: Border.all(color: WuxiaColors.border.withValues(alpha: 0.7)),
          borderRadius: BorderRadius.circular(5),
        ),
        child: const Center(
          child: Icon(Icons.add, size: 14, color: WuxiaColors.textMuted),
        ),
      ),
    );
  }
}

class BattlePouchRail extends StatelessWidget {
  const BattlePouchRail({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: BattleLayoutTokens.pouchWidth,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            children: [
              Text(
                UiStrings.battlePouch,
                style: TextStyle(
                  color: WuxiaColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
              Spacer(),
              Text(
                UiStrings.battlePouchReserved,
                style: TextStyle(color: WuxiaColors.textMuted, fontSize: 9),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              for (var i = 0; i < 3; i++) ...[
                Semantics(
                  label: '${UiStrings.battlePouch} ${i + 1}',
                  value: UiStrings.battlePouchReserved,
                  child: Container(
                    key: ValueKey('battle_pouch_slot_$i'),
                    width: BattleLayoutTokens.pouchSlotSize,
                    height: BattleLayoutTokens.pouchSlotSize,
                    decoration: BoxDecoration(
                      color: WuxiaColors.sidebar.withValues(alpha: 0.62),
                      border: Border.all(color: WuxiaColors.border),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: const Icon(
                      Icons.inventory_2_outlined,
                      size: 17,
                      color: WuxiaColors.textMuted,
                    ),
                  ),
                ),
                if (i < 2)
                  const SizedBox(width: BattleLayoutTokens.pouchSlotGap),
              ],
            ],
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
/// 描述 + 字段表(类型/目标/倍率/耗内/冷却/特性)+ 拖招提示。
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
