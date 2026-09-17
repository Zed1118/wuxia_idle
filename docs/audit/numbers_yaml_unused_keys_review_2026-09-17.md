# numbers.yaml 零引用逐条复核（B2）

基线：`c64b165938d948a24ab64c7c71de950eea466758`。B2-1 已完成；B2-2 进行中。

复跑命令：`python3 tools/audit/numbers_key_usage.py --baseline c64b165938d948a24ab64c7c71de950eea466758`。

本次机器实测：`{'scalar_leaves': 1796, 'normalized_paths': 847, 'unique_terminals': 497, 'zero_normalized_paths': 87, 'zero_unique_terminals': 51, 'verdicts': {'生产消费': 234, '仅测试消费': 0, '零引用': 202, '疑似间接消费需人判': 1360}}`。

基线保护：`{'command': ['git', 'diff', '--quiet', 'c64b165938d948a24ab64c7c71de950eea466758', '--', 'lib'], 'exit_code': 0, 'tracked_paths_match': True, 'passed': True}`。

原表逐行集合重新计数：202 叶子 / 87 归一路径；新增 0，移出 0。没有新增守卫消费或失效排除理由。

## 十四组排除证据

### 元数据

NumbersConfig 只从 meta 取 version；未增加 meta 逐键守卫，其余未透传到字段。

`sed -n 346,346p lib/data/numbers_config.dart`；1 行；`lib/data/numbers_config.dart:346`。

```dart
    final meta = y['meta'] as Map<String, dynamic>;
```

`sed -n 353,353p lib/data/numbers_config.dart`；1 行；`lib/data/numbers_config.dart:353`。

```dart
      version: meta['version'] as String,
```

### 基础公式文档开关

DamageFormula 只按字段取两个系数，没有整表遍历或额外逐键守卫。

`sed -n 2429,2429p lib/data/numbers_config.dart`；1 行；`lib/data/numbers_config.dart:2429`。

```dart
  factory DamageFormula.fromYaml(Map<String, dynamic> y) {
```

### 最终公式文档开关

CombatNumbers 构造器逐段解析，没有 final_damage_formula 入口或该段逐键守卫。

`sed -n 1361,1361p lib/data/numbers_config.dart`；1 行；`lib/data/numbers_config.dart:1361`。

```dart
  factory CombatNumbers.fromYaml(Map<String, dynamic> y) {
```

### 装备阶模板

NumbersConfig 的 equipment 读取是强化、开锋、共鸣、遗物与处置；实装装备定义来自独立 equipment.yaml。

`sed -n 376,376p lib/data/numbers_config.dart`；1 行；`lib/data/numbers_config.dart:376`。

```dart
      enhancementBonusPerLevel:
```

`sed -n 220,220p lib/data/game_repository.dart`；1 行；`lib/data/game_repository.dart:220`。

```dart
    final equipmentRaw = parseYamlMap(await load('data/equipment.yaml'));
```

`sed -n 228,228p lib/data/game_repository.dart`；1 行；`lib/data/game_repository.dart:228`。

```dart
    final equipmentDefs = _parseDefMap(
```

### 强化公式文档

强化入口逐字段解析；success_curve 循环只取 level_range/success_rate/material_penalty，公式走 _fallbackFormula。

`sed -n 922,922p lib/data/numbers_config.dart`；1 行；`lib/data/numbers_config.dart:922`。

```dart
  factory EnhancementConfig.fromYaml({
```

`sed -n 995,995p lib/data/numbers_config.dart`；1 行；`lib/data/numbers_config.dart:995`。

```dart
  static double _fallbackFormula(int targetLevel) {
```

`sed -n 1000,1000p lib/data/numbers_config.dart`；1 行；`lib/data/numbers_config.dart:1000`。

```dart
  static List<EnhanceLevelBracket> _parseSuccessCurve(List raw) {
```

### 共鸣换主预留

共鸣只取 stages、inheritance_retention、seclusion_battle_count_per_hour；stages 新增缺值报错仍只校验显式读取字段。

`sed -n 404,404p lib/data/numbers_config.dart`；1 行；`lib/data/numbers_config.dart:404`。

```dart
      resonanceStages: _parseResonanceStages(
```

`sed -n 619,619p lib/data/numbers_config.dart`；1 行；`lib/data/numbers_config.dart:619`。

```dart
  static List<ResonanceStageConfig> _parseResonanceStages(
```

### 心法阶名称

