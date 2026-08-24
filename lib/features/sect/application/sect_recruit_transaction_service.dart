import 'package:isar_community/isar.dart';

import '../../../core/domain/attributes.dart';
import '../../../core/domain/character.dart';
import '../../../core/domain/enums.dart';
import '../../../data/defs/sect_candidate_def.dart';
import '../../../data/game_repository.dart';
import '../domain/sect.dart';
import 'sect_member_service.dart';

enum SectRecruitTransactionResult { success, fullCap }

/// 门派招收的 transaction-owned 写入口。
///
/// caller 必须持有 `isar.writeTxn`。默认门派初始化、候选角色创建、入派与
/// 满员清理全部留在同一事务，供主线 pending affair claim 原子组合。
class SectRecruitTransactionService {
  const SectRecruitTransactionService(this.isar);

  final Isar isar;

  Future<Sect> ensureDefaultSectInTxn({
    required String defaultSectName,
    required DateTime now,
  }) async {
    final existing = await isar.sects.get(1);
    if (existing != null) return existing;
    final sect = Sect()
      ..id = 1
      ..name = defaultSectName
      ..founderId = 1
      ..sectLevel = 1
      ..sectReputation = 50
      ..totalWins = 0
      ..memberCount = 0
      ..territoryIds = []
      ..createdAt = now
      ..lastEventAt = null;
    await isar.sects.put(sect);
    return sect;
  }

  Future<SectRecruitTransactionResult> recruitInTxn({
    required SectCandidateDef candidate,
    required String defaultSectName,
    required DateTime now,
  }) async {
    final repo = GameRepository.instance;
    final sect = await ensureDefaultSectInTxn(
      defaultSectName: defaultSectName,
      now: now,
    );

    final realmDef = repo.getRealm(
      candidate.defaultRealm,
      candidate.defaultLayer,
    );
    final newCharacter = Character.create(
      name: candidate.name,
      realmTier: candidate.defaultRealm,
      realmLayer: candidate.defaultLayer,
      attributes: Attributes()
        ..constitution = candidate.attributeProfile.constitution
        ..enlightenment = candidate.attributeProfile.enlightenment
        ..agility = candidate.attributeProfile.agility
        ..fortune = candidate.attributeProfile.fortune,
      rarity: repo.numbers.rarityForTotalPoints(
        candidate.attributeProfile.total,
      ),
      lineageRole: LineageRole.disciple,
      isFounder: false,
      isActive: false,
      createdAt: now,
      school: candidate.school,
      internalForce: realmDef.internalForceMax,
      internalForceMax: realmDef.internalForceMax,
      experienceToNextLayer: realmDef.experienceToNext,
      portraitPath: candidate.portraitPath,
    );
    await isar.characters.put(newCharacter);

    final result = await SectMemberService(isar).recruit(
      targetCharacterId: newCharacter.id,
      sectId: sect.id,
      numbers: repo.numbers,
    );
    switch (result) {
      case RecruitResult.success:
        return SectRecruitTransactionResult.success;
      case RecruitResult.fullCap:
        await isar.characters.delete(newCharacter.id);
        return SectRecruitTransactionResult.fullCap;
      case RecruitResult.alreadyInSect:
      case RecruitResult.sectNotFound:
      case RecruitResult.targetNotFound:
        throw StateError(
          'Unexpected transaction-owned recruit result: $result',
        );
    }
  }
}
