import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/services/drop_service.dart';
import 'package:wuxia_idle/utils/rng.dart';

/// GameRepository + yaml 加载器 + NumbersConfig 集成测试。
///
/// 用真实的 `data/*.yaml` 占位 fixture（pubspec 已声明 data/ 是 asset 根，
/// 这里直接通过文件 IO 加载——`flutter test` 的 cwd 是项目根，所以相对
/// 路径 `data/xxx.yaml` 可读）。注入式 loader 避免依赖 rootBundle。
void main() {
  Future<String> fileLoader(String path) async {
    final f = File(path);
    if (!await f.exists()) throw FileSystemException('不存在', path);
    return f.readAsString();
  }

  tearDown(GameRepository.resetForTest);

  group('GameRepository.loadAllDefs（占位 fixture）', () {
    test('加载完整 → counts 与 phase1_tasks T07.7.3 一致', () async {
      final repo = await GameRepository.loadAllDefs(loader: fileLoader);

      expect(repo.realms.length, 49, reason: '49 级境界');
      expect(repo.equipmentDefs.length, 35,
          reason: '35 件装备（Phase 3 Week 7 T63 扩 7 阶 × 5 件）');
      expect(repo.techniqueDefs.length, 21,
          reason: '21 本心法（Phase 3 Week 8 T64 扩 7 阶 × 3 流派）');
      // W14-3-A:skills.yaml 63 招(21 心法 × 3 招) + encounter_skills.yaml
      // 35 招(7 阶 × 5)合并到同一 Map = 98。
      expect(repo.skillDefs.length, 98,
          reason: '63 心法招(skills.yaml) + 35 奇遇招(encounter_skills.yaml)');
      expect(repo.encounterSkillIds.length, 35,
          reason: 'encounter_skills.yaml 35 招(7 阶 × 5)');
      expect(repo.stageDefs.length, 15, reason: '主线 15 关（Phase 3 Week 5 T59 扩容）');
      expect(repo.numbers.version, isNotEmpty);
    });

    test('GameRepository.instance 在 load 后可访问', () async {
      await GameRepository.loadAllDefs(loader: fileLoader);
      expect(GameRepository.isLoaded, isTrue);
      expect(identical(GameRepository.instance, GameRepository.instance),
          isTrue);
    });

    test('NumbersConfig 强类型字段（damage_formula / max_hp_formula / 防御率）', () async {
      final repo = await GameRepository.loadAllDefs(loader: fileLoader);
      expect(repo.numbers.combat.damageFormula.equipmentAttackFactor, 1.0);
      expect(repo.numbers.combat.damageFormula.internalForceFactor, 0.4);
      expect(repo.numbers.combat.maxHpFormula.internalForceFactor, 0.7);
      expect(repo.numbers.combat.maxHpFormula.constitutionFactor, 500);
      expect(repo.numbers.defenseRateByTier[RealmTier.xueTu], 0.05);
      expect(repo.numbers.defenseRateByTier[RealmTier.wuSheng], 0.35);
      // Phase 4 W10 战败代价（与 dispersion 同 0.50 但字段独立）
      expect(repo.numbers.defeatBossInternalForcePenalty, 0.50);
      expect(repo.numbers.defeatBossCultivationPenalty, 0.50);
    });

    test('LevelDiffModifier.diff3OrMore.attacker null 兜底为 1.0', () async {
      final repo = await GameRepository.loadAllDefs(loader: fileLoader);
      final m = repo.numbers.levelDiffModifier;
      expect(m.sameTier.attacker, 1.0);
      expect(m.diff1.attacker, 1.4);
      expect(m.diff2.attacker, 2.5);
      expect(m.diff3OrMore.defender, 0.05);
      expect(m.diff3OrMore.attacker, 1.0,
          reason: 'yaml attacker=null → 数据层兜底 1.0（GDD §5.5 已碾压无须放大）');
    });

    test('便捷查询 getRealmByAbsoluteLevel / getRealm', () async {
      final repo = await GameRepository.loadAllDefs(loader: fileLoader);
      final r = repo.getRealmByAbsoluteLevel(28);
      expect(r.tier, RealmTier.yiLiu);
      expect(r.layer, RealmLayer.dengFeng);
      expect(r.equipmentTierCap, EquipmentTier.liQi);
      expect(r.techniqueTierCap, TechniqueTier.menPaiJueXue);

      final r1 = repo.getRealm(RealmTier.xueTu, RealmLayer.qiMeng);
      expect(r1.absoluteLevel, 1);
      expect(r1.internalForceMax, 500);

      final r49 = repo.getRealmByAbsoluteLevel(49);
      expect(r49.internalForceMax, 15000);
      expect(r49.equipmentTierCap, EquipmentTier.shenWu);
    });

    test('getRealmByAbsoluteLevel 越界抛 RangeError', () async {
      final repo = await GameRepository.loadAllDefs(loader: fileLoader);
      expect(() => repo.getRealmByAbsoluteLevel(0), throwsRangeError);
      expect(() => repo.getRealmByAbsoluteLevel(50), throwsRangeError);
    });

    test('getEquipment / getTechnique / getSkill / getStage 按 id 命中', () async {
      final repo = await GameRepository.loadAllDefs(loader: fileLoader);
      expect(
        repo.getEquipment('weapon_haojiahuo_qing_feng_jian').name,
        '青锋剑',
      );
      expect(
        repo.getTechnique('tech_gangmeng_mingjia').school,
        TechniqueSchool.gangMeng,
      );
      expect(
        repo.getSkill('skill_lingqiao_jichu_basic').type,
        SkillType.normalAttack,
      );
      expect(
        repo.getStage('stage_03_02').enemyTeam.length,
        3,
      );
    });

    test('T27 dropTable 解析 → stage_01_02 / 03_05 dropTable 非空，'
        '其他未配关卡 dropTable 为空（向后兼容）', () async {
      final repo = await GameRepository.loadAllDefs(loader: fileLoader);
      final s2 = repo.getStage('stage_01_02');
      expect(s2.dropTable.length, 1,
          reason: '荒山野店：必掉磨剑石');
      final sFinal = repo.getStage('stage_03_05');
      expect(sFinal.dropTable.length, 3,
          reason: '章末大 Boss：龙泉剑 + 60% 玉佩 + 必掉心血结晶');
      // W13-v3:stage_01_01 加 onboarding dropTable(必掉护甲 + 1 磨剑石)
      final s1 = repo.getStage('stage_01_01');
      expect(s1.dropTable.length, 2,
          reason: '新手第一关 onboarding：100% 寻常布衣 + 100% 1 磨剑石');
    });

    test('W13-v3 #10 兜底：DropService.rollDrops(stage_01_01) 100% 掉护甲 + 磨剑石',
        () async {
      // Codex v4 视觉验收 #10 未取得硬截图(GUI/RDP 操作问题),用 service 层
      // 直接验证 dropTable 配置在 DropService 路径上真生效,作为视觉缺失的代码层兜底。
      final repo = await GameRepository.loadAllDefs(loader: fileLoader);
      final stage = repo.getStage('stage_01_01');
      final svc = DropService(equipmentDefLookup: repo.getEquipment);

      // 跑 5 次,因 dropChance=1.0 每次都应该 1 装备 + 1 物料,验证非概率 flake
      for (var i = 0; i < 5; i++) {
        final result = svc.rollDrops(stage, DefaultRng(seed: i));
        expect(result.equipments.length, 1,
            reason: 'iter $i:armor_xunchang_bu_yi 100% 必掉');
        expect(result.equipments.first.defId, 'armor_xunchang_bu_yi');
        expect(result.items.length, 1,
            reason: 'iter $i:item_mojianshi 100% 必掉');
        expect(result.items.first.defId, 'item_mojianshi');
        expect(result.items.first.quantity, 1,
            reason: 'iter $i:quantity [1,1] 永远 1');
      }
    });

    test('Phase 3 Week 5 主线 15 关红线：3 章 × 5 关 + 4/5 关 isBossStage', () async {
      final repo = await GameRepository.loadAllDefs(loader: fileLoader);
      final mainlines = repo.stageDefs.values
          .where((s) => s.stageType == StageType.mainline)
          .toList();
      expect(mainlines.length, 15);
      for (final ch in [1, 2, 3]) {
        final inCh = mainlines.where((s) => s.chapterIndex == ch).toList();
        expect(inCh.length, 5, reason: 'Ch$ch 应有 5 关');
      }
      // 章末两关 4/5 是 Boss + 配 narrativeDefeatId；1/2/3 关非 Boss + 无 defeat
      for (final ch in [1, 2, 3]) {
        for (final idx in [1, 2, 3, 4, 5]) {
          final id = 'stage_0${ch}_0$idx';
          final s = repo.getStage(id);
          if (idx >= 4) {
            expect(s.isBossStage, isTrue, reason: '$id 应为 Boss 关');
            expect(s.narrativeDefeatId, isNotNull,
                reason: '$id 应配 narrativeDefeatId');
          } else {
            expect(s.isBossStage, isFalse, reason: '$id 非 Boss 关');
            expect(s.narrativeDefeatId, isNull,
                reason: '$id 不应配 narrativeDefeatId');
          }
        }
      }
    });

    test('未配置的 id → 抛 StateError', () async {
      final repo = await GameRepository.loadAllDefs(loader: fileLoader);
      expect(() => repo.getEquipment('not_exist'), throwsStateError);
      expect(() => repo.getTechnique('not_exist'), throwsStateError);
      expect(() => repo.getSkill('not_exist'), throwsStateError);
      expect(() => repo.getStage('not_exist'), throwsStateError);
    });

    test('占位 fixture 红线均通过（武器 baseAttackMax ≤ 2000、内力 ∈ [500,15000]）',
        () async {
      final repo = await GameRepository.loadAllDefs(loader: fileLoader);
      for (final e in repo.equipmentDefs.values) {
        expect(e.baseAttackMax, lessThanOrEqualTo(2000));
        expect(e.baseAttackMin, lessThanOrEqualTo(e.baseAttackMax));
      }
      for (final r in repo.realms) {
        expect(r.internalForceMax, inInclusiveRange(500, 15000));
      }
    });
  });

  group('红线 fail-fast', () {
    test('装备 baseAttackMax > 2000 → 启动失败抛 StateError', () async {
      Future<String> brokenLoader(String path) async {
        if (path.endsWith('equipment.yaml')) {
          return '''
equipment:
  - id: weapon_evil
    name: 越界武器
    tier: shenWu
    slot: weapon
    baseAttackMin: 100
    baseAttackMax: 9999
    baseHealthMin: 0
    baseHealthMax: 0
    baseSpeedMin: 0
    baseSpeedMax: 10
    presetLoreIds: []
    dropSourceTags: []
    iconPath: x.png
''';
        }
        return fileLoader(path);
      }

      expect(
        GameRepository.loadAllDefs(loader: brokenLoader),
        throwsA(isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('baseAttackMax'),
        )),
      );
    });

    test('T63 装备覆盖度：某阶 < 5 件 → 抛 StateError', () async {
      Future<String> brokenLoader(String path) async {
        if (path.endsWith('equipment.yaml')) {
          return '''
equipment:
  - id: weapon_lone
    name: 孤剑
    tier: xunChang
    slot: weapon
    schoolBias: lingQiao
    baseAttackMin: 100
    baseAttackMax: 150
    baseHealthMin: 0
    baseHealthMax: 0
    baseSpeedMin: 0
    baseSpeedMax: 10
    presetLoreIds: []
    dropSourceTags: []
    iconPath: x.png
''';
        }
        return fileLoader(path);
      }

      expect(
        GameRepository.loadAllDefs(loader: brokenLoader),
        throwsA(isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('覆盖度不足'),
        )),
      );
    });

    test('T64 心法覆盖度：缺 (tier,school) 组合 → 抛 StateError', () async {
      // techniques.yaml 只塞 1 本 → 7×3=21 组合缺一堆,覆盖度先抛
      Future<String> brokenLoader(String path) async {
        if (path.endsWith('techniques.yaml')) {
          return '''
techniques:
  - id: tech_solo
    name: 孤本
    tier: ruMenGong
    school: gangMeng
    description: TODO
    skillIds: []
    internalForceGrowthBonus: 1.0
    speedBonus: 0
    acquireSourceTags: []
''';
        }
        return fileLoader(path);
      }

      expect(
        GameRepository.loadAllDefs(loader: brokenLoader),
        throwsA(isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('心法覆盖度不足'),
        )),
      );
    });

    test('T64 心法每本 3 招 type 分布:ult 被改成 normalAttack → 抛 StateError',
        () async {
      // 真实 techniques.yaml 全 21 本通过覆盖度 → 走每本校验
      // skills.yaml 把 jichu gangMeng ult 的 type 改成 normalAttack → 该本 types 分布错
      Future<String> brokenLoader(String path) async {
        if (path.endsWith('skills.yaml')) {
          final original = await fileLoader(path);
          // skill_gangmeng_jichu_ult 的 type: ultimate → normalAttack
          return original.replaceFirst(
            '''
  - id: skill_gangmeng_jichu_ult
    name: 怒涛拳
    description: TODO_NARRATIVE
    type: ultimate''',
            '''
  - id: skill_gangmeng_jichu_ult
    name: 怒涛拳
    description: TODO_NARRATIVE
    type: normalAttack''',
          );
        }
        return fileLoader(path);
      }

      expect(
        GameRepository.loadAllDefs(loader: brokenLoader),
        throwsA(isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('应精确为'),
        )),
      );
    });

    test('T63 装备覆盖度：某阶 weapon 流派缺失 → 抛 StateError', () async {
      // 5 件 xunChang 满足数量 + armor + accessory,但 weapon 全 lingQiao,
      // 缺 gangMeng/yinRou 流派武器
      Future<String> brokenLoader(String path) async {
        if (path.endsWith('equipment.yaml')) {
          return '''
equipment:
  - id: weapon_a
    name: 剑甲
    tier: xunChang
    slot: weapon
    schoolBias: lingQiao
    baseAttackMin: 100
    baseAttackMax: 150
    baseHealthMin: 0
    baseHealthMax: 0
    baseSpeedMin: 0
    baseSpeedMax: 10
    presetLoreIds: []
    dropSourceTags: []
    iconPath: x.png
  - id: weapon_b
    name: 剑乙
    tier: xunChang
    slot: weapon
    schoolBias: lingQiao
    baseAttackMin: 100
    baseAttackMax: 150
    baseHealthMin: 0
    baseHealthMax: 0
    baseSpeedMin: 0
    baseSpeedMax: 10
    presetLoreIds: []
    dropSourceTags: []
    iconPath: x.png
  - id: armor_a
    name: 甲
    tier: xunChang
    slot: armor
    baseAttackMin: 0
    baseAttackMax: 0
    baseHealthMin: 100
    baseHealthMax: 200
    baseSpeedMin: 0
    baseSpeedMax: 5
    presetLoreIds: []
    dropSourceTags: []
    iconPath: x.png
  - id: accessory_a
    name: 佩甲
    tier: xunChang
    slot: accessory
    baseAttackMin: 20
    baseAttackMax: 40
    baseHealthMin: 50
    baseHealthMax: 100
    baseSpeedMin: 0
    baseSpeedMax: 8
    presetLoreIds: []
    dropSourceTags: []
    iconPath: x.png
  - id: accessory_b
    name: 佩乙
    tier: xunChang
    slot: accessory
    baseAttackMin: 20
    baseAttackMax: 40
    baseHealthMin: 50
    baseHealthMax: 100
    baseSpeedMin: 0
    baseSpeedMax: 8
    presetLoreIds: []
    dropSourceTags: []
    iconPath: x.png
''';
        }
        return fileLoader(path);
      }

      expect(
        GameRepository.loadAllDefs(loader: brokenLoader),
        throwsA(isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('流派武器'),
        )),
      );
    });

    test('yaml 故意写错语法 → 抛异常（fail fast，不静默兜底）', () async {
      Future<String> brokenLoader(String path) async {
        if (path.endsWith('skills.yaml')) {
          return '{ this is : not valid yaml: oops:::';
        }
        return fileLoader(path);
      }

      expect(
        GameRepository.loadAllDefs(loader: brokenLoader),
        throwsA(anything),
      );
    });

    test('id 重复 → 抛 StateError', () async {
      Future<String> dupeLoader(String path) async {
        if (path.endsWith('techniques.yaml')) {
          return '''
techniques:
  - id: tech_dup
    name: 重复 1
    tier: ruMenGong
    school: gangMeng
    description: TODO
    skillIds: []
    internalForceGrowthBonus: 1.0
    speedBonus: 0
    acquireSourceTags: []
  - id: tech_dup
    name: 重复 2
    tier: ruMenGong
    school: lingQiao
    description: TODO
    skillIds: []
    internalForceGrowthBonus: 1.0
    speedBonus: 0
    acquireSourceTags: []
''';
        }
        return fileLoader(path);
      }

      expect(
        GameRepository.loadAllDefs(loader: dupeLoader),
        throwsA(isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('重复 def id'),
        )),
      );
    });
  });

  group('Phase 3 T33 · stage 链路校验', () {
    test('6 关 fixture 全部带正确的 prev 链 + opening/victory id', () async {
      final repo = await GameRepository.loadAllDefs(loader: fileLoader);

      // Ch1
      final s1 = repo.getStage('stage_01_01');
      final s2 = repo.getStage('stage_01_02');
      expect(s1.prevStageId, isNull, reason: 'Ch1 首关');
      expect(s1.narrativeOpeningId, 'stage_01_01_opening');
      expect(s1.narrativeVictoryId, 'stage_01_01_victory');
      expect(s2.prevStageId, 'stage_01_01');
      expect(s2.chapterIndex, 1);

      // Ch2
      final s3 = repo.getStage('stage_02_01');
      final s4 = repo.getStage('stage_02_02');
      expect(s3.prevStageId, isNull);
      expect(s4.prevStageId, 'stage_02_01');
      expect(s4.chapterIndex, 2);

      // Ch3
      final s5 = repo.getStage('stage_03_01');
      final s6 = repo.getStage('stage_03_02');
      expect(s5.prevStageId, isNull);
      expect(s6.prevStageId, 'stage_03_01');
      expect(s6.chapterIndex, 3);
    });

    test('prevStageId 引用不存在的 stage → 启动失败抛 StateError', () async {
      Future<String> brokenLoader(String path) async {
        if (path.endsWith('stages.yaml')) {
          return '''
stages:
  - id: orphan_stage
    name: 孤儿关
    stageType: mainline
    chapterIndex: 1
    prevStageId: ghost_stage_does_not_exist
    requiredRealm: xueTu
    enemyTeam: []
    isBossStage: false
    dropEquipmentDefIds: []
    dropItemDefIds: []
    baseExpReward: 0
    difficultyMultiplier: 1.0
''';
        }
        return fileLoader(path);
      }

      expect(
        GameRepository.loadAllDefs(loader: brokenLoader),
        throwsA(isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('引用不存在的关卡'),
        )),
      );
    });

    test('prevStageId 跨章引用 → 启动失败抛 StateError', () async {
      Future<String> brokenLoader(String path) async {
        if (path.endsWith('stages.yaml')) {
          return '''
stages:
  - id: ch1_stage
    name: 第一章关
    stageType: mainline
    chapterIndex: 1
    requiredRealm: xueTu
    enemyTeam: []
    isBossStage: false
    dropEquipmentDefIds: []
    dropItemDefIds: []
    baseExpReward: 0
    difficultyMultiplier: 1.0
  - id: ch2_stage_wrong_prev
    name: 第二章关错引第一章
    stageType: mainline
    chapterIndex: 2
    prevStageId: ch1_stage
    requiredRealm: sanLiu
    enemyTeam: []
    isBossStage: false
    dropEquipmentDefIds: []
    dropItemDefIds: []
    baseExpReward: 0
    difficultyMultiplier: 1.0
''';
        }
        return fileLoader(path);
      }

      expect(
        GameRepository.loadAllDefs(loader: brokenLoader),
        throwsA(isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('跨章引用'),
        )),
      );
    });
  });

  group('改 numbers 反映 (T07 验收 #2)', () {
    test('替换 numbers.yaml equipment_attack_factor=2.0 → 立刻生效', () async {
      Future<String> patchedLoader(String path) async {
        if (path.endsWith('numbers.yaml')) {
          final original = await fileLoader(path);
          // 把平衡值 1.0 临时改成 2.0，确认 NumbersConfig 反映该改动
          return original.replaceFirst(
            'equipment_attack_factor: 1.0',
            'equipment_attack_factor: 2.0',
          );
        }
        return fileLoader(path);
      }

      final repo = await GameRepository.loadAllDefs(loader: patchedLoader);
      expect(repo.numbers.combat.damageFormula.equipmentAttackFactor, 2.0);
    });
  });

  group('未初始化访问保护', () {
    test('未调用 loadAllDefs 直接访问 instance → 抛 StateError', () {
      // tearDown 已 reset，此 test 内不调 load
      expect(GameRepository.isLoaded, isFalse);
      expect(() => GameRepository.instance, throwsStateError);
    });
  });

  group('Phase 3 Week 4 T53 · 师徒红线校验', () {
    // 用 brokenLoader 注入 data/masters.yaml 文本；其余文件走真实 fileLoader。
    Future<String> Function(String) mastersLoader(String yaml) {
      return (String path) async {
        if (path.endsWith('masters.yaml')) return yaml;
        return fileLoader(path);
      };
    }

    test('占位 fixture 3 角色加载 + getMasterBySlot / getFounderMaster', () async {
      final repo = await GameRepository.loadAllDefs(loader: fileLoader);
      expect(repo.masters.length, 3);
      expect(repo.masters[0].lineageRole, LineageRole.founder);
      expect(repo.masters[1].lineageRole, LineageRole.disciple);
      expect(repo.masters[2].lineageRole, LineageRole.disciple);
      expect(repo.getMasterBySlot(0).id, 'founder');
      expect(repo.getMasterBySlot(2).id, 'second_disciple');
      expect(repo.getFounderMaster().id, 'founder');
      expect(() => repo.getMasterBySlot(3), throwsRangeError);
    });

    test('slotIndex 重复 → 抛 StateError', () async {
      const broken = '''
masters:
  - id: founder
    lineageRole: founder
    slotIndex: 0
    defaultRealm: yiLiu
    defaultLayer: qiMeng
    attributeProfile: {constitution: 5, enlightenment: 5, agility: 5, fortune: 5}
  - id: dup_slot
    lineageRole: disciple
    slotIndex: 0
    defaultRealm: erLiu
    defaultLayer: qiMeng
    attributeProfile: {constitution: 5, enlightenment: 5, agility: 5, fortune: 5}
  - id: second_disciple
    lineageRole: disciple
    slotIndex: 2
    defaultRealm: sanLiu
    defaultLayer: qiMeng
    attributeProfile: {constitution: 5, enlightenment: 5, agility: 5, fortune: 5}
''';

      expect(
        GameRepository.loadAllDefs(loader: mastersLoader(broken)),
        throwsA(isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('slotIndex'),
        )),
      );
    });

    test('slot=0 不是 founder → 抛 StateError', () async {
      const broken = '''
masters:
  - id: wrong_founder
    lineageRole: disciple
    slotIndex: 0
    defaultRealm: yiLiu
    defaultLayer: qiMeng
    attributeProfile: {constitution: 5, enlightenment: 5, agility: 5, fortune: 5}
  - id: first_disciple
    lineageRole: disciple
    slotIndex: 1
    defaultRealm: erLiu
    defaultLayer: qiMeng
    attributeProfile: {constitution: 5, enlightenment: 5, agility: 5, fortune: 5}
  - id: second_disciple
    lineageRole: disciple
    slotIndex: 2
    defaultRealm: sanLiu
    defaultLayer: qiMeng
    attributeProfile: {constitution: 5, enlightenment: 5, agility: 5, fortune: 5}
''';

      expect(
        GameRepository.loadAllDefs(loader: mastersLoader(broken)),
        throwsA(isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('founder'),
        )),
      );
    });

    test('defaultRealm=wuSheng → 抛 StateError（飞升锚点）', () async {
      const broken = '''
masters:
  - id: founder
    lineageRole: founder
    slotIndex: 0
    defaultRealm: wuSheng
    defaultLayer: qiMeng
    attributeProfile: {constitution: 5, enlightenment: 5, agility: 5, fortune: 5}
  - id: first_disciple
    lineageRole: disciple
    slotIndex: 1
    defaultRealm: erLiu
    defaultLayer: qiMeng
    attributeProfile: {constitution: 5, enlightenment: 5, agility: 5, fortune: 5}
  - id: second_disciple
    lineageRole: disciple
    slotIndex: 2
    defaultRealm: sanLiu
    defaultLayer: qiMeng
    attributeProfile: {constitution: 5, enlightenment: 5, agility: 5, fortune: 5}
''';

      expect(
        GameRepository.loadAllDefs(loader: mastersLoader(broken)),
        throwsA(isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('wuSheng'),
        )),
      );
    });

    test('attributeProfile 总和越界（>24）→ 抛 StateError', () async {
      const broken = '''
masters:
  - id: founder
    lineageRole: founder
    slotIndex: 0
    defaultRealm: yiLiu
    defaultLayer: qiMeng
    attributeProfile: {constitution: 10, enlightenment: 10, agility: 8, fortune: 1}
  - id: first_disciple
    lineageRole: disciple
    slotIndex: 1
    defaultRealm: erLiu
    defaultLayer: qiMeng
    attributeProfile: {constitution: 5, enlightenment: 5, agility: 5, fortune: 5}
  - id: second_disciple
    lineageRole: disciple
    slotIndex: 2
    defaultRealm: sanLiu
    defaultLayer: qiMeng
    attributeProfile: {constitution: 5, enlightenment: 5, agility: 5, fortune: 5}
''';

      expect(
        GameRepository.loadAllDefs(loader: mastersLoader(broken)),
        throwsA(isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('total='),
        )),
      );
    });

    test('starting equipment tier 超出 defaultRealm 三系锁死 → 抛 StateError',
        () async {
      // 二弟子三流 (cap=xiangYang) 但 starting 给 liQi 武器
      const broken = '''
masters:
  - id: founder
    lineageRole: founder
    slotIndex: 0
    defaultRealm: yiLiu
    defaultLayer: qiMeng
    attributeProfile: {constitution: 5, enlightenment: 5, agility: 5, fortune: 5}
  - id: first_disciple
    lineageRole: disciple
    slotIndex: 1
    defaultRealm: erLiu
    defaultLayer: qiMeng
    attributeProfile: {constitution: 5, enlightenment: 5, agility: 5, fortune: 5}
  - id: second_disciple
    lineageRole: disciple
    slotIndex: 2
    defaultRealm: sanLiu
    defaultLayer: qiMeng
    attributeProfile: {constitution: 5, enlightenment: 5, agility: 5, fortune: 5}
    startingEquipmentIds:
      - weapon_liqi_long_quan
''';

      expect(
        GameRepository.loadAllDefs(loader: mastersLoader(broken)),
        throwsA(isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('三系锁死'),
        )),
      );
    });

    test('T55：祖师 startingEquipmentIds 无 isLineageHeritage 装备 → 抛 StateError',
        () async {
      // 祖师 starting 只挂寻常货武器（非遗物），缺师承遗物
      const broken = '''
masters:
  - id: founder
    lineageRole: founder
    slotIndex: 0
    defaultRealm: yiLiu
    defaultLayer: qiMeng
    attributeProfile: {constitution: 5, enlightenment: 5, agility: 5, fortune: 5}
    startingEquipmentIds:
      - weapon_xunchang_tie_jian
  - id: first_disciple
    lineageRole: disciple
    slotIndex: 1
    defaultRealm: erLiu
    defaultLayer: qiMeng
    attributeProfile: {constitution: 5, enlightenment: 5, agility: 5, fortune: 5}
  - id: second_disciple
    lineageRole: disciple
    slotIndex: 2
    defaultRealm: sanLiu
    defaultLayer: qiMeng
    attributeProfile: {constitution: 5, enlightenment: 5, agility: 5, fortune: 5}
''';

      expect(
        GameRepository.loadAllDefs(loader: mastersLoader(broken)),
        throwsA(isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('isLineageHeritage'),
        )),
      );
    });

    test('startingTechniqueId 在 techniques.yaml 不存在 → 抛 StateError', () async {
      const broken = '''
masters:
  - id: founder
    lineageRole: founder
    slotIndex: 0
    defaultRealm: yiLiu
    defaultLayer: qiMeng
    attributeProfile: {constitution: 5, enlightenment: 5, agility: 5, fortune: 5}
    startingTechniqueIds:
      - tech_does_not_exist
  - id: first_disciple
    lineageRole: disciple
    slotIndex: 1
    defaultRealm: erLiu
    defaultLayer: qiMeng
    attributeProfile: {constitution: 5, enlightenment: 5, agility: 5, fortune: 5}
  - id: second_disciple
    lineageRole: disciple
    slotIndex: 2
    defaultRealm: sanLiu
    defaultLayer: qiMeng
    attributeProfile: {constitution: 5, enlightenment: 5, agility: 5, fortune: 5}
''';

      expect(
        GameRepository.loadAllDefs(loader: mastersLoader(broken)),
        throwsA(isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('未在 techniques.yaml'),
        )),
      );
    });
  });
}
