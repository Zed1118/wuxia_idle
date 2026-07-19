import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/domain/save_data.dart';
import 'package:wuxia_idle/data/defs/sect_candidate_def.dart';
import 'package:wuxia_idle/data/defs/stage_def.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/data/narrative_loader.dart';
import 'package:wuxia_idle/features/narrative/presentation/narrative_reader_screen.dart';
import 'package:wuxia_idle/features/sect/presentation/stage_boss_recruit_hook.dart';
import 'package:wuxia_idle/shared/utils/rng.dart';

import '../../support/isar_test_support.dart';
import '../../support/test_data.dart';

/// 招降 hook（victory/defeat 两版）守卫分支行为测（2026-07-19 coverage 补强）。
///
/// `stage_boss_recruit_test.dart` 已钉 yaml/schema/持久化/victory 命中主链，
/// 本文件补守卫矩阵与 defeat 命中链：
///   - 非 Boss / bossRecruit=null / 已触发 / rng 不命中 / candidate 未加载 → 静默跳过
///   - 命中但 recruitFlow=null 且 ref=null → 静默返回（不炸）
///   - defeat hook 命中 → recruitFlow 调 + onMarkTriggered 写防刷表
///   - 叙事非 placeholder → 先推阅读屏，关闭后才进招收 flow（顺序语义）
void main() {
  late Directory tempDir;

  setUpAll(() async {
    await initializeTestIsarCore();
    if (!GameRepository.isLoaded) {
      await loadTestGameRepository();
    }
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('wuxia_boss_hook_branch_');
    await IsarSetup.init(directory: tempDir, inspector: false);
  });

  tearDown(() async {
    await IsarSetup.close();
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  StageDef bossStage({
    String id = 'test_hook_boss',
    String candidateRef = 'bamboo_swordsman',
    double probability = 1.0,
  }) => StageDef(
    id: id,
    name: '测试Boss关',
    stageType: StageType.mainline,
    requiredRealm: RealmTier.sanLiu,
    enemyTeam: const [],
    isBossStage: true,
    baseExpReward: 0,
    difficultyMultiplier: 1,
    bossRecruit: BossRecruitConfig(
      candidateRef: candidateRef,
      baseProbability: probability,
    ),
  );

  StageDef nonBossStage() => const StageDef(
    id: 'test_hook_normal',
    name: '测试普通关',
    stageType: StageType.mainline,
    requiredRealm: RealmTier.sanLiu,
    enemyTeam: [],
    isBossStage: false,
    baseExpReward: 0,
    difficultyMultiplier: 1,
  );

  StageDef bossNoRecruitStage() => const StageDef(
    id: 'test_hook_boss_nocfg',
    name: '测试Boss关无招降',
    stageType: StageType.mainline,
    requiredRealm: RealmTier.sanLiu,
    enemyTeam: [],
    isBossStage: true,
    baseExpReward: 0,
    difficultyMultiplier: 1,
  );

  /// 记录调用的 recruitFlow 桩。
  Future<void> Function({
    required BuildContext context,
    required WidgetRef? ref,
    required Isar isar,
    required SectCandidateDef candidate,
    required Future<void> Function() onMarkTriggered,
    required Future<void> Function()? onFallback,
    required String successSnackBar,
    required String capFullSnackBar,
    required String noSectSnackBar,
  })
  recordingFlow(_FlowProbe probe) {
    return ({
      required context,
      required ref,
      required isar,
      required candidate,
      required onMarkTriggered,
      required onFallback,
      required successSnackBar,
      required capFullSnackBar,
      required noSectSnackBar,
    }) async {
      probe.calls++;
      probe.candidateId = candidate.id;
      probe.markTriggered = onMarkTriggered;
    };
  }

  Future<void> markStageTriggered(String stageId) async {
    final isar = IsarSetup.instance;
    await isar.writeTxn(() async {
      final save = await isar.saveDatas.get(0);
      save!.triggeredBossRecruitStageIds = [stageId];
      await isar.saveDatas.put(save);
    });
  }

  Future<List<String>> triggeredIds() async =>
      (await IsarSetup.instance.saveDatas.get(0))!.triggeredBossRecruitStageIds;

  test('非 Boss 关 → victory/defeat hook 均静默跳过', () async {
    final probe = _FlowProbe();
    await runStageBossRecruitHookAfterVictory(
      context: _MountedBuildContext(),
      ref: null,
      rng: _FixedRng(0),
      stage: nonBossStage(),
      recruitFlow: recordingFlow(probe),
      loadNarrative: (id) async => NarrativeContent.placeholder(id),
    );
    await runStageBossFailRecoverHookAfterDefeat(
      context: _MountedBuildContext(),
      ref: null,
      rng: _FixedRng(0),
      stage: nonBossStage(),
      recruitFlow: recordingFlow(probe),
      loadNarrative: (id) async => NarrativeContent.placeholder(id),
    );
    expect(probe.calls, 0);
  });

  test('Boss 关但 bossRecruit=null → 静默跳过', () async {
    final probe = _FlowProbe();
    await runStageBossRecruitHookAfterVictory(
      context: _MountedBuildContext(),
      ref: null,
      rng: _FixedRng(0),
      stage: bossNoRecruitStage(),
      recruitFlow: recordingFlow(probe),
      loadNarrative: (id) async => NarrativeContent.placeholder(id),
    );
    expect(probe.calls, 0);
  });

  test('已触发（防刷表含 stageId）→ 静默跳过，不重复招收', () async {
    await markStageTriggered('test_hook_boss');
    final probe = _FlowProbe();
    await runStageBossRecruitHookAfterVictory(
      context: _MountedBuildContext(),
      ref: null,
      rng: _FixedRng(0),
      stage: bossStage(),
      recruitFlow: recordingFlow(probe),
      loadNarrative: (id) async => NarrativeContent.placeholder(id),
    );
    await runStageBossFailRecoverHookAfterDefeat(
      context: _MountedBuildContext(),
      ref: null,
      rng: _FixedRng(0),
      stage: bossStage(),
      recruitFlow: recordingFlow(probe),
      loadNarrative: (id) async => NarrativeContent.placeholder(id),
    );
    expect(probe.calls, 0, reason: 'victory/defeat 共用防刷表，已触发即跳过');
  });

  test('rng 不命中 → 不进招收，不写防刷表', () async {
    final probe = _FlowProbe();
    await runStageBossRecruitHookAfterVictory(
      context: _MountedBuildContext(),
      ref: null,
      rng: _FixedRng(0.99),
      stage: bossStage(probability: 0.40),
      recruitFlow: recordingFlow(probe),
      loadNarrative: (id) async => NarrativeContent.placeholder(id),
    );
    await runStageBossFailRecoverHookAfterDefeat(
      context: _MountedBuildContext(),
      ref: null,
      rng: _FixedRng(0.99),
      stage: bossStage(),
      recruitFlow: recordingFlow(probe),
      loadNarrative: (id) async => NarrativeContent.placeholder(id),
    );
    expect(probe.calls, 0);
    expect(await triggeredIds(), isEmpty);
  });

  test('candidateRef 未加载 → 保险 fallback 静默跳过', () async {
    final probe = _FlowProbe();
    await runStageBossRecruitHookAfterVictory(
      context: _MountedBuildContext(),
      ref: null,
      rng: _FixedRng(0),
      stage: bossStage(candidateRef: 'ghost_npc_not_loaded'),
      recruitFlow: recordingFlow(probe),
      loadNarrative: (id) async => NarrativeContent.placeholder(id),
    );
    expect(probe.calls, 0);
    expect(await triggeredIds(), isEmpty);
  });

  test('命中但 recruitFlow=null 且 ref=null → 静默返回不炸', () async {
    await runStageBossRecruitHookAfterVictory(
      context: _MountedBuildContext(),
      ref: null,
      rng: _FixedRng(0),
      stage: bossStage(),
      loadNarrative: (id) async => NarrativeContent.placeholder(id),
    );
    expect(await triggeredIds(), isEmpty, reason: '未进 flow 不写防刷表');
  });

  test('defeat hook 命中 → recruitFlow 调 + onMarkTriggered 写防刷表', () async {
    final probe = _FlowProbe();
    await runStageBossFailRecoverHookAfterDefeat(
      context: _MountedBuildContext(),
      ref: null,
      rng: _FixedRng(0),
      stage: bossStage(),
      recruitFlow: recordingFlow(probe),
      loadNarrative: (id) async => NarrativeContent.placeholder(id),
    );
    expect(probe.calls, 1);
    expect(probe.candidateId, 'bamboo_swordsman');
    expect(probe.markTriggered, isNotNull);
    await probe.markTriggered!();
    expect(await triggeredIds(), contains('test_hook_boss'));
  });

  testWidgets('叙事非 placeholder → 先推阅读屏，关闭后才进招收 flow', (tester) async {
    BuildContext? hostContext;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              hostContext = context;
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
    final probe = _FlowProbe();
    late Future<void> future;
    await tester.runAsync(() async {
      future = runStageBossRecruitHookAfterVictory(
        context: hostContext!,
        ref: null,
        rng: _FixedRng(0),
        stage: bossStage(),
        recruitFlow: recordingFlow(probe),
        loadNarrative: (id) async => NarrativeContent(
          id: id,
          title: '招降叙事占位',
          paragraphs: const ['一段'],
          isPlaceholder: false,
        ),
      );
      await tester.pump();
    });
    // 阅读屏先出，且此时 flow 未进（顺序语义：先叙事后招收）。
    for (
      var i = 0;
      i < 50 && find.byType(NarrativeReaderScreen).evaluate().isEmpty;
      i++
    ) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 30)),
      );
      await tester.pump(const Duration(milliseconds: 30));
    }
    expect(find.byType(NarrativeReaderScreen), findsOneWidget);
    expect(probe.calls, 0, reason: '叙事关闭前不进招收 flow');

    await tester.runAsync(() async {
      Navigator.of(hostContext!).pop();
    });
    await tester.runAsync(() => future);
    expect(probe.calls, 1, reason: '叙事关闭后须进招收 flow');
    expect(probe.candidateId, 'bamboo_swordsman');
  });
}

class _FlowProbe {
  int calls = 0;
  String? candidateId;
  Future<void> Function()? markTriggered;
}

class _FixedRng implements Rng {
  _FixedRng(this.value);
  final double value;

  @override
  int nextInt(int max) => 0;

  @override
  double nextDouble() => value;

  @override
  T pick<T>(List<T> list) => list.first;
}

class _MountedBuildContext implements BuildContext {
  @override
  bool get mounted => true;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
