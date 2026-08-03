import 'package:flutter/material.dart';

import '../domain/battle_state.dart';
import '../../../shared/strings.dart';
import '../../../shared/theme/colors.dart';
import '../../../shared/theme/wuxia_tokens.dart';
import '../../../shared/widgets/wuxia_ui/glossary_tip.dart';
import 'countdown_ring.dart';

/// 批次 1.4:战斗角色头像旁的 buff/debuff 状态标签条。
///
/// **纯展示层**:只读 [BattleCharacter] 已有的战斗状态字段 + 调用方传入的
/// [wardActive] 渲染,绝不写 state、不参与任何战斗结算。状态来源(均为引擎
/// 已驱动字段,ward 除外见下):
/// - [wardActive]（floor30 护法结界 Task 6）→ 结界(buff · boss 专属,判定需
///   完整 [BattleState] 故由调用方算好传入,本组件不读 state)
/// - [BattleCharacter.internalInjury]    → 内伤(debuff · 影响生死,持续掉血可致死)
/// - [BattleCharacter.staggerTicksRemaining] → 踉跄(debuff · 影响操作,被破招后防御骤降)
/// - [BattleCharacter.swordSongResonanceActive] → 剑鸣(buff · 纯数值,暴击附威能)
///
/// **优先级排序**(GDD §1.4 任务定义 + floor30 结界摆最前):
/// ① 结界(决定当前输出是否有效) > ② 影响生死 > ③ 影响操作 > ④ 纯数值 buff。
/// 同 [Wrap] 内左→右即优先级降序。
///
/// **hover 释义**:复用已 ship 的薄 [GlossaryTip](宣纸黄底水墨 Tooltip),释义文案
/// 走 [UiStrings]。帮助系统 [HelpTopic] 无逐状态术语条目(仅有总括 combatAdvanced),
/// 故不新建平行术语表,直接用最薄 tooltip——与本任务「优先复用、没有就用最薄
/// hover tooltip」边界一致。
///
/// **蓄势**不在此渲染：顶部横幅保留单主警示，每名蓄势者的名帖旁使用
/// 暗绛拍数小印。本组件中的 [BeatCountdownRing] 只表示破绽/踉跄窗口，
/// 不能被误认为已移除的蓄势读秒环。
class AvatarStatusTags extends StatelessWidget {
  const AvatarStatusTags({
    super.key,
    required this.character,
    required this.beat,
    this.staggerWindowTicks = 3,
    this.wardActive = false,
  });

  final BattleCharacter character;

  /// 读秒环节拍(供破绽环平滑插值;内伤走 [SteppedCountdownRing] 不接节拍)。
  final Animation<double> beat;

  /// 破绽窗口时长(破绽读秒环分母)。
  final int staggerWindowTicks;

  /// floor30 护法结界(Task 6):此角色当前是否处于护法结界庇护中。纯读展示,
  /// 由调用方(需要完整 [BattleState] 才能判定护法存活)算好传入,
  /// 不在本组件内读 state(守本组件「只读 character」的既有契约)。
  final bool wardActive;

  @override
  Widget build(BuildContext context) {
    final items = <Widget>[];

    // ① 结界庇护(floor30 护法结界·boss 专属 buff):有护法存活时展示,
    // 让玩家理解「为何 Boss 几乎打不动」——优先级摆最前,信息权重高于自身
    // debuff(直接决定当前输出是否有效)。
    // 取色 bossFrame(Boss 专属深金)而非 internalForce(内力青蓝):后者是真气
    // 语义色,挂到 boss 头顶 pill 上会在水墨色板外多出一块高饱和蓝(基准图同位
    // 是绛红/金印),且与同屏 boss 金边不同源。深金与 boss 专属语义一致。
    if (wardActive) {
      items.add(
        const GuardianWardBrushTag(
          spec: AvatarStatusSpec(
            label: UiStrings.guardianWardActiveLabel,
            gloss: UiStrings.guardianWardActiveGloss,
            color: WuxiaColors.bossFrame,
          ),
        ),
      );
    }
    // ② 影响生死:内伤(持续掉血可致死)→ 读秒环(守方出手减1的不规则节奏,值变过渡)。
    final injury = character.internalInjury;
    if (injury != null && injury.remainingTurns > 0) {
      items.add(
        GlossaryTip(
          definition: UiStrings.statusInternalInjuryGloss,
          child: SteppedCountdownRing(
            remaining: injury.remainingTurns,
            color: WuxiaColors.statDecrease,
            size: 34,
          ),
        ),
      );
    }
    // ③ 影响操作:破绽/踉跄(被破招后防御骤降)→ 读秒环(每全局拍减1,接节拍平滑扫)。
    // 配色定夺(spec §3.4·2026-07-01 真机截图复核):破绽用暖金 lingQiao(机会),
    // 非 hpLow 绛红——绛红已是敌蓄力(危险)用色,破绽是「破招后可乘之机」的进攻窗口;
    // 且触发破绽的「可破招」⚡ 图标本就是 lingQiao,金色成链呼应,与绛红危险/暗绛内伤三态各自可读。
    if (character.staggerTicksRemaining > 0) {
      items.add(
        GlossaryTip(
          definition: UiStrings.statusStaggerGloss,
          child: BeatCountdownRing(
            remaining: character.staggerTicksRemaining,
            total: staggerWindowTicks,
            beat: beat,
            color: WuxiaColors.lingQiao,
            size: 34,
          ),
        ),
      );
    }
    // ④ 纯数值 buff:剑鸣(暴击附威能·非倒计时,保留文字药丸)。
    if (character.swordSongResonanceActive) {
      items.add(
        const AvatarStatusTag(
          spec: AvatarStatusSpec(
            label: UiStrings.statusSwordSongLabel,
            gloss: UiStrings.statusSwordSongGloss,
            color: WuxiaColors.resultHighlight,
          ),
        ),
      );
    }

    if (items.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 4,
      runSpacing: 3,
      alignment: WrapAlignment.center,
      children: items.take(2).toList(growable: false),
    );
  }
}

