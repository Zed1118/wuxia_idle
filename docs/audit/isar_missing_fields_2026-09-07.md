# Isar 旧档缺字段清查与 0.48.0 迁移

## 交付状态与边界

本单基于本地 main `adff44e5821d7ae651b2fba694a38c42ba080469`，B `6c162e4bd` 与 C `0d3a21833` 均为其祖先，开工版本 0.47.0 与 gauntletRunSerial 段已核验。原始交付位于独立分支 `codex/isar-missing-fields-048-20260907`，当时未合 main、未 push；后续本地 main 集成见文末记录。

已实现 62 个静态数值字段的精确哨兵归位，并为 72 条真实持久路径补缺字段、迁移、已有值及重开证据。不是所有不一致字段都已修复：10 个可疑数值默认与 5 个非数值歧义字段保持待决；140 个 late 无初始化器字段也不猜填。有关可疑默认值已通过本任务文字问题提交用户选择，目前按保守方案保留。

原始证据目录：`/Users/a10506/Documents/Codex/2026-09-07/isar-missing-fields-048/`。本报告是本任务唯一恢复与交付记录。

## 实测结果

使用 `@Name('原集合名')` 精简旧 schema 真正落盘，再以生产 schema 重开。没有用新 schema 手工赋哨兵来冒充缺字段证据。类型探针覆盖真实 Character、Equipment/Lore、EncounterProgress/BiomeMinutes、MainlineProgress、TowerProgress。数值逐字段证据另外使用全部 26 个同名旧集合与 11 个同名 embedded。

| Dart 类型/场景 | 缺字段实际读值 | 与用户假设对照 |
|---|---|---|
| 非空 int（本仓全部为 Isar long） | -9223372036854775808（minLong） | 证实；不是 Dart 初始化器 |
| 非空 double | NaN | 证实 |
| 非空 bool，初始化器 false 或 true | false | 证实缺失读 false；true 初始化器不生效 |
| 非空 String | 空串 | 证实；本仓没有非空 String 初始化器 |
| 非空 DateTime | 微秒时间戳 0，即 UTC 1970-01-01 | 补全未定项；不是最小日期、也不是 Lore 的 DateTime(2000) |
| nullable 字段 | null | int/String/enum/DateTime 已在真实 schema 读出验证；其余按同类生成读法核对 |
| @Enumerated(EnumType.name) | 首枚举项；Character.rarity 得 yongCai，不是 biaoZhun | 补全未定项 |
| @enumerated（ordinal） | 首枚举项；BiomeMinutes.biome 得 mountainPath，不是 mountainForest | 补充 |
| List<int>/List<String>/List<DateTime>/List<embedded> | [] | 补全未定项；覆盖本仓全部 List 元素类型 |
| 整个非空 embedded 属性缺失 | 新建该 embedded 默认对象；Attributes 四项为 5 | 与“已有对象内缺字段”不同，另有实际缺属性旧 schema 证据 |
| 已存在 embedded 对象内缺 int/double | minLong / NaN | 不能只处理 collection 的直接字段 |

DateTime、枚举和 bool 的 fallback 本身可能也是合法持久值，不具备 minLong/NaN 那样唯一的缺失识别能力。当前 Isar Community 3.3.2 没有 `Isar.minLong` 公共静态成员；代码使用经过实测的常量值，不依赖不存在的 API。

## 全量清查总数

| 分类 | 数量 | 处理 |
|---|---:|---|
| @collection | 26 | 全部与生产 IsarSetup 注册表核对 |
| @embedded | 11 | 全部遍历；不是原估计的 9 |
| 字段声明（含主键） | 390 | 下方逐项清单 |
| Id 主键 | 26 | 不做哨兵归位，避免触发 autoIncrement 或改身份 |
| 非 Id 字段 | 364 | 固定分母 |
| 清查判定汇总 | 62 归位 / 173 跳过 / 155 待决 | 跳过=26 Id+67 nullable+80 一致默认；待决=15 可疑默认+140 late |
| 有静态初始化器的非空 int/double | 72 | 62 归位，10 待决 |
| 无初始化器的非空 int | 46 | 不猜填 |
| 其他 late 无初始化器字段 | 94 | String 34、DateTime 31、enum 26、bool 2、Attributes 1 |
| nullable | 67 | null 与默认一致，跳过 |
| 其他非空初始化器 | 85 | 80 一致跳过，5 歧义待决 |
| 只读派生 getter（另列，不计字段声明） | 2 | Attributes.total、EncounterProgress.attributeGainsTotal；不向无 setter 属性赋值 |

因此非空数值总数是 118（72 有初始化器 + 46 late），并非约 75。未做字段引入版本的 Git 考古；源 AST 清查、真实 schema 和实测读取分别交叉验证。

## 0.48.0 生产路径及顺序

入口 `IsarSetup.init / switchSlot → _ensureSaveData → _migrateSaveData`，仍使用每槽独立的 `wuxia_save_slotN` 数据库。全段位于同一 writeTxn；只写被精确哨兵命中的行。不存在在线/离线分支，也没有跨槽查询。

- 保留迁移链末尾段 18，调用 `IsarMissingFieldDefaults.repairInTxn`，最终统一写 saveVersion。
- 增加 0.48 的前置依赖归位（只针对 Character 与 TowerProgress），再读取旧业务迁移缓存。否则 NaN 会在 0.36 比较中吞掉 6 小时旧内息时长，负周目会在 0.42 先生成错误 receipt；仅尾部修复来不及。
- 旧 0.36 在 internalForceMax 仍为 minLong 时保留既有内力；旧 0.39 在任一出生属性仍为 minLong 时保留既有资质，避免 deferred 字段继续污染合法字段。
- int 只检查 == minLong，double 只检查 isNaN；不使用 <0 或 !isFinite。合法值、有限负值、infinity、旧 seed、合法 false/首枚举项/epoch 均有保持证据。0.47 段原有的 gauntlet 负数策略按原版本门保留，本次不扩大它。
- 默认值直接从领域对象初始化器取得，没有复制新业务数值，没有改 YAML、装备基础表、三系锁死或战斗/奖励公式。

### 可疑默认值（本单不擅自归位）

| 字段 | 初始化器 | 原因 |
|---|---|---|
| SaveData.slotId | 1 | 不代表 slot 2/3 的实际身份；也不按目录反推。此字段缺失时，旧版本迁移可能按既有保护失败并回滚 |
| ActivityMemberSnapshot.characterId | 0 | 不能把未知参与者指向占位 ID |
| ForgingSlot.slotIndex | 1 | 多个未知槽位不能都认定为槽 1，也不按列表索引猜原槽号 |
| Character.internalForceMax | 500 | 是境界相关上限的占位值，不能冒充旧上限 |
| Technique.cultivationProgressToNext | 100 | 是活跃的升级阈值，不能擅自用当前层/配置重算 |
| Sect.memberCount | 0 | 有成员不代表人数可归 0；不跨表推算人数 |
| Attributes.constitution/enlightenment/agility/fortune | 各 5 | 不补造出生点数或历史加点事实 |

Character.experienceToNextLayer=100、level=1、levelExp=0 已明确是退役兼容镜像，本单只归静态默认，不让其重新参与生产成长决策。Equipment.base*=0、各进度/钱包=0 的归位也仅表示 schema 默认，绝不声称重建原数值或历史局数。

### 不具备可靠缺失识别能力的 5 个字段

Character.isAlive（true/false）、Lore.isPreset（true/false）、Lore.addedAt（2000/epoch）、Character.rarity（biaoZhun/首项）、BiomeMinutes.biome（mountainForest/首项）均保持原值。生产确实存在 isAlive=false 和 isPreset=false；批量改 true 会改变死亡/延续典故事实。枚举首项和 epoch 也可能是真实值，不能按 fallback 反推字段是否曾存在。

140 个 late 字段没有可归的初始化器；完整清单逐项标为待决。它们包含身份、外键、旧 seed、战绩、时间和状态，不用缺失读取值冒充合法默认。整块 embedded 缺失后 Isar 已构造默认值的情形，也无法仅靠当前值重建原对象。

## 防复发守卫

已实现 `test/data/isar_missing_field_coverage_test.dart`：

1. 从真实生产注册的全部 collection/embedded schemas 出发，与 AST 清单逐属性对齐，防漏集合、漏 embedded 或漏字段。
2. 所有非空 numeric 必须进入修复清单或带理由的明确 deferred 清单；新增数值字段会红，不能自动归入“未覆盖但跳过”。存储位宽改变也要求重新实测。
3. 修复字段必须有真实旧库证据；所有嵌套根路径也逐一对齐，新增已有 embedded 的宿主不会静默漏测。
4. bool=true、日期占位、非首项枚举等不一致初始化器必须进入明确歧义清单。

实际变异新增 `SaveData.missingFieldCoverageProbe = 0` 并重新运行 build_runner 后，守卫拒绝未登记字段；恢复源码与生成 schema 后通过。不是只扫描一个手写清单后断言自身存在。

## expeditionRunSerial 的实际影响复核

minLong + 1 = -9223372036854775807，是负值上的正常加一，不是这一步发生整数回绕。Dart Random 接受负种子。生产 `ExpeditionSeed.forNode` 只混入序号低 32 位，minLong+k 与 k 产生相同节点种子；不同 k 的随机流仍变化。因此旧问题潜伏，但不应把已有负序号重新归 0 或改旧 ExpeditionRun.seed。本单仅修仍等于精确 minLong 的 SaveData.expeditionRunSerial，已有 minLong+1 与旧会话 seed 已验证保持。

## 验证与变异

以下均为本候选当前源码的真实执行记录；源文件哈希见证据目录 `validated-source-hashes.json`，提交完成后再次对照。最终运行没有更换依赖版本或设置 DEVELOPER_DIR。独立 probe 子包先执行 `dart pub get --enforce-lockfile`，以支持整个 cwd 的 analyze。生成文件按仓库规则忽略，不提交 `.g.dart`。

