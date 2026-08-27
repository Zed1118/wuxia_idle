import '../../domain/phase0a/arena_vector.dart';
import '../../domain/phase0a/phase0a_combat_events.dart';
import '../../domain/phase0a/phase0a_combat_model.dart';
import '../../domain/phase0a/posture.dart';
import 'phase0a_presentation_tokens.dart';

/// Phase 0A VFX entry 语义档:一次消费产出的表现指令类型。
enum Phase0aVfxKind {
  /// 精确伤害飘字(数值取自事件结算结果,不重算)。
  damagePopup,

  /// 玩家近距普攻命中的双弧墨痕。
  meleeSlash,

  /// 玩家远距普攻命中的掌风轨迹。
  palmTrail,

  /// 数字技能成功释放时，按装备技能的 typed 流派绘制起手墨势。
  skillCast,

  /// 数字技能逐目标结算时，按装备技能的 typed 流派绘制命中墨势。
  skillImpact,

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

  /// Boss 蓄力起手预警。
  bossChargeWarning,

  /// 玩家成功破招反馈。
  bossChargeInterrupted,

  /// 敌方姿态累积到阈值、进入破绽窗口的独立破势反馈。
  postureBroken,

  /// 破招被护法截走：Boss 不受破招，伤害落到护法。
  guardIntercepted,

  /// 两名护法在 Boss 蓄力掩护相位内完成合击。
  guardianCoop,

  /// 玩家主动防御起手与入站结算反馈。
  defenseStarted,
  defenseResolved,

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
    this.statusTicks,
    this.hotkey,
    this.skillId,
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
  final int? statusTicks;
  final int? hotkey;
  final String? skillId;

  /// 单点 VFX 的世界坐标锚点(技能两段 / 近战墨痕 / Q 涡旋 / R 墨爆 / 死亡墨散)。
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
  static const int maxDamagePopups = Phase0aPresentationTokens.maxDamagePopups;

  /// 契约常量(token 直引):单次消费 entry 总上限。
  static const int maxEntries = Phase0aPresentationTokens.maxEntries;

  /// 玩家远距普攻产生掌风轨迹的距离阈值(世界单位,token 直引)。
  static const double palmTrailMinDistance =
      Phase0aPresentationTokens.palmTrailMinDistance;

  final Map<String, Phase0aActor> _actors = <String, Phase0aActor>{};
  bool _sealed = false;

  /// 同步一拍竞技场全量状态,建立 id → 单位(位置/阵营)索引。
  ///
  /// 坐标读取为 event-first:事件携带的结算时坐标快照优先,字段为空
  /// 才回退本索引(兼容手工构造的旧事件)。本索引仍是 actor.side
  /// 阵营判定与坐标回退的唯一来源。
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

    void pushPopup(
      String targetId,
      int damage,
      bool isCritical, {
      ArenaVector? anchor,
    }) {
      if (damage <= 0 || popupCount >= maxDamagePopups) return;
      popupCount++;
      push(
        Phase0aVfxEntry(
          kind: Phase0aVfxKind.damagePopup,
          targetId: targetId,
          damage: damage,
          isCritical: isCritical,
          // 事件携带的结算时坐标快照优先;字段为空才回退同步状态
          // (兼容旧事件)。渲染层不得通过 id 反查当前 state
          // (目标可能已死亡/移除)。
          anchor: anchor ?? _actors[targetId]?.position,
        ),
      );
    }

