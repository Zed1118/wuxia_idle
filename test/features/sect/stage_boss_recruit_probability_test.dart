import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/attributes.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/domain/save_data.dart';
import 'package:wuxia_idle/data/defs/stage_def.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/data/narrative_loader.dart';
import 'package:wuxia_idle/data/yaml_loader.dart';
import 'package:wuxia_idle/features/encounter/application/encounter_service.dart';
import 'package:wuxia_idle/features/mainline/application/mainline_settlement.dart';
import 'package:wuxia_idle/features/mainline/domain/mainline_pending_jianghu_affair.dart';
import 'package:wuxia_idle/features/mainline/domain/mainline_settlement_journal.dart';
import 'package:wuxia_idle/features/sect/domain/stage_boss_recruit_probability.dart';
import 'package:wuxia_idle/features/sect/presentation/stage_boss_recruit_hook.dart';
import 'package:wuxia_idle/shared/utils/rng.dart';

import '../../support/isar_test_support.dart';

void main() {
  late Directory tempDir;

  setUpAll(initializeTestIsarCore);

  setUp(() async {
    await _loadRepository();
    tempDir = await Directory.systemTemp.createTemp(
      'stage_boss_recruit_probability_',
    );
    await IsarSetup.init(directory: tempDir, inspector: false);
    final isar = IsarSetup.instance;
    await isar.writeTxn(() async {
      final founder = Character.create(
        name: '招降概率测试掌门',
        realmTier: RealmTier.xueTu,
        realmLayer: RealmLayer.qiMeng,
        attributes: Attributes()..fortune = 5,
        rarity: RarityTier.biaoZhun,
        lineageRole: LineageRole.founder,
        isFounder: true,
        createdAt: DateTime.utc(2026, 9, 17),
      );
      final founderId = await isar.characters.put(founder);
      final save = (await isar.saveDatas.get(0))!;
      save.founderCharacterId = founderId;
      save.activeCharacterIds = [founderId];
      await isar.saveDatas.put(save);
    });
  });

  tearDown(() async {
    await IsarSetup.close();
    IsarSetup.resetForTest();
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
    GameRepository.resetForTest();
  });

  test('六个生产招降关缺省概率保持空值，由共享解析路径读取 numbers', () {
    final repo = GameRepository.instance;
    final stages = repo.stageDefs.values.where((s) => s.bossRecruit != null);
    expect(stages, hasLength(6));
    for (final stage in stages) {
      expect(stage.bossRecruit!.baseProbability, isNull, reason: stage.id);
      expect(
        resolveStageBossRecruitProbability(
          config: stage.bossRecruit!,
          numbers: repo.numbers,
        ),
        repo.numbers.sectManagement.recruit.stageBossRecruitProb,
        reason: stage.id,
      );
    }
  });

  test('显式 null 与缺 key 均保留空值，并随内存 numbers 的变化解析', () async {
    final repo = await _loadRepository(probability: 0.73);
    for (final raw in <Map<String, dynamic>>[
      {'candidateRef': 'bamboo_swordsman'},
      {'candidateRef': 'bamboo_swordsman', 'baseProbability': null},
    ]) {
      final config = BossRecruitConfig.fromYaml(raw);
      expect(config.baseProbability, isNull);
      expect(
        resolveStageBossRecruitProbability(
          config: config,
          numbers: repo.numbers,
        ),
        repo.numbers.sectManagement.recruit.stageBossRecruitProb,
      );
    }
  });

  test('显式关卡概率含零值均优先于 numbers，不被默认来源覆盖', () async {
    final repo = await _loadRepository(probability: 0.73);
    for (final probability in [0.0, 0.19, 1.0]) {
      final config = BossRecruitConfig.fromYaml({
        'candidateRef': 'bamboo_swordsman',
        'baseProbability': probability,
      });
      expect(config.baseProbability, probability);
      expect(
        resolveStageBossRecruitProbability(
          config: config,
          numbers: repo.numbers,
        ),
        probability,
      );
    }
  });

  for (final (label, recruits)
      in <(String, Future<bool> Function(StageDef, double))>[
        ('主线事务结算', _mainlineRecruits),
        ('战胜招降 hook', _victoryHookRecruits),
      ]) {
    group(label, () {
      test('生产 YAML 仍保持已批准的四成招降边界', () async {
        final stage = GameRepository.instance.stageDefs['stage_01_05']!;
        expect(await recruits(stage, 0.399999), isTrue);
        expect(await recruits(stage, 0.40), isFalse);
      });

      test('缺省概率随 numbers 改变，命中和不命中的边界均取新来源', () async {
        final repo = await _loadRepository(probability: 0.73);
        final stage = repo.stageDefs['stage_01_05']!;
        expect(await recruits(stage, 0.729999), isTrue);
        expect(await recruits(stage, 0.73), isFalse);
      });

      test('显式 null 概率也由 numbers 控制真实消费路径', () async {
        await _loadRepository(probability: 0.73);
        final stage = _stageWithProbability(null);
        expect(await recruits(stage, 0.729999), isTrue);
        expect(await recruits(stage, 0.73), isFalse);
      });

      test('显式 override 保持关卡概率，不能被 numbers 覆盖', () async {
        await _loadRepository(probability: 0.73);
        final stage = _stageWithProbability(0.20);
        expect(await recruits(stage, 0.199999), isTrue);
        expect(await recruits(stage, 0.20), isFalse);
      });
    });
  }
}

