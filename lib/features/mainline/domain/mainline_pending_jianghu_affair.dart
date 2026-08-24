import 'dart:convert';

enum MainlinePendingJianghuAffairKind { encounterChoice, stageBossRecruit }

/// A typed, versioned reference stored in the settlement outbox.
///
/// The encoded value is deliberately opaque to callers: consumers must parse
/// this contract rather than infer meaning from string prefixes or separators.
final class MainlinePendingJianghuAffairRef {
  MainlinePendingJianghuAffairRef._({
    required this.kind,
    required this.settlementId,
    required this.sourceId,
    required this.encounterId,
    required this.stageId,
    required this.candidateRef,
    required this.ordinal,
    required this.resolutionSeed,
  });

  static const int currentVersion = 1;
  static const String _prefix = 'jianghu-affair:v$currentVersion:';

  final MainlinePendingJianghuAffairKind kind;
  final String settlementId;
  final String sourceId;
  final String? encounterId;
  final String? stageId;
  final String? candidateRef;
  final int ordinal;
  final int resolutionSeed;

  factory MainlinePendingJianghuAffairRef.encounterChoice({
    required String settlementId,
    required String encounterId,
    required int ordinal,
    required int resolutionSeed,
  }) {
    _validateOrdinal(ordinal);
    _validateSeed(resolutionSeed);
    final canonicalEncounterId = _text(encounterId, 'encounterId');
    return MainlinePendingJianghuAffairRef._(
      kind: MainlinePendingJianghuAffairKind.encounterChoice,
      settlementId: _text(settlementId, 'settlementId'),
      sourceId: 'encounter:$canonicalEncounterId',
      encounterId: canonicalEncounterId,
      stageId: null,
      candidateRef: null,
      ordinal: ordinal,
      resolutionSeed: resolutionSeed,
    );
  }

  factory MainlinePendingJianghuAffairRef.stageBossRecruit({
    required String settlementId,
    required String stageId,
    required String candidateRef,
    required int ordinal,
    required int resolutionSeed,
  }) {
    _validateOrdinal(ordinal);
    _validateSeed(resolutionSeed);
    final canonicalStageId = _text(stageId, 'stageId');
    final canonicalCandidateRef = _text(candidateRef, 'candidateRef');
    return MainlinePendingJianghuAffairRef._(
      kind: MainlinePendingJianghuAffairKind.stageBossRecruit,
      settlementId: _text(settlementId, 'settlementId'),
      sourceId: 'stage-boss-recruit:$canonicalStageId:$canonicalCandidateRef',
      encounterId: null,
      stageId: canonicalStageId,
      candidateRef: canonicalCandidateRef,
      ordinal: ordinal,
      resolutionSeed: resolutionSeed,
    );
  }

  String get effectId {
    final payload = <String, Object?>{
      'v': currentVersion,
      'kind': kind.name,
      'settlementId': settlementId,
      'sourceId': sourceId,
      if (encounterId != null) 'encounterId': encounterId,
      if (stageId != null) 'stageId': stageId,
      if (candidateRef != null) 'candidateRef': candidateRef,
      'ordinal': ordinal,
      'resolutionSeed': resolutionSeed,
    };
    final json = jsonEncode(payload);
    final encoded = base64Url.encode(utf8.encode(json)).replaceAll('=', '');
    return '$_prefix$encoded';
  }

  static MainlinePendingJianghuAffairRef parse(String value) {
    if (!value.startsWith(_prefix)) {
      throw FormatException('Invalid affair ref', value);
    }
    final encoded = value.substring(_prefix.length);
    if (encoded.isEmpty || encoded.contains('=')) {
      throw FormatException('Invalid affair encoding', value);
    }
    late Map<String, dynamic> payload;
    try {
      final padded = encoded.padRight((encoded.length + 3) ~/ 4 * 4, '=');
      final decoded = utf8.decode(base64Url.decode(padded));
      final object = jsonDecode(decoded);
      if (object is! Map) {
        throw const FormatException('Payload is not an object');
      }
      payload = Map<String, dynamic>.from(object);
    } catch (_) {
      throw FormatException('Invalid affair payload', value);
    }
    final kind = payload['kind'];
    final keys = payload.keys.toSet();
    if (payload['v'] != currentVersion ||
        (kind != 'encounterChoice' && kind != 'stageBossRecruit')) {
      throw FormatException('Unknown affair version or kind', value);
    }
    final expected = kind == 'encounterChoice'
        ? {
            'v',
            'kind',
            'settlementId',
            'sourceId',
            'encounterId',
            'ordinal',
            'resolutionSeed',
          }
        : {
            'v',
            'kind',
            'settlementId',
            'sourceId',
            'stageId',
            'candidateRef',
            'ordinal',
            'resolutionSeed',
          };
    if (keys.length != expected.length || !keys.containsAll(expected)) {
      throw FormatException('Unexpected affair payload keys', value);
    }
    final ordinal = payload['ordinal'];
    final seed = payload['resolutionSeed'];
    if (ordinal is! int || seed is! int) {
      throw FormatException('Invalid affair numbers', value);
    }
    final ref = kind == 'encounterChoice'
        ? MainlinePendingJianghuAffairRef.encounterChoice(
            settlementId: _payloadText(payload, 'settlementId'),
            encounterId: _payloadText(payload, 'encounterId'),
            ordinal: ordinal,
            resolutionSeed: seed,
          )
        : MainlinePendingJianghuAffairRef.stageBossRecruit(
            settlementId: _payloadText(payload, 'settlementId'),
            stageId: _payloadText(payload, 'stageId'),
            candidateRef: _payloadText(payload, 'candidateRef'),
            ordinal: ordinal,
            resolutionSeed: seed,
          );
    if (ref.effectId != value) {
      throw FormatException('Non-canonical affair ref', value);
    }
    return ref;
  }

  @override
  bool operator ==(Object other) =>
      other is MainlinePendingJianghuAffairRef && other.effectId == effectId;
  @override
  int get hashCode => effectId.hashCode;

  static String _text(String value, String name) {
    final normalized = value.trim();
    if (normalized.isEmpty || normalized != value) {
      throw ArgumentError.value(value, name, 'must be non-empty and trimmed');
    }
    return value;
  }

  static String _payloadText(Map<String, dynamic> payload, String key) {
    final value = payload[key];
    if (value is! String) throw FormatException('Invalid $key');
    try {
      return _text(value, key);
    } on ArgumentError {
      throw FormatException('Invalid $key');
    }
  }

  static void _validateOrdinal(int value) {
    if (value < 1) {
      throw ArgumentError.value(value, 'ordinal', 'must be >= 1');
    }
  }

  static void _validateSeed(int value) {
    if (value < 1) {
      throw ArgumentError.value(value, 'resolutionSeed', 'must be > 0');
    }
  }
}
