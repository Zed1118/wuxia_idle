import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/sect_rank.dart';
import 'package:wuxia_idle/data/defs/sect_candidate_def.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/features/sect/application/sect_member_service.dart';
import 'package:wuxia_idle/features/sect/domain/sect.dart';
import 'package:wuxia_idle/features/sect/presentation/sect_recruit_handler.dart';
import 'package:wuxia_idle/shared/strings.dart';

import '../../support/isar_test_support.dart';
import '../../support/test_data.dart';

/// `runSectRecruitFlow` 行为测（2026-07-19 coverage 补强）。
///
/// 真 Isar + 真 GameRepository + widget 层真确认弹窗交互，钉分支行为语义：
///   - 玩家婉拒 → declined + onFallback 调 + 不 markTriggered + 候选角色未入库
///   - 确认招收 → success + markTriggered 调 + 角色入派 + Sect lazy-init + SnackBar
///   - 满员 → fullCap + 孤儿角色回滚删除 + onFallback 调 + 不 markTriggered
/// 交替 runAsync/pump 的轮询体例沿 `disciple_join_hook_test._pumpUntilFound`。
void main() {
  late Directory tempDir;

  setUpAll(() async {
    await initializeTestIsarCore();
    if (!GameRepository.isLoaded) {
      await loadTestGameRepository();
    }
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp(
      'wuxia_sect_recruit_handler_',
    );
    await IsarSetup.init(directory: tempDir, inspector: false);
  });

  tearDown(() async {
    await IsarSetup.close();
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  SectCandidateDef candidate() =>
      GameRepository.instance.sectCandidates['bamboo_swordsman']!;

  /// 泵一个最小宿主（ScaffoldMessenger + dialog Navigator 就绪），捕获 context/ref。
  Future<({BuildContext context, WidgetRef ref})> pumpHost(
    WidgetTester tester,
  ) async {
    BuildContext? hostContext;
    WidgetRef? hostRef;
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: Consumer(
              builder: (context, ref, _) {
                hostContext = context;
                hostRef = ref;
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      ),
    );
    return (context: hostContext!, ref: hostRef!);
  }

  Future<void> pumpUntilFound(
    WidgetTester tester,
    Finder finder, {
    int maxRounds = 50,
  }) async {
    const step = Duration(milliseconds: 30);
    for (var i = 0; i < maxRounds; i++) {
      if (finder.evaluate().isNotEmpty) return;
      await tester.runAsync(() => Future<void>.delayed(step));
      await tester.pump(step);
    }
    // 找到后再让续拍落定（弹窗动画/真 async 收尾），随后的 tap 才打得中。
    for (var i = 0; i < 3; i++) {
      await tester.runAsync(() => Future<void>.delayed(step));
      await tester.pump(step);
    }
    expect(finder.evaluate().isNotEmpty, isTrue, reason: '轮询超时未找到: $finder');
  }

  /// 起 flow（不 await），等弹窗出现后点 [tapLabel] 按钮，返回 flow 结果。
  Future<SectRecruitOutcome> runFlowAndTap(
    WidgetTester tester, {
    required BuildContext context,
    required WidgetRef ref,
    required String tapLabel,
    required void Function() onMarkTriggered,
    required void Function() onFallback,
  }) async {
    late Future<SectRecruitOutcome> future;
    await tester.runAsync(() async {
      future = runSectRecruitFlow(
        context: context,
        ref: ref,
        isar: IsarSetup.instance,
        candidate: candidate(),
        onMarkTriggered: () async => onMarkTriggered(),
        onFallback: () async => onFallback(),
        successSnackBar: '招收成功占位',
        capFullSnackBar: '门派满员占位',
        noSectSnackBar: '无门派占位',
      );
      await tester.pump();
    });
    await pumpUntilFound(tester, find.text(tapLabel));
    await tester.tap(find.text(tapLabel));
    final outcome = await tester.runAsync(() => future);
    return outcome!;
  }

  testWidgets('玩家婉拒 → declined + onFallback + 不 markTriggered + 角色未入库', (
    tester,
  ) async {
    final host = await pumpHost(tester);
    var fallbackCalls = 0;
    var markCalls = 0;

    final outcome = await runFlowAndTap(
      tester,
      context: host.context,
      ref: host.ref,
      tapLabel: UiStrings.sectEncounterRecruitDecline,
      onMarkTriggered: () => markCalls++,
      onFallback: () => fallbackCalls++,
    );

    expect(outcome, SectRecruitOutcome.declined);
    expect(fallbackCalls, 1, reason: '婉拒须走 fallback（可重战重遇语义）');
    expect(markCalls, 0, reason: '婉拒不 markTriggered');
    await tester.runAsync(() async {
      expect(
        await IsarSetup.instance.characters.count(),
        0,
        reason: '婉拒不应建候选角色',
      );
      // lazy-init 先于弹窗：默认门派已落库（此后招收才有 sect 可入）。
      final sects = await IsarSetup.instance.sects.where().findAll();
      expect(sects, hasLength(1));
      expect(sects.single.name, UiStrings.sectLazyInitName);
    });
  });

  testWidgets(
    '确认招收 → success + markTriggered + 角色入派 + lazy-init 默认门派 + SnackBar',
    (tester) async {
      final host = await pumpHost(tester);
      var fallbackCalls = 0;
      var markCalls = 0;

      final outcome = await runFlowAndTap(
        tester,
        context: host.context,
        ref: host.ref,
        tapLabel: UiStrings.sectEncounterRecruitAccept,
        onMarkTriggered: () => markCalls++,
        onFallback: () => fallbackCalls++,
      );

      expect(outcome, SectRecruitOutcome.success);
      expect(markCalls, 1, reason: '成功须 markTriggered（一次性防刷）');
      expect(fallbackCalls, 0);
      await tester.runAsync(() async {
        final chars = await IsarSetup.instance.characters.where().findAll();
        expect(chars, hasLength(1));
        final c = chars.single;
        expect(c.name, candidate().name);
        expect(c.isInSect, isTrue);
        expect(c.sectRank, SectRank.initiate);
        expect(c.isFounder, isFalse);
        final sect = (await IsarSetup.instance.sects.where().findAll()).single;
        expect(
          sect.name,
          UiStrings.sectLazyInitName,
          reason: '无门派行时 lazy-init 建默认派',
        );
        expect(sect.memberCount, 1);
        expect(c.sectId, sect.id);
      });
      await tester.pump();
      expect(find.text('招收成功占位'), findsOneWidget, reason: '成功 SnackBar 应显示');
    },
  );

  testWidgets('满员 → fullCap + 孤儿角色回滚删除 + onFallback + 不 markTriggered', (
    tester,
  ) async {
    // 先种满员门派（cap 取 numbers 真值，不写死）。
    final cap = SectMemberService.memberCapFor(
      GameRepository.instance.numbers,
      1,
    );
    await tester.runAsync(() async {
      await IsarSetup.instance.writeTxn(() async {
        await IsarSetup.instance.sects.put(
          Sect()
            ..name = '满员派'
            ..founderId = 1
            ..sectLevel = 1
            ..sectReputation = 50
            ..totalWins = 0
            ..memberCount = cap
            ..territoryIds = []
            ..createdAt = DateTime(2026, 5, 26),
        );
      });
    });
    final host = await pumpHost(tester);
    var fallbackCalls = 0;
    var markCalls = 0;

    final outcome = await runFlowAndTap(
      tester,
      context: host.context,
      ref: host.ref,
      tapLabel: UiStrings.sectEncounterRecruitAccept,
      onMarkTriggered: () => markCalls++,
      onFallback: () => fallbackCalls++,
    );

    expect(outcome, SectRecruitOutcome.capFull);
    expect(fallbackCalls, 1, reason: '满员须走 fallback（可重战重遇语义）');
    expect(markCalls, 0, reason: '满员不 markTriggered');
    await tester.runAsync(() async {
      expect(
        await IsarSetup.instance.characters.count(),
        0,
        reason: 'recruit 失败时孤儿角色须回滚删除',
      );
      final sect = (await IsarSetup.instance.sects.where().findAll()).single;
      expect(sect.memberCount, cap, reason: '回滚后 memberCount 不变');
    });
  });
}
