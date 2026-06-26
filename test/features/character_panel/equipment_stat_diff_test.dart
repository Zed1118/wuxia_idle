import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/domain/equipment.dart';
import 'package:wuxia_idle/core/domain/forging_slot.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/numbers_config.dart';
import 'package:wuxia_idle/features/character_panel/domain/equipment_stat_diff.dart';

Equipment _eq({
  int atk = 100,
  int hp = 100,
  int spd = 10,
  int enhance = 0,
  EquipmentTier tier = EquipmentTier.xunChang,
  int battleCount = 0,
  bool heritage = false,
  TechniqueSchool? school,
  List<ForgingSlot>? forging,
}) =>
    Equipment.create(
      defId: 'weapon_xunchang_tie_jian',
      tier: tier,
      slot: EquipmentSlot.weapon,
      obtainedAt: DateTime(2026),
      obtainedFrom: 'test',
      baseAttack: atk,
      baseHealth: hp,
      baseSpeed: spd,
      enhanceLevel: enhance,
      battleCount: battleCount,
      isLineageHeritage: heritage,
      school: school,
      forgingSlots: forging,
    );

void main() {
  late NumbersConfig n;

  setUpAll(() async {
    final repo = await GameRepository.loadAllDefs(
      loader: (path) => File(path).readAsString(),
    );
    n = repo.numbers;
  });

  test('候选攻高血低 → direction up/down/flat 正确', () {
    final cmp = equipmentFullDiff(
      current: _eq(atk: 100, hp: 200, spd: 10),
      candidate: _eq(atk: 150, hp: 100, spd: 10),
      numbers: n,
    );
    expect(cmp.isBaseline, isFalse);
    final atkRow =
        cmp.numericRows.firstWhere((r) => r.label.contains('攻'));
    final hpRow = cmp.numericRows.firstWhere((r) => r.label.contains('血'));
    final spdRow = cmp.numericRows.firstWhere((r) => r.label.contains('速'));
    expect(atkRow.direction, StatDirection.up);
    expect(hpRow.direction, StatDirection.down);
    expect(spdRow.direction, StatDirection.flat);
    expect(atkRow.candidateValue, greaterThan(atkRow.currentValue!));
  });

  test('空槽 current==null → isBaseline + currentValue null + 全 flat', () {
    final cmp = equipmentFullDiff(current: null, candidate: _eq(), numbers: n);
    expect(cmp.isBaseline, isTrue);
    expect(cmp.numericRows.every((r) => r.currentValue == null), isTrue);
    expect(
      cmp.numericRows.every((r) => r.direction == StatDirection.flat),
      isTrue,
    );
    expect(
      cmp.numericRows.firstWhere((r) => r.label.contains('攻')).candidateValue,
      greaterThan(0),
    );
  });

  test('品阶升 → categoryRow.highlightUp', () {
    final cmp = equipmentFullDiff(
      current: _eq(tier: EquipmentTier.xunChang),
      candidate: _eq(tier: EquipmentTier.xiangYang),
      numbers: n,
    );
    final tierRow =
        cmp.categoryRows.firstWhere((r) => r.label.contains('品阶'));
    expect(tierRow.highlightUp, isTrue);
  });

  test('开锋槽两侧长 3、空槽显占位', () {
    final cmp = equipmentFullDiff(current: _eq(), candidate: _eq(), numbers: n);
    expect(cmp.forgingCurrent.length, 3);
    expect(cmp.forgingCandidate.length, 3);
    expect(
      cmp.forgingCandidate
          .every((s) => s == EquipmentStatDiffText.emptyForging),
      isTrue,
    );
  });
}
