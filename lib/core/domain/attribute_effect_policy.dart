import 'dart:math' as math;

import 'attributes.dart';

enum EncounterProbabilitySource { enlightenment, fortune }

final class AttributeEffectRules {
  const AttributeEffectRules({
    required this.referenceValue,
    required this.heavyInjuryReductionPerPoint,
    required this.heavyInjuryReductionMax,
    required this.growthBonusPerPoint,
    required this.growthBonusMax,
    required this.insightProbabilitySensitivity,
    required this.fortuneProbabilitySensitivity,
    required this.specialChoiceRequired,
  });

  final int referenceValue;
  final double heavyInjuryReductionPerPoint;
  final double heavyInjuryReductionMax;
  final double growthBonusPerPoint;
  final double growthBonusMax;
  final double insightProbabilitySensitivity;
  final double fortuneProbabilitySensitivity;
  final int specialChoiceRequired;

  factory AttributeEffectRules.fromYaml(Map<String, dynamic> yaml) {
    try {
      final constitution = _requiredMap(yaml, 'constitution');
      final enlightenment = _requiredMap(yaml, 'enlightenment');
      final fortune = _requiredMap(yaml, 'fortune');
      final rules = AttributeEffectRules(
        referenceValue: _requiredInt(yaml, 'reference_value'),
        heavyInjuryReductionPerPoint: _requiredDouble(
          constitution,
          'heavy_injury_reduction_per_point',
        ),
        heavyInjuryReductionMax: _requiredDouble(
          constitution,
          'heavy_injury_reduction_max',
        ),
        growthBonusPerPoint: _requiredDouble(
          enlightenment,
          'growth_bonus_per_point',
        ),
        growthBonusMax: _requiredDouble(enlightenment, 'growth_bonus_max'),
        insightProbabilitySensitivity: _requiredDouble(
          enlightenment,
          'insight_probability_sensitivity',
        ),
        fortuneProbabilitySensitivity: _requiredDouble(
          fortune,
          'encounter_probability_sensitivity',
        ),
        specialChoiceRequired: _requiredInt(fortune, 'special_choice_required'),
      );
      rules._validate();
      return rules;
    } on FormatException {
      rethrow;
    } catch (error) {
      throw FormatException('attribute_effects 配置无效: $error');
    }
  }

  void _validate() {
    if (referenceValue < 0 || specialChoiceRequired < 0) {
      throw const FormatException('attribute_effects 属性阈值不得为负数');
    }
    if (heavyInjuryReductionPerPoint < 0 ||
        heavyInjuryReductionMax < 0 ||
        heavyInjuryReductionMax > 1 ||
        growthBonusPerPoint < 0 ||
        growthBonusMax < 0 ||
        insightProbabilitySensitivity <= 0 ||
        fortuneProbabilitySensitivity <= 0) {
      throw const FormatException('attribute_effects 系数超出有效范围');
    }
  }

  static Map<String, dynamic> _requiredMap(
    Map<String, dynamic> yaml,
    String key,
  ) {
    final value = yaml[key];
    if (value is! Map) throw FormatException('attribute_effects 缺少 $key');
    return value.cast<String, dynamic>();
  }

  static int _requiredInt(Map<String, dynamic> yaml, String key) {
    final value = yaml[key];
    if (value is! num || value.toInt() != value) {
      throw FormatException('attribute_effects.$key 必须为整数');
    }
    return value.toInt();
  }

  static double _requiredDouble(Map<String, dynamic> yaml, String key) {
    final value = yaml[key];
    if (value is! num) {
      throw FormatException('attribute_effects.$key 必须为数字');
    }
    return value.toDouble();
  }
}

final class AttributeEffectPolicy {
  const AttributeEffectPolicy(this.rules);

  final AttributeEffectRules rules;

  double heavyInjuryHours({
    required double baseHours,
    required int constitution,
  }) {
    final points = math.max(0, constitution - rules.referenceValue);
    final reduction = math.min(
      rules.heavyInjuryReductionMax,
      points * rules.heavyInjuryReductionPerPoint,
    );
    return baseHours * (1 - reduction);
  }

  double growthMultiplier({required int enlightenment}) {
    final points = math.max(0, enlightenment - rules.referenceValue);
    final bonus = math.min(
      rules.growthBonusMax,
      points * rules.growthBonusPerPoint,
    );
    return 1 + bonus;
  }

  int effectiveUsageCount({required int rawUses, required int enlightenment}) =>
      (rawUses * growthMultiplier(enlightenment: enlightenment)).floor();

  int effectiveProgressDelta({
    required int rawBefore,
    required int rawDelta,
    required int enlightenment,
  }) {
    final multiplier = growthMultiplier(enlightenment: enlightenment);
    return ((rawBefore + rawDelta) * multiplier).floor() -
        (rawBefore * multiplier).floor();
  }

  double encounterProbability({
    required double base,
    required EncounterProbabilitySource source,
    required Attributes attributes,
  }) {
    final (value, sensitivity) = switch (source) {
      EncounterProbabilitySource.enlightenment => (
        attributes.enlightenment,
        rules.insightProbabilitySensitivity,
      ),
      EncounterProbabilitySource.fortune => (
        attributes.fortune,
        rules.fortuneProbabilitySensitivity,
      ),
    };
    return (base * (1 + value / sensitivity)).clamp(0.0, 1.0);
  }
}
