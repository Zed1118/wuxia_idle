/// 门派事件 resolve 入参体例(P3.4 §12.1 Batch 2.2)。
///
/// `SectEventService.resolve` 接此枚举,联动 reputation/totalWins/sectLevel/status。
/// - `win`:    reputation +win_delta · totalWins +1 · 每 promote_wins_threshold 胜 +sectLevel
/// - `loss`:   reputation +loss_delta(clamp ≥0)
/// - `expired`:reputation +loss_delta · status=expired
enum SectOutcome { win, loss, expired }
