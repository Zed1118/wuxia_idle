import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/defs/master_def.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/numbers_config.dart';
import 'package:wuxia_idle/data/validation/lineage_recruit_red_lines_validator.dart';

import '../../support/test_data.dart';

/// B2 复核 4A(2026-09-17):角色四项属性区间 `[1,10]/[16,24]` 此前在
/// `lineage_recruit_red_lines_validator.dart` 四处写死,`numbers.character.attributes`
/// 合同零消费。现校验器读 [NumbersConfig.attributeBounds];本测试证明它真读了:
/// 同一批生产 def,换一份收窄的区间就必须红。
void main() {
  late GameRepository repo;
  late Map<String, dynamic> yamlAttributes;

  setUpAll(() async {
    repo = await loadTestGameRepository();
    yamlAttributes = loadTestNumbersSection(['character', 'attributes']);
  });

  test('attributeBounds 四个上下界与 numbers.yaml 字面一致', () {
    final b = repo.numbers.attributeBounds;
    expect(b.pointMin, yamlAttributes['point_per_attribute_min']);
    expect(b.pointMax, yamlAttributes['point_per_attribute_max']);
    expect(b.totalMin, yamlAttributes['total_points_min']);
    expect(b.totalMax, yamlAttributes['total_points_max']);
  });

  test('区间自洽:下界 ≤ 上界,总和区间落在四项单项之和内', () {
    expect(
      () => AttributeBoundsConfig.fromYaml({
        'point_per_attribute_min': 5,
        'point_per_attribute_max': 4,
        'total_points_min': 16,
        'total_points_max': 24,
      }),
      throwsA(isA<ArgumentError>()),
    );
    expect(
      () => AttributeBoundsConfig.fromYaml({
        'point_per_attribute_min': 1,
        'point_per_attribute_max': 10,
        'total_points_min': 3,
        'total_points_max': 24,
      }),
      throwsA(isA<ArgumentError>()),
    );
  });

  group('四个校验器消费 attributeBounds', () {
    /// 用该校验器自己那批生产 def 的极值构造「刚好卡掉一件」的区间:
    /// 单项上界压到 max-1,或总和下界抬到 min+1,任一必红。
    AttributeBoundsConfig narrowedPoint(Iterable<AttributeProfile> profiles) {
      final b = repo.numbers.attributeBounds;
      final maxPoint = profiles
          .expand(
            (p) => [p.constitution, p.enlightenment, p.agility, p.fortune],
          )
          .reduce((a, b) => a > b ? a : b);
      return AttributeBoundsConfig(
        pointMin: b.pointMin,
        pointMax: maxPoint - 1,
        totalMin: b.totalMin,
        totalMax: b.totalMax,
      );
    }

    AttributeBoundsConfig raisedTotalFloor(
      Iterable<AttributeProfile> profiles,
    ) {
      final b = repo.numbers.attributeBounds;
      final minTotal = profiles
          .map((p) => p.total)
          .reduce((a, b) => a < b ? a : b);
      return AttributeBoundsConfig(
        pointMin: b.pointMin,
        pointMax: b.pointMax,
        totalMin: minTotal + 1,
        totalMax: b.totalMax,
      );
    }

    final cases =
        <
          ({
            String name,
            Iterable<AttributeProfile> Function() profiles,
            void Function(AttributeBoundsConfig bounds) run,
          })
        >[
          (
            name: 'enforceMasterRedLines',
            profiles: () => repo.masters.map((m) => m.attributeProfile),
            run: (bounds) => enforceMasterRedLines(
              masters: repo.masters,
              techniqueDefs: repo.techniqueDefs,
              equipmentDefs: repo.equipmentDefs,
              attributeBounds: bounds,
            ),
          ),
          (
            name: 'enforceFounderCreationRedLines',
            profiles: () =>
                repo.founderCreation.fatePool.map((f) => f.attributeProfile),
            run: (bounds) => enforceFounderCreationRedLines(
              strict: true,
              founderCreation: repo.founderCreation,
              techniqueDefs: repo.techniqueDefs,
              equipmentDefs: repo.equipmentDefs,
              attributeBounds: bounds,
            ),
          ),
          (
            name: 'enforceRecruitCandidateRedLines',
            profiles: () =>
                repo.recruitCandidates.values.map((c) => c.attributeProfile),
            run: (bounds) => enforceRecruitCandidateRedLines(
              strict: true,
              recruitCandidates: repo.recruitCandidates,
              techniqueDefs: repo.techniqueDefs,
              equipmentDefs: repo.equipmentDefs,
              attributeBounds: bounds,
            ),
          ),
          (
            name: 'enforceSectCandidateRedLines',
            profiles: () =>
                repo.sectCandidates.values.map((c) => c.attributeProfile),
            run: (bounds) => enforceSectCandidateRedLines(
              strict: true,
              sectCandidates: repo.sectCandidates,
              techniqueDefs: repo.techniqueDefs,
              equipmentDefs: repo.equipmentDefs,
              attributeBounds: bounds,
            ),
          ),
        ];

    for (final c in cases) {
      test('${c.name}:生产区间通过', () {
        expect(c.profiles(), isNotEmpty, reason: '${c.name} 生产 def 为空');
        expect(() => c.run(repo.numbers.attributeBounds), returnsNormally);
      });

      for (final (label, narrow) in [
        ('单项上界压到 max-1', narrowedPoint),
        ('总和下界抬到 min+1', raisedTotalFloor),
      ]) {
        test('${c.name}:$label 后必红且报文带新区间', () {
          final bounds = narrow(c.profiles());
          expect(
            () => c.run(bounds),
            throwsA(
              isA<StateError>().having(
                (e) => e.toString(),
                '报文',
                anyOf(
                  contains('[${bounds.pointMin}, ${bounds.pointMax}]'),
                  contains('[${bounds.totalMin}, ${bounds.totalMax}]'),
                ),
              ),
            ),
            reason: '${c.name} 对收窄区间零反应 = 未读 attributeBounds',
          );
        });
      }
    }
  });
}
