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

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('wuxia_expedition_provider_');
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
}
