import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';

import '../../../core/application/battle_providers.dart';
import '../../../core/application/system_clock_provider.dart';
import '../../../core/domain/character.dart';
import '../../../core/domain/save_data.dart';
import '../../../data/isar_provider.dart';
import '../../../shared/utils/rng_provider.dart';
import '../domain/sect.dart';
import '../domain/sect_event.dart';
import '../domain/sect_outcome.dart';
import '../domain/territory_def.dart';
import 'sect_event_service.dart';
import 'sect_member_service.dart';
import 'sect_reputation_decay.dart';
import 'territory_service.dart';

/// 门派系统 Riverpod wire(1.0 P3.4 §12.1 · T19b 技术债清账)。
///
/// **T19b 升级**(原 Batch 2.3 内存 state → 真 Isar 持久化):
/// - `SectSchema` / `SectEventSchema` 已加入 `IsarSetup._allSchemas`(0.13.0)。
/// - [currentSectProvider] StreamProvider 读 `isar.sects` watchObject(1)。
/// - [activeSectEventsProvider] / [historicalSectEventsProvider] StreamProvider
///   走 status filter 查询 watch。
/// - [resolveSectEventProvider] 写库走 [SectEventService.resolve] 算 delta 后
///   `isar.writeTxn` put sect + event。
/// - Isar 未 init 时(widget test 不 init 路径)StreamProvider 退兜底空 stream,
///   resolve no-op,沿 [isarProvider] nullable propagation 体例。

final sectEventServiceProvider = Provider<SectEventService>((ref) {
  final numbers = ref.watch(numbersConfigProvider);
  return SectEventService(numbers: numbers);
});

final sectReputationDecayServiceProvider =
    Provider<SectReputationDecayService>((ref) {
  final numbers = ref.watch(numbersConfigProvider);
  return SectReputationDecayService(numbers: numbers);
});

/// 默认无名宗 Sect 实例(P3.4 spec 初态)。
Sect _defaultSect(DateTime now) => Sect()
  ..id = 1
  ..name = '无名宗'
  ..founderId = 1
  ..sectLevel = 1
  ..sectReputation = 50
  ..totalWins = 0
  ..createdAt = now
  ..lastEventAt = null;

/// Demo 单 sect(id=1)Stream watch。Isar 未 init → 退 [Stream.value] 默认 sect。
final currentSectProvider = StreamProvider<Sect?>((ref) async* {
  final isar = ref.watch(isarProvider);
  final clock = ref.watch(systemClockProvider);
  if (isar == null) {
    yield _defaultSect(clock.now());
    return;
  }
  // ensure exists
  final existing = await isar.sects.get(1);
  if (existing == null) {
    final fresh = _defaultSect(clock.now());
    await isar.writeTxn(() => isar.sects.put(fresh));
  }
  yield* isar.sects.watchObject(1, fireImmediately: true);
});

/// P4.1 1.1 founder_buff cross_sect spec §2:玩家 sect.id 派生 provider。
///
/// Demo 单 sect 假设(`Sect.id=1` 由 [currentSectProvider] lazy-init):
///   - currentSect.value != null → 返 sect.id
///   - currentSect.value == null → 返 null(Sect lazy-init race · caller 端
///     fallback 单 founder isInSect=false 路径维持 P1.1 R5)
///
/// caller(`stage_battle_setup` battle 前 / UI 显示)`ref.watch(playerSectIdProvider)`
/// 拿 int? 传给 `FounderBuffService.isBuffActiveFor` per-character API。
final playerSectIdProvider = Provider<int?>((ref) {
  final sect = ref.watch(currentSectProvider).value;
  return sect?.id;
});

/// active(pending)sect events Stream。
final activeSectEventsProvider =
    StreamProvider<List<SectEvent>>((ref) async* {
  final isar = ref.watch(isarProvider);
  if (isar == null) {
    yield const [];
    return;
  }
  yield* isar.sectEvents
      .filter()
      .statusEqualTo(SectEventStatus.pending)
      .sortByTriggeredAtDesc()
      .watch(fireImmediately: true);
});

