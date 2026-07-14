import 'package:isar_community/isar.dart';

import '../../../core/domain/character.dart';
import '../../../core/domain/save_data.dart';
import '../../battle/domain/derived_stats.dart';

/// 编成写入结果状态(spec `2026-07-14-team-lineup-screen-design.md` §2 校验矩阵)。
enum LineupApplyStatus {
  success,
  saveMissing, // SaveData 未初始化
  emptyLineup, // 出战不可为空(至少祖师)
  tooMany, // 超 3 人
  duplicateIds, // 同一角色重复入列
  unknownCharacter, // 角色不存在
  deadCharacter, // 非存活角色不可出战
  founderMissing, // 祖师(save.founderCharacterId)必在
  ascendedFounder, // 已飞升太祖(isFounder 且非当代祖师)不可回场
  retreatLocked, // 成员增删涉及闭关中角色(currentRetreatSessionId 非空)
}

/// 编成写入结果。失败态零副作用;[offendingCharacterId] 供 UI 指认拒因角色。
class LineupApplyResult {
  final LineupApplyStatus status;
  final int? offendingCharacterId;

  const LineupApplyResult(this.status, {this.offendingCharacterId});

  bool get isSuccess => status == LineupApplyStatus.success;
}

/// 出战编成唯一写入口(玩法评估 §十三 #4 · 2026-07-14 拍板 C 完整编成屏)。
///
/// **单一真相源**:`SaveData.activeCharacterIds`(列表序 = 站位序,slot 0 前排);
/// `Character.isActive` 为镜像,随本服务写路径同步(生产读方:
/// `item_use_service` / `post_battle_healing_panel` 的 `.isActiveEqualTo(true)`
/// 查询、门派谱当代兜底)。join / recruitment / ascension 既有写点行为不动
/// (各自测试已覆盖),编成操作一律走本服务。
///
/// **战斗态边界(spec §2 口径订正)**:全仓无「战斗进行中」持久信号——战斗 roster
/// 在 `StageBattleSetup._buildPlayerTeam` 进场时快照,结算 roster 由 caller 传入
/// 快照列表;编成屏与 BattleScreen 路由互斥,故战斗态排他由导航结构保证,
/// 本服务不做(也无从做)战斗态校验。
///
/// **闭关锁**:`Character.currentRetreatSessionId != null` 即闭关中
/// (`RetreatSession` 无 characterId,靠角色指针绑定;`isInRetreat` 是无写点的
/// 构造器死字段,不作判据)。闭关中角色**成员增删拦截**(防收功结算悬空),
/// 纯槽序重排放行(结算按角色 id 定位,与槽序无关)。
///
/// 体例对齐 [TechniqueLearnFlowService]:自持 Isar、自开 writeTxn、
/// 返回结果对象、失败态在写事务外返回零副作用。
class LineupService {
  final Isar isar;

  const LineupService(this.isar);

  /// 校验并落库新编成。[newActiveIds] 列表序即站位序。
  Future<LineupApplyResult> apply({required List<int> newActiveIds}) async {
    final save = await isar.saveDatas.get(0);
    if (save == null) {
      return const LineupApplyResult(LineupApplyStatus.saveMissing);
    }
    if (newActiveIds.isEmpty) {
      return const LineupApplyResult(LineupApplyStatus.emptyLineup);
    }
    if (newActiveIds.length > 3) {
      return const LineupApplyResult(LineupApplyStatus.tooMany);
    }
    if (newActiveIds.toSet().length != newActiveIds.length) {
      return const LineupApplyResult(LineupApplyStatus.duplicateIds);
    }

    final members = <int, Character>{};
    for (final id in newActiveIds) {
      final c = await isar.characters.get(id);
      if (c == null) {
        return LineupApplyResult(
          LineupApplyStatus.unknownCharacter,
          offendingCharacterId: id,
        );
      }
      members[id] = c;
    }

    for (final c in members.values) {
      if (!c.isAlive) {
        return LineupApplyResult(
          LineupApplyStatus.deadCharacter,
          offendingCharacterId: c.id,
        );
      }
    }

    final founderId = save.founderCharacterId;
    if (founderId == null || !newActiveIds.contains(founderId)) {
      return const LineupApplyResult(LineupApplyStatus.founderMissing);
    }
    for (final c in members.values) {
      if (c.isFounder && c.id != founderId) {
        return LineupApplyResult(
          LineupApplyStatus.ascendedFounder,
          offendingCharacterId: c.id,
        );
      }
    }

    // 闭关锁只拦成员增删;留在阵中(纯重排)不受影响。
    final oldIds = save.activeCharacterIds.toSet();
    final newIds = newActiveIds.toSet();
    final added = newIds.difference(oldIds);
    final removed = oldIds.difference(newIds);
    for (final id in added) {
      if (members[id]!.currentRetreatSessionId != null) {
        return LineupApplyResult(
          LineupApplyStatus.retreatLocked,
          offendingCharacterId: id,
        );
      }
    }
    for (final id in removed) {
      final c = await isar.characters.get(id);
      if (c != null && c.currentRetreatSessionId != null) {
        return LineupApplyResult(
          LineupApplyStatus.retreatLocked,
          offendingCharacterId: id,
        );
      }
    }

    await isar.writeTxn(() async {
      // 事务内重读 save,防 stale 快照覆盖并发写(沿 disciple_join_service 体例)。
      final fresh = await isar.saveDatas.get(0) ?? save;
      fresh.activeCharacterIds = List.of(newActiveIds);
      await isar.saveDatas.put(fresh);

      for (final id in removed) {
        final c = await isar.characters.get(id);
        if (c != null && c.isActive) {
          c.isActive = false;
          await isar.characters.put(c);
        }
      }
      // 加入者 + 留阵者统一置真(防御性收敛历史镜像漂移)。
      for (final id in newActiveIds) {
        final c = await isar.characters.get(id);
        if (c != null && !c.isActive) {
          c.isActive = true;
          await isar.characters.put(c);
        }
      }
    });
    return const LineupApplyResult(LineupApplyStatus.success);
  }

  /// 替补池:全部可上场的 inactive 角色。
  ///
  /// 口径(Phase 0 现查,2026-07-14):`isActive==false && isAlive && !isFounder`
  /// 索引查询——覆盖四条进入管线(E.1 收徒 / Boss 招降 / 战败收降 / 门派任务;
  /// 后三条不写 `SaveData.recruitedDiscipleIds`,故不能用该列表);排除已飞升
  /// 太祖(isFounder && inactive)与非存活角色。绝对境界层降序、同层 id 升序。
  Future<List<Character>> loadReserve() async {
    final reserve = await isar.characters
        .filter()
        .isActiveEqualTo(false)
        .isAliveEqualTo(true)
        .isFounderEqualTo(false)
        .findAll();
    reserve.sort((a, b) {
      final levelDiff =
          RealmUtils.absoluteLevelOf(b.realmTier, b.realmLayer) -
          RealmUtils.absoluteLevelOf(a.realmTier, a.realmLayer);
      if (levelDiff != 0) return levelDiff;
      return a.id.compareTo(b.id);
    });
    return reserve;
  }
}