/// 护法结界专用的断边干笔题签。
///
/// 结界是战场机制提示，不沿用普通 buff 的现代圆角药丸；文字仍保留 hover
/// 释义与同一深金语义，底形则用不规则墨痕承接人物背后的护界气韵。
class GuardianWardBrushTag extends StatelessWidget {
  const GuardianWardBrushTag({super.key, required this.spec});

  final AvatarStatusSpec spec;

  @override
  Widget build(BuildContext context) {
    return GlossaryTip(
      definition: spec.gloss,
      child: CustomPaint(
        key: const ValueKey('battle.statusTag.guardianWardBrushPaper'),
        painter: const _GuardianWardBrushTagPainter(),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(7, 3, 7, 3),
          child: Text(
            spec.label,
            style: const TextStyle(
              fontSize: 10,
              height: 1,
              color: WuxiaUi.goldOnPaper,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.35,
            ),
          ),
        ),
      ),
    );
  }
}

/// 题签底形画笔。
///
/// **刻意不接 [AvatarStatusSpec.color]**:该字段是深底色板的 boss 金
/// ([WuxiaColors.bossFrame] `0xFFD4A017`),而题签是宣纸底,须走 [WuxiaUi] 那套
/// 旧金([WuxiaUi.goldOnPaper] `0xFF755D34`)——两套色板混用会把 2026-08-02 终拍
/// 认可的旧金干笔题签变成亮金。语义同源由 `avatar_status_tags_test` 在 spec 层
/// 断言,不靠这里渲染。故本画笔无入参,渲染只随 size 变。
class _GuardianWardBrushTagPainter extends CustomPainter {
  const _GuardianWardBrushTagPainter();

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final paper = Path()
      ..moveTo(1, size.height * 0.34)
      ..lineTo(size.width * 0.09, size.height * 0.12)
      ..lineTo(size.width * 0.38, size.height * 0.18)
      ..lineTo(size.width * 0.63, size.height * 0.08)
      ..lineTo(size.width - 1, size.height * 0.28)
      ..lineTo(size.width * 0.95, size.height * 0.76)
      ..lineTo(size.width * 0.71, size.height * 0.88)
      ..lineTo(size.width * 0.43, size.height * 0.80)
      ..lineTo(size.width * 0.14, size.height * 0.92)
      ..lineTo(0, size.height * 0.66)
      ..close();
    canvas.drawPath(
      paper,
      Paint()..color = WuxiaUi.gold.withValues(alpha: 0.11),
    );

    // 断边轮廓与两道贴身断毫分用两支笔。两道断毫本就同为 0.20(比轮廓淡一档),
    // 旧写法靠 `edge..color=` 级联改写同一支 Paint 达成,第二道是"继承"来的淡度、
    // 不是写明的——读代码时极易误判成 0.68。这里只把真实渲染写明,像素不变。
    Paint strokeAt(double alpha) => Paint()
      ..color = WuxiaUi.goldOnPaper.withValues(alpha: alpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.85
      ..strokeCap = StrokeCap.square;

    canvas.drawPath(paper, strokeAt(0.68));

    final hair = strokeAt(0.20);
    canvas.drawLine(
      Offset(size.width * 0.12, size.height * 0.34),
      Offset(size.width * 0.46, size.height * 0.27),
      hair,
    );
    canvas.drawLine(
      Offset(size.width * 0.58, size.height * 0.73),
      Offset(size.width * 0.88, size.height * 0.66),
      hair,
    );
  }

  // 渲染只随 size 变(无入参),故重建同型 painter 时无需重绘。
  @override
  bool shouldRepaint(covariant _GuardianWardBrushTagPainter oldDelegate) =>
      false;
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
