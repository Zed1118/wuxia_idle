# YAML 完整性审计报告（2026-05-12）

## 范围 & 方法

本次只读审计 `data/` 根目录 yaml，不修改 `lib/`、`data/*.yaml`、`data/narratives/`、`data/lore/`、`data/events/`。审计脚本用 Ruby `YAML.load_file` 解析现有文件，并人工对照 `lib/data/game_repository.dart` 的启动期校验逻辑。

实际扫到的根目录 yaml：`equipment.yaml`、`numbers.yaml`、`skills.yaml`、`stages.yaml`、`techniques.yaml`、`towers.yaml`。

未创建但纳入审计口径的文件：`encounters.yaml`、`ranks.yaml`、独立闭关地图 yaml（当前闭关地图实际位于 `numbers.yaml` 的 `retreat.maps`）。

## 1. 同文件内 id 唯一性

| 文件 | id 总数 | 重复 id | 状态 |
|---|---:|---|---|
| `stages.yaml` | 6 | 无 | ✓ |
| `towers.yaml` | 0（无 `id` 字段；以 `floorIndex` 为主键） | 无 | ✓ |
| `equipment.yaml` | 10 | 无 | ✓ |
| `techniques.yaml` | 6 | 无 | ✓ |
| `skills.yaml` | 18 | 无 | ✓ |
| `encounters.yaml` | ⬜ 文件未创建 | - | ⬜ |
| `numbers.yaml` | 0（根层无 `id` 字段） | 无 | ✓ |
| `numbers.yaml` `retreat.maps` | 5（按 `map_type` 审计） | 无 | ✓ |
| `ranks.yaml` | ⬜ 文件未创建 | - | ⬜ |
| 独立闭关地图 yaml | ⬜ 文件未创建 | - | ⬜ |

备注：`GameRepository._parseDefMap` 当前对 `equipment` / `techniques` / `skills` / `stages` 做 def id 去重；`towers.yaml` 由 `_enforceTowerRedLines` 校验 `floorIndex` 连续唯一；闭关地图由 `_enforceSeclusionRedLines` 校验 `RetreatMapType` 唯一。

## 2. 跨文件引用完整性

### 2.1 `stages.yaml` ↔ `narratives/`

按 AGENTS §8.1 的精确联结口径，本节检查：
- `stage.id` ↔ `data/narratives/<stage_id>.yaml`
- `narrativeOpeningId` ↔ `data/narratives/<narrativeOpeningId>.yaml`
- `narrativeVictoryId` ↔ `data/narratives/<narrativeVictoryId>.yaml`
- `prevStageId` ↔ 同文件 stage id

| stage id | narrative 文件 | 状态 |
|---|---|---|
| `mainline_test_01` | `data/narratives/mainline_test_01.yaml` | ⚠ 缺失 |
| `mainline_test_02` | `data/narratives/mainline_test_02.yaml` | ⚠ 缺失 |
| `mainline_test_03` | `data/narratives/mainline_test_03.yaml` | ⚠ 缺失 |
| `mainline_test_04` | `data/narratives/mainline_test_04.yaml` | ⚠ 缺失 |
| `mainline_test_05` | `data/narratives/mainline_test_05.yaml` | ⚠ 缺失 |
| `mainline_test_06` | `data/narratives/mainline_test_06.yaml` | ⚠ 缺失 |

| stage id | prevStageId | 状态 |
|---|---|---|
| `mainline_test_01` | - | ✓ |
| `mainline_test_02` | `mainline_test_01` | ✓ |
| `mainline_test_03` | - | ✓ |
| `mainline_test_04` | `mainline_test_03` | ✓ |
| `mainline_test_05` | - | ✓ |
| `mainline_test_06` | `mainline_test_05` | ✓ |

| stage id | narrativeOpeningId | 状态 | narrativeVictoryId | 状态 |
|---|---|---|---|---|
| `mainline_test_01` | `mainline_test_01_opening` | ⚠ 缺失 | `mainline_test_01_victory` | ⚠ 缺失 |
| `mainline_test_02` | `mainline_test_02_opening` | ⚠ 缺失 | `mainline_test_02_victory` | ⚠ 缺失 |
| `mainline_test_03` | `mainline_test_03_opening` | ⚠ 缺失 | `mainline_test_03_victory` | ⚠ 缺失 |
| `mainline_test_04` | `mainline_test_04_opening` | ⚠ 缺失 | `mainline_test_04_victory` | ⚠ 缺失 |
| `mainline_test_05` | `mainline_test_05_opening` | ⚠ 缺失 | `mainline_test_05_victory` | ⚠ 缺失 |
| `mainline_test_06` | `mainline_test_06_opening` | ⚠ 缺失 | `mainline_test_06_victory` | ⚠ 缺失 |

