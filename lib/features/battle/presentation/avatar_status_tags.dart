import 'package:flutter/material.dart';

import '../domain/battle_state.dart';
import '../../../shared/strings.dart';
import '../../../shared/theme/colors.dart';
import '../../../shared/widgets/wuxia_ui/glossary_tip.dart';

/// 批次 1.4:战斗角色头像旁的 buff/debuff 状态标签条。
///
/// **纯展示层**:只读 [BattleCharacter] 已有的战斗状态字段渲染,绝不写 state、
/// 不参与任何战斗结算。状态来源(均为引擎已驱动字段):
/// - [BattleCharacter.internalInjury]    → 内伤(debuff · 影响生死,持续掉血可致死)
/// - [BattleCharacter.staggerTicksRemaining] → 踉跄(debuff · 影响操作,被破招后防御骤降)
/// - [BattleCharacter.swordSongResonanceActive] → 剑鸣(buff · 纯数值,暴击附威能)
///
/// **优先级排序**(GDD §1.4 任务定义):① 影响生死 > ② 影响操作 > ③ 纯数值 buff。
/// 同 [Wrap] 内左→右即优先级降序。
///
/// **hover 释义**:复用已 ship 的薄 [GlossaryTip](宣纸黄底水墨 Tooltip),释义文案
/// 走 [UiStrings]。帮助系统 [HelpTopic] 无逐状态术语条目(仅有总括 combatAdvanced),
/// 故不新建平行术语表,直接用最薄 tooltip——与本任务「优先复用、没有就用最薄
/// hover tooltip」边界一致。
///
/// **蓄势/破招**不在此渲染:[CharacterAvatar] 已用 `_ChargeBar` 蓄力进度条 +
/// flash_on 图标专门表现,不重复贴标签。
class AvatarStatusTags extends StatelessWidget {
  const AvatarStatusTags({super.key, required this.character});

  final BattleCharacter character;

  @override
  Widget build(BuildContext context) {
    final tags = <AvatarStatusSpec>[];

    // ① 影响生死:内伤(持续掉血可致死)。
    if (character.internalInjury != null) {
      tags.add(const AvatarStatusSpec(
        label: UiStrings.statusInternalInjuryLabel,
        gloss: UiStrings.statusInternalInjuryGloss,
        color: WuxiaColors.yinRou,
      ));
    }
    // ② 影响操作:踉跄(被破招后防御骤降、难还手)。
    if (character.staggerTicksRemaining > 0) {
      tags.add(const AvatarStatusSpec(
        label: UiStrings.statusStaggerLabel,
        gloss: UiStrings.statusStaggerGloss,
        color: WuxiaColors.hpLow,
      ));
    }
    // ③ 纯数值 buff:剑鸣(暴击附威能)。
    if (character.swordSongResonanceActive) {
      tags.add(const AvatarStatusSpec(
        label: UiStrings.statusSwordSongLabel,
        gloss: UiStrings.statusSwordSongGloss,
        color: WuxiaColors.resultHighlight,
      ));
    }

    if (tags.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 4,
      runSpacing: 3,
      alignment: WrapAlignment.center,
      children: [for (final t in tags) AvatarStatusTag(spec: t)],
    );
  }
}

/// 单个状态标签:水墨克制的圆角小药丸 + hover/长按释义。
class AvatarStatusTag extends StatelessWidget {
  const AvatarStatusTag({super.key, required this.spec});

  final AvatarStatusSpec spec;

  @override
  Widget build(BuildContext context) {
    return GlossaryTip(
      definition: spec.gloss,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: spec.color.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: spec.color.withValues(alpha: 0.8)),
        ),
        child: Text(
          spec.label,
          style: TextStyle(
            fontSize: 10,
            height: 1.1,
            color: spec.color,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

/// 单个状态的展示规格(纯数据)。
@immutable
class AvatarStatusSpec {
  const AvatarStatusSpec({
    required this.label,
    required this.gloss,
    required this.color,
  });

  final String label;
  final String gloss;
  final Color color;
}
