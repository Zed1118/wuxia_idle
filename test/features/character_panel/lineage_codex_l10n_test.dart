import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/features/battle/domain/enum_localizations.dart';
import 'package:wuxia_idle/shared/strings.dart';

void main() {
  test('lineageRole 穷尽 5 值且非空', () {
    for (final r in LineageRole.values) {
      expect(EnumL10n.lineageRole(r).isNotEmpty, true);
    }
    expect(EnumL10n.lineageRole(LineageRole.founder), '祖师');
    expect(EnumL10n.lineageRole(LineageRole.senior), '大弟子');
  });

  test('世代卷文案词条存在', () {
    expect(UiStrings.lineageCodexTitle.isNotEmpty, true);
    expect(UiStrings.lineageCodexGenerationLabel(1), contains('代'));
    expect(UiStrings.lineageCodexProgress(2, 3).isNotEmpty, true);
  });
}
