import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/shared/strings.dart';

void main() {
  test('正式界面统一使用首领，不混入 Boss', () {
    final playerFacingBossTexts = <String>[
      UiStrings.surrenderConfirmMessage,
      UiStrings.combatTermGloss(CombatTerm.phase),
      UiStrings.diagCauseCharge,
      UiStrings.diagCauseGuardianWard,
      UiStrings.diagGuardianWardDamageTaken(25),
      UiStrings.diagSuggestGuardianWard,
      UiStrings.mainlineRouteMapSubtitle,
      UiStrings.mainlineRouteBoss,
      UiStrings.stageListBoss,
      UiStrings.mainMenuTowerBossStatus(4, 5),
      UiStrings.towerBossMinor,
      UiStrings.towerBossMajor,
      UiStrings.towerMilestoneSummitBoss,
      UiStrings.towerSpineLegend,
      UiStrings.towerFirstClearCeremony(5, isBoss: true),
      UiStrings.equipmentSourceMainline(1, '黑风寨', true),
      UiStrings.equipmentSourceStage('试剑台', true),
      UiStrings.equipmentSourceTower(5, true),
      UiStrings.skillTreasureManualHint,
    ];

    for (final text in playerFacingBossTexts) {
      expect(text, isNot(contains('Boss')), reason: text);
      expect(text, contains('首领'), reason: text);
    }
  });

  test('等级缩写统一为 LvN', () {
    expect(UiStrings.profileLevelValue(12), 'Lv12');
    expect(UiStrings.profileCultivationLevel(12), 'Lv12');
    expect(UiStrings.taohuaIslandSceneHotspotMeta(12, 3), 'Lv12 · 3');
  });

  test('存档摘要不泄漏英文槽位和版本前缀', () {
    final summary = UiStrings.saveManagementSummary(2, '0.26.0', 3);
    expect(summary, '槽位 2 · 版本 0.26.0 · 3 个备份');
    expect(summary, isNot(contains('slot')));
  });

  test('奇遇招式失败提示不泄漏内部标识和异常', () {
    final messages = <String>[
      UiStrings.encounterSkillNotEncounterSkill('skill_debug_internal'),
      UiStrings.encounterSkillCharacterMissing(991),
      UiStrings.encounterSkillDefMissing('skill_missing_internal'),
      UiStrings.encounterSkillEquipFailed(
        StateError('database stack with internal path'),
      ),
      UiStrings.encounterSkillUnequipFailed(
        StateError('database stack with internal path'),
      ),
    ];

    for (final message in messages) {
      expect(message, isNot(contains('skill_')), reason: message);
      expect(message, isNot(contains('991')), reason: message);
      expect(message, isNot(contains('StateError')), reason: message);
      expect(message, isNot(contains('internal')), reason: message);
    }
    expect(UiStrings.encounterSkillTierLocked(4, '二流'), '境界不足：需第 4 阶，当前 二流');
  });

  test('正式界面使用招式且真实时长不缩写', () {
    final playerFacingSkillTexts = <String>[
      UiStrings.battleEmptySkillSlot,
      UiStrings.skillInfoTapHint,
      UiStrings.diagSuggestDps,
      UiStrings.diagSuggestGeneric,
      UiStrings.diagJumpSkills,
      UiStrings.forgingSpecialSkillPickerTitle,
      UiStrings.forgingSpecialSkillLabel('试剑诀'),
      UiStrings.sweepTowerRepeatNote,
    ];
    for (final text in playerFacingSkillTexts) {
      expect(text, isNot(contains('技能')), reason: text);
      expect(text, contains('招式'), reason: text);
    }
    final playerFacingDurations = <String>[
      UiStrings.durationHoursMinutes(79, 0),
      UiStrings.retreatRemainingText(2, 15),
      UiStrings.seclusionMapActiveRemainingHint(125),
      UiStrings.gameEventRetreatSummary('无名客', 8, '藏经阁'),
      UiStrings.taohuaIslandDuration(2),
      UiStrings.expeditionRemainingText(3, 20),
      UiStrings.activeRetreatTimeRange('10:00', '18:00', 8),
      UiStrings.activeRetreatElapsed('8.0 小时'),
      UiStrings.conditionInnerDemonResidueRecovery(5.2),
      UiStrings.injuryRecoveryHint(5.2),
      UiStrings.taohuaIslandStatusHealingValue(2, 5.2),
    ];
    for (final text in playerFacingDurations) {
      expect(text, isNot(contains(RegExp(r'\d+\s*h|\d+\s*min'))), reason: text);
      expect(text, isNot(contains(' 时')), reason: text);
      expect(text, contains('小时'), reason: text);
    }
    expect(UiStrings.seclusionExpected('磨剑石', 1.5), contains('/ 小时'));
    expect(UiStrings.seclusionMapEventHour(12), '第 12 小时');
    expect(
      UiStrings.combatTermGloss(CombatTerm.heavyInjury, hours: 3),
      contains('3 小时'),
    );
  });

  test('相近词保留系统边界', () {
    expect(UiStrings.cycleNthLabel(2), contains('周目'));
    expect(UiStrings.towerCurrentCycleLabel(2), contains('轮回'));
    expect(UiStrings.offlineRecapAwayLine(8), contains('小时'));
  });
}
