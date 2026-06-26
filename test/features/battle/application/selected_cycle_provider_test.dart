import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/battle/application/selected_cycle_provider.dart';
import 'package:wuxia_idle/features/mainline/domain/mainline_progress.dart';

/// resolveTargetCycle 纯函数(战斗交互重做 Phase 2 周目按章):决定某章进入战斗
/// 用的周目。玩家显式选择优先;否则已通章回放最高;未通章用 cycle 1。
void main() {
  MainlineProgress chapterCleared(String chapterKey, List<int> cycles) {
    return MainlineProgress()
      ..saveDataId = 1
      ..clearedChapterCycleKeys =
          cycles.map((c) => '$chapterKey#$c').toList();
  }

  test('玩家显式选择优先于一切', () {
    final p = chapterCleared('ch1', [1, 2]);
    expect(resolveTargetCycle(3, p, 'ch1'), 3);
    expect(resolveTargetCycle(1, p, 'ch1'), 1);
  });

  test('未选择 + 已通章 → 回放最高已通周目', () {
    final p = chapterCleared('ch1', [1, 2]);
    expect(resolveTargetCycle(null, p, 'ch1'), 2);
  });

  test('未选择 + 整章未通(highest=0) → cycle 1(首通)', () {
    final p = chapterCleared('ch1', []);
    expect(resolveTargetCycle(null, p, 'ch1'), 1);
  });

  test('chapterKey 隔离:别的章已通不影响本章', () {
    final p = chapterCleared('innerDemon', [1, 2]);
    // ch1 未通 → 1;innerDemon 已通到 2 → 2。
    expect(resolveTargetCycle(null, p, 'ch1'), 1);
    expect(resolveTargetCycle(null, p, 'innerDemon'), 2);
  });

  // keepAlive 回归锚:选定周目须跨「进战斗→返回」导航(选关屏 unmount)存活,
  // 否则打完一关跳回最高已通周目。autoDispose 时移除监听后重读会回 null,
  // keepAlive 下仍保留选定值。
  test('SelectedChallengeCycle keepAlive:移除监听后选定值仍保留(不回 null)', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    // 模拟选关屏挂载监听 + 玩家选第2周目。
    final sub =
        container.listen(selectedChallengeCycleProvider('ch1'), (_, _) {});
    container
        .read(selectedChallengeCycleProvider('ch1').notifier)
        .select(2);
    expect(container.read(selectedChallengeCycleProvider('ch1')), 2);

    // 模拟选关屏 unmount(移除监听)→ keepAlive 不回收。
    sub.close();
    expect(
      container.read(selectedChallengeCycleProvider('ch1')),
      2,
      reason: 'keepAlive:导航离开选关屏后选定周目仍为2;autoDispose 会回 null',
    );
  });
}
