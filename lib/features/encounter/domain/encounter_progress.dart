import 'package:isar_community/isar.dart';

import '../../../data/models/enums.dart';

part 'encounter_progress.g.dart';

/// 奇遇/武学领悟进度(C-W14-1)。
///
/// **每存档单行**:与 SaveData 一对一关联(Phase 3+ 仅 saveDataId=1)。
///
/// 设计取舍:
///   - [triggeredEncounterIds] 已触发列表,append-only;一次触发后不再
///     重新候选(Demo 简化 cooldown 模型,GDD §8.1 cooldown_days 留 W14-2)
///   - [schoolKillCounts] 按 [TechniqueSchool] 累计击杀数;只增不减,不按
///     encounter 清零(若多 encounter 都门槛 lingQiao=100,任一触发后另一仍
///     可候选)
///   - **属性微调 lifetime cap**(GDD §4.1 line 183 "生涯 +3~5 点"):
///     4 个 [attributeGains*] 字段总和上限 [attributeGainCap](默认 5,
///     由 EncounterService 强制)
@collection
class EncounterProgress {
  Id id = Isar.autoIncrement;

  /// 关联 SaveData.slotId(Phase 3+ 固定 1)。
  late int saveDataId;

  /// 已触发的 encounter id(无序集合语义,append-only)。
  List<String> triggeredEncounterIds = [];

  /// 按流派的击杀累积。@embedded 列表 + MapLike extension 模拟 Map。
  List<SchoolKillCount> schoolKillCounts = [];

  /// 按 biome 挂机累积分钟数(C-W14-2)。MapLike 体例,同 schoolKillCounts。
  /// 通过 [EncounterService.recordIdleMinutes] 累加(闭关 actualHours × 60)。
  List<BiomeMinutes> biomeMinutes = [];

  /// 按 weather 挂机累积分钟数(C-W14-2)。MapLike 体例,同 biomeMinutes。
  List<WeatherMinutes> weatherMinutes = [];

  /// 生涯累积属性微调点数(分 4 字段)。GDD §4.1 line 183 总和 ≤ 5。
  int attributeGainsConstitution = 0;
  int attributeGainsEnlightenment = 0;
  int attributeGainsAgility = 0;
  int attributeGainsFortune = 0;

  /// 奇遇专属解锁招式池(与常规 21 心法 × 3 招体系解耦,append-only)。
  /// Phase 1 仅记录;战斗系统消费 / 奇遇 skill 池字典留 W14-2 接。
  List<String> unlockedSkillIds = [];

  int get attributeGainsTotal =>
      attributeGainsConstitution +
      attributeGainsEnlightenment +
      attributeGainsAgility +
      attributeGainsFortune;

  /// 进度行创建时间(首次 getOrCreate 时记录)。
  late DateTime createdAt;
}

/// 按流派击杀计数 @embedded(C-W14-1)。
///
/// 用 `List[SchoolKillCount]` + MapLike extension 模拟 `Map[TechniqueSchool, int]`,
/// 沿用 [RewardEntry] / [SkillUsageEntry] 体例。
@embedded
class SchoolKillCount {
  @enumerated
  TechniqueSchool school = TechniqueSchool.gangMeng;
  int count = 0;
}

/// 按 biome 挂机累计分钟 @embedded(C-W14-2,同 [SchoolKillCount] 体例)。
@embedded
class BiomeMinutes {
  @enumerated
  EncounterBiome biome = EncounterBiome.mountainForest;
  int minutes = 0;
}

/// 按 weather 挂机累计分钟 @embedded(C-W14-2,同 [SchoolKillCount] 体例)。
@embedded
class WeatherMinutes {
  @enumerated
  EncounterWeather weather = EncounterWeather.clear;
  int minutes = 0;
}

/// 在 [List] of [SchoolKillCount] 上模拟 Map 语义。
///
/// **重要**:Isar findAll 反序列化 list 为 fixed-length(W13 教训
/// feedback_codex_pen_windows_visual_check.md / skill_usage_persist_test)。
/// caller 写入前必须 `List.of(progress.schoolKillCounts)` 转 growable,
/// 否则 [increment] 在新 school 出现时抛 UnsupportedError。
extension MapLikeOnSchoolKill on List<SchoolKillCount> {
  int countOf(TechniqueSchool school) {
    for (final e in this) {
      if (e.school == school) return e.count;
    }
    return 0;
  }

  /// 累计 +[delta](默认 +1)。caller 须先转 growable。
  void increment(TechniqueSchool school, [int delta = 1]) {
    for (final e in this) {
      if (e.school == school) {
        e.count += delta;
        return;
      }
    }
    add(SchoolKillCount()
      ..school = school
      ..count = delta);
  }
}

/// 同 [MapLikeOnSchoolKill] 体例,作用于 biome 分钟 list(C-W14-2)。
extension MapLikeOnBiomeMinutes on List<BiomeMinutes> {
  int minutesOf(EncounterBiome biome) {
    for (final e in this) {
      if (e.biome == biome) return e.minutes;
    }
    return 0;
  }

  void addMinutes(EncounterBiome biome, int delta) {
    if (delta <= 0) return;
    for (final e in this) {
      if (e.biome == biome) {
        e.minutes += delta;
        return;
      }
    }
    add(BiomeMinutes()
      ..biome = biome
      ..minutes = delta);
  }
}

/// 同 [MapLikeOnSchoolKill] 体例,作用于 weather 分钟 list(C-W14-2)。
extension MapLikeOnWeatherMinutes on List<WeatherMinutes> {
  int minutesOf(EncounterWeather weather) {
    for (final e in this) {
      if (e.weather == weather) return e.minutes;
    }
    return 0;
  }

  void addMinutes(EncounterWeather weather, int delta) {
    if (delta <= 0) return;
    for (final e in this) {
      if (e.weather == weather) {
        e.minutes += delta;
        return;
      }
    }
    add(WeatherMinutes()
      ..weather = weather
      ..minutes = delta);
  }
}
