import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/defs/faction_def.dart';

void main() {
  test('fromYaml parses complete faction definition', () {
    final def = FactionDef.fromYaml({
      'id': 'shaolin',
      'name': '少林寺',
      'alignment': 'orthodox',
      'npc_ids': ['shaolin_abbot'],
    });

    expect(def.id, 'shaolin');
    expect(def.name, '少林寺');
    expect(def.alignment, 'orthodox');
    expect(def.npcIds, ['shaolin_abbot']);
  });

  test('fromYaml rejects blank id or name', () {
    expect(
      () => FactionDef.fromYaml({
        'id': '',
        'name': '无名',
        'alignment': 'neutral',
        'npc_ids': const [],
      }),
      throwsStateError,
    );
    expect(
      () => FactionDef.fromYaml({
        'id': 'unknown',
        'name': '   ',
        'alignment': 'neutral',
        'npc_ids': const [],
      }),
      throwsStateError,
    );
  });

  test('fromYaml defaults missing npc_ids to empty', () {
    final def = FactionDef.fromYaml({
      'id': 'wudang',
      'name': '武当派',
      'alignment': 'orthodox',
    });
    expect(def.npcIds, isEmpty);
  });
}
