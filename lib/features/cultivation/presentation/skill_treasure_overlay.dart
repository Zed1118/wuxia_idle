import 'dart:async';

import 'package:flutter/material.dart';

import '../../../data/game_repository.dart';
import '../../../shared/strings.dart';
import '../../../shared/theme/colors.dart';
import '../../../shared/widgets/wuxia_ui/wuxia_ui.dart';
import '../domain/skill_drop_result.dart';

/// 技能书珍稀卷轴静态内容（第七阶段批二 ④）。
///
/// 纯展示 widget，无动画；动画由 [SkillTreasureOverlay] 驱动。
/// [skillName] 招式名、[imagePath] 招式插图路径（null / 资产缺失均走 fallback）。
/// [isManual] true = 真解首通（题字「悟得真解」）；false = 残页集齐（题字「残页集齐 · 神功重现」）。
///
/// 导出为独立 StatelessWidget 方便 widget test 直接 pump，不依赖 GameRepository。
class SkillTreasureContent extends StatelessWidget {
  final String skillName;
  final String? imagePath;
  final bool isManual;

  const SkillTreasureContent({
    super.key,
    required this.skillName,
    required this.imagePath,
    required this.isManual,
  });

  @override
  Widget build(BuildContext context) {
    final caption = isManual
        ? UiStrings.skillTreasureManualCaption
        : UiStrings.skillTreasureFragmentCaption;

    return Align(
      alignment: const Alignment(0, -0.10),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 印章符（复用 ceremony 风格：48×48 + sealGlyph「武」题字）
            Transform.rotate(
              angle: -0.08,
              child: SizedBox(
                width: 48,
                height: 48,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Image.asset(
                      WuxiaUi.ceremonyRedSeal,
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => DecoratedBox(
                        decoration: BoxDecoration(
                          color: WuxiaColors.gangMeng,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                    const Text(
                      UiStrings.sealGlyph,
                      style: TextStyle(
                        color: WuxiaColors.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            // 卷轴感题字「武学新得」/ 「秘传重现」(caption 语境标)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: WuxiaColors.resultHighlight.withValues(alpha: 0.15),
                border: Border.all(
                  color: WuxiaColors.resultHighlight.withValues(alpha: 0.45),
                ),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                caption,
                style: const TextStyle(
                  color: WuxiaColors.resultHighlight,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 招式插图（null 或资产缺失 → 水墨卷轴占位符）
            _SkillImage(imagePath: imagePath),
            const SizedBox(height: 14),

            // 招式名（大，金色题字感）
            Text(
              skillName,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: WuxiaColors.resultHighlight,
                fontSize: 38,
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(
                    blurRadius: 10,
                    color: Color(0xCC000000),
                    offset: Offset(2, 3),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

/// 招式插图（Image.asset + errorBuilder 降级为水墨卷轴符号）。
class _SkillImage extends StatelessWidget {
  final String? imagePath;
  const _SkillImage({required this.imagePath});

  @override
  Widget build(BuildContext context) {
    final path = imagePath;
    if (path == null) return _fallback();

    return Image.asset(
      path,
      height: 180,
      fit: BoxFit.contain,
      errorBuilder: (_, _, _) => _fallback(),
    );
  }

  Widget _fallback() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: const Color(0x22F0CC72),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: WuxiaColors.resultHighlight.withValues(alpha: 0.35),
          width: 1.5,
        ),
      ),
      alignment: Alignment.center,
      child: const Text(
        '武',
        style: TextStyle(
          color: WuxiaColors.resultHighlight,
          fontSize: 56,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

/// 招式书珍稀卷轴 overlay（第七阶段批二 ④）。
///
/// 结构与 [HeroCameraOverlay] 对齐：
/// - AnimationController 滑入+缩放+淡入（520ms）
/// - auto-dismiss（[_holdSeconds] 后，默认 3.0s fallback）
/// - 点击跳过
/// - once-guard 防重复回调（[_done]）
///
/// 纯展示层：不读写 BattleState / Isar。
/// 导出为公开 StatefulWidget 方便 widget test 直接 pump。
class SkillTreasureOverlay extends StatefulWidget {
  final String skillName;
  final String? imagePath;
  final bool isManual;
  final VoidCallback onDone;

  const SkillTreasureOverlay({
    super.key,
    required this.skillName,
    required this.imagePath,
    required this.isManual,
    required this.onDone,
  });

  @override
  State<SkillTreasureOverlay> createState() => _SkillTreasureOverlayState();
}

class _SkillTreasureOverlayState extends State<SkillTreasureOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _slide;
  late final Animation<double> _scale;
  late final Animation<double> _opacity;
  bool _done = false;
  Timer? _autoTimer;

  double get _holdSeconds =>
      GameRepository.isLoaded
          ? GameRepository.instance.numbers.heroCamera.holdSeconds
          : 3.0;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );

    final curve = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    // 从下方轻微滑入（y 偏移），区别于英雄镜头从右侧滑入（x 偏移）
    _slide = Tween<double>(begin: 1.0, end: 0.0).animate(curve);
    _scale = Tween<double>(begin: 0.88, end: 1.0).animate(curve);
    _opacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );

    _ctrl.forward();

    _autoTimer = Timer(
      Duration(milliseconds: (_holdSeconds * 1000).round()),
      _finish,
    );
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
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            radius: 0.9,
            colors: [Color(0x33000000), Color(0xCC000000)],
            stops: [0.45, 1.0],
          ),
        ),
        alignment: Alignment.center,
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (_, child) {
            return Transform.translate(
              // 从下方 32px 处滑入（卷轴展开感）
              offset: Offset(0, _slide.value * 32),
              child: Transform.scale(
                scale: _scale.value,
                child: Opacity(
                  opacity: _opacity.value,
                  child: child,
                ),
              ),
            );
          },
          child: SkillTreasureContent(
            skillName: widget.skillName,
            imagePath: widget.imagePath,
            isManual: widget.isManual,
          ),
        ),
      ),
    );
  }
}

/// 残页轻提示行（Task 11 DRY 共享入口）。
///
/// 仅 [SkillDropResult.isMinorFragment] 返回非空（集齐走重仪式 [presentSkillTreasure]，
/// 不走轻提示；SkillDropResult.none 返回 null）。
/// 招式名经 [GameRepository.getSkill] 查；仓库未载入 / id 不存在时 fallback 用
/// id 字面量（防 StateError 崩溃，与 [presentSkillTreasure] 一致）。
String? skillFragmentLineFor(SkillDropResult result) {
  if (!result.isMinorFragment) return null;
  final skillId = result.fragmentSkillId;
  if (skillId == null) return null;
  String skillName = skillId;
  if (GameRepository.isLoaded) {
    try {
      skillName = GameRepository.instance.getSkill(skillId).name;
    } catch (_) {
      // getSkill 抛 StateError：id 不存在，fallback 用 id 字面量。
    }
  }
  return UiStrings.skillFragmentGainedLine(
    skillName,
    result.fragmentCount,
    result.fragmentThreshold,
  );
}

/// 公共触发入口：若 [result.isMajor]，播卷轴重仪式并 await 至结束。
///
/// 从 [GameRepository] 查招式名 + 插图路径；若仓库未加载或 id 不存在则
/// 用 id 作为 fallback 名称（防止 StateError 崩溃）。
/// 返回 true = 播了卷轴；false = 非重仪式结果（no-op）。
///
/// **Task 11 调用处**：主线 / 爬塔 entry flow 在 SkillDropResult 有效时调用此函数。
Future<bool> presentSkillTreasure(
  BuildContext context,
  SkillDropResult result,
) async {
  if (!result.isMajor) return false;

  final skillId = result.manualGranted ?? result.fragmentSkillId;
  if (skillId == null || !context.mounted) return false;

  // 查招式名与插图（仓库未加载 / 找不到时 fallback，不崩溃）
  String skillName = skillId;
  String? imagePath;
  if (GameRepository.isLoaded) {
    try {
      final def = GameRepository.instance.getSkill(skillId);
      skillName = def.name;
      imagePath = def.imagePath;
    } catch (_) {
      // getSkill 抛 StateError：id 不存在，fallback 用 id 字面量
    }
  }

  final isManual = result.manualGranted != null;

  if (!context.mounted) return false;
  await showGeneralDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.transparent,
    transitionDuration: Duration.zero,
    pageBuilder: (ctx, _, _) => SkillTreasureOverlay(
      skillName: skillName,
      imagePath: imagePath,
      isManual: isManual,
      onDone: () => Navigator.of(ctx).pop(),
    ),
  );
  return true;
}
