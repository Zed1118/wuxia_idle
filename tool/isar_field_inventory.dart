import 'dart:convert';
import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';

/// Source declarations, independent of generated schemas and entity imports.
///
/// This inventory deliberately does not claim that a Dart initializer is the
/// value Isar supplies when a property is missing from an older database.
final class IsarFieldInventory {
  IsarFieldInventory(Iterable<IsarEntityInventory> entities)
    : entities = List.unmodifiable(entities);

  final List<IsarEntityInventory> entities;

  Iterable<IsarFieldInventoryEntry> get fields =>
      entities.expand((entity) => entity.fields);

  Map<String, Object?> toJson() => {
    'scope': 'Dart declarations; missing-property behavior requires a real DB',
    'counts': {
      'entities': entities.length,
      'collections': entities.where((e) => e.kind == 'collection').length,
      'embedded': entities.where((e) => e.kind == 'embedded').length,
      'fieldsIncludingIds': fields.length,
      'idFields': fields.where((f) => f.isId).length,
      'nonIdFields': fields.where((f) => !f.isId).length,
      'nullableFields': fields.where((f) => f.isNullable).length,
      'lateFields': fields.where((f) => f.isLate).length,
      'fieldsWithInitializer': fields
          .where((f) => f.initializer != null)
          .length,
      'enumAnnotatedFields': fields
          .where((f) => f.enumAnnotation != null)
          .length,
      'gettersExcludedFromFields': entities.fold<int>(
        0,
        (count, entity) => count + entity.getters.length,
      ),
    },
    'entities': entities.map((entity) => entity.toJson()).toList(),
  };
}

final class IsarEntityInventory {
  IsarEntityInventory({
    required this.className,
    required this.schemaName,
    required this.kind,
    required this.file,
    required this.line,
    required Iterable<IsarFieldInventoryEntry> fields,
    required Iterable<IsarGetterInventoryEntry> getters,
  }) : fields = List.unmodifiable(fields),
       getters = List.unmodifiable(getters);

  final String className;
  final String schemaName;
  final String kind;
  final String file;
  final int line;
  final List<IsarFieldInventoryEntry> fields;
  final List<IsarGetterInventoryEntry> getters;

  String get location => '$file:$line';

  Map<String, Object?> toJson() => {
    'className': className,
    'schemaName': schemaName,
    'kind': kind,
    'file': file,
    'line': line,
    'location': location,
    'fields': fields.map((field) => field.toJson()).toList(),
    'getters': getters.map((getter) => getter.toJson()).toList(),
  };
}

final class IsarFieldInventoryEntry {
  const IsarFieldInventoryEntry({
    required this.className,
    required this.name,
    required this.persistedName,
    required this.type,
    required this.isId,
    required this.isNullable,
    required this.isLate,
    required this.isFinal,
    required this.initializer,
    required this.enumAnnotation,
    required this.file,
    required this.line,
    required this.column,
  });

  final String className;
  final String name;
  final String persistedName;
  final String type;
  final bool isId;
  final bool isNullable;
  final bool isLate;
  final bool isFinal;
  final String? initializer;
  final String? enumAnnotation;
  final String file;
  final int line;
  final int column;

  String get key => '$className.$name';
  String get location => '$file:$line:$column';

  Map<String, Object?> toJson() => {
    'className': className,
    'name': name,
    'persistedName': persistedName,
    'type': type,
    'isId': isId,
    'isNullable': isNullable,
    'isLate': isLate,
    'isFinal': isFinal,
    'initializer': initializer,
    'enumAnnotation': enumAnnotation,
    'file': file,
    'line': line,
    'column': column,
    'location': location,
  };
}

/// Non-ignored instance getters are separate because schemas can persist them,
/// but they are not mutable fields eligible for a migration assignment.
final class IsarGetterInventoryEntry {
  const IsarGetterInventoryEntry({
    required this.name,
    required this.persistedName,
    required this.type,
    required this.file,
    required this.line,
  });

  final String name;
  final String persistedName;
  final String type;
  final String file;
  final int line;

  Map<String, Object?> toJson() => {
    'name': name,
    'persistedName': persistedName,
    'type': type,
    'file': file,
    'line': line,
  };
}

