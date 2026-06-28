import '../../../core/domain/enums.dart';
import '../../../data/defs/drop_entry.dart';

/// 闭关地图定义（numbers.yaml `retreat.maps[]`，Phase 3 T47）。
///
/// 5 张地图各有不同产出偏向（GDD §8.3），所有产出系数乘以境界缩放后得最终每小时产出。
class SeclusionMapDef {
  final RetreatMapType mapType;
  final String mapName;

  /// 可进入该地图所需的最低境界大阶。
  final RealmTier requiredRealm;

  final double experiencePerHour;
  final double mojianshiPerHour;

  /// 银两产出系数（P4 材料经济 P1）。每小时银两 = silverPerHour × actualHours × scale × solarBonus。
  final double silverPerHour;

  /// 装备掉落概率权重（1.0 = 基础，1.5 = +50%，与 base_equip_drop_probability 相乘）。
  final double equipmentDropRate;

  final double techniqueLearnRate;
  final double internalForceGrowth;

  /// 闭关通用物品产出（InventoryItem.defId → 每小时基础产出）。
  /// 与磨剑石/银两同乘 actualHours × realmScale × solarBonus。
  final Map<String, double> itemOutputsPerHour;

  /// 场景生境(C-W14-2)。闭关 actualHours 通过
  /// [EncounterService.recordIdleMinutes] 喂 biome 累计分钟。null = 未标。
  final EncounterBiome? biome;

  /// 默认天气(C-W14-2)。闭关挂机的天气当前简化为地图级常量(GDD §7.3 节气
  /// 系统留 §12 #7 决策)。null = clear 不喂。
  final EncounterWeather? weather;

  /// 地图大图资源路径(M4 PoC #46 美术 Stage 2 W6 收官 5 地图 9.0/10)。
  final String? imagePath;

  /// 闭关掉落表（numbers.yaml `retreat.maps[].dropTable`，B2 接通）。
  /// 压一阶定位：装备 tier 锁地图 requiredRealm 低一阶。缺省空表 = 不掉。
  final List<DropEntry> dropTable;

  /// 地图路径记录（numbers.yaml `retreat.maps[].route`）。
  /// 只用于收功回看，不改变收益，保证在线/离线同源。
  final List<String> routeSteps;

  /// 地图事件记录候选（numbers.yaml `retreat.maps[].event_notes`）。
  /// 按 actualHours 的 threshold 触发，只做叙事提示，不制造加速或留存压力。
  final List<RetreatMapEventDef> eventNotes;

  const SeclusionMapDef({
    required this.mapType,
    required this.mapName,
    required this.requiredRealm,
    required this.experiencePerHour,
    required this.mojianshiPerHour,
    required this.silverPerHour,
    required this.equipmentDropRate,
    required this.techniqueLearnRate,
    required this.internalForceGrowth,
    this.itemOutputsPerHour = const {},
    this.biome,
    this.weather,
    this.imagePath,
    this.dropTable = const [],
    this.routeSteps = const [],
    this.eventNotes = const [],
  });

  factory SeclusionMapDef.fromYaml(Map<String, dynamic> y) {
    final outputs = y['base_outputs'] as Map<String, dynamic>;
    return SeclusionMapDef(
      mapType: RetreatMapType.values.byName(y['map_type'] as String),
      mapName: y['map_name'] as String,
      requiredRealm: RealmTier.values.byName(y['required_realm'] as String),
      experiencePerHour: (outputs['experience_per_hour'] as num).toDouble(),
      mojianshiPerHour: (outputs['mojianshi_per_hour'] as num).toDouble(),
      silverPerHour: (outputs['silver_per_hour'] as num?)?.toDouble() ?? 0.0,
      equipmentDropRate: (outputs['equipment_drop_rate'] as num).toDouble(),
      techniqueLearnRate: (outputs['technique_learn_rate'] as num).toDouble(),
      internalForceGrowth: (outputs['internal_force_growth'] as num).toDouble(),
      itemOutputsPerHour: {
        for (final e
            in (outputs['item_outputs_per_hour'] as Map<String, dynamic>? ?? {})
                .entries)
          e.key: (e.value as num).toDouble(),
      },
      biome: (y['biome'] as String?) == null
          ? null
          : EncounterBiome.values.byName(y['biome'] as String),
      weather: (y['weather'] as String?) == null
          ? null
          : EncounterWeather.values.byName(y['weather'] as String),
      imagePath: y['image_path'] as String?,
      dropTable:
          (y['dropTable'] as List<dynamic>?)
              ?.map((e) => DropEntry.fromYaml(e as Map<String, dynamic>))
              .toList() ??
          const [],
      routeSteps: ((y['route'] as List<dynamic>?) ?? const []).cast<String>(),
      eventNotes: ((y['event_notes'] as List<dynamic>?) ?? const [])
          .map(
            (e) => RetreatMapEventDef.fromYaml(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList(growable: false),
    );
  }
}

class RetreatMapEventDef {
  final double triggerAfterHours;
  final RetreatMapEventKind kind;
  final String text;

  const RetreatMapEventDef({
    required this.triggerAfterHours,
    required this.kind,
    required this.text,
  });

  factory RetreatMapEventDef.fromYaml(Map<String, dynamic> y) {
    return RetreatMapEventDef(
      triggerAfterHours: (y['trigger_after_hours'] as num).toDouble(),
      kind: RetreatMapEventKind.values.byName(y['kind'] as String),
      text: y['text'] as String,
    );
  }
}

enum RetreatMapEventKind { harvest, risk, trace }

class RetreatMapEventRecord {
  final double hourMark;
  final RetreatMapEventKind kind;
  final String text;

  const RetreatMapEventRecord({
    required this.hourMark,
    required this.kind,
    required this.text,
  });
}
