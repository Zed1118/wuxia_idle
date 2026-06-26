import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/core/domain/attributes.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/isar_setup.dart';

/// 第八阶段 A·角色等级 Lv 安全网回填 TDD(真 bug 修复)。
///
/// Isar 不应用 Dart 字段默认值:旧档 Character 无 level 字段读回 int64 哨兵(负数)。
/// `repairCharacterLevels` 幂等修复 level<1 / levelExp<0 的角色为 1/0。
void main() {
  setUpAll(() async {
    await Isar.initializeIsarCore(download: true);
  });

  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('wuxia_lv_repair_');
  });

  tearDown(() async {
    if (Isar.getInstance('wuxia_save_slot1') != null) {
      await IsarSetup.close();
    }
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  Character mkChar({required int level, required int levelExp}) =>
      Character.create(
        name: '旧档角色',
        realmTier: RealmTier.erLiu,
        realmLayer: RealmLayer.qiMeng,
        attributes: Attributes(),
        rarity: RarityTier.xunChang,
        lineageRole: LineageRole.founder,
        createdAt: DateTime(2026, 1, 1),
      )
        ..level = level
        ..levelExp = levelExp;

  test('哨兵 level(int64 min)→ 重置 level=1 / levelExp=0', () async {
    await IsarSetup.init(directory: tempDir, inspector: false);
    final isar = IsarSetup.instance;
    // 模拟旧档读回:level/levelExp 为 Isar 非空 int 哨兵。
    await isar.writeTxn(() async {
      await isar.characters.put(
        mkChar(level: -9223372036854775808, levelExp: -9223372036854775808),
      );
    });

    await IsarSetup.repairCharacterLevels(isar);

    final fixed = (await isar.characters.where().findAll()).single;
    expect(fixed.level, 1);
    expect(fixed.levelExp, 0);
  });

  test('合法角色(level≥1)幂等不动', () async {
    await IsarSetup.init(directory: tempDir, inspector: false);
    final isar = IsarSetup.instance;
    await isar.writeTxn(() async {
      await isar.characters.put(mkChar(level: 7, levelExp: 55));
    });

    await IsarSetup.repairCharacterLevels(isar);

    final c = (await isar.characters.where().findAll()).single;
    expect(c.level, 7, reason: '合法 level 不被重置');
    expect(c.levelExp, 55);
  });
}
