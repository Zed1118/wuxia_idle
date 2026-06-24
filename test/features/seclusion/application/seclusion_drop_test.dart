import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/domain/attributes.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/equipment.dart';
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

  RetreatSession shanLinSession(int id) => RetreatSession()
    ..id = id
    ..saveDataId = kSaveDataId
    ..mapType = RetreatMapType.shanLin
    ..durationHours = 4
    ..startedAt = DateTime(2026, 5, 11, 10, 0)
    ..status = RetreatStatus.active
    ..actualRewards = [];

  test('computeOutputs：闸命中 + dropService → 1 件压一阶(山林 xunChang)', () {
    final now = DateTime(2026, 5, 11, 14, 0); // start + 4h
    final dropSvc = DropService(
      equipmentDefLookup: GameRepository.instance.getEquipment,
      defaultObtainedFrom: UiStrings.dropSourceSeclusion,
      now: () => now,
    );
    final out = SeclusionService.computeOutputs(
      session: shanLinSession(50),
      charRealmTier: RealmTier.xueTu,
      config: GameRepository.instance.numbers.retreat,
      maps: GameRepository.instance.seclusionMaps,
      now: now,
      dropService: dropSvc,
      rng: _ConstRng(0.0), // 0.0 < equipProb(1.0×0.1) → 命中；抽第 1 条
    );
    expect(out.equipmentDrops, hasLength(1));
    expect(out.equipmentDrops.first.tier, EquipmentTier.xunChang);
    expect(out.equipmentDrops.first.obtainedFrom, UiStrings.dropSourceSeclusion);
  });

  test('computeOutputs：不传 dropService → equipDrops 恒空(零回归)', () {
    final now = DateTime(2026, 5, 11, 14, 0);
    final out = SeclusionService.computeOutputs(
      session: shanLinSession(51),
      charRealmTier: RealmTier.xueTu,
      config: GameRepository.instance.numbers.retreat,
      maps: GameRepository.instance.seclusionMaps,
      now: now,
      rng: _ConstRng(0.0),
    );
    expect(out.equipmentDrops, isEmpty);
  });

  test('completeRetreat：收功后掉落装备真入 isar.equipments + obtainedFrom 闭关', () async {
    final start = DateTime(2026, 5, 11, 10, 0);
    final completeAt = start.add(const Duration(hours: 4));
    final session = RetreatSession()
      ..id = 60
      ..saveDataId = kSaveDataId
      ..mapType = RetreatMapType.shanLin
      ..durationHours = 4
      ..startedAt = start
      ..status = RetreatStatus.active
      ..actualRewards = [];
    await IsarSetup.instance.writeTxn(
      () => IsarSetup.instance.retreatSessions.put(session),
    );

    await SeclusionService(isar: IsarSetup.instance).completeRetreat(
      session: session,
      characterId: kCharId,
      charRealmTier: RealmTier.xueTu,
      config: GameRepository.instance.numbers.retreat,
      maps: GameRepository.instance.seclusionMaps,
      now: completeAt,
      rng: _ConstRng(0.0), // 强制外层闸命中
    );

    final eqs = await IsarSetup.instance.equipments.where().findAll();
    expect(eqs, hasLength(1));
    expect(eqs.first.tier, EquipmentTier.xunChang);
    expect(eqs.first.obtainedFrom, UiStrings.dropSourceSeclusion);
  });
}
