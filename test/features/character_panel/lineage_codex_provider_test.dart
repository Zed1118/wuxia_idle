import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/domain/equipment.dart';
import 'package:wuxia_idle/features/character_panel/application/lineage_codex_provider.dart';

Character _c(int id, {bool founder = false, int? master, LineageRole role = LineageRole.disciple}) =>
    Character()
      ..name = 'c$id'
      ..realmTier = RealmTier.sanLiu
      ..lineageRole = role
      ..id = id
      ..isFounder = founder
      ..masterId = master;

void main() {
  group('groupGenerations', () {
    test('单代：1 祖师 + 2 弟子(masterId 指向祖师)', () {
      final chars = [_c(1, founder: true, role: LineageRole.founder), _c(2, master: 1, role: LineageRole.senior), _c(3, master: 1, role: LineageRole.junior)];
      final gens = groupGenerations(characters: chars, heritage: const [], currentFounderId: 1, activeIds: const [1, 2, 3], recruitedIds: const []);
      expect(gens.length, 1);
      expect(gens[0].founder.id, 1);
      expect(gens[0].disciples.map((c) => c.id), [2, 3]);
      expect(gens[0].isCurrent, true);
    });

    test('多代：按 founder id 升序，太祖在前', () {
      final chars = [_c(1, founder: true, role: LineageRole.founder), _c(2, founder: true, master: 1, role: LineageRole.senior)];
      final gens = groupGenerations(characters: chars, heritage: const [], currentFounderId: 2, activeIds: const [2], recruitedIds: const []);
      expect(gens.map((g) => g.founder.id), [1, 2]);
      expect(gens[1].isCurrent, true);
    });

    test('当代弟子兜底走 active∪recruited(masterId 为空也不漏)', () {
      final chars = [_c(1, founder: true, role: LineageRole.founder), _c(2, master: null, role: LineageRole.senior)];
      final gens = groupGenerations(characters: chars, heritage: const [], currentFounderId: 1, activeIds: const [1, 2], recruitedIds: const []);
      expect(gens[0].disciples.map((c) => c.id), contains(2));
    });

    test('遗物按 owner 归代，背包(null owner)归当代', () {
      final chars = [_c(1, founder: true, role: LineageRole.founder)];
      final relic = Equipment()..id = 9..isLineageHeritage = true..ownerCharacterId = null..tier = EquipmentTier.xunChang;
      final gens = groupGenerations(characters: chars, heritage: [relic], currentFounderId: 1, activeIds: const [1], recruitedIds: const []);
      expect(gens[0].heritageEquipments.map((e) => e.id), [9]);
    });
  });
}
