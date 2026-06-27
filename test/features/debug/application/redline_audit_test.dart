import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/debug/application/redline_audit.dart';

Future<String> _fileLoader(String path) async => File(path).readAsString();

void main() {
  tearDown(GameRepository.resetForTest);

  group('classifyRedline', () {
    test('PASS/WARN/FAIL 状态计算', () {
      expect(
        classifyRedline(observed: 80, limit: 100),
        RedlineAuditStatus.pass,
      );
      expect(
        classifyRedline(observed: 90, limit: 100),
        RedlineAuditStatus.warn,
      );
      expect(
        classifyRedline(observed: 101, limit: 100),
        RedlineAuditStatus.fail,
      );
    });
  });

  group('buildRedlineAuditReport', () {
    setUp(() async {
      await GameRepository.loadAllDefs(loader: _fileLoader);
    });

    test('覆盖 §5.4 关键红线项目', () {
      final report = buildRedlineAuditReport(GameRepository.instance);
      expect(
        report.items.map((i) => i.id),
        containsAll(<String>[
          'equipment_base_attack',
          'player_hp',
          'boss_hp',
          'internal_force',
          'skill_power_multiplier',
          'normal_damage',
          'ultimate_critical',
        ]),
      );
    });

    test('production 当前报告无 FAIL 且输出来源', () {
      final report = buildRedlineAuditReport(GameRepository.instance);
      expect(report.hasFail, isFalse);
      for (final item in report.items) {
        expect(item.source, isNot('-'), reason: '${item.id} 必须标注来源');
        expect(item.observed, greaterThan(0), reason: '${item.id} 必须真扫描');
      }

      final markdown = report.toMarkdown();
      expect(markdown, contains('数值红线审计报告'));
      expect(markdown, contains('装备基础攻击'));
      expect(markdown, contains('大招暴击'));
    });

    test('ultimate_critical 探针走 SkillType.ultimate（防误取 powerSkill）', () {
      final repo = GameRepository.instance;
      final report = buildRedlineAuditReport(repo);
      final item = report.items.firstWhere((i) => i.id == 'ultimate_critical');
      // source 格式 'damage_probe:<skillId>'，解析出的招式必须是大招类型。
      // 误取 powerSkill 会低估大招峰值，使审计自称的「大招暴击」名不副实。
      final skillId = item.source.split(':').last;
      expect(
        repo.skillDefs[skillId]?.type,
        SkillType.ultimate,
        reason: '大招暴击探针必须取 SkillType.ultimate 招式，不能取 powerSkill',
      );
    });
  });
}
