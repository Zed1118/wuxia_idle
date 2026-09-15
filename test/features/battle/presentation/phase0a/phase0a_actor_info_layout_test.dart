import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/battle/presentation/phase0a/phase0a_actor_info_layout.dart';
import 'package:wuxia_idle/features/battle/presentation/phase0a/phase0a_presentation_tokens.dart';
import 'package:wuxia_idle/shared/widgets/combat_hp_bar.dart';

const _viewports = [Size(1280, 720), Size(1440, 900)];

Phase0aActorInfoAnchor _anchor(
  String id,
  Rect actor, {
  bool priority = false,
}) => Phase0aActorInfoAnchor(
  id: id,
  actorRect: actor,
  bodyRect: phase0aActorBodyEnvelope(actor),
  priority: priority,
);

Finder _info(String id) => find.byKey(ValueKey('info_$id'));

Future<void> _pumpLayout(
  WidgetTester tester, {
  required List<Phase0aActorInfoAnchor> anchors,
  required Rect available,
  required Map<String, Offset> offsets,
  List<Rect>? obstacles,
  double textScale = 1,
  bool expanded = false,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
        child: CustomMultiChildLayout(
          delegate: Phase0aActorInfoLayout(
            anchors: anchors,
            bodyObstacles: obstacles ?? anchors.map((a) => a.bodyRect).toList(),
            availableRect: available,
            retainedOffsets: offsets,
          ),
          children: [
            for (final anchor in anchors)
              LayoutId(
                id: anchor.id,
                child: ColoredBox(
                  key: ValueKey('info_${anchor.id}'),
                  color: Colors.white,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        expanded
                            ? 'Commander ${anchor.id} of the mountain'
                            : anchor.id,
                        style: const TextStyle(fontSize: 14),
                      ),
                      HpBar(
                        key: ValueKey('hp_${anchor.id}'),
                        current: 37,
                        max: 100,
                        height: 14,
                        tightLabel: true,
                      ),
                      if (expanded) ...[
                        Text(
                          'Charging ${anchor.id}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        Text(
                          'Guarded ${anchor.id}',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    ),
  );
  await tester.pump();
}

Map<String, Rect> _expectClear(
  WidgetTester tester,
  List<Phase0aActorInfoAnchor> anchors,
  Rect available, {
  List<Rect>? obstacles,
}) {
  final placed = <String, Rect>{};
  for (final anchor in anchors) {
    expect(_info(anchor.id), findsOneWidget);
    final rect = tester.getRect(_info(anchor.id));
    expect(rect.width, greaterThan(0));
    expect(rect.height, greaterThan(0));
    expect(rect.left, greaterThanOrEqualTo(available.left));
    expect(rect.top, greaterThanOrEqualTo(available.top));
    expect(rect.right, lessThanOrEqualTo(available.right));
    expect(rect.bottom, lessThanOrEqualTo(available.bottom));
    for (final body in obstacles ?? anchors.map((a) => a.bodyRect)) {
      expect(
        rect.overlaps(body),
        isFalse,
        reason: '${anchor.id} covers body $body',
      );
    }
    for (final other in placed.entries) {
      expect(
        rect.overlaps(other.value),
        isFalse,
        reason: '${anchor.id} covers ${other.key}',
      );
    }
    final hp = tester.widget<HpBar>(find.byKey(ValueKey('hp_${anchor.id}')));
    expect(hp.current, 37);
    expect(hp.max, 100);
    placed[anchor.id] = rect;
  }
  expect(tester.takeException(), isNull);
  return placed;
}

void main() {
  for (final viewport in _viewports) {
    testWidgets(
      'four edges and camera-like movement preserve visible information $viewport',
      (tester) async {
        await tester.binding.setSurfaceSize(viewport);
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final available = Rect.fromLTRB(
          16,
          20,
          viewport.width - 16,
          viewport.height - 180,
        );
        final originals = [
          const Rect.fromLTWH(0, 0, 112, 158),
          Rect.fromLTWH(viewport.width - 112, 0, 112, 158),
          Rect.fromLTWH(0, available.bottom - 158, 112, 158),
          Rect.fromLTWH(viewport.width - 112, available.bottom - 158, 112, 158),
        ];
        final offsets = <String, Offset>{};
        for (final move in [
          Offset.zero,
          const Offset(-25, 18),
          const Offset(20, -12),
        ]) {
          final anchors = [
            for (var i = 0; i < originals.length; i++)
              _anchor('edge_$i', originals[i].shift(move)),
          ];
          await _pumpLayout(
            tester,
            anchors: anchors,
            available: available,
            offsets: offsets,
          );
          _expectClear(tester, anchors, available);
        }
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }

  testWidgets(
    'adjacent actors retain names HP and states as text and block heights grow',
    (tester) async {
      await tester.binding.setSurfaceSize(_viewports.first);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      const available = Rect.fromLTRB(16, 20, 1264, 540);
      final anchors = [
        _anchor(
          'boss',
          const Rect.fromLTWH(700, 170, 128, 158),
          priority: true,
        ),
        _anchor('guard_a', const Rect.fromLTWH(700, 60, 128, 158)),
        _anchor('guard_b', const Rect.fromLTWH(700, 300, 128, 158)),
      ];
      final offsets = <String, Offset>{};
      await _pumpLayout(
        tester,
        anchors: anchors,
        available: available,
        offsets: offsets,
      );
      final original = _expectClear(tester, anchors, available);
      await _pumpLayout(
        tester,
        anchors: anchors,
        available: available,
        offsets: offsets,
        textScale: 1.6,
        expanded: true,
      );
      final expanded = _expectClear(tester, anchors, available);
      for (final anchor in anchors) {
        expect(
          expanded[anchor.id]!.height,
          greaterThan(original[anchor.id]!.height),
        );
        for (final text in [
          'Commander ${anchor.id} of the mountain',
          'Charging ${anchor.id}',
          'Guarded ${anchor.id}',
        ]) {
          final finder = find.descendant(
            of: _info(anchor.id),
            matching: find.text(text),
          );
          expect(finder, findsOneWidget);
          final textRect = tester.getRect(finder);
          expect(expanded[anchor.id]!.contains(textRect.center), isTrue);
        }
      }
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'input reordering is deterministic and valid retained offsets do not bounce back',
    (tester) async {
      await tester.binding.setSurfaceSize(_viewports.first);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      const available = Rect.fromLTRB(16, 20, 1264, 540);
      final anchors = [
        _anchor('z_guard', const Rect.fromLTWH(930, 110, 112, 158)),
        _anchor(
          'a_boss',
          const Rect.fromLTWH(930, 220, 112, 158),
          priority: true,
        ),
      ];
      final offsets = <String, Offset>{};
      await _pumpLayout(
        tester,
        anchors: anchors,
        available: available,
        offsets: offsets,
      );
      final first = _expectClear(tester, anchors, available);
      expect(
        first[anchors.last.id]!.center.dy,
        closeTo(anchors.last.bodyRect.center.dy, 0.001),
        reason:
            'a side lane must align with its owner, not the preceding actor',
      );
      await _pumpLayout(
        tester,
        anchors: anchors.reversed.toList(),
        obstacles: anchors.reversed.map((a) => a.bodyRect).toList(),
        available: available,
        offsets: <String, Offset>{},
      );
      expect(_expectClear(tester, anchors, available), first);

      // Remove the earlier collision, keeping the already valid visual lane.
      final boss = anchors.last;
      expect(first[boss.id]!.topLeft, isNot(boss.actorRect.topLeft));
      for (var rebuild = 0; rebuild < 3; rebuild++) {
        await _pumpLayout(
          tester,
          anchors: [boss],
          obstacles: const [],
          available: available,
          offsets: offsets,
        );
        expect(tester.getRect(_info(boss.id)), first[boss.id]);
        expect(offsets.keys, [
          boss.id,
        ], reason: 'removed owners must leave no stale offsets');
      }
      final shifted = _anchor(
        boss.id,
        boss.actorRect.shift(const Offset(-12, 9)),
        priority: true,
      );
      await _pumpLayout(
        tester,
        anchors: [shifted],
        obstacles: const [],
        available: available,
        offsets: offsets,
      );
      expect(
        tester.getRect(_info(boss.id)),
        first[boss.id]!.shift(const Offset(-12, 9)),
      );
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'no free region retains critical content and explicitly remains an overlap',
    (tester) async {
      const available = Rect.fromLTWH(20, 20, 112, 90);
      final anchors = [
        _anchor(
          'trapped',
          const Rect.fromLTWH(20, 20, 112, 158),
          priority: true,
        ),
      ];
      await _pumpLayout(
        tester,
        anchors: anchors,
        obstacles: [available],
        available: available,
        offsets: <String, Offset>{},
      );
      expect(find.text('trapped'), findsOneWidget);
      expect(find.byKey(const ValueKey('hp_trapped')), findsOneWidget);
      final rect = tester.getRect(_info('trapped'));
      expect(
        rect.overlaps(available),
        isTrue,
        reason: 'information retention is not evidence of successful avoidance',
      );
      expect(rect.left, available.left);
      expect(rect.top, available.top);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'body envelope contains actual implicit transforms through interrupted retargets',
    (tester) async {
      await tester.binding.setSurfaceSize(_viewports.first);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      const bodyKey = ValueKey('transformed_body');
      for (final width in [90.0, 112.0, 124.0]) {
        final actor = Rect.fromLTWH(400, 210, width, 158);
        final envelope = phase0aActorBodyEnvelope(actor);
        Future<void> pose({
          required Offset slide,
          required double scale,
          required double turns,
        }) => tester.pumpWidget(
          MaterialApp(
            home: Stack(
              children: [
                Positioned.fromRect(
                  rect: actor,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned(
                        bottom: Phase0aPresentationTokens.actorImageBottomInset,
                        height: Phase0aPresentationTokens.actorImageHeight,
                        left: 0,
                        right: 0,
                        child: AnimatedSlide(
                          offset: slide,
                          duration: const Duration(milliseconds: 80),
                          curve: Curves.easeOutCubic,
                          child: AnimatedScale(
                            scale: scale,
                            duration: const Duration(milliseconds: 80),
                            curve: Curves.easeOutBack,
                            child: AnimatedRotation(
                              turns: turns,
                              duration: const Duration(milliseconds: 80),
                              curve: Curves.easeOutBack,
                              alignment: Alignment.bottomCenter,
                              child: const ColoredBox(
                                key: bodyKey,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
        void check() {
          final box = tester.renderObject<RenderBox>(find.byKey(bodyKey));
          final actual = MatrixUtils.transformRect(
            box.getTransformTo(null),
            Offset.zero & box.size,
          );
          expect(actual.left, greaterThanOrEqualTo(envelope.left));
          expect(actual.top, greaterThanOrEqualTo(envelope.top));
          expect(actual.right, lessThanOrEqualTo(envelope.right));
          expect(actual.bottom, lessThanOrEqualTo(envelope.bottom));
        }

        await pose(slide: Offset.zero, scale: 1, turns: 0);
        check();
        // Reverse both targets before the old transition completes. This exercises
        // Flutter's current tween value, not a duplicate envelope calculation.
        for (var retarget = 0; retarget < 16; retarget++) {
          final action = retarget.isEven;
          final fraction = action
              ? Phase0aPresentationTokens.actorActionSlideFraction
              : -Phase0aPresentationTokens.actorHitSlideFraction;
          await pose(
            slide: Offset(fraction, -fraction),
            scale: action
                ? Phase0aPresentationTokens.actorActionScale
                : Phase0aPresentationTokens.actorHitScale,
            turns: action
                ? Phase0aPresentationTokens.postureUnbalancedTurns
                : 0,
          );
          for (var frame = 0; frame < 4; frame++) {
            await tester.pump(const Duration(milliseconds: 16));
            check();
          }
        }
        await tester.pump(const Duration(milliseconds: 80));
        check();
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      }
    },
  );
}
