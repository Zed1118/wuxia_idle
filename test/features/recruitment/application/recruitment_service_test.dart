import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/save_data.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/features/recruitment/application/recruitment_service.dart';

/// P1.1 A1 E.1 · RecruitmentService 红线契约(audit doc 方案 3 + 5 决策)。
///
/// 验证语义(memory `feedback_red_line_test_semantics` + audit §6.2):
/// - hasOffered / getRecruitedIds 默认值(SaveData 未 seed)
/// - getCandidates 来自 GameRepository.instance.recruitCandidates
/// - declineRecruitment 写入 recruitmentOffered=true,**不创** Character
/// - declineRecruitment 幂等:offered=true 时再调 no-op
/// - acceptCandidate 创建 Character 入 Isar(isActive=false 即 inactive 池)+
///   recruitedDiscipleIds 追加 + markOffered=true
/// - acceptCandidate 幂等:offered=true 时返回 -1 no-op
/// - candidateId 不在 yaml 中 → 抛 StateError(fail-fast,非 silent skip)
/// - caller 持锁(本服务方法不开 writeTxn,test 端 writeTxn 包裹)
void main() {
  late Directory tempDir;

  setUpAll(() async {
    await Isar.initializeIsarCore(download: true);
    if (!GameRepository.isLoaded) {
      await GameRepository.loadAllDefs(
        loader: (path) => File(path).readAsString(),
      );
    }
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('wuxia_recruit_svc_test_');
    await IsarSetup.init(directory: tempDir, inspector: false);
  });

  tearDown(() async {
    await IsarSetup.close();
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  Future<void> seedSave({bool offered = false}) async {
    final isar = IsarSetup.instance;
    await isar.writeTxn(() async {
      await isar.saveDatas.put(SaveData()
        ..slotId = IsarSetup.currentSlotId
        ..saveVersion = '0.12.0'
        ..createdAt = DateTime.now()
        ..lastSavedAt = DateTime.now()
        ..lastOnlineAt = DateTime.now()
        ..recruitmentOffered = offered);
    });
  }

  test('hasOffered 未 seed SaveData → 默认 false', () async {
    final svc = RecruitmentService(IsarSetup.instance);
    expect(await svc.hasOffered(), false);
  });

  test('getRecruitedIds 未 seed SaveData → 默认空 list', () async {
    final svc = RecruitmentService(IsarSetup.instance);
    expect(await svc.getRecruitedIds(), isEmpty);
  });

  test('getCandidates 返回 3 候选(D2.b 决议 · 按 id 升序)', () {
    final candidates = RecruitmentService.getCandidates();
    expect(candidates.length, 3);
    expect(candidates[0].id, 'candidate_a');
    expect(candidates[1].id, 'candidate_b');
    expect(candidates[2].id, 'candidate_c');
  });

  test('declineRecruitment 写 recruitmentOffered=true + 不创 Character', () async {
    await seedSave();
    final isar = IsarSetup.instance;
    final svc = RecruitmentService(isar);

    await isar.writeTxn(() => svc.declineRecruitment());

    expect(await svc.hasOffered(), true);
    expect(await isar.characters.count(), 0,
        reason: '谢绝路径不应创任何 Character');
  });

  test('declineRecruitment 幂等:offered=true 时再调 no-op', () async {
    await seedSave(offered: true);
    final isar = IsarSetup.instance;
    final svc = RecruitmentService(isar);

    await isar.writeTxn(() => svc.declineRecruitment());

    expect(await svc.hasOffered(), true);
  });

  test('acceptCandidate 创建 Character + recruitedDiscipleIds 追加 + markOffered',
      () async {
    await seedSave();
    final isar = IsarSetup.instance;
    final svc = RecruitmentService(isar);

    final newId = await isar.writeTxn(
      () => svc.acceptCandidate('candidate_a'),
    );

    expect(newId, greaterThan(0));
    expect(await svc.hasOffered(), true);
    expect(await svc.getRecruitedIds(), [newId]);

    final c = await isar.characters.get(newId);
    expect(c, isNotNull);
    expect(c!.name, '云寒青',
        reason: 'D4.b NPC name 来源 recruit_candidates.yaml');
    expect(c.isFounder, false);
    expect(c.isActive, false,
        reason: 'D1.b inactive 池语义:isActive=false + 不入 activeCharacterIds');

    // 校验 activeCharacterIds 仍为空(D1.b 决议的关键)
    final save = await isar.saveDatas.get(0);
    expect(save!.activeCharacterIds, isEmpty,
        reason: 'active 上限不动 · 红线 demo_max_characters: 3 不破');
  });

  test('acceptCandidate 幂等:offered=true 时返回 -1 no-op', () async {
    await seedSave(offered: true);
    final isar = IsarSetup.instance;
    final svc = RecruitmentService(isar);

    final result = await isar.writeTxn(
      () => svc.acceptCandidate('candidate_a'),
    );

    expect(result, -1);
    expect(await isar.characters.count(), 0,
        reason: 'offered=true 路径 acceptCandidate 不应创 Character');
  });

  test('acceptCandidate candidateId 不在 yaml → 抛 StateError', () async {
    await seedSave();
    final isar = IsarSetup.instance;
    final svc = RecruitmentService(isar);

    expect(
      () => isar.writeTxn(() => svc.acceptCandidate('not_exist_candidate')),
      throwsA(isA<StateError>().having(
        (e) => e.message,
        'message',
        contains('未在 recruit_candidates.yaml'),
      )),
    );
  });
}
