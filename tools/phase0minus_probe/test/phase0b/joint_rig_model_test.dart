import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:phase0minus_probe/phase0b/joint/joint_rig_model.dart';

void main() {
  late JointRig rig;

  setUpAll(() {
    rig = JointRig.parse(
      File('assets/phase0b/joint/founder_rig_v1.yaml').readAsStringSync(),
    );
  });

  test('rig has one root, unique parts, and complete 3-second clip', () {
    expect(rig.root, 'pelvis');
    expect(rig.parts, hasLength(16));
    expect(rig.parts.where((part) => part.parent == null), hasLength(1));
    expect(rig.parts.map((part) => part.id).toSet(), hasLength(16));
    expect(
      rig.parts.every(
        (part) =>
            part.source.left >= 0 &&
            part.source.top >= 0 &&
            part.source.right <= 1254 &&
            part.source.bottom <= 1254,
      ),
      isTrue,
    );
    expect(rig.duration, 3);
    expect(rig.keys.first.time, 0);
    expect(rig.keys.last.time, 3);
  });

  test('sampling is deterministic and wraps at the clip boundary', () {
    final first = rig.sample(0);
    final wrapped = rig.sample(3);
    final strike = rig.sample(1.25);

    expect(wrapped.rootOffset, first.rootOffset);
    expect(wrapped.angles, first.angles);
    expect(strike.rootOffset.dx, closeTo(12, 0.001));
    expect(strike.angles['right_sleeve'], closeTo(1.05, 0.001));
  });

  test('invalid parent is rejected', () {
    final source = File(
      'assets/phase0b/joint/founder_rig_v1.yaml',
    ).readAsStringSync();

    expect(
      () => JointRig.parse(source.replaceFirst('parent: pelvis', 'parent: x')),
      throwsFormatException,
    );
  });
}
