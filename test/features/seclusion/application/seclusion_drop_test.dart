import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/domain/attributes.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/data/defs/drop_entry.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/features/equipment/application/drop_service.dart';
import 'package:wuxia_idle/features/seclusion/application/seclusion_service.dart';
import 'package:wuxia_idle/features/seclusion/domain/retreat_session.dart';
import 'package:wuxia_idle/shared/strings.dart';
import 'package:wuxia_idle/shared/utils/rng.dart';

/// 固定 nextDouble 的测试 Rng（驱动外层闸 + 加权抽 1 确定性）。
class _ConstRng implements Rng {
  _ConstRng(this.value);
  final double value;
  @override
  double nextDouble() => value;
  @override
  int nextInt(int max) => 0;
  @override
  T pick<T>(List<T> list) => list[0];
}

const kSaveDataId = 1;
const kCharId = 10;

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
    tempDir = await Directory.systemTemp.createTemp('wuxia_seclusion_drop_');
    await IsarSetup.init(directory: tempDir, inspector: false);
    final ch = Character.create(
      name: 'test_hero',
      realmTier: RealmTier.xueTu,
      realmLayer: RealmLayer.qiMeng,
      attributes: Attributes(),
      rarity: RarityTier.biaoZhun,
      lineageRole: LineageRole.founder,
      createdAt: DateTime(2026, 1, 1),
      internalForce: 500,
    )..id = kCharId;
    await IsarSetup.instance.writeTxn(
      () => IsarSetup.instance.characters.put(ch),
    );
  });

  tearDown(() async {
    if (Isar.getInstance('wuxia_save_slot1') != null) {
      await IsarSetup.close();
    }
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  test('红线：5 图 dropTable 装备 tier == 压一阶目标 tier（守 §5.3 锁步）', () {
    const expected = <RetreatMapType, EquipmentTier>{
      RetreatMapType.shanLin: EquipmentTier.xunChang, // xueTu 边界压不动
      RetreatMapType.guJianZhong: EquipmentTier.xunChang, // sanLiu→压
      RetreatMapType.cangJingGe: EquipmentTier.xunChang,
      RetreatMapType.xuanYaPuBu: EquipmentTier.xiangYang, // erLiu→压
      RetreatMapType.duanYaJueBi: EquipmentTier.zhongQi, // zongShi→压
    };
    for (final m in GameRepository.instance.seclusionMaps) {
      expect(m.dropTable, isNotEmpty, reason: '${m.mapType} 应有 dropTable');
      for (final entry in m.dropTable.whereType<EquipmentDrop>()) {
        final def = GameRepository.instance.getEquipment(entry.equipmentDefId);
        expect(def.tier, expected[m.mapType],
            reason: '${m.mapType} 的 ${entry.equipmentDefId} tier 越界');
      }
    }
  });
}
