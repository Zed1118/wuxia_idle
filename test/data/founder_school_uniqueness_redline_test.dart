import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/defs/founder_creation_def.dart';
import 'package:wuxia_idle/data/game_repository.dart';

/// 祖师塑形 schools 唯一性红线：id 与 school 各自唯一，
/// 防同一流派配多条 schools 项致创建页选项漂移（覆盖度红线兜不住）。
void main() {
  FounderSchoolOption school(String id, TechniqueSchool s) => FounderSchoolOption(
        id: id,
        school: s,
        label: '$id-label',
        temperament: '气质',
        summary: '简介',
        attributeHint: '属性提示',
        startingTechniqueIds: const ['tech_x'],
        goalHint: '目标',
      );

  test('三流派各一条 → 不抛', () {
    expect(
      () => enforceFounderSchoolUniqueness([
        school('gang_meng', TechniqueSchool.gangMeng),
        school('ling_qiao', TechniqueSchool.lingQiao),
        school('yin_rou', TechniqueSchool.yinRou),
      ]),
      returnsNormally,
    );
  });

  test('id 重复 → 抛', () {
    expect(
      () => enforceFounderSchoolUniqueness([
        school('gang_meng', TechniqueSchool.gangMeng),
        school('gang_meng', TechniqueSchool.lingQiao),
      ]),
      throwsStateError,
    );
  });

  test('school 重复(同流派配两条·覆盖度红线兜不住的缺口) → 抛', () {
    // id 不同但 school 同 → 凑满三流派的覆盖度校验单独跑会漏过,本红线拦下。
    expect(
      () => enforceFounderSchoolUniqueness([
        school('gang_meng_a', TechniqueSchool.gangMeng),
        school('gang_meng_b', TechniqueSchool.gangMeng),
        school('ling_qiao', TechniqueSchool.lingQiao),
        school('yin_rou', TechniqueSchool.yinRou),
      ]),
      throwsStateError,
    );
  });

  test('空列表 → 不抛(覆盖度红线另行兜底)', () {
    expect(
      () => enforceFounderSchoolUniqueness(const []),
      returnsNormally,
    );
  });
}
