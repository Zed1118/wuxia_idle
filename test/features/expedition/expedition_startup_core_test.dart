import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/application/system_clock_provider.dart';
import 'package:wuxia_idle/data/defs/expedition_config.dart';
import 'package:wuxia_idle/data/isar_provider.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/features/expedition/application/expedition_combat.dart';
import 'package:wuxia_idle/features/expedition/application/phase0a_expedition_combat_runner.dart';
import 'package:wuxia_idle/features/expedition/application/expedition_providers.dart';
import 'package:wuxia_idle/features/expedition/application/expedition_service.dart';
import 'package:wuxia_idle/features/expedition/application/expedition_startup.dart';
import 'package:wuxia_idle/features/expedition/domain/expedition_node.dart';
import 'package:wuxia_idle/features/expedition/domain/expedition_run.dart';
import 'package:wuxia_idle/features/activity/domain/activity_member_snapshot.dart';

import '../../support/isar_test_support.dart';

/// `settleActiveExpeditionOnOpen` 纯依赖核心行为测（2026-07-19 coverage 补强）。
///
/// fake service/combat 隔离 Isar 与战斗，只钉本层分支语义：
///   - 无 active 远征 → no-op 聚合结果（caughtUp=true / 0 节点），不进 settleToNow
///   - 有 active 远征 → 原样转调 `service.settleToNow`，combat/config/now 透传、结果透返
///
/// 下半补 `maybeSettleExpedition`（生产入口）provider 级守卫：
/// isar/service/config 任一 null → no-op；全就绪 → 真 runner 注入 + clock 取时 + 转调。
void main() {
  const config = ExpeditionConfig(
    normalNodeMinutes: 5,
    eliteNodeMinutes: 10,
    hpRecoverPctPerNode: 0,
    qiRecoverPctPerNode: 0,
    zhangshiPctPerLayer: 0,
  );

  test('无 active 远征 → no-op 结果且不进入结算', () async {
    final service = _FakeExpeditionService(active: null);
    final result = await settleActiveExpeditionOnOpen(
      service: service,
      combat: _NoopCombat(),
      config: config,
      now: DateTime(2026, 7, 19, 12),
    );
    expect(result.nodesSettled, 0);
    expect(result.currentNode, 0);
    expect(result.caughtUp, isTrue);
    expect(result.defeated, isFalse);
    expect(service.settleCalls, 0, reason: '无 active 不应进入 settleToNow');
  });

  test('有 active 远征 → 转调 settleToNow 并透传 combat/config/now 与结果', () async {
    const expected = ExpeditionSettlementResult(
      nodesSettled: 3,
      currentNode: 3,
      caughtUp: false,
      defeated: true,
    );
    final service = _FakeExpeditionService(
      active: ExpeditionRun(),
      settleResult: expected,
    );
    final combat = _NoopCombat();
    final now = DateTime(2026, 7, 19, 12, 30);
    final result = await settleActiveExpeditionOnOpen(
      service: service,
      combat: combat,
      config: config,
      now: now,
    );
    expect(result, same(expected), reason: '结算结果应原样透返');
    expect(service.settleCalls, 1);
    expect(service.lastCombat, same(combat));
    expect(service.lastConfig, same(config));
    expect(service.lastNow, now);
  });

  group('maybeSettleExpedition · provider 守卫', () {
    late Directory tempDir;

    setUpAll(() async {
      await initializeTestIsarCore();
    });

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp(
        'wuxia_expedition_startup_',
      );
      await IsarSetup.init(directory: tempDir, inspector: false);
    });

    tearDown(() async {
      await IsarSetup.close();
      if (await tempDir.exists()) await tempDir.delete(recursive: true);
    });

    /// 泵最小宿主（带 overrides）并捕获 WidgetRef。
    /// 注：不在本文件显式标注 overrides 列表类型（`Override` 符号与
    /// riverpod_annotation 冲突），列表字面量直接在 ProviderScope 参数处推导。
    Future<WidgetRef> Function(WidgetTester) pumpRefWith(
      ProviderScope Function(Widget child) scope,
    ) {
      return (tester) async {
        WidgetRef? captured;
        await tester.pumpWidget(
          scope(
            Consumer(
              builder: (context, ref, _) {
                captured = ref;
                return const SizedBox.shrink();
              },
            ),
          ),
        );
        return captured!;
      };
    }

    testWidgets('isar 为 null → no-op，不触 service', (tester) async {
      final service = _FakeExpeditionService(active: ExpeditionRun());
      final pump = pumpRefWith(
        (child) => ProviderScope(
          overrides: [
            isarProvider.overrideWith((ref) => null),
            expeditionServiceProvider.overrideWith((ref) => service),
            expeditionConfigProvider.overrideWith((ref) => config),
          ],
          child: MaterialApp(home: child),
        ),
      );
      await maybeSettleExpedition(await pump(tester));
      expect(service.settleCalls, 0);
    });

    testWidgets('service 为 null → no-op', (tester) async {
      final pump = pumpRefWith(
        (child) => ProviderScope(
          overrides: [
            isarProvider.overrideWith((ref) => IsarSetup.instance),
            expeditionServiceProvider.overrideWith((ref) => null),
            expeditionConfigProvider.overrideWith((ref) => config),
          ],
          child: MaterialApp(home: child),
        ),
      );
      // service 缺失时不炸、返回即 no-op（无 service 可断言，跑通即证据）。
      await maybeSettleExpedition(await pump(tester));
    });

    testWidgets('config 为 null → no-op', (tester) async {
      final service = _FakeExpeditionService(active: ExpeditionRun());
      final pump = pumpRefWith(
        (child) => ProviderScope(
          overrides: [
            isarProvider.overrideWith((ref) => IsarSetup.instance),
            expeditionServiceProvider.overrideWith((ref) => service),
            expeditionConfigProvider.overrideWith((ref) => null),
          ],
          child: MaterialApp(home: child),
        ),
      );
      await maybeSettleExpedition(await pump(tester));
      expect(service.settleCalls, 0);
    });

    testWidgets('全就绪 → 真 runner 注入 + clock 取时 + 转调 service', (tester) async {
      final fixedNow = DateTime(2026, 7, 19, 8, 30);
      const expected = ExpeditionSettlementResult(
        nodesSettled: 2,
        currentNode: 2,
        caughtUp: true,
        defeated: false,
      );
      final service = _FakeExpeditionService(
        active: ExpeditionRun()
          ..members = [ActivityMemberSnapshot()..characterId = 1],
        settleResult: expected,
      );
      final pump = pumpRefWith(
        (child) => ProviderScope(
          overrides: [
            isarProvider.overrideWith((ref) => IsarSetup.instance),
            expeditionServiceProvider.overrideWith((ref) => service),
            expeditionConfigProvider.overrideWith((ref) => config),
            systemClockProvider.overrideWithValue(_FixedClock(fixedNow)),
          ],
          child: MaterialApp(home: child),
        ),
      );
      await maybeSettleExpedition(await pump(tester));
      expect(service.settleCalls, 1);
      expect(
        service.lastCombat,
        isA<Phase0aExpeditionCombatRunner>(),
        reason: '路线 C 生产入口须注入 Phase 0A runner',
      );
      expect(service.lastNow, fixedNow, reason: '未传 now 时取 systemClock');
      expect(service.lastConfig, same(config));
    });
  });
}

