import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/save_data.dart';
import 'package:wuxia_idle/shared/battle_shared/player_combatant_snapshot_assembler.dart';
import 'package:wuxia_idle/features/onboarding/application/onboarding_service.dart';
import 'package:wuxia_idle/features/onboarding/domain/founder_creation_selection.dart';
import 'package:wuxia_idle/shared/battle_shared/combatant_snapshot.dart';
import 'package:wuxia_idle/shared/utils/rng.dart';

final class Phase0aCh1FounderProfile {
  const Phase0aCh1FounderProfile({
    required this.profileId,
    required this.snapshot,
  });

  final String profileId;
  final CombatantSnapshot snapshot;
}

Future<Phase0aCh1FounderProfile> seedPhase0aCh1FounderProfile({
  required Isar isar,
  required String schoolId,
  required String originId,
  required String fateId,
  required int rngSeed,
}) async {
  if (!GameRepository.isLoaded) {
    throw StateError('GameRepository must be loaded before seeding a profile');
  }
  final config = GameRepository.instance.founderCreation;

  T unique<T>(
    String kind,
    String id,
    Iterable<T> options,
    String Function(T) key,
  ) {
    final matches = options.where((option) => key(option) == id).toList();
    if (matches.length != 1) {
      throw StateError('$kind option "$id" must resolve to exactly one entry');
    }
    return matches.single;
  }

  final school = unique('school', schoolId, config.schools, (e) => e.id);
  final origin = unique('origin', originId, config.origins, (e) => e.id);
  final fate = unique('fate', fateId, config.fatePool, (e) => e.id);
  final selection = FounderCreationSelection(
    school: school,
    origin: origin,
    fate: fate,
  );

  final existing = await isar.characters
      .filter()
      .isFounderEqualTo(true)
      .count();
  if (existing != 0) {
    throw StateError(
      'profile seed requires an empty Isar (founder already exists)',
    );
  }
  await isar.writeTxn(() async {
    if (await isar.saveDatas.get(0) == null) {
      await isar.saveDatas.put(SaveData()..id = 0);
    }
  });
  await OnboardingService(
    isar: isar,
    rng: DefaultRng(seed: rngSeed),
  ).createFoundingMaster(selection: selection, soloStart: true);

  final snapshots = await PlayerCombatantSnapshotAssembler(
    isar: isar,
  ).loadExactRoster(const [1]);
  if (snapshots.length != 1) {
    throw StateError('expected exactly one founder snapshot');
  }
  return Phase0aCh1FounderProfile(
    profileId: '$schoolId/$originId/$fateId/$rngSeed',
    snapshot: snapshots.single,
  );
}
