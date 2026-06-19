import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/battle/domain/battle_state.dart';
import 'package:wuxia_idle/core/domain/attributes.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/domain/technique.dart';
import 'package:wuxia_idle/data/game_repository.dart';

/// 第七阶段批三 Task10: BattleCharacter.lineageRole 字段透传验证。
///
/// 覆盖:
/// 1. fromCharacter 将 Character.lineageRole 透传到 BattleCharacter.lineageRole。
/// 2. 直接构造(无 lineageRole 参数,敌人/NPC 路径)→ lineageRole == null。
/// 3. copyWith 不传 lineageRole → 保留原值;传入新值 → 覆盖。

// ─── 最小 BattleCharacter fixture(直接构造) ─────────────────────────────────

BattleCharacter _bareCharacter() => const BattleCharacter(
      characterId: 99,
      name: 'npc',
      realmTier: RealmTier.sanLiu,
      realmLayer: RealmLayer.yuanShu,
      school: TechniqueSchool.gangMeng,
      maxHp: 1000,
      currentHp: 1000,
      maxInternalForce: 500,
      currentInternalForce: 500,
      speed: 100,
      criticalRate: 0.05,
      evasionRate: 0.0,
      defenseRate: 0.1,
      totalEquipmentAttack: 0,
      mainCultivationLayer: CultivationLayer.daCheng,
      availableSkills: [],
      skillCooldowns: {},
      activeBuffs: [],
      actionPoint: 0,
      isAlive: true,
      teamSide: 1,
      slotIndex: 0,
      // lineageRole 不传 → 默认 null
    );

// ─── fromCharacter 所需最小 fixture ──────────────────────────────────────────

Character _mkChar({LineageRole role = LineageRole.junior}) {
  final attrs = Attributes()
    ..constitution = 5
    ..enlightenment = 5
    ..agility = 5
    ..fortune = 5;
  return Character.create(
    name: '测试弟子',
    realmTier: RealmTier.xueTu,
    realmLayer: RealmLayer.ruMen,
    attributes: attrs,
    rarity: RarityTier.biaoZhun,
    lineageRole: role,
    createdAt: DateTime(2026, 1, 1),
    internalForce: 100,
    school: TechniqueSchool.gangMeng,
  );
}

Technique _mkTech() {
  return Technique.create(
    defId: 'tech_gangmeng_jichu',
    ownerCharacterId: 1,
    tier: TechniqueTier.ruMenGong,
    school: TechniqueSchool.gangMeng,
    role: TechniqueRole.main,
    learnedAt: DateTime(2026, 1, 1),
    cultivationLayer: CultivationLayer.chuKui,
  );
}

Future<String> _fileLoader(String path) async {
  final f = File(path);
  if (!await f.exists()) throw FileSystemException('不存在', path);
  return f.readAsString();
}

void main() {
  group('BattleCharacter lineageRole 字段透传', () {
    setUp(() async {
      await GameRepository.loadAllDefs(loader: _fileLoader);
    });
    tearDown(GameRepository.resetForTest);

    test('直接构造 / 敌人路径: lineageRole 缺省为 null', () {
      final bc = _bareCharacter();
      expect(bc.lineageRole, isNull,
          reason: '敌人/NPC 直接构造不传 lineageRole → 必须为 null');
    });

    test('fromCharacter 透传 junior → BattleCharacter.lineageRole == junior', () {
      final char = _mkChar(role: LineageRole.junior);
      final tech = _mkTech();
      final bc = BattleCharacter.fromCharacter(
        character: char,
        equipped: const [],
        mainTechnique: tech,
        numbers: GameRepository.instance.numbers,
        teamSide: 0,
        slotIndex: 1,
      );
      expect(bc.lineageRole, LineageRole.junior,
          reason: 'fromCharacter 应将 Character.lineageRole 透传');
    });

    test('fromCharacter 透传 senior → BattleCharacter.lineageRole == senior', () {
      final char = _mkChar(role: LineageRole.senior);
      final tech = _mkTech();
      final bc = BattleCharacter.fromCharacter(
        character: char,
        equipped: const [],
        mainTechnique: tech,
        numbers: GameRepository.instance.numbers,
        teamSide: 0,
        slotIndex: 0,
      );
      expect(bc.lineageRole, LineageRole.senior);
    });

    test('copyWith 不传 lineageRole → 保留原值', () {
      final bc = _bareCharacter().copyWith(lineageRole: LineageRole.junior);
      final copied = bc.copyWith(speed: 200);
      expect(copied.lineageRole, LineageRole.junior,
          reason: 'copyWith 不传 lineageRole 时应保留 this.lineageRole');
    });

    test('copyWith 传入新 lineageRole → 覆盖', () {
      final bc = _bareCharacter().copyWith(lineageRole: LineageRole.junior);
      final overridden = bc.copyWith(lineageRole: LineageRole.senior);
      expect(overridden.lineageRole, LineageRole.senior,
          reason: 'copyWith 传入新值时应覆盖旧值');
    });

  });
}
