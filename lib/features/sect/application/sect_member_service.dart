import 'package:isar_community/isar.dart';

import '../../../core/domain/character.dart';
import '../../../data/numbers_config.dart';
import '../domain/sect.dart';
import '../domain/sect_rank.dart';

/// 门派成员服务(P4.1 §12.2 Q2=C 双向 fk + Q3=A 复用 Character + Q5=A 三阶)。
///
/// **设计纪律**(对齐 [RecruitmentService] / [TutorialService] 体例):
/// - **caller 持锁**:service 方法不开 `writeTxn`,caller 必须在
///   `isar.writeTxn` 内 await,保证 character + sect 多表写入原子性
///   (memory `feedback_isar_pitfalls` §1)。
/// - **双向 fk 一致性**:[recruit] / [dismiss] 必同步更新 `Character.{isInSect,
///   sectId,sectRank}` + `Sect.memberCount`,任一缺失即视为 schema 不变量破。
/// - **founder 不计入 memberCount**:founder 通过 `Sect.founderId` 直接索引,
///   `Character.isInSect=true && sectId=this.id` 含 founder,但 `memberCount`
///   不含 founder 本人(cap 校 += founder 例外不进 [recruit])。
class SectMemberService {
  final Isar isar;

  SectMemberService(this.isar);

  /// 招收 [targetCharacterId] 进 [sectId](阶位默认 [SectRank.initiate])。
  ///
  /// 副作用(caller writeTxn 内):
  /// - target.{isInSect=true, sectId, sectRank=initiate}
  /// - sect.memberCount++
  ///
  /// 失败条件(枚举返,不抛):
  /// - target 不存在 → [RecruitResult.targetNotFound]
  /// - target 已入派 → [RecruitResult.alreadyInSect]
  /// - sect 不存在 → [RecruitResult.sectNotFound]
  /// - memberCount ≥ cap(by_sect_level[sectLevel-1])→ [RecruitResult.fullCap]
  Future<RecruitResult> recruit({
    required int targetCharacterId,
    required int sectId,
    required NumbersConfig numbers,
  }) async {
    final target = await isar.characters.get(targetCharacterId);
    if (target == null) return RecruitResult.targetNotFound;
    if (target.isInSect) return RecruitResult.alreadyInSect;
    final sect = await isar.sects.get(sectId);
    if (sect == null) return RecruitResult.sectNotFound;
    final cap = memberCapFor(numbers, sect.sectLevel);
    if (sect.memberCount >= cap) return RecruitResult.fullCap;

    target.isInSect = true;
    target.sectId = sectId;
    target.sectRank = SectRank.initiate;
    sect.memberCount += 1;
    await isar.characters.put(target);
    await isar.sects.put(sect);
    return RecruitResult.success;
  }

  /// 升阶([SectRank.initiate] → [SectRank.inner] → [SectRank.elder])。
  ///
  /// 单向不可降阶(elder 已是顶 → [PromoteResult.alreadyMax])。
  /// [contribution] 为 caller 端注入的累计贡献(Demo P4.1 阶段由 UI 手动升传
  /// `Sect.totalWins` 或类似维度,自动升迁规则细化挂 1.1)。
  Future<PromoteResult> promoteRank({
    required int characterId,
    required int contribution,
    required NumbersConfig numbers,
  }) async {
    final target = await isar.characters.get(characterId);
    if (target == null) return PromoteResult.characterNotFound;
    if (!target.isInSect || target.sectRank == null) {
      return PromoteResult.notInSect;
    }
    final t = numbers.sectManagement.rankPromoteThreshold;
    switch (target.sectRank!) {
      case SectRank.initiate:
        if (contribution < t.innerMinContribution) {
          return PromoteResult.belowThreshold;
        }
        target.sectRank = SectRank.inner;
        await isar.characters.put(target);
        return PromoteResult.success;
      case SectRank.inner:
        if (contribution < t.elderMinContribution) {
          return PromoteResult.belowThreshold;
        }
        target.sectRank = SectRank.elder;
        await isar.characters.put(target);
        return PromoteResult.success;
      case SectRank.elder:
        return PromoteResult.alreadyMax;
    }
  }

  /// 退派(清三字段 + memberCount--)。
  ///
  /// founder 是否可 dismiss:Demo P4.1 不阻止(founder isInSect=true 但
  /// memberCount 不含 founder,dismiss 后 memberCount 不变 → 由 [recruit]
  /// 单边维护,本方法不动 founder 例外)。1.1 加 founder 锁定。
  Future<DismissResult> dismiss({required int characterId}) async {
    final target = await isar.characters.get(characterId);
    if (target == null) return DismissResult.characterNotFound;
    if (!target.isInSect || target.sectId == null) {
      return DismissResult.notInSect;
    }
    final sect = await isar.sects.get(target.sectId!);
    if (sect == null) return DismissResult.sectNotFound;

    final isFounderOfSect = sect.founderId == characterId;
    target.isInSect = false;
    target.sectId = null;
    target.sectRank = null;
    if (!isFounderOfSect && sect.memberCount > 0) {
      sect.memberCount -= 1;
    }
    await isar.characters.put(target);
    await isar.sects.put(sect);
    return DismissResult.success;
  }

  /// 查 [sectId] 全成员(含 founder · 沿 [Character.sectId] index)。
  Future<List<Character>> listMembers(int sectId) async {
    return isar.characters.filter().sectIdEqualTo(sectId).findAll();
  }

  /// 计算 [sectLevel](1-7)的 member cap。
  ///
  /// `numbers.yaml sect_management.member_cap.by_sect_level[sectLevel-1]`。
  /// 越界 clamp 末位(Demo 1-7 阶不越界)。
  static int memberCapFor(NumbersConfig numbers, int sectLevel) {
    final list = numbers.sectManagement.memberCap.bySectLevel;
    if (list.isEmpty) return 0;
    final idx = (sectLevel - 1).clamp(0, list.length - 1);
    return list[idx];
  }
}

/// [SectMemberService.recruit] 返回枚举(枚举返,不抛)。
enum RecruitResult {
  success,
  fullCap,
  alreadyInSect,
  sectNotFound,
  targetNotFound,
}

/// [SectMemberService.promoteRank] 返回枚举。
enum PromoteResult {
  success,
  alreadyMax,
  belowThreshold,
  characterNotFound,
  notInSect,
}

/// [SectMemberService.dismiss] 返回枚举。
enum DismissResult {
  success,
  notInSect,
  characterNotFound,
  sectNotFound,
}
