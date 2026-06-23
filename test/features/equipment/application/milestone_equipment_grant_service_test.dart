import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/core/domain/equipment.dart';
import 'package:wuxia_idle/core/domain/save_data.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/features/equipment/application/milestone_equipment_grant_service.dart';

/// F1 MilestoneEquipmentGrantService 真 Isar 落地测试。
///
/// 不走 testWidgets(真 Isar writeTxn 与 FakeAsync 不兼容 · memory
/// feedback_isar_widget_test_deadlock),用普通 test() 直调 service。
/// setup 体例沿 equipment_service_test.dart。
void main() {
  late Directory tempDir;
  late MilestoneEquipmentGrantService service;

  setUpAll(() async {
    await Isar.initializeIsarCore(download: true);
    if (!GameRepository.isLoaded) {
      await GameRepository.loadAllDefs(
        loader: (path) => File(path).readAsString(),
      );
    }
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('wuxia_milestone_test_');
    await IsarSetup.init(directory: tempDir, inspector: false);
    service = MilestoneEquipmentGrantService(isar: IsarSetup.instance);
  });

  tearDown(() async {
    if (Isar.getInstance('wuxia_save_slot1') != null) {
      await IsarSetup.close();
    }
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('grantForTag 首次授予百战甲进背包(owner=null) + 记防重集', () async {
    final granted = await service.grantForTag(
      'mass_battle_merit',
      obtainedFrom: '群战军功',
    );
    expect(granted, contains('armor_special_bai_zhan_jia'));

    final all = await IsarSetup.instance.equipments.where().findAll();
    final bzj =
        all.firstWhere((e) => e.defId == 'armor_special_bai_zhan_jia');
    expect(bzj.ownerCharacterId, isNull, reason: '入背包不绑角色');
    expect(bzj.obtainedFrom, '群战军功');

    final save = await IsarSetup.instance.saveDatas.get(0);
    expect(
      save!.grantedMilestoneEquipmentIds,
      contains('armor_special_bai_zhan_jia'),
    );
  });

  test('grantForTag 二次调用幂等 no-op(不重发)', () async {
    await service.grantForTag('mass_battle_merit', obtainedFrom: '群战军功');
    final second =
        await service.grantForTag('mass_battle_merit', obtainedFrom: '群战军功');
    expect(second, isEmpty);

    final all = await IsarSetup.instance.equipments
        .filter()
        .defIdEqualTo('armor_special_bai_zhan_jia')
        .findAll();
    expect(all.length, 1, reason: '幂等:仅 1 件不重复');
  });

  test('inner_demon_reward 授心魔珠', () async {
    final granted = await service.grantForTag(
      'inner_demon_reward',
      obtainedFrom: '降服心魔',
    );
    expect(granted, contains('accessory_special_xin_mo_zhu'));
  });

  test('ascension_reward 授无名剑', () async {
    final granted = await service.grantForTag(
      'ascension_reward',
      obtainedFrom: '飞升所得',
    );
    expect(granted, contains('weapon_special_wu_ming_jian'));
  });

  test('未知 tag → 空', () async {
    expect(await service.grantForTag('nope', obtainedFrom: 'x'), isEmpty);
  });
}