/// historical(resolved + expired)sect events Stream(`resolvedAt` 倒序)。
final historicalSectEventsProvider =
    StreamProvider<List<SectEvent>>((ref) async* {
  final isar = ref.watch(isarProvider);
  if (isar == null) {
    yield const [];
    return;
  }
  yield* isar.sectEvents
      .filter()
      .statusEqualTo(SectEventStatus.resolved)
      .or()
      .statusEqualTo(SectEventStatus.expired)
      .sortByResolvedAtDesc()
      .watch(fireImmediately: true);
});

/// resolve 落库 AsyncNotifier(spec §4 三态:win/loss/expired)。
///
/// 体例同 `tutorial_service.markHintRead` async mutation:
/// - service 端算 delta + mutate 返新实例
/// - 本端 `isar.writeTxn` 持久化 sect + event
/// - 上游 StreamProvider watch 自动刷新 UI
class ResolveSectEventNotifier extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() => null;

  Future<void> resolve({
    required Sect sect,
    required SectEvent event,
    required SectOutcome outcome,
  }) async {
    final isar = ref.read(isarProvider);
    final svc = ref.read(sectEventServiceProvider);
    final clock = ref.read(systemClockProvider);
    final (newSect, newEvent) = svc.resolve(
      sect: sect,
      event: event,
      outcome: outcome,
      now: clock.now(),
    );
    if (isar == null) return; // widget test 路径 no-op
    await isar.writeTxn(() async {
      await isar.sects.put(newSect);
      await isar.sectEvents.put(newEvent);

      // P4.1 §12.2 Q7=B mission hook(预埋 · Demo 无 mission trigger
      // 路径 · 1.1 加 SectEventType.mission 触发后自然激活)。
      // 设计:outcome=win + event.type=mission → 50% rng
      // `missionRecruitProb` → 从 SaveData.recruitedDiscipleIds(P1.1 收徒池)
      // 选首个未入派弟子,招入 sect。candidate pool 局限于已收弟子,
      // Q6 A encounter candidate pool 已实装(v1.12 · PR #13 sect_candidates pool 5 NPC) +
      // Q6 B stage_boss 招降已实装(v1.14 · PR #15 BossRecruitConfig + 3 章末大 Boss)。
      if (outcome == SectOutcome.win &&
          newEvent.type == SectEventType.mission) {
        await _maybeRecruitMissionCandidate(isar, newSect);
      }
    });
  }

  Future<void> _maybeRecruitMissionCandidate(Isar isar, Sect sect) async {
    final rng = ref.read(rngProvider);
    final numbers = ref.read(numbersConfigProvider);
    final memberSvc = ref.read(sectMemberServiceProvider);
    if (memberSvc == null) return;
    final prob = numbers.sectManagement.recruit.missionRecruitProb;
    if (rng.nextDouble() >= prob) return;

    final save = await isar.saveDatas.get(0);
    if (save == null) return;
    final candidates = save.recruitedDiscipleIds;
    if (candidates.isEmpty) return;
    for (final id in candidates) {
      final c = await isar.characters.get(id);
      if (c != null && !c.isInSect) {
        await memberSvc.recruit(
          targetCharacterId: id,
          sectId: sect.id,
          numbers: numbers,
        );
        break;
      }
    }
  }
}

final resolveSectEventProvider =
    AsyncNotifierProvider<ResolveSectEventNotifier, void>(
  ResolveSectEventNotifier.new,
);

// =============================================================================
// P4.1 §12.2 帮派门派 B2 service + provider 接入(default 决议 Q1-Q8 草案)
// =============================================================================

/// 门派成员服务([SectMemberService] · Q2=C 双向 fk + Q5=A 三阶)。
///
/// **nullable propagation**(沿 `recruitmentServiceProvider` 体例):
/// Isar 未 init(widget test fixture)→ null,caller 端 null-coalesce 跳过。
final sectMemberServiceProvider = Provider<SectMemberService?>((ref) {
  final isar = ref.watch(isarProvider);
  if (isar == null) return null;
  return SectMemberService(isar);
});

/// 山头领地服务([TerritoryService] · Q4=A 静态 yaml + dynamic owner)。
final territoryServiceProvider = Provider<TerritoryService?>((ref) {
  final isar = ref.watch(isarProvider);
  if (isar == null) return null;
  return TerritoryService(isar);
});

