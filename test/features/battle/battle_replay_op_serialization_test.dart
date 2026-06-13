import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/battle/domain/battle_replay.dart';

/// 半手动战斗 P0 步骤5:操作序列 JSON 序列化(落盘 BattleReplayRecord.opsJson)。
///
/// `{anchor, charId, skillId, targetId}` ↔ JSON round-trip。targetId 可空
/// (未指定目标走 AI 默认)需保真。
void main() {
  test('单条 op toJson/fromJson round-trip(含 targetId)', () {
    const op = BattleReplayOp(anchor: 3, charId: 1, skillId: 'sk_a', targetId: -2);
    final back = BattleReplayOp.fromJson(op.toJson());
    expect(back, equals(op));
  });

  test('targetId=null 序列化保真', () {
    const op = BattleReplayOp(anchor: 5, charId: 2, skillId: 'sk_b');
    final back = BattleReplayOp.fromJson(op.toJson());
    expect(back, equals(op));
    expect(back.targetId, isNull);
  });

  test('列表 encodeList/decodeList round-trip(保序 + 逐字段全等)', () {
    const ops = [
      BattleReplayOp(anchor: 1, charId: 1, skillId: 'sk_a', targetId: -1),
      BattleReplayOp(anchor: 1, charId: 2, skillId: 'sk_b'),
      BattleReplayOp(anchor: 4, charId: 3, skillId: 'sk_c', targetId: -3),
    ];
    final json = BattleReplayOp.encodeList(ops);
    final back = BattleReplayOp.decodeList(json);
    expect(back, equals(ops));
  });

  test('空列表 round-trip', () {
    final json = BattleReplayOp.encodeList(const []);
    expect(BattleReplayOp.decodeList(json), isEmpty);
  });
}
