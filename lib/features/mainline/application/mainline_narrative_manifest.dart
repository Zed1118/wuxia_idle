import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/domain/enums.dart';
import '../../../data/defs/stage_def.dart';
import '../../../data/game_repository.dart';
import '../../../data/yaml_loader.dart';

enum MainlineNarrativeTargetType { chapterStageTimeline }

enum MainlineNarrativeUnlockTrigger { stageAvailable, stageCleared }

enum MainlineNarrativeDisposition {
  migrate,
  merge,
  archiveWithContentOwnerReason,
}

class MainlineNarrativeManifestEntry {
  const MainlineNarrativeManifestEntry({
    required this.narrativeId,
    required this.targetType,
    required this.targetId,
    required this.unlockTrigger,
    required this.disposition,
    this.contentOwnerReason,
  });

  final String narrativeId;
  final MainlineNarrativeTargetType targetType;
  final String targetId;
  final MainlineNarrativeUnlockTrigger unlockTrigger;
  final MainlineNarrativeDisposition disposition;
  final String? contentOwnerReason;

  bool get isOptionalReading =>
      disposition == MainlineNarrativeDisposition.migrate;

  factory MainlineNarrativeManifestEntry.fromYaml(Map<String, dynamic> yaml) {
    _rejectUnknownKeys(yaml, const {
      'narrativeId',
      'targetType',
      'targetId',
      'unlockTrigger',
      'disposition',
      'contentOwnerReason',
    }, 'entry');
    final disposition = _parseDisposition(_requiredString(yaml, 'disposition'));
    final rawReason = yaml['contentOwnerReason'];
    if (rawReason != null && rawReason is! String) {
      throw StateError('contentOwnerReason must be a string.');
    }
    final reason = (rawReason as String?)?.trim();
    if (disposition ==
            MainlineNarrativeDisposition.archiveWithContentOwnerReason &&
        (reason == null || reason.trim().isEmpty)) {
      throw StateError(
        'Archived mainline narrative entries require contentOwnerReason.',
      );
    }
    if (disposition !=
            MainlineNarrativeDisposition.archiveWithContentOwnerReason &&
        reason != null) {
      throw StateError(
        'contentOwnerReason is only valid for archived narrative entries.',
      );
    }
    return MainlineNarrativeManifestEntry(
      narrativeId: _requiredString(yaml, 'narrativeId'),
      targetType: _parseTargetType(_requiredString(yaml, 'targetType')),
      targetId: _requiredString(yaml, 'targetId'),
      unlockTrigger: _parseUnlockTrigger(
        _requiredString(yaml, 'unlockTrigger'),
      ),
      disposition: disposition,
      contentOwnerReason: reason,
    );
  }
}

class MainlineNarrativeManifest {
  MainlineNarrativeManifest._(this.schemaVersion, this.entries)
    : _byNarrativeId = Map.unmodifiable({
        for (final entry in entries) entry.narrativeId: entry,
      });

  static const assetPath = 'data/narratives/mainline_narrative_manifest.yaml';

  final int schemaVersion;
  final List<MainlineNarrativeManifestEntry> entries;
  final Map<String, MainlineNarrativeManifestEntry> _byNarrativeId;

  MainlineNarrativeManifestEntry? entryFor(String? narrativeId) =>
      narrativeId == null ? null : _byNarrativeId[narrativeId];

  static Future<MainlineNarrativeManifest> load({
    Future<String> Function(String)? loader,
  }) async {
    final raw = await (loader ?? rootBundle.loadString)(assetPath);
    return parse(raw);
  }

  static MainlineNarrativeManifest parse(String raw) {
    final yaml = parseYamlMap(raw);
    _rejectUnknownKeys(yaml, const {'schemaVersion', 'entries'}, 'root');
    final rawSchemaVersion = yaml['schemaVersion'];
    if (rawSchemaVersion is! int || rawSchemaVersion != 1) {
      throw StateError(
        'Unsupported mainline narrative manifest schemaVersion: '
        '$rawSchemaVersion.',
      );
    }
    final rawEntries = yaml['entries'];
    if (rawEntries is! List) {
      throw StateError('Mainline narrative manifest entries must be a list.');
    }
    final entries = <MainlineNarrativeManifestEntry>[];
    final seenNarrativeIds = <String>{};
    for (final rawEntry in rawEntries) {
      if (rawEntry is! Map) {
        throw StateError('Mainline narrative manifest entry must be a map.');
      }
      final entry = MainlineNarrativeManifestEntry.fromYaml(
        Map<String, dynamic>.from(rawEntry),
      );
      if (!seenNarrativeIds.add(entry.narrativeId)) {
        throw StateError(
          'Duplicate mainline narrative ID: ${entry.narrativeId}.',
        );
      }
      entries.add(entry);
    }
    return MainlineNarrativeManifest._(
      rawSchemaVersion,
      List.unmodifiable(entries),
    );
  }

