import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/defs/founder_names_def.dart';
import 'package:wuxia_idle/features/onboarding/domain/founder_creation_selection.dart';
import 'package:wuxia_idle/shared/utils/rng.dart';

const _cfg = FounderNamesConfig(
  founderSurnames: ['慕容', '令狐'],
  founderGiven: ['无咎', '惊鸿'],
  sectPrefixes: ['青城', '昆仑'],
  sectSuffixes: ['派', '门'],
);

void main() {
  test('generateFounderName 组合姓+名、非空、在长度上限内', () {
    final name = generateFounderName(_cfg, DefaultRng(seed: 42));
    expect(name.isNotEmpty, true);
    expect(name.length <= 8, true);
    expect(_cfg.founderSurnames.any((s) => name.startsWith(s)), true);
  });

  test('generateSectName 组合前缀+后缀、非空、在长度上限内', () {
    final name = generateSectName(_cfg, DefaultRng(seed: 42));
    expect(name.isNotEmpty, true);
    expect(name.length <= 12, true);
    expect(_cfg.sectSuffixes.any((s) => name.endsWith(s)), true);
  });

  test('空池回退空串（UI 侧不填）', () {
    expect(
      generateFounderName(FounderNamesConfig.empty, DefaultRng(seed: 1)),
      '',
    );
    expect(
      generateSectName(FounderNamesConfig.empty, DefaultRng(seed: 1)),
      '',
    );
  });
}
