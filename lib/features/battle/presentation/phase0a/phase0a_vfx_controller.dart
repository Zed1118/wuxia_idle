import '../../domain/phase0a/arena_vector.dart';
import '../../domain/phase0a/phase0a_combat_events.dart';
import '../../domain/phase0a/phase0a_combat_model.dart';
import 'phase0a_presentation_tokens.dart';

/// Phase 0A VFX entry 语义档:一次消费产出的表现指令类型。
enum Phase0aVfxKind {
  /// 精确伤害飘字(数值取自事件结算结果,不重算)。
  damagePopup,

  /// 玩家远距普攻命中的掌风轨迹。
  palmTrail,

  /// Q 聚怪力场涡旋。
  gatherVortex,

  /// Q 聚怪逐被拉拢目标的拉拢轨迹。
  gatherPull,

  /// R 清场径向墨爆。
  clearBurst,

  /// 敌方单位被击败的墨散(区分普通/精英语义档)。
  defeatInk,

  /// 波次横幅(携带对外 1-based 波次序号与总波数)。
  waveBanner,

  /// 终局封签(胜/败全场唯一)。
  outcomeSeal,
}

/// 单条表现指令(不可变)。字段按 kind 取用,未用字段为空。
///
/// [anchor]/[source]/[vfxTarget] 为事件发生时的世界坐标快照。
/// 渲染层不得通过 id 反查当前 [Phase0aArenaState] 获取位置
/// (敌人死亡后已从 state 移除,会导致 VFX 定位到错误的 fallback 位置)。
final class Phase0aVfxEntry {
  const Phase0aVfxEntry({
    required this.kind,
    this.actorId,
    this.targetId,
    this.damage,
    this.isCritical = false,
    this.defeatKind,
    this.waveIndex,
    this.waveTotal,
    this.isVictory,
    this.anchor,
    this.source,
    this.vfxTarget,
  });

  final Phase0aVfxKind kind;
  final String? actorId;
  final String? targetId;
  final int? damage;
  final bool isCritical;
  final Phase0aDefeatKind? defeatKind;
  final int? waveIndex;
  final int? waveTotal;
  final bool? isVictory;

  /// 单点 VFX 的世界坐标锚点(Q 涡旋 / R 墨爆 / 死亡墨散)。
  final ArenaVector? anchor;

  /// 掌风轨迹:出手者世界坐标。
  final ArenaVector? source;

  /// 掌风轨迹:目标世界坐标。
  final ArenaVector? vfxTarget;
}

/// Phase 0A 事件 → VFX entry 映射器。
///
/// 只搬运事件携带的结算数值与语义档,不重算伤害、不补发事件;
/// 终局封签落下后(_sealed),后续一切战斗事件不再产出 entry。
final class Phase0aVfxController {
  /// 契约常量(token 直引):伤害飘字上限。
  static const int maxDamagePopups =
      Phase0aPresentationTokens.maxDamagePopups;

  /// 契约常量(token 直引):单次消费 entry 总上限。
  static const int maxEntries = Phase0aPresentationTokens.maxEntries;

  /// 玩家远距普攻产生掌风轨迹的距离阈值(世界单位,token 直引)。
  static const double palmTrailMinDistance =
      Phase0aPresentationTokens.palmTrailMinDistance;

  final Map<String, Phase0aActor> _actors = <String, Phase0aActor>{};
  bool _sealed = false;

  /// 同步一拍竞技场全量状态,建立 id → 单位(位置/阵营)索引。
  void syncActors(Phase0aArenaState state) {
    _actors
      ..clear()
      ..[state.player.id] = state.player;
    for (final enemy in state.enemies) {
      _actors[enemy.id] = enemy;
    }
  }

