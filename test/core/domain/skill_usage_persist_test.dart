import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/domain/skill_usage_entry.dart';
import 'package:wuxia_idle/core/domain/technique.dart';

/// W13 fix 回归：Isar `@embedded List<SkillUsageEntry>` 反序列化为
/// fixed-length list，`MapLikeOnSkillUsage.increment` 走 add 分支会抛
/// `UnsupportedError: Cannot add to a fixed-length list`。
///
/// W11 #32 销账时只用 [Technique.create] 内存构造 list(growable)走 service
/// test，漏掉真持久化路径。本 spec 验证：
///   1. Isar findAll 后直接调 `.increment(newSkillId)` → 抛
///   2. `skillUsageCount = List.of(...)` 转 growable 再调 → 通过
void main() {
  late Directory tempDir;

  setUpAll(() async {
    await Isar.initializeIsarCore(download: true);
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('wuxia_skillusage_test_');
    await IsarSetup.init(directory: tempDir, inspector: false);
  });

  tearDown(() async {
    if (Isar.getInstance('wuxia_save_slot1') != null) {
      await IsarSetup.close();
    }
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  Future<Technique> putAndReload(Technique tech) async {
    final isar = IsarSetup.instance;
    await isar.writeTxn(() => isar.techniques.put(tech));
    final reloaded = await isar.techniques.get(tech.id);
    expect(reloaded, isNotNull);
    return reloaded!;
  }

  test('Isar findAll 后直接 increment 新 skillId → 抛 fixed-length 异常',
      () async {
    final tech = Technique.create(
      defId: 'tech_test',
      ownerCharacterId: 1,
      tier: TechniqueTier.changLianGong,
      school: TechniqueSchool.gangMeng,
      role: TechniqueRole.main,
      learnedAt: DateTime.now(),
      cultivationLayer: CultivationLayer.chuKui,
      cultivationProgress: 0,
      cultivationProgressToNext: 100,
    );
    final reloaded = await putAndReload(tech);

    expect(
      () => reloaded.skillUsageCount.increment('skill_new', 1),
      throwsA(isA<UnsupportedError>()),
      reason: 'Isar @embedded List<SkillUsageEntry> 反序列化是 fixed-length，'
          'increment add 分支会抛。W13 之前 catch (_) 静默吞掉。',
    );
  });

  test('List.of 转 growable 后 increment 通过（W13 fix 路径）',
      () async {
    final tech = Technique.create(
      defId: 'tech_test',
      ownerCharacterId: 1,
      tier: TechniqueTier.changLianGong,
      school: TechniqueSchool.gangMeng,
      role: TechniqueRole.main,
      learnedAt: DateTime.now(),
      cultivationLayer: CultivationLayer.chuKui,
      cultivationProgress: 0,
      cultivationProgressToNext: 100,
    );
    final reloaded = await putAndReload(tech);

    // W13 fix 路径：caller 端在拉 Isar 后立刻转 growable
    reloaded.skillUsageCount = List.of(reloaded.skillUsageCount);
    reloaded.skillUsageCount.increment('skill_new', 3);

    expect(reloaded.skillUsageCount.length, 1);
    expect(reloaded.skillUsageCount.first.skillId, 'skill_new');
    expect(reloaded.skillUsageCount.first.count, 3);
  });

  test('已存在 skillId 的 increment 直接累加，不走 add 分支 → 不抛',
      () async {
    final tech = Technique.create(
      defId: 'tech_test',
      ownerCharacterId: 1,
      tier: TechniqueTier.changLianGong,
      school: TechniqueSchool.gangMeng,
      role: TechniqueRole.main,
      learnedAt: DateTime.now(),
      cultivationLayer: CultivationLayer.chuKui,
      cultivationProgress: 0,
      cultivationProgressToNext: 100,
      skillUsageCount: [
        SkillUsageEntry()
          ..skillId = 'skill_exist'
          ..count = 5,
      ],
    );
    final reloaded = await putAndReload(tech);

    // 同 skillId 走 line 27 的 this[idx].count += delta，不走 add → 不抛
    reloaded.skillUsageCount.increment('skill_exist', 2);
    expect(reloaded.skillUsageCount.first.count, 7);
  });
}
