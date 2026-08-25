import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/data/numbers_config.dart';
import 'package:wuxia_idle/features/combat_shared/application/combat_content_providers.dart';
import 'package:wuxia_idle/features/jianghu/application/jianghu_providers.dart';
import 'package:wuxia_idle/features/jianghu/domain/reputation.dart';
import 'package:wuxia_idle/features/jianghu_map/application/reputation_location_detail_provider.dart';
import 'package:wuxia_idle/features/jianghu_map/domain/reputation_location_detail.dart';
import 'package:wuxia_idle/features/mainline/application/mainline_providers.dart';
import 'package:wuxia_idle/features/mainline/domain/mainline_progress.dart';
import 'package:wuxia_idle/features/mainline/domain/onboarding_gate.dart';

import '../../../support/isar_test_support.dart';
import '../../../support/test_data.dart';

void main() {
  late Directory tempDir;

  setUpAll(() async {
    initializeTestIsarCore();
    await loadTestGameRepository();
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp(
      'reputation_location_detail_',
    );
    await IsarSetup.init(directory: tempDir, inspector: false);
  });

  tearDown(() async {
    await IsarSetup.close();
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  Reputation reputation(int id, String factionId, int value) => Reputation()
    ..id = id
    ..playerId = 1
    ..factionId = factionId
    ..value = value
    ..updatedAt = DateTime(2026, 8, 25);

  Future<ReputationLocationDetail> readDetail({
    List<String> cleared = const [kFirstChapterFinalStageId],
    List<Reputation>? reputations,
  }) {
    final container = ProviderContainer(
      overrides: [
        mainlineProgressProvider.overrideWith(
          (ref) async => MainlineProgress()..clearedStageIds = cleared,
        ),
        reputationsForCurrentPlayerProvider.overrideWith(
          (ref) async =>
              reputations ??
              [reputation(1, 'shaolin', 50), reputation(2, 'jiaoMen', -80)],
        ),
      ],
    );
    addTearDown(container.dispose);
    return container.read(reputationLocationDetailProvider.future);
  }

  test('读取六门派、稀疏持久声望、七阶与生产变化来源', () async {
    final detail = await readDetail();

    expect(detail.factions, hasLength(6));
    expect(detail.tiers, hasLength(7));
    expect(detail.tiers.first.min, -100);
    expect(detail.tiers.last.max, 100);
    expect(detail.trackedFactionCount, 2);
    expect(detail.factions.singleWhere((row) => row.id == 'shaolin').value, 50);
    expect(
      detail.factions.singleWhere((row) => row.id == 'jiaoMen').tier,
      'xueTu',
    );
    expect(
      detail.factions.singleWhere((row) => row.id == 'wudang').value,
      isNull,
    );
    expect(detail.stageBossKillDelta, 5);
    expect(detail.stageBossKillRivalDelta, 3);
    expect(detail.encounterNpcDeltaMin, -8);
    expect(detail.encounterNpcDeltaMax, 8);
  });

  test('未产生声望记录时六门派保持未记录且不补零', () async {
    final detail = await readDetail(reputations: const []);

    expect(detail.trackedFactionCount, 0);
    expect(detail.factions.every((row) => row.value == null), isTrue);
  });

  test('第一章末关前直达 provider fail closed', () async {
    await expectLater(
      readDetail(cleared: const []),
      throwsA(isA<StateError>()),
    );
  });

  test('声望 service 不可用时 fail closed', () async {
    final container = ProviderContainer(
      overrides: [
        mainlineProgressProvider.overrideWith(
          (ref) async =>
              MainlineProgress()
                ..clearedStageIds = const [kFirstChapterFinalStageId],
        ),
        reputationServiceProvider.overrideWithValue(null),
        reputationsForCurrentPlayerProvider.overrideWith(
          (ref) async => const <Reputation>[],
        ),
      ],
    );
    addTearDown(container.dispose);

    await expectLater(
      container.read(reputationLocationDetailProvider.future),
      throwsA(isA<StateError>()),
    );
  });

  test('未知门派持久声望 fail closed', () async {
    await expectLater(
      readDetail(reputations: [reputation(1, 'missing_faction', 10)]),
      throwsA(isA<StateError>()),
    );
  });

  test('重复门派持久声望不猜测并 fail closed', () async {
    await expectLater(
      readDetail(
        reputations: [
          reputation(1, 'shaolin', 10),
          reputation(2, 'shaolin', 20),
        ],
      ),
      throwsA(isA<StateError>()),
    );
  });

  test('越界持久声望 fail closed', () async {
    await expectLater(
      readDetail(reputations: [reputation(1, 'shaolin', 101)]),
      throwsA(isA<StateError>()),
    );
  });

  test('七阶配置出现断档时校验器 fail closed', () {
    final tiers = <ReputationTierDef>[
      const ReputationTierDef(
        tier: 'xueTu',
        min: -100,
        max: -71,
        label: '声名狼藉',
      ),
      const ReputationTierDef(tier: 'yiLiu', min: -10, max: 10, label: '薄有微名'),
    ];

    expect(
      () => validatedReputationLocationTiers(tiers),
      throwsA(isA<StateError>()),
    );
  });

  test('生产 numbers provider 与 repository 均可消费', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(
      container.read(numbersConfigProvider).jianghu.reputationTiers,
      hasLength(7),
    );
    expect(GameRepository.instance.factionDefs, hasLength(6));
  });
}
