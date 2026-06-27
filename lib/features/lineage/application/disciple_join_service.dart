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

  /// 若 [clearedStageId] 命中一条或多条弟子拜入触发条目且该关未触发过,
  /// 按配置顺序逐条懒创建尚不存在的弟子并入队,返回新建弟子列表(可能 0-2 人)。
  ///
  /// 关级防重标记 [SaveData.triggeredDiscipleJoinStageIds] 在**遍历完所有匹配后**
  /// 一次性写入:同一关多条 join 时,senior 拜入不能先标记该关把 junior 挡掉。
  Future<List<Character>> joinForClearedStage(
    String clearedStageId, {
    DateTime? at,
  }) async {
    final repo = GameRepository.instance;
    final matches = repo.numbers.lineageOnboarding.discipleJoins
        .where((j) => j.stageId == clearedStageId)
        .toList();
    if (matches.isEmpty) return const <Character>[];

    final save = await isar.saveDatas.get(0);
    if (save == null) return const <Character>[];
    // 关级防重:该关已触发过 → 整关跳过(重战不再拜入)。
    if (save.triggeredDiscipleJoinStageIds.contains(clearedStageId)) {
      return const <Character>[];
    }

    final created = <Character>[];
    for (final join in matches) {
      final c = await _createDiscipleIfAbsent(join, at: at);
      if (c != null) created.add(c);
    }

    // 遍历完所有匹配后,一次性标记该关已触发(角色级防重已在 _createDiscipleIfAbsent 内)。
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
    return created;
  }

  /// 单条 join:角色级防重(该 role 弟子已存在 → 返回 null 不重建),否则懒创建入队。
  /// **不**在此标记关级防重(由 [joinForClearedStage] 遍历后统一标记)。
  Future<Character?> _createDiscipleIfAbsent(
    DiscipleJoinDef join, {
    DateTime? at,
  }) async {
    // 角色级防重:该 role 命名弟子已存在(旧档祖年化 / 迁移边缘)→ 不重建。
    final existingSameRole = await isar.characters
        .filter()
        .lineageRoleEqualTo(join.role)
        .findFirst();
    if (existingSameRole != null) return null;

    final repo = GameRepository.instance;
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

      final save = await isar.saveDatas.get(0);
      if (save == null) return;
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

      // 事务内重读 save,避免 stale 快照覆盖并发写(多弟子顺序 append)。
      final freshSave = await isar.saveDatas.get(0) ?? save;
      freshSave.activeCharacterIds = [
        ...freshSave.activeCharacterIds,
        disciple.id,
      ];
      await isar.saveDatas.put(freshSave);
      created = disciple;
    });
    return created;
  }
}
