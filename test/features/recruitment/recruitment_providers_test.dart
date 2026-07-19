import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/isar_provider.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/features/recruitment/application/recruitment_providers.dart';
import 'package:wuxia_idle/features/recruitment/application/recruitment_service.dart';

import '../../support/isar_test_support.dart';
import '../../support/test_data.dart';

/// `recruitment_providers` 三 provider 行为测（2026-07-19 夜批 coverage
/// 补强，基线 0/9 行）。
///
/// 真 Isar + 真 GameRepository + ProviderContainer 真读（生产入口 =
/// tutorial step 6 banner 读 `recruitmentOfferedProvider`、LineagePanelScreen
/// inactive 段读 `recruitedDiscipleIdsProvider`），钉：
///   - service nullable propagation（Isar 未 init → null → banner 短路）
///   - offered:false → decline 后 true（一次性 only，banner 关）
///   - ids:[] → accept 后 [新弟子 id]（inactive 池语义落 SaveData）
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
      'wuxia_recruitment_providers_',
    );
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

  test('service:Isar 未 init → null;init + invalidate → 非 null', () async {
    final container = makeContainer();
    final sub = container.listen(recruitmentServiceProvider, (_, _) {});
    addTearDown(sub.close);

    expect(
      container.read(recruitmentServiceProvider),
      isNull,
      reason: 'test 路径 Isar 未 init → caller null-coalesce 跳过',
    );

    await IsarSetup.init(directory: tempDir, inspector: false);
    container.invalidate(isarProvider);
    expect(container.read(recruitmentServiceProvider), isNotNull);
  });

  test('offered:service null → false;decline 后 → true', () async {
    final container = makeContainer();
    expect(
      await container.read(recruitmentOfferedProvider.future),
      isFalse,
      reason: 'service null 时 banner 按「未发出」走 push dialog',
    );

    await IsarSetup.init(directory: tempDir, inspector: false);
    container.invalidate(isarProvider);
    final sub = container.listen(recruitmentOfferedProvider, (_, _) {});
    addTearDown(sub.close);
    expect(
      await container.read(recruitmentOfferedProvider.future),
      isFalse,
      reason: '全新 SaveData recruitmentOffered 默认 false',
    );

    await IsarSetup.instance.writeTxn(
      () => RecruitmentService(IsarSetup.instance).declineRecruitment(),
    );
    container.invalidate(recruitmentOfferedProvider);
    expect(
      await container.read(recruitmentOfferedProvider.future),
      isTrue,
      reason: 'D3.a 一次性:婉拒也 markOffered,banner 直接关',
    );
  });

  test('ids:accept 候选后返回新弟子 id;此前为空', () async {
    await IsarSetup.init(directory: tempDir, inspector: false);
    final container = makeContainer();
    container.invalidate(isarProvider);
    final sub = container.listen(recruitedDiscipleIdsProvider, (_, _) {});
    addTearDown(sub.close);

    expect(
      await container.read(recruitedDiscipleIdsProvider.future),
      isEmpty,
      reason: '全新 SaveData recruitedDiscipleIds 默认空',
    );

    final candidateId = RecruitmentService.getCandidates().first.id;
    final newId = await IsarSetup.instance.writeTxn(
      () => RecruitmentService(IsarSetup.instance).acceptCandidate(candidateId),
    );
    expect(newId, greaterThan(0));

    container.invalidate(recruitedDiscipleIdsProvider);
    expect(
      await container.read(recruitedDiscipleIdsProvider.future),
      [newId],
      reason: '收徒成功后 SaveData.recruitedDiscipleIds 追加新弟子 id',
    );
  });
}