/// [sectId] 全成员 Stream(沿 `Character.sectId` index)。
///
/// Isar 未 init → 退空 Stream。Demo 单 sect 用 sect.id=1。
final sectMembersProvider =
    StreamProvider.family<List<Character>, int>((ref, sectId) async* {
  final isar = ref.watch(isarProvider);
  if (isar == null) {
    yield const [];
    return;
  }
  yield* isar.characters
      .filter()
      .sectIdEqualTo(sectId)
      .watch(fireImmediately: true);
});

/// 中立可占领的 territory list(`TerritoryService.availableForClaim`)。
final availableTerritoriesProvider =
    FutureProvider<List<TerritoryDef>>((ref) async {
  final svc = ref.watch(territoryServiceProvider);
  if (svc == null) return TerritoryService.allDefs();
  // sect 写入触发 invalidate(caller `ref.invalidate(availableTerritoriesProvider)`
  // after claim/release writeTxn · 沿 resolveSectEventProvider 体例)。
  return svc.availableForClaim();
});

/// 招收 + 升阶 + 退派 AsyncNotifier(B2 spec §3 · 沿 [ResolveSectEventNotifier] 体例)。
///
/// caller 端用法:`ref.read(sectMemberMutationProvider.notifier).recruit(...)`
class SectMemberMutationNotifier extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() => null;

  Future<RecruitResult> recruit({
    required int targetCharacterId,
    required int sectId,
  }) async {
    final isar = ref.read(isarProvider);
    final svc = ref.read(sectMemberServiceProvider);
    final numbers = ref.read(numbersConfigProvider);
    if (isar == null || svc == null) return RecruitResult.targetNotFound;
    late RecruitResult result;
    await isar.writeTxn(() async {
      result = await svc.recruit(
        targetCharacterId: targetCharacterId,
        sectId: sectId,
        numbers: numbers,
      );
    });
    return result;
  }

  Future<PromoteResult> promoteRank({
    required int characterId,
    required int contribution,
  }) async {
    final isar = ref.read(isarProvider);
    final svc = ref.read(sectMemberServiceProvider);
    final numbers = ref.read(numbersConfigProvider);
    if (isar == null || svc == null) return PromoteResult.characterNotFound;
    late PromoteResult result;
    await isar.writeTxn(() async {
      result = await svc.promoteRank(
        characterId: characterId,
        contribution: contribution,
        numbers: numbers,
      );
    });
    return result;
  }

  Future<DismissResult> dismiss({required int characterId}) async {
    final isar = ref.read(isarProvider);
    final svc = ref.read(sectMemberServiceProvider);
    if (isar == null || svc == null) return DismissResult.characterNotFound;
    late DismissResult result;
    await isar.writeTxn(() async {
      result = await svc.dismiss(characterId: characterId);
    });
    return result;
  }
}

final sectMemberMutationProvider =
    AsyncNotifierProvider<SectMemberMutationNotifier, void>(
  SectMemberMutationNotifier.new,
);

/// 占领 + 释放 AsyncNotifier(B2 spec §3)。
///
/// caller 端用法:`ref.read(territoryMutationProvider.notifier).claim(...)`
class TerritoryMutationNotifier extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() => null;

  Future<ClaimResult> claim({
    required int sectId,
    required String territoryId,
  }) async {
    final isar = ref.read(isarProvider);
    final svc = ref.read(territoryServiceProvider);
    final numbers = ref.read(numbersConfigProvider);
    if (isar == null || svc == null) return ClaimResult.territoryNotFound;
    late ClaimResult result;
    await isar.writeTxn(() async {
      result = await svc.claim(
        sectId: sectId,
        territoryId: territoryId,
        numbers: numbers,
      );
    });
    return result;
  }

  Future<ReleaseResult> release({
    required int sectId,
    required String territoryId,
  }) async {
    final isar = ref.read(isarProvider);
    final svc = ref.read(territoryServiceProvider);
    if (isar == null || svc == null) return ReleaseResult.sectNotFound;
    late ReleaseResult result;
    await isar.writeTxn(() async {
      result = await svc.release(
        sectId: sectId,
        territoryId: territoryId,
      );
    });
    return result;
  }
}

final territoryMutationProvider =
    AsyncNotifierProvider<TerritoryMutationNotifier, void>(
  TerritoryMutationNotifier.new,
);

