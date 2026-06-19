import 'package:isar_community/isar.dart';

import '../../../core/domain/character.dart';
import '../../../core/domain/save_data.dart';
import '../../../data/game_repository.dart';
import '../../../data/numbers_config.dart';
import '../../../shared/utils/rng.dart';
import '../../onboarding/application/master_builder.dart';

/// 第七阶段批三 · 渐进解锁:过 join 触发关后懒创建对应命名弟子并入队。
///
/// 防重双保险:① [SaveData.triggeredDiscipleJoinStageIds](一次性,重战不触发);
/// ② 该 role 命名弟子已存在则不重建(防御边缘:迁移防重集丢失 / 未来 boot 顺序回归)。
class DiscipleJoinService {
  DiscipleJoinService({required this.isar});
  final Isar isar;

  /// 若 [clearedStageId] 是某弟子拜入触发关且未触发过且该弟子尚不存在,
  /// 懒创建弟子并入队,返回新弟子;否则返回 null。
  Future<Character?> joinForClearedStage(
    String clearedStageId, {
    DateTime? at,
  }) async {
    final repo = GameRepository.instance;
    final cfg = repo.numbers.lineageOnboarding;
    DiscipleJoinDef? join;
    for (final j in cfg.discipleJoins) {
      if (j.stageId == clearedStageId) {
        join = j;
        break;
      }
    }
    if (join == null) return null;

    final save = await isar.saveDatas.get(0);
    if (save == null) return null;
    if (save.triggeredDiscipleJoinStageIds.contains(clearedStageId)) return null;

    // 防御:该 role 命名弟子已存在(迁移老档 / 边缘)→ 不重建,但补标记防重。
    final existingSameRole = await isar.characters
        .filter()
        .lineageRoleEqualTo(join.role)
        .findFirst();
    if (existingSameRole != null) {
      await isar.writeTxn(() async {
        final s = await isar.saveDatas.get(0);
        if (s != null &&
            !s.triggeredDiscipleJoinStageIds.contains(clearedStageId)) {
          s.triggeredDiscipleJoinStageIds = [
            ...s.triggeredDiscipleJoinStageIds,
            clearedStageId,
          ];
          await isar.saveDatas.put(s);
        }
      });
      return null;
    }

    final masters = repo.masters;
    if (join.masterSlotIndex >= masters.length) return null;
    final def = masters[join.masterSlotIndex];
    final now = at ?? DateTime.now();
    final rng = DefaultRng();

    Character? created;
    await isar.writeTxn(() async {
      final disciple = buildMasterCharacter(def, now: now); // lineageRole 来自 masters.yaml
      await isar.characters.put(disciple);
      await equipMasterStarting(
        isar,
        character: disciple,
        defIds: def.startingEquipmentIds,
        rng: rng,
        now: now,
      );
      await learnMasterStarting(
        isar,
        character: disciple,
        techDefIds: def.startingTechniqueIds,
        now: now,
      );

      final founderId = save.founderCharacterId;
      if (founderId != null) {
        disciple.masterId = founderId;
        final founder = await isar.characters.get(founderId);
        if (founder != null) {
          founder.discipleIds = [...founder.discipleIds, disciple.id];
          await isar.characters.put(founder);
        }
      }
      await isar.characters.put(disciple);

      // 事务内重读 save,避免 stale 快照覆盖并发写。
      final freshSave = await isar.saveDatas.get(0) ?? save;
      freshSave.activeCharacterIds = [
        ...freshSave.activeCharacterIds,
        disciple.id,
      ];
      freshSave.triggeredDiscipleJoinStageIds = [
        ...freshSave.triggeredDiscipleJoinStageIds,
        clearedStageId,
      ];
      await isar.saveDatas.put(freshSave);
      created = disciple;
    });
    return created;
  }
}
