import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/core/domain/attributes.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/domain/technique.dart';
import 'package:wuxia_idle/data/numbers_config.dart';
import 'package:wuxia_idle/features/cultivation/application/cultivation_service.dart';
import 'package:wuxia_idle/features/dispel/application/dispel_service.dart';

/// T25 DispelService 验收（phase2_tasks T25 §297-321）。
///
/// 算法 A（Pen 拍板）：散功后 progress×0.5，layer 反向回退直到
/// progress >= prev→current progress_required。
void main() {
  late NumbersConfig n;

  setUpAll(() async {
    final repo = await GameRepository.loadAllDefs(
      loader: (path) => File(path).readAsString(),
    );
    n = repo.numbers;
  });

  Character newChar({
    int id = 1,
    int internalForce = 5000,
    int? mainTechniqueId,
    List<int>? assistTechniqueIds,
  }) {
    final c = Character.create(
      name: '测试者',
      realmTier: RealmTier.erLiu,
      realmLayer: RealmLayer.qiMeng,
      attributes: Attributes()
        ..constitution = 5
        ..enlightenment = 5
        ..agility = 5
        ..fortune = 5,
      rarity: RarityTier.biaoZhun,
      lineageRole: LineageRole.disciple,
      createdAt: DateTime(2026, 5, 11),
      internalForce: internalForce,
      internalForceMax: 10000,
      mainTechniqueId: mainTechniqueId,
      assistTechniqueIds: assistTechniqueIds,
    );
    c.id = id;
    return c;
  }

  Technique newTech({
    required int id,
    required int ownerCharId,
    TechniqueRole role = TechniqueRole.main,
    CultivationLayer layer = CultivationLayer.chuKui,
    int progress = 0,
    int progressToNext = 100,
  }) {
    final t = Technique.create(
      defId: 'tech_$id',
      ownerCharacterId: ownerCharId,
      tier: TechniqueTier.mingJiaGong,
      school: TechniqueSchool.gangMeng,
      role: role,
      learnedAt: DateTime(2026, 5, 11),
      cultivationLayer: layer,
      cultivationProgress: progress,
      cultivationProgressToNext: progressToNext,
    );
    t.id = id;
    return t;
  }

  // ────────────────────────────────────────────────────────────────────────────
  // 校验失败
  // ────────────────────────────────────────────────────────────────────────────

  group('校验失败', () {
    test('旧主修 role=assist → oldMainTechIsNotMain', () {
      final ch = newChar(internalForce: 5000);
      final mainT = newTech(id: 10, ownerCharId: 1, role: TechniqueRole.assist);
      final newT = newTech(id: 11, ownerCharId: 1, role: TechniqueRole.assist);
      final r = DispelService.dispel(
        ch: ch,
        mainTech: mainT,
        newMainTech: newT,
        n: n,
      );
      expect(r.outcome, DispelOutcome.oldMainTechIsNotMain);
      expect(ch.internalForce, 5000); // 未触动
    });

    test('新主修不属于该角色 → newMainTechNotOwnedByCharacter', () {
      final ch = newChar(id: 1, internalForce: 5000);
      final mainT = newTech(id: 10, ownerCharId: 1);
      final newT = newTech(id: 11, ownerCharId: 99, role: TechniqueRole.assist);
      final r = DispelService.dispel(
        ch: ch,
        mainTech: mainT,
        newMainTech: newT,
        n: n,
      );
      expect(r.outcome, DispelOutcome.newMainTechNotOwnedByCharacter);
      expect(ch.internalForce, 5000);
    });

    test('新主修 role=main → newMainTechIsNotAssist', () {
      final ch = newChar(internalForce: 5000);
      final mainT = newTech(id: 10, ownerCharId: 1);
      final newT = newTech(id: 11, ownerCharId: 1, role: TechniqueRole.main);
      final r = DispelService.dispel(
        ch: ch,
        mainTech: mainT,
        newMainTech: newT,
        n: n,
      );
      expect(r.outcome, DispelOutcome.newMainTechIsNotAssist);
    });
  });

  // ────────────────────────────────────────────────────────────────────────────
  // 双重惩罚（内力 + progress）
  // ────────────────────────────────────────────────────────────────────────────

  group('双重惩罚', () {
    test('内力 5000 → 2500，progress 100 → 50（floor 精度）', () {
      final ch = newChar(
        internalForce: 5000,
        mainTechniqueId: 10,
        assistTechniqueIds: [11],
      );
      final mainT = newTech(
        id: 10, ownerCharId: 1,
        layer: CultivationLayer.xiaoCheng, progress: 100, progressToNext: 250,
      );
      final newT = newTech(
        id: 11, ownerCharId: 1, role: TechniqueRole.assist,
      );
      final r = DispelService.dispel(
        ch: ch, mainTech: mainT, newMainTech: newT, n: n,
      );
      expect(r.outcome, DispelOutcome.success);
      expect(ch.internalForce, 2500);
      expect(mainT.cultivationProgress, 50);
      expect(mainT.role, TechniqueRole.assist);
      expect(newT.role, TechniqueRole.main);
    });

    test('内力 5001 → 2500（floor，不 round）', () {
      final ch = newChar(
        internalForce: 5001,
        mainTechniqueId: 10,
        assistTechniqueIds: [11],
      );
      final mainT = newTech(id: 10, ownerCharId: 1);
      final newT = newTech(id: 11, ownerCharId: 1, role: TechniqueRole.assist);
      final r = DispelService.dispel(
        ch: ch, mainTech: mainT, newMainTech: newT, n: n,
      );
      expect(r.outcome, DispelOutcome.success);
      expect(ch.internalForce, 2500); // 5001*0.5=2500.5 → toInt floor → 2500
    });
  });

  // ────────────────────────────────────────────────────────────────────────────
  // cultivationLayer 反向回退（算法 A 核心）
  // ────────────────────────────────────────────────────────────────────────────

  group('cultivationLayer 反向回退（算法 A）', () {
    test('回退一层：yuanMan/1500 → daCheng/750', () {
      final ch = newChar(mainTechniqueId: 10, assistTechniqueIds: [11]);
      final mainT = newTech(
        id: 10, ownerCharId: 1,
        layer: CultivationLayer.yuanMan, progress: 1500, progressToNext: 1500,
      );
      final newT = newTech(id: 11, ownerCharId: 1, role: TechniqueRole.assist);
      final r = DispelService.dispel(
        ch: ch, mainTech: mainT, newMainTech: newT, n: n,
      );
      expect(r.outcome, DispelOutcome.success);
      expect(r.layersRolledBack, 1);
      expect(r.oldLayer, CultivationLayer.yuanMan);
      expect(r.newLayer, CultivationLayer.daCheng);
      expect(mainT.cultivationLayer, CultivationLayer.daCheng);
      expect(mainT.cultivationProgress, 750);
      expect(mainT.cultivationProgressToNext, 900); // daCheng→yuanMan
    });

    test('不回退：yuanMan/2000 → yuanMan/1000（progress 仍 ≥ daCheng→yuanMan 的 900）', () {
      final ch = newChar(mainTechniqueId: 10, assistTechniqueIds: [11]);
      final mainT = newTech(
        id: 10, ownerCharId: 1,
        layer: CultivationLayer.yuanMan, progress: 2000, progressToNext: 1500,
      );
      final newT = newTech(id: 11, ownerCharId: 1, role: TechniqueRole.assist);
      final r = DispelService.dispel(
        ch: ch, mainTech: mainT, newMainTech: newT, n: n,
      );
      expect(r.layersRolledBack, 0);
      expect(r.newLayer, CultivationLayer.yuanMan);
      expect(mainT.cultivationProgress, 1000); // 2000*0.5
      expect(mainT.cultivationProgressToNext, 1500);
    });

    test('多层连退：dianFeng/1600 → daCheng/800', () {
      // disperse: progress=800
      // 800<1500(yuanMan→dianFeng) 退 yuanMan
      // 800<900(daCheng→yuanMan) 退 daCheng
      // 800>=500(zhongCheng→daCheng) 停
      final ch = newChar(mainTechniqueId: 10, assistTechniqueIds: [11]);
      final mainT = newTech(
        id: 10, ownerCharId: 1,
        layer: CultivationLayer.dianFeng, progress: 1600, progressToNext: 2500,
      );
      final newT = newTech(id: 11, ownerCharId: 1, role: TechniqueRole.assist);
      final r = DispelService.dispel(
        ch: ch, mainTech: mainT, newMainTech: newT, n: n,
      );
      expect(r.layersRolledBack, 2);
      expect(r.newLayer, CultivationLayer.daCheng);
      expect(mainT.cultivationProgress, 800);
      expect(mainT.cultivationProgressToNext, 900);
    });

    test('chuKui 边界：layer=chuKui/progress=50 散功 → 仍 chuKui/25（无下限可退）', () {
      final ch = newChar(mainTechniqueId: 10, assistTechniqueIds: [11]);
      final mainT = newTech(
        id: 10, ownerCharId: 1,
        layer: CultivationLayer.chuKui, progress: 50, progressToNext: 100,
      );
      final newT = newTech(id: 11, ownerCharId: 1, role: TechniqueRole.assist);
      final r = DispelService.dispel(
        ch: ch, mainTech: mainT, newMainTech: newT, n: n,
      );
      expect(r.layersRolledBack, 0);
      expect(r.newLayer, CultivationLayer.chuKui);
      expect(mainT.cultivationProgress, 25);
    });
  });

  // ────────────────────────────────────────────────────────────────────────────
  // Character 字段更新 + 辅修槽
  // ────────────────────────────────────────────────────────────────────────────

  group('Character 字段更新', () {
    test('mainTechniqueId 切到新主修；旧主修挪入 assist 槽', () {
      final ch = newChar(mainTechniqueId: 10, assistTechniqueIds: [11, 12]);
      final mainT = newTech(id: 10, ownerCharId: 1);
      final newT = newTech(id: 11, ownerCharId: 1, role: TechniqueRole.assist);
      DispelService.dispel(ch: ch, mainTech: mainT, newMainTech: newT, n: n);

      expect(ch.mainTechniqueId, 11);
      expect(ch.assistTechniqueIds, contains(10)); // 旧主修入辅修
      expect(ch.assistTechniqueIds, isNot(contains(11))); // 新主修离开辅修
      expect(ch.assistTechniqueIds, contains(12)); // 其他辅修不动
    });

    test('辅修槽满 3：旧主修被丢弃（oldTechniqueDiscarded=true）', () {
      // 散功前：assist=[11,12,13]；新主修=11 来自 assist
      // 切换后：assist 移除 11 → [12,13]，旧主修 10 可塞入 → [12,13,10]
      // 这个例子不会满，需要构造更精细的：
      // 假设 assist=[11,12,13,14]（4 个，但 yaml 限 3）→ 实际上 max 3 不会发生
      // 真正"满"的场景：散功后新主修离开 assist 后槽位仍为 3，即原来 assist 有 4 项
      // 但 spec 说 assist 最多 3，所以"满"只在反常状态下出现。这里测试该兜底逻辑。
      final ch = newChar(mainTechniqueId: 10, assistTechniqueIds: [11, 12, 13, 99]);
      final mainT = newTech(id: 10, ownerCharId: 1);
      final newT = newTech(id: 11, ownerCharId: 1, role: TechniqueRole.assist);
      final r = DispelService.dispel(
        ch: ch, mainTech: mainT, newMainTech: newT, n: n,
      );
      // assist 移除 11 后剩 [12,13,99]（=3，已满），旧主修 10 不入
      expect(r.oldTechniqueDiscarded, isTrue);
      expect(ch.assistTechniqueIds, [12, 13, 99]);
      expect(ch.assistTechniqueIds, isNot(contains(10)));
    });
  });

  // ────────────────────────────────────────────────────────────────────────────
  // 散功后回升：与 CultivationService 联动
  // ────────────────────────────────────────────────────────────────────────────

  group('散功后回升', () {
    test('散功后用 recordSkillUsage 累积，能从回退后的 layer 重新升回去', () {
      // yuanMan/1500 散功 → daCheng/750 (progressToNext=900)
      // 累积 +150 → daCheng/900 → 升 yuanMan/0 (progressToNext=1500)
      // 累积 +1500 → 升 dianFeng/0
      final ch = newChar(mainTechniqueId: 10, assistTechniqueIds: [11]);
      final mainT = newTech(
        id: 10, ownerCharId: 1,
        layer: CultivationLayer.yuanMan, progress: 1500, progressToNext: 1500,
      );
      final newT = newTech(id: 11, ownerCharId: 1, role: TechniqueRole.assist);
      DispelService.dispel(ch: ch, mainTech: mainT, newMainTech: newT, n: n);
      // 散功后 mainT: daCheng/750, role=assist
      // 用 CultivationService 给 mainT 累积，验证升层逻辑能接上
      final r1 = CultivationService.recordSkillUsage(
        tech: mainT,
        skillId: 'skill_a',
        progressToNextMap: n.cultivationProgressToNext,
        delta: 150,
      );
      expect(r1.didLevelUp, isTrue);
      expect(r1.newLayer, CultivationLayer.yuanMan);
      expect(mainT.cultivationProgress, 0);
      expect(mainT.cultivationProgressToNext, 1500);

      final r2 = CultivationService.recordSkillUsage(
        tech: mainT,
        skillId: 'skill_a',
        progressToNextMap: n.cultivationProgressToNext,
        delta: 1500,
      );
      expect(r2.didLevelUp, isTrue);
      expect(r2.newLayer, CultivationLayer.dianFeng);
    });
  });

  // ────────────────────────────────────────────────────────────────────────────
  // Phase 4 W10：Boss 战败被动散功（applyDefeatPenalty）
  // ────────────────────────────────────────────────────────────────────────────

  group('Phase 4 W10 · applyDefeatPenalty Boss 战败被动散功', () {
    test('基本流程：内力 ×0.5 + progress ×0.5 + layer 回退 + role 不动', () {
      // yuanMan/1500 → progress=750；prev(daCheng→yuanMan req)=900；
      // 750<900 → 回退 daCheng；prev(zhongCheng→daCheng req)=500；
      // 750>=500 → 停。期望：daCheng/750，progressToNext=900（daCheng→yuanMan）
      final ch = newChar(internalForce: 8000);
      final mainT = newTech(
        id: 10,
        ownerCharId: 1,
        role: TechniqueRole.main,
        layer: CultivationLayer.yuanMan,
        progress: 1500,
        progressToNext: 1500,
      );
      final r = DispelService.applyDefeatPenalty(
        ch: ch,
        mainTech: mainT,
        n: n,
      );
      expect(ch.internalForce, 4000);
      expect(mainT.cultivationProgress, 750);
      expect(mainT.cultivationLayer, CultivationLayer.daCheng);
      expect(mainT.cultivationProgressToNext, 900);
      expect(r.layersRolledBack, 1);
      expect(r.oldLayer, CultivationLayer.yuanMan);
      expect(r.newLayer, CultivationLayer.daCheng);
      expect(r.internalForceBefore, 8000);
      expect(r.internalForceAfter, 4000);
      expect(r.progressBefore, 1500);
      expect(r.didRollback, isTrue);
      // role / wasMainBeforeReset 必须不动（区别于 dispel）
      expect(mainT.role, TechniqueRole.main);
      expect(mainT.wasMainBeforeReset, isFalse);
    });

    test('chuKui + progress=0 边界：无副作用、layersRolledBack=0', () {
      final ch = newChar(internalForce: 100);
      final mainT = newTech(
        id: 10,
        ownerCharId: 1,
        role: TechniqueRole.main,
        layer: CultivationLayer.chuKui,
        progress: 0,
        progressToNext: 100,
      );
      final r = DispelService.applyDefeatPenalty(
        ch: ch,
        mainTech: mainT,
        n: n,
      );
      expect(ch.internalForce, 50); // 内力仍按比例扣
      expect(mainT.cultivationProgress, 0);
      expect(mainT.cultivationLayer, CultivationLayer.chuKui);
      expect(mainT.cultivationProgressToNext, 100);
      expect(r.layersRolledBack, 0);
      expect(r.didRollback, isFalse);
    });

    test('单层回退：xiaoCheng/100 → progress=50 < chuKui→xiaoCheng req=100 → 回退 chuKui/50', () {
      final ch = newChar(internalForce: 1000);
      final mainT = newTech(
        id: 10,
        ownerCharId: 1,
        role: TechniqueRole.main,
        layer: CultivationLayer.xiaoCheng,
        progress: 100,
        progressToNext: 250,
      );
      final r = DispelService.applyDefeatPenalty(
        ch: ch,
        mainTech: mainT,
        n: n,
      );
      expect(mainT.cultivationLayer, CultivationLayer.chuKui);
      expect(mainT.cultivationProgress, 50);
      expect(mainT.cultivationProgressToNext, 100);
      expect(r.layersRolledBack, 1);
      expect(ch.internalForce, 500);
    });

    test('role 保持 main：DispelService.dispel 之后状态分叉对照', () {
      // 防回归：与 dispel 路径区别——defeat 后 mainTech 仍是 role=main，
      // wasMainBeforeReset=false，下次战斗仍以同本心法升修炼度。
      final ch = newChar(internalForce: 4000);
      final mainT = newTech(
        id: 10,
        ownerCharId: 1,
        role: TechniqueRole.main,
        layer: CultivationLayer.daCheng,
        progress: 900,
        progressToNext: 900,
      );
      DispelService.applyDefeatPenalty(ch: ch, mainTech: mainT, n: n);
      expect(mainT.role, TechniqueRole.main);
      // 再走一次 CultivationService.recordSkillUsage 验证升层逻辑能正常累积
      final r1 = CultivationService.recordSkillUsage(
        tech: mainT,
        skillId: 'skill_a',
        progressToNextMap: n.cultivationProgressToNext,
        delta: 5000,
      );
      expect(r1.didLevelUp, isTrue);
    });
  });
}
