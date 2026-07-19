import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/attributes.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/domain/save_data.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/features/expedition/application/expedition_providers.dart';
import 'package:wuxia_idle/features/expedition/domain/expedition_run.dart';

import '../../support/isar_test_support.dart';

Character _char({
  required String name,
  bool isFounder = false,
  bool isActive = false,
  int? mainTechniqueId,
}) => Character()
  ..name = name
  ..realmTier = RealmTier.sanLiu
  ..realmLayer = RealmLayer.qiMeng
  ..attributes = Attributes()
  ..rarity = RarityTier.biaoZhun
  ..lineageRole = LineageRole.disciple
  ..createdAt = DateTime(2026, 7, 16)
  ..isFounder = isFounder
  ..isActive = isActive
  ..mainTechniqueId = mainTechniqueId;

void main() {
  late Directory tempDir;

  setUpAll(() => initializeTestIsarCore());

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp(
      'wuxia_expedition_provider_',
    );
    await IsarSetup.init(directory: tempDir, inspector: false);
    await IsarSetup.instance.writeTxn(() async {
      await IsarSetup.instance.saveDatas.put(
        SaveData()
          ..id = 0
          ..saveVersion = '0.37.0'
          ..createdAt = DateTime(2026, 7, 16)
          ..lastSavedAt = DateTime(2026, 7, 16)
          ..lastOnlineAt = DateTime(2026, 7, 16),
      );
    });
  });

  tearDown(() async {
    await IsarSetup.close();
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  test('activeExpedition：无远征 → null；派遣后失效重读 → 返回 run', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(await container.read(activeExpeditionProvider.future), isNull);

    late int cid;
    await IsarSetup.instance.writeTxn(() async {
      cid = await IsarSetup.instance.characters.put(
        Character()
          ..name = '弟子'
          ..realmTier = RealmTier.sanLiu
          ..realmLayer = RealmLayer.qiMeng
          ..attributes = Attributes()
          ..rarity = RarityTier.biaoZhun
          ..lineageRole = LineageRole.disciple
          ..createdAt = DateTime(2026, 7, 16)
          ..isFounder = false
          ..mainTechniqueId = 5,
      );
    });

    final svc = container.read(expeditionServiceProvider)!;
    await svc.dispatch(
      characterIds: [cid],
      policy: ExpeditionPolicy.yanJingCaiYao,
      now: DateTime(2026, 7, 16, 10),
    );

    container.invalidate(activeExpeditionProvider);
    final run = await container.read(activeExpeditionProvider.future);
    expect(run, isNotNull);
    expect(run!.members.single.characterId, cid);
  });

  test(
    'expeditionCandidates：active非祖师∪reserve，排除祖师，标 hasMain/occupied',
    () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      late int founderId, aId, bId, cId;
      await IsarSetup.instance.writeTxn(() async {
        founderId = await IsarSetup.instance.characters.put(
          _char(
            name: '祖师',
            isFounder: true,
            isActive: true,
            mainTechniqueId: 1,
          ),
        );
        aId = await IsarSetup.instance.characters.put(
          _char(name: '甲', isActive: true, mainTechniqueId: 5),
        );
        bId = await IsarSetup.instance.characters.put(
          _char(name: '乙', mainTechniqueId: 6),
        );
        cId = await IsarSetup.instance.characters.put(_char(name: '丙'));
        final save = await IsarSetup.instance.saveDatas.get(0);
        save!.activeCharacterIds = [founderId, aId];
        await IsarSetup.instance.saveDatas.put(save);
      });

      final candidates = await container.read(
        expeditionCandidatesProvider.future,
      );
      final byId = {for (final c in candidates) c.character.id: c};
      expect(byId.containsKey(founderId), isFalse, reason: '祖师不入候选池');
      expect(byId.keys, containsAll([aId, bId, cId]));
      expect(byId[aId]!.hasMainTechnique, isTrue);
      expect(byId[cId]!.hasMainTechnique, isFalse, reason: '丙未修主修');
      expect(byId[cId]!.dispatchable, isFalse);
      expect(candidates.every((c) => !c.occupied), isTrue, reason: '尚无远征占用');

      // 派遣甲 → 甲被占用、不可再派。
      final svc = container.read(expeditionServiceProvider)!;
      await svc.dispatch(
        characterIds: [aId],
        policy: ExpeditionPolicy.yanJingCaiYao,
        now: DateTime(2026, 7, 16, 10),
      );
      container.invalidate(expeditionCandidatesProvider);
      final after = await container.read(expeditionCandidatesProvider.future);
      final a2 = after.firstWhere((c) => c.character.id == aId);
      expect(a2.occupied, isTrue);
      expect(a2.dispatchable, isFalse);
    },
  );
}