  /// 消费一批已排序去重的事件,产出表现指令序列。
  /// 终局之后(含本批内封签之后)不再产出任何 entry。
  List<Phase0aVfxEntry> consume(List<Phase0aEvent> events) {
    if (_sealed || events.isEmpty) return const <Phase0aVfxEntry>[];
    final entries = <Phase0aVfxEntry>[];
    var popupCount = 0;

    bool hasRoom() => entries.length < maxEntries;

    void push(Phase0aVfxEntry entry) {
      if (hasRoom()) entries.add(entry);
    }

    void pushPopup(String targetId, int damage, bool isCritical) {
      if (damage <= 0 || popupCount >= maxDamagePopups) return;
      popupCount++;
      push(
        Phase0aVfxEntry(
          kind: Phase0aVfxKind.damagePopup,
          targetId: targetId,
          damage: damage,
          isCritical: isCritical,
          // 保存事件发生时目标的世界坐标快照。
          // 渲染层不得通过 id 反查当前 state(目标可能已死亡/移除)。
          anchor: _actors[targetId]?.position,
        ),
      );
    }

    for (final event in events) {
      if (_sealed || !hasRoom()) break;
      switch (event) {
        case Phase0aHitLanded():
          pushPopup(event.target, event.resolvedDamage, event.isCritical);
          _maybePushPalmTrail(event, push);
        case Phase0aGatherStarted():
          push(
            Phase0aVfxEntry(
              kind: Phase0aVfxKind.gatherVortex,
              anchor: _actors[event.actor]?.position,
            ),
          );
        case Phase0aGatherApplied():
          for (final outcome in event.outcomes) {
            if (outcome.statusApplied == Phase0aSkillStatus.pulled) {
              push(
                Phase0aVfxEntry(
                  kind: Phase0aVfxKind.gatherPull,
                  actorId: event.actor,
                  targetId: outcome.target,
                ),
              );
            }
          }
        case Phase0aClearStarted():
          push(
            Phase0aVfxEntry(
              kind: Phase0aVfxKind.clearBurst,
              anchor: _actors[event.actor]?.position,
            ),
          );
        case Phase0aClearApplied():
          for (final outcome in event.outcomes) {
            pushPopup(outcome.target, outcome.resolvedDamage, false);
          }
        case Phase0aEnemyDefeated():
          push(
            Phase0aVfxEntry(
              kind: Phase0aVfxKind.defeatInk,
              targetId: event.target,
              defeatKind: event.defeatKind,
              anchor: _actors[event.target]?.position,
            ),
          );
        case Phase0aWaveStarted():
          push(
            Phase0aVfxEntry(
              kind: Phase0aVfxKind.waveBanner,
              waveIndex: event.waveIndex,
              waveTotal: event.waveTotal,
            ),
          );
        case Phase0aBattleVictory():
          push(const Phase0aVfxEntry(kind: Phase0aVfxKind.outcomeSeal, isVictory: true));
          _sealed = true;
        case Phase0aBattleDefeat():
          push(const Phase0aVfxEntry(kind: Phase0aVfxKind.outcomeSeal, isVictory: false));
          _sealed = true;
        case Phase0aAttackStarted():
        case Phase0aSkillAvailabilityChanged():
        case Phase0aWaveCleared():
          break;
      }
    }
    return entries;
  }

  /// 仅玩家普攻且出手距离达到阈值时产生掌风轨迹;敌方远程不发。
  void _maybePushPalmTrail(
    Phase0aHitLanded event,
    void Function(Phase0aVfxEntry) push,
  ) {
    final actor = _actors[event.actor];
    final target = _actors[event.target];
    if (actor == null || target == null) return;
    if (actor.side != Phase0aSide.player) return;
    final ArenaVector delta = target.position - actor.position;
    if (delta.length < palmTrailMinDistance) return;
    push(
      Phase0aVfxEntry(
        kind: Phase0aVfxKind.palmTrail,
        actorId: event.actor,
        targetId: event.target,
        source: actor.position,
        vfxTarget: target.position,
      ),
    );
  }
}
