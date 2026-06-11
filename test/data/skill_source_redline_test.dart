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
      // 真解/残页 drop 指向的招与 source 对齐(波B:残页挂载点 = tower floor 或
      // stage 重打,source 统一 fragment)
      for (final st in repo.stageDefs.values) {
        final m = st.dropSkillManualId;
        if (m != null) {
          expect(repo.skillDefs[m]!.source, SkillSource.mainlineDrop);
        }
        final sf = st.dropSkillFragmentId;
        if (sf != null) {
          expect(repo.skillDefs[sf]!.source, SkillSource.fragment,
              reason: '${st.id} 重打残页招 source 应为 fragment(波B 红线 ⑤)');
        }
      }
      for (final f in repo.towerFloors) {
        final fr = f.dropSkillFragmentId;
        if (fr != null) {
          expect(repo.skillDefs[fr]!.source, SkillSource.fragment);
        }
      }
    });

    test('drop 招(mainlineDrop|fragment)必有 style + tier(波B 红线 ⑥)', () {
      final repo = GameRepository.instance;
      final drops = repo.skillDefs.values.where((s) =>
          s.source == SkillSource.mainlineDrop ||
          s.source == SkillSource.fragment);
      expect(drops, isNotEmpty, reason: 'production 应有 drop 来源招');
      for (final s in drops) {
        expect(s.style, isNotNull,
            reason: '${s.id} drop 招缺 style(装配 gate 按流派,缺=永不可装配)');
        expect(s.tier, isNotNull,
            reason: '${s.id} drop 招缺 tier(canEquipAtRealm 恒 true 破 §5.3)');
      }
    });

    test('drop 招挂载完备:每招恰 1 个挂载点,无孤儿无重复(波B 红线 ⑦)', () {
      final repo = GameRepository.instance;
      final manualMounts = <String>[];
      final fragmentMounts = <String>[];
      for (final st in repo.stageDefs.values) {
        if (st.dropSkillManualId != null) {
          manualMounts.add(st.dropSkillManualId!);
        }
        if (st.dropSkillFragmentId != null) {
          fragmentMounts.add(st.dropSkillFragmentId!);
        }
      }
      for (final f in repo.towerFloors) {
        if (f.dropSkillFragmentId != null) {
          fragmentMounts.add(f.dropSkillFragmentId!);
        }
      }
      final manualSkills = repo.skillDefs.values
          .where((s) => s.source == SkillSource.mainlineDrop)
          .map((s) => s.id)
          .toSet();
      final fragmentSkills = repo.skillDefs.values
          .where((s) => s.source == SkillSource.fragment)
          .map((s) => s.id)
          .toSet();
      // 集合相等(无孤儿) + 列表长度 == 集合大小(无重复挂载)
      expect(manualMounts.toSet(), manualSkills,
          reason: 'mainlineDrop 招集合应与 stage manual 挂载集合一致');
      expect(manualMounts.length, manualSkills.length,
          reason: '真解不应被重复挂载');
      expect(fragmentMounts.toSet(), fragmentSkills,
          reason: 'fragment 招集合应与残页挂载集合(塔+章末重打)一致');
      expect(fragmentMounts.length, fragmentSkills.length,
          reason: '残页不应被重复挂载');
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

    test('旧值 tower_fragment 已退役 → 解析期抛(波B fragment 泛化)', () async {
      String inject(String s) => s.replaceFirst(
            '    source: fragment',
            '    source: tower_fragment',
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

    test('drop 招剥掉 style → 抛 StateError(波B 红线 ⑥)', () async {
      // 对一个 mainline_drop 招注掉 style 行(青锋绝)。
      String inject(String s) => s.replaceFirstMapped(
            RegExp(
                r'(  - id: skill_qingshan_qingfeng\n(?:.*\n)*?)    style: \w+\n'),
            (m) => m.group(1)!,
          );
      expect(
        GameRepository.loadAllDefs(
          loader: makeLoader('data/skills.yaml', inject),
        ),
        throwsA(isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('波B 红线 ⑥'),
        )),
      );
    });

    test('真解挂载点移除 → 孤儿真解抛 StateError(波B 红线 ⑦)', () async {
      String inject(String s) => s.replaceFirst(
            RegExp(r'    dropSkillManualId: skill_qingshan_qingfeng.*\n'),
            '',
          );
      expect(
        GameRepository.loadAllDefs(
          loader: makeLoader('data/stages.yaml', inject),
        ),
        throwsA(isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('波B 红线 ⑦'),
        )),
      );
    });
  });
}