    for (final event in events) {
      if (_sealed) break;
      if (!hasRoom()) {
        final outcomeSeal = switch (event) {
          Phase0aBattleVictory() => const Phase0aVfxEntry(
            kind: Phase0aVfxKind.outcomeSeal,
            isVictory: true,
          ),
          Phase0aBattleDefeat() => const Phase0aVfxEntry(
            kind: Phase0aVfxKind.outcomeSeal,
            isVictory: false,
          ),
          _ => null,
        };
        if (outcomeSeal == null) continue;
        entries[entries.length - 1] = outcomeSeal;
        _sealed = true;
        break;
      }
      switch (event) {
        case Phase0aHitLanded():
          pushPopup(
            event.target,
            event.resolvedDamage,
            event.isCritical,
            anchor: event.targetPosition,
          );
          _maybePushPlayerAttackVfx(event, push);
        case Phase0aGatherStarted():
          push(
            Phase0aVfxEntry(
              kind: Phase0aVfxKind.gatherVortex,
              anchor: event.actorPosition ?? _actors[event.actor]?.position,
            ),
          );
        case Phase0aGatherApplied():
          for (final outcome in event.outcomes) {
            // 同链补缺:Q 结算伤害与 Clear/Skill 同样逐目标飘字,
            // anchor = 结算落点(真实环点),零伤不发。
            pushPopup(
              outcome.target,
              outcome.resolvedDamage,
              outcome.isCritical,
              anchor: outcome.targetPosition,
            );
            if (outcome.statusApplied == Phase0aSkillStatus.pulled) {
              final source =
                  outcome.sourcePosition ?? _actors[outcome.target]?.position;
              final target =
                  outcome.targetPosition ?? _actors[event.actor]?.position;
              if (source == null || target == null) continue;
              push(
                Phase0aVfxEntry(
                  kind: Phase0aVfxKind.gatherPull,
                  actorId: event.actor,
                  targetId: outcome.target,
                  source: source,
                  vfxTarget: target,
                ),
              );
            }
          }
        case Phase0aClearStarted():
          push(
            Phase0aVfxEntry(
              kind: Phase0aVfxKind.clearBurst,
              anchor: event.actorPosition ?? _actors[event.actor]?.position,
            ),
          );
        case Phase0aClearApplied():
          for (final outcome in event.outcomes) {
            pushPopup(
              outcome.target,
              outcome.resolvedDamage,
              outcome.isCritical,
              anchor: outcome.targetPosition,
            );
          }
        case Phase0aSkillApplied():
          for (final outcome in event.outcomes) {
            pushPopup(
              outcome.target,
              outcome.resolvedDamage,
              outcome.isCritical,
              anchor: outcome.targetPosition,
            );
            push(
              Phase0aVfxEntry(
                kind: Phase0aVfxKind.skillImpact,
                actorId: event.actor,
                targetId: outcome.target,
                hotkey: event.hotkey,
                skillId: event.skillId,
                anchor:
                    outcome.targetPosition ?? _actors[outcome.target]?.position,
              ),
            );
          }
        case Phase0aEnemyDefeated():
          push(
            Phase0aVfxEntry(
              kind: Phase0aVfxKind.defeatInk,
              targetId: event.target,
              defeatKind: event.defeatKind,
              anchor: event.targetPosition ?? _actors[event.target]?.position,
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
        case Phase0aBossChargeStarted():
          push(
            Phase0aVfxEntry(
              kind: Phase0aVfxKind.bossChargeWarning,
              actorId: event.actor,
              statusTicks: event.chargeTicks,
              anchor: _actors[event.actor]?.position,
            ),
          );
        case Phase0aPostureChanged():
          if (event.eventType == PostureEventType.vulnerabilityEntered) {
            push(
              Phase0aVfxEntry(
                kind: Phase0aVfxKind.postureBroken,
                actorId: event.actor,
                targetId: event.target,
                statusTicks: event.vulnerabilityTicksRemaining,
                anchor: event.targetPosition ?? _actors[event.target]?.position,
              ),
            );
          }
        case Phase0aGuardIntercepted():
          push(
            Phase0aVfxEntry(
              kind: Phase0aVfxKind.guardIntercepted,
              actorId: event.actor,
              targetId: event.guardian,
              damage: event.resolvedDamage,
              anchor: event.guardianPosition,
              source: event.bossPosition,
              vfxTarget: event.guardianPosition,
            ),
          );
        case Phase0aGuardianCoopStrike():
          push(
            Phase0aVfxEntry(
              kind: Phase0aVfxKind.guardianCoop,
              actorId: event.mainGuardian,
              targetId: event.target,
              damage: event.totalDamage,
              anchor: event.targetPosition,
              source: event.mainGuardianPosition,
              vfxTarget: event.partnerPosition,
            ),
          );
        case Phase0aDefenseStarted():
          push(
            Phase0aVfxEntry(
              kind: Phase0aVfxKind.defenseStarted,
              actorId: event.actor,
              anchor: event.toPosition,
              source: event.fromPosition,
              statusTicks: event.windowTicks,
              damage: event.shieldAbsorption.round(),
            ),
          );
        case Phase0aDefenseResolved():
          push(
            Phase0aVfxEntry(
              kind: Phase0aVfxKind.defenseResolved,
              actorId: event.attacker,
              targetId: event.target,
              anchor: event.targetPosition,
              damage: event.counterDamage,
            ),
          );
        case Phase0aBattleVictory():
          push(
            const Phase0aVfxEntry(
              kind: Phase0aVfxKind.outcomeSeal,
              isVictory: true,
            ),
          );
          _sealed = true;
        case Phase0aBattleDefeat():
          push(
            const Phase0aVfxEntry(
              kind: Phase0aVfxKind.outcomeSeal,
              isVictory: false,
            ),
          );
          _sealed = true;
        case Phase0aSkillStarted():
          push(
            Phase0aVfxEntry(
              kind: Phase0aVfxKind.skillCast,
              actorId: event.actor,
              hotkey: event.hotkey,
              skillId: event.skillId,
              anchor: _actors[event.actor]?.position,
            ),
          );
        case Phase0aAttackStarted():
        case Phase0aBossPhaseChanged():
        case Phase0aEnemySkillStarted():
        case Phase0aSkillAvailabilityChanged():
        case Phase0aWaveCleared():
        case Phase0aSpawnWarningStarted():
        case Phase0aEnemyEntered():
        case Phase0aSpawnGraceExpired():
          break;
      }
    }
    return entries;
  }

  /// 玩家普攻按事件时距离二分表现:近距双弧墨痕,远距掌风;
  /// 敌方命中只触发通用受击反馈,不冒用玩家招式 VFX。
  ///
  /// 阵营判定仍从同步状态读取;坐标 event-first——事件携带的
  /// 结算时快照优先,字段为空才回退同步状态。
  void _maybePushPlayerAttackVfx(
    Phase0aHitLanded event,
    void Function(Phase0aVfxEntry) push,
  ) {
    final actor = _actors[event.actor];
    if (actor == null || actor.side != Phase0aSide.player) return;
    final actorPosition = event.actorPosition ?? actor.position;
    final targetPosition =
        event.targetPosition ?? _actors[event.target]?.position;
    if (targetPosition == null) return;
    final ArenaVector delta = targetPosition - actorPosition;
    if (delta.length < palmTrailMinDistance) {
      push(
        Phase0aVfxEntry(
          kind: Phase0aVfxKind.meleeSlash,
          actorId: event.actor,
          targetId: event.target,
          isCritical: event.isCritical,
          anchor: targetPosition,
        ),
      );
      return;
    }
    push(
      Phase0aVfxEntry(
        kind: Phase0aVfxKind.palmTrail,
        actorId: event.actor,
        targetId: event.target,
        isCritical: event.isCritical,
        source: actorPosition,
        vfxTarget: targetPosition,
      ),
    );
  }
}
