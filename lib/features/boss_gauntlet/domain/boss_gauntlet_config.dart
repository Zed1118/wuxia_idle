import '../../../data/defs/stage_def.dart';

class GauntletStageConfig {
  const GauntletStageConfig({required this.role, required this.enemyTeamId});
  final String role; // 'elite' | 'boss'
  final String enemyTeamId;
}

/// 断魂庄配置（§8.2）。A2 落关次角色/补给上限校验；Phase C C1.3.2 扩展敌队机制。
///
/// 敌队随 `enemy_teams`（teamId → `EnemyDef` 列表）解析（design §8.2：敌队进
/// `boss_gauntlets.yaml`，机制走 `EnemyDef` 既有字段 bossPhases/guardianWard/
/// vulnerability，skillIds 引用现有 `skills.yaml`）。敌队引用完整性校验
/// （每关 enemy_team_id 解析、chargeSkillId∈skillIds、相位招/护法/弱点引用不悬空）
/// 在 `GameRepository` 加载期统一跑（需 skillDefs/队内 id 交叉核对，纯配置无法自足），
/// 见 `GameRepository._enforceGauntletEnemyRedLines`。
class BossGauntletConfig {
  const BossGauntletConfig({
    required this.stages,
    required this.supplyCap,
    this.enemyTeams = const {},
    this.firstClearRewardSkillId = '',
    this.rewardCandidateEquipmentIds = const [],
  });

  final List<GauntletStageConfig> stages;
  final int supplyCap;

  /// teamId → 敌队（关次经 [GauntletStageConfig.enemyTeamId] 引用）。
  final Map<String, List<EnemyDef>> enemyTeams;

  /// 首通解锁的秘籍招式 id（§6.2·「锁脉针法」= skill_suo_mai_zhen）。
  final String firstClearRewardSkillId;

  /// Boss 胜利三选一命名装备候选 defId（恰 3 件·§6.2）。数值/命名 TODO(batch3-probe)：
  /// 现引用现有好家伙(二流)装备占位，后续替换为断魂庄专属命名奖励。
  final List<String> rewardCandidateEquipmentIds;

  /// 解析关次敌队；未知 teamId 返回空列表（引用完整性由加载期红线守）。
  List<EnemyDef> enemiesForTeam(String teamId) =>
      enemyTeams[teamId] ?? const <EnemyDef>[];

  factory BossGauntletConfig.fromYaml(Map<String, dynamic> y) {
    final supplyCap = (y['supply_cap'] as num?)?.toInt() ?? 0;
    final rawStages = (y['stages'] as List?) ?? const [];
    final stages = [
      for (final s in rawStages)
        GauntletStageConfig(
          role: (s as Map)['role'] as String? ?? '',
          enemyTeamId: s['enemy_team_id'] as String? ?? '',
        ),
    ];

    final rawTeams = (y['enemy_teams'] as Map?) ?? const {};
    final enemyTeams = <String, List<EnemyDef>>{
      for (final entry in rawTeams.entries)
        entry.key as String: [
          for (final e in (entry.value as List? ?? const []))
            EnemyDef.fromYaml(Map<String, dynamic>.from(e as Map)),
        ],
    };

    if (supplyCap != 3) {
      throw StateError('boss_gauntlets: 补给上限固定为 3，got $supplyCap');
    }
    final eliteCount = stages.where((s) => s.role == 'elite').length;
    final bossCount = stages.where((s) => s.role == 'boss').length;
    if (stages.length != 3 || eliteCount != 2 || bossCount != 1) {
      throw StateError(
        'boss_gauntlets: 三关须恰为两精英+一Boss，got '
        '${stages.length}关 elite=$eliteCount boss=$bossCount',
      );
    }
    for (final s in stages) {
      if (s.enemyTeamId.isEmpty) {
        throw StateError('boss_gauntlets: 关次 enemy_team_id 不得为空');
      }
    }

    final firstClearSkill = y['first_clear_reward_skill_id'] as String? ?? '';
    final rewardCandidates = [
      for (final e
          in (y['reward_candidate_equipment_ids'] as List? ?? const []))
        e as String,
    ];
    if (firstClearSkill.isEmpty) {
      throw StateError('boss_gauntlets: first_clear_reward_skill_id 不得为空');
    }
    if (rewardCandidates.length != 3) {
      throw StateError(
        'boss_gauntlets: 奖励候选须恰 3 件（三选一），got ${rewardCandidates.length}',
      );
    }
    if (rewardCandidates.any((id) => id.isEmpty)) {
      throw StateError('boss_gauntlets: 奖励候选 id 不得为空');
    }

    return BossGauntletConfig(
      stages: stages,
      supplyCap: supplyCap,
      enemyTeams: enemyTeams,
      firstClearRewardSkillId: firstClearSkill,
      rewardCandidateEquipmentIds: rewardCandidates,
    );
  }
}