class _FixedClock extends SystemClock {
  const _FixedClock(this.t);
  final DateTime t;

  @override
  DateTime now() => t;
}

class _FakeExpeditionService implements ExpeditionService {
  _FakeExpeditionService({
    ExpeditionRun? active,
    ExpeditionSettlementResult? settleResult,
  }) : _active = active,
       _settleResult = settleResult;

  final ExpeditionRun? _active;
  final ExpeditionSettlementResult? _settleResult;
  int settleCalls = 0;
  ExpeditionCombat? lastCombat;
  ExpeditionConfig? lastConfig;
  DateTime? lastNow;

  @override
  Future<ExpeditionRun?> activeRun() async => _active;

  @override
  Future<ExpeditionSettlementResult> settleToNow({
    required ExpeditionCombat combat,
    required ExpeditionConfig config,
    DateTime? now,
    int maxNodesPerBatch = ExpeditionService.defaultMaxNodesPerBatch,
    int maxBatches = 4096,
  }) async {
    settleCalls++;
    lastCombat = combat;
    lastConfig = config;
    lastNow = now;
    return _settleResult!;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _NoopCombat implements ExpeditionCombat {
  @override
  Future<Map<int, ExpeditionMemberCaps>> memberCaps(
    List<int> characterIds,
  ) async => const {};

  @override
  Future<ExpeditionNodeOutcome> fight({
    required ExpeditionNode node,
    required Map<int, ExpeditionMemberVital> memberStates,
    required int nodeSeed,
    required int cycleIndex,
  }) async => const ExpeditionNodeOutcome(
    leftWin: true,
    survivorHp: {},
    survivorQi: {},
  );
}
