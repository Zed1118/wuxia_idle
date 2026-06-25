import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/features/injury/application/injury_service.dart';

void main() {
  test('applyHeavyInjury 设 injuryHoursRemaining=recoveryHours,再伤刷新不叠加', () {
    final c = Character()..injuryHoursRemaining = 0;
    InjuryService.applyHeavyInjury(c, recoveryHours: 8.0);
    expect(c.injuryHoursRemaining, 8.0);
    c.injuryHoursRemaining = 3.0; // 疗养中
    InjuryService.applyHeavyInjury(c, recoveryHours: 8.0); // 再伤
    expect(c.injuryHoursRemaining, 8.0, reason: '刷新不叠加(仿余毒)');
  });
  test('accumulateLightInjury +1 不超 maxStacks', () {
    final c = Character()..lightInjuryStacks = 4;
    InjuryService.accumulateLightInjury(c, maxStacks: 5);
    expect(c.lightInjuryStacks, 5);
    InjuryService.accumulateLightInjury(c, maxStacks: 5);
    expect(c.lightInjuryStacks, 5, reason: 'clamp 到 maxStacks');
  });
}
