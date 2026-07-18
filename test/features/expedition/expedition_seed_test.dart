import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/expedition/domain/expedition_seed.dart';

void main() {
  test('相同(存档,远征,节点)得相同 seed；不同输入得不同 seed', () {
    expect(
      ExpeditionSeed.forNode(saveId: 1, runSerial: 3, node: 7),
      ExpeditionSeed.forNode(saveId: 1, runSerial: 3, node: 7),
    );
    expect(
      ExpeditionSeed.forNode(saveId: 1, runSerial: 3, node: 7),
      isNot(ExpeditionSeed.forNode(saveId: 1, runSerial: 3, node: 8)),
    );
    expect(
      ExpeditionSeed.forNode(saveId: 1, runSerial: 3, node: 7),
      isNot(ExpeditionSeed.forNode(saveId: 2, runSerial: 3, node: 7)),
    );
  });
  test('seed 为非负 32-bit，重启稳定（显式混种，不用对象 hashCode）', () {
    final s = ExpeditionSeed.forNode(saveId: 12, runSerial: 5, node: 21);
    expect(s, greaterThanOrEqualTo(0));
    expect(s, lessThan(1 << 32));
  });
}
