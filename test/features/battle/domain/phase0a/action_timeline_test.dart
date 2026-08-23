import 'package:flutter_test/flutter_test.dart';

import 'package:wuxia_idle/features/battle/domain/phase0a/action_timeline.dart';

void main() {
  ActionTimelineConfig config({
    int firstEffectTick = 2,
    int cancelStartTick = 0,
    int cancelEndTick = 3,
  }) => ActionTimelineConfig(
    windupTicks: 2,
    activeTicks: 3,
    recoveryTicks: 2,
    firstEffectTick: firstEffectTick,
    cancelWindowStartTick: cancelStartTick,
    cancelWindowEndTick: cancelEndTick,
    interruptedCooldownTicks: 4,
    cancelledCooldownTicks: 3,
    failedCooldownTicks: 5,
  );

  test('fixed tick 状态按 windup→active→recovery→completed 演进', () {
    final timeline = ActionTimeline(config());

    expect(timeline.phase, ActionTimelinePhase.idle);
    expect(timeline.start(), [
      const ActionTimelineEvent(ActionTimelineEventType.started, tick: 0),
    ]);
    expect(timeline.advance(3).map((event) => event.type), [
      ActionTimelineEventType.phaseChanged,
      ActionTimelineEventType.firstEffect,
    ]);
    expect(timeline.phase, ActionTimelinePhase.active);
    expect(timeline.advance(3).map((event) => event.type), [
      ActionTimelineEventType.phaseChanged,
    ]);
    expect(timeline.phase, ActionTimelinePhase.recovery);
    expect(timeline.advance(2).map((event) => event.type), [
      ActionTimelineEventType.completed,
    ]);
    expect(timeline.phase, ActionTimelinePhase.completed);
  });

  test('跨多 tick advance 不丢首效，且一次动作最多一个 firstEffect', () {
    final timeline = ActionTimeline(config(firstEffectTick: 3));
    timeline.start();

    final events = timeline.advance(7);
    expect(
      events.where(
        (event) => event.type == ActionTimelineEventType.firstEffect,
      ),
      hasLength(1),
    );
    expect(events.map((event) => event.tick), orderedEquals([2, 3, 5, 6]));
    expect(timeline.advance(3), isEmpty);
  });

  test('取消仅在配置窗口生效并标记取消冷却', () {
    final timeline = ActionTimeline(
      config(cancelStartTick: 1, cancelEndTick: 1),
    );
    timeline.start();

    expect(timeline.cancel(), isFalse);
    timeline.advance(1);
    expect(timeline.cancel(), isTrue);
    expect(timeline.phase, ActionTimelinePhase.cancelled);
    expect(timeline.cooldownMarker, ActionTimelineCooldownMarker.cancelled);
    expect(timeline.cooldownRemainingTicks, 3);
    expect(
      timeline.drainTerminalEvents().single.type,
      ActionTimelineEventType.cancelled,
    );
  });

  test('被打断与主动失败是终态并分别标记冷却', () {
    final interrupted = ActionTimeline(config());
    interrupted.start();
    interrupted.advance(2);
    expect(interrupted.interrupt(), isTrue);
    expect(interrupted.phase, ActionTimelinePhase.interrupted);
    expect(
      interrupted.cooldownMarker,
      ActionTimelineCooldownMarker.interrupted,
    );
    expect(interrupted.cooldownRemainingTicks, 4);
    expect(
      interrupted.drainTerminalEvents().single.type,
      ActionTimelineEventType.interrupted,
    );

    final failed = ActionTimeline(config());
    failed.start();
    expect(failed.fail(), isTrue);
    expect(failed.phase, ActionTimelinePhase.failed);
    expect(failed.cooldownMarker, ActionTimelineCooldownMarker.failed);
    expect(failed.cooldownRemainingTicks, 5);
    expect(
      failed.drainTerminalEvents().single.type,
      ActionTimelineEventType.failed,
    );
  });

  test('非法 tick、窗口和首效位置直接拒绝', () {
    expect(
      () => ActionTimelineConfig(
        windupTicks: -1,
        activeTicks: 1,
        recoveryTicks: 1,
        firstEffectTick: 0,
        cancelWindowStartTick: 0,
        cancelWindowEndTick: 0,
        interruptedCooldownTicks: 0,
        cancelledCooldownTicks: 0,
        failedCooldownTicks: 0,
      ),
      throwsArgumentError,
    );
    expect(
      () => ActionTimelineConfig(
        windupTicks: 1,
        activeTicks: 1,
        recoveryTicks: 1,
        firstEffectTick: 0,
        cancelWindowStartTick: 2,
        cancelWindowEndTick: 1,
        interruptedCooldownTicks: 0,
        cancelledCooldownTicks: 0,
        failedCooldownTicks: 0,
      ),
      throwsArgumentError,
    );
    final timeline = ActionTimeline(config());
    expect(() => timeline.advance(0), throwsArgumentError);
    expect(() => timeline.advance(-1), throwsArgumentError);
  });
}
