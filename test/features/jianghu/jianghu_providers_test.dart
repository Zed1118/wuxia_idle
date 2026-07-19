import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/isar_provider.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/features/jianghu/application/jianghu_providers.dart';
import 'package:wuxia_idle/features/jianghu/domain/reputation.dart';

import '../../support/isar_test_support.dart';
import '../../support/test_data.dart';

/// `jianghu_providers` 行为测（2026-07-19 夜批 coverage 补强，基线 9/18 行）。
///
/// 真 Isar + 真 GameRepository + ProviderContainer 真读，钉：
///   - factionDisplayName:命中 yaml → 中文名;未命中 → 原 id 兜底
///   - reputationTier:经真 service 查 7 阶映射;service null → yiLiu 兜底
///   - reputation/npcRelation service nullable propagation
///   - reputationsForCurrentPlayer:null → 空;建行后按 playerId=1 拉回
void main() {
  late Directory tempDir;

  setUpAll(() async {
    await initializeTestIsarCore();
    if (!GameRepository.isLoaded) {
      await loadTestGameRepository();
    }
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('wuxia_jianghu_prov_');
  });

  tearDown(() async {
    await IsarSetup.close();
    IsarSetup.resetForTest();
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  ProviderContainer makeContainer() {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    return container;
  }

  test('factionDisplayName:命中 → yaml 名;未命中 → 原 id', () {
    final container = makeContainer();
    final anyFaction = GameRepository.instance.factionDefs.keys.first;
    expect(
      container.read(factionDisplayNameProvider(anyFaction)),
      GameRepository.instance.factionDefs[anyFaction]!.name,
    );
    expect(
      container.read(factionDisplayNameProvider('no_such_faction')),
      'no_such_faction',
      reason: '未知 id 原样兜底',
    );
  });

  test('reputationTier:service null → yiLiu;init 后查真映射', () async {
    final container = makeContainer();
    expect(
      container.read(reputationTierProvider(0)),
      'yiLiu',
      reason: 'service null → 中间档兜底',
    );

    await IsarSetup.init(directory: tempDir, inspector: false);
    container.invalidate(isarProvider);
    expect(container.read(reputationServiceProvider), isNotNull);
    final viaService = container.read(reputationServiceProvider)!.tierOf(100);
    expect(
      container.read(reputationTierProvider(100)),
      viaService,
      reason: 'provider 直通 service 7 阶映射',
    );
  });

  test('npcRelationService:Isar 未 init → null;init → 非 null', () async {
    final container = makeContainer();
    expect(container.read(npcRelationServiceProvider), isNull);

    await IsarSetup.init(directory: tempDir, inspector: false);
    container.invalidate(isarProvider);
    expect(container.read(npcRelationServiceProvider), isNotNull);
  });

  test('reputationsForCurrentPlayer:null → 空;建行后拉回', () async {
    final container = makeContainer();
    expect(
      await container.read(reputationsForCurrentPlayerProvider.future),
      isEmpty,
      reason: 'service null → 空 list(UI 兜底)',
    );

    await IsarSetup.init(directory: tempDir, inspector: false);
    container.invalidate(isarProvider);
    expect(
      await container.read(reputationsForCurrentPlayerProvider.future),
      isEmpty,
      reason: '无行 → 空 list',
    );

    await IsarSetup.instance.writeTxn(() async {
      await IsarSetup.instance.reputations.put(
        Reputation()
          ..playerId = 1
          ..factionId = 'shaoLin'
          ..value = 42,
      );
    });
    container.invalidate(reputationsForCurrentPlayerProvider);
    final rows = await container.read(
      reputationsForCurrentPlayerProvider.future,
    );
    expect(rows, hasLength(1));
    expect(rows.single.factionId, 'shaoLin');
    expect(rows.single.value, 42);
  });
}
