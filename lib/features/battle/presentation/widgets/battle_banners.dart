import 'package:flutter/material.dart';

import '../../../../core/domain/enums.dart';
import '../../domain/battle_log.dart';
import '../../domain/battle_skill_utils.dart';
import '../../domain/battle_state.dart';
import '../../../../shared/strings.dart';
import '../../../../shared/theme/colors.dart';
import '../../../../shared/theme/wuxia_tokens.dart';

class HintBanner extends StatelessWidget {
  final String hint;
  const HintBanner({super.key, required this.hint});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      color: WuxiaColors.hintBannerBg,
      child: Text(
        hint,
        style: const TextStyle(color: WuxiaColors.hintBannerText, fontSize: 13),
      ),
    );
  }
}

// ─── 江湖记招提示横幅（P1 周目进化 E2）───────────────────────────────────────

class CycleHintBanner extends StatelessWidget {
  final String hint;
  const CycleHintBanner({super.key, required this.hint});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      color: WuxiaColors.cycleHintBg,
      child: Text(
        hint,
        style: const TextStyle(color: WuxiaColors.cycleHintText, fontSize: 12),
      ),
    );
  }
}

// ─── 破绽窗口指令栏提示（第六阶段 Task 5）─────────────────────────────────

/// 指令栏上方薄提示条：右队（敌方）有存活角色处于破绽窗口，
/// 且我方至少有一个非普攻招式当前可立即下发时，显示「破绽 · 该爆发了」。
///
/// **只读 state**：不触碰 interveneNow / AP / 逻辑速度（红线 §5.5）。
/// 窗口关闭（所有敌方 stagger=0）后自然消失（SizedBox.shrink）。
class CoopBurstPromptBar extends StatelessWidget {
  final BattleState state;
  const CoopBurstPromptBar({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final hasBreakWindow = state.rightTeam.any(
      (e) => e.isAlive && e.staggerTicksRemaining > 0,
    );
    final hasActionableBurst = state.leftTeam.any(
      (character) => character.availableSkills.any(
        (skill) =>
            skill.type != SkillType.normalAttack &&
            canInterveneNow(state, character, skill),
      ),
    );
    if (!hasBreakWindow || !hasActionableBurst) {
      return const SizedBox.shrink();
    }

    return Container(
      key: const ValueKey('coop_burst_prompt_bar'),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      decoration: BoxDecoration(
        color: WuxiaColors.resultHighlight.withValues(alpha: 0.12), // 浅金底，水墨克制
        border: const Border(top: BorderSide(color: WuxiaColors.border)),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bolt_rounded,
            size: 13,
            color: WuxiaColors.resultHighlight,
          ),
          SizedBox(width: 5),
          Text(
            UiStrings.coopBurstPrompt,
            style: TextStyle(
              color: WuxiaColors.resultHighlight,
              fontSize: 12,
              letterSpacing: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── 蓄力危险条（T2）──────────────────────────────────────────────────────

/// 敌人蓄力大招时的顶部警示条。纯读 [BattleState.rightTeam]：取最临近发动
/// （[BattleCharacter.chargeTicksRemaining] 最小）的存活蓄力敌人，显示招名 + 剩余节拍，提示玩家
/// 看准时机破招。无敌人蓄力时返回 [SizedBox.shrink]（不占高度、不渲染 key）。
class DangerBar extends StatelessWidget {
  final BattleState state;
  const DangerBar({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    if (state.isFinished) return const SizedBox.shrink();
    BattleCharacter? imminent;
    for (final e in state.rightTeam) {
      if (!e.isAlive || e.chargingSkill == null) continue;
      if (imminent == null ||
          e.chargeTicksRemaining < imminent.chargeTicksRemaining) {
        imminent = e;
      }
    }
    if (imminent == null) return const SizedBox.shrink();
    final imminentCharacter = imminent;

    return SizedBox(
      key: const ValueKey('battle_danger_bar'),
      height: 34,
      width: double.infinity,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final stripWidth = (constraints.maxWidth * 0.16)
              .clamp(230.0, 290.0)
              .toDouble();
          final rightInset = (constraints.maxWidth * 0.23)
              .clamp(100.0, 390.0)
              .toDouble();
          return Align(
            alignment: Alignment.topRight,
            child: Container(
              key: const ValueKey('battle_danger_bar_strip'),
              width: stripWidth,
              height: 34,
              margin: EdgeInsets.only(right: rightInset),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Stack(
                children: [
                  const Positioned.fill(
                    child: IgnorePointer(
                      child: CustomPaint(
                        key: ValueKey('battle.dangerInkBrush'),
                        painter: _DangerInkBrushPainter(),
                      ),
                    ),
                  ),
                  Semantics(
                    container: true,
                    label: UiStrings.battleDangerCharging(
                      imminentCharacter.name,
                      imminentCharacter.chargingSkill!.name,
                      imminentCharacter.chargeTicksRemaining,
                    ),
                    excludeSemantics: true,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          UiStrings.battleDangerChargeLabel,
                          style: TextStyle(
                            color: Color(0xFFE3C59F),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 1,
                          height: 14,
                          color: const Color(0x888A2B21),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          UiStrings.battleDangerTicks(
                            imminentCharacter.chargeTicksRemaining,
                          ),
                          style: const TextStyle(
                            color: Color(0xFFD8C8AF),
                            fontSize: 11,
                            height: 1.1,
                          ),
                        ),
                      ],
                    ),
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

class _DangerInkBrushPainter extends CustomPainter {
  const _DangerInkBrushPainter();

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final path = Path()
      ..moveTo(0, size.height * 0.45)
      ..lineTo(size.width * 0.08, size.height * 0.26)
      ..lineTo(size.width * 0.20, size.height * 0.18)
      ..lineTo(size.width * 0.37, size.height * 0.22)
      ..lineTo(size.width * 0.54, size.height * 0.12)
      ..lineTo(size.width * 0.74, size.height * 0.20)
      ..lineTo(size.width * 0.92, size.height * 0.30)
      ..lineTo(size.width, size.height * 0.52)
      ..lineTo(size.width * 0.91, size.height * 0.72)
      ..lineTo(size.width * 0.71, size.height * 0.79)
      ..lineTo(size.width * 0.52, size.height * 0.70)
      ..lineTo(size.width * 0.29, size.height * 0.84)
      ..lineTo(size.width * 0.10, size.height * 0.71)
      ..close();
    canvas.drawPath(
      path,
      Paint()..color = WuxiaUi.jiang.withValues(alpha: 0.57),
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = WuxiaUi.ink.withValues(alpha: 0.72)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.85
        ..strokeCap = StrokeCap.square,
    );

    final scratch = Paint()
      ..color = WuxiaUi.paper2.withValues(alpha: 0.12)
      ..strokeWidth = 0.75
      ..strokeCap = StrokeCap.square;
    canvas.drawLine(
      Offset(size.width * 0.09, size.height * 0.38),
      Offset(size.width * 0.34, size.height * 0.31),
      scratch,
    );
    canvas.drawLine(
      Offset(size.width * 0.61, size.height * 0.61),
      Offset(size.width * 0.91, size.height * 0.55),
      scratch,
    );
  }

  @override
  bool shouldRepaint(covariant _DangerInkBrushPainter oldDelegate) => false;
}

// ─── 最近战报条（T3）──────────────────────────────────────────────────────

/// 底部常驻的最近关键战报（大招/破招/暴击/击杀），最多 3 条，最新在上。
/// 纯读 [BattleLog.recentKeyActions]；无关键战报时返回 [SizedBox.shrink]。
/// 点击整条 → [onTap]（打开完整日志抽屉）。实时反馈仍靠飘字/弹道，
/// 本条只做"刚刚发生了什么大事"的常驻速览。
class BattleReportStrip extends StatelessWidget {
  final BattleState state;
  final VoidCallback onTap;
  const BattleReportStrip({
    super.key,
    required this.state,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final keys = BattleLog.recentKeyActions(state);
    if (keys.isEmpty) return const SizedBox.shrink();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: const ValueKey('battle_report_strip'),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: const BoxDecoration(
            color: WuxiaColors.sidebar,
            border: Border(top: BorderSide(color: WuxiaColors.border)),
          ),
          child: Row(
            children: [
              const Icon(Icons.bolt, size: 14, color: WuxiaColors.textMuted),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var i = 0; i < keys.length; i++)
                      Text(
                        BattleLog.formatActionCompact(keys[i], state),
                        key: ValueKey('battle_report_line_$i'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: i == 0
                              ? WuxiaColors.textSecondary
                              : WuxiaColors.textMuted,
                          fontSize: 11,
                          height: 1.35,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right,
                size: 16,
                color: WuxiaColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
