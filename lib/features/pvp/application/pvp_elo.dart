import 'dart:math';

/// 标准 ELO 公式纯函数(1.0 P3.3 §12.3,spec p3_3_pvp_spec_2026-05-24 §4)。
///
/// 独立抽出方便 R3 测族单测,不依赖 NumbersConfig / Isar / Random。
/// caller 从 `numbers.yaml pvp.elo` 段拿 K factor 后传入。

/// 期望胜率(标准 ELO):`E_self = 1 / (1 + 10^((oppElo - selfElo) / 400))`。
///
/// - 同分 → 0.5
/// - 高 400 → ≈ 0.91(`1 / (1 + 10^-1)`)
/// - 低 400 → ≈ 0.09(`1 / (1 + 10^1)`)
double expectedScore(int selfElo, int oppElo) =>
    1.0 / (1.0 + pow(10, (oppElo - selfElo) / 400.0));

/// ELO 单场积分变化:`delta = round(K * (actual - expected))`。
///
/// [actualScore]:1.0 = 胜 / 0.5 = 平 / 0.0 = 负
/// [kFactor]:默认 K=32(`numbers.yaml pvp.elo.k_factor`)
///
/// 标准锚:K=32 + 同分 win → +16 / loss → -16 / draw → 0;
///         K=32 + 高分 (+400) win → +3 / loss → -29。
int eloDelta({
  required int selfElo,
  required int oppElo,
  required double actualScore,
  required int kFactor,
}) {
  final expected = expectedScore(selfElo, oppElo);
  return (kFactor * (actualScore - expected)).round();
}
