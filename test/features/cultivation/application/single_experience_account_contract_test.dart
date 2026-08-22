import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../../support/dart_source_contract.dart';

void main() {
  const productionExperiencePaths = [
    'lib/features/mainline/presentation/stage_entry_flow.dart',
    'lib/features/tower/presentation/tower_entry_flow.dart',
    'lib/features/combat_shared/application/combat_progression_settlement_service.dart',
    'lib/features/seclusion/application/seclusion_service.dart',
    'lib/features/seclusion/application/offline_passive_service.dart',
    'lib/features/inventory/application/item_use_service.dart',
  ];

  test(
    'all production experience paths ignore the legacy level account',
    () async {
      for (final path in productionExperiencePaths) {
        final contract = DartSourceContract.parse(
          await File(path).readAsString(),
          path: path,
        );
        expect(contract.memberAccessCount('level'), 0, reason: path);
        expect(contract.memberAccessCount('levelExp'), 0, reason: path);
        expect(contract.identifierCount('LevelService'), 0, reason: path);
        expect(contract.identifierCount('LevelConfig'), 0, reason: path);
      }
    },
  );

  test('AST guard catches legacy level reads, writes, and chained access', () {
    final contract = DartSourceContract.parse('''
void probe(dynamic character, dynamic repository) {
  final snapshot = character.level;
  character.level = 1;
  character.level += 2;
  character.level++;
  final repositoryLevel = repository.numbers.level;
  final localLevel = this.numbers.level;
  final singletonLevel = GameRepository.instance.numbers.level;
}
''');

    expect(contract.memberAccessCount('level'), 7);
  });

  test('AST guard catches legacy levelExp reads and every write form', () {
    final contract = DartSourceContract.parse('''
void probe(dynamic character) {
  final snapshot = character.levelExp;
  character.levelExp = 1;
  character.levelExp += 2;
  character.levelExp++;
}
''');

    expect(contract.memberAccessCount('levelExp'), 4);
  });

  test('AST guard ignores legacy-looking comments and string literals', () {
    final contract = DartSourceContract.parse(r'''
void probe() {
  // character.level += 1;
  // character.levelExp += 1;
  const fakeLevelRead = 'character.level';
  const fakeLevelWrite = 'character.level++';
  const fakeRead = 'character.levelExp';
  const fakeWrite = 'character.levelExp++';
}
''');

    expect(contract.memberAccessCount('level'), 0);
    expect(contract.memberAccessCount('levelExp'), 0);
  });
}
