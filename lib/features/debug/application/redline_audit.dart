import 'dart:math';

import '../../../core/domain/attributes.dart';
import '../../../core/domain/character.dart';
import '../../../core/domain/enums.dart';
import '../../../core/domain/equipment.dart';
import '../../../core/domain/forging_slot.dart';
import '../../../data/defs/equipment_def.dart';
import '../../../data/defs/skill_def.dart';
import '../../../data/defs/stage_def.dart';
import '../../../data/game_repository.dart';
import '../../../shared/strings.dart';
import '../../battle/domain/damage_calculator.dart';
import '../../battle/domain/derived_stats.dart';

enum RedlineAuditStatus { pass, warn, fail }

class RedlineAuditItem {
  final String id;
  final String label;
  final int observed;
  final int limit;
  final String source;
  final RedlineAuditStatus status;
  final String note;

  const RedlineAuditItem({
    required this.id,
    required this.label,
    required this.observed,
    required this.limit,
    required this.source,
    required this.status,
    required this.note,
  });

  int get headroom => limit - observed;
}

class RedlineAuditReport {
  final List<RedlineAuditItem> items;

  const RedlineAuditReport(this.items);

  bool get hasFail => items.any((i) => i.status == RedlineAuditStatus.fail);
  bool get hasWarn => items.any((i) => i.status == RedlineAuditStatus.warn);

  RedlineAuditStatus get status {
    if (hasFail) return RedlineAuditStatus.fail;
    if (hasWarn) return RedlineAuditStatus.warn;
    return RedlineAuditStatus.pass;
  }

  String toMarkdown() {
    final buf = StringBuffer()
      ..writeln(UiStrings.redlineAuditMdTitle)
      ..writeln()
      ..writeln(UiStrings.redlineAuditMdIntro)
      ..writeln()
      ..writeln(UiStrings.redlineAuditMdTableHeader)
      ..writeln('|---|---|---:|---:|---|');
    for (final item in items) {
      buf.writeln(
        '| ${item.label} | ${statusLabel(item.status)} | ${item.observed} | '
        '${item.limit} | ${item.source} |',
      );
    }
    buf.writeln();
    buf.writeln(UiStrings.redlineAuditMdNotesHeader);
    for (final item in items) {
      buf.writeln('- ${item.label}: ${item.note}');
    }
    return buf.toString();
  }
}

RedlineAuditStatus classifyRedline({
  required int observed,
  required int limit,
  double warnAtRatio = 0.9,
}) {
  if (observed > limit) return RedlineAuditStatus.fail;
  if (limit > 0 && observed >= (limit * warnAtRatio).floor()) {
    return RedlineAuditStatus.warn;
  }
  return RedlineAuditStatus.pass;
}

String statusLabel(RedlineAuditStatus status) => switch (status) {
  RedlineAuditStatus.pass => 'PASS',
  RedlineAuditStatus.warn => 'WARN',
  RedlineAuditStatus.fail => 'FAIL',
};

