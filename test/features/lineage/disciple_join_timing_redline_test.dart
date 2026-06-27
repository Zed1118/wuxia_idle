import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/game_repository.dart';

/// 队伍解锁时机语义守护(2026-06-27 · spec A 后移至终局)。
///
/// 编码设计意图(写语义不写瞬时数字),防未来把弟子入队又挪回前期:
/// ① 前期单主角 —— 无弟子在第 1 章入队(chapterIndex ≥ 2);
/// ② 收徒在章末大 Boss 关后(经历更强挑战后拜入,isBossStage);
/// ③ 大弟子(senior)在二弟子(junior)之前 —— spec A 后移后两弟子**同关终局**
///    一并拜入,senior 配置序先于 junior(拜师叙事 senior 先弹、junior 后补满),
///    「三人成众」叙事框架仍成立。
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

  test('③ 大弟子先于二弟子(同关终局拜入,senior 配置序先于 junior)', () {
    final joins = repo.numbers.lineageOnboarding.discipleJoins;
    final seniorIdx = joins.indexWhere((j) => j.role == LineageRole.senior);
    final juniorIdx = joins.indexWhere((j) => j.role == LineageRole.junior);
    expect(seniorIdx, greaterThanOrEqualTo(0), reason: '应有 senior 拜入条目');
    expect(juniorIdx, greaterThanOrEqualTo(0), reason: '应有 junior 拜入条目');
    // spec A:两弟子同关(stage_06_05)一并拜入,故同 stageId;senior 配置序先于
    // junior,拜师叙事 senior 先弹、junior 后入队补满,「三人成众/你们」文案自洽。
    expect(
      joins[seniorIdx].stageId,
      joins[juniorIdx].stageId,
      reason: 'spec A 后移:两弟子同关终局一并拜入',
    );
    expect(
      seniorIdx,
      lessThan(juniorIdx),
      reason: 'senior 配置序须先于 junior,否则拜入叙事顺序矛盾',
    );
  });
}
