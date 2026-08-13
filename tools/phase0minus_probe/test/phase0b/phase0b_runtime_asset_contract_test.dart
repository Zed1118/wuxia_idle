import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'runtime sample keeps three transparent pose atlases and local backdrop',
    () {
      const root = 'assets/phase0b/runtime';
      final founder = File('$root/founder_pose_atlas_v1.png');
      final bandit = File('$root/bandit_pose_atlas_v1.png');
      final elite = File('$root/elite_pose_atlas_v1.png');
      final backdrop = File('$root/mountain_pass_background_v1.webp');

      expect(founder.existsSync(), isTrue);
      expect(bandit.existsSync(), isTrue);
      expect(elite.existsSync(), isTrue);
      expect(backdrop.existsSync(), isTrue);
      expect(founder.lengthSync(), greaterThan(100000));
      expect(bandit.lengthSync(), greaterThan(100000));
      expect(elite.lengthSync(), greaterThan(100000));
      expect(backdrop.lengthSync(), greaterThan(10000));
      expect(founder.readAsBytesSync().take(8), <int>[
        137,
        80,
        78,
        71,
        13,
        10,
        26,
        10,
      ]);
      expect(bandit.readAsBytesSync().take(8), <int>[
        137,
        80,
        78,
        71,
        13,
        10,
        26,
        10,
      ]);
    },
  );
}
