// 战绩册 Boss 唯一键派生 — 纯函数，供回填（backfill）与胜利 hook 共享（保 DRY）。
//
// 主线 bossKey = stageId 原样。
// 爬塔 bossKey = 'tower_floor_<N>'。
//
// groupIndex 展示分组序号（排序用）：
//   - 主线 Ch1-6：对应 stageId 前缀 stage_01_ → stage_06_，解析章序号 1-6。
//   - 心魔（stageId 前缀 stage_inner_demon_）→ 7。
//   - 轻功（stageId 前缀 stage_light_foot_）→ 8。
//   - 群战（stageId 前缀 stage_mass_battle_）→ 9。
//   - 其他未识别前缀 → 99（兜底）。
//
// 爬塔 groupIndex = 层号（1-30）。

/// 主线 Boss 的稳定键（= stageId 原样）。
String mainlineBossKey(String stageId) => stageId;

/// 爬塔 Boss 的稳定键。
String towerBossKey(int floorIndex) => 'tower_floor_$floorIndex';

/// 主线 Boss 展示分组序号。
///
/// stageId 真实前缀（来自 `data/stages.yaml` 实读）：
///   - Ch1-6 主线：`stage_01_` / `stage_02_` / … / `stage_06_`
///   - 心魔：`stage_inner_demon_`
///   - 轻功：`stage_light_foot_`
///   - 群战：`stage_mass_battle_`
int mainlineGroupIndex(String stageId) {
  if (stageId.startsWith('stage_inner_demon_')) return 7;
  if (stageId.startsWith('stage_light_foot_')) return 8;
  if (stageId.startsWith('stage_mass_battle_')) return 9;
  // Ch1-6 格式：stage_0{ch}_{seq}，例如 stage_01_05、stage_06_04。
  // 取下划线分割第二段（'01'…'06'），转为数字。
  final parts = stageId.split('_');
  // 期望格式 ['stage', '01'…'06', '<seq>']，长度 >= 3
  if (parts.length >= 3) {
    final chNum = int.tryParse(parts[1]);
    if (chNum != null && chNum >= 1 && chNum <= 6) return chNum;
  }
  return 99; // 未识别前缀兜底
}
