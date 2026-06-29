import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/defs/drop_entry.dart';
import 'package:wuxia_idle/data/defs/stage_def.dart';
import 'package:wuxia_idle/features/mainline/application/mainline_progress_service.dart';
import 'package:wuxia_idle/features/mainline/application/new_save_goal_guidance.dart';

void main() {
  StageDef stage(
    String id, {
    bool boss = false,
    List<DropEntry> dropTable = const [],
    String? dropSkillManualId,
  }) {
    return StageDef(
      id: id,
      name: id,
      stageType: StageType.mainline,
      chapterIndex: 1,
      requiredRealm: RealmTier.xueTu,
      enemyTeam: const [],
      isBossStage: boss,
      dropTable: dropTable,
      dropSkillManualId: dropSkillManualId,
      baseExpReward: 100,
      difficultyMultiplier: 1,
    );
  }

  test('fromChapterEntries 选择第一条 available 关卡', () {
    final entries = <StageEntry>[
      (def: stage('stage_01_01'), status: StageStatus.cleared),
      (
        def: stage(
          'stage_01_02',
          dropTable: const [
            EquipmentDrop(
              equipmentDefId: 'weapon_xunchang_tie_jian',
              dropChance: 1,
            ),
          ],
        ),
        status: StageStatus.available,
      ),
      (def: stage('stage_01_03'), status: StageStatus.available),
    ];

    final guidance = NewSaveGoalGuidance.fromChapterEntries(
      chapterIndex: 1,
      entries: entries,
    );

    expect(guidance, isNotNull);
    expect(guidance!.stage.id, 'stage_01_02');
    expect(guidance.stageIndex, 2);
    expect(guidance.reason, NewSaveGoalReason.getEquipment);
  });

  test('Boss 和掉招关优先给推进理由', () {
    final bossGuidance = NewSaveGoalGuidance.fromStage(
      chapterIndex: 1,
      stageIndex: 5,
      stage: stage('stage_01_05', boss: true),
    );
    final skillGuidance = NewSaveGoalGuidance.fromStage(
      chapterIndex: 2,
      stageIndex: 5,
      stage: stage(
        'stage_02_05',
        boss: true,
        dropSkillManualId: 'skill_qingshan_qingfeng',
      ),
    );

    expect(bossGuidance.reason, NewSaveGoalReason.firstClearBoss);
    expect(skillGuidance.reason, NewSaveGoalReason.learnSkill);
  });

  test('纯物品掉落关给材料理由；无可挑战关返回 null', () {
    final materialGuidance = NewSaveGoalGuidance.fromStage(
      chapterIndex: 1,
      stageIndex: 1,
      stage: stage(
        'stage_01_01',
        dropTable: const [
          ItemDrop(
            inventoryItemDefId: 'item_mojianshi',
            quantityMin: 1,
            quantityMax: 1,
            dropChance: 1,
          ),
        ],
      ),
    );
    final none = NewSaveGoalGuidance.fromChapterEntries(
      chapterIndex: 1,
      entries: [(def: stage('stage_01_01'), status: StageStatus.locked)],
    );

    expect(materialGuidance.reason, NewSaveGoalReason.gatherMaterial);
    expect(none, isNull);
  });
}
