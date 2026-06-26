import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/narrative_loader.dart';

void main() {
  Future<String> loadFromDisk(String path) => File(path).readAsString();

  group('mainline late chapter narrative polish', () {
    test(
      'late chapter victory narratives have titles and real content',
      () async {
        for (final id in [
          'stage_04_05_victory',
          'stage_05_05_victory',
          'stage_06_05_victory',
        ]) {
          final content = await NarrativeLoader.load(id, loader: loadFromDisk);

          expect(content.isPlaceholder, isFalse, reason: id);
          expect(content.title, isNotNull, reason: id);
          expect(content.title!.trim(), isNotEmpty, reason: id);
          expect(content.paragraphs, isNotEmpty, reason: id);
        }
      },
    );

    test(
      'final quote keeps master words separate from narrator conclusion',
      () async {
        final content = await NarrativeLoader.load(
          'stage_06_05_victory',
          loader: loadFromDisk,
        );
        final text = content.paragraphs.join('\n');

        expect(text, contains('「最后那一段路——」'));
        expect(text, contains('下文要自己走'));
        expect(text, isNot(contains('「最后那一段路，也许已说完，下文要自己走」')));
      },
    );
  });
}
