import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/numbers_config.dart';
import 'package:wuxia_idle/features/seclusion/application/seclusion_service.dart';
import 'package:wuxia_idle/features/seclusion/domain/retreat_session.dart';

import '../../../support/test_data.dart';

void main() {
  late RetreatConfig production;
  setUpAll(() async {
    production = (await loadTestGameRepository()).numbers.retreat;
  });

  for (final point in [
    (22, 59, false, false),
    (23, 0, true, false),
    (0, 59, true, false),
    (1, 0, false, false),
    (10, 59, false, false),
    (11, 0, false, true),
    (12, 59, false, true),
    (13, 0, false, false),
  ]) {
    test('真实闭关结算边界 ${point.$1}:${point.$2}', () {
      expect(
        _internalForce(
          production,
          point.$1,
          point.$2,
          TechniqueSchool.gangMeng,
        ),
        point.$3 || point.$4 ? 6 : 5,
      );
      expect(
        _internalForce(production, point.$1, point.$2, TechniqueSchool.yinRou),
        point.$3 ? 6 : 5,
      );
    });
  }

  test('修改两个时段配置会移动真实结算加成窗口', () {
    final config = _patchedRetreat((ranges) {
      ranges[0]['time_range'] = ['21:00', '23:00'];
      ranges[1]['time_range'] = ['09:00', '11:00'];
    });
    for (final point in [(21, 30, 6), (23, 0, 5), (9, 30, 6), (11, 0, 5)]) {
      expect(
        _internalForce(config, point.$1, point.$2, TechniqueSchool.gangMeng),
        point.$3,
      );
    }
  });

  test('跨午夜区间保留分钟精度且左闭右开', () {
    final config = _patchedRetreat((ranges) {
      ranges[0]['time_range'] = ['23:15', '01:30'];
    });
    for (final point in [(23, 14, 5), (23, 15, 6), (1, 29, 6), (1, 30, 5)]) {
      expect(
        _internalForce(config, point.$1, point.$2, TechniqueSchool.yinRou),
        point.$3,
      );
    }
  });

  for (var index = 0; index < 3; index++) {
    test('第 $index 个时段缺少 time_range 时加载立即抛错', () {
      expect(
        () => _patchedRetreat((ranges) => ranges[index].remove('time_range')),
        throwsArgumentError,
      );
    });
  }

  for (final value in <Object?>[
    null,
    '23:00-01:00',
    ['23:00'],
    ['23:00', '01:00', '02:00'],
    ['24:00', '01:00'],
    ['23:60', '01:00'],
    ['23:00', '1:00'],
    [23, 1],
  ]) {
    test('拒绝非法 time_range：$value', () {
      expect(
        () => _patchedRetreat((ranges) => ranges[0]['time_range'] = value),
        throwsArgumentError,
      );
    });
  }

  test('其他时段显式 null 合法并保持普通产出', () {
    final config = _patchedRetreat((ranges) => ranges[2]['time_range'] = null);
    expect(_internalForce(config, 15, 0, TechniqueSchool.gangMeng), 5);
  });
}

RetreatConfig _patchedRetreat(void Function(List<Map>) patch) {
  final numbers = loadTestNumbersSection([]);
  final ranges = ((numbers['retreat'] as Map)['time_of_day_bonus'] as List)
      .cast<Map>();
  patch(ranges);
  return NumbersConfig.fromYaml(numbers).retreat;
}

int _internalForce(
  RetreatConfig config,
  int hour,
  int minute,
  TechniqueSchool school,
) {
  final startedAt = DateTime(2026, 9, 19, hour, minute);
  final session = RetreatSession()
    ..mapType = RetreatMapType.shanLin
    ..startedAt = startedAt;
  return SeclusionService.computeOutputs(
    session: session,
    charRealmTier: RealmTier.xueTu,
    config: config,
    maps: config.maps,
    now: startedAt.add(const Duration(hours: 1)),
    charSchool: school,
  ).internalForcePoints;
}
