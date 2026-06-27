enum BuildingType {
  tieJiangChang,
  caoYaoYuan,
  daZaoTai,
  danFang,
  muGongFang,
  lingQuan,
  zhuZaoTai,
}

enum BuildingKind { source, processor }

class RecipeDef {
  final String recipeId;
  final String outputItem;
  final double inputPerOutput;
  final double ratePerHour;
  final int realmUnlockIndex;

  const RecipeDef({
    required this.recipeId,
    required this.outputItem,
    required this.inputPerOutput,
    required this.ratePerHour,
    required this.realmUnlockIndex,
  });

  factory RecipeDef.fromYaml(Map<String, dynamic> y) => RecipeDef(
        recipeId: y['recipe_id'] as String,
        outputItem: y['output_item'] as String,
        inputPerOutput: (y['input_per_output'] as num).toDouble(),
        ratePerHour: (y['rate_per_hour'] as num).toDouble(),
        realmUnlockIndex: (y['realm_unlock_index'] as num).toInt(),
      );
}

const _yamlKeyByType = {
  'tie_jiang_chang': BuildingType.tieJiangChang,
  'cao_yao_yuan': BuildingType.caoYaoYuan,
  'da_zao_tai': BuildingType.daZaoTai,
  'dan_fang': BuildingType.danFang,
  'mu_gong_fang': BuildingType.muGongFang,
  'ling_quan': BuildingType.lingQuan,
  'zhu_zao_tai': BuildingType.zhuZaoTai,
};

BuildingType buildingTypeFromYamlKey(String k) =>
    _yamlKeyByType[k] ?? (throw ArgumentError('未知建筑 key: $k'));