| 命令 | 真实输出节选/核对 | 原始日志 |
|---|---|---|
| `dart run build_runner build --delete-conflicting-outputs` | `Built with build_runner/aot in 0s; wrote 0 outputs.` | [build-runner-final.log](/Users/a10506/Documents/Codex/2026-09-07/isar-missing-fields-048/build-runner-final.log) |
| `flutter analyze` | `No issues found! (ran in 3.4s)` | [analyze-final.log](/Users/a10506/Documents/Codex/2026-09-07/isar-missing-fields-048/analyze-final.log) |
| `flutter test --machine` | `6285 PASS / 0 FAIL / 0 SKIP；实际加载 899/899 文件，缺漏 0` | [full-test.log](/Users/a10506/Documents/Codex/2026-09-07/isar-missing-fields-048/full-test.log) |
| `dart format .` | `Formatted 1771 files (0 changed) in 3.49 seconds.` | [format-final-check.log](/Users/a10506/Documents/Codex/2026-09-07/isar-missing-fields-048/format-final-check.log) |
| `flutter build macos` | `✓ Built build/macos/Build/Products/Release/wuxia_idle.app (177.3MB)` | [macos-build.log](/Users/a10506/Documents/Codex/2026-09-07/isar-missing-fields-048/macos-build.log) |

macOS 构建退出 0；audioplayers_darwin 等依赖的 Swift 编译警告保留在原始日志中，本单未修改依赖。

build_runner 的 0 outputs 是最终增量核验结果；本单新增旧 schema 已在前序 `build-types.log` / `build-numeric.log` / `build-boundaries.log` 和守卫变异重建中实际生成。format 首次执行修改了本单两个新测试文件，最终整目录 1771 文件为 0 改动。

首轮全量同样加载了 899/899 文件，结果 6284 PASS / 1 FAIL。失败来自既有 `experience_threshold_production_usage_contract_test`：它的全仓文本扫描将 0.48 对退役兼容镜像的静态哨兵归位误判为业务阈值消费。本次仅将该迁移文件加入已有允许路径并解释用途，其余全仓禁读检查保留；守卫恢复 1/1，另补跑实际成长服务 24/24，确认升级仍消费 RealmDef。生产源码没有因此改变。首轮失败原文与汇总保存在 `first-full-test.log` / `first-full-test-summary.json`，没有覆盖失败历史。

最终全量在项目共享锁 `/Users/a10506/.claude/locks/wuxia_full_test.lock` 内执行，从文件系统枚举 `test/**/*_test.dart`，与机器 reporter 的 suite 路径逐项对照；不是只相信最终退出码。机器 reporter 的原始结束事件：

```json
{"success":true,"type":"done","time":418867}
```

另对全部 13 个新增/受影响测试文件逐文件运行，合计 115/115。其中 72 条真实持久路径均先证 absent property → 原始哨兵，再证 0.48 默认值，最后写入非默认合法值并降版本迁移、重复重开，确认不覆盖。7 条跨旧版本/原子回滚/多槽隔离/既有数值及 seed 边界全部通过；2 条类型探针、4 条守卫全部通过。完整文件路径列表与计数见 `full-test-summary.json` 和各 `target-*-summary.json`。

### 变异原始结果

临时只禁用末尾 0.48 段中的归位调用，运行 expeditionRunSerial 单条证据：

```text
  Expected: every element(<0>)
    Actual: [-9223372036854775808]
00:00 +0 -1: Some tests failed.
```

退出 1；恢复源码同条测试 `+1: All tests passed!`，退出 0。精确原文及 reporter 时间见 [禁用日志](/Users/a10506/Documents/Codex/2026-09-07/isar-missing-fields-048/segment-048-mutation-red.log) / [恢复日志](/Users/a10506/Documents/Codex/2026-09-07/isar-missing-fields-048/segment-048-mutation-restored.log)，时间展示以上方原始日志为准。

额外禁用旧段前置归位：旧 0.35 的 6 小时时长测试 Expected 6、Actual 0.0，退出 1；恢复后 +1 通过、退出 0。日志：`legacy-prerepair-mutation-red.log` / `legacy-prerepair-mutation-restored.log`。

防复发实变异：给真实 SaveData 加 `int missingFieldCoverageProbe = 0;`，重新生成 schema 后守卫显示 `Actual: Set:['SaveData.missingFieldCoverageProbe']`，退出 1；删除临时字段、重新生成并核对生成文件哈希后，守卫 4/4 通过、退出 0。对应 `guard-mutation-final-red.log` / `guard-restored-green.log` / `guard-mutation-final-results.json`。最初一轮守卫已经证红，但外部包装脚本因 matcher 文本截断未找到字段名而退出；完善诊断后重新取得明确字段名及完整红绿记录，旧日志保留。

### 独立复核与交付边界

独立数值复核最终记录位于 `numeric-review.md` 第 5 节，对上述生产两文件当前 SHA256 静态复核无剩余阻断项；非数值清查见 `nonnumeric-review.md`。独立静态复核没有冒充动态测试，旧建议与最终采用方案已分开注明。