RedlineAuditReport buildRedlineAuditReport(GameRepository repo) {
  final red = repo.numbers.combat.redLines;
  final maxEquipmentAttack = _maxBy<EquipmentDef>(
    repo.equipmentDefs.values,
    valueOf: (e) => e.baseAttackMax,
  );
  final maxSkillPower = _maxBy<SkillDef>(
    repo.skillDefs.values,
    valueOf: (s) => s.powerMultiplier,
  );
  final maxBossHp = _maxBossHp(repo);
  final playerProbe = _measurePlayerExtremum(repo);
  final damageProbe = _measureDamageProbe(repo);

  return RedlineAuditReport([
    RedlineAuditItem(
      id: 'equipment_base_attack',
      label: UiStrings.redlineItemEquipmentAttack,
      observed: maxEquipmentAttack.value,
      limit: red.equipmentBaseAttackMax,
      source: 'equipment:${maxEquipmentAttack.source}',
      status: classifyRedline(
        observed: maxEquipmentAttack.value,
        limit: red.equipmentBaseAttackMax,
      ),
      note: UiStrings.redlineNoteEquipmentAttack,
    ),
    RedlineAuditItem(
      id: 'player_hp',
      label: UiStrings.redlineItemPlayerHp,
      observed: playerProbe.maxHp,
      limit: red.playerHpMax,
      source: playerProbe.hpSource,
      status: classifyRedline(
        observed: playerProbe.maxHp,
        limit: red.playerHpMax,
      ),
      note: UiStrings.redlineNotePlayerHp(repo.numbers.level.maxLevel),
    ),
    RedlineAuditItem(
      id: 'boss_hp',
      label: UiStrings.redlineItemBossHp,
      observed: maxBossHp.value,
      limit: red.bossHpMax,
      source: maxBossHp.source,
      status: classifyRedline(observed: maxBossHp.value, limit: red.bossHpMax),
      note: UiStrings.redlineNoteBossHp,
    ),
    RedlineAuditItem(
      id: 'internal_force',
      label: UiStrings.redlineItemInternalForce,
      observed: playerProbe.maxInternalForce,
      limit: red.internalForceMax,
      source: playerProbe.internalForceSource,
      status: classifyRedline(
        observed: playerProbe.maxInternalForce,
        limit: red.internalForceMax,
      ),
      note: UiStrings.redlineNoteInternalForce(repo.numbers.level.maxLevel),
    ),
    RedlineAuditItem(
      id: 'skill_power_multiplier',
      label: UiStrings.redlineItemSkillMultiplier,
      observed: maxSkillPower.value,
      limit: red.skillPowerMultiplierMax,
      source: 'skill:${maxSkillPower.source}',
      status: classifyRedline(
        observed: maxSkillPower.value,
        limit: red.skillPowerMultiplierMax,
      ),
      note: UiStrings.redlineNoteSkillMultiplier,
    ),
    RedlineAuditItem(
      id: 'normal_damage',
      label: UiStrings.redlineItemNormalDamage,
      observed: damageProbe.normalCrit,
      limit: red.damageReadabilityMax,
      source: damageProbe.normalSource,
      status: classifyRedline(
        observed: damageProbe.normalCrit,
        limit: red.damageReadabilityMax,
      ),
      note: UiStrings.redlineNoteNormalDamage(red.normalDamageTypicalTarget),
    ),
    RedlineAuditItem(
      id: 'ultimate_critical',
      label: UiStrings.redlineItemUltimateCrit,
      observed: damageProbe.ultimateCrit,
      limit: red.damageReadabilityMax,
      source: damageProbe.ultimateSource,
      status: classifyRedline(
        observed: damageProbe.ultimateCrit,
        limit: red.damageReadabilityMax,
      ),
      note: UiStrings.redlineNoteUltimateCrit,
    ),
  ]);
}

({int value, String source}) _maxBy<T>(
  Iterable<T> items, {
  required int Function(T item) valueOf,
}) {
  T? best;
  var bestValue = 0;
  for (final item in items) {
    final value = valueOf(item);
    if (best == null || value > bestValue) {
      best = item;
      bestValue = value;
    }
  }
  return (value: bestValue, source: _sourceId(best));
}

String _sourceId(Object? item) {
  if (item == null) return '-';
  if (item is EquipmentDef) return item.id;
  if (item is SkillDef) return item.id;
  return item.toString();
}

({int value, String source}) _maxBossHp(GameRepository repo) {
  var best = 0;
  var source = '-';

  void visit(String prefix, Iterable<EnemyDef> enemies) {
    for (final e in enemies) {
      if (e.isBoss && e.baseHp > best) {
        best = e.baseHp;
        source = '$prefix:${e.id}';
      }
    }
  }

  for (final stage in repo.stageDefs.values) {
    visit('stage:${stage.id}', stage.enemyTeam);
  }
  for (final floor in repo.towerFloors) {
    visit('tower:${floor.floorIndex}', floor.enemyTeam);
  }
  return (value: best, source: source);
}

({int maxHp, String hpSource, int maxInternalForce, String internalForceSource})
_measurePlayerExtremum(GameRepository repo) {
  var hp = 0;
  var hpSource = '-';
  var internalForce = 0;
  var internalForceSource = '-';

  for (final tier in RealmTier.values) {
    final built = _buildExtremumCharacter(repo, tier);
    built.character
      ..level = repo.numbers.level.maxLevel
      ..isFounder = true;
    final currentHp = CharacterDerivedStats.maxHp(
      built.character,
      built.equipped,
      repo.numbers,
      founderBuffActive: true,
    );
    final currentInternalForce =
        CharacterDerivedStats.internalForceMaxWithLineage(
          built.character,
          built.equipped,
          repo.numbers,
          founderBuffActive: true,
        );
    if (currentHp > hp) {
      hp = currentHp;
      hpSource = 'player_extreme:${tier.name}';
    }
    if (currentInternalForce > internalForce) {
      internalForce = currentInternalForce;
      internalForceSource = 'player_extreme:${tier.name}';
    }
  }

  return (
    maxHp: hp,
    hpSource: hpSource,
    maxInternalForce: internalForce,
    internalForceSource: internalForceSource,
  );
}

