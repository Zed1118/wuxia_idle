import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/core/domain/save_data.dart';
import 'package:wuxia_idle/data/isar_setup.dart';

import '../fixtures/legacy_numeric_fields.dart';
import '../support/isar_numeric_field_evidence.dart';
import '../support/isar_test_support.dart';

void main() {
  setUpAll(initializeTestIsarCore);

  for (final field in numericFieldEvidence) {
    test(
      '${field.rootSchema} ${field.key}: absent -> default; legal value and reopen preserved',
      () async {
        final dir = await Directory.systemTemp.createTemp(
          'isar_missing_field_',
        );
        Isar? raw;
        try {
          final root = legacyNumericSchemas.singleWhere(
            (s) => s.name == field.rootSchema,
          );
          Schema schema = root;
          for (final segment in field.path.take(field.path.length - 1)) {
            schema = root.embeddedSchemas[schema.properties[segment]!.target]!;
          }
          expect(schema.properties, isNot(contains(field.path.last)));

          raw = await Isar.open(
            legacyNumericSchemas,
            directory: dir.path,
            name: 'wuxia_save_slot1',
            inspector: false,
          );
          await seedLegacyNumericRows(raw);
          await raw.close();
          raw = await Isar.open(
            IsarSetup.schemasForTesting,
            directory: dir.path,
            name: 'wuxia_save_slot1',
            inspector: false,
          );
          final missing = await field.read(raw);
          expect(missing, isNotEmpty);
          for (final value in missing) {
            expect(
              field.isDouble ? value.isNaN : value == -9223372036854775808,
              isTrue,
              reason: field.key,
            );
          }
          await raw.close();

          await IsarSetup.init(directory: dir, inspector: false);
          expect((await IsarSetup.currentSaveData())!.saveVersion, '0.49.0');
          expect(
            await field.read(IsarSetup.instance),
            everyElement(field.defaultValue()),
          );

          final num legalValue = field.isDouble ? 0.5 : 2;
          await IsarSetup.instance.writeTxn(() async {
            await field.write(IsarSetup.instance, legalValue);
            final save = (await IsarSetup.currentSaveData())!
              ..saveVersion = '0.47.0';
            await IsarSetup.instance.saveDatas.put(save);
          });
          await IsarSetup.close();
          for (var reopen = 0; reopen < 2; reopen++) {
            await IsarSetup.init(directory: dir, inspector: false);
            expect(
              await field.read(IsarSetup.instance),
              everyElement(legalValue),
            );
            await IsarSetup.close();
          }
        } finally {
          if (raw?.isOpen ?? false) await raw!.close();
          if (IsarSetup.instanceOrNull != null) await IsarSetup.close();
          await dir.delete(recursive: true);
        }
      },
    );
  }
}
