import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';

import '../../../core/domain/attributes.dart';
import '../../../core/domain/character.dart';
import '../../../core/domain/enums.dart';
import '../../../data/defs/sect_candidate_def.dart';
import '../../../data/game_repository.dart';
import '../../encounter/presentation/sect_recruit_confirm_dialog.dart';
import '../application/sect_member_service.dart';
import '../domain/sect.dart';
import '../../../shared/strings.dart';

/// P4.1 1.1 Q6A/Q6B 共用 · sect NPC 招降 flow handler 抽自 `encounter_hook._handleSectRecruit:174`(spec
/// `p4_1_q6b_stage_boss_recruit_spec_2026-05-26.md` §3.1)。
///
/// **caller 解耦语义** — Q6A encounter recruit 调 `EncounterService.markTriggered` +
/// `EncounterService.applyOutcome` fallback;Q6B stage_boss recruit 调
/// `SaveData.triggeredBossRecruitStageIds writeTxn` + onFallback=null 静默。
enum SectRecruitOutcome {
  /// 招收成功 · `SectMemberService.recruit` 返 success · markTriggered + SnackBar
  success,

  /// 门派人数已满 · fallback + SnackBar · **不 markTriggered**(玩家可重战重遇)
  capFull,

  /// 玩家 confirm dialog 婉拒 · fallback · **不 markTriggered**(玩家可重战重遇)
  declined,

  /// Sect lazy-init 失败(极端 race · 理论不命中)· SnackBar · **不 markTriggered**
  noSect,

  /// 其他 SectMemberService.recruit 失败(targetNotFound / alreadyInSect / sectNotFound)
  unexpectedFail,
}

/// 执行 sect NPC 招收完整 flow:
///   1. Sect lazy-init(get(1) == null → put 默认 sect · 沿 sect_providers `_defaultSect`)
///   2. `showSectRecruitConfirmDialog` 二次确认(Q4=C)
///   3. 玩家取消 → onFallback(可空 · null = 静默)+ 返 declined
///   4. 玩家确认 → isar.writeTxn { Character.create + SectMemberService.recruit }
///      - success → onMarkTriggered + SnackBar 成功 + 返 success
///      - fullCap → 回滚 newChar.delete + onFallback + SnackBar cap full + 返 capFull
///      - 其他 fail → debugPrint + 返 unexpectedFail
Future<SectRecruitOutcome> runSectRecruitFlow({
  required BuildContext context,
  required WidgetRef ref,
  required Isar isar,
  required SectCandidateDef candidate,
  required Future<void> Function() onMarkTriggered,
  required Future<void> Function()? onFallback,
  required String successSnackBar,
  required String capFullSnackBar,
  required String noSectSnackBar,
}) async {
  final repo = GameRepository.instance;

  // 1. Sect lazy-init(spec §3 R3 修)
  var sect = await isar.sects.get(1);
  if (sect == null) {
    final freshSect = Sect()
      ..id = 1
      ..name = UiStrings.sectLazyInitName
      ..founderId = 1
      ..sectLevel = 1
      ..sectReputation = 50
      ..totalWins = 0
      ..createdAt = DateTime.now()
      ..lastEventAt = null;
    await isar.writeTxn(() => isar.sects.put(freshSect));
    sect = await isar.sects.get(1);
  }
  if (sect == null) {
    if (!context.mounted) return SectRecruitOutcome.noSect;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(noSectSnackBar)));
    return SectRecruitOutcome.noSect;
  }
  final playerSectId = sect.id;

  // 2. confirm dialog
  if (!context.mounted) return SectRecruitOutcome.declined;
  final confirmed = await showSectRecruitConfirmDialog(context, candidate);

  if (!confirmed) {
    if (onFallback != null) await onFallback();
    return SectRecruitOutcome.declined;
  }

  // 3. 招收 isar.writeTxn(caller 持锁体例)
  final realmDef =
      repo.getRealm(candidate.defaultRealm, candidate.defaultLayer);
  final now = DateTime.now();
  RecruitResult? result;
  int? newCharId;
  await isar.writeTxn(() async {
    final newChar = Character.create(
      name: candidate.name,
      realmTier: candidate.defaultRealm,
      realmLayer: candidate.defaultLayer,
      attributes: Attributes()
        ..constitution = candidate.attributeProfile.constitution
        ..enlightenment = candidate.attributeProfile.enlightenment
        ..agility = candidate.attributeProfile.agility
        ..fortune = candidate.attributeProfile.fortune,
      rarity: RarityTier.biaoZhun,
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
    await isar.characters.put(newChar);
    newCharId = newChar.id;

    final memberSvc = SectMemberService(isar);
    result = await memberSvc.recruit(
      targetCharacterId: newChar.id,
      sectId: playerSectId,
      numbers: repo.numbers,
    );
  });

  // 4. result 处理
  if (result == RecruitResult.success) {
    await onMarkTriggered();
    if (!context.mounted) return SectRecruitOutcome.success;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(successSnackBar)));
    return SectRecruitOutcome.success;
  }

  // 失败回滚 newChar(SectMemberService.recruit 失败时 Character 已 put · 需清孤儿)
  if (newCharId != null) {
    await isar.writeTxn(() => isar.characters.delete(newCharId!));
  }

  if (result == RecruitResult.fullCap) {
    if (onFallback != null) await onFallback();
    if (!context.mounted) return SectRecruitOutcome.capFull;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(capFullSnackBar)));
    return SectRecruitOutcome.capFull;
  }

  // 其他 fail(unexpected · targetNotFound / alreadyInSect / sectNotFound)
  debugPrint('sect recruit unexpected fail: $result');
  return SectRecruitOutcome.unexpectedFail;
}
