import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/defs/skill_def.dart';
import 'package:wuxia_idle/data/game_repository.dart';

/// 波A A4 · source 来源 tag 红线测族(写约束语义,不锚瞬时数字)。
///
/// production 全量自洽 + broken loader transform 注错验证 fail-fast。
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

  group('production 全量自洽', () {
    test('全招 source 非空 + 池一致性(集合语义)', () {
      final repo = GameRepository.instance;
      for (final s in repo.skillDefs.values) {
        expect(s.source, isNotNull, reason: '${s.id} 缺 source');
      }
      // 奇遇池全 encounter
      for (final id in repo.encounterSkillIds) {
        expect(repo.skillDefs[id]!.source, SkillSource.encounter,
            reason: '$id 在奇遇池');
      }
      // 破招技全 special
      for (final s in repo.skillDefs.values.where((s) => s.canInterrupt)) {
        expect(s.source, SkillSource.special, reason: '${s.id} 是破招技');
      }
      // 真解/残页 drop 指向的招与 source 对齐
      for (final st in repo.stageDefs.values) {
        final m = st.dropSkillManualId;
        if (m != null) {
          expect(repo.skillDefs[m]!.source, SkillSource.mainlineDrop);
        }
      }
      for (final f in repo.towerFloors) {
        final fr = f.dropSkillFragmentId;
        if (fr != null) {
          expect(repo.skillDefs[fr]!.source, SkillSource.towerFragment);
        }
      }
    });
  });

  group('broken loader transform', () {
    test('剥掉一招的 source → 抛 StateError(红线 ①)', () async {
      String inject(String s) => s.replaceFirst(
            RegExp(r'    source: technique\n'),
            '',
          );
      expect(
        GameRepository.loadAllDefs(
          loader: makeLoader('data/skills.yaml', inject),
        ),
        throwsA(isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('缺 source'),
        )),
      );
    });

    test('非法 source 值 → 解析期抛(红线枚举)', () async {
      String inject(String s) => s.replaceFirst(
            '    source: technique',
            '    source: gacha',
          );
      expect(
        GameRepository.loadAllDefs(
          loader: makeLoader('data/skills.yaml', inject),
        ),
        throwsA(isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('未知 skill source'),
        )),
      );
    });
  });
}