tiers 遍历只取 tier 和 speed_bonus；不遍历行内所有 key/value。

`sed -n 553,553p lib/data/numbers_config.dart`；1 行；`lib/data/numbers_config.dart:553`。

```dart
  static Map<TechniqueTier, int> _parseTechniqueSpeedBonus(List tiers) {
```

### 招式参考倍率

NumbersConfig 无 skills 入口；实装 SkillDef 来自独立 skills.yaml。

`sed -n 345,345p lib/data/numbers_config.dart`；1 行；`lib/data/numbers_config.dart:345`。

```dart
  factory NumbersConfig.fromYaml(Map<String, dynamic> y) {
```

`sed -n 222,222p lib/data/game_repository.dart`；1 行；`lib/data/game_repository.dart:222`。

```dart
    final skillsRaw = parseYamlMap(await load('data/skills.yaml'));
```

`sed -n 238,238p lib/data/game_repository.dart`；1 行；`lib/data/game_repository.dart:238`。

```dart
    final skillDefs = _parseDefMap(
```

### 角色设计与事件范围

character 只取 lifetime_cap_per_character 和 rarity_distribution；新增缺值报错仅守卫前者，未整表或动态读取零命中字段。

`sed -n 492,492p lib/data/numbers_config.dart`；1 行；`lib/data/numbers_config.dart:492`。

```dart
      adventureAttributeLifetimeCap:
```

`sed -n 504,504p lib/data/numbers_config.dart`；1 行；`lib/data/numbers_config.dart:504`。

```dart
      rarityTiers: _parseRarityTiers(
```

### 时段文档锚

按 period 选行后只读 multiplier/target_attribute/applies_to_school；没有读取 time_range。

`sed -n 2847,2847p lib/data/numbers_config.dart`；1 行；`lib/data/numbers_config.dart:2847`。

```dart
  factory RetreatConfig.fromYaml(Map<String, dynamic> y) {
```

`sed -n 2912,2912p lib/data/numbers_config.dart`；1 行；`lib/data/numbers_config.dart:2912`。

```dart
      ziShiInternalForceMultiplier: (ziShi['multiplier'] as num).toDouble(),
```

### 旧塔配置段

NumbersConfig 无 tower 入口；实际楼层由独立 towers.yaml 读取，原始 Map 未被遍历消费。

`sed -n 345,345p lib/data/numbers_config.dart`；1 行；`lib/data/numbers_config.dart:345`。

```dart
  factory NumbersConfig.fromYaml(Map<String, dynamic> y) {
```

`sed -n 224,224p lib/data/game_repository.dart`；1 行；`lib/data/game_repository.dart:224`。

```dart
    final towersRaw = parseYamlMap(await load('data/towers.yaml'));
```

`sed -n 270,270p lib/data/game_repository.dart`；1 行；`lib/data/game_repository.dart:270`。

```dart
    final towerFloors =
```

### 传承预留字段

inheritance 只接祖师 buff 和 HeritageItems；后者仍逐个读取六个字段，缺值报错未扩展字段集合，没有通用 Map 遍历。

`sed -n 428,428p lib/data/numbers_config.dart`；1 行；`lib/data/numbers_config.dart:428`。

```dart
      founderAncestorBuff: FounderAncestorBuff.fromYaml(
```

`sed -n 807,807p lib/data/numbers_config.dart`；1 行；`lib/data/numbers_config.dart:807`。

```dart
  factory HeritageItems.fromYaml(Map<String, dynamic> y) {
```

### 旧相生数值段

NumbersConfig 无 synergies 入口；实际相生定义来自独立 synergies.yaml，原始 Map 未被遍历消费。

`sed -n 345,345p lib/data/numbers_config.dart`；1 行；`lib/data/numbers_config.dart:345`。

```dart
  factory NumbersConfig.fromYaml(Map<String, dynamic> y) {
```

`sed -n 373,373p lib/data/game_repository.dart`；1 行；`lib/data/game_repository.dart:373`。

```dart
      'data/synergies.yaml',
```

### 手工公式战例

NumbersConfig 无 validation_examples 解析入口；raw 仅持有数据不构成消费。

`sed -n 345,345p lib/data/numbers_config.dart`；1 行；`lib/data/numbers_config.dart:345`。

```dart
  factory NumbersConfig.fromYaml(Map<String, dynamic> y) {
```

`sed -n 540,540p lib/data/numbers_config.dart`；1 行；`lib/data/numbers_config.dart:540`。

```dart
      raw: y,
```
