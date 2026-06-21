import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/defs/item_def.dart';

void main() {
  group('ItemDef.fromYaml — jingYanDan', () {
    test('jingYanDan 解析 layer_fraction', () {
      final d = ItemDef.fromYaml({
        'defId': 'x',
        'type': 'jingYanDan',
        'name': '丹',
        'layer_fraction': 0.5,
      });
      expect(d.layerFraction, 0.5);
    });

    test('jingYanDan 缺 layer_fraction 抛 StateError', () {
      expect(
        () => ItemDef.fromYaml({'defId': 'x', 'type': 'jingYanDan', 'name': '丹'}),
        throwsStateError,
      );
    });

    test('jingYanDan layer_fraction 支持整数 yaml 值', () {
      final d = ItemDef.fromYaml({
        'defId': 'x',
        'type': 'jingYanDan',
        'name': '丹',
        'layer_fraction': 1,
      });
      expect(d.layerFraction, 1.0);
    });
  });

  group('ItemDef.fromYaml — techniqueScroll', () {
    test('techniqueScroll 解析 unlockSkillId', () {
      final d = ItemDef.fromYaml({
        'defId': 'scroll_1',
        'type': 'techniqueScroll',
        'name': '秘籍',
        'unlockSkillId': 'skill_abc',
      });
      expect(d.unlockSkillId, 'skill_abc');
      expect(d.layerFraction, isNull);
    });

    test('techniqueScroll 缺 unlockSkillId 抛 StateError', () {
      expect(
        () => ItemDef.fromYaml({'defId': 'scroll_1', 'type': 'techniqueScroll', 'name': '秘籍'}),
        throwsStateError,
      );
    });
  });
}
