import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/defs/master_def.dart';

void main() {
  test('MasterDef 解析 senior/junior 子枚举', () {
    final senior = MasterDef.fromYaml({
      'id': 't_senior', 'lineageRole': 'senior', 'slotIndex': 1,
      'defaultRealm': 'xueTu', 'defaultLayer': 'qiMeng',
      'attributeProfile': {'constitution': 5, 'enlightenment': 5, 'agility': 5, 'fortune': 5},
    });
    expect(senior.lineageRole, LineageRole.senior);
    final junior = MasterDef.fromYaml({
      'id': 't_junior', 'lineageRole': 'junior', 'slotIndex': 2,
      'defaultRealm': 'xueTu', 'defaultLayer': 'qiMeng',
      'attributeProfile': {'constitution': 5, 'enlightenment': 5, 'agility': 5, 'fortune': 5},
    });
    expect(junior.lineageRole, LineageRole.junior);
  });

  test('LineageRole 保留 disciple 值供老档反序列化', () {
    expect(LineageRole.values.byName('disciple'), LineageRole.disciple);
  });
}
