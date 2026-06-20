/// P4 战绩册红线测（Task 12）。
///
/// 约束语义测——守不变量,不写瞬时文件数。
/// 1. §5.4 战绩册纯展示:battle_record feature 目录不引战斗公式层
///    (damage_calculator / derived_stats)。
/// 2. §5.5 离线挂机不产生战绩纪念:seclusion 离线路径源码不引
///    boss_memory 相关模块。
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('§5.4 战绩册纯展示边界', () {
    test('battle_record feature 目录不引伤害公式层 (damage_calculator)', () {
      final dir = Directory('lib/features/battle_record');
      final dartFiles = dir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'));
      for (final f in dartFiles) {
        final src = f.readAsStringSync();
        expect(
          src.contains('damage_calculator'),
          isFalse,
          reason: '${f.path} 不应引伤害公式层 damage_calculator',
        );
      }
    });

    test('battle_record feature 目录不引派生属性层 (derived_stats)', () {
      final dir = Directory('lib/features/battle_record');
      final dartFiles = dir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'));
      for (final f in dartFiles) {
        final src = f.readAsStringSync();
        expect(
          src.contains('derived_stats'),
          isFalse,
          reason: '${f.path} 不应引派生属性层 derived_stats',
        );
      }
    });
  });

  group('§5.5 离线挂机不产生战绩纪念', () {
    // 离线路径 = seclusion application 层的 offline_passive_service +
    // offline_recap_service（战绩由主线/爬塔胜利钩子写，不由离线产出路径写）。

    test('offline_passive_service 不引 boss_memory 任何模块', () {
      final f = File(
        'lib/features/seclusion/application/offline_passive_service.dart',
      );
      final src = f.readAsStringSync();
      expect(
        src.toLowerCase().contains('boss_memory'),
        isFalse,
        reason: 'offline_passive_service 不应引 boss_memory',
      );
    });

    test('offline_recap_service 不引 boss_memory 任何模块', () {
      final f = File(
        'lib/features/seclusion/application/offline_recap_service.dart',
      );
      final src = f.readAsStringSync();
      expect(
        src.toLowerCase().contains('boss_memory'),
        isFalse,
        reason: 'offline_recap_service 不应引 boss_memory',
      );
    });

    test('offline_recap_gate 不引 boss_memory 任何模块', () {
      final f = File(
        'lib/features/seclusion/presentation/offline_recap_gate.dart',
      );
      final src = f.readAsStringSync();
      expect(
        src.toLowerCase().contains('boss_memory'),
        isFalse,
        reason: 'offline_recap_gate 不应引 boss_memory',
      );
    });

    test('seclusion feature 整目录不含 boss_memory 引用', () {
      final dir = Directory('lib/features/seclusion');
      final dartFiles = dir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'));
      for (final f in dartFiles) {
        final src = f.readAsStringSync();
        expect(
          src.toLowerCase().contains('boss_memory'),
          isFalse,
          reason: '${f.path} 不应含 boss_memory — 离线路径不触发战绩写入',
        );
      }
    });
  });
}
