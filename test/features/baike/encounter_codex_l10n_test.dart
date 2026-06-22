import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/shared/strings.dart';

void main() {
  test('奇遇录文案词条存在', () {
    expect(UiStrings.baikeTabEncounter.isNotEmpty, true);
    expect(UiStrings.encounterCodexProgress(3, 57).isNotEmpty, true);
    expect(UiStrings.encounterCodexGroupInsight.isNotEmpty, true);
    expect(UiStrings.encounterCodexEmpty.isNotEmpty, true);
    expect(UiStrings.encounterCodexLocked.isNotEmpty, true);
  });
}
