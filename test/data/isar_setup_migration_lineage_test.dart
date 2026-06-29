import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/core/domain/attributes.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/domain/save_data.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/isar_setup.dart';

/// 第七阶段批三 Task 4：存档 0.24.0 → 0.25.0 迁移测试。
///
/// 老档(<0.25.0)已由旧 onboarding 种满 3 人队,两名命名弟子 lineageRole 都还是
/// disciple。迁移须:
///   a) 把 founder.discipleIds 顺序前 2 位 disciple → senior / junior(通用收徒弟
///      子,即不在 discipleIds 里的,不动);
///   b) 预填 SaveData.triggeredDiscipleJoinStageIds 为全部配置的 join stage id
///      (弟子已在 → hook 不再触发、不重建弟子);
///   c) 弟子不得被删除或改动 lineageRole 之外的任何数据。
void main() {
  setUpAll(() async {
    await Isar.initializeIsarCore(download: true);
    // 迁移段 b 需要 lineageOnboarding.joinStageIds → 必须先加载 defs。
    if (!GameRepository.isLoaded) {
      await GameRepository.loadAllDefs(
        loader: (path) => File(path).readAsString(),
      );
    }
  });

  group('0.24.0 → 0.25.0 队伍成长迁移', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp(
        'wuxia_isar_mig_lineage_',
      );
    });

    tearDown(() async {
      if (Isar.getInstance('wuxia_save_slot1') != null) {
        await IsarSetup.close();
      }
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    Character makeChar({
      required String name,
      required LineageRole role,
      bool isFounder = false,
      int? masterId,
      List<int>? discipleIds,
    }) {
      final attrs = Attributes()
        ..constitution = 5
        ..enlightenment = 5
        ..agility = 5
        ..fortune = 5;
      return Character.create(
        name: name,
        realmTier: RealmTier.xueTu,
        realmLayer: RealmLayer.qiMeng,
        attributes: attrs,
        rarity: RarityTier.xunChang,
        lineageRole: role,
        createdAt: DateTime(2026, 1, 1),
        internalForce: 100,
        internalForceMax: 100,
        school: TechniqueSchool.gangMeng,
        isFounder: isFounder,
        masterId: masterId,
        discipleIds: discipleIds,
        isActive: true,
      );
    }

    test('命名弟子 role 重映射 + 拜入预填 + 弟子数据不变', () async {
      // 构造 0.24.0 旧档:满 3 人队,两弟子 role 仍 disciple。
      await IsarSetup.init(directory: tempDir, inspector: false);
      await IsarSetup.instance.writeTxn(() async {
        final isar = IsarSetup.instance;
        // 先建 founder(id=1)与两弟子(id=2,3),isar autoIncrement。
        final founder = makeChar(
          name: '祖师',
          role: LineageRole.founder,
          isFounder: true,
          discipleIds: [2, 3],
        );
        final senior = makeChar(
          name: '大弟子',
          role: LineageRole.disciple,
          masterId: 1,
        );
        final junior = makeChar(
          name: '二弟子',
          role: LineageRole.disciple,
          masterId: 1,
        );
        // 通用收徒弟子(id=4):不在 founder.discipleIds 里,迁移不应改动其 role。
        final generic = makeChar(name: '普通弟子', role: LineageRole.disciple);
        await isar.characters.put(founder);
        await isar.characters.put(senior);
        await isar.characters.put(junior);
        await isar.characters.put(generic);
        // 确认 id 落到 1/2/3/4(fresh isar autoIncrement 从 1 起)。
        expect(founder.id, 1);
        expect(senior.id, 2);
        expect(junior.id, 3);
        expect(generic.id, 4);

        final save = (await isar.saveDatas.get(0))!;
        save
          ..saveVersion = '0.24.0'
          ..activeCharacterIds = [1, 2, 3]
          ..founderCharacterId = 1
          ..triggeredDiscipleJoinStageIds = [];
        await isar.saveDatas.put(save);
      });
      await IsarSetup.close();

      // 重开 → _ensureSaveData 检版本差 → 跑迁移。
      await IsarSetup.init(directory: tempDir, inspector: false);
      final isar = IsarSetup.instance;
      final save = (await isar.saveDatas.get(0))!;
      final senior = (await isar.characters.get(2))!;
      final junior = (await isar.characters.get(3))!;

      // ① id=2 → senior
      expect(senior.lineageRole, LineageRole.senior);
      // ② id=3 → junior
      expect(junior.lineageRole, LineageRole.junior);
      // ③ 当前 config 的 join stage id 全部预填(spec A 后移后 = {stage_06_05};
      //    用 live config 断言防未来配置改动再次硬编码失配)。
      final expectedJoinIds =
          GameRepository.instance.numbers.lineageOnboarding.joinStageIds;
      expect(
        expectedJoinIds,
        contains('stage_06_05'),
        reason: 'spec A:弟子拜入关已后移至 stage_06_05',
      );
      expect(
        save.triggeredDiscipleJoinStageIds.toSet(),
        containsAll(expectedJoinIds),
        reason: '迁移预填全部当前 join stage id,防 hook 重触发',
      );
      // ④ 版本升到当前版本
      expect(save.saveVersion, IsarSetup.currentSaveVersion);
      // ⑤ activeCharacterIds 未动(弟子未删/未改)
      expect(save.activeCharacterIds, [1, 2, 3]);
      // 弟子其余数据未动
      expect(senior.name, '大弟子');
      expect(senior.masterId, 1);
      expect(junior.name, '二弟子');
      // ⑥ 通用收徒弟子(不在 discipleIds)→ role 保持 disciple,不被重映射
      final generic = (await isar.characters.get(4))!;
      expect(generic.lineageRole, LineageRole.disciple);
    });

    test('幂等:已 senior/junior 的弟子重跑迁移不被回写', () async {
      await IsarSetup.init(directory: tempDir, inspector: false);
      await IsarSetup.instance.writeTxn(() async {
        final isar = IsarSetup.instance;
        final founder = makeChar(
          name: '祖师',
          role: LineageRole.founder,
          isFounder: true,
          discipleIds: [2, 3],
        );
        final senior = makeChar(
          name: '大弟子',
          role: LineageRole.senior, // 已是 senior
          masterId: 1,
        );
        final junior = makeChar(
          name: '二弟子',
          role: LineageRole.junior, // 已是 junior
          masterId: 1,
        );
        await isar.characters.put(founder);
        await isar.characters.put(senior);
        await isar.characters.put(junior);

        final save = (await isar.saveDatas.get(0))!;
        save
          ..saveVersion = '0.24.0'
          ..activeCharacterIds = [1, 2, 3]
          ..founderCharacterId = 1;
        await isar.saveDatas.put(save);
      });
      await IsarSetup.close();

      await IsarSetup.init(directory: tempDir, inspector: false);
      final isar = IsarSetup.instance;
      final senior = (await isar.characters.get(2))!;
      final junior = (await isar.characters.get(3))!;
      expect(senior.lineageRole, LineageRole.senior);
      expect(junior.lineageRole, LineageRole.junior);
    });
  });
}
