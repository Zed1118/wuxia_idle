/// 主线参与者政策纯合同（P2-M2-R01 / MAINLINE-REPLAY-PARTICIPANT-01，
/// G0 选项 C；decision registry 2026-08-24 frozen）。
///
/// 合同内容：
/// - 仅 `realtime` 时钟的重打（真人或前台 bot）可选择被判定为
///   eligible 且空闲的请求角色；不合格即拒绝，不回退掌门；
/// - `headless` 时钟重打恒固定当前掌门，不受 controller 与
///   `requestedIdleEligible` 影响；
/// - 扫荡恒固定当前掌门；首通不在选择范围，恒固定当前掌门；
/// - `offlineResume` 未被决议覆盖，拒绝；
/// - 记录、成长与伤势归实际参与者（即 [MainlineParticipantSelection]
///   的参与者），本合同只固定归属对象，不实现记账。
///
/// 本合同不解析掌门、不判断空闲/占用、不定义 eligibility 规则，这些由
/// 调用方注入；也不接入任何生产流。
library;

import '../../battle/domain/phase0a/activity_participation_request.dart';

/// 参与者来源：请求的合格空闲角色，或固定当前掌门。
enum MainlineParticipantSource { requestedIdleEligible, currentLeader }

/// 政策选择结果：实际参与者与其来源。
final class MainlineParticipantSelection {
  const MainlineParticipantSelection._(this.participantId, this.source);

  /// 实际出战的角色 ID；记录、成长与伤势均归此人。
  final int participantId;

  final MainlineParticipantSource source;

  /// 成长与伤势归属对象恒等于实际参与者。
  int get actualParticipantId => participantId;

  @override
  bool operator ==(Object other) =>
      other is MainlineParticipantSelection &&
      other.participantId == participantId &&
      other.source == source;

  @override
  int get hashCode => Object.hash(participantId, source);

  @override
  String toString() =>
      'MainlineParticipantSelection(participantId: $participantId, '
      'source: ${source.name})';
}

/// 主线参与合同错误基类。
class MainlineParticipationException implements Exception {
  const MainlineParticipationException(this.message);

  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

/// 合同拒绝：请求不在已签字的选择范围内，或可见路径请求角色不合格。
/// Fail closed，不猜测参与者。
final class MainlineParticipationRefusedError
    extends MainlineParticipationException {
  const MainlineParticipationRefusedError(super.message);
}

/// 主线参与者政策（纯函数，无持久化）。
final class MainlineParticipationPolicy {
  const MainlineParticipationPolicy._();

  /// 按已签字合同解析实际参与者。
  ///
  /// [currentLeaderId] 为当前掌门角色 ID，必须由调用方经
  /// `CurrentLeaderResolver` 等既有口径解析后注入。
  /// [requestedIdleEligible] 为调用方对请求角色「合格且空闲」的判定；
  /// 本合同不发明该判定，只消费它。
  static MainlineParticipantSelection resolveParticipant({
    required ActivityParticipationRequest request,
    required int currentLeaderId,
    required bool requestedIdleEligible,
  }) {
    if (currentLeaderId <= 0) {
      throw ArgumentError.value(
        currentLeaderId,
        'currentLeaderId',
        'must be a positive character ID',
      );
    }
    if (request.contentKind != ActivityContentKind.mainline) {
      throw const MainlineParticipationRefusedError(
        'Mainline participation policy applies only to mainline content',
      );
    }
    if (request.participation != ActivityParticipationMode.direct) {
      throw const MainlineParticipationRefusedError(
        'Mainline participation contract covers direct participation only',
      );
    }
    const leader = MainlineParticipantSource.currentLeader;
    switch (request.entryKind) {
      case ActivityEntryKind.firstClear:
        return MainlineParticipantSelection._(currentLeaderId, leader);
      case ActivityEntryKind.replay:
        final visible = request.clock == ActivityClock.realtime;
        if (!visible) {
          return MainlineParticipantSelection._(currentLeaderId, leader);
        }
        if (!requestedIdleEligible) {
          throw const MainlineParticipationRefusedError(
            'Visible replay requires the requested character to be '
            'eligible and idle; no leader fallback',
          );
        }
        return MainlineParticipantSelection._(
          request.characterId,
          MainlineParticipantSource.requestedIdleEligible,
        );
      case ActivityEntryKind.sweep:
        return MainlineParticipantSelection._(currentLeaderId, leader);
      case ActivityEntryKind.offlineResume:
        throw const MainlineParticipationRefusedError(
          'offlineResume is not covered by MAINLINE-REPLAY-PARTICIPANT-01',
        );
    }
  }
}