备注：仓库里存在 DeepSeek 侧 `data/narratives/stages/stage_01_01.yaml` 等文件，但它们不按当前 `stages.yaml` 的 `mainline_test_*` id 命名，精确联结口径下不匹配。

### 2.2 `towers.yaml` ↔ `narratives/`（Boss 层）

| floor | bossKind | narrativeOpeningId | 状态 | narrativeVictoryId | 状态 |
|---:|---|---|---|---|---|
| 5 | `minor` | `tower_05_opening` | ⚠ 缺失 | `tower_05_victory` | ⚠ 缺失 |
| 10 | `major` | `tower_10_opening` | ⚠ 缺失 | `tower_10_victory` | ⚠ 缺失 |
| 15 | `minor` | `tower_15_opening` | ⚠ 缺失 | `tower_15_victory` | ⚠ 缺失 |
| 20 | `major` | `tower_20_opening` | ⚠ 缺失 | `tower_20_victory` | ⚠ 缺失 |
| 25 | `minor` | `tower_25_opening` | ⚠ 缺失 | `tower_25_victory` | ⚠ 缺失 |
| 30 | `major` | `tower_30_opening` | ⚠ 缺失 | `tower_30_victory` | ⚠ 缺失 |

普通层未配置 narrative，符合 `GameRepository._enforceTowerRedLines` 当前要求。

### 2.3 `equipment.yaml` ↔ `lore/`

| equipment id | lore 文件 | 状态 |
|---|---|---|
| `weapon_xunchang_tie_jian` | `data/lore/weapon_xunchang_tie_jian.yaml` | ⚠ 缺失 |
| `armor_xunchang_bu_yi` | `data/lore/armor_xunchang_bu_yi.yaml` | ⚠ 缺失 |
| `accessory_xunchang_yu_pei` | `data/lore/accessory_xunchang_yu_pei.yaml` | ⚠ 缺失 |
| `weapon_xiangyang_gang_dao` | `data/lore/weapon_xiangyang_gang_dao.yaml` | ⚠ 缺失 |
| `armor_xiangyang_pi_jia` | `data/lore/armor_xiangyang_pi_jia.yaml` | ⚠ 缺失 |
| `accessory_xiangyang_yin_jie` | `data/lore/accessory_xiangyang_yin_jie.yaml` | ⚠ 缺失 |
| `weapon_haojiahuo_qing_feng_jian` | `data/lore/weapon_haojiahuo_qing_feng_jian.yaml` | ⚠ 缺失 |
| `armor_haojiahuo_jin_pao` | `data/lore/armor_haojiahuo_jin_pao.yaml` | ⚠ 缺失 |
| `accessory_haojiahuo_yu_pei_lao` | `data/lore/accessory_haojiahuo_yu_pei_lao.yaml` | ⚠ 缺失 |
| `weapon_liqi_long_quan` | `data/lore/weapon_liqi_long_quan.yaml` | ⚠ 缺失 |

备注：`data/lore/` 下已有 45 个具体装备典故文件和 7 个模板文件，但文件名不按当前 `equipment.yaml` id 命名，精确联结口径下不匹配。

### 2.4 `encounters.yaml` ↔ `events/`

`data/encounters.yaml`：⬜ Week 4 待启 / 文件未创建。

`data/events/` 当前已有 26 个事件文案文件。因 Mac 侧 `encounters.yaml` 未创建，本轮无法进行 id 双向联结校验。

## 3. schema 合理性快查

### 3.1 `stages.yaml`

浅扫必填字段：`id` / `name` / `stageType` / `requiredRealm` / `enemyTeam` / `isBossStage` / `baseExpReward` / `difficultyMultiplier`。

结果：6/6 条均具备上述字段；`prevStageId` 均引用同文件内存在 stage id；未发现跨章 prev 引用。

