import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/arena_vector.dart';
import 'package:wuxia_idle/features/battle/presentation/phase0a/phase0a_actor_render_motion.dart';
import 'package:wuxia_idle/features/battle/presentation/phase0a/phase0a_presentation_tokens.dart';

void main() {
  test('进步斩在 0.18 秒内插值且 camera center 单帧增量不超过普通移动一拍', () {
    final motion = Phase0aActorRenderMotion(ArenaVector.zero);
    const fixedDeltaSeconds = 0.1;
    const moveSpeed = 210.0;
    const advancingDistance = 120.0;
    const advancingSeconds =
        Phase0aPresentationTokens.basicAttackAdvanceRenderSeconds;
    const frameSeconds = 0.02;
    const ordinaryTickDistance = moveSpeed * fixedDeltaSeconds;

    motion.retarget(
      const ArenaVector(advancingDistance, 0),
      durationSeconds: advancingSeconds,
      preserveUntilComplete: true,
    );

    var previous = motion.current;
    for (var frame = 0; frame < 5; frame++) {
      motion.advance(frameSeconds);
      final cameraCenterDelta = (motion.current - previous).length;
      expect(cameraCenterDelta, lessThanOrEqualTo(ordinaryTickDistance));
      previous = motion.current;
    }
    expect(
      motion.current.x,
      lessThan(advancingDistance),
      reason: '0.1 秒时仍应处于进步斩过程，不能沿用单拍到位的表现',
    );

    motion.retarget(
      const ArenaVector(advancingDistance + ordinaryTickDistance, 0),
      durationSeconds: fixedDeltaSeconds,
    );
    for (var frame = 0; frame < 4; frame++) {
      motion.advance(frameSeconds);
      final cameraCenterDelta = (motion.current - previous).length;
      expect(cameraCenterDelta, lessThanOrEqualTo(ordinaryTickDistance));
      previous = motion.current;
    }
    expect(motion.current, const ArenaVector(advancingDistance, 0));

    for (var frame = 0; frame < 5; frame++) {
      motion.advance(frameSeconds);
    }
    expect(
      motion.current,
      const ArenaVector(advancingDistance + ordinaryTickDistance, 0),
      reason: '进步斩完成后应消费排队的 held movement 目标',
    );
  });
}
