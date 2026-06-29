import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/defs/drop_entry.dart';
import 'package:wuxia_idle/data/defs/skill_def.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/features/equipment/application/drop_service.dart';
import 'package:wuxia_idle/shared/utils/rng.dart';

/// GameRepository + yaml 加载器 + NumbersConfig 集成测试。
///
/// 用真实的 `data/*.yaml` 占位 fixture（pubspec 已声明 data/ 是 asset 根，
/// 这里直接通过文件 IO 加载——`flutter test` 的 cwd 是项目根，所以相对
/// 路径 `data/xxx.yaml` 可读）。注入式 loader 避免依赖 rootBundle。
void main() {
  Future<String> fileLoader(String path) async {
    final f = File(path);
    if (!await f.exists()) throw FileSystemException('不存在', path);
    // Windows git 默认 core.autocrlf=true 会把 yaml checkout 成 CRLF,
    // 而 broken loader 内用 Dart 多行字面量(LF)做 replaceFirst,
    // 不 normalize 则 needle 永远 miss,fail-fast test 不抛 StateError。
    return (await f.readAsString()).replaceAll('\r\n', '\n');
  }

  tearDown(GameRepository.resetForTest);

  group('GameRepository.loadAllDefs（占位 fixture）', () {
    test('加载完整 → counts 与 phase1_tasks T07.7.3 一致', () async {
      final repo = await GameRepository.loadAllDefs(loader: fileLoader);

      expect(repo.realms.length, 49, reason: '49 级境界');
      expect(repo.equipmentDefs.length, 80,
          reason: '80 件装备（P2.1 Batch 1 扩 7 阶 × 11 + 3 跨阶特殊）');
      expect(repo.techniqueDefs.length, 49,
          reason: '49 本心法（P2.1 Batch 2 扩 21 原 + 21 防御 + 7 内力）');
      // P2.1 Batch 2: 49 心法 × 3 = 147 + 18 lightfoot + 1 joint = 166
      // + P0.5: 破势 + 青锋绝 = 168;波A: + 截影 + 拂脉(三流派破招技)= 170
      // + 波B 24 招内容批: 真解 5 + 塔残页 6 + 章末重打残页 3 = 184
      // + 开锋槽 3 装备专属技 21 = 205
      // + 40 encounter_skills.yaml = 245 total
      expect(repo.skillDefs.length, 245,
          reason: '205 skills.yaml(147 心法 + 18 轻功 + 1 joint + 2 P0.5 + 2 波A 破招'
              ' + 14 波B 真解残页 + 21 开锋专属技) + 40 奇遇招');
      expect(repo.encounterSkillIds.length, 40,
          reason: 'encounter_skills.yaml 40 招(原 35 + T02 +5 武学领悟新招)');
      final mainlineCount = repo.stageDefs.values
          .where((s) => s.stageType == StageType.mainline)
          .length;
      final innerDemonCount = repo.stageDefs.values
          .where((s) => s.stageType == StageType.innerDemon)
          .length;
      final lightFootCount = repo.stageDefs.values
          .where((s) => s.stageType == StageType.lightFoot)
          .length;
      final massBattleCount = repo.stageDefs.values
          .where((s) => s.stageType == StageType.massBattle)
          .length;
      expect(mainlineCount, 30,
          reason: '主线 30 关(2026-05-22 P2 Ch6 扩,6 章 × 5 关)');
      expect(innerDemonCount, 7,
          reason: '心魔 7 关(2026-05-22 P2.2 §12.1 Batch 2.1 schema)');
      expect(lightFootCount, 5,
          reason: '轻功 5 关(2026-05-23 P3.1 §12.3 Batch 2.1 schema)');
      expect(massBattleCount, 5,
          reason: '群战守城 5 关(2026-05-24 P3.2 §12.3 Batch 2.3 stages)');
      expect(repo.stageDefs.length,
          mainlineCount + innerDemonCount + lightFootCount + massBattleCount,
          reason: 'stageDefs 现含 mainline + innerDemon + lightFoot + massBattle 四类');
      expect(repo.numbers.version, isNotEmpty);
      // P2.1 Batch 4:synergies.yaml 8→12(+4 specificTechniques 传说彩蛋)
      expect(repo.synergies.length, 12,
          reason: '心法相生 12 组合(P2.1 Batch 4 扩充,5 schoolPair + 1 sameSchool + 1 sameTier + 5 specificTechniques)');
    });

    test('开锋槽 3：36 件 weapon 使用真正专属技候选 / 44 件 armor+accessory 留空', () async {
      final repo = await GameRepository.loadAllDefs(loader: fileLoader);
      final weapons = repo.equipmentDefs.values
          .where((e) => e.slot == EquipmentSlot.weapon)
          .toList();
      final nonWeapons = repo.equipmentDefs.values
          .where((e) => e.slot != EquipmentSlot.weapon)
          .toList();

      expect(weapons.length, 36, reason: '7 阶 × 5 + 1 特殊');
      expect(nonWeapons.length, 44, reason: '7 阶 × (armor 3 + accessory 3) + 2 特殊');

      for (final w in weapons) {
        expect(w.specialSkillCandidates, isNotEmpty,
            reason: 'weapon ${w.id} 应配至少 1 个开锋专属技候选');
        for (final skillId in w.specialSkillCandidates) {
          final skill = repo.skillDefs[skillId];
          expect(skill, isNotNull,
              reason: '${w.id} 引用的 $skillId 必须在 skills.yaml 中存在');
          expect(skill!.source, SkillSource.special,
              reason: '${w.id} 槽 3 候选必须是真正装备专属技,不能复用心法招');
          expect(skill.parentTechniqueDefId, isNull,
              reason: '${w.id} 槽 3 候选不得绑定心法体系');
          expect(skill.tier, isNotNull,
              reason: '$skillId 必须有 tier,由 canEquipAtRealm 守三系锁死');
          expect(skill.style, isNotNull,
              reason: '$skillId 必须有 style,用于展示流派与 build 识别');
        }
      }
      for (final e in nonWeapons) {
        expect(e.specialSkillCandidates, isEmpty,
            reason: 'armor/accessory ${e.id} 不参与 specialSkill 槽(G1.a 决议)');
      }
    });

    test('GameRepository.instance 在 load 后可访问', () async {
      await GameRepository.loadAllDefs(loader: fileLoader);
      expect(GameRepository.isLoaded, isTrue);
      expect(identical(GameRepository.instance, GameRepository.instance),
          isTrue);
    });

    test('祖师起手 = 学徒新手·空手·入门功（2026-06-27 回归 GDD / T55 放宽）',
        () async {
      // 加载不抛 = T55「祖师起手须含师承遗物」已放宽（空 startingEquipmentIds
      // 合法）+ 三系锁死（tier ≤ 学徒 cap）通过。
      final repo = await GameRepository.loadAllDefs(loader: fileLoader);
      final founder = repo.masters[0];
      expect(founder.lineageRole, LineageRole.founder);
      expect(founder.defaultRealm, RealmTier.xueTu, reason: '学徒新手起手');
      expect(founder.defaultLayer, RealmLayer.qiMeng);
      expect(founder.startingEquipmentIds, isEmpty, reason: '空手起家');
      expect(founder.startingTechniqueIds, isNotEmpty);
      for (final id in founder.startingTechniqueIds) {
        expect(repo.techniqueDefs[id]?.tier, TechniqueTier.ruMenGong,
            reason: '$id 应为入门功（学徒 cap）');
      }
    });

    test('NumbersConfig 强类型字段（damage_formula / max_hp_formula / 防御率）', () async {
      final repo = await GameRepository.loadAllDefs(loader: fileLoader);
      expect(repo.numbers.combat.damageFormula.equipmentAttackFactor, 1.0);
      expect(repo.numbers.combat.damageFormula.internalForceFactor, 0.4);
      // P0.1 #38 重平衡(2026-05-17,方案 D):0.7→0.5 / 500→400
      expect(repo.numbers.combat.maxHpFormula.internalForceFactor, 0.5);
      expect(repo.numbers.combat.maxHpFormula.constitutionFactor, 400);
      expect(repo.numbers.defenseRateByTier[RealmTier.xueTu], 0.05);
      expect(repo.numbers.defenseRateByTier[RealmTier.wuSheng], 0.35);
      // Phase 4 W10 战败代价（与 dispersion 同 0.50 但字段独立）
      expect(repo.numbers.defeatBossInternalForcePenalty, 0.50);
      expect(repo.numbers.defeatBossCultivationPenalty, 0.50);
    });

    test('P3.2 Batch 2.3:5 关 stage_mass_battle_01..05 加载完整(waveCount + enemyCounts + prevStageId 链)',
        () async {
      final repo = await GameRepository.loadAllDefs(loader: fileLoader);
      final stages = ['01', '02', '03', '04', '05']
          .map((n) => repo.getStage('stage_mass_battle_$n'))
          .toList();

      // 5 关全部存在 + stageType + 字段齐
      for (final s in stages) {
        expect(s.stageType, StageType.massBattle,
            reason: '${s.id} stageType 必须 massBattle');
        expect(s.massBattleWaveCount, isNotNull,
            reason: '${s.id} 必配 massBattleWaveCount');
        expect(s.massBattleEnemyCounts, isNotNull,
            reason: '${s.id} 必配 massBattleEnemyCounts');
        // wave 数 1-4 + enemy 数 5-7(spec §4 红线)
        expect(s.massBattleWaveCount, inInclusiveRange(1, 4),
            reason: '${s.id} waveCount ∈ [1, 4]');
        expect(s.massBattleEnemyCounts!.length, s.massBattleWaveCount,
            reason: '${s.id} enemyCounts.length == waveCount');
        for (final cnt in s.massBattleEnemyCounts!) {
          expect(cnt, inInclusiveRange(5, 7),
              reason: '${s.id} 每 wave enemy 数 ∈ [5, 7](以少胜多 spec §1)');
        }
        // enemyTeam 3 模板(沿 LightFoot 体例 service 层 buildWavesFor 循环扩展)
        expect(s.enemyTeam.length, 3,
            reason: '${s.id} enemyTeam 3 模板(三流派覆盖)');
      }

      // wave/enemy 具体数值对齐 spec §4 表
      expect(stages[0].massBattleWaveCount, 2);
      expect(stages[0].massBattleEnemyCounts, [5, 5]);
      expect(stages[1].massBattleWaveCount, 3);
      expect(stages[1].massBattleEnemyCounts, [5, 6, 6]);
      expect(stages[2].massBattleWaveCount, 3);
      expect(stages[2].massBattleEnemyCounts, [6, 6, 7]);
      expect(stages[3].massBattleWaveCount, 4);
      expect(stages[3].massBattleEnemyCounts, [5, 6, 6, 7]);
      expect(stages[4].massBattleWaveCount, 4);
      expect(stages[4].massBattleEnemyCounts, [6, 6, 7, 7]);

      // prevStageId 链(02..05 链到 01,01 无 prevStageId 在 stages.yaml 内
      // 因为 prev=stage_06_05 跨 stageType,在 numbers.yaml unlock_triggers 配)
      expect(stages[0].prevStageId, isNull,
          reason: 'stage_mass_battle_01 chain 起点 stages.yaml 内 prev null');
      expect(stages[1].prevStageId, 'stage_mass_battle_01');
      expect(stages[2].prevStageId, 'stage_mass_battle_02');
      expect(stages[3].prevStageId, 'stage_mass_battle_03');
      expect(stages[4].prevStageId, 'stage_mass_battle_04');

      // §5.4 Tier 锁死:01-03 yiLiu / 04-05 jueDing
      expect(stages[0].requiredRealm, RealmTier.yiLiu);
      expect(stages[1].requiredRealm, RealmTier.yiLiu);
      expect(stages[2].requiredRealm, RealmTier.yiLiu);
      expect(stages[3].requiredRealm, RealmTier.jueDing);
      expect(stages[4].requiredRealm, RealmTier.jueDing);

      // 05 BOSS(沿 LightFoot 末关 isBossStage=true 体例)
      expect(stages[4].isBossStage, isTrue,
          reason: 'stage_mass_battle_05 守城卫战 章末 BOSS');
    });

    test('P3.2 Batch 2.1:mass_battle yaml schema 加载完整(formations + wave + stage + unlock)',
        () async {
      final repo = await GameRepository.loadAllDefs(loader: fileLoader);
      final mb = repo.numbers.massBattle;

      // formations 3 阵型 × 4 字段(沿 yanXing/baGua/fengShi spec §2 数值)
      expect(mb.formations.length, 3, reason: 'yanXing/baGua/fengShi 3 阵型');
      final yanXing = mb.formations[Formation.yanXing]!;
      expect(yanXing.criticalRateDelta, 0.10, reason: '雁行:crit +0.10');
      expect(yanXing.defenseRateDelta, -0.05, reason: '雁行:defense -0.05');
      expect(yanXing.evasionRateDelta, 0.00);
      expect(yanXing.damageMultiplier, 1.00);
      final baGua = mb.formations[Formation.baGua]!;
      expect(baGua.defenseRateDelta, 0.10, reason: '八卦:defense +0.10');
      expect(baGua.evasionRateDelta, 0.05, reason: '八卦:evasion +0.05');
      expect(baGua.criticalRateDelta, 0.00);
      expect(baGua.damageMultiplier, 1.00);
      final fengShi = mb.formations[Formation.fengShi]!;
      expect(fengShi.damageMultiplier, 1.10, reason: '锋矢:damage ×1.10');
      expect(fengShi.criticalRateDelta, 0.05, reason: '锋矢:crit +0.05');
      expect(fengShi.evasionRateDelta, 0.00);
      expect(fengShi.defenseRateDelta, 0.00);

      // wave_intermission 4 规则(契 §5.5 在线 = 离线 + 守城压力累积)
      expect(mb.waveIntermission.resetActionPoint, isTrue,
          reason: 'wave 间 actionPoint 归 0 → 走 tick 不快进');
      expect(mb.waveIntermission.preserveHp, isTrue,
          reason: 'wave 间 HP 保留 → 守城压力累积');
      expect(mb.waveIntermission.preserveInternalForce, isTrue,
          reason: 'wave 间内力保留 → 限大招使用');
      expect(mb.waveIntermission.preserveCooldowns, isFalse,
          reason: 'wave 间 cd 重置 → 给玩家下波大招机会');

      // stage_formations 5 关默认阵型(主题契合,Tier 风格梯度)
      expect(mb.stageFormations.length, 5);
      expect(mb.stageFormations['stage_mass_battle_01'], Formation.yanXing);
      expect(mb.stageFormations['stage_mass_battle_02'], Formation.baGua);
      expect(mb.stageFormations['stage_mass_battle_03'], Formation.fengShi);
      expect(mb.stageFormations['stage_mass_battle_04'], Formation.baGua);
      expect(mb.stageFormations['stage_mass_battle_05'], Formation.fengShi);

      // unlock_triggers 5 项链(沿 light_foot 体例 key=触发,value=解锁的下一关)
      expect(mb.unlockTriggers.length, 5);
      expect(mb.unlockTriggers['stage_06_05'], 'stage_mass_battle_01',
          reason: '平行支线挂 Demo Ch6 末后(沿 LightFoot 体例 stage_06_05 触发)');
      expect(mb.unlockTriggers['stage_mass_battle_01'], 'stage_mass_battle_02');
      expect(mb.unlockTriggers['stage_mass_battle_02'], 'stage_mass_battle_03');
      expect(mb.unlockTriggers['stage_mass_battle_03'], 'stage_mass_battle_04');
      expect(mb.unlockTriggers['stage_mass_battle_04'], 'stage_mass_battle_05');
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
        1,
      );
    });

    test('T27 dropTable 解析 → stage_01_02 / 03_05 dropTable 非空，'
        '其他未配关卡 dropTable 为空（向后兼容）', () async {
      final repo = await GameRepository.loadAllDefs(loader: fileLoader);
      final s2 = repo.getStage('stage_01_02');
      // 材料经济 P1 起：各关 dropTable 加 item_silver，故断言改为 ≥ 原有条数
      expect(s2.dropTable.length, greaterThanOrEqualTo(3),
          reason: '荒山野店：2 装备 + 必掉磨剑石(+P1 起加 item_silver)');
      // 验证 item_mojianshi 仍在 dropTable（而非关注绝对条数）
      expect(
        s2.dropTable.whereType<ItemDrop>().map((e) => e.inventoryItemDefId),
        contains('item_mojianshi'),
      );
      final sFinal = repo.getStage('stage_03_05');
      expect(sFinal.dropTable.length, greaterThanOrEqualTo(3),
          reason: '章末大 Boss：龙泉剑 + 60% 玉佩 + 必掉心血结晶(+P1 起加 item_silver)');
      expect(
        sFinal.dropTable.whereType<ItemDrop>().map((e) => e.inventoryItemDefId),
        contains('item_xinxuejiejing'),
      );
      // W13-v3:stage_01_01 加 onboarding dropTable(必掉护甲 + 1 磨剑石)
      final s1 = repo.getStage('stage_01_01');
      expect(s1.dropTable.length, greaterThanOrEqualTo(3),
          reason: '新手第一关：100% 布衣 + 30% 铜铃 + 100% 磨剑石(+P1 起加 item_silver)');
      expect(
        s1.dropTable.whereType<ItemDrop>().map((e) => e.inventoryItemDefId),
        contains('item_mojianshi'),
      );
    });

    test('W13-v3 #10 兜底：DropService.rollDrops(stage_01_01) 100% 掉护甲 + 磨剑石',
        () async {
      // Codex v4 视觉验收 #10 未取得硬截图(GUI/RDP 操作问题),用 service 层
      // 直接验证 dropTable 配置在 DropService 路径上真生效,作为视觉缺失的代码层兜底。
      final repo = await GameRepository.loadAllDefs(loader: fileLoader);
      final stage = repo.getStage('stage_01_01');
      final svc = DropService(equipmentDefLookup: repo.getEquipment);

      // 跑 5 次,armor 100% 必掉 + accessory 30% 概率掉,验证必掉项非 flake
      // 材料经济 P1 起：stage_01_01 dropTable 含 item_mojianshi + item_silver
      for (var i = 0; i < 5; i++) {
        final result = svc.rollDrops(stage, DefaultRng(seed: i));
        expect(result.equipments.length, greaterThanOrEqualTo(1),
            reason: 'iter $i:armor_xunchang_bu_yi 100% 必掉');
        expect(result.equipments.map((e) => e.defId),
            contains('armor_xunchang_bu_yi'));
        // P1 起：物品条目 ≥ 1（mojianshi + silver 各 100% 必掉）
        expect(result.items.length, greaterThanOrEqualTo(1),
            reason: 'iter $i:item_mojianshi 100% 必掉');
        expect(result.items.map((e) => e.defId), contains('item_mojianshi'),
            reason: 'iter $i:item_mojianshi 必在 items');
        final mojianshi = result.items.firstWhere((e) => e.defId == 'item_mojianshi');
        expect(mojianshi.quantity, 1,
            reason: 'iter $i:quantity [1,1] 永远 1');
        // P1 新增：item_silver 必掉
        expect(result.items.map((e) => e.defId), contains('item_silver'),
            reason: 'iter $i:item_silver 已配 dropChance=1.0 必掉');
      }
    });

    test('主线 30 关红线:6 章 × 5 关 + 4/5 关 isBossStage(2026-05-22 P2 Ch6 扩)',
        () async {
      final repo = await GameRepository.loadAllDefs(loader: fileLoader);
      final mainlines = repo.stageDefs.values
          .where((s) => s.stageType == StageType.mainline)
          .toList();
      expect(mainlines.length, 30);
      for (final ch in [1, 2, 3, 4, 5, 6]) {
        final inCh = mainlines.where((s) => s.chapterIndex == ch).toList();
        expect(inCh.length, 5, reason: 'Ch$ch 应有 5 关');
      }
      // 章末两关 4/5 是 Boss + 配 narrativeDefeatId;1/2/3 关非 Boss + 无 defeat
      for (final ch in [1, 2, 3, 4, 5, 6]) {
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

    test('drop 覆盖率红线:除 special 外每件装备至少有 1 个主线关卡 dropTable 来源',
        () async {
      final repo = await GameRepository.loadAllDefs(loader: fileLoader);
      final specialTags = {'ascension_reward', 'inner_demon_reward', 'mass_battle_merit'};
      final mainlines = repo.stageDefs.values
          .where((s) => s.stageType == StageType.mainline)
          .toList();

      final droppedIds = <String>{};
      for (final stage in mainlines) {
        for (final entry in stage.dropTable) {
          if (entry case EquipmentDrop(:final equipmentDefId)) {
            droppedIds.add(equipmentDefId);
          }
        }
      }

      final missing = <String>[];
      for (final e in repo.equipmentDefs.values) {
        final isSpecial = e.dropSourceTags.any(specialTags.contains);
        if (!isSpecial && !droppedIds.contains(e.id)) {
          missing.add(e.id);
        }
      }
      expect(missing, isEmpty,
          reason: '以下装备无主线 drop 来源: $missing');
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
    description: 蓄势三息,一拳如怒涛拍岸
    type: ultimate''',
            '''
  - id: skill_gangmeng_jichu_ult
    name: 怒涛拳
    description: 蓄势三息,一拳如怒涛拍岸
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

    /// R3 单链(spec §九 R3 风险挂账):每章 5 关 prevStageId 严格 N→N-1 单链。
    ///
    /// 红线断言语义(memory `feedback_red_line_test_semantics`):
    /// - 每章首关(stage_X_01) prevStageId = null
    /// - 每章后续关(stage_X_02..05) prevStageId 严格 = stage_X_(N-1)
    ///
    /// Ch5/Ch6 spec 起草前若 stages.yaml prevStageId 写错(打字 / 跨章 / 形成环)
    /// 此 test 拦截。现有 `_enforceRedLines` 只验「引用存在 + 同章」,本 test 补
    /// 「严格单链 N-1」语义。
    test('R3 主线 6 章 30 关 prevStageId 严格 N→N-1 单链(每章首关 null)',
        () async {
      final repo = await GameRepository.loadAllDefs(loader: fileLoader);
      for (final ch in [1, 2, 3, 4, 5, 6]) {
        for (final idx in [1, 2, 3, 4, 5]) {
          final id = 'stage_0${ch}_0$idx';
          final s = repo.getStage(id);
          if (idx == 1) {
            expect(s.prevStageId, isNull,
                reason: '$id 每章首关 prevStageId 应 null,实际 ${s.prevStageId}');
          } else {
            final expected = 'stage_0${ch}_0${idx - 1}';
            expect(s.prevStageId, expected,
                reason: '$id prevStageId 应严格 = $expected(单链 N→N-1),'
                    '实际 ${s.prevStageId}');
          }
        }
      }
    });

    /// R6 dropTable 反向引用(spec §九 R6 风险挂账 + 2026-05-22 audit 发现):
    /// stages.yaml dropTable EquipmentDrop.equipmentDefId 必须在 equipment.yaml 存在。
    ///
    /// 红线断言语义(memory `feedback_red_line_test_semantics`):
    /// - 主线 / 爬塔 / 闭关全 stages.yaml dropTable 反向引用全命中
    /// - 防 Ch5/Ch6 加 dropTable 引用错的 def 至 runtime crash(DropService.rollDrops
    ///   抛 StateError)
    ///
    /// **现有 `_enforceRedLines` 不显式验 dropTable 反向引用** — 本 test 补红线。
    /// memory `feedback_audit_report_phase0_verify` 维度 4 反向引用 grep 已确认
    /// Ch4 7/7 命中,但生产层无 test 锁死。
    test('R6 stages.yaml dropTable equipmentDefId 反向引用全命中', () async {
      final repo = await GameRepository.loadAllDefs(loader: fileLoader);
      final equipmentIds = repo.equipmentDefs.keys.toSet();

      for (final stage in repo.stageDefs.values) {
        // dropTable EquipmentDrop 反向引用
        for (final entry in stage.dropTable) {
          if (entry is EquipmentDrop) {
            expect(equipmentIds.contains(entry.equipmentDefId), isTrue,
                reason: 'stage ${stage.id} dropTable EquipmentDrop '
                    '${entry.equipmentDefId} 应在 equipment.yaml 存在 '
                    '(防 Ch5/Ch6 写错 runtime crash)');
          }
        }
      }
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
      expect(repo.masters[1].lineageRole, LineageRole.senior);
      expect(repo.masters[2].lineageRole, LineageRole.junior);
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

    test('T55 放宽（2026-06-27）：祖师无师承遗物起手 → 加载通过（不再抛）',
        () async {
      // 原 T55 要求祖师起手须含 isLineageHeritage 装备；2026-06-27 放宽移除
      // （祖师改学徒新手空手起家，师承遗物改游戏中获得）。同一 fixture（祖师
      // 只挂寻常货武器、无遗物）现应正常加载——本测守 T55 放宽不被回退。
      const ok = '''
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
    lineageRole: senior
    slotIndex: 1
    defaultRealm: erLiu
    defaultLayer: qiMeng
    attributeProfile: {constitution: 5, enlightenment: 5, agility: 5, fortune: 5}
  - id: second_disciple
    lineageRole: junior
    slotIndex: 2
    defaultRealm: sanLiu
    defaultLayer: qiMeng
    attributeProfile: {constitution: 5, enlightenment: 5, agility: 5, fortune: 5}
''';

      final repo = await GameRepository.loadAllDefs(loader: mastersLoader(ok));
      expect(repo.masters[0].lineageRole, LineageRole.founder);
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

  group('P1.1 A1 E.1 · 收徒候选红线校验', () {
    // 用 recruitLoader 注入 data/recruit_candidates.yaml 文本;其余文件走真实 fileLoader。
    Future<String> Function(String) recruitLoader(String yaml) {
      return (String path) async {
        if (path.endsWith('recruit_candidates.yaml')) return yaml;
        return fileLoader(path);
      };
    }

    test('生产 yaml 3 候选加载 + 维度 ABC 完整', () async {
      final repo = await GameRepository.loadAllDefs(loader: fileLoader);
      expect(repo.recruitCandidates.length, 3,
          reason: 'D2.b 决议 3 NPC');
      expect(repo.recruitCandidates['candidate_a']!.school?.name, 'gangMeng');
      expect(repo.recruitCandidates['candidate_b']!.school?.name, 'lingQiao');
      expect(repo.recruitCandidates['candidate_c']!.school, isNull);
      // 全部 disciple 角色(audit M 决议)
      for (final c in repo.recruitCandidates.values) {
        expect(c.lineageRole, LineageRole.disciple);
        expect(c.defaultRealm, RealmTier.sanLiu);
      }
    });

    test('候选数 ≠ 3 → 抛 StateError(本批 D2.b 锚 3)', () async {
      const broken = '''
recruit_candidates:
  - id: c1
    name: '甲'
    lineageRole: disciple
    defaultRealm: sanLiu
    defaultLayer: qiMeng
    school: gangMeng
    attributeProfile: {constitution: 5, enlightenment: 5, agility: 5, fortune: 5}
    startingTechniqueIds: []
    startingEquipmentIds: []
    lore: '占位'
  - id: c2
    name: '乙'
    lineageRole: disciple
    defaultRealm: sanLiu
    defaultLayer: qiMeng
    school: lingQiao
    attributeProfile: {constitution: 5, enlightenment: 5, agility: 5, fortune: 5}
    startingTechniqueIds: []
    startingEquipmentIds: []
    lore: '占位'
''';

      expect(
        GameRepository.loadAllDefs(loader: recruitLoader(broken)),
        throwsA(isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('收徒候选应为 3 条'),
        )),
      );
    });

    test('candidate.lineageRole=founder → 抛 StateError(只能 disciple)', () async {
      const broken = '''
recruit_candidates:
  - id: c1
    name: '甲'
    lineageRole: founder
    defaultRealm: sanLiu
    defaultLayer: qiMeng
    school: gangMeng
    attributeProfile: {constitution: 5, enlightenment: 5, agility: 5, fortune: 5}
    startingTechniqueIds: []
    startingEquipmentIds: []
    lore: '占位'
  - id: c2
    name: '乙'
    lineageRole: disciple
    defaultRealm: sanLiu
    defaultLayer: qiMeng
    school: lingQiao
    attributeProfile: {constitution: 5, enlightenment: 5, agility: 5, fortune: 5}
    startingTechniqueIds: []
    startingEquipmentIds: []
    lore: '占位'
  - id: c3
    name: '丙'
    lineageRole: disciple
    defaultRealm: sanLiu
    defaultLayer: qiMeng
    attributeProfile: {constitution: 5, enlightenment: 5, agility: 5, fortune: 5}
    startingTechniqueIds: []
    startingEquipmentIds: []
    lore: '占位'
''';

      expect(
        GameRepository.loadAllDefs(loader: recruitLoader(broken)),
        throwsA(isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('必须为 disciple'),
        )),
      );
    });

    test('attributeProfile.total > 24 → 抛 StateError', () async {
      const broken = '''
recruit_candidates:
  - id: c1
    name: '甲'
    lineageRole: disciple
    defaultRealm: sanLiu
    defaultLayer: qiMeng
    school: gangMeng
    attributeProfile: {constitution: 10, enlightenment: 10, agility: 10, fortune: 10}
    startingTechniqueIds: []
    startingEquipmentIds: []
    lore: '占位'
  - id: c2
    name: '乙'
    lineageRole: disciple
    defaultRealm: sanLiu
    defaultLayer: qiMeng
    school: lingQiao
    attributeProfile: {constitution: 5, enlightenment: 5, agility: 5, fortune: 5}
    startingTechniqueIds: []
    startingEquipmentIds: []
    lore: '占位'
  - id: c3
    name: '丙'
    lineageRole: disciple
    defaultRealm: sanLiu
    defaultLayer: qiMeng
    attributeProfile: {constitution: 5, enlightenment: 5, agility: 5, fortune: 5}
    startingTechniqueIds: []
    startingEquipmentIds: []
    lore: '占位'
''';

      expect(
        GameRepository.loadAllDefs(loader: recruitLoader(broken)),
        throwsA(isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('应 ∈ [16, 24]'),
        )),
      );
    });
  });

  group('P2-a 奇遇招式池兜底(外部 review)', () {
    // encounter_skills.yaml 在生产被 catch 静默吞掉(损坏/缺失)→ 招式池为空,
    // 而 encounters.yaml 仍引用 unlockSkill skillId → 旧逻辑因
    // `encounterSkillIds.isNotEmpty` 闸门跳过一致性校验,奇遇招式静默失效。
    // 修复后:招式池空但奇遇有 unlockSkill 引用 → fail-fast 抛 StateError。
    test('encounter_skills 池空但 encounters 引用 skillId → 抛 StateError', () async {
      Future<String> brokenLoader(String path) async {
        if (path.endsWith('encounter_skills.yaml')) {
          return 'encounter_skills: []\n'; // 模拟损坏/缺失被吞 → 空池
        }
        return fileLoader(path);
      }

      expect(
        GameRepository.loadAllDefs(loader: brokenLoader),
        throwsA(isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('encounter skill 池'),
        )),
      );
    });
  });
}
