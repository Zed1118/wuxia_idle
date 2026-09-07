import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/data/isar_missing_field_defaults.dart';
import 'package:wuxia_idle/data/isar_setup.dart';

import '../../tool/isar_field_inventory.dart';
import '../support/isar_numeric_field_evidence.dart';

void main() {
  test(
    'every root path into repaired embedded fields has real legacy evidence',
    () {
      final inventory = inventoryIsarFields();
      final classNames = {
        for (final entity in inventory.entities)
          entity.schemaName: entity.className,
      };
      final schemas = <String, Schema>{};
      for (final root in IsarSetup.schemasForTesting) {
        schemas[root.name] = root;
        schemas.addAll(root.embeddedSchemas);
      }
      final expected = <String>{};
      void visit(String root, Schema schema, List<String> path) {
        for (final property in schema.properties.values) {
          final next = [...path, property.name];
          final key = '${classNames[schema.name]}.${property.name}';
          if (IsarMissingFieldDefaults.repairedFields.contains(key)) {
            expected.add('$root:${next.join('.')}');
          }
          if (property.target != null) {
            visit(root, schemas[property.target]!, next);
          }
        }
      }

      for (final root in IsarSetup.schemasForTesting) {
        visit(root.name, root, []);
      }
      expect(
        numericFieldEvidence
            .map((f) => '${f.rootSchema}:${f.path.join('.')}')
            .toSet(),
        expected,
      );
    },
  );

  test(
    'every real collection/embedded property has source inventory coverage',
    () {
      final inventory = inventoryIsarFields();
      final schemas = <String, Schema>{};
      for (final root in IsarSetup.schemasForTesting) {
        schemas[root.name] = root;
        schemas.addAll(root.embeddedSchemas);
      }
      expect(
        schemas.keys.toSet(),
        inventory.entities.map((e) => e.schemaName).toSet(),
      );
      for (final entity in inventory.entities) {
        expect(
          schemas[entity.schemaName]!.properties.keys.toSet(),
          {
            ...entity.fields.where((f) => !f.isId).map((f) => f.persistedName),
            ...entity.getters.map((g) => g.persistedName),
          },
          reason: entity.className,
        );
      }
    },
  );

  test(
    'new nonnullable numeric fields require a repair or an explicit reviewed deferral',
    () {
      final inventory = inventoryIsarFields();
      final numeric = inventory.fields.where(
        (f) =>
            !f.isId && !f.isNullable && (f.type == 'int' || f.type == 'double'),
      );
      final reviewed = {
        ...IsarMissingFieldDefaults.repairedFields,
        ...IsarMissingFieldDefaults.deferredNumericFields.keys,
      };
      expect(
        numeric.map((f) => f.key).toSet().difference(reviewed),
        isEmpty,
        reason:
            'New numeric fields need migration evidence or an explicit deferral',
      );
      expect(numeric.map((f) => f.key).toSet(), {
        ...IsarMissingFieldDefaults.repairedFields,
        ...IsarMissingFieldDefaults.deferredNumericFields.keys,
      });
      expect(
        IsarMissingFieldDefaults.repairedFields.intersection(
          IsarMissingFieldDefaults.deferredNumericFields.keys.toSet(),
        ),
        isEmpty,
      );
      expect(
        numericFieldEvidence.map((f) => f.key).toSet(),
        IsarMissingFieldDefaults.repairedFields,
      );
      for (final field in numeric.where(
        (f) => IsarMissingFieldDefaults.repairedFields.contains(f.key),
      )) {
        expect(field.initializer, isNotNull, reason: field.key);
      }
      final schemas = <String, Schema>{};
      for (final root in IsarSetup.schemasForTesting) {
        schemas[root.name] = root;
        schemas.addAll(root.embeddedSchemas);
      }
      for (final entity in inventory.entities) {
        for (final field in entity.fields.where(
          (f) => numeric.any((n) => n.key == f.key),
        )) {
          expect(
            schemas[entity.schemaName]!.properties[field.persistedName]!.type,
            field.type == 'int' ? IsarType.long : IsarType.double,
            reason:
                'New storage widths require a new missing-value probe: ${field.key}',
          );
        }
      }
    },
  );

  test(
    'ambiguous nonnumeric defaults cannot silently escape the reviewed list',
    () {
      final inventory = inventoryIsarFields();
      final schemas = <String, Schema>{};
      for (final root in IsarSetup.schemasForTesting) {
        schemas[root.name] = root;
        schemas.addAll(root.embeddedSchemas);
      }
      final mismatches = <String>{};
      for (final entity in inventory.entities) {
        for (final field in entity.fields) {
          if (field.initializer == null || field.isNullable || field.isId) {
            continue;
          }
          if (field.type == 'bool' && field.initializer != 'false' ||
              field.type == 'DateTime' ||
              field.type == 'String' && field.initializer != "''" ||
              field.type.startsWith('List<') && field.initializer != '[]') {
            mismatches.add(field.key);
          }
          if (field.enumAnnotation != null) {
            final values = schemas[entity.schemaName]!
                .properties[field.persistedName]!
                .enumMap!;
            if (field.initializer!.split('.').last != values.keys.first) {
              mismatches.add(field.key);
            }
          }
        }
      }
      expect(
        mismatches,
        IsarMissingFieldDefaults.deferredNonNumericFields.keys.toSet(),
      );
    },
  );
}
