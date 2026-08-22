/// 旧 3v3 战斗表现层 SFX 纯映射。
///
/// 从 shared/audio/audio_assets.dart 迁出，隔离对旧
/// [BattleState]/[BattleAction]/[BattleCharacter] 的依赖，让共享层保持引擎中立。
/// 仅旧 [BattleScreen] / 其播放控制器消费；Phase 0A 路径走
/// `phase0a_sfx.dart`（体例对齐但独立）。
library;

import '../../../shared/audio/audio_assets.dart';
import '../domain/battle_state.dart';

/// 战斗动作 → SFX 纯映射。表现层用，不读/写 BattleState。
/// 优先级：大招 > 暴击 > 普通命中；闪避/无结果不出声。死亡 SFX v1 不做。
SfxId? sfxForAction({required BattleAction action, required bool isUltimate}) {
  final r = action.attackResult;
  if (r == null) return null;
  if (r.isDodged) return null;
  if (isUltimate) return SfxId.battleUlt;
  if (r.isCritical) return SfxId.battleCrit;
  return SfxId.battleHit;
}

/// 战斗状态边沿 → 蓄力/破招/踉跄 SFX。表现层用，纯函数（不碰 SoundManager）。
/// 逐角色（按 characterId 跨 prev/next 匹配）判转移：
///  - chargingSkill null→非null  → battleChargeStart(起手蓄力)
///  - chargingSkill 非null→null 且 stagger 增加 → battleInterrupt(被破招)
///  - staggerTicksRemaining 减少 → battleStagger(踉跄跳过)
/// prev 为 null(开局)→ 空。
List<SfxId> chargeTransitionSfx(BattleState? prev, BattleState next) {
  if (prev == null) return const [];
  final out = <SfxId>[];
  final prevById = <int, BattleCharacter>{};
  for (final c in prev.leftTeam) {
    prevById[c.characterId] = c;
  }
  for (final c in prev.rightTeam) {
    prevById[c.characterId] = c;
  }
  for (final c in [...next.leftTeam, ...next.rightTeam]) {
    final p = prevById[c.characterId];
    if (p == null) continue;
    final wasCharging = p.chargingSkill != null;
    final isCharging = c.chargingSkill != null;
    if (!wasCharging && isCharging) {
      out.add(SfxId.battleChargeStart);
    } else if (wasCharging &&
        !isCharging &&
        c.staggerTicksRemaining > p.staggerTicksRemaining) {
      out.add(SfxId.battleInterrupt);
    }
    if (c.staggerTicksRemaining < p.staggerTicksRemaining) {
      out.add(SfxId.battleStagger);
    }
  }
  return out;
}
