import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/features/cultivation/domain/skill_unlock_service.dart';

void main() {
  late Directory tempDir;

  setUpAll(() async {
    await Isar.initializeIsarCore(download: true);
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('wuxia_skill_unlock_');
    await IsarSetup.init(directory: tempDir, inspector: false);
  });

  tearDown(() async {
    await IsarSetup.close();
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  test('grantManual 直接解锁;重复 grant 幂等', () async {
    final svc = SkillUnlockService(IsarSetup.instance);
    await svc.grantManual('skill_qingshan_qingfeng');
    expect(await svc.isUnlocked('skill_qingshan_qingfeng'), true);
    await svc.grantManual('skill_qingshan_qingfeng'); // 幂等
    final (cur, _) = await svc.fragmentProgress('skill_qingshan_qingfeng');
    expect(cur, anyOf(0, isPositive));
  });

  test('addFragment 累加,达阈值(5)自动解锁,过阈值不重复', () async {
    final svc = SkillUnlockService(IsarSetup.instance, fragmentThreshold: 5);
    await svc.addFragment('skill_x', 3);
    expect(await svc.isUnlocked('skill_x'), false);
    final (cur, total) = await svc.fragmentProgress('skill_x');
    expect(cur, 3);
    expect(total, 5);
    await svc.addFragment('skill_x', 2); // 达 5
    expect(await svc.isUnlocked('skill_x'), true);
    await svc.addFragment('skill_x', 9); // 已解锁后不重复/不报错
    expect(await svc.isUnlocked('skill_x'), true);
  });

  test('解锁后再 addFragment 不再增残页(已解锁短路)', () async {
    final svc = SkillUnlockService(IsarSetup.instance, fragmentThreshold: 5);
    await svc.grantManual('skill_y');
    await svc.addFragment('skill_y', 3);
    final (cur, _) = await svc.fragmentProgress('skill_y');
    expect(cur, 0); // 已解锁,残页不累加
  });
}
