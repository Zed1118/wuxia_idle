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

/// P1 周目进化 E2：主线关卡列表屏 CycleSelectControl 接线测试。
///
/// 验证已通关关卡 tile 中渲染 CycleSelectControl（结构测试），以及
/// 未通关/locked 关卡 tile 中不渲染 CycleSelectControl。
/// 不接 Isar — provider override 喂态。
void main() {
  setUpAll(() async {
    if (!GameRepository.isLoaded) {
      await GameRepository.loadAllDefs(
        loader: (path) => File(path).readAsString(),
      );
    }
  });

  /// Ch1 stage_01_01 已通（cycle 1），其余关卡未通。
  MainlineProgress mkProgressCleared() {
    return MainlineProgress()
      ..saveDataId = 1
      ..currentChapterIndex = 1
      ..clearedStageIds = ['stage_01_01']
      ..clearedAt = [DateTime(2026)]
      ..clearedStageCycleKeys = ['stage_01_01#1'];
  }

  /// 全新进度（无通关）。
  MainlineProgress mkProgressFresh() {
    return MainlineProgress()
      ..saveDataId = 1
      ..currentChapterIndex = 1
      ..clearedStageIds = []
      ..clearedAt = []
      ..clearedStageCycleKeys = [];
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
      'stage_01_01 已通关 → CycleSelectControl 渲染在 tile 中（结构测试）',
      (tester) async {
    await pumpScreen(tester, progress: mkProgressCleared());

    // CycleSelectControl 嵌在已通关 tile 内 — 验在 widget 树中存在。
    // highestCleared=1(有 stage_01_01#1)+ maxCycle=3 → 应渲染「第1周目」 + 「挑战第2周目」。
    expect(
      find.byType(CycleSelectControl),
      findsWidgets,
      reason: '已通关关卡的 tile 中应含 CycleSelectControl',
    );
    // 验证「挑战第2周目」文案渲染（来自 CycleSelectControl 内部）。
    expect(
      find.textContaining(UiStrings.cycleChallengeNextLabel(2)),
      findsOneWidget,
      reason: '第1周目已通、maxCycle=3 时应显示「挑战第2周目」',
    );
  });

  testWidgets(
      '全新进度（无通关）→ 无 cycle replay/challenge 文案渲染（CycleSelectControl 内部 guard）',
      (tester) async {
    await pumpScreen(tester, progress: mkProgressFresh());

    // CycleSelectControl 在 tile 里（对 available 关卡 onSelectCycle=null）但
    // highestCleared=0 → 内部 guard 返回 SizedBox，无周目文案。
    expect(find.text(UiStrings.cycleReplayCurrentSuffix), findsNothing);
    expect(find.textContaining('挑战第'), findsNothing);
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
