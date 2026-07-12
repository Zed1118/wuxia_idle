import 'character.dart';

abstract final class InnerBreathDisorder {
  static double apply({
    required Character character,
    required double hours,
    required double maxHours,
  }) {
    final safeMax = maxHours < 0 ? 0.0 : maxHours;
    final next = character.innerBreathDisorderHoursRemaining + hours;
    character.innerBreathDisorderHoursRemaining = next.clamp(0.0, safeMax);
    return character.innerBreathDisorderHoursRemaining;
  }

  static double recover({required Character character, required double hours}) {
    final next = character.innerBreathDisorderHoursRemaining - hours;
    character.innerBreathDisorderHoursRemaining = next < 0 ? 0 : next;
    return character.innerBreathDisorderHoursRemaining;
  }
}
