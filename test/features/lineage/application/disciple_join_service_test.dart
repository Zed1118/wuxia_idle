import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/domain/save_data.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/features/lineage/application/disciple_join_service.dart';
import 'package:wuxia_idle/features/onboarding/application/onboarding_service.dart';

/// 第七阶段批三 · Task 6:[DiscipleJoinService.joinForClearedStage] 过关懒创建命名弟子。
///
/// 沿 onboarding_service_test 体例:tempDir + Isar.init + GameRepository.loadAllDefs,
/// SOLO seed(ensureFoundingMasters 默认 soloStart=true,仅祖师)。
void main() {
  late Directory tempDir;
  late Isar isar;

  setUpAll(() async {
    await Isar.initializeIsarCore(download: true);
    if (!GameRepository.isLoaded) {
      await GameRepository.loadAllDefs(
        loader: (path) => File(path).readAsString(),
      );
    }
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('wuxia_disciple_join_test_');
    await IsarSetup.init(directory: tempDir, inspector: false);
    isar = IsarSetup.instance;
    // SOLO 开局:仅祖师 id=1。
    await OnboardingService(isar: isar).ensureFoundingMasters();
  });

  tearDown(() async {
    if (Isar.getInstance('wuxia_save_slot1') != null) {
      await IsarSetup.close();
    }
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('过 join 关 → 懒创建 senior 弟子并入队 + 防重', () async {
    final svc = DiscipleJoinService(isar: isar);
    final joined = await svc.joinForClearedStage('stage_01_02');
    expect(joined, isNotNull);
    expect(joined!.lineageRole, LineageRole.senior);
    expect(joined.isActive, true);
    final save = await isar.saveDatas.get(0);
    expect(save!.activeCharacterIds.contains(joined.id), true);
    expect(save.triggeredDiscipleJoinStageIds.contains('stage_01_02'), true);
    final founder = await isar.characters.get(1);
    expect(founder!.discipleIds.contains(joined.id), true);
    expect(joined.masterId, 1);

    // 幂等:重战同关不再创建
    final again = await svc.joinForClearedStage('stage_01_02');
    expect(again, isNull);
    expect((await isar.characters.where().findAll()).length, 2); // founder + 1
  });

  test('二弟子 junior 拜入 + 满队', () async {
    final svc = DiscipleJoinService(isar: isar);
    await svc.joinForClearedStage('stage_01_02');
    final j2 = await svc.joinForClearedStage('stage_01_04');
    expect(j2!.lineageRole, LineageRole.junior);
    expect((await isar.saveDatas.get(0))!.activeCharacterIds.length, 3);
  });

  test('非 join 关 → null 无副作用', () async {
    final svc = DiscipleJoinService(isar: isar);
    expect(await svc.joinForClearedStage('stage_01_01'), isNull);
    expect((await isar.characters.where().findAll()).length, 1); // 仅 founder
  });

  test('防御:该 role 命名弟子已存在 → 不重复创建(belt-and-suspenders)', () async {
    final svc = DiscipleJoinService(isar: isar);
    final first = await svc.joinForClearedStage('stage_01_02'); // 建 senior
    expect(first, isNotNull);
    // 清掉 triggered 标记模拟「防重集丢失」边缘,但 senior 角色已在
    await isar.writeTxn(() async {
      final s = await isar.saveDatas.get(0);
      s!.triggeredDiscipleJoinStageIds = [];
      await isar.saveDatas.put(s);
    });
    final dup = await svc.joinForClearedStage('stage_01_02');
    expect(dup, isNull); // 角色已存在 → 不重建
    // senior 仍只有一个
    final seniors = (await isar.characters.where().findAll())
        .where((c) => c.lineageRole == LineageRole.senior)
        .toList();
    expect(seniors.length, 1);
  });
}
