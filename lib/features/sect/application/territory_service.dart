import 'package:isar_community/isar.dart';

import '../../../data/game_repository.dart';
import '../../../data/numbers_config.dart';
import '../domain/sect.dart';
import '../domain/territory_def.dart';

/// 山头领地服务(P4.1 §12.2 Q4=A 静态 yaml + dynamic owner)。
///
/// **设计纪律**(对齐 [SectMemberService] / [RecruitmentService] 体例):
/// - **caller 持锁**:[claim] / [release] 不开 `writeTxn`,caller 必须在
///   `isar.writeTxn` 内 await。
/// - **静态 def 复用**:territory 静态字段(name / baseDefenseLevel / ...)
///   由 [GameRepository.territoryDefs] graceful 加载,本 service 不重复 parse
///   yaml,只查 + 写 `Sect.territoryIds`。
/// - **dynamic owner**:`Sect.territoryIds: List<String>` 唯一权威源,
///   Demo 单玩家路径单 sect 持有(O(N) sweep 查 owner)。
class TerritoryService {
  final Isar isar;

  TerritoryService(this.isar);

  /// 全 territory 静态 def(沿 yaml id 升序)。
  ///
  /// [GameRepository] 未加载(test fixture)→ 空 list。
  static List<TerritoryDef> allDefs() {
    if (!GameRepository.isLoaded) return const [];
    final map = GameRepository.instance.territoryDefs;
    final list = map.values.toList();
    list.sort((a, b) => a.id.compareTo(b.id));
    return list;
  }

  /// 查 [territoryId] 的静态 def([GameRepository.territoryDefs])。
  static TerritoryDef? defOf(String territoryId) {
    if (!GameRepository.isLoaded) return null;
    return GameRepository.instance.territoryDefs[territoryId];
  }

  /// 查 [territoryId] 当前 owner sectId(O(N) sweep 全 sect)。
  ///
  /// 中立无主(无 sect 持有)→ null。Demo 单 sect 假设下 O(N)=O(1)。
  Future<int?> ownerOf(String territoryId) async {
    final sects = await isar.sects.where().findAll();
    for (final s in sects) {
      if (s.territoryIds.contains(territoryId)) return s.id;
    }
    return null;
  }

  /// [sectId] 占领 [territoryId](caller writeTxn 内)。
  ///
  /// 副作用:sect.territoryIds.add(territoryId)。
  ///
  /// 失败条件:
  /// - territory def 不存在(yaml 未配)→ [ClaimResult.territoryNotFound]
  /// - sect 不存在 → [ClaimResult.sectNotFound]
  /// - territory 已被任意 sect 持有 → [ClaimResult.alreadyOwned]
  /// - sect.territoryIds.length ≥ cap(by_sect_level[sectLevel-1])→
  ///   [ClaimResult.fullCap]
  Future<ClaimResult> claim({
    required int sectId,
    required String territoryId,
    required NumbersConfig numbers,
  }) async {
    if (defOf(territoryId) == null) return ClaimResult.territoryNotFound;
    final sect = await isar.sects.get(sectId);
    if (sect == null) return ClaimResult.sectNotFound;

    // 查全 sect 反向索引(防多 sect 抢占)。
    final currentOwner = await ownerOf(territoryId);
    if (currentOwner != null) return ClaimResult.alreadyOwned;

    final cap = territoryCapFor(numbers, sect.sectLevel);
    if (sect.territoryIds.length >= cap) return ClaimResult.fullCap;

    sect.territoryIds = [...sect.territoryIds, territoryId];
    await isar.sects.put(sect);
    return ClaimResult.success;
  }

  /// [sectId] 放弃 [territoryId](caller writeTxn 内)。
  Future<ReleaseResult> release({
    required int sectId,
    required String territoryId,
  }) async {
    final sect = await isar.sects.get(sectId);
    if (sect == null) return ReleaseResult.sectNotFound;
    if (!sect.territoryIds.contains(territoryId)) {
      return ReleaseResult.notOwned;
    }
    sect.territoryIds =
        sect.territoryIds.where((id) => id != territoryId).toList();
    await isar.sects.put(sect);
    return ReleaseResult.success;
  }

  /// 中立可占领(无任何 sect 持有)的 territory list(沿 def id 升序)。
  Future<List<TerritoryDef>> availableForClaim() async {
    final defs = allDefs();
    if (defs.isEmpty) return const [];
    final occupied = <String>{};
    final sects = await isar.sects.where().findAll();
    for (final s in sects) {
      occupied.addAll(s.territoryIds);
    }
    return defs.where((d) => !occupied.contains(d.id)).toList();
  }

  /// 计算 [sectLevel](1-7)的 territory cap。
  ///
  /// `numbers.yaml sect_management.territory.max_per_sect_by_level[sectLevel-1]`。
  static int territoryCapFor(NumbersConfig numbers, int sectLevel) {
    final list = numbers.sectManagement.territory.maxPerSectByLevel;
    if (list.isEmpty) return 0;
    final idx = (sectLevel - 1).clamp(0, list.length - 1);
    return list[idx];
  }
}

/// [TerritoryService.claim] 返回枚举。
enum ClaimResult {
  success,
  alreadyOwned,
  fullCap,
  territoryNotFound,
  sectNotFound,
}

/// [TerritoryService.release] 返回枚举。
enum ReleaseResult {
  success,
  notOwned,
  sectNotFound,
}

/// 模拟招收 candidate 软概率结果(Q6 A · encounter sectMemberApplier 用 · 待 task 6 接入)。
typedef SectMemberRecruitApplier = Future<void> Function({
  required int sectId,
  required int targetCharacterId,
});