({Character character, List<Equipment> equipped}) _buildExtremumCharacter(
  GameRepository repo,
  RealmTier tier,
) {
  final realmDef = repo.getRealm(tier, RealmLayer.dengFeng);
  final eqTier = realmDef.equipmentTierCap;

  EquipmentDef defOf(EquipmentSlot slot) => repo.equipmentDefs.values
      .firstWhere((d) => d.tier == eqTier && d.slot == slot);

  Equipment buildEq(EquipmentSlot slot) {
    final def = defOf(slot);
    return Equipment.create(
      defId: def.id,
      tier: def.tier,
      slot: def.slot,
      obtainedAt: DateTime(2026, 6, 27),
      obtainedFrom: 'redline_audit',
      baseHealth: def.baseHealthMax,
    );
  }

  final character = Character.create(
    name: 'redline_${tier.name}',
    realmTier: tier,
    realmLayer: RealmLayer.dengFeng,
    attributes: Attributes()
      ..constitution = 10
      ..enlightenment = 10
      ..agility = 10
      ..fortune = 10,
    rarity: RarityTier.jueShi,
    lineageRole: LineageRole.disciple,
    createdAt: DateTime(2026, 6, 27),
    internalForce: realmDef.internalForceMax,
    internalForceMax: realmDef.internalForceMax,
  );

  return (
    character: character,
    equipped: [
      buildEq(EquipmentSlot.weapon),
      buildEq(EquipmentSlot.armor),
      buildEq(EquipmentSlot.accessory),
    ],
  );
}

({int normalCrit, String normalSource, int ultimateCrit, String ultimateSource})
_measureDamageProbe(GameRepository repo) {
  final normalSkill = _maxSkillByType(repo, SkillType.normalAttack);
  final ultimateSkill = _maxSkillByType(repo, SkillType.ultimate);
  final totalEqAtk = _maxDamageProbeEquipmentAttack(repo);

  int calc(SkillDef skill) => DamageCalculator.calculateResolved(
    attackerInternalForce: repo.numbers.combat.redLines.internalForceMax,
    attackerEquipmentAttack: totalEqAtk,
    attackerCultivationLayer: CultivationLayer.jiJing,
    attackerSchool: TechniqueSchool.gangMeng,
    defenderSchool: TechniqueSchool.yinRou,
    attackerRealmTier: RealmTier.wuSheng,
    attackerRealmLayer: RealmLayer.dengFeng,
    defenderRealmTier: RealmTier.wuSheng,
    defenderRealmLayer: RealmLayer.dengFeng,
    defenderDefenseRate: repo.numbers.defenseRateByTier[RealmTier.wuSheng]!,
    defenderEvasionRate: 0,
    attackerCriticalRate: 1,
    attackPowerMultiplier: 1,
    skill: skill,
    n: repo.numbers,
    rng: Random(7),
    forceCritical: true,
  ).mainDamage;

  return (
    normalCrit: calc(normalSkill),
    normalSource: 'damage_probe:${normalSkill.id}',
    ultimateCrit: calc(ultimateSkill),
    ultimateSource: 'damage_probe:${ultimateSkill.id}',
  );
}

SkillDef _maxSkillByType(GameRepository repo, SkillType type) {
  return repo.skillDefs.values
      .where((s) => s.type == type)
      .reduce((a, b) => a.powerMultiplier >= b.powerMultiplier ? a : b);
}

int _maxDamageProbeEquipmentAttack(GameRepository repo) {
  Equipment buildEq(EquipmentDef def) => Equipment.create(
    defId: def.id,
    tier: def.tier,
    slot: def.slot,
    obtainedAt: DateTime(2026, 6, 27),
    obtainedFrom: 'redline_audit_damage_probe',
    baseAttack: def.baseAttackMax,
    enhanceLevel: 49,
    battleCount: 1000000,
    forgingSlots: [
      ForgingSlot()
        ..slotIndex = 1
        ..type = ForgingSlotType.attack
        ..unlocked = true
        ..bonusValue = 15,
      ForgingSlot()
        ..slotIndex = 2
        ..type = ForgingSlotType.attack
        ..unlocked = true
        ..bonusValue = 20,
    ],
  );

  var total = 0;
  for (final slot in [EquipmentSlot.weapon, EquipmentSlot.accessory]) {
    final def = repo.equipmentDefs.values
        .where((d) => d.tier == EquipmentTier.shenWu && d.slot == slot)
        .reduce((a, b) => a.baseAttackMax >= b.baseAttackMax ? a : b);
    total += CharacterDerivedStats.effectiveEquipmentAttack(
      buildEq(def),
      repo.numbers,
    );
  }
  return total;
}
