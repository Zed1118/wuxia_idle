import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/defs/realm_def.dart';
import 'package:wuxia_idle/data/defs/skill_def.dart';
import 'package:wuxia_idle/data/defs/stage_def.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/validation/skill_red_lines_validator.dart';

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
      // 断魂庄首通奖励指向的招 = gauntlet(Phase C 转正·红线 ⑤+)
      final gc = repo.bossGauntletConfig;
      if (gc != null && gc.firstClearRewardSkillId.isNotEmpty) {
        expect(
          repo.skillDefs[gc.firstClearRewardSkillId]!.source,
          SkillSource.gauntlet,
          reason: '断魂庄首通奖励 ${gc.firstClearRewardSkillId} source 应为 gauntlet',
        );
      }
    });

    test('drop 招(mainlineDrop|fragment|gauntlet)必有 style + tier(波B 红线 ⑥)', () {
      final repo = GameRepository.instance;
      final drops = repo.skillDefs.values.where(
        (s) =>
            s.source == SkillSource.mainlineDrop ||
            s.source == SkillSource.fragment ||
            s.source == SkillSource.gauntlet,
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
      // gauntlet(断魂庄首通奖励):挂载集合 == 应挂载招集合,无孤儿无重复(红线⑦ gauntlet 分支)。
      final gauntletMounts = <String>[
        if (repo.bossGauntletConfig != null &&
            repo.bossGauntletConfig!.firstClearRewardSkillId.isNotEmpty)
          repo.bossGauntletConfig!.firstClearRewardSkillId,
      ];
      final gauntletSkills = repo.skillDefs.values
          .where(
            (s) =>
                s.source == SkillSource.gauntlet &&
                !s.mountDeferred &&
                s.canEquipAtRealm(releaseTier),
          )
          .map((s) => s.id)
          .toSet();
      expect(
        gauntletMounts.toSet(),
        gauntletSkills,
        reason: 'gauntlet 招集合应与断魂庄首通奖励挂载集合一致',
      );
      expect(
        gauntletMounts.length,
        gauntletSkills.length,
        reason: '断魂庄首通奖励招不应被重复挂载',
      );
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

    test('断魂庄首通奖励指向非 gauntlet 招 → 抛 StateError(断魂庄红线 ⑤+ 错挂)', () async {
      String inject(String s) => s.replaceFirst(
        'first_clear_reward_skill_id: skill_suo_mai_zhen',
        'first_clear_reward_skill_id: skill_qingshan_qingfeng',
      );
      expect(
        GameRepository.loadAllDefs(
          loader: makeLoader('data/boss_gauntlets.yaml', inject),
        ),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('应为 gauntlet'),
          ),
        ),
      );
    });

    test(
      '断魂庄首通招被标 mount_deferred → 挂载点错挂抛 StateError(红线⑦ gauntlet 分支)',
      () async {
        String inject(String s) => s.replaceFirstMapped(
          RegExp(
            r'(  - id: skill_suo_mai_zhen\n(?:.*\n)*?    tier: \d+[^\n]*\n)',
          ),
          (m) => '${m.group(1)!}    mount_deferred: true\n',
        );
        expect(
          GameRepository.loadAllDefs(
            loader: makeLoader('data/skills.yaml', inject),
          ),
          throwsA(
            isA<StateError>()
                .having((e) => e.message, 'message', contains('波B 红线 ⑦'))
                .having(
                  (e) => e.message,
                  '错挂含被豁免的 gauntlet 招',
                  contains('skill_suo_mai_zhen'),
                ),
          ),
        );
      },
    );
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

    // 集成:发布上限拉到二流(cap=17·releaseSkillTierCap=3)时,发布阶内 drop 招
    // 须全部有挂载或经 mount_deferred: true 豁免,否则红线⑦孤儿 fail-fast。
    // (千钧坠岳/烛影摇红 Ch7 已正式挂载;锁脉针 2026-07-19 转正 gauntlet 挂载。)
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

    // 集成:mount_deferred 豁免按招粒度且确被消费 — 给已挂载真解(青锋绝)注入
    // mount_deferred → 该招退出「应挂载招集合」,其 stage 挂载点变 dangling 错挂,
    // 红线⑦ 抛错,反向证明豁免字段确被逐招消费。
    // (2026-07-19 来源语义转正:断魂庄锁脉针已删 mount_deferred 正式挂载为
    // gauntlet 首通奖励;当前 production 无 deferred 招,机制保留待后续内容。)
    test('给已挂载真解注入 mount_deferred → 挂载点错挂抛 StateError(豁免按招消费)', () async {
      Future<String> loader(String path) async {
        final original = await File(path).readAsString();
        if (path == 'data/skills.yaml') {
          return original.replaceFirstMapped(
            RegExp(
              r'(  - id: skill_qingshan_qingfeng\n(?:.*\n)*?    tier: \d+[^\n]*\n)',
            ),
            (m) => '${m.group(1)!}    mount_deferred: true\n',
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
                '错挂含被豁免招',
                contains('skill_qingshan_qingfeng'),
              ),
        ),
      );
    });
  });

  group('断魂庄 gauntlet 红线⑦(直接单测·合成 defs)', () {
    // releaseRealm = 三流(tier cap 2),与 production 当前发布上限同阶。
    final releaseRealm = RealmDef(
      tier: RealmTier.sanLiu,
      layer: RealmLayer.qiMeng,
      absoluteLevel: 8,
      internalForceMax: 1000,
      experienceToNext: 100,
      equipmentTierCap: EquipmentTier.values[1],
      techniqueTierCap: TechniqueTier.values[1],
    );

    SkillDef gauntletSkill(String id, {bool deferred = false}) => SkillDef(
      id: id,
      name: id,
      description: 'd',
      type: SkillType.powerSkill,
      powerMultiplier: 100,
      qiDelta: -10,
      cooldownTurns: 1,
      requiresManualTrigger: false,
      visualEffect: 'none',
      style: TechniqueSchool.yinRou,
      tier: 2,
      source: SkillSource.gauntlet,
      mountDeferred: deferred,
    );

    // stageDefs 非空以进入红线⑦ 块(无 drop 挂载,纯占位)。
    const stage = StageDef(
      id: 's1',
      name: '测试关',
      stageType: StageType.mainline,
      requiredRealm: RealmTier.xueTu,
      enemyTeam: [],
      isBossStage: false,
      baseExpReward: 0,
      difficultyMultiplier: 1.0,
    );

    void run({
      required Map<String, SkillDef> skills,
      List<String> gauntletIds = const [],
    }) => enforceSkillSourceRedLines(
      skillDefs: skills,
      stageDefs: {'s1': stage},
      towerFloors: const [],
      encounterSkillIds: const {},
      releaseRealm: releaseRealm,
      gauntletRewardSkillIds: gauntletIds,
    );

    test('挂载齐全(招在 + 首通奖励引用在)→ 不抛', () {
      expect(
        () => run(skills: {'g1': gauntletSkill('g1')}, gauntletIds: ['g1']),
        returnsNormally,
      );
    });

    test('挂载引用缺失(招在、首通奖励空)→ 红线⑦ 孤儿错', () {
      expect(
        () => run(skills: {'g1': gauntletSkill('g1')}),
        throwsA(
          isA<StateError>()
              .having((e) => e.message, 'message', contains('波B 红线 ⑦'))
              .having((e) => e.message, '孤儿含未挂载招', contains('g1')),
        ),
      );
    });

    test('同一招被两个挂载点引用 → 红线⑦ 重复挂载错', () {
      expect(
        () =>
            run(skills: {'g1': gauntletSkill('g1')}, gauntletIds: ['g1', 'g1']),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('重复挂载'),
          ),
        ),
      );
    });

    test('挂载指向非 gauntlet 来源招 → 红线⑤+ 错挂(先与⑦)', () {
      const other = SkillDef(
        id: 't1',
        name: 't1',
        description: 'd',
        type: SkillType.powerSkill,
        powerMultiplier: 100,
        qiDelta: -10,
        cooldownTurns: 1,
        requiresManualTrigger: false,
        visualEffect: 'none',
        source: SkillSource.technique,
      );
      expect(
        () => run(skills: {'t1': other}, gauntletIds: ['t1']),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('应为 gauntlet'),
          ),
        ),
      );
    });

    test('mountDeferred 豁免机制保留:deferred gauntlet 招无挂载 → 不抛', () {
      expect(
        () => run(skills: {'g1': gauntletSkill('g1', deferred: true)}),
        returnsNormally,
      );
    });

    test('deferred 招仍被挂载 → 红线⑦ 错挂(dangling)', () {
      expect(
        () => run(
          skills: {'g1': gauntletSkill('g1', deferred: true)},
          gauntletIds: ['g1'],
        ),
        throwsA(
          isA<StateError>()
              .having((e) => e.message, 'message', contains('波B 红线 ⑦'))
              .having((e) => e.message, '错挂含豁免招', contains('g1')),
        ),
      );
    });

    test('gauntlet 招缺 style/tier → 红线⑥', () {
      const noStyle = SkillDef(
        id: 'g2',
        name: 'g2',
        description: 'd',
        type: SkillType.powerSkill,
        powerMultiplier: 100,
        qiDelta: -10,
        cooldownTurns: 1,
        requiresManualTrigger: false,
        visualEffect: 'none',
        tier: 2,
        source: SkillSource.gauntlet,
      );
      expect(
        () => run(skills: {'g2': noStyle}, gauntletIds: ['g2']),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('波B 红线 ⑥'),
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
