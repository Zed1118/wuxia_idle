import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/application/battle_providers.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/numbers_config.dart';
import 'package:wuxia_idle/features/battle/presentation/cycle_select_control.dart';
import 'package:wuxia_idle/features/mainline/application/mainline_providers.dart';
import 'package:wuxia_idle/features/mainline/domain/mainline_progress.dart';
import 'package:wuxia_idle/features/mainline/presentation/stage_list_screen.dart';
import 'package:wuxia_idle/shared/strings.dart';

/// 周目按章:主线关卡列表屏章级 CycleSelectControl 接线测试(Phase 2 上移)。
///
/// 验证整章已通(clearedChapterCycleKeys 含 ch1#1)→ 章头渲染唯一一个
/// CycleSelectControl;整章未通 → 内部 guard 不渲染周目文案。
/// 不接 Isar — provider override 喂态。
void main() {
  setUpAll(() async {
    if (!GameRepository.isLoaded) {
      await GameRepository.loadAllDefs(
        loader: (path) => File(path).readAsString(),
      );
    }
  });

  /// Ch1 整章已通(章末 Boss cycle 1)→ 章级周目 key ch1#1。
  MainlineProgress mkProgressCleared() {
    return MainlineProgress()
      ..saveDataId = 1
      ..currentChapterIndex = 1
      ..clearedStageIds = [
        'stage_01_01',
        'stage_01_02',
        'stage_01_03',
        'stage_01_04',
        'stage_01_05',
      ]
      ..clearedAt = List.filled(5, DateTime(2026))
      ..clearedStageCycleKeys = ['stage_01_05#1']
      ..clearedChapterCycleKeys = ['ch1#1'];
  }

  /// 全新进度（无通关）。
  MainlineProgress mkProgressFresh() {
    return MainlineProgress()
      ..saveDataId = 1
      ..currentChapterIndex = 1
      ..clearedStageIds = []
      ..clearedAt = []
      ..clearedStageCycleKeys = []
      ..clearedChapterCycleKeys = [];
  }

  Future<void> pumpScreen(
    WidgetTester tester, {
    required MainlineProgress progress,
    int maxCycle = 3,
  }) async {
    await tester.binding.setSurfaceSize(const Size(1024, 720));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          mainlineProgressProvider.overrideWith((ref) async => progress),
          numbersConfigProvider.overrideWithValue(
            _NumbersStub(maxCycleMainline: maxCycle),
          ),
        ],
        child: const MaterialApp(
          home: StageListScreen(chapterIndex: 1),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  testWidgets(
      '整章已通(ch1#1) → 章头唯一 CycleSelectControl 显「挑战第2周目」',
      (tester) async {
    await pumpScreen(tester, progress: mkProgressCleared());

    // 周目控件上移到章层 → 全屏唯一一个(非 per-tile)。
    expect(
      find.byType(CycleSelectControl),
      findsOneWidget,
      reason: '章级周目控件唯一,挂在章头(journey map 下方)',
    );
    expect(
      find.textContaining(UiStrings.cycleChallengeNextLabel(2)),
      findsOneWidget,
      reason: '第1周目已通、maxCycle=3 时应显示「挑战第2周目」',
    );
  });

  testWidgets(
      '整章未通 → 章级 CycleSelectControl 内部 guard 不渲染周目文案',
      (tester) async {
    await pumpScreen(tester, progress: mkProgressFresh());

    // 控件挂在章头但 highestClearedCycleForChapter=0 → 返回 SizedBox。
    expect(find.text(UiStrings.cycleReplayCurrentSuffix), findsNothing);
    expect(find.textContaining('挑战第'), findsNothing);
  });

  /// Ch1 第1周目「全 5 关」已手工首通 → 扫荡门槛达成。
  MainlineProgress mkProgressSweepable() {
    return MainlineProgress()
      ..saveDataId = 1
      ..currentChapterIndex = 1
      ..clearedStageIds = [
        'stage_01_01',
        'stage_01_02',
        'stage_01_03',
        'stage_01_04',
        'stage_01_05',
      ]
      ..clearedAt = List.filled(5, DateTime(2026))
      ..clearedStageCycleKeys = [
        'stage_01_01#1',
        'stage_01_02#1',
        'stage_01_03#1',
        'stage_01_04#1',
        'stage_01_05#1',
      ]
      ..clearedChapterCycleKeys = ['ch1#1'];
  }

  testWidgets('第1周目全关已通 → 扫荡按钮高亮且标签带周目「第 1 周目」', (tester) async {
    await pumpScreen(tester, progress: mkProgressSweepable());

    // 用户要求:按钮一眼能看出扫的是第几周目。
    expect(find.text(UiStrings.sweepChapterButtonCycle(1)), findsOneWidget);
    // 门槛达成→不显灰显锁定提示。
    expect(find.text(UiStrings.sweepLockedHintCycle(1)), findsNothing);
  });

  testWidgets('第1周目未全通(仅 Boss) → 扫荡按钮灰显 + 周目门槛提示(§5.7 灰掉不隐藏)',
      (tester) async {
    // mkProgressCleared 仅含 stage_01_05#1(Boss),前 4 关无 #1 → 门槛未达。
    await pumpScreen(tester, progress: mkProgressCleared());

    // 灰显态告知玩家:为何不能扫 + 扫的是哪个周目(取代旧「整块隐藏」)。
    expect(find.text(UiStrings.sweepLockedHintCycle(1)), findsOneWidget);
    // 未达门槛→不显可点的高亮扫荡按钮。
    expect(find.text(UiStrings.sweepChapterButtonCycle(1)), findsNothing);
  });
}

/// NumbersConfig stub：只实现 cycleEvolution。
class _NumbersStub implements NumbersConfig {
  const _NumbersStub({required int maxCycleMainline})
      : _maxCycle = maxCycleMainline;

  final int _maxCycle;

  @override
  CycleEvolutionConfig get cycleEvolution => CycleEvolutionConfig(
        maxCycleMainline: _maxCycle,
        maxCycleTower: 2,
        scalePerCycle: 0.0,
        defenseRateCap: 0.6,
        traits: const CycleTraitsConfig(
          yuti: YutiTraitParams(
              defenseRateBonusC2: 0.0, defenseRateBonusC3: 0.0),
          fanzhen: FanzhenTraitParams(damagePerTick: 0, ticks: 0),
          ningjia: NingjiaTraitParams(critDamageTakenMult: 1.0),
          zhenqi: ZhenqiTraitParams(internalForcePct: 0.0),
          shipo: ShipoTraitParams(chargeSkillId: ''),
        ),
        assignment: const {},
      );

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError(
      '_NumbersStub: 只实现 cycleEvolution, '
      'invoked=${invocation.memberName}');
}
