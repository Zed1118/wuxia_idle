import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/defs/skill_def.dart';
import 'package:wuxia_idle/data/game_repository.dart';

import '../support/test_data.dart';

/// 波A A4 · source 来源 tag 红线测族(写约束语义,不锚瞬时数字)。
///
/// production 全量自洽 + broken loader transform 注错验证 fail-fast。
void main() {
  setUpAll(loadTestGameRepository);

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
        expect(
          repo.skillDefs[id]!.source,
          SkillSource.encounter,
          reason: '$id 在奇遇池',
        );
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
          expect(
            repo.skillDefs[sf]!.source,
            SkillSource.fragment,
            reason: '${st.id} 重打残页招 source 应为 fragment(波B 红线 ⑤)',
          );
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
      final drops = repo.skillDefs.values.where(
        (s) =>
            s.source == SkillSource.mainlineDrop ||
            s.source == SkillSource.fragment,
      );
      expect(drops, isNotEmpty, reason: 'production 应有 drop 来源招');
      for (final s in drops) {
        expect(
          s.style,
          isNotNull,
          reason: '${s.id} drop 招缺 style(装配 gate 按流派,缺=永不可装配)',
        );
        expect(
          s.tier,
          isNotNull,
          reason: '${s.id} drop 招缺 tier(canEquipAtRealm 恒 true 破 §5.3)',
        );
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
      final releaseTier = _releaseCapTier(repo);
      // mountDeferred 招豁免挂载完备性(定义在发布阶内但正式挂载点留后续内容)。
      final manualSkills = repo.skillDefs.values
          .where(
            (s) =>
                s.source == SkillSource.mainlineDrop &&
                !s.mountDeferred &&
                s.canEquipAtRealm(releaseTier),
          )
          .map((s) => s.id)
          .toSet();
      final fragmentSkills = repo.skillDefs.values
          .where(
            (s) =>
                s.source == SkillSource.fragment &&
                !s.mountDeferred &&
                s.canEquipAtRealm(releaseTier),
          )
          .map((s) => s.id)
          .toSet();
      // 当前发布范围内集合相等(无孤儿) + 列表长度 == 集合大小(无重复挂载)。
      // 高阶 drop 定义保留给未来副本，不要求在当前内容提前投放。
      expect(
        manualMounts.toSet(),
        manualSkills,
        reason: 'mainlineDrop 招集合应与 stage manual 挂载集合一致',
      );
      expect(manualMounts.length, manualSkills.length, reason: '真解不应被重复挂载');
      expect(
        fragmentMounts.toSet(),
        fragmentSkills,
        reason: 'fragment 招集合应与残页挂载集合(塔+章末重打)一致',
      );
      expect(fragmentMounts.length, fragmentSkills.length, reason: '残页不应被重复挂载');
    });
  });

  group('broken loader transform', () {
    test('剥掉一招的 source → 抛 StateError(红线 ①)', () async {
      String inject(String s) =>
          s.replaceFirst(RegExp(r'    source: technique\n'), '');
      expect(
        GameRepository.loadAllDefs(
          loader: makeLoader('data/skills.yaml', inject),
        ),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('缺 source'),
          ),
        ),
      );
    });

    test('非法 source 值 → 解析期抛(红线枚举)', () async {
      String inject(String s) =>
          s.replaceFirst('    source: technique', '    source: gacha');
      expect(
        GameRepository.loadAllDefs(
          loader: makeLoader('data/skills.yaml', inject),
        ),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('未知 skill source'),
          ),
        ),
      );
    });

    test('旧值 tower_fragment 已退役 → 解析期抛(波B fragment 泛化)', () async {
      String inject(String s) =>
          s.replaceFirst('    source: fragment', '    source: tower_fragment');
      expect(
        GameRepository.loadAllDefs(
          loader: makeLoader('data/skills.yaml', inject),
        ),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('未知 skill source'),
          ),
        ),
      );
    });

    test('drop 招剥掉 style → 抛 StateError(波B 红线 ⑥)', () async {
      // 对一个 mainline_drop 招注掉 style 行(青锋绝)。
      String inject(String s) => s.replaceFirstMapped(
        RegExp(
          r'(  - id: skill_qingshan_qingfeng\n(?:.*\n)*?)    style: \w+\n',
        ),
        (m) => m.group(1)!,
      );
      expect(
        GameRepository.loadAllDefs(
          loader: makeLoader('data/skills.yaml', inject),
        ),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('波B 红线 ⑥'),
          ),
        ),
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
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('波B 红线 ⑦'),
          ),
        ),
      );
    });
  });

  group('mount_deferred 豁免（波B 红线 ⑦ opt-in·里程碑批切片1）', () {
    // 单元:字段解析(缺省 false / 显式 true)。
    test('SkillDef.fromYaml 解析 mount_deferred(缺省 false)', () {
      final base = <String, dynamic>{
        'id': 'test_skill',
        'name': 'n',
        'description': 'd',
        'type': 'powerSkill',
        'powerMultiplier': 100,
        'qiDelta': -10,
        'cooldownTurns': 1,
        'requiresManualTrigger': false,
        'visualEffect': 'none',
      };
      expect(SkillDef.fromYaml(base).mountDeferred, isFalse);
      expect(
        SkillDef.fromYaml({...base, 'mount_deferred': true}).mountDeferred,
        isTrue,
      );
    });

    // 集成:发布上限拉到二流(cap=17·releaseSkillTierCap=3)时,二流 drop 招
    // (千钧坠岳/烛影摇红)本会触发红线⑦孤儿;经 mount_deferred: true 豁免后
    // loadAllDefs 不再抛(正式挂载留 batch3 远征掉落 / Phase C 断魂庄)。
    test('cap=17 下 mount_deferred 招不触发孤儿(loadAllDefs 成功)', () async {
      String bumpCap(String s) => s.replaceFirst(
        'max_absolute_realm_level: 10',
        'max_absolute_realm_level: 17',
      );
      // 不抛即通过(若存在未豁免的二流孤儿招则会抛红线⑦)。
      await GameRepository.loadAllDefs(
        loader: makeLoader('data/numbers.yaml', bumpCap),
      );
    });

    // 集成:豁免按招粒度且确被消费 — 保留千钧坠岳(mainlineDrop)豁免、只抹掉
    // 烛影摇红(fragment)的 mount_deferred。孤儿应只报烛影摇红、不报千钧坠岳:
    // ① 证明烛影摇红的豁免确被消费(抹掉即重新成孤儿);② 证明千钧坠岳的豁免仍
    // 生效(否则 mainlineDrop 检查会先抛出它,孤儿里就会出现千钧坠岳)。
    test('cap=17 下只抹掉 fragment 招 mount_deferred → 只该招触发孤儿(按招豁免)', () async {
      Future<String> loader(String path) async {
        final original = await File(path).readAsString();
        if (path == 'data/numbers.yaml') {
          return original.replaceFirst(
            'max_absolute_realm_level: 10',
            'max_absolute_realm_level: 17',
          );
        }
        if (path == 'data/skills.yaml') {
          // 抹掉烛影摇红块内的 mount_deferred 行(非贪婪定位到本招首个)。
          return original.replaceFirstMapped(
            RegExp(
              r'(  - id: skill_zhu_ying_yao_hong\n(?:.*\n)*?)    mount_deferred: true\n',
            ),
            (m) => m.group(1)!,
          );
        }
        return original;
      }

      await expectLater(
        GameRepository.loadAllDefs(loader: loader),
        throwsA(
          isA<StateError>()
              .having((e) => e.message, 'message', contains('波B 红线 ⑦'))
              .having(
                (e) => e.message,
                'orphan 含被抹的 fragment 招',
                contains('skill_zhu_ying_yao_hong'),
              )
              .having(
                (e) => e.message,
                'orphan 不含仍豁免的 mainline 招',
                isNot(contains('skill_qian_jun_zhui_yue')),
              ),
        ),
      );
    });
  });
}

RealmTier _releaseCapTier(GameRepository repo) {
  final absoluteLevel =
      repo.numbers.progressionReleaseCap.maxAbsoluteRealmLevel;
  return RealmTier.values[(absoluteLevel - 1) ~/ RealmLayer.values.length];
}