/// Parses every non-generated Dart file below [sourceDirectory] (default lib).
///
/// Only explicitly declared, non-static, non-ignored fields on annotated
/// classes enter [IsarFieldInventory.fields]. Inheritance and inferred field
/// types fail closed instead of silently producing an incomplete inventory.
IsarFieldInventory inventoryIsarFields({Directory? sourceDirectory}) {
  final root = (sourceDirectory ?? Directory('lib')).absolute;
  if (!root.existsSync()) {
    throw ArgumentError.value(root.path, 'sourceDirectory', 'Does not exist');
  }
  final files =
      root
          .listSync(recursive: true, followLinks: false)
          .whereType<File>()
          .where(
            (file) =>
                file.path.endsWith('.dart') && !file.path.endsWith('.g.dart'),
          )
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));
  final entities = <IsarEntityInventory>[];
  for (final file in files) {
    final relativePath = file.path
        .substring(root.parent.path.length + 1)
        .replaceAll(Platform.pathSeparator, '/');
    final parsed = parseString(
      content: file.readAsStringSync(),
      path: relativePath,
      throwIfDiagnostics: false,
    );
    if (parsed.errors.isNotEmpty) {
      throw StateError(
        'Cannot parse $relativePath: ${parsed.errors.join(', ')}',
      );
    }
    for (final entity
        in parsed.unit.declarations.whereType<ClassDeclaration>()) {
      final collection = _annotation(entity.metadata, {
        'collection',
        'Collection',
      });
      final embedded = _annotation(entity.metadata, {'embedded', 'Embedded'});
      if (collection == null && embedded == null) continue;
      final className = entity.name.lexeme;
      if (entity.extendsClause != null || entity.withClause != null) {
        throw StateError(
          '$relativePath:$className has inherited fields; extend the inventory '
          'before accepting its coverage',
        );
      }
      final fields = <IsarFieldInventoryEntry>[];
      final getters = <IsarGetterInventoryEntry>[];
      for (final member in entity.members) {
        if (_annotation(member.metadata, {'ignore', 'Ignore'}) != null) {
          continue;
        }
        if (member is FieldDeclaration && !member.isStatic) {
          final variables = member.fields;
          final type = variables.type;
          if (type == null) {
            throw StateError(
              '$relativePath:$className has an inferred field type: '
              '${member.toSource()}',
            );
          }
          for (final variable in variables.variables) {
            final location = parsed.lineInfo.getLocation(variable.name.offset);
            fields.add(
              IsarFieldInventoryEntry(
                className: className,
                name: variable.name.lexeme,
                persistedName: _persistedName(
                  member.metadata,
                  variable.name.lexeme,
                ),
                type: type.toSource(),
                isId: type is NamedType && type.name.lexeme == 'Id',
                isNullable: type.question != null,
                isLate: variables.lateKeyword != null,
                isFinal: variables.isFinal,
                initializer: variable.initializer?.toSource(),
                enumAnnotation: _annotation(member.metadata, {
                  'enumerated',
                  'Enumerated',
                })?.toSource(),
                file: relativePath,
                line: location.lineNumber,
                column: location.columnNumber,
              ),
            );
          }
        } else if (member is MethodDeclaration &&
            member.isGetter &&
            !member.isStatic) {
          getters.add(
            IsarGetterInventoryEntry(
              name: member.name.lexeme,
              persistedName: _persistedName(
                member.metadata,
                member.name.lexeme,
              ),
              type: member.returnType?.toSource() ?? '<inferred>',
              file: relativePath,
              line: parsed.lineInfo.getLocation(member.name.offset).lineNumber,
            ),
          );
        }
      }
      entities.add(
        IsarEntityInventory(
          className: className,
          schemaName: _persistedName(entity.metadata, className),
          kind: collection != null ? 'collection' : 'embedded',
          file: relativePath,
          line: parsed.lineInfo.getLocation(entity.name.offset).lineNumber,
          fields: fields,
          getters: getters,
        ),
      );
    }
  }
  if (entities.isEmpty) {
    throw StateError('No Isar entities found in ${root.path}');
  }
  return IsarFieldInventory(entities);
}

Annotation? _annotation(Iterable<Annotation> metadata, Set<String> names) {
  for (final annotation in metadata) {
    if (names.contains(annotation.name.toSource().split('.').last)) {
      return annotation;
    }
  }
  return null;
}

String _persistedName(Iterable<Annotation> metadata, String fallback) {
  final annotation = _annotation(metadata, {'Name'});
  if (annotation == null) return fallback;
  final arguments = annotation.arguments?.arguments;
  if (arguments != null && arguments.length == 1) {
    final argument = arguments.single;
    if (argument is StringLiteral && argument.stringValue != null) {
      return argument.stringValue!;
    }
  }
  throw StateError('Cannot determine persisted name: ${annotation.toSource()}');
}

void main(List<String> arguments) {
  final remaining = [...arguments];
  final outputIndex = remaining.indexOf('--output');
  String? outputPath;
  if (outputIndex >= 0 && outputIndex + 1 < remaining.length) {
    outputPath = remaining[outputIndex + 1];
    remaining.removeRange(outputIndex, outputIndex + 2);
  }
  if (remaining.length > 1 || remaining.any((a) => a.startsWith('--'))) {
    throw ArgumentError(
      'Usage: dart run tool/isar_field_inventory.dart [lib] [--output path]',
    );
  }
  final inventory = inventoryIsarFields(
    sourceDirectory: remaining.isEmpty ? null : Directory(remaining.single),
  );
  final json = const JsonEncoder.withIndent('  ').convert(inventory.toJson());
  if (outputPath == null) {
    stdout.writeln(json);
  } else {
    File(outputPath).writeAsStringSync('$json\n');
  }
}
