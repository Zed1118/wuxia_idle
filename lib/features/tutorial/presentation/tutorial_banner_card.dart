import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/isar_provider.dart';
import '../../../shared/theme/colors.dart';
import '../application/tutorial_providers.dart';
import '../application/tutorial_service.dart';
import '../domain/tutorial_hint_def.dart';

/// 新手引导 banner(P1 #42 Phase 2 §10 P1.y · GDD §10.2 第 2 方式)。
///
/// MainMenu 顶部条件渲染:
/// - `tutorialStep ∈ {6,7,8} && step ∉ tutorialHintsRead` → 显
/// - 否则父端不渲染本 widget(本 widget 不做条件判定,由 MainMenu 决定)
///
/// 设计:
/// - 红点 + 50-100 字介绍(GDD §10.2)
/// - 点击 → markHintRead 同事务 + invalidate provider → 父端自然隐藏
/// - 复用 `_TodayFestivalChip` Card + Padding + Row 体例
class TutorialBannerCard extends ConsumerWidget {
  /// hint def(必传,父端按 step 查 [TutorialHintDef.byStep])。
  final TutorialHintDef hint;

  /// 点击行为覆盖(P1.1 A1 E.1 加):step 6 收徒 banner 需 push RecruitmentDialog
  /// 而非只 markHintRead。父端按需注入(默认 null = 走原 markHintRead 路径)。
  final Future<void> Function()? onTapOverride;

  const TutorialBannerCard({
    super.key,
    required this.hint,
    this.onTapOverride,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onTapOverride != null ? onTapOverride!() : _onTap(ref),
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: WuxiaColors.panel,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: WuxiaColors.resultHighlight),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      hint.iconData,
                      color: WuxiaColors.resultHighlight,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            hint.title,
                            style: const TextStyle(
                              color: WuxiaColors.resultHighlight,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            hint.body,
                            style: const TextStyle(
                              color: WuxiaColors.textSecondary,
                              fontSize: 12,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // 右上角红点(GDD §10.2)。
              Positioned(
                top: -2,
                right: -2,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: WuxiaColors.hpLow,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _onTap(WidgetRef ref) async {
    final isar = ref.read(isarProvider);
    if (isar == null) return;
    final svc = TutorialService(isar);
    await isar.writeTxn(() => svc.markHintRead(hint.step));
    ref.invalidate(currentTutorialHintsReadProvider);
  }
}
