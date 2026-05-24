import 'dart:math';

import '../../../core/domain/enums.dart';
import '../../battle/domain/battle_state.dart';
import '../domain/pvp_record.dart';
import '../domain/pvp_snapshot.dart';

/// PVP 同步抽象(1.0 P3.3 §12.3,spec p3_3_pvp_spec_2026-05-24 §4 Q5=D)。
///
/// **方案 D**:Demo/Phase 1-4 走 [NoopPvpSync](本地 mock 对手 + 0 副作用),
/// Phase 5+ Supabase 真接入时新建 `SupabasePvpSync implements PvpSyncService`
/// 并替换 provider 注入,**0 victory hook 改动**(沿 LeaderboardSyncService 体例)。
abstract class PvpSyncService {
  /// 找对手(给定玩家 ELO + 段位窗口,返本地或远端候选 team)。
  ///
  /// 实现端负责 fallback:`numbers.yaml pvp.match_range.elo_window=100`
  /// 找不到池时扩到 `fallback_window=300`(Phase 5 真接入时实装,Noop 直接返镜像)。
  Future<List<BattleCharacter>> findOpponent({
    required int playerElo,
    required int eloWindow,
  });

  /// 上传玩家阵容快照(Phase 5 真接入,Noop 0 副作用)。
  Future<void> uploadSnapshot(PvpSnapshot snapshot);

  /// 上传战斗结果(Phase 5 真接入,Noop 0 副作用)。
  Future<void> uploadResult(PvpRecord record);
}

/// Noop 实装(Phase 1-4 默认注入)。
///
/// - [findOpponent]:本地生成 3 角色 mirror team(同 ELO 段位 ±100),
///   字段合 §5.4 红线 sanity 范围(maxHp ≤ 8000 / IF ≤ 5000 / atk ≤ 2000)。
/// - [uploadSnapshot] / [uploadResult]:0 副作用 / 0 network call。
///
/// **mirror team realm 选择**:本 Noop 不查 GameRepository(test 可不初始化),
/// 直接按 ELO bracket 派生 [RealmTier](`numbers.yaml pvp.ranks` 段窗 200);
/// `defenseRate` hardcode 0.20(erLiu/yiLiu 中位,合 §5.4 红线),Phase 5 真接入
/// 走快照里 attacker/defender 真境界字段。
class NoopPvpSync implements PvpSyncService {
  /// rng 可注入以便 R3.4 测族锚 seed(目前 mirror 生成走固定字段不依赖 _rng,
  /// 留接口给 Phase 5+ 真随机化 mirror 段位浮动用)。
  // ignore: unused_field
  final Random _rng;

  NoopPvpSync({Random? rng}) : _rng = rng ?? Random();

  @override
  Future<List<BattleCharacter>> findOpponent({
    required int playerElo,
    required int eloWindow,
  }) async {
    return List<BattleCharacter>.generate(
      3,
      (i) => _makeMirror(playerElo, i),
      growable: false,
    );
  }

  @override
  Future<void> uploadSnapshot(PvpSnapshot snapshot) async {
    // intentionally noop · Phase 5 SupabasePvpSync 落真序列化
  }

  @override
  Future<void> uploadResult(PvpRecord record) async {
    // intentionally noop · Phase 5 SupabasePvpSync 落真上传
  }

  /// 生成单个 mirror BattleCharacter。
  ///
  /// 字段口径(全部合 §5.4 红线 sanity):
  ///   - characterId:`-10001 - slotIndex`(负数避与玩家 Isar id 冲突,沿 _enemyToBattle 体例)
  ///   - school:`{gangMeng, lingQiao, yinRou}[slotIndex % 3]`(3 流派轮换)
  ///   - realmTier:ELO bracket 派生(§5.2 七阶 + numbers.yaml pvp.ranks)
  ///   - maxHp / maxInternalForce / totalEquipmentAttack:固定 sane 默认
  ///   - skills:empty(Noop 阶段不真跑战斗;Phase 5 快照解码时填真招)
  BattleCharacter _makeMirror(int playerElo, int slotIndex) {
    const schools = [
      TechniqueSchool.gangMeng,
      TechniqueSchool.lingQiao,
      TechniqueSchool.yinRou,
    ];
    final realm = _rankFromElo(playerElo);
    return BattleCharacter(
      characterId: -10001 - slotIndex,
      name: '对手#${slotIndex + 1}',
      realmTier: realm,
      realmLayer: RealmLayer.jingTong,
      school: schools[slotIndex % 3],
      maxHp: 8000,
      currentHp: 8000,
      maxInternalForce: 5000,
      currentInternalForce: 5000,
      speed: 200,
      criticalRate: 0.10,
      evasionRate: 0.05,
      defenseRate: 0.20,
      totalEquipmentAttack: 1500,
      mainCultivationLayer: CultivationLayer.daCheng,
      availableSkills: const [],
      skillCooldowns: const {},
      activeBuffs: const [],
      actionPoint: 0,
      isAlive: true,
      teamSide: 1,
      slotIndex: slotIndex,
    );
  }

  /// ELO → RealmTier 映射(numbers.yaml `pvp.ranks` 段窗 200)。
  ///
  /// xueTu < 1000 / sanLiu 1000-1199 / erLiu 1200-1399 / yiLiu 1400-1599 /
  /// jueDing 1600-1799 / zongShi 1800-1999 / wuSheng 2000+。
  RealmTier _rankFromElo(int elo) {
    if (elo < 1000) return RealmTier.xueTu;
    if (elo < 1200) return RealmTier.sanLiu;
    if (elo < 1400) return RealmTier.erLiu;
    if (elo < 1600) return RealmTier.yiLiu;
    if (elo < 1800) return RealmTier.jueDing;
    if (elo < 2000) return RealmTier.zongShi;
    return RealmTier.wuSheng;
  }
}
