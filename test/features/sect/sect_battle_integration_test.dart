import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/numbers_config.dart';
import 'package:wuxia_idle/features/sect/application/sect_event_service.dart';
import 'package:wuxia_idle/features/sect/application/sect_providers.dart';
import 'package:wuxia_idle/features/sect/application/sect_reputation_decay.dart';

import 'package:wuxia_idle/core/application/battle_providers.dart';

/// P3.4 Batch 2.3 service provider wire 测族(spec §7 R1.8/R1.9)。
///
/// T19b 重构注:原 SectStateNotifier 内存 state e2e 测(R1.5-R1.7)合并迁
/// sect_event_service_test.dart 的 resolve service 单测 + 新建
/// sect_isar_persistence_test.dart 的 Isar 真持久化 e2e(走 Isar.open + writeTxn)。
///
/// 本文件保留:provider 注入 wire 路径通(R1.8/R1.9)。
void main() {
  final yaml = <String, dynamic>{
    'sect_event': {
      'tournament': {
        'trigger_probability': 0.30,
        'cooldown_days': 30,
        'trigger_realm_min': 'yiLiu',
        'expire_days': 7,
      },
      'reputation': {
        'initial': 50,
        'win_delta': 10,
        'loss_delta': -5,
        'decay_per_month_idle': 5,
        'max': 100,
        'min': 0,
      },
      'sect_level': {
        'max': 7,
        'initial': 1,
        'promote_wins_threshold': 3,
      },
      'active_events_max': 3,
    },
  };

  ProviderContainer makeContainer() {
    final numbers = NumbersConfigStub(yaml);
    final container = ProviderContainer(
      overrides: [
        numbersConfigProvider.overrideWithValue(numbers),
      ],
    );
    return container;
  }

  group('P3.4 Decay service provider wire', () {
    test('R1.8 sectReputationDecayServiceProvider 注入 numbers → 路径通', () {
      final container = makeContainer();
      addTearDown(container.dispose);

      final decay = container.read(sectReputationDecayServiceProvider);
      expect(decay, isA<SectReputationDecayService>());
    });

    test('R1.9 sectEventServiceProvider 注入 numbers → 路径通', () {
      final container = makeContainer();
      addTearDown(container.dispose);

      final svc = container.read(sectEventServiceProvider);
      expect(svc, isA<SectEventService>());
    });
  });
}

class NumbersConfigStub implements NumbersConfig {
  const NumbersConfigStub(this._raw);
  final Map<String, dynamic> _raw;

  @override
  Map<String, dynamic> get raw => _raw;

  @override
  SectEventDef get sectEvent => SectEventDef.fromYaml(
      (_raw['sect_event'] as Map?)?.cast<String, dynamic>());

  @override
  PvpDef get pvp =>
      PvpDef.fromYaml((_raw['pvp'] as Map?)?.cast<String, dynamic>());

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError(
      'NumbersConfigStub: only raw impl, invocation=${invocation.memberName}');
}
