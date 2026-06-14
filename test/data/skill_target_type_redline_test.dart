import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/defs/skill_def.dart';
import 'package:wuxia_idle/data/game_repository.dart';

/// 2026-06-14 拖招交互 · targetType 红线测族(写约束语义,不锚瞬时数字)。
///
/// production 全量自洽 + broken loader 注错验证 fail-fast + fromYaml 默认值。
void main() {
  setUpAll(() async {
    if (!GameRepository.isLoaded) {
      await GameRepository.loadAllDefs(
        loader: (p) => File(p).readAsString(),
      );
    }
  });

  Future<String> Function(String) makeLoader(
    String targetPath,
    String Function(String original) transform,
  ) {
    Future<String> loader(String path) async {
      final original = await File(path).readAsString();
      if (path == targetPath) return transform(original);
      return original;
    }

    return loader;
  }

  group('production targetType 自洽', () {
    test('普攻/合击一律 single(拖招红线 ①)', () {
      final repo = GameRepository.instance;
      final naAndJoint = repo.skillDefs.values.where((s) =>
          s.type == SkillType.normalAttack ||
          s.type == SkillType.jointSkill);
      expect(naAndJoint, isNotEmpty);
      for (final s in naAndJoint) {
        expect(s.targetType, TargetType.single,
            reason: '${s.id}(${s.type.name})普攻/合击不可群体');
      }
    });

    test('aoe 群体技集合非空,且当前设计仅大招配 aoe(拖招红线 ②)', () {
      final repo = GameRepository.instance;
      final aoe =
          repo.skillDefs.values.where((s) => s.targetType == TargetType.aoe);
      expect(aoe, isNotEmpty, reason: 'production 应有群体技(防回填整体丢失)');
      for (final s in aoe) {
        expect(s.type, SkillType.ultimate,
            reason: '${s.id} 当前设计群体技仅大招(普攻/power 单体)');
      }
    });

    test('代表性招目标类型锚设计意图(集合自洽,非全量数字)', () {
      final repo = GameRepository.instance;
      // 万剑诀「漫天剑影」= 群体技代表
      expect(repo.skillDefs['skill_lingqiao_changlian_ult']!.targetType,
          TargetType.aoe);
      // 直拳 = 普攻单体
      expect(repo.skillDefs['skill_gangmeng_jichu_basic']!.targetType,
          TargetType.single);
    });
  });

  group('broken loader / 默认值', () {
    test('普攻注入 targetType: aoe → 抛 StateError(红线 ①)', () async {
      String inject(String s) => s.replaceFirst(
            '    type: normalAttack',
            '    type: normalAttack\n    targetType: aoe',
          );
      expect(
        GameRepository.loadAllDefs(
          loader: makeLoader('data/skills.yaml', inject),
        ),
        throwsA(isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('拖招红线 ①'),
        )),
      );
    });

    test('非法 targetType 值 → 解析期抛(枚举红线)', () async {
      String inject(String s) => s.replaceFirst(
            '    targetType: single',
            '    targetType: cleave',
          );
      expect(
        GameRepository.loadAllDefs(
          loader: makeLoader('data/skills.yaml', inject),
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('未填 targetType 的招 fromYaml 默认 single', () {
      final s = SkillDef.fromYaml({
        'id': 'skill_test_default',
        'name': '测试招',
        'description': '默认值测试',
        'type': 'powerSkill',
        'powerMultiplier': 1000,
        'internalForceCost': 50,
        'cooldownTurns': 3,
        'requiresManualTrigger': false,
        'visualEffect': 'punch_basic',
        'source': 'technique',
      });
      expect(s.targetType, TargetType.single);
    });
  });
}
