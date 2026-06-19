import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/narrative_loader.dart';
import 'package:wuxia_idle/shared/strings.dart';

void main() {
  test('拜师 narrative 可加载', () async {
    final first = await NarrativeLoader.load('lineage_first_disciple_join');
    expect(first.paragraphs, isNotEmpty);
    final second = await NarrativeLoader.load('lineage_second_disciple_join');
    expect(second.paragraphs, isNotEmpty);
  });

  test('UiStrings 拜入题字存在', () {
    expect(UiStrings.discipleJoinCaption('大弟子'), contains('大弟子'));
  });
}
