import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/defs/founder_names_def.dart';

void main() {
  test('fromYaml 解析四池非空且为 String', () {
    final cfg = FounderNamesConfig.fromYaml(const {
      'founder_surnames': ['慕容', '令狐'],
      'founder_given': ['无咎', '惊鸿'],
      'sect_prefixes': ['青城', '昆仑'],
      'sect_suffixes': ['派', '门'],
    });
    expect(cfg.founderSurnames, ['慕容', '令狐']);
    expect(cfg.founderGiven.length, 2);
    expect(cfg.sectPrefixes.first, '青城');
    expect(cfg.sectSuffixes, contains('派'));
  });

  test('缺 key 回退空列表', () {
    final cfg = FounderNamesConfig.fromYaml(const {});
    expect(cfg.founderSurnames, isEmpty);
    expect(cfg.sectSuffixes, isEmpty);
  });
}
