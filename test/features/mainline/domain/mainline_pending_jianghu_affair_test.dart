import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/mainline/domain/mainline_pending_jianghu_affair.dart';

void main() {
  group('MainlinePendingJianghuAffairRef', () {
    test('typed encounter ref 严格 round-trip 且 canonical 稳定', () {
      final ref = MainlinePendingJianghuAffairRef.encounterChoice(
        settlementId: 'v1|run-1|stage_01_03|3|42',
        encounterId: 'bamboo_listen_rain',
        ordinal: 1,
        resolutionSeed: 101,
      );

      expect(ref.kind, MainlinePendingJianghuAffairKind.encounterChoice);
      expect(ref.encounterId, 'bamboo_listen_rain');
      expect(ref.sourceId, 'encounter:bamboo_listen_rain');
      expect(ref.stageId, isNull);
      expect(ref.candidateRef, isNull);
      expect(MainlinePendingJianghuAffairRef.parse(ref.effectId), ref);
      expect(
        MainlinePendingJianghuAffairRef.parse(ref.effectId).effectId,
        ref.effectId,
      );
    });

    test('typed Boss 招降 ref 绑定 stage/candidate/settlement/ordinal', () {
      final ref = MainlinePendingJianghuAffairRef.stageBossRecruit(
        settlementId: 'v1|run-1|stage_01_05|5|42',
        stageId: 'stage_01_05',
        candidateRef: 'candidate_black_wind_leader',
        ordinal: 2,
        resolutionSeed: 202,
      );

      expect(ref.kind, MainlinePendingJianghuAffairKind.stageBossRecruit);
      expect(ref.stageId, 'stage_01_05');
      expect(ref.candidateRef, 'candidate_black_wind_leader');
      expect(
        ref.sourceId,
        'stage-boss-recruit:stage_01_05:candidate_black_wind_leader',
      );
      expect(MainlinePendingJianghuAffairRef.parse(ref.effectId), ref);
    });

    test('空字段、错误 payload、未知版本与非 canonical 编码 fail closed', () {
      expect(
        () => MainlinePendingJianghuAffairRef.encounterChoice(
          settlementId: '',
          encounterId: 'x',
          ordinal: 1,
          resolutionSeed: 1,
        ),
        throwsArgumentError,
      );
      expect(
        () => MainlinePendingJianghuAffairRef.parse('jianghu-affair:v2:e30'),
        throwsFormatException,
      );
      expect(
        () => MainlinePendingJianghuAffairRef.parse('untyped:encounter:x'),
        throwsFormatException,
      );
    });
  });
}
