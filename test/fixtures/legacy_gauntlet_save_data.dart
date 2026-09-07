import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/features/boss_gauntlet/domain/boss_gauntlet_run.dart';

part 'legacy_gauntlet_save_data.g.dart';

/// Minimal pre-0.47 on-disk schema: gauntletRunSerial is genuinely absent.
@collection
@Name('SaveData')
class LegacyGauntletSaveData {
  Id id = 0;
  int slotId = 1;
  String saveVersion = '0.46.0';
  late DateTime createdAt;
  late DateTime lastSavedAt;
  late DateTime lastOnlineAt;
  int expeditionRunSerial = 17;
}

/// Pre-0.47 run schema without the cycle-seed opt-in flag.
@collection
@Name('BossGauntletRun')
class LegacyBossGauntletRun {
  Id id = Isar.autoIncrement;
  int saveDataId = 0;
  late int seed;
  int cycleIndex = 2;
  int currentStage = 2;
  @enumerated
  GauntletPhase sessionPhase = GauntletPhase.inBattle;
}
