import 'package:isar_community/isar.dart';

import '../../../data/numbers_config.dart';
import '../domain/npc_relation.dart';

/// NPC 关系服务(P1.2 §3 · GDD §12.1 江湖恩怨)。
///
/// 设计纪律:
/// - 稀疏表(Q2=B):仅存有显式关系的 (source, target) pair · 默认 noop = 1.0
/// - 单向 source→target:互害需 caller 双写
/// - level [-100, +100]:enmity 阈值由 numbers.yaml.jianghu.enmity_combat_modifier 控
/// - upsert 走 writeTxn · attackPowerMultFor 读路径不写 Isar
class NpcRelationService {
  final Isar isar;
  final NumbersConfig numbers;

  NpcRelationService(this.isar, this.numbers);

  /// upsert 单条关系(同 (source, target) 已存在则更新 type/level,不存在则新建)。
  Future<void> upsert({
    required int sourceCharacterId,
    required int targetCharacterId,
    required String type,
    required int level,
  }) async {
    await isar.writeTxn(() async {
      final existing = await isar.npcRelations
          .filter()
          .sourceCharacterIdEqualTo(sourceCharacterId)
          .targetCharacterIdEqualTo(targetCharacterId)
          .findFirst();
      if (existing == null) {
        final r = NpcRelation()
          ..sourceCharacterId = sourceCharacterId
          ..targetCharacterId = targetCharacterId
          ..type = type
          ..level = level.clamp(-100, 100)
          ..updatedAt = DateTime.now();
        await isar.npcRelations.put(r);
      } else {
        existing.type = type;
        existing.level = level.clamp(-100, 100);
        existing.updatedAt = DateTime.now();
        await isar.npcRelations.put(existing);
      }
    });
  }

  /// 拉 source 对各 NPC 的所有 foe 关系且 level ≤ threshold(默认走 yaml 配置)。
  /// level 字段未 @Index(稀疏表 cardinality 低,Dart 端 filter 足够),走 in-memory 过滤。
  Future<List<NpcRelation>> enmityAgainst(int sourceCharacterId) async {
    final threshold = numbers.jianghu.enmityCombatModifier.threshold;
    final foes = await isar.npcRelations
        .filter()
        .sourceCharacterIdEqualTo(sourceCharacterId)
        .typeEqualTo('foe')
        .findAll();
    return foes.where((r) => r.level <= threshold).toList(growable: false);
  }

  /// 拉指定 source 全部关系(UI panel 用)。
  Future<List<NpcRelation>> allFor(int sourceCharacterId) async {
    return isar.npcRelations
        .filter()
        .sourceCharacterIdEqualTo(sourceCharacterId)
        .findAll();
  }

  /// 战斗 attackPower mult 三档(spec §5):
  /// - level ≤ severe_threshold(-80)→ severe_mult(1.25)
  /// - level ≤ threshold(-50)→ player_attack_power_mult(1.15)
  /// - 其余 / 无关系 → 1.0
  ///
  /// clamp 上限 ≤ clamp_max(防 yaml 配错越 §5.4 红线)。
  Future<double> attackPowerMultFor(
    int sourceCharacterId,
    int targetCharacterId,
  ) async {
    final rel = await isar.npcRelations
        .filter()
        .sourceCharacterIdEqualTo(sourceCharacterId)
        .targetCharacterIdEqualTo(targetCharacterId)
        .findFirst();
    if (rel == null) return 1.0;
    final emc = numbers.jianghu.enmityCombatModifier;
    double mult;
    if (rel.level <= emc.severeThreshold) {
      mult = emc.severeMult;
    } else if (rel.level <= emc.threshold) {
      mult = emc.playerAttackPowerMult;
    } else {
      mult = 1.0;
    }
    return mult > emc.clampMax ? emc.clampMax : mult;
  }
}
