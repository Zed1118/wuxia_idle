import 'package:flutter/material.dart';

import '../../../../shared/strings.dart';
import '../../../../shared/theme/colors.dart';
import '../../domain/pvp_record.dart';
import 'rank_badge_widget.dart';

/// PVP 战例最近 N 场 list(1.0 P3.3 §12.3 Phase 4 · spec §5)。
///
/// 一行 = 一场对决:`{对手段位}  胜/负/和  ±ELO  {timestamp}`。
/// `playerId` 决定本机玩家视角(winnerId == playerId → 胜)。
/// 空 records 显空态文案,避空 ListView 留白。
class PvpHistoryList extends StatelessWidget {
  const PvpHistoryList({
    super.key,
    required this.records,
    required this.playerId,
  });

  /// 倒序最近 N 场(caller 负责截取 · `numbers.yaml pvp.history.max_records=200`)。
  final List<PvpRecord> records;

  /// 本机玩家 character id(判胜负 + draw 视角)。
  final int playerId;

  @override
  Widget build(BuildContext context) {
    if (records.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        decoration: BoxDecoration(
          color: WuxiaColors.panel,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: WuxiaColors.border),
        ),
        child: const Center(
          child: Text(
            UiStrings.pvpHistoryEmpty,
            style: TextStyle(color: WuxiaColors.textMuted, fontSize: 13),
          ),
        ),
      );
    }
    return Container(
      decoration: BoxDecoration(
        color: WuxiaColors.panel,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: WuxiaColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final r in records) _PvpHistoryRow(record: r, playerId: playerId),
        ],
      ),
    );
  }
}

class _PvpHistoryRow extends StatelessWidget {
  const _PvpHistoryRow({required this.record, required this.playerId});

  final PvpRecord record;
  final int playerId;

  String _outcomeLabel() {
    if (record.winnerId == null) return UiStrings.pvpHistoryDraw;
    return record.winnerId == playerId
        ? UiStrings.pvpHistoryWin
        : UiStrings.pvpHistoryLoss;
  }

  Color _outcomeColor() {
    if (record.winnerId == null) return WuxiaColors.textMuted;
    return record.winnerId == playerId
        ? WuxiaColors.hpHigh
        : WuxiaColors.hpLow;
  }

  String _timestampLabel(DateTime t) {
    String pad(int n) => n.toString().padLeft(2, '0');
    return '${t.month}-${pad(t.day)} ${pad(t.hour)}:${pad(t.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    final oppRank = RankBadgeWidget.rankInfo(record.playerEloBefore).name;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          SizedBox(
            width: 56,
            child: Text(
              oppRank,
              style: const TextStyle(
                color: WuxiaColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ),
          SizedBox(
            width: 32,
            child: Text(
              _outcomeLabel(),
              style: TextStyle(
                color: _outcomeColor(),
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(
            width: 60,
            child: Text(
              UiStrings.pvpHistoryEloDelta(record.eloDelta),
              style: TextStyle(
                color: record.eloDelta >= 0
                    ? WuxiaColors.hpHigh
                    : WuxiaColors.hpLow,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              _timestampLabel(record.timestamp),
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: WuxiaColors.textMuted,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