/// 只替换加载器返回的内存文本，磁盘上的数值表与关卡表保持原样。
Future<GameRepository> _loadRepository({double? probability}) async {
  String? numbersOverride;
  if (probability != null) {
    final raw = parseYamlMap(await File('data/numbers.yaml').readAsString());
    final recruit =
        (raw['sect_management'] as Map<String, dynamic>)['recruit']
            as Map<String, dynamic>;
    recruit['stage_boss_recruit_prob'] = probability;
    numbersOverride = jsonEncode(raw);
  }
  return GameRepository.loadAllDefs(
    loader: (path) async {
      if (path == 'data/numbers.yaml' && numbersOverride != null) {
        return numbersOverride;
      }
      return File(path).readAsString();
    },
  );
}

StageDef _stageWithProbability(double? probability) {
  final raw = parseYamlMap(File('data/stages.yaml').readAsStringSync());
  final stage = Map<String, dynamic>.from(
    (raw['stages'] as List).singleWhere(
          (entry) => (entry as Map)['id'] == 'stage_01_05',
        )
        as Map,
  );
  stage['bossRecruit'] = {
    'candidateRef': 'bamboo_swordsman',
    'baseProbability': probability,
  };
  return StageDef.fromYaml(stage);
}

Future<bool> _mainlineRecruits(StageDef stage, double roll) async {
  final isar = IsarSetup.instance;
  final save = (await isar.saveDatas.get(0))!;
  final numbers = GameRepository.instance.numbers;
  final refs = await isar.writeTxn(
    () => planMainlinePendingJianghuAffairsInTxn(
      isar: isar,
      identity: MainlineSettlementIdentity(
        runId: 'recruit-probability-run',
        stageId: stage.id,
        loadoutVersion: 1,
        participantId: save.founderCharacterId!,
      ),
      stage: stage,
      saveDataId: IsarSetup.currentSlotId,
      encounterService: EncounterService(
        isar: isar,
        attributeGainCap: numbers.adventureAttributeLifetimeCap,
        attributeEffects: numbers.attributeEffects,
      ),
      encounters: const [],
      rng: _FixedRng(roll),
    ),
  );
  if (refs.isEmpty) return false;
  expect(refs, hasLength(1));
  expect(refs.single.kind, MainlinePendingJianghuAffairKind.stageBossRecruit);
  expect(refs.single.stageId, stage.id);
  expect(refs.single.candidateRef, stage.bossRecruit!.candidateRef);
  return true;
}

Future<bool> _victoryHookRecruits(StageDef stage, double roll) async {
  var flowCalls = 0;
  await runStageBossRecruitHookAfterVictory(
    context: _MountedBuildContext(),
    stage: stage,
    rng: _FixedRng(roll),
    loadNarrative: (id) async => NarrativeContent.placeholder(id),
    recruitFlow:
        ({
          required context,
          required ref,
          required isar,
          required candidate,
          required onMarkTriggered,
          required onFallback,
          required successSnackBar,
          required capFullSnackBar,
          required noSectSnackBar,
        }) async {
          flowCalls += 1;
          expect(candidate.id, stage.bossRecruit!.candidateRef);
        },
  );
  expect(flowCalls, lessThanOrEqualTo(1));
  return flowCalls == 1;
}

class _FixedRng implements Rng {
  const _FixedRng(this.value);

  final double value;

  @override
  double nextDouble() => value;

  @override
  int nextInt(int max) => 0;

  @override
  T pick<T>(List<T> list) => list.first;
}

class _MountedBuildContext implements BuildContext {
  @override
  bool get mounted => true;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
