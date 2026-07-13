import '../../../core/domain/enums.dart';

class ResonanceUpgradeNotice {
  final String equipmentName;
  final ResonanceStage newStage;

  const ResonanceUpgradeNotice({
    required this.equipmentName,
    required this.newStage,
  });

  @override
  String toString() =>
      'ResonanceUpgradeNotice($equipmentName → ${newStage.name})';
}
