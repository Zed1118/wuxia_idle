import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/save_data.dart';
import 'package:wuxia_idle/shared/battle_shared/current_leader_resolver.dart';

void main() {
  test('null save or pointer fails closed with a diagnostic error', () async {
    expect(
      () => CurrentLeaderResolver.resolve(
        save: null,
        characterExists: (_) async => true,
      ),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          contains('founderCharacterId'),
        ),
      ),
    );

    expect(
      () => CurrentLeaderResolver.resolve(
        save: SaveData(),
        characterExists: (_) async => true,
      ),
      throwsA(isA<StateError>()),
    );
  });

  test(
    'valid pointer resolves exactly and does not inspect another role',
    () async {
      final save = SaveData()..founderCharacterId = 42;
      final lookedUp = <int>[];

      final id = await CurrentLeaderResolver.resolve(
        save: save,
        characterExists: (characterId) async {
          lookedUp.add(characterId);
          return characterId == 42;
        },
      );

      expect(id, 42);
      expect(lookedUp, [42]);
    },
  );

  test('悬空 pointer fails closed without first-character fallback', () {
    final save = SaveData()..founderCharacterId = 42;

    expect(
      () => CurrentLeaderResolver.resolve(
        save: save,
        characterExists: (_) async => false,
      ),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          allOf(contains('42'), contains('no Character')),
        ),
      ),
    );
  });

  test('合法传位前后指针均原样返回', () async {
    for (final characterId in [1, 2]) {
      final save = SaveData()..founderCharacterId = characterId;

      expect(
        await CurrentLeaderResolver.resolve(
          save: save,
          characterExists: (id) async => id == characterId,
        ),
        characterId,
      );
    }
  });
}
