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
      final cleanBackdrop = File('$root/mountain_pass_background_v2.png');
      final cutout = File('$root/founder_cutout_parts_v1.png');
      final panorama = File('$root/scroll_panorama_mountain_to_gate_v1.png');

      expect(founder.existsSync(), isTrue);
      expect(bandit.existsSync(), isTrue);
      expect(elite.existsSync(), isTrue);
      expect(backdrop.existsSync(), isTrue);
      expect(cleanBackdrop.existsSync(), isTrue);
      expect(cutout.existsSync(), isTrue);
      expect(panorama.existsSync(), isTrue);
      expect(panorama.lengthSync(), greaterThan(1000000));
      expect(founder.lengthSync(), greaterThan(100000));
      expect(bandit.lengthSync(), greaterThan(100000));
      expect(elite.lengthSync(), greaterThan(100000));
      expect(backdrop.lengthSync(), greaterThan(10000));
      expect(cleanBackdrop.lengthSync(), greaterThan(100000));
      expect(cutout.lengthSync(), greaterThan(100000));
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
