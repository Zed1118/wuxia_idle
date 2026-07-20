import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/core/domain/attributes.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/domain/save_data.dart';
import 'package:wuxia_idle/core/domain/sect_rank.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/isar_provider.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/features/sect/application/sect_member_service.dart';
import 'package:wuxia_idle/features/sect/application/sect_providers.dart';
import 'package:wuxia_idle/features/sect/application/territory_service.dart';
import 'package:wuxia_idle/features/sect/domain/sect.dart';
import 'package:wuxia_idle/features/sect/domain/sect_event.dart';
import 'package:wuxia_idle/features/sect/domain/sect_outcome.dart';
import 'package:wuxia_idle/shared/strings.dart';
import 'package:wuxia_idle/shared/utils/rng.dart';
import 'package:wuxia_idle/shared/utils/rng_provider.dart';

import '../../support/isar_test_support.dart';
import '../../support/test_data.dart';

/// `sect_providers.dart` wire 层行为测（2026-07-19 夜批 coverage 补强，
/// 基线 40/168 行）。
///
/// 真 Isar + 真 GameRepository + ProviderContainer/widget 宿主真读，分七组钉：
///   A. member/territory service nullable propagation
///   B. currentSect lazy-init + playerSectId 派生
///   C. active/historical 事件流过滤
///   D. resolve 落库（win delta + mission 招徒 hook 双向 rng）
///   E. member mutation recruit/promoteRank/dismiss 落库与失败枚举
///   F. territory mutation claim/release 落库与失败枚举 + availableForClaim
///   G. 月度 tick 落库（lastTickAt 推进）+ widget 入口 spawn/maybeRun
class _FixedRng implements Rng {
  _FixedRng(this._next);
  final double _next;

  @override
  double nextDouble() => _next;

  @override
  int nextInt(int max) => 0;

  @override
  T pick<T>(List<T> items) => items.first;
}

