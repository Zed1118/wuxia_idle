import 'package:isar_community/isar.dart';

part 'legacy_sect_member_count.g.dart';

/// Same persisted collection identity as Sect, without its later count cache.
/// SaveData and Character use their real schemas so no other missing field can
/// influence the relationship evidence under examination.
@collection
@Name('Sect')
class LegacySectWithoutMemberCount {
  Id id = 1;
  String name = 'Legacy Sect';
  int founderId = 1;
  int sectLevel = 1;
  int sectReputation = 37;
  int totalWins = 5;
  DateTime createdAt = DateTime.utc(2026, 9, 7);
  DateTime? lastEventAt;
  DateTime? lastTickAt;
  List<String> territoryIds = [];
}