⚠ 备注：narrative 精确文件全部缺失，但当前 `NarrativeLoader` 运行期会 placeholder 兜底；这属于文案联结缺口，不是启动期 schema 崩溃点。

### 3.2 `towers.yaml`

| 检查项 | 结果 | 状态 |
|---|---|---|
| 层数 | 30 | ✓ |
| `floorIndex` 连续性 | 1-30 连续 | ✓ |
| 重复 `floorIndex` | 无 | ✓ |
| Boss 层 | 5/15/25 为 `minor`，10/20/30 为 `major` | ✓ |
| 普通层 narrative | 均为空 | ✓ |

⚠ 备注：Boss 层 narrative id 已配置，但对应 `data/narratives/<id>.yaml` 文件缺失。

### 3.3 `equipment.yaml` / `techniques.yaml` 七阶覆盖

| 文件 | 当前覆盖 | 目标覆盖 | 状态 |
|---|---|---|---|
| `equipment.yaml` | 4 阶：`xunChang` / `xiangYang` / `haoJiaHuo` / `liQi` | 7 阶 | ⚠ 部分覆盖 |
| `techniques.yaml` | 2 阶：`ruMenGong` / `mingJiaGong`；3 流派均有 | 7 阶 + 3 流派 | ⚠ 部分覆盖 |

## 4. 发现的问题清单

### 阻塞

- 无当前启动期阻塞项：按 `GameRepository` 现有校验，根目录 yaml 内部 id、stage prev 链、爬塔结构、闭关地图结构均可通过。

### 数据 bug

- ⚠ `stages.yaml` 的 `stage.id` 与 `data/narratives/<stage_id>.yaml` 精确联结全部缺失。
- ⚠ `stages.yaml` 的 `narrativeOpeningId` / `narrativeVictoryId` 对应 narrative 文件全部缺失。
- ⚠ `towers.yaml` 的 6 个 Boss 层 narrative 文件全部缺失。
- ⚠ `equipment.yaml` 的 10 个 equipment id 对应 `data/lore/<equipment_id>.yaml` 文件全部缺失。

### 文案待写

- ⚠ `data/events/` 已有 26 个事件文案文件，但 `data/encounters.yaml` 未创建，无法建立奇遇触发条件 ↔ 文案 id 联结。
- ⚠ `data/narratives/stages/` 与 `data/lore/` 已有不少 DeepSeek 文件，但命名体系与当前 Mac 侧根目录 yaml id 不一致。

### 命名不一致

- ⚠ 主线数值 id 使用 `mainline_test_01` 体系；DeepSeek stage 文案使用 `stage_01_01` 体系。
- ⚠ 当前装备数值 id 带 slot/tier 前缀，如 `weapon_xunchang_tie_jian`；DeepSeek lore 文件多为短 id，如 `cu_tie_jian.yaml`、`qing_feng_jian.yaml`。

### 备注

- ⬜ `encounters.yaml`、`ranks.yaml`、独立闭关地图 yaml 未创建。
- `towers.yaml` 无 `id` 字段，当前以 `floorIndex` 作为主键；这符合现有 `TowerFloorDef` / `GameRepository` 逻辑。
- `numbers.yaml` 根层无 `id` 字段；闭关地图实际在 `numbers.yaml` `retreat.maps` 内，按 `map_type` 审计未发现重复。

## 5. 不下结论的建议

1. 明天 Opus 优先决定主线 narrative id 体系：是让 DeepSeek 按 `mainline_test_*` 补文件，还是 Mac 侧重命名 `stages.yaml` / narrative id。
2. 第二优先处理装备 lore 联结：当前 `equipment.yaml` 与 `data/lore/` 文件名完全不对齐，会影响典故系统接入。
3. 若 Week 4 选 C 奇遇，先定 `encounters.yaml` id 清单，再让 `data/events/` 对齐；否则会重复出现“文案已写但无法联结”的状态。
4. 若 Week 4 选 E 武学领悟，需要先统一 `data/narratives/techniques/insights/` 与未来 `insights.yaml` 的 id 关系。
5. 七阶覆盖不足是 Demo 内容量问题，不是当前 schema 启动问题；扩装备/心法时再同步检查 7 阶与三系锁死。
