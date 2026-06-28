import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/defs/item_def.dart';
import 'package:wuxia_idle/data/game_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(GameRepository.resetForTest);

  test('经验丹 def fromYaml: type/name/layer_fraction 解析', () {
    final d = ItemDef.fromYaml({
      'defId': 'item_jingyandan_small',
      'type': 'jingYanDan',
      'name': '凝神丹',
      'layer_fraction': 0.2,
    });
    expect(d.defId, 'item_jingyandan_small');
    expect(d.type, ItemType.jingYanDan);
    expect(d.name, '凝神丹');
    expect(d.layerFraction, 0.2);
    expect(d.unlockSkillId, isNull);
  });

  test('秘籍 def fromYaml: unlockSkillId 解析', () {
    final d = ItemDef.fromYaml({
      'defId': 'item_scroll_kai_bei_shou',
      'type': 'techniqueScroll',
      'name': '开碑手·秘籍',
      'unlockSkillId': 'skill_kai_bei_shou',
    });
    expect(d.type, ItemType.techniqueScroll);
    expect(d.unlockSkillId, 'skill_kai_bei_shou');
    expect(d.layerFraction, isNull);
  });

  test('疗伤 def fromYaml: recovery 字段解析', () {
    final d = ItemDef.fromYaml({
      'defId': 'item_liaoshangdan',
      'type': 'miscMaterial',
      'name': '疗伤丹',
      'injury_heal_hours': 4,
      'residue_heal_hours': 2.0,
      'clear_light_injury': true,
    });
    expect(d.type, ItemType.miscMaterial);
    expect(d.injuryHealHours, 4.0);
    expect(d.residueHealHours, 2.0);
    expect(d.clearLightInjury, isTrue);
    expect(d.hasRecoveryEffect, isTrue);
    expect(d.isUsable, isTrue);
  });

  test('经验丹 layer_fraction 支持整数 yaml 值（1→1.0）', () {
    final d = ItemDef.fromYaml({
      'defId': 'x',
      'type': 'jingYanDan',
      'name': '丹',
      'layer_fraction': 1,
    });
    expect(d.layerFraction, 1.0);
  });

  test('经验丹缺 layer_fraction → 抛错', () {
    expect(
      () => ItemDef.fromYaml({'defId': 'x', 'type': 'jingYanDan', 'name': 'x'}),
      throwsStateError,
    );
  });

  test('秘籍缺 unlockSkillId → 抛错', () {
    expect(
      () => ItemDef.fromYaml({
        'defId': 'x',
        'type': 'techniqueScroll',
        'name': 'x',
      }),
      throwsStateError,
    );
  });

  test('GameRepository 加载 items.yaml: 核心道具 def 完整', () async {
    final repo = await GameRepository.loadAllDefs();
    expect(repo.itemDefs.length, greaterThanOrEqualTo(23));
    expect(repo.itemDefs['item_jingyandan_small']?.layerFraction, 0.2);
    expect(repo.itemDefs['item_liaoshangdan']?.injuryHealHours, 4.0);
    expect(repo.itemDefs['item_liaoshangdan']?.residueHealHours, 2.0);
    expect(repo.itemDefs['item_liaoshangdan']?.clearLightInjury, isTrue);
    expect(
      repo.itemDefs['item_scroll_kai_bei_shou']?.unlockSkillId,
      'skill_kai_bei_shou',
    );

    const phaseTwoIds = [
      'item_mucai',
      'item_lingquanshui',
      'item_liaoshangdan',
      'item_duancai',
      'item_kaifeng_fucai',
      'item_xingnang_buji',
    ];
    for (final id in phaseTwoIds) {
      expect(repo.itemDefs.containsKey(id), isTrue, reason: id);
    }
  });
}