  void validateAgainstStages(Iterable<StageDef> allStages) {
    final expected =
        <
          String,
          ({String targetId, MainlineNarrativeUnlockTrigger unlockTrigger})
        >{};
    final mainlineStages = allStages.where(
      (stage) => stage.stageType == StageType.mainline,
    );

    void expectNarrative(
      String? narrativeId,
      StageDef stage,
      MainlineNarrativeUnlockTrigger unlockTrigger,
    ) {
      if (narrativeId == null) return;
      if (expected.containsKey(narrativeId)) {
        throw StateError(
          'Mainline narrative ID is reused by stage data: $narrativeId.',
        );
      }
      expected[narrativeId] = (
        targetId: stage.id,
        unlockTrigger: unlockTrigger,
      );
    }

    for (final stage in mainlineStages) {
      expectNarrative(
        stage.narrativeOpeningId,
        stage,
        MainlineNarrativeUnlockTrigger.stageAvailable,
      );
      expectNarrative(
        stage.narrativeVictoryId,
        stage,
        MainlineNarrativeUnlockTrigger.stageCleared,
      );
      expectNarrative(
        stage.narrativeDefeatId,
        stage,
        MainlineNarrativeUnlockTrigger.stageCleared,
      );
    }

    if (_byNarrativeId.length != expected.length ||
        !_byNarrativeId.keys.toSet().containsAll(expected.keys) ||
        !expected.keys.toSet().containsAll(_byNarrativeId.keys)) {
      final missing = expected.keys.toSet().difference(
        _byNarrativeId.keys.toSet(),
      );
      final orphaned = _byNarrativeId.keys.toSet().difference(
        expected.keys.toSet(),
      );
      throw StateError(
        'Mainline narrative manifest does not match stage data. '
        'missing=$missing orphaned=$orphaned.',
      );
    }

    for (final entry in entries) {
      final destination = expected[entry.narrativeId]!;
      if (entry.disposition != MainlineNarrativeDisposition.migrate) {
        throw StateError(
          'Current mainline narrative manifest requires migrate disposition: '
          '${entry.narrativeId}.',
        );
      }
      if (entry.targetType !=
              MainlineNarrativeTargetType.chapterStageTimeline ||
          entry.targetId != destination.targetId ||
          entry.unlockTrigger != destination.unlockTrigger) {
        throw StateError(
          'Invalid destination for mainline narrative ${entry.narrativeId}.',
        );
      }
    }
  }
}

final mainlineNarrativeManifestProvider =
    FutureProvider<MainlineNarrativeManifest>((ref) async {
      final manifest = await MainlineNarrativeManifest.load();
      manifest.validateAgainstStages(GameRepository.instance.stageDefs.values);
      return manifest;
    });

String _requiredString(Map<String, dynamic> yaml, String key) {
  final value = yaml[key];
  if (value is! String || value.trim().isEmpty) {
    throw StateError('Mainline narrative manifest requires $key.');
  }
  return value.trim();
}

void _rejectUnknownKeys(
  Map<String, dynamic> yaml,
  Set<String> allowed,
  String location,
) {
  final unknown = yaml.keys.toSet().difference(allowed);
  if (unknown.isNotEmpty) {
    throw StateError(
      'Unknown mainline narrative manifest keys at $location: $unknown.',
    );
  }
}

MainlineNarrativeDisposition _parseDisposition(String value) => switch (value) {
  'migrate' => MainlineNarrativeDisposition.migrate,
  'merge' => MainlineNarrativeDisposition.merge,
  'archive_with_content_owner_reason' =>
    MainlineNarrativeDisposition.archiveWithContentOwnerReason,
  _ => throw StateError('Unsupported mainline narrative disposition: $value.'),
};

MainlineNarrativeTargetType _parseTargetType(String value) => switch (value) {
  'chapterStageTimeline' => MainlineNarrativeTargetType.chapterStageTimeline,
  _ => throw StateError('Unsupported mainline narrative targetType: $value.'),
};

MainlineNarrativeUnlockTrigger _parseUnlockTrigger(String value) =>
    switch (value) {
      'stageAvailable' => MainlineNarrativeUnlockTrigger.stageAvailable,
      'stageCleared' => MainlineNarrativeUnlockTrigger.stageCleared,
      _ => throw StateError(
        'Unsupported mainline narrative unlockTrigger: $value.',
      ),
    };
