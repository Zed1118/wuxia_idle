import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/defs/tower_floor_def.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/models/enums.dart';

/// Phase 3 T40 · towers.yaml schema + TowerFloorDef + 30 层 fixture
///
/// 覆盖：
///   - fromYaml 解析（含 bossKind null / minor / major / dropTable）
///   - 30 层 fixture 加载（启动校验全过）
///   - floorIndex 1-30 连续唯一
///   - Boss 分布严格（minor 5/15/25、major 10/20/30）
///   - 普通层 narrative 必须 null
///   - 境界曲线（每 5 层升一阶）
///   - getTowerFloor 越界 RangeError
///   - fail-fast：普通层带 narrative / Boss 分布错位 / 层不连续 / Boss HP 越界
void main() {
  Future<String> fileLoader(String path) async {
    final f = File(path);
    if (!await f.exists()) throw FileSystemException('不存在', path);
    return f.readAsString();
  }

  tearDown(GameRepository.resetForTest);

  group('TowerFloorDef.fromYaml', () {
    test('解析普通层（bossKind null + 无 narrative）', () {
      final y = {
        'floorIndex': 1,
        'requiredRealm': 'xueTu',
        'enemyTeam': [
          {
            'id': 'enemy_t01',
            'name': '测试敌',
            'realmTier': 'xueTu',
            'realmLayer': 'qiMeng',
            'school': 'gangMeng',
            'baseHp': 800,
            'baseAttack': 200,
            'baseSpeed': 100,
            'skillIds': ['skill_gangmeng_jichu_basic'],
            'iconPath': 'assets/x.png',
          },
        ],
      };
      final def = TowerFloorDef.fromYaml(y);
      expect(def.floorIndex, 1);
      expect(def.requiredRealm, RealmTier.xueTu);
      expect(def.bossKind, isNull);
      expect(def.isBoss, isFalse);
      expect(def.narrativeOpeningId, isNull);
      expect(def.narrativeVictoryId, isNull);
      expect(def.enemyTeam.length, 1);
      expect(def.dropTable, isEmpty);
    });

    test('解析小 Boss 层（bossKind minor + narrative + dropTable）', () {
      final y = {
        'floorIndex': 5,
        'requiredRealm': 'xueTu',
        'bossKind': 'minor',
        'narrativeOpeningId': 'tower_05_opening',
        'narrativeVictoryId': 'tower_05_victory',
        'enemyTeam': [
          {
            'id': 'boss_05',
            'name': '试剑石老叟',
            'realmTier': 'xueTu',
            'realmLayer': 'dengFeng',
            'school': 'gangMeng',
            'baseHp': 3100,
            'baseAttack': 600,
            'baseSpeed': 140,
            'skillIds': ['skill_gangmeng_jichu_basic'],
            'iconPath': 'assets/x.png',
          },
        ],
        'dropTable': [
          {'equipmentDefId': 'weapon_xunchang_tie_jian', 'dropChance': 1.0},
        ],
      };
      final def = TowerFloorDef.fromYaml(y);
      expect(def.bossKind, TowerBossKind.minor);
      expect(def.isBoss, isTrue);
      expect(def.narrativeOpeningId, 'tower_05_opening');
      expect(def.dropTable.length, 1);
    });

    test('解析大 Boss 层（bossKind major）', () {
      final y = {
        'floorIndex': 10,
        'requiredRealm': 'sanLiu',
        'bossKind': 'major',
        'narrativeOpeningId': 'tower_10_opening',
        'narrativeVictoryId': 'tower_10_victory',
        'enemyTeam': [
          {
            'id': 'boss_10',
            'name': '黑风寨主',
            'realmTier': 'sanLiu',
            'realmLayer': 'dengFeng',
            'school': 'lingQiao',
            'baseHp': 5500,
            'baseAttack': 900,
            'baseSpeed': 175,
            'skillIds': ['skill_lingqiao_jichu_basic'],
            'iconPath': 'assets/x.png',
          },
        ],
      };
      final def = TowerFloorDef.fromYaml(y);
      expect(def.bossKind, TowerBossKind.major);
      expect(def.isBoss, isTrue);
    });
  });

  group('30 层 fixture 集成（GameRepository 启动校验）', () {
    test('towerFloors.length == 30 + 升序 + floorIndex 1-30 连续唯一', () async {
      final repo = await GameRepository.loadAllDefs(loader: fileLoader);
      expect(repo.towerFloors.length, 30);
      for (var i = 0; i < repo.towerFloors.length; i++) {
        expect(repo.towerFloors[i].floorIndex, i + 1,
            reason: 'floorIndex 必须连续 1-30');
      }
    });

    test('Boss 分布严格：minor=5/15/25、major=10/20/30，其他层 bossKind=null',
        () async {
      final repo = await GameRepository.loadAllDefs(loader: fileLoader);
      const minor = {5, 15, 25};
      const major = {10, 20, 30};
      for (final f in repo.towerFloors) {
        final expected = minor.contains(f.floorIndex)
            ? TowerBossKind.minor
            : major.contains(f.floorIndex)
                ? TowerBossKind.major
                : null;
        expect(f.bossKind, expected,
            reason: 'floor=${f.floorIndex} bossKind 不符');
      }
    });

    test('普通层 narrative 必须 null；Boss 层 narrative 非 null', () async {
      final repo = await GameRepository.loadAllDefs(loader: fileLoader);
      for (final f in repo.towerFloors) {
        if (f.bossKind == null) {
          expect(f.narrativeOpeningId, isNull,
              reason: '普通 floor=${f.floorIndex} 不应配 opening');
          expect(f.narrativeVictoryId, isNull,
              reason: '普通 floor=${f.floorIndex} 不应配 victory');
        } else {
          expect(f.narrativeOpeningId, isNotNull,
              reason: 'Boss floor=${f.floorIndex} 应有 opening id');
          expect(f.narrativeVictoryId, isNotNull,
              reason: 'Boss floor=${f.floorIndex} 应有 victory id');
        }
      }
    });

    test('境界曲线：每 5 层升一阶（学徒→三流→二流→一流→绝顶→宗师）', () async {
      final repo = await GameRepository.loadAllDefs(loader: fileLoader);
      const expectedByRange = <RealmTier, List<int>>{
        RealmTier.xueTu: [1, 5],
        RealmTier.sanLiu: [6, 10],
        RealmTier.erLiu: [11, 15],
        RealmTier.yiLiu: [16, 20],
        RealmTier.jueDing: [21, 25],
        RealmTier.zongShi: [26, 30],
      };
      for (final entry in expectedByRange.entries) {
        for (var i = entry.value[0]; i <= entry.value[1]; i++) {
          expect(repo.getTowerFloor(i).requiredRealm, entry.key,
              reason: 'floor=$i 期望境界 ${entry.key.name}');
        }
      }
    });

    test('Boss 层固定 1 个敌人；普通层每队 1-3 人', () async {
      final repo = await GameRepository.loadAllDefs(loader: fileLoader);
      for (final f in repo.towerFloors) {
        if (f.bossKind != null) {
          expect(f.enemyTeam.length, 1,
              reason: 'Boss floor=${f.floorIndex} 必须 1 个敌人');
        } else {
          expect(f.enemyTeam.length, inInclusiveRange(1, 3),
              reason: '普通 floor=${f.floorIndex} 敌人数 ∉ [1, 3]');
        }
      }
    });

    test('getTowerFloor 越界 → RangeError', () async {
      final repo = await GameRepository.loadAllDefs(loader: fileLoader);
      expect(() => repo.getTowerFloor(0), throwsRangeError);
      expect(() => repo.getTowerFloor(31), throwsRangeError);
      expect(() => repo.getTowerFloor(-1), throwsRangeError);
      // 边界命中
      expect(repo.getTowerFloor(1).floorIndex, 1);
      expect(repo.getTowerFloor(30).floorIndex, 30);
    });
  });

  group('红线 fail-fast', () {
    Future<String> Function(String) makeLoader(String towersOverride) {
      return (String path) async {
        if (path.endsWith('towers.yaml')) {
          return towersOverride;
        }
        return fileLoader(path);
      };
    }

    test('普通层带 narrativeOpeningId → StateError', () async {
      final overrides = _buildBrokenTowersYaml((floors) {
        // floor=1 是普通层，强行塞 narrativeOpeningId
        floors[0] =
            floors[0].replaceFirst('requiredRealm: xueTu', '''requiredRealm: xueTu
    narrativeOpeningId: not_allowed_for_normal_floor''');
      });
      expect(
        GameRepository.loadAllDefs(loader: makeLoader(overrides)),
        throwsA(isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('普通层不应配 narrative'),
        )),
      );
    });

    test('Boss 分布错位（floor=6 写成 minor）→ StateError', () async {
      final overrides = _buildBrokenTowersYaml((floors) {
        // floor=6 是普通层，强行塞 bossKind: minor
        floors[5] =
            floors[5].replaceFirst('requiredRealm: sanLiu', '''requiredRealm: sanLiu
    bossKind: minor''');
      });
      expect(
        GameRepository.loadAllDefs(loader: makeLoader(overrides)),
        throwsA(isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('bossKind'),
        )),
      );
    });

    test('floorIndex 不连续（缺 floor=15）→ StateError', () async {
      final overrides = _buildBrokenTowersYaml((floors) {
        // 删除 floor=15 整层
        floors.removeAt(14);
      });
      expect(
        GameRepository.loadAllDefs(loader: makeLoader(overrides)),
        throwsA(isA<StateError>().having(
          (e) => e.message,
          'message',
          anyOf(contains('层数'), contains('不连续')),
        )),
      );
    });

    test('Boss HP > 50000（§5.4 红线）→ StateError', () async {
      final overrides = _buildBrokenTowersYaml((floors) {
        // floor=30 大 Boss baseHp 拉到越界值
        floors[29] = floors[29].replaceFirst(
            'baseHp: 15000', 'baseHp: 99999');
      });
      expect(
        GameRepository.loadAllDefs(loader: makeLoader(overrides)),
        throwsA(isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('50000'),
        )),
      );
    });
  });
}

/// 读真 towers.yaml，按 `- floorIndex:` 切成 30 块，让 mutator 改若干块，
/// 然后拼回 yaml 字符串。用于构造 fail-fast 测试的 broken fixture。
String _buildBrokenTowersYaml(void Function(List<String> floorBlocks) mutator) {
  final raw = File('data/towers.yaml').readAsStringSync();
  // 找 "floors:" header 后面所有 - floorIndex: N 起始的块
  final headerEnd = raw.indexOf('floors:');
  if (headerEnd < 0) {
    throw StateError('towers.yaml 缺 floors: 段，测试 fixture 解析失败');
  }
  final header = raw.substring(0, headerEnd + 'floors:'.length);
  final body = raw.substring(headerEnd + 'floors:'.length);

  // 用 "\n  - floorIndex:" 作为分隔（保留前导换行）
  final parts = body.split(RegExp(r'(?=\n  - floorIndex:)'));
  // parts[0] 可能是注释行/空行，剩下是 30 个 floor 块
  final preamble = parts.first;
  final floors = parts.skip(1).toList();
  if (floors.length != 30) {
    throw StateError('解析 towers.yaml 切到 ${floors.length} 块，期望 30');
  }
  mutator(floors);
  return '$header$preamble${floors.join()}';
}
