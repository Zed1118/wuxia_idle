import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/defs/stage_def.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/mainline/application/mainline_narrative_manifest.dart';

import '../support/test_data.dart';

void main() {
  late GameRepository repository;

  setUpAll(() async {
    repository = await loadTestGameRepository();
  });

  test(
    'production manifest exactly covers 105 opening, 105 victory, 42 defeat IDs',
    () async {
      final manifest = await MainlineNarrativeManifest.load(
        loader: (path) => File(path).readAsString(),
      );
      final mainlineStages = repository.stageDefs.values
          .where((stage) => stage.stageType == StageType.mainline)
          .toList(growable: false);

      expect(mainlineStages, hasLength(105));
      expect(
        mainlineStages.where((stage) => stage.narrativeOpeningId != null),
        hasLength(105),
      );
      expect(
        mainlineStages.where((stage) => stage.narrativeVictoryId != null),
        hasLength(105),
      );
      expect(
        mainlineStages.where((stage) => stage.narrativeDefeatId != null),
        hasLength(42),
      );
      expect(manifest.entries, hasLength(252));
      expect(
        manifest.entries.map((entry) => entry.narrativeId).toSet(),
        hasLength(252),
      );
      expect(
        manifest.entries.every(
          (entry) =>
              entry.disposition == MainlineNarrativeDisposition.migrate &&
              entry.targetType ==
                  MainlineNarrativeTargetType.chapterStageTimeline,
        ),
        isTrue,
      );
      expect(
        () => manifest.validateAgainstStages(repository.stageDefs.values),
        returnsNormally,
      );
    },
  );

  testWidgets('production manifest asset is bundled and loadable', (
    tester,
  ) async {
    final manifest = await MainlineNarrativeManifest.load();
    expect(manifest.entries, hasLength(252));
  });

  group('strict parser', () {
    test('rejects duplicate narrative IDs', () {
      expect(
        () => MainlineNarrativeManifest.parse(
          _yaml([_entry('stage_01_01_opening'), _entry('stage_01_01_opening')]),
        ),
        throwsStateError,
      );
    });

    test('rejects unknown root and entry keys', () {
      expect(
        () => MainlineNarrativeManifest.parse(
          '${_yaml([_entry('stage_01_01_opening')])}unknown: true\n',
        ),
        throwsStateError,
      );
      expect(
        () => MainlineNarrativeManifest.parse(
          _yaml(['${_entry('stage_01_01_opening')}\n    unknown: true']),
        ),
        throwsStateError,
      );
    });

    test('rejects wrong types, blank strings, and unsupported enums', () {
      expect(
        () => MainlineNarrativeManifest.parse(
          'schemaVersion: "1"\nentries: []\n',
        ),
        throwsStateError,
      );
      for (final field in const [
        'narrativeId',
        'targetType',
        'targetId',
        'unlockTrigger',
        'disposition',
      ]) {
        expect(
          () => MainlineNarrativeManifest.parse(
            _yaml([
              _entry(
                'stage_01_01_opening',
                overrides: {field: field == 'narrativeId' ? '"   "' : '42'},
              ),
            ]),
          ),
          throwsStateError,
          reason: field,
        );
      }
      expect(
        () => MainlineNarrativeManifest.parse(
          _yaml([
            _entry('stage_01_01_opening', targetType: 'unsupportedTarget'),
          ]),
        ),
        throwsStateError,
      );
      expect(
        () => MainlineNarrativeManifest.parse(
          _yaml([
            _entry('stage_01_01_opening', unlockTrigger: 'unsupportedTrigger'),
          ]),
        ),
        throwsStateError,
      );
    });

    test('trims string fields before storing them', () {
      final manifest = MainlineNarrativeManifest.parse(
        _yaml([_entry(' stage_01_01_opening ', targetId: ' stage_01_01 ')]),
      );

      expect(manifest.entries.single.narrativeId, 'stage_01_01_opening');
      expect(manifest.entries.single.targetId, 'stage_01_01');
    });

    test(
      'parses future dispositions but production validation rejects non-migrate',
      () {
        final manifest = MainlineNarrativeManifest.parse(
          _yaml([_entry('stage_test_opening', disposition: 'merge')]),
        );
        final stage = _stage(openingId: 'stage_test_opening');

        expect(() => manifest.validateAgainstStages([stage]), throwsStateError);
      },
    );

    test('archive capability requires a content owner reason', () {
      expect(
        () => MainlineNarrativeManifest.parse(
          _yaml([
            _entry(
              'stage_test_opening',
              disposition: 'archive_with_content_owner_reason',
            ),
          ]),
        ),
        throwsStateError,
      );
    });
  });

  test('validation rejects destination or trigger drift from stage data', () {
    final manifest = MainlineNarrativeManifest.parse(
      _yaml([
        _entry(
          'stage_test_opening',
          targetId: 'stage_wrong',
          unlockTrigger: 'stageCleared',
        ),
      ]),
    );

    expect(
      () => manifest.validateAgainstStages([
        _stage(openingId: 'stage_test_opening'),
      ]),
      throwsStateError,
    );
  });
}

String _yaml(List<String> entries) =>
    'schemaVersion: 1\nentries:\n${entries.join('\n')}\n';

String _entry(
  String narrativeId, {
  String targetType = 'chapterStageTimeline',
  String targetId = 'stage_test',
  String unlockTrigger = 'stageAvailable',
  String disposition = 'migrate',
  Map<String, String> overrides = const {},
}) {
  final fields = <String, String>{
    'narrativeId': '"$narrativeId"',
    'targetType': targetType,
    'targetId': '"$targetId"',
    'unlockTrigger': unlockTrigger,
    'disposition': disposition,
    ...overrides,
  };
  return [
    '  - narrativeId: ${fields['narrativeId']}',
    for (final field in const [
      'targetType',
      'targetId',
      'unlockTrigger',
      'disposition',
    ])
      '    $field: ${fields[field]}',
  ].join('\n');
}

StageDef _stage({required String openingId}) => StageDef(
  id: 'stage_test',
  name: 'test',
  stageType: StageType.mainline,
  requiredRealm: RealmTier.xueTu,
  enemyTeam: const [],
  isBossStage: false,
  narrativeOpeningId: openingId,
  baseExpReward: 0,
  difficultyMultiplier: 1,
);
