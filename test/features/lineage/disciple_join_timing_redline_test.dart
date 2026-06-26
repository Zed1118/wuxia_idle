import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/game_repository.dart';

/// 队伍解锁时机语义守护(2026-06-26 · 用户拍板「靠后」)。
///
/// 编码设计意图(写语义不写瞬时数字),防未来把弟子入队又挪回前期:
/// ① 前期单主角 —— 无弟子在第 1 章入队(chapterIndex ≥ 2);
/// ② 收徒在章末大 Boss 关后(经历更强挑战后拜入,isBossStage);
/// ③ 大弟子(senior)先于二弟子(junior)入队 —— 保「三人成众」叙事框架成立
///    (二弟子拜入时大弟子已在队)。
void main() {
  late GameRepository repo;

  setUpAll(() async {
    repo = await GameRepository.loadAllDefs(
      loader: (path) => File(path).readAsString(),
    );
  });

  int chapterOf(String stageId) {
    final def = repo.stageDefs[stageId];
    expect(def, isNotNull, reason: '$stageId 应是真实存在的关卡');
    expect(def!.chapterIndex, isNotNull, reason: '$stageId 应有 chapterIndex');
    return def.chapterIndex!;
  }

  test('① 前期单主角:无弟子在第 1 章入队(chapterIndex ≥ 2)', () {
    final joins = repo.numbers.lineageOnboarding.discipleJoins;
    expect(joins, isNotEmpty);
    for (final j in joins) {
      expect(
        chapterOf(j.stageId),
        greaterThanOrEqualTo(2),
        reason: '${j.stageId}(${j.role.name})入队过早 —— 前期应单主角',
      );
    }
  });

  test('② 收徒在章末大 Boss 关后(isBossStage)', () {
    for (final j in repo.numbers.lineageOnboarding.discipleJoins) {
      expect(
        repo.stageDefs[j.stageId]!.isBossStage,
        isTrue,
        reason: '${j.stageId} 应为章末 Boss 关',
      );
    }
  });

  test('③ 大弟子先于二弟子入队(保「三人成众」框架成立)', () {
    final joins = repo.numbers.lineageOnboarding.discipleJoins;
    final senior =
        joins.firstWhere((j) => j.role == LineageRole.senior);
    final junior =
        joins.firstWhere((j) => j.role == LineageRole.junior);
    expect(
      chapterOf(senior.stageId),
      lessThan(chapterOf(junior.stageId)),
      reason: '二弟子拜入时大弟子须已在队,否则入队文案「三人成众/你们」矛盾',
    );
  });
}