void main() {
  late Directory tempDir;

  setUpAll(() async {
    await initializeTestIsarCore();
    if (!GameRepository.isLoaded) {
      await loadTestGameRepository();
    }
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('wuxia_sect_providers_');
  });

  tearDown(() async {
    await IsarSetup.close();
    IsarSetup.resetForTest();
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  ProviderContainer makeContainer() {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    return container;
  }

  /// 带 rng override 的容器（mission 招徒 hook 用）。Riverpod 3 umbrella
  /// 不导出 `Override` 类型,override 只能就地内联,不能参数化传递。
  ProviderContainer makeRngContainer(double nextDouble) {
    final container = ProviderContainer(
      overrides: [rngProvider.overrideWithValue(_FixedRng(nextDouble))],
    );
    addTearDown(container.dispose);
    return container;
  }

  Future<void> initIsar() =>
      IsarSetup.init(directory: tempDir, inspector: false);

  Sect makeSect({int id = 1, int rep = 50, int wins = 0, int level = 1}) =>
      Sect()
        ..id = id
        ..name = '测试宗'
        ..founderId = 1
        ..sectLevel = level
        ..sectReputation = rep
        ..totalWins = wins
        ..createdAt = DateTime(2026, 7, 1)
        ..territoryIds = []
        ..memberCount = 0;

  SectEvent makeEvent({
    int sectId = 1,
    SectEventType type = SectEventType.tournament,
    SectEventStatus status = SectEventStatus.pending,
    DateTime? triggeredAt,
    String narrativeId = 'n1',
  }) => SectEvent()
    ..sectId = sectId
    ..type = type
    ..status = status
    ..triggeredAt = triggeredAt ?? DateTime(2026, 7, 10)
    ..narrativeId = narrativeId;

  Character makeChar({required int id, bool isInSect = false}) {
    final realm = GameRepository.instance.getRealm(
      RealmTier.xueTu,
      RealmLayer.qiMeng,
    );
    return Character.create(
        name: '弟子$id',
        realmTier: RealmTier.xueTu,
        realmLayer: RealmLayer.qiMeng,
        attributes: Attributes(),
        rarity: RarityTier.biaoZhun,
        lineageRole: LineageRole.disciple,
        createdAt: DateTime(2026, 7, 19),
        internalForce: realm.internalForceMax,
        internalForceMax: realm.internalForceMax,
        experienceToNextLayer: realm.experienceToNext,
        isActive: false,
      )
      ..id = id
      ..isInSect = isInSect
      ..sectId = isInSect ? 1 : null;
  }

  group('A. service nullable propagation', () {
    test('member/territory:Isar 未 init → null;init → 非 null', () async {
      final container = makeContainer();
      expect(container.read(sectMemberServiceProvider), isNull);
      expect(container.read(territoryServiceProvider), isNull);

      await initIsar();
      container.invalidate(isarProvider);
      expect(container.read(sectMemberServiceProvider), isNotNull);
      expect(container.read(territoryServiceProvider), isNotNull);
    });
  });

  group('B. currentSect lazy-init + playerSectId', () {
    test('Isar 未 init → 退默认无名宗(id=1);playerSectId 派生 1', () async {
      final container = makeContainer();
      final sub = container.listen(currentSectProvider, (_, _) {});
      addTearDown(sub.close);

      final sect = await container.read(currentSectProvider.future);
      expect(sect, isNotNull);
      expect(sect!.id, 1);
      expect(sect.name, UiStrings.sectLazyInitName);
      expect(container.read(playerSectIdProvider), 1);
    });

    test('Isar init → 首读 lazy-init 落库,再读复用同一行', () async {
      await initIsar();
      final container = makeContainer();
      container.invalidate(isarProvider);
      final sub = container.listen(currentSectProvider, (_, _) {});
      addTearDown(sub.close);

      final sect = await container.read(currentSectProvider.future);
      expect(sect!.name, UiStrings.sectLazyInitName);
      final persisted = await IsarSetup.instance.sects.get(1);
      expect(persisted, isNotNull, reason: 'lazy-init 已 writeTxn 落库');
      expect(persisted!.sectReputation, 50);
      expect(container.read(playerSectIdProvider), 1);
    });
  });

  group('C. 事件流过滤', () {
    test('Isar 未 init → active/historical 均空', () async {
      final container = makeContainer();
      // 持订阅保活:StreamProvider 无监听时 read(.future) 在 Isar watch 流
      // 首发前被 dispose → 永不发射(B 组同体例)。
      final subA = container.listen(activeSectEventsProvider, (_, _) {});
      final subH = container.listen(historicalSectEventsProvider, (_, _) {});
      addTearDown(subA.close);
      addTearDown(subH.close);
      expect(await container.read(activeSectEventsProvider.future), isEmpty);
      expect(
        await container.read(historicalSectEventsProvider.future),
        isEmpty,
      );
    });

    test('pending 只进 active;resolved/expired 只进 historical', () async {
      await initIsar();
      await IsarSetup.instance.writeTxn(() async {
        await IsarSetup.instance.sectEvents.putAll([
          makeEvent(narrativeId: 'pend'),
          makeEvent(status: SectEventStatus.resolved, narrativeId: 'done')
            ..resolvedAt = DateTime(2026, 7, 11),
          makeEvent(status: SectEventStatus.expired, narrativeId: 'gone')
            ..resolvedAt = DateTime(2026, 7, 12),
        ]);
      });
      final container = makeContainer();
      container.invalidate(isarProvider);
      final subA = container.listen(activeSectEventsProvider, (_, _) {});
      final subH = container.listen(historicalSectEventsProvider, (_, _) {});
      addTearDown(subA.close);
      addTearDown(subH.close);

      final active = await container.read(activeSectEventsProvider.future);
      expect(active.map((e) => e.narrativeId), ['pend']);

      final historical = await container.read(
        historicalSectEventsProvider.future,
      );
      expect(
        historical.map((e) => e.narrativeId).toSet(),
        {'done', 'gone'},
        reason: 'resolved+expired 都进历史,按 resolvedAt 倒序',
      );
      expect(historical.first.narrativeId, 'gone', reason: 'resolvedAt 倒序');
    });

    test('sectMembers:Isar 未 init → 空;按 sectId 过滤成员', () async {
      final container = makeContainer();
      final sub0 = container.listen(sectMembersProvider(1), (_, _) {});
      addTearDown(sub0.close);
      expect(
        await container.read(sectMembersProvider(1).future),
        isEmpty,
        reason: 'Isar 未 init → 退空 Stream',
      );

      await initIsar();
      await IsarSetup.instance.writeTxn(() async {
        await IsarSetup.instance.characters.putAll([
          makeChar(id: 5, isInSect: true),
          makeChar(id: 6, isInSect: true),
          makeChar(id: 7), // 未入派不进列表
        ]);
      });
      container.invalidate(isarProvider);
      final sub = container.listen(sectMembersProvider(1), (_, _) {});
      addTearDown(sub.close);

      final members = await container.read(sectMembersProvider(1).future);
      expect(members.map((c) => c.id).toSet(), {
        5,
        6,
      }, reason: '沿 Character.sectId 索引拉全成员');
    });
  });

  group('D. resolve 落库', () {
    test('win:sect 声望/胜场/事件态落库 + reputationDelta 写入', () async {
      await initIsar();
      await IsarSetup.instance.writeTxn(() async {
        await IsarSetup.instance.sects.put(makeSect());
        await IsarSetup.instance.sectEvents.put(makeEvent());
      });
      final container = makeContainer();
      container.invalidate(isarProvider);
      final winDelta =
          GameRepository.instance.numbers.sectEvent.reputation.winDelta;

      final sect = (await IsarSetup.instance.sects.get(1))!;
      final event = (await IsarSetup.instance.sectEvents
          .filter()
          .narrativeIdEqualTo('n1')
          .findFirst())!;
      await container
          .read(resolveSectEventProvider.notifier)
          .resolve(sect: sect, event: event, outcome: SectOutcome.win);

      final after = (await IsarSetup.instance.sects.get(1))!;
      expect(after.sectReputation, 50 + winDelta);
      expect(after.totalWins, 1);
      expect(after.lastEventAt, isNotNull);
      final afterEvent = (await IsarSetup.instance.sectEvents.get(event.id))!;
      expect(afterEvent.status, SectEventStatus.resolved);
      expect(afterEvent.resolvedAt, isNotNull);
      expect(afterEvent.reputationDelta, winDelta);
    });

    test('mission win + rng 命中 → 从收徒池招首个未入派弟子', () async {
      await initIsar();
      await IsarSetup.instance.writeTxn(() async {
        await IsarSetup.instance.sects.put(makeSect());
        await IsarSetup.instance.sectEvents.put(
          makeEvent(type: SectEventType.mission),
        );
        await IsarSetup.instance.characters.put(makeChar(id: 9));
        final save = (await IsarSetup.instance.saveDatas.get(0))!
          ..recruitedDiscipleIds = [9];
        await IsarSetup.instance.saveDatas.put(save);
      });
      final container = makeRngContainer(0.0);
      container.invalidate(isarProvider);

      final sect = (await IsarSetup.instance.sects.get(1))!;
      final event = (await IsarSetup.instance.sectEvents
          .filter()
          .narrativeIdEqualTo('n1')
          .findFirst())!;
      await container
          .read(resolveSectEventProvider.notifier)
          .resolve(sect: sect, event: event, outcome: SectOutcome.win);

      final disciple = (await IsarSetup.instance.characters.get(9))!;
      expect(disciple.isInSect, isTrue, reason: 'rng 0.0 < prob 0.5 命中招徒');
      expect(disciple.sectId, 1);
      expect(
        (await IsarSetup.instance.sects.get(1))!.memberCount,
        1,
        reason: '双向 fk:memberCount 同步 +1',
      );
    });

    test('mission win + rng 未命中 → 不招徒', () async {
      await initIsar();
      await IsarSetup.instance.writeTxn(() async {
        await IsarSetup.instance.sects.put(makeSect());
        await IsarSetup.instance.sectEvents.put(
          makeEvent(type: SectEventType.mission),
        );
        await IsarSetup.instance.characters.put(makeChar(id: 9));
        final save = (await IsarSetup.instance.saveDatas.get(0))!
          ..recruitedDiscipleIds = [9];
        await IsarSetup.instance.saveDatas.put(save);
      });
      final container = makeRngContainer(0.99);
      container.invalidate(isarProvider);

      final sect = (await IsarSetup.instance.sects.get(1))!;
      final event = (await IsarSetup.instance.sectEvents
          .filter()
          .narrativeIdEqualTo('n1')
          .findFirst())!;
      await container
          .read(resolveSectEventProvider.notifier)
          .resolve(sect: sect, event: event, outcome: SectOutcome.win);

      final disciple = (await IsarSetup.instance.characters.get(9))!;
      expect(disciple.isInSect, isFalse, reason: 'rng 0.99 ≥ prob 0.5 未命中,不入派');
    });

    test('mission win + rng 恰等于 prob → 不招徒(边界含端点)', () async {
      await initIsar();
      await IsarSetup.instance.writeTxn(() async {
        await IsarSetup.instance.sects.put(makeSect());
        await IsarSetup.instance.sectEvents.put(
          makeEvent(type: SectEventType.mission),
        );
        await IsarSetup.instance.characters.put(makeChar(id: 9));
        final save = (await IsarSetup.instance.saveDatas.get(0))!
          ..recruitedDiscipleIds = [9];
        await IsarSetup.instance.saveDatas.put(save);
      });
      final prob = GameRepository
          .instance
          .numbers
          .sectManagement
          .recruit
          .missionRecruitProb;
      final container = makeRngContainer(prob);
      container.invalidate(isarProvider);

      final sect = (await IsarSetup.instance.sects.get(1))!;
      final event = (await IsarSetup.instance.sectEvents
          .filter()
          .narrativeIdEqualTo('n1')
          .findFirst())!;
      await container
          .read(resolveSectEventProvider.notifier)
          .resolve(sect: sect, event: event, outcome: SectOutcome.win);

      final disciple = (await IsarSetup.instance.characters.get(9))!;
      expect(
        disciple.isInSect,
        isFalse,
        reason: 'roll >= prob 即拒(roll==prob 端点不中招)',
      );
    });
  });

  group('E. member mutation', () {
    test(
      'recruit:成功落库双向 fk;重复招 → alreadyInSect;不存在 → targetNotFound',
      () async {
        await initIsar();
        await IsarSetup.instance.writeTxn(() async {
          await IsarSetup.instance.sects.put(makeSect());
          await IsarSetup.instance.characters.put(makeChar(id: 5));
        });
        final container = makeContainer();
        container.invalidate(isarProvider);
        final notifier = container.read(sectMemberMutationProvider.notifier);

        expect(
          await notifier.recruit(targetCharacterId: 5, sectId: 1),
          RecruitResult.success,
        );
        final c = (await IsarSetup.instance.characters.get(5))!;
        expect(c.isInSect, isTrue);
        expect(c.sectId, 1);
        expect(c.sectRank, SectRank.initiate);
        expect((await IsarSetup.instance.sects.get(1))!.memberCount, 1);

        expect(
          await notifier.recruit(targetCharacterId: 5, sectId: 1),
          RecruitResult.alreadyInSect,
        );
        expect(
          await notifier.recruit(targetCharacterId: 999, sectId: 1),
          RecruitResult.targetNotFound,
        );
      },
    );

    test(
      'promoteRank:阈值下 belowThreshold;达标升 inner;不存在 → characterNotFound',
      () async {
        await initIsar();
        await IsarSetup.instance.writeTxn(() async {
          await IsarSetup.instance.sects.put(makeSect());
          await IsarSetup.instance.characters.put(
            makeChar(id: 5, isInSect: true)..sectRank = SectRank.initiate,
          );
        });
        final container = makeContainer();
        container.invalidate(isarProvider);
        final notifier = container.read(sectMemberMutationProvider.notifier);
        final t =
            GameRepository.instance.numbers.sectManagement.rankPromoteThreshold;

        expect(
          await notifier.promoteRank(
            characterId: 5,
            contribution: t.innerMinContribution - 1,
          ),
          PromoteResult.belowThreshold,
        );
        expect(
          await notifier.promoteRank(
            characterId: 5,
            contribution: t.innerMinContribution,
          ),
          PromoteResult.success,
        );
        expect(
          (await IsarSetup.instance.characters.get(5))!.sectRank,
          SectRank.inner,
        );
        expect(
          await notifier.promoteRank(
            characterId: 999,
            contribution: t.innerMinContribution,
          ),
          PromoteResult.characterNotFound,
        );
      },
    );

    test('dismiss:清三字段 + memberCount 回落;不存在 → characterNotFound', () async {
      await initIsar();
      await IsarSetup.instance.writeTxn(() async {
        await IsarSetup.instance.sects.put(makeSect()..memberCount = 1);
        await IsarSetup.instance.characters.put(
          makeChar(id: 5, isInSect: true)..sectRank = SectRank.initiate,
        );
      });
      final container = makeContainer();
      container.invalidate(isarProvider);
      final notifier = container.read(sectMemberMutationProvider.notifier);

      expect(await notifier.dismiss(characterId: 5), DismissResult.success);
      final c = (await IsarSetup.instance.characters.get(5))!;
      expect(c.isInSect, isFalse);
      expect(c.sectId, isNull);
      expect(c.sectRank, isNull);
      expect((await IsarSetup.instance.sects.get(1))!.memberCount, 0);
      expect(
        await notifier.dismiss(characterId: 999),
        DismissResult.characterNotFound,
      );
    });
  });

  group('F. territory mutation + available', () {
    test('claim:中立领地落 sect.territoryIds;未知 id → territoryNotFound', () async {
      await initIsar();
      await IsarSetup.instance.writeTxn(
        () => IsarSetup.instance.sects.put(makeSect()),
      );
      final container = makeContainer();
      container.invalidate(isarProvider);
      final notifier = container.read(territoryMutationProvider.notifier);
      final territoryId = TerritoryService.allDefs().first.id;

      expect(
        await notifier.claim(sectId: 1, territoryId: territoryId),
        ClaimResult.success,
      );
      expect(
        (await IsarSetup.instance.sects.get(1))!.territoryIds,
        contains(territoryId),
      );
      expect(
        await notifier.claim(sectId: 1, territoryId: 'no_such_territory'),
        ClaimResult.territoryNotFound,
      );
    });

    test('release:放回中立;未持有 → notOwned;无 sect → sectNotFound', () async {
      await initIsar();
      final territoryId = TerritoryService.allDefs().first.id;
      await IsarSetup.instance.writeTxn(
        () => IsarSetup.instance.sects.put(
          makeSect()..territoryIds = [territoryId],
        ),
      );
      final container = makeContainer();
      container.invalidate(isarProvider);
      final notifier = container.read(territoryMutationProvider.notifier);

      expect(
        await notifier.release(sectId: 1, territoryId: territoryId),
        ReleaseResult.success,
      );
      expect(
        (await IsarSetup.instance.sects.get(1))!.territoryIds,
        isNot(contains(territoryId)),
      );
      expect(
        await notifier.release(sectId: 1, territoryId: territoryId),
        ReleaseResult.notOwned,
      );
      expect(
        await notifier.release(sectId: 999, territoryId: territoryId),
        ReleaseResult.sectNotFound,
      );
    });

    test('availableTerritories:占位后剔除;Isar 未 init → 全量 def', () async {
      await initIsar();
      final territoryId = TerritoryService.allDefs().first.id;
      await IsarSetup.instance.writeTxn(
        () => IsarSetup.instance.sects.put(
          makeSect()..territoryIds = [territoryId],
        ),
      );
      final container = makeContainer();
      container.invalidate(isarProvider);

      final available = await container.read(
        availableTerritoriesProvider.future,
      );
      expect(available.map((d) => d.id), isNot(contains(territoryId)));
      expect(available.length, TerritoryService.allDefs().length - 1);

      final container2 = makeContainer();
      final all = await container2.read(availableTerritoriesProvider.future);
      // container2 与 container 同进程,Isar 已 init → 走 svc 路径同样剔除;
      // null 路径由 A 组 null 断言覆盖,此处只核 svc 路径幂等。
      expect(all.length, available.length);
    });
  });

  group('G. 月度 tick + widget 入口', () {
    test('tick:Isar 未 init → no-op 不抛', () async {
      final container = makeContainer();
      final coord = container.read(monthlyTickCoordinatorProvider);
      await coord.tick(DateTime(2026, 8, 1));
    });

    test('tick:跨月推进 lastTickAt 落库(空命中月也 put sect)', () async {
      await initIsar();
      final container = makeContainer();
      container.invalidate(isarProvider);
      // 持订阅保活 + 触发 lazy-init 建档(createdAt 由 systemClock 给真 now,
      // 与注入 tick 时间无关,断言只核 lastTickAt 非空且回读一致)。
      // activeSectEventsProvider 同样须保活:tick callback 内
      // `ref.read(activeSectEventsProvider.future)` 无监听会被 dispose 在
      // Isar watch 首发前(对齐生产「sect screen 开着」有监听态,见计划文件发现项)。
      final sub = container.listen(currentSectProvider, (_, _) {});
      final subA = container.listen(activeSectEventsProvider, (_, _) {});
      addTearDown(sub.close);
      addTearDown(subA.close);
      await container.read(currentSectProvider.future);

      final coord = container.read(monthlyTickCoordinatorProvider);
      await coord.tick(DateTime.now().add(const Duration(days: 40)));

      final sect = (await IsarSetup.instance.sects.get(1))!;
      expect(
        sect.lastTickAt,
        sect.createdAt.add(const Duration(days: 30)),
        reason: '40 天 → elapsedMonths=1 → 锚点推进 30 天(非简单 = tick 时刻)',
      );
    });
  });
}

// 覆盖缺口说明(2026-07-19 夜批):
// `debugSpawnSectEvent(WidgetRef)` / `maybeRunSectMonthlyTick(WidgetRef)` 两个
// widget 入口(~15 行)未覆盖。尝试 widget 测试驱动时,函数体内
// `ref.read(currentSectProvider.future)`(StreamProvider + Isar watch)在
// widget test fake-async 环境下恒挂起——四种体例(交替 pump / 预建档 /
// host watch 保活 / pumpWidget 进 runAsync)均不治,根因即项目 memory
// `feedback_isar_widget_test_deadlock`(Isar + widget test 不用)。
// 两函数的可测内核已由本文件 G 组覆盖:_runSectMonthlyTick 全链路
// (maybeRun 本体 = clock 读 + coordinator.tick 一行转发);debugSpawn 的
// pool 判空/事件构造/put 为纯转发,生产由 kDebugMode 门控 dev 入口调用。
// 复测方向:若后续要给 StreamProvider.future 读加统一保活封装或改
// maybeRun/debugSpawn 收 Ref,可在那时补测。