D 单原始交付时只提交独立候选，未合 main / push / 跑远端 CI，不代签真人或 Windows 验收，M0–M9 仍按既有 1/10。AGENTS.md、CLAUDE.md、data/*.yaml 均无本单修改；主仓四个既有用户文件逐一 SHA256 对照未变。15 个可疑初始化器字段与 140 个 late 无默认字段仍明确待决，不将本次自动化通过写成“全部旧档语义恢复”。

## 逐字段清单

以下清单由 AST 与实际注册 schemas 交叉核对。数值归位项附实际赋值位置；类型规则实测不等于每个无初始化器字段都有业务默认。

### Attributes（embedded）

源文件：`lib/core/domain/attributes.dart`

| 字段 | 类型 | Dart 初始化器 | 判定 | 归位位置 |
|---|---|---|---|---|
| `constitution` :11 | `int` | `5` | 待决：身份/阈值/出生属性占位 | — |
| `enlightenment` :12 | `int` | `5` | 待决：身份/阈值/出生属性占位 | — |
| `agility` :13 | `int` | `5` | 待决：身份/阈值/出生属性占位 | — |
| `fortune` :14 | `int` | `5` | 待决：身份/阈值/出生属性占位 | — |
| `total` :16 | 只读 getter | 从成员计算 | 跳过：无 setter，不计字段分母 | — |

### Character（collection）

源文件：`lib/core/domain/character.dart`

| 字段 | 类型 | Dart 初始化器 | 判定 | 归位位置 |
|---|---|---|---|---|
| `id` :14 | `Id` | `Isar.autoIncrement` | 跳过：主键，不是缺字段业务计数器 | — |
| `name` :16 | `String` | `无（late）` | 待决：无初始化器，不把 fallback 当语义默认 | — |
| `realmTier` :19 | `RealmTier` | `无（late）` | 待决：无初始化器，不把 fallback 当语义默认 | — |
| `realmLayer` :22 | `RealmLayer` | `无（late）` | 待决：无初始化器，不把 fallback 当语义默认 | — |
| `internalForce` :24 | `int` | `0` | 归位：仅精确 minLong / NaN → 初始化器 | `lib/data/isar_missing_field_defaults.dart:282` |
| `internalForceMax` :25 | `int` | `500` | 待决：身份/阈值/出生属性占位 | — |
| `innerBreathDisorderHoursRemaining` :29 | `double` | `0` | 归位：仅精确 minLong / NaN → 初始化器 | `lib/data/isar_missing_field_defaults.dart:286` |
| `innerDemonResidueHoursRemaining` :33 | `double` | `0` | 归位：仅精确 minLong / NaN → 初始化器 | `lib/data/isar_missing_field_defaults.dart:291` |
| `lightInjuryStacks` :36 | `int` | `0` | 归位：仅精确 minLong / NaN → 初始化器 | `lib/data/isar_missing_field_defaults.dart:296` |
| `injuryHoursRemaining` :40 | `double` | `0` | 归位：仅精确 minLong / NaN → 初始化器 | `lib/data/isar_missing_field_defaults.dart:300` |
| `experience` :42 | `int` | `0` | 归位：仅精确 minLong / NaN → 初始化器 | `lib/data/isar_missing_field_defaults.dart:304` |
| `experienceToNextLayer` :47 | `int` | `100` | 归位：仅精确 minLong / NaN → 初始化器 | `lib/data/isar_missing_field_defaults.dart:308` |
| `level` :52 | `int` | `1` | 归位：仅精确 minLong / NaN → 初始化器 | `lib/data/isar_missing_field_defaults.dart:312` |
| `levelExp` :53 | `int` | `0` | 归位：仅精确 minLong / NaN → 初始化器 | `lib/data/isar_missing_field_defaults.dart:316` |
| `insightPoints` :59 | `int` | `0` | 归位：仅精确 minLong / NaN → 初始化器 | `lib/data/isar_missing_field_defaults.dart:320` |
| `attributes` :61 | `Attributes` | `无（late）` | 待决：无初始化器，不把 fallback 当语义默认 | — |
| `rarity` :84 | `RarityTier` | `RarityTier.biaoZhun` | 待决：缺失 fallback 与合法值重合 | — |
| `school` :87 | `TechniqueSchool?` | `隐式 null` | 跳过：缺失 null 与 Dart 默认一致 | — |
| `mainTechniqueId` :89 | `int?` | `隐式 null` | 跳过：缺失 null 与 Dart 默认一致 | — |
| `assistTechniqueIds` :90 | `List<int>` | `[]` | 跳过：实测类型规则下缺失值与初始化器一致 | — |
| `equippedWeaponId` :92 | `int?` | `隐式 null` | 跳过：缺失 null 与 Dart 默认一致 | — |
| `equippedArmorId` :93 | `int?` | `隐式 null` | 跳过：缺失 null 与 Dart 默认一致 | — |
| `equippedAccessoryId` :94 | `int?` | `隐式 null` | 跳过：缺失 null 与 Dart 默认一致 | — |
| `learnedSkillIds` :96 | `List<String>` | `[]` | 跳过：实测类型规则下缺失值与初始化器一致 | — |
| `mainSkillId1` :101 | `String?` | `隐式 null` | 跳过：缺失 null 与 Dart 默认一致 | — |
| `mainSkillId2` :102 | `String?` | `隐式 null` | 跳过：缺失 null 与 Dart 默认一致 | — |
| `assistSkillId` :103 | `String?` | `隐式 null` | 跳过：缺失 null 与 Dart 默认一致 | — |
| `resonanceSkillId` :104 | `String?` | `隐式 null` | 跳过：缺失 null 与 Dart 默认一致 | — |
| `ultimateSkillId` :105 | `String?` | `隐式 null` | 跳过：缺失 null 与 Dart 默认一致 | — |
| `keySkillId` :110 | `String?` | `隐式 null` | 跳过：缺失 null 与 Dart 默认一致 | — |
| `equippedEncounterSkillId` :118 | `String?` | `隐式 null` | 跳过：缺失 null 与 Dart 默认一致 | — |
| `isActive` :121 | `bool` | `false` | 跳过：实测类型规则下缺失值与初始化器一致 | — |
| `isInRetreat` :123 | `bool` | `false` | 跳过：实测类型规则下缺失值与初始化器一致 | — |
| `currentRetreatSessionId` :124 | `int?` | `隐式 null` | 跳过：缺失 null 与 Dart 默认一致 | — |
| `masterId` :126 | `int?` | `隐式 null` | 跳过：缺失 null 与 Dart 默认一致 | — |
| `discipleIds` :127 | `List<int>` | `[]` | 跳过：实测类型规则下缺失值与初始化器一致 | — |
| `lineageRole` :130 | `LineageRole` | `无（late）` | 待决：无初始化器，不把 fallback 当语义默认 | — |
| `isFounder` :132 | `bool` | `false` | 跳过：实测类型规则下缺失值与初始化器一致 | — |
| `isAlive` :133 | `bool` | `true` | 待决：缺失 fallback 与合法值重合 | — |
| `birthInGameYear` :134 | `int` | `0` | 归位：仅精确 minLong / NaN → 初始化器 | `lib/data/isar_missing_field_defaults.dart:324` |
| `attributeBonusFromAdventure` :139 | `int` | `0` | 归位：仅精确 minLong / NaN → 初始化器 | `lib/data/isar_missing_field_defaults.dart:328` |
| `isInSect` :146 | `bool` | `false` | 跳过：实测类型规则下缺失值与初始化器一致 | — |
| `sectId` :149 | `int?` | `隐式 null` | 跳过：缺失 null 与 Dart 默认一致 | — |
| `sectRank` :155 | `SectRank?` | `隐式 null` | 跳过：缺失 null 与 Dart 默认一致 | — |
| `portraitPath` :160 | `String?` | `隐式 null` | 跳过：缺失 null 与 Dart 默认一致 | — |
| `founderCreationSchoolId` :164 | `String?` | `隐式 null` | 跳过：缺失 null 与 Dart 默认一致 | — |
| `founderCreationOriginId` :165 | `String?` | `隐式 null` | 跳过：缺失 null 与 Dart 默认一致 | — |
| `founderCreationFateId` :166 | `String?` | `隐式 null` | 跳过：缺失 null 与 Dart 默认一致 | — |
| `createdAt` :168 | `DateTime` | `无（late）` | 待决：无初始化器，不把 fallback 当语义默认 | — |

### Equipment（collection）

源文件：`lib/core/domain/equipment.dart`

| 字段 | 类型 | Dart 初始化器 | 判定 | 归位位置 |
|---|---|---|---|---|
| `id` :16 | `Id` | `Isar.autoIncrement` | 跳过：主键，不是缺字段业务计数器 | — |
| `defId` :19 | `String` | `无（late）` | 待决：无初始化器，不把 fallback 当语义默认 | — |
| `customName` :21 | `String?` | `隐式 null` | 跳过：缺失 null 与 Dart 默认一致 | — |
| `tier` :24 | `EquipmentTier` | `无（late）` | 待决：无初始化器，不把 fallback 当语义默认 | — |
| `slot` :27 | `EquipmentSlot` | `无（late）` | 待决：无初始化器，不把 fallback 当语义默认 | — |
| `school` :30 | `TechniqueSchool?` | `隐式 null` | 跳过：缺失 null 与 Dart 默认一致 | — |
| `baseAttack` :32 | `int` | `0` | 归位：仅精确 minLong / NaN → 初始化器 | `lib/data/isar_missing_field_defaults.dart:338` |
| `baseHealth` :33 | `int` | `0` | 归位：仅精确 minLong / NaN → 初始化器 | `lib/data/isar_missing_field_defaults.dart:342` |
| `baseSpeed` :34 | `int` | `0` | 归位：仅精确 minLong / NaN → 初始化器 | `lib/data/isar_missing_field_defaults.dart:346` |
| `enhanceLevel` :36 | `int` | `0` | 归位：仅精确 minLong / NaN → 初始化器 | `lib/data/isar_missing_field_defaults.dart:350` |
| `ownerCharacterId` :39 | `int?` | `隐式 null` | 跳过：缺失 null 与 Dart 默认一致 | — |
| `isLineageHeritage` :41 | `bool` | `false` | 跳过：实测类型规则下缺失值与初始化器一致 | — |
| `isLocked` :42 | `bool` | `false` | 跳过：实测类型规则下缺失值与初始化器一致 | — |
| `previousOwnerCharacterIds` :43 | `List<int>` | `[]` | 跳过：实测类型规则下缺失值与初始化器一致 | — |
| `battleCount` :45 | `int` | `0` | 归位：仅精确 minLong / NaN → 初始化器 | `lib/data/isar_missing_field_defaults.dart:354` |
| `forgingSlots` :48 | `List<ForgingSlot>` | `[]` | 跳过：实测类型规则下缺失值与初始化器一致 | — |
| `lores` :49 | `List<Lore>` | `[]` | 跳过：实测类型规则下缺失值与初始化器一致 | — |
| `obtainedAt` :51 | `DateTime` | `无（late）` | 待决：无初始化器，不把 fallback 当语义默认 | — |
| `obtainedFrom` :52 | `String` | `无（late）` | 待决：无初始化器，不把 fallback 当语义默认 | — |

### ForgingSlot（embedded）

源文件：`lib/core/domain/forging_slot.dart`

| 字段 | 类型 | Dart 初始化器 | 判定 | 归位位置 |
|---|---|---|---|---|
| `slotIndex` :13 | `int` | `1` | 待决：身份/阈值/出生属性占位 | — |
| `type` :16 | `ForgingSlotType?` | `隐式 null` | 跳过：缺失 null 与 Dart 默认一致 | — |
| `unlocked` :18 | `bool` | `false` | 跳过：实测类型规则下缺失值与初始化器一致 | — |
| `bonusValue` :19 | `int` | `0` | 归位：仅精确 minLong / NaN → 初始化器 | `lib/data/isar_missing_field_defaults.dart:367` |
| `specialSkillId` :20 | `String?` | `隐式 null` | 跳过：缺失 null 与 Dart 默认一致 | — |

### GameEvent（collection）

源文件：`lib/core/domain/game_event.dart`

| 字段 | 类型 | Dart 初始化器 | 判定 | 归位位置 |
|---|---|---|---|---|
| `id` :12 | `Id` | `Isar.autoIncrement` | 跳过：主键，不是缺字段业务计数器 | — |
| `eventType` :15 | `GameEventType` | `无（late）` | 待决：无初始化器，不把 fallback 当语义默认 | — |
| `title` :17 | `String` | `无（late）` | 待决：无初始化器，不把 fallback 当语义默认 | — |
| `summary` :18 | `String` | `无（late）` | 待决：无初始化器，不把 fallback 当语义默认 | — |
| `relatedCharacterId` :20 | `int?` | `隐式 null` | 跳过：缺失 null 与 Dart 默认一致 | — |
| `relatedEntityIds` :21 | `List<String>` | `[]` | 跳过：实测类型规则下缺失值与初始化器一致 | — |
| `occurredAt` :24 | `DateTime` | `无（late）` | 待决：无初始化器，不把 fallback 当语义默认 | — |
| `isRead` :27 | `bool` | `false` | 跳过：实测类型规则下缺失值与初始化器一致 | — |

### InventoryItem（collection）

源文件：`lib/core/domain/inventory_item.dart`

| 字段 | 类型 | Dart 初始化器 | 判定 | 归位位置 |
|---|---|---|---|---|
| `id` :13 | `Id` | `Isar.autoIncrement` | 跳过：主键，不是缺字段业务计数器 | — |
| `defId` :16 | `String` | `无（late）` | 待决：无初始化器，不把 fallback 当语义默认 | — |
| `itemType` :19 | `ItemType` | `无（late）` | 待决：无初始化器，不把 fallback 当语义默认 | — |
| `quantity` :21 | `int` | `0` | 归位：仅精确 minLong / NaN → 初始化器 | `lib/data/isar_missing_field_defaults.dart:377` |
| `firstObtainedAt` :23 | `DateTime` | `无（late）` | 待决：无初始化器，不把 fallback 当语义默认 | — |
| `lastObtainedAt` :24 | `DateTime` | `无（late）` | 待决：无初始化器，不把 fallback 当语义默认 | — |

### IslandBuildingState（embedded）

源文件：`lib/core/domain/island_building_state.dart`

| 字段 | 类型 | Dart 初始化器 | 判定 | 归位位置 |
|---|---|---|---|---|
| `type` :15 | `BuildingType` | `BuildingType.tieJiangChang` | 跳过：实测类型规则下缺失值与初始化器一致 | — |
| `level` :17 | `int` | `1` | 归位：仅精确 minLong / NaN → 初始化器 | `lib/data/isar_missing_field_defaults.dart:387` |
| `stored` :22 | `double` | `0` | 归位：仅精确 minLong / NaN → 初始化器 | `lib/data/isar_missing_field_defaults.dart:391` |
| `activeRecipeId` :25 | `String?` | `隐式 null` | 跳过：缺失 null 与 Dart 默认一致 | — |

### Lore（embedded）

源文件：`lib/core/domain/lore.dart`

| 字段 | 类型 | Dart 初始化器 | 判定 | 归位位置 |
|---|---|---|---|---|
| `text` :12 | `String` | `''` | 跳过：实测类型规则下缺失值与初始化器一致 | — |
| `isPreset` :13 | `bool` | `true` | 待决：缺失 fallback 与合法值重合 | — |
| `addedAt` :14 | `DateTime` | `DateTime(2000)` | 待决：缺失 fallback 与合法值重合 | — |
| `triggerEventDesc` :15 | `String?` | `隐式 null` | 跳过：缺失 null 与 Dart 默认一致 | — |

### RewardEntry（embedded）

源文件：`lib/core/domain/reward_entry.dart`

| 字段 | 类型 | Dart 初始化器 | 判定 | 归位位置 |
|---|---|---|---|---|
| `rewardKey` :11 | `String` | `''` | 跳过：实测类型规则下缺失值与初始化器一致 | — |
| `quantity` :12 | `int` | `0` | 归位：仅精确 minLong / NaN → 初始化器 | `lib/data/isar_missing_field_defaults.dart:401` |

### SaveData（collection）

源文件：`lib/core/domain/save_data.dart`

| 字段 | 类型 | Dart 初始化器 | 判定 | 归位位置 |
|---|---|---|---|---|
| `id` :16 | `Id` | `0` | 跳过：主键，不是缺字段业务计数器 | — |
| `slotId` :20 | `int` | `1` | 待决：身份/阈值/出生属性占位 | — |
| `slotName` :23 | `String?` | `隐式 null` | 跳过：缺失 null 与 Dart 默认一致 | — |
| `saveVersion` :26 | `String` | `无（late）` | 待决：无初始化器，不把 fallback 当语义默认 | — |
| `createdAt` :28 | `DateTime` | `无（late）` | 待决：无初始化器，不把 fallback 当语义默认 | — |
| `lastSavedAt` :29 | `DateTime` | `无（late）` | 待决：无初始化器，不把 fallback 当语义默认 | — |
| `lastOnlineAt` :32 | `DateTime` | `无（late）` | 待决：无初始化器，不把 fallback 当语义默认 | — |
| `sectName` :36 | `String?` | `隐式 null` | 跳过：缺失 null 与 Dart 默认一致 | — |
| `founderCharacterId` :37 | `int?` | `隐式 null` | 跳过：缺失 null 与 Dart 默认一致 | — |
| `activeCharacterIds` :40 | `List<int>` | `[]` | 跳过：实测类型规则下缺失值与初始化器一致 | — |
| `totalPlaySeconds` :44 | `int` | `0` | 归位：仅精确 minLong / NaN → 初始化器 | `lib/data/isar_missing_field_defaults.dart:411` |
| `isOnboardingCompleted` :45 | `bool` | `false` | 跳过：实测类型规则下缺失值与初始化器一致 | — |
| `highestTowerLayer` :46 | `int` | `0` | 归位：仅精确 minLong / NaN → 初始化器 | `lib/data/isar_missing_field_defaults.dart:415` |
| `towerLeaderboardSyncedAt` :48 | `DateTime?` | `隐式 null` | 跳过：缺失 null 与 Dart 默认一致 | — |
| `tutorialStep` :52 | `int` | `0` | 归位：仅精确 minLong / NaN → 初始化器 | `lib/data/isar_missing_field_defaults.dart:419` |
| `tutorialHintsRead` :57 | `List<int>` | `[]` | 跳过：实测类型规则下缺失值与初始化器一致 | — |
| `recruitmentOffered` :64 | `bool` | `false` | 跳过：实测类型规则下缺失值与初始化器一致 | — |
| `recruitedDiscipleIds` :72 | `List<int>` | `[]` | 跳过：实测类型规则下缺失值与初始化器一致 | — |
| `triggeredBossRecruitStageIds` :79 | `List<String>` | `[]` | 跳过：实测类型规则下缺失值与初始化器一致 | — |
| `triggeredDiscipleJoinStageIds` :86 | `List<String>` | `[]` | 跳过：实测类型规则下缺失值与初始化器一致 | — |
| `grantedMilestoneEquipmentIds` :92 | `List<String>` | `[]` | 跳过：实测类型规则下缺失值与初始化器一致 | — |
| `skillUnlockProgress` :97 | `List<SkillUnlockEntry>` | `[]` | 跳过：实测类型规则下缺失值与初始化器一致 | — |
| `totalPassiveMojianshi` :100 | `int` | `0` | 归位：仅精确 minLong / NaN → 初始化器 | `lib/data/isar_missing_field_defaults.dart:423` |
| `totalPassiveExperience` :101 | `int` | `0` | 归位：仅精确 minLong / NaN → 初始化器 | `lib/data/isar_missing_field_defaults.dart:427` |
| `islandBuildings` :105 | `List<IslandBuildingState>` | `[]` | 跳过：实测类型规则下缺失值与初始化器一致 | — |
| `islandLastSettledAt` :109 | `DateTime?` | `隐式 null` | 跳过：缺失 null 与 Dart 默认一致 | — |
| `sweepReadinessPoints` :112 | `int?` | `隐式 null` | 跳过：缺失 null 与 Dart 默认一致 | — |
| `sweepReadinessLastRecoveredAt` :115 | `DateTime?` | `隐式 null` | 跳过：缺失 null 与 Dart 默认一致 | — |
| `jianghuJourneyUnlocked` :120 | `bool` | `false` | 跳过：实测类型规则下缺失值与初始化器一致 | — |
| `baicaoMaxDepth` :123 | `int` | `0` | 归位：仅精确 minLong / NaN → 初始化器 | `lib/data/isar_missing_field_defaults.dart:431` |
| `expeditionRunSerial` :126 | `int` | `0` | 归位：仅精确 minLong / NaN → 初始化器 | `lib/data/isar_missing_field_defaults.dart:435` |
| `gauntletRunSerial` :129 | `int` | `0` | 归位：仅精确 minLong / NaN → 初始化器 | `lib/data/isar_missing_field_defaults.dart:439` |
| `clearedGauntletIds` :132 | `List<String>` | `[]` | 跳过：实测类型规则下缺失值与初始化器一致 | — |
| `duanhunFirstClearedAt` :135 | `DateTime?` | `隐式 null` | 跳过：缺失 null 与 Dart 默认一致 | — |
| `duanhunClearedCyclesMax` :141 | `int` | `0` | 归位：仅精确 minLong / NaN → 初始化器 | `lib/data/isar_missing_field_defaults.dart:443` |
| `grantedTicketMilestoneIds` :150 | `List<String>` | `[]` | 跳过：实测类型规则下缺失值与初始化器一致 | — |

### SkillUnlockEntry（embedded）

源文件：`lib/core/domain/skill_unlock_entry.dart`

| 字段 | 类型 | Dart 初始化器 | 判定 | 归位位置 |
|---|---|---|---|---|
| `skillId` :12 | `String` | `''` | 跳过：实测类型规则下缺失值与初始化器一致 | — |
| `fragmentCount` :13 | `int` | `0` | 归位：仅精确 minLong / NaN → 初始化器 | `lib/data/isar_missing_field_defaults.dart:459` |
| `unlocked` :14 | `bool` | `false` | 跳过：实测类型规则下缺失值与初始化器一致 | — |

### SkillUsageEntry（embedded）

源文件：`lib/core/domain/skill_usage_entry.dart`

| 字段 | 类型 | Dart 初始化器 | 判定 | 归位位置 |
|---|---|---|---|---|
| `skillId` :11 | `String` | `''` | 跳过：实测类型规则下缺失值与初始化器一致 | — |
| `count` :12 | `int` | `0` | 归位：仅精确 minLong / NaN → 初始化器 | `lib/data/isar_missing_field_defaults.dart:469` |

### Technique（collection）

源文件：`lib/core/domain/technique.dart`

| 字段 | 类型 | Dart 初始化器 | 判定 | 归位位置 |
|---|---|---|---|---|
| `id` :15 | `Id` | `Isar.autoIncrement` | 跳过：主键，不是缺字段业务计数器 | — |
| `defId` :18 | `String` | `无（late）` | 待决：无初始化器，不把 fallback 当语义默认 | — |
| `ownerCharacterId` :21 | `int` | `无（late）` | 待决：无初始化器，不猜历史值 | — |
| `tier` :24 | `TechniqueTier` | `无（late）` | 待决：无初始化器，不把 fallback 当语义默认 | — |
| `school` :27 | `TechniqueSchool` | `无（late）` | 待决：无初始化器，不把 fallback 当语义默认 | — |
| `cultivationLayer` :30 | `CultivationLayer` | `CultivationLayer.chuKui` | 跳过：实测类型规则下缺失值与初始化器一致 | — |
| `cultivationProgress` :32 | `int` | `0` | 归位：仅精确 minLong / NaN → 初始化器 | `lib/data/isar_missing_field_defaults.dart:479` |
| `cultivationProgressToNext` :33 | `int` | `100` | 待决：身份/阈值/出生属性占位 | — |
| `skillUsageCount` :35 | `List<SkillUsageEntry>` | `[]` | 跳过：实测类型规则下缺失值与初始化器一致 | — |
| `role` :38 | `TechniqueRole` | `无（late）` | 待决：无初始化器，不把 fallback 当语义默认 | — |
| `wasMainBeforeReset` :40 | `bool` | `false` | 跳过：实测类型规则下缺失值与初始化器一致 | — |
| `learnedAt` :41 | `DateTime` | `无（late）` | 待决：无初始化器，不把 fallback 当语义默认 | — |

### ActivityMemberSnapshot（embedded）

源文件：`lib/features/activity/domain/activity_member_snapshot.dart`

| 字段 | 类型 | Dart 初始化器 | 判定 | 归位位置 |
|---|---|---|---|---|
| `characterId` :12 | `int` | `0` | 待决：身份/阈值/出生属性占位 | — |
| `reservedEquipmentIds` :15 | `List<int>` | `[]` | 跳过：实测类型规则下缺失值与初始化器一致 | — |
| `reservedTechniqueIds` :18 | `List<int>` | `[]` | 跳过：实测类型规则下缺失值与初始化器一致 | — |
| `currentHp` :20 | `int` | `0` | 归位：仅精确 minLong / NaN → 初始化器 | `lib/data/isar_missing_field_defaults.dart:492` |
| `currentQi` :21 | `int` | `0` | 归位：仅精确 minLong / NaN → 初始化器 | `lib/data/isar_missing_field_defaults.dart:496` |
| `isDowned` :22 | `bool` | `false` | 跳过：实测类型规则下缺失值与初始化器一致 | — |
| `maxHp` :27 | `int` | `0` | 归位：仅精确 minLong / NaN → 初始化器 | `lib/data/isar_missing_field_defaults.dart:500` |
| `maxQi` :28 | `int` | `0` | 归位：仅精确 minLong / NaN → 初始化器 | `lib/data/isar_missing_field_defaults.dart:504` |
| `skillCooldownKeys` :33 | `List<String>` | `[]` | 跳过：实测类型规则下缺失值与初始化器一致 | — |
| `skillCooldownTurns` :36 | `List<int>` | `[]` | 跳过：实测类型规则下缺失值与初始化器一致 | — |

### DurableActivityCombatRun（collection）

源文件：`lib/features/activity/domain/durable_activity_combat_run.dart`

| 字段 | 类型 | Dart 初始化器 | 判定 | 归位位置 |
|---|---|---|---|---|
| `id` :26 | `Id` | `Isar.autoIncrement` | 跳过：主键，不是缺字段业务计数器 | — |
| `saveDataId` :29 | `int` | `无（late）` | 待决：无初始化器，不猜历史值 | — |
| `kind` :32 | `DurableActivityKind` | `无（late）` | 待决：无初始化器，不把 fallback 当语义默认 | — |
| `contentId` :34 | `String` | `无（late）` | 待决：无初始化器，不把 fallback 当语义默认 | — |
| `loadoutPlanId` :35 | `String` | `无（late）` | 待决：无初始化器，不把 fallback 当语义默认 | — |
| `stageId` :36 | `String` | `无（late）` | 待决：无初始化器，不把 fallback 当语义默认 | — |
| `cycleIndex` :37 | `int` | `无（late）` | 待决：无初始化器，不猜历史值 | — |
| `seed` :38 | `int` | `无（late）` | 待决：无初始化器，不猜历史值 | — |
| `contentKind` :41 | `ActivityContentKind` | `无（late）` | 待决：无初始化器，不把 fallback 当语义默认 | — |
| `participation` :44 | `ActivityParticipationMode` | `无（late）` | 待决：无初始化器，不把 fallback 当语义默认 | — |
| `controller` :47 | `ActivityController` | `无（late）` | 待决：无初始化器，不把 fallback 当语义默认 | — |
| `clock` :50 | `ActivityClock` | `无（late）` | 待决：无初始化器，不把 fallback 当语义默认 | — |
| `entryKind` :53 | `ActivityEntryKind` | `无（late）` | 待决：无初始化器，不把 fallback 当语义默认 | — |
| `members` :56 | `List<ActivityMemberSnapshot>` | `[]` | 跳过：实测类型规则下缺失值与初始化器一致 | — |
| `participantCreatedAt` :58 | `DateTime` | `无（late）` | 待决：无初始化器，不把 fallback 当语义默认 | — |
| `participantName` :59 | `String` | `无（late）` | 待决：无初始化器，不把 fallback 当语义默认 | — |
| `formation` :63 | `Formation?` | `隐式 null` | 跳过：缺失 null 与 Dart 默认一致 | — |
| `phase` :66 | `DurableActivityPhase` | `DurableActivityPhase.active` | 跳过：实测类型规则下缺失值与初始化器一致 | — |
| `outcome` :69 | `DurableActivityOutcome` | `DurableActivityOutcome.none` | 跳过：实测类型规则下缺失值与初始化器一致 | — |
| `startedAt` :71 | `DateTime` | `无（late）` | 待决：无初始化器，不把 fallback 当语义默认 | — |
| `lastAdvancedAt` :74 | `DateTime` | `无（late）` | 待决：无初始化器，不把 fallback 当语义默认 | — |
| `settlementAppliedAt` :76 | `DateTime?` | `隐式 null` | 跳过：缺失 null 与 Dart 默认一致 | — |
| `closedAt` :77 | `DateTime?` | `隐式 null` | 跳过：缺失 null 与 Dart 默认一致 | — |

### BossMemory（collection）

源文件：`lib/features/battle_record/domain/boss_memory.dart`

| 字段 | 类型 | Dart 初始化器 | 判定 | 归位位置 |
|---|---|---|---|---|
| `id` :10 | `Id` | `Isar.autoIncrement` | 跳过：主键，不是缺字段业务计数器 | — |
| `saveDataId` :11 | `int` | `无（late）` | 待决：无初始化器，不猜历史值 | — |
| `bossKey` :15 | `String` | `无（late）` | 待决：无初始化器，不把 fallback 当语义默认 | — |
| `source` :18 | `BossMemorySource` | `无（late）` | 待决：无初始化器，不把 fallback 当语义默认 | — |
| `groupIndex` :22 | `int` | `无（late）` | 待决：无初始化器，不猜历史值 | — |
| `bossName` :24 | `String` | `无（late）` | 待决：无初始化器，不把 fallback 当语义默认 | — |
| `firstClearedAt` :26 | `DateTime?` | `隐式 null` | 跳过：缺失 null 与 Dart 默认一致 | — |
| `isPreRecord` :29 | `bool` | `无（late）` | 待决：无初始化器，不把 fallback 当语义默认 | — |
| `totalDamage` :31 | `int?` | `隐式 null` | 跳过：缺失 null 与 Dart 默认一致 | — |
| `critCount` :32 | `int?` | `隐式 null` | 跳过：缺失 null 与 Dart 默认一致 | — |
| `totalTicks` :33 | `int?` | `隐式 null` | 跳过：缺失 null 与 Dart 默认一致 | — |
| `topContributorName` :34 | `String?` | `隐式 null` | 跳过：缺失 null 与 Dart 默认一致 | — |
| `topContributorDamage` :35 | `int?` | `隐式 null` | 跳过：缺失 null 与 Dart 默认一致 | — |
| `treasureName` :36 | `String?` | `隐式 null` | 跳过：缺失 null 与 Dart 默认一致 | — |
| `treasureTier` :39 | `EquipmentTier?` | `隐式 null` | 跳过：缺失 null 与 Dart 默认一致 | — |
| `rosterNames` :41 | `List<String>` | `[]` | 跳过：实测类型规则下缺失值与初始化器一致 | — |
| `rosterPortraits` :42 | `List<String>` | `[]` | 跳过：实测类型规则下缺失值与初始化器一致 | — |
| `defeatCount` :45 | `int` | `无（late）` | 待决：无初始化器，不猜历史值 | — |

### BossGauntletRun（collection）

源文件：`lib/features/boss_gauntlet/domain/boss_gauntlet_run.dart`

| 字段 | 类型 | Dart 初始化器 | 判定 | 归位位置 |
|---|---|---|---|---|
| `id` :16 | `Id` | `Isar.autoIncrement` | 跳过：主键，不是缺字段业务计数器 | — |
| `saveDataId` :18 | `int` | `无（late）` | 待决：无初始化器，不猜历史值 | — |
| `seed` :22 | `int` | `无（late）` | 待决：无初始化器，不猜历史值 | — |
| `cycleSeedEnabled` :25 | `bool` | `false` | 跳过：实测类型规则下缺失值与初始化器一致 | — |
| `currentStage` :28 | `int` | `1` | 归位：仅精确 minLong / NaN → 初始化器 | `lib/data/isar_missing_field_defaults.dart:522` |
| `cycleIndex` :33 | `int` | `1` | 归位：仅精确 minLong / NaN → 初始化器 | `lib/data/isar_missing_field_defaults.dart:526` |
| `sessionPhase` :36 | `GauntletPhase` | `GauntletPhase.inBattle` | 跳过：实测类型规则下缺失值与初始化器一致 | — |
| `members` :39 | `List<ActivityMemberSnapshot>` | `[]` | 跳过：实测类型规则下缺失值与初始化器一致 | — |
| `escrowItemDefIds` :43 | `List<String>` | `[]` | 跳过：实测类型规则下缺失值与初始化器一致 | — |
| `escrowLoadedQty` :46 | `List<int>` | `[]` | 跳过：实测类型规则下缺失值与初始化器一致 | — |
| `escrowUsedQty` :49 | `List<int>` | `[]` | 跳过：实测类型规则下缺失值与初始化器一致 | — |
| `rewardCandidateDefIds` :53 | `List<String>` | `[]` | 跳过：实测类型规则下缺失值与初始化器一致 | — |
| `isFirstClearPending` :56 | `bool` | `false` | 跳过：实测类型规则下缺失值与初始化器一致 | — |
| `stagedRewards` :59 | `List<RewardEntry>` | `[]` | 跳过：实测类型规则下缺失值与初始化器一致 | — |

### EncounterProgress（collection）

源文件：`lib/features/encounter/domain/encounter_progress.dart`

| 字段 | 类型 | Dart 初始化器 | 判定 | 归位位置 |
|---|---|---|---|---|
| `id` :22 | `Id` | `Isar.autoIncrement` | 跳过：主键，不是缺字段业务计数器 | — |
| `saveDataId` :25 | `int` | `无（late）` | 待决：无初始化器，不猜历史值 | — |
| `triggeredEncounterIds` :28 | `List<String>` | `[]` | 跳过：实测类型规则下缺失值与初始化器一致 | — |
| `schoolKillCounts` :31 | `List<SchoolKillCount>` | `[]` | 跳过：实测类型规则下缺失值与初始化器一致 | — |
| `biomeMinutes` :35 | `List<BiomeMinutes>` | `[]` | 跳过：实测类型规则下缺失值与初始化器一致 | — |
| `weatherMinutes` :38 | `List<WeatherMinutes>` | `[]` | 跳过：实测类型规则下缺失值与初始化器一致 | — |
| `attributeGainsConstitution` :41 | `int` | `0` | 归位：仅精确 minLong / NaN → 初始化器 | `lib/data/isar_missing_field_defaults.dart:542` |
| `attributeGainsEnlightenment` :42 | `int` | `0` | 归位：仅精确 minLong / NaN → 初始化器 | `lib/data/isar_missing_field_defaults.dart:546` |
| `attributeGainsAgility` :43 | `int` | `0` | 归位：仅精确 minLong / NaN → 初始化器 | `lib/data/isar_missing_field_defaults.dart:550` |
| `attributeGainsFortune` :44 | `int` | `0` | 归位：仅精确 minLong / NaN → 初始化器 | `lib/data/isar_missing_field_defaults.dart:554` |
| `unlockedSkillIds` :48 | `List<String>` | `[]` | 跳过：实测类型规则下缺失值与初始化器一致 | — |
| `createdAt` :57 | `DateTime` | `无（late）` | 待决：无初始化器，不把 fallback 当语义默认 | — |
| `attributeGainsTotal` :50 | 只读 getter | 从成员计算 | 跳过：无 setter，不计字段分母 | — |

### SchoolKillCount（embedded）

源文件：`lib/features/encounter/domain/encounter_progress.dart`

| 字段 | 类型 | Dart 初始化器 | 判定 | 归位位置 |
|---|---|---|---|---|
| `school` :67 | `TechniqueSchool` | `TechniqueSchool.gangMeng` | 跳过：实测类型规则下缺失值与初始化器一致 | — |
| `count` :68 | `int` | `0` | 归位：仅精确 minLong / NaN → 初始化器 | `lib/data/isar_missing_field_defaults.dart:573` |

### BiomeMinutes（embedded）

源文件：`lib/features/encounter/domain/encounter_progress.dart`

| 字段 | 类型 | Dart 初始化器 | 判定 | 归位位置 |
|---|---|---|---|---|
| `biome` :75 | `EncounterBiome` | `EncounterBiome.mountainForest` | 待决：缺失 fallback 与合法值重合 | — |
| `minutes` :76 | `int` | `0` | 归位：仅精确 minLong / NaN → 初始化器 | `lib/data/isar_missing_field_defaults.dart:583` |

### WeatherMinutes（embedded）

源文件：`lib/features/encounter/domain/encounter_progress.dart`

| 字段 | 类型 | Dart 初始化器 | 判定 | 归位位置 |
|---|---|---|---|---|
| `weather` :83 | `EncounterWeather` | `EncounterWeather.clear` | 跳过：实测类型规则下缺失值与初始化器一致 | — |
| `minutes` :84 | `int` | `0` | 归位：仅精确 minLong / NaN → 初始化器 | `lib/data/isar_missing_field_defaults.dart:593` |

### ExpeditionMilestoneRecord（collection）

源文件：`lib/features/expedition/domain/expedition_milestone_record.dart`

| 字段 | 类型 | Dart 初始化器 | 判定 | 归位位置 |
|---|---|---|---|---|
| `id` :12 | `Id` | `Isar.autoIncrement` | 跳过：主键，不是缺字段业务计数器 | — |
| `recordVersion` :14 | `int` | `1` | 归位：仅精确 minLong / NaN → 初始化器 | `lib/data/isar_missing_field_defaults.dart:603` |
| `recordKey` :17 | `String` | `无（late）` | 待决：无初始化器，不把 fallback 当语义默认 | — |
| `saveDataId` :20 | `int` | `无（late）` | 待决：无初始化器，不猜历史值 | — |
| `routeId` :22 | `String` | `无（late）` | 待决：无初始化器，不把 fallback 当语义默认 | — |
| `milestoneId` :23 | `String` | `无（late）` | 待决：无初始化器，不把 fallback 当语义默认 | — |
| `nodeIndex` :26 | `int` | `无（late）` | 待决：无初始化器，不猜历史值 | — |
| `nodeSeed` :27 | `int` | `无（late）` | 待决：无初始化器，不猜历史值 | — |
| `cycleIndex` :28 | `int` | `1` | 归位：仅精确 minLong / NaN → 初始化器 | `lib/data/isar_missing_field_defaults.dart:607` |
| `sourceRunId` :30 | `int` | `无（late）` | 待决：无初始化器，不猜历史值 | — |
| `sourceParticipantId` :31 | `int` | `无（late）` | 待决：无初始化器，不猜历史值 | — |
| `discoveredAt` :32 | `DateTime` | `无（late）` | 待决：无初始化器，不把 fallback 当语义默认 | — |
| `manualClearedAt` :35 | `DateTime?` | `隐式 null` | 跳过：缺失 null 与 Dart 默认一致 | — |

### ExpeditionRun（collection）

源文件：`lib/features/expedition/domain/expedition_run.dart`

| 字段 | 类型 | Dart 初始化器 | 判定 | 归位位置 |
|---|---|---|---|---|
| `id` :14 | `Id` | `Isar.autoIncrement` | 跳过：主键，不是缺字段业务计数器 | — |
| `saveDataId` :17 | `int` | `无（late）` | 待决：无初始化器，不猜历史值 | — |
| `policy` :20 | `ExpeditionPolicy` | `无（late）` | 待决：无初始化器，不把 fallback 当语义默认 | — |
| `seed` :23 | `int` | `无（late）` | 待决：无初始化器，不猜历史值 | — |
| `departedAt` :25 | `DateTime` | `无（late）` | 待决：无初始化器，不把 fallback 当语义默认 | — |
| `lastSettledAt` :26 | `DateTime?` | `隐式 null` | 跳过：缺失 null 与 Dart 默认一致 | — |
| `currentNode` :29 | `int` | `0` | 归位：仅精确 minLong / NaN → 初始化器 | `lib/data/isar_missing_field_defaults.dart:617` |
| `cycleIndex` :33 | `int` | `1` | 归位：仅精确 minLong / NaN → 初始化器 | `lib/data/isar_missing_field_defaults.dart:621` |
| `members` :36 | `List<ActivityMemberSnapshot>` | `[]` | 跳过：实测类型规则下缺失值与初始化器一致 | — |
| `stagedRewards` :39 | `List<RewardEntry>` | `[]` | 跳过：实测类型规则下缺失值与初始化器一致 | — |
| `defeated` :44 | `bool` | `false` | 跳过：实测类型规则下缺失值与初始化器一致 | — |

### NpcRelation（collection）

源文件：`lib/features/jianghu/domain/npc_relation.dart`

| 字段 | 类型 | Dart 初始化器 | 判定 | 归位位置 |
|---|---|---|---|---|
| `id` :14 | `Id` | `Isar.autoIncrement` | 跳过：主键，不是缺字段业务计数器 | — |
| `sourceCharacterId` :16 | `int` | `无（late）` | 待决：无初始化器，不猜历史值 | — |
| `targetCharacterId` :18 | `int` | `无（late）` | 待决：无初始化器，不猜历史值 | — |
| `type` :19 | `String` | `无（late）` | 待决：无初始化器，不把 fallback 当语义默认 | — |
| `level` :20 | `int` | `无（late）` | 待决：无初始化器，不猜历史值 | — |
| `updatedAt` :21 | `DateTime` | `无（late）` | 待决：无初始化器，不把 fallback 当语义默认 | — |

### Reputation（collection）

源文件：`lib/features/jianghu/domain/reputation.dart`

| 字段 | 类型 | Dart 初始化器 | 判定 | 归位位置 |
|---|---|---|---|---|
| `id` :15 | `Id` | `Isar.autoIncrement` | 跳过：主键，不是缺字段业务计数器 | — |
| `playerId` :19 | `int` | `无（late）` | 待决：无初始化器，不猜历史值 | — |
| `factionId` :21 | `String` | `无（late）` | 待决：无初始化器，不把 fallback 当语义默认 | — |
| `value` :22 | `int` | `无（late）` | 待决：无初始化器，不猜历史值 | — |
| `updatedAt` :23 | `DateTime` | `无（late）` | 待决：无初始化器，不把 fallback 当语义默认 | — |

### MainlineProgress（collection）

源文件：`lib/features/mainline/domain/mainline_progress.dart`

| 字段 | 类型 | Dart 初始化器 | 判定 | 归位位置 |
|---|---|---|---|---|
| `id` :18 | `Id` | `Isar.autoIncrement` | 跳过：主键，不是缺字段业务计数器 | — |
| `saveDataId` :22 | `int` | `无（late）` | 待决：无初始化器，不猜历史值 | — |
| `currentChapterIndex` :25 | `int` | `1` | 归位：仅精确 minLong / NaN → 初始化器 | `lib/data/isar_missing_field_defaults.dart:637` |
| `clearedStageIds` :28 | `List<String>` | `[]` | 跳过：实测类型规则下缺失值与初始化器一致 | — |
| `clearedAt` :31 | `List<DateTime>` | `[]` | 跳过：实测类型规则下缺失值与初始化器一致 | — |
| `clearedStageCycleKeys` :37 | `List<String>` | `[]` | 跳过：实测类型规则下缺失值与初始化器一致 | — |
| `clearedChapterCycleKeys` :44 | `List<String>` | `[]` | 跳过：实测类型规则下缺失值与初始化器一致 | — |

### MainlineSettlementJournal（collection）

源文件：`lib/features/mainline/domain/mainline_settlement_journal.dart`

| 字段 | 类型 | Dart 初始化器 | 判定 | 归位位置 |
|---|---|---|---|---|
| `id` :114 | `Id` | `Isar.autoIncrement` | 跳过：主键，不是缺字段业务计数器 | — |
| `settlementId` :117 | `String` | `无（late）` | 待决：无初始化器，不把 fallback 当语义默认 | — |
| `saveDataId` :120 | `int` | `无（late）` | 待决：无初始化器，不猜历史值 | — |
| `runId` :123 | `String` | `无（late）` | 待决：无初始化器，不把 fallback 当语义默认 | — |
| `stageId` :125 | `String` | `无（late）` | 待决：无初始化器，不把 fallback 当语义默认 | — |
| `participantId` :126 | `int` | `无（late）` | 待决：无初始化器，不猜历史值 | — |
| `loadoutVersion` :127 | `int` | `无（late）` | 待决：无初始化器，不猜历史值 | — |
| `loadoutSnapshotId` :128 | `String` | `无（late）` | 待决：无初始化器，不把 fallback 当语义默认 | — |
| `loadoutSnapshotIds` :129 | `List<String>` | `[]` | 跳过：实测类型规则下缺失值与初始化器一致 | — |
| `phase` :132 | `MainlineSettlementPhase` | `MainlineSettlementPhase.prepared` | 跳过：实测类型规则下缺失值与初始化器一致 | — |
| `postSettlementAction` :135 | `MainlinePostSettlementAction` | `MainlinePostSettlementAction.none` | 跳过：实测类型规则下缺失值与初始化器一致 | — |
| `pendingEffectIds` :138 | `List<String>` | `[]` | 跳过：实测类型规则下缺失值与初始化器一致 | — |
| `completedEffectIds` :139 | `List<String>` | `[]` | 跳过：实测类型规则下缺失值与初始化器一致 | — |
| `createdAt` :141 | `DateTime` | `无（late）` | 待决：无初始化器，不把 fallback 当语义默认 | — |
| `updatedAt` :142 | `DateTime` | `无（late）` | 待决：无初始化器，不把 fallback 当语义默认 | — |
| `coreAppliedAt` :143 | `DateTime?` | `隐式 null` | 跳过：缺失 null 与 Dart 默认一致 | — |
| `closedAt` :144 | `DateTime?` | `隐式 null` | 跳过：缺失 null 与 Dart 默认一致 | — |

### ProgressiveUnlockReceipt（collection）

源文件：`lib/features/progressive_unlock/domain/progressive_unlock_receipt.dart`

| 字段 | 类型 | Dart 初始化器 | 判定 | 归位位置 |
|---|---|---|---|---|
| `id` :9 | `Id` | `Isar.autoIncrement` | 跳过：主键，不是缺字段业务计数器 | — |
| `receiptVersion` :11 | `int` | `1` | 归位：仅精确 minLong / NaN → 初始化器 | `lib/data/isar_missing_field_defaults.dart:647` |
| `receiptKey` :14 | `String` | `无（late）` | 待决：无初始化器，不把 fallback 当语义默认 | — |
| `saveDataId` :17 | `int` | `无（late）` | 待决：无初始化器，不猜历史值 | — |
| `unlockId` :20 | `ProgressiveUnlockId` | `无（late）` | 待决：无初始化器，不把 fallback 当语义默认 | — |
| `highestState` :23 | `ProgressiveUnlockState` | `无（late）` | 待决：无初始化器，不把 fallback 当语义默认 | — |
| `firstObservedAt` :25 | `DateTime` | `无（late）` | 待决：无初始化器，不把 fallback 当语义默认 | — |
| `updatedAt` :26 | `DateTime` | `无（late）` | 待决：无初始化器，不把 fallback 当语义默认 | — |
| `openedAt` :30 | `DateTime?` | `隐式 null` | 跳过：缺失 null 与 Dart 默认一致 | — |
| `sealAcknowledgedAt` :33 | `DateTime?` | `隐式 null` | 跳过：缺失 null 与 Dart 默认一致 | — |

### PvpRecord（collection）

源文件：`lib/features/pvp/domain/pvp_record.dart`

| 字段 | 类型 | Dart 初始化器 | 判定 | 归位位置 |
|---|---|---|---|---|
| `id` :23 | `Id` | `Isar.autoIncrement` | 跳过：主键，不是缺字段业务计数器 | — |
| `matchId` :26 | `String` | `无（late）` | 待决：无初始化器，不把 fallback 当语义默认 | — |
| `playerId` :30 | `int` | `无（late）` | 待决：无初始化器，不猜历史值 | — |
| `opponentSnapshotId` :33 | `int` | `无（late）` | 待决：无初始化器，不猜历史值 | — |
| `leftSnapshotId` :36 | `int` | `无（late）` | 待决：无初始化器，不猜历史值 | — |
| `winnerId` :39 | `int?` | `隐式 null` | 跳过：缺失 null 与 Dart 默认一致 | — |
| `playerEloBefore` :42 | `int` | `无（late）` | 待决：无初始化器，不猜历史值 | — |
| `playerEloAfter` :45 | `int` | `无（late）` | 待决：无初始化器，不猜历史值 | — |
| `eloDelta` :48 | `int` | `无（late）` | 待决：无初始化器，不猜历史值 | — |
| `timestamp` :51 | `DateTime` | `无（late）` | 待决：无初始化器，不把 fallback 当语义默认 | — |

### PvpSnapshot（collection）

源文件：`lib/features/pvp/domain/pvp_snapshot.dart`

| 字段 | 类型 | Dart 初始化器 | 判定 | 归位位置 |
|---|---|---|---|---|
| `id` :14 | `Id` | `Isar.autoIncrement` | 跳过：主键，不是缺字段业务计数器 | — |
| `snapshotJson` :17 | `String` | `无（late）` | 待决：无初始化器，不把 fallback 当语义默认 | — |
| `snapshotElo` :20 | `int` | `无（late）` | 待决：无初始化器，不猜历史值 | — |
| `takenAt` :23 | `DateTime` | `无（late）` | 待决：无初始化器，不把 fallback 当语义默认 | — |

### RewardClaimReceipt（collection）

源文件：`lib/features/reward/domain/reward_claim_receipt.dart`

| 字段 | 类型 | Dart 初始化器 | 判定 | 归位位置 |
|---|---|---|---|---|
| `id` :14 | `Id` | `Isar.autoIncrement` | 跳过：主键，不是缺字段业务计数器 | — |
| `receiptVersion` :17 | `int` | `1` | 归位：仅精确 minLong / NaN → 初始化器 | `lib/data/isar_missing_field_defaults.dart:657` |
| `claimKey` :20 | `String` | `无（late）` | 待决：无初始化器，不把 fallback 当语义默认 | — |
| `saveDataId` :23 | `int` | `无（late）` | 待决：无初始化器，不猜历史值 | — |
| `contentKind` :26 | `RewardContentKind` | `无（late）` | 待决：无初始化器，不把 fallback 当语义默认 | — |
| `contentId` :28 | `String` | `无（late）` | 待决：无初始化器，不把 fallback 当语义默认 | — |
| `layer` :31 | `RewardLayer` | `无（late）` | 待决：无初始化器，不把 fallback 当语义默认 | — |
| `scope` :34 | `RewardScope` | `无（late）` | 待决：无初始化器，不把 fallback 当语义默认 | — |
| `participantId` :36 | `int?` | `隐式 null` | 跳过：缺失 null 与 Dart 默认一致 | — |
| `occurrenceId` :37 | `String?` | `隐式 null` | 跳过：缺失 null 与 Dart 默认一致 | — |
| `sourceSettlementId` :40 | `String` | `无（late）` | 待决：无初始化器，不把 fallback 当语义默认 | — |
| `isHistoricalTombstone` :43 | `bool` | `false` | 跳过：实测类型规则下缺失值与初始化器一致 | — |
| `createdAt` :45 | `DateTime` | `无（late）` | 待决：无初始化器，不把 fallback 当语义默认 | — |

### RetreatSession（collection）

源文件：`lib/features/seclusion/domain/retreat_session.dart`

| 字段 | 类型 | Dart 初始化器 | 判定 | 归位位置 |
|---|---|---|---|---|
| `id` :19 | `Id` | `Isar.autoIncrement` | 跳过：主键，不是缺字段业务计数器 | — |
| `saveDataId` :22 | `int` | `无（late）` | 待决：无初始化器，不猜历史值 | — |
| `mapType` :25 | `RetreatMapType` | `无（late）` | 待决：无初始化器，不把 fallback 当语义默认 | — |
| `durationHours` :28 | `int` | `0` | 归位：仅精确 minLong / NaN → 初始化器 | `lib/data/isar_missing_field_defaults.dart:667` |
| `realmTierAtStart` :33 | `RealmTier?` | `隐式 null` | 跳过：缺失 null 与 Dart 默认一致 | — |
| `startedAt` :36 | `DateTime` | `无（late）` | 待决：无初始化器，不把 fallback 当语义默认 | — |
| `completedAt` :39 | `DateTime?` | `隐式 null` | 跳过：缺失 null 与 Dart 默认一致 | — |
| `status` :42 | `RetreatStatus` | `RetreatStatus.active` | 跳过：实测类型规则下缺失值与初始化器一致 | — |
| `actualRewards` :46 | `List<RewardEntry>` | `[]` | 跳过：实测类型规则下缺失值与初始化器一致 | — |

### Sect（collection）

源文件：`lib/features/sect/domain/sect.dart`

| 字段 | 类型 | Dart 初始化器 | 判定 | 归位位置 |
|---|---|---|---|---|
| `id` :23 | `Id` | `Isar.autoIncrement` | 跳过：主键，不是缺字段业务计数器 | — |
| `name` :25 | `String` | `无（late）` | 待决：无初始化器，不把 fallback 当语义默认 | — |
| `founderId` :28 | `int` | `无（late）` | 待决：无初始化器，不猜历史值 | — |
| `sectLevel` :31 | `int` | `无（late）` | 待决：无初始化器，不猜历史值 | — |
| `sectReputation` :34 | `int` | `无（late）` | 待决：无初始化器，不猜历史值 | — |
| `totalWins` :37 | `int` | `无（late）` | 待决：无初始化器，不猜历史值 | — |
| `createdAt` :39 | `DateTime` | `无（late）` | 待决：无初始化器，不把 fallback 当语义默认 | — |
| `lastEventAt` :42 | `DateTime?` | `隐式 null` | 跳过：缺失 null 与 Dart 默认一致 | — |
| `lastTickAt` :48 | `DateTime?` | `隐式 null` | 跳过：缺失 null 与 Dart 默认一致 | — |
| `territoryIds` :54 | `List<String>` | `[]` | 跳过：实测类型规则下缺失值与初始化器一致 | — |
| `memberCount` :62 | `int` | `0` | 待决：身份/阈值/出生属性占位 | — |

### SectEvent（collection）

源文件：`lib/features/sect/domain/sect_event.dart`

| 字段 | 类型 | Dart 初始化器 | 判定 | 归位位置 |
|---|---|---|---|---|
| `id` :13 | `Id` | `Isar.autoIncrement` | 跳过：主键，不是缺字段业务计数器 | — |
| `sectId` :17 | `int` | `无（late）` | 待决：无初始化器，不猜历史值 | — |
| `type` :20 | `SectEventType` | `无（late）` | 待决：无初始化器，不把 fallback 当语义默认 | — |
| `status` :23 | `SectEventStatus` | `无（late）` | 待决：无初始化器，不把 fallback 当语义默认 | — |
| `triggeredAt` :25 | `DateTime` | `无（late）` | 待决：无初始化器，不把 fallback 当语义默认 | — |
| `resolvedAt` :28 | `DateTime?` | `隐式 null` | 跳过：缺失 null 与 Dart 默认一致 | — |
| `narrativeId` :31 | `String` | `无（late）` | 待决：无初始化器，不把 fallback 当语义默认 | — |
| `reputationDelta` :34 | `int?` | `隐式 null` | 跳过：缺失 null 与 Dart 默认一致 | — |

### TowerPersonalRecord（collection）

源文件：`lib/features/tower/domain/tower_personal_record.dart`

| 字段 | 类型 | Dart 初始化器 | 判定 | 归位位置 |
|---|---|---|---|---|
| `id` :11 | `Id` | `Isar.autoIncrement` | 跳过：主键，不是缺字段业务计数器 | — |
| `recordVersion` :13 | `int` | `1` | 归位：仅精确 minLong / NaN → 初始化器 | `lib/data/isar_missing_field_defaults.dart:680` |
| `recordKey` :16 | `String` | `无（late）` | 待决：无初始化器，不把 fallback 当语义默认 | — |
| `saveDataId` :19 | `int` | `无（late）` | 待决：无初始化器，不猜历史值 | — |
| `participantId` :22 | `int` | `无（late）` | 待决：无初始化器，不猜历史值 | — |
| `highestClearedFloor` :25 | `int` | `0` | 归位：仅精确 minLong / NaN → 初始化器 | `lib/data/isar_missing_field_defaults.dart:684` |
| `bestClearTimeMs` :30 | `int?` | `隐式 null` | 跳过：缺失 null 与 Dart 默认一致 | — |
| `createdAt` :32 | `DateTime` | `无（late）` | 待决：无初始化器，不把 fallback 当语义默认 | — |
| `updatedAt` :33 | `DateTime` | `无（late）` | 待决：无初始化器，不把 fallback 当语义默认 | — |
| `lastClearedAt` :34 | `DateTime` | `无（late）` | 待决：无初始化器，不把 fallback 当语义默认 | — |

### TowerProgress（collection）

源文件：`lib/features/tower/domain/tower_progress.dart`

| 字段 | 类型 | Dart 初始化器 | 判定 | 归位位置 |
|---|---|---|---|---|
| `id` :19 | `Id` | `Isar.autoIncrement` | 跳过：主键，不是缺字段业务计数器 | — |
| `saveDataId` :23 | `int` | `无（late）` | 待决：无初始化器，不猜历史值 | — |
| `highestClearedFloor` :27 | `int` | `0` | 归位：仅精确 minLong / NaN → 初始化器 | `lib/data/isar_missing_field_defaults.dart:694` |
| `highestClearedAt` :30 | `DateTime?` | `隐式 null` | 跳过：缺失 null 与 Dart 默认一致 | — |
| `totalAttempts` :33 | `int` | `0` | 归位：仅精确 minLong / NaN → 初始化器 | `lib/data/isar_missing_field_defaults.dart:698` |
| `totalDefeats` :36 | `int` | `0` | 归位：仅精确 minLong / NaN → 初始化器 | `lib/data/isar_missing_field_defaults.dart:702` |
| `createdAt` :39 | `DateTime` | `无（late）` | 待决：无初始化器，不把 fallback 当语义默认 | — |
| `perFloorClearTimes` :45 | `List<int>` | `[]` | 跳过：实测类型规则下缺失值与初始化器一致 | — |
| `bestClearTime` :49 | `int?` | `隐式 null` | 跳过：缺失 null 与 Dart 默认一致 | — |
| `lastClearedAt` :53 | `DateTime?` | `隐式 null` | 跳过：缺失 null 与 Dart 默认一致 | — |
| `currentCycleIndex` :57 | `int` | `1` | 归位：仅精确 minLong / NaN → 初始化器 | `lib/data/isar_missing_field_defaults.dart:706` |
| `maxClearedCycle` :62 | `int` | `0` | 归位：仅精确 minLong / NaN → 初始化器 | `lib/data/isar_missing_field_defaults.dart:710` |

### EquipmentCatalogEntry（collection）

源文件：`lib/features/weapon_codex/domain/equipment_catalog_entry.dart`

| 字段 | 类型 | Dart 初始化器 | 判定 | 归位位置 |
|---|---|---|---|---|
| `id` :11 | `Id` | `Isar.autoIncrement` | 跳过：主键，不是缺字段业务计数器 | — |
| `saveDataId` :12 | `int` | `无（late）` | 待决：无初始化器，不猜历史值 | — |
| `defId` :16 | `String` | `无（late）` | 待决：无初始化器，不把 fallback 当语义默认 | — |
| `firstObtainedAt` :19 | `DateTime?` | `隐式 null` | 跳过：缺失 null 与 Dart 默认一致 | — |
| `firstObtainedFrom` :22 | `String` | `无（late）` | 待决：无初始化器，不把 fallback 当语义默认 | — |
| `obtainedCount` :25 | `int` | `无（late）` | 待决：无初始化器，不猜历史值 | — |
| `isPreRecord` :28 | `bool` | `无（late）` | 待决：无初始化器，不把 fallback 当语义默认 | — |

## 2026-09-07 D 单前置条件集成

用户在分诊任务开工受阻后明确要求先处理前置条件。本次接收 D 单 `ecc75dba9bba04e8f18b6dbe603d0679e99b6cae`，以 `adff44e5821d7ae651b2fba694a38c42ba080469` 为基线，在既有集成 worktree 创建合并提交 `547db1c430db01d4624fd6c0377638664ef72c1c`；其整棵 Git tree 与 D 单相同。以下检查均在该 exact SHA 上重新执行，并非复用历史 PASS。随后只更新本报告与 PROGRESS，再快进纳入本地 main；最终 main SHA 和前后保护核验见 [交付记录](/Users/a10506/Documents/Codex/2026-09-07/isar-d-integration/delivery.json)。

| 实际命令 | 当前结果 | 原始输出 |
|---|---|---|
| `dart run build_runner build --delete-conflicting-outputs` | `Built with build_runner/aot in 6s; wrote 144 outputs.` | [build-runner.log](/Users/a10506/Documents/Codex/2026-09-07/isar-d-integration/build-runner.log) |
| `flutter analyze` | `No issues found! (ran in 7.5s)` | [analyze.log](/Users/a10506/Documents/Codex/2026-09-07/isar-d-integration/analyze.log) |
| `dart format .` | `Formatted 1771 files (0 changed) in 4.71 seconds.` | [format.log](/Users/a10506/Documents/Codex/2026-09-07/isar-d-integration/format.log) |
| `flutter build macos` | `✓ Built build/macos/Build/Products/Release/wuxia_idle.app (177.3MB)` | [macos-build.log](/Users/a10506/Documents/Codex/2026-09-07/isar-d-integration/macos-build.log) |
| `flutter test --no-pub --machine` | 6285 PASS / 0 FAIL / 0 SKIP；899/899 文件，漏文件 0 | [全量摘要](/Users/a10506/Documents/Codex/2026-09-07/isar-d-integration/full-test-summary.json) |

相关测试另按 13 个文件逐个执行，合计 115/115。全量持有既有共享锁；生成文件未提交；未设置 DEVELOPER_DIR。macOS 构建的第三方编译警告原样保留在日志中。后续记录提交只含两份 Markdown，不改变受测代码。main 快进后另执行一次 build_runner，补齐主仓忽略的生成文件；结果见交付记录与 `main-build-runner.log`。

主仓 `lib/data/isar_missing_field_defaults.dart` 存在、`_currentSaveVersion == '0.48.0'`，且 `git log --oneline -3` 能正常读取，分诊任务的两条前置条件与历史查询权限自检均已满足。主仓已有 AGENTS.md、CLAUDE.md、.qoder/settings.json、归档文件逐个 SHA256 对照未变；本次未 push、未发布、未启动真实存档迁移，不删除分支/worktree，不代签 CI、真人或 Windows 验收。此次只解除 D 单集成依赖，待决字段的考古分诊与菜单尚未开展。
