# 角色四项属性职责优化设计

> 日期：2026-07-13
> 分支：`codex/character-attribute-roles`
> 基线：`main` @ `b44a8942`
> 决策来源：用户逐项确认“保留旧角色数值、统一属性职责、采用推荐方案”

## 1. 目标

让四项先天属性各自拥有清楚、真实且不过度重叠的作用：

- 根骨决定能否久战，并缩短新产生的重伤时间。
- 悟性决定学武效率，并负责武学领悟类事件的软概率。
- 身法决定出手与闪避，不再同时垄断暴击。
- 机缘决定普通江湖奇遇，并解锁少量可见的特殊选项。

战斗强弱仍主要来自境界、永久内力、装备、心法与招式。四项先天属性改变角色的成长方式和江湖经历，不新增传统网游式力量、智力、耐力或可洗点系统。

## 2. 已确认边界

- 不重洗、不迁移、不重新分配现有角色的根骨、悟性、身法和机缘。
- 不修改 Isar 字段、schema、存档路径、`saveVersion` 或多槽语义。
- 不开放手动加点、反复重抽或属性重置。
- 不新增属性，不改变境界 ↔ 装备阶 ↔ 心法阶锁定。
- 不改变关卡、敌人、掉落表、招式倍率或伤害公式结构。
- 不接机缘商店折扣，不接装备掉率，不制造换人购物或刷高机缘收益的机械操作。
- 在线、离线和闭关使用同一属性规则，不增加在线专属收益。
- 所有系数进入 `data/numbers.yaml`，Dart 只实现强类型公式。

## 3. 数值规则

### 3.1 根骨

根骨继续按既有公式增加最大生命。新增的重伤时长规则只作用于新产生的重伤：

```text
有效点数 = max(根骨 - 5, 0)
减时比例 = min(有效点数 × 0.02, 0.20)
新重伤时长 = 基础重伤时长 × (1 - 减时比例)
```

当前基础重伤时长为 8 小时：根骨 5 为 8 小时，根骨 10 为 7.2 小时，根骨 15 为 6.4 小时。根骨低于 5 不增加惩罚。旧档已经存在的 `injuryHoursRemaining` 不追溯重算，恢复计时速度也不改变。

### 3.2 悟性

悟性成长倍率只提供正向差异，避免无法重抽的低悟性角色变成负资产：

```text
有效点数 = max(悟性 - 5, 0)
成长加成 = min(有效点数 × 0.02, 0.20)
成长倍率 = 1 + 成长加成
```

该倍率用于三条真实成长路径：

1. **主修心法修炼度**：数据库继续保存真实招式使用次数。一次结算新增的修炼度按主修心法全部真实使用次数的累计折算差计算，保留小数收益而不增加新存档字段：

   ```text
   有效累计次数 = floor(真实累计次数 × 成长倍率)
   本次修炼度增量 = 本次有效累计次数 - 上次有效累计次数
   ```

2. **招式熟练度**：`skillUsageCount` 保存真实次数；阶段、伤害、冷却和破招收益读取 `floor(真实次数 × 成长倍率)`。已有高悟性角色会立即按既有真实次数得到相应有效熟练次数，但不会伪造历史使用记录。
3. **领悟点凝练**：修炼度增量为 `floor(领悟点消费 × 既有兑换率 × 成长倍率)`，领悟点扣除量不变。

武学领悟类事件不再读取机缘，改为：

```text
实际概率 = 基础概率 × (1 + 悟性 ÷ 20)
```

继续沿用既有概率 clamp、冷却、触发条件和 RNG；只替换软概率使用的属性。

### 3.3 身法与暴击

- 速度公式保持 `100 + 身法 × 8 + 装备速度 + 心法速度加成`。
- 闪避公式保持每点身法增加 0.3%，并继续受 30% 上限约束。
- 删除每点身法增加 0.5% 暴击率的规则和对应强类型配置字段。
- 玩家基础暴击率从 5% 调整为 7.5%，补回典型 5 点身法原本提供的 2.5%。
- 灵巧流派额外 20%、祖师增益、装备、心法、招式效果和 50% 暴击率上限保持不变。
- 敌人使用独立的 `enemy_defaults.critical_rate`，不受玩家基础暴击率调整影响。

### 3.4 机缘

除 `techniqueInsight` 外的既有奇遇继续使用：

```text
实际概率 = 基础概率 × (1 + 机缘 ÷ 20)
```

首批四个现有 `fortuneEvent` 增加第四个机缘选项，统一要求机缘 8。选项复用现有 outcome ID，不增加奖励表或数值强度：

| 事件 | 新选项方向 | 复用 outcome |
|---|---|---|
| 茶亭对局 `cha_ting_dui_ju` | 先看削竹签的人，再决定落子 | `defend_draw` |
| 渡客问道 `du_ke_wen_dao` | 先闻杯沿残留的药香 | `gain_wisdom` |
| 风雪古店 `feng_xue_gu_dian` | 坐到一直空着的第三张桌 | `get_divination` |
| 夜渡孤船 `ye_du_gu_chuan` | 把一枚无字旧钱放进艄公掌心 | `negotiate` |

`EncounterChoice` 新增可选的 `fortuneRequired`。字段缺失表示普通选项；字段存在时必须为正整数。机缘不足时选项仍显示，但禁用点击，并展示集中式文案“机缘 N”；达到要求后正常选择。触发角色沿用现有出战首位角色，不另造账号级机缘。

## 4. 架构

### 4.1 纯属性规则模块

新增 `lib/core/domain/attribute_effect_policy.dart`，包含：

- 不依赖 YAML 的强类型 `AttributeEffectRules` 值对象。
- `heavyInjuryHours`：计算新重伤时长。
- `enlightenmentGrowthMultiplier`：计算悟性成长倍率。
- `effectiveUsageCount`：从真实次数派生有效熟练次数。
- `effectiveUsageDelta`：从累计次数前后差派生本次修炼度增量。
- `encounterProbabilityAttribute` 或等价纯函数：按事件类型选择悟性或机缘。

该模块不读 Isar、不读 `GameRepository`、不操作 Widget，也不持有缓存。调用者传入 `Attributes`、基础值和 `AttributeEffectRules` 即可得到结果。

### 4.2 配置

`NumbersConfig` 将 `numbers.yaml attribute_effects` 解析为 `AttributeEffectRules`。建议结构：

```yaml
attribute_effects:
  reference_value: 5
  constitution:
    heavy_injury_reduction_per_point: 0.02
    heavy_injury_reduction_max: 0.20
  enlightenment:
    growth_bonus_per_point: 0.02
    growth_bonus_max: 0.20
    insight_probability_sensitivity: 20
  fortune:
    encounter_probability_sensitivity: 20
    special_choice_required: 8
```

生产加载必须校验：参考值和灵敏度为正数，逐点比例及上限在 `[0,1]`，特殊选项门槛为正整数。为现有小型 `NumbersConfig` 测试 fixture 提供与生产值相同的显式默认对象，但 `GameRepository.loadAllDefs()` 对生产 YAML 缺段继续 fail-fast。

### 4.3 生产接线

- `InjuryService.applyBattleInjuries` 在施加重伤时调用统一规则；轻伤逻辑不变。
- `BattleResolutionService` 已拥有 `Character`，把悟性规则传给 `CultivationService`，不让后者依赖整个仓库。
- `BattleCharacter.fromCharacter` 和所有熟练度展示入口使用同一有效次数规则。
- `InsightExchangeService` 读取角色悟性并使用同一倍率。
- `EncounterService.evaluateTriggers` 按 `EncounterType` 选择属性和灵敏度。
- `runEncounterHookAfterVictory` 把触发角色机缘传给 `showEncounterDialog`。
- `EncounterEventLoader` 解析 `fortune_required`；既有引用完整性校验继续保证 outcome ID 存在。
- `CharacterDerivedStats` 增加装备总攻击求和与基础防御率查询。
- `CharacterPanelScreen` 只展示派生结果，不复制公式。

## 5. 角色面板与交互

面板仍区分“四项基础属性”和“当前实力”。派生卡片调整为：

- 第一排：生命、内力、装备攻击。
- 第二排：速度、基础防御率、暴击率、闪避率。

第二排采用响应式布局，常规桌面宽度优先四列；空间不足时自动换行，不通过压缩字号硬塞。装备攻击为三件已穿装备经过强化、共鸣和开锋后的攻击总和。基础防御率只显示境界基础值，不混入战斗中的相生、破招、护法或临时减防。

真气、气海、真气获取和减耗属于每场战斗及心法配置，不进入常驻角色面板。四项属性气泡同步为真实职责；机缘说明删除商店折扣，身法说明删除暴击。

机缘锁定选项必须保留桌面语义：禁用态不可用鼠标或键盘触发；语义标签包含选项文本和“需要机缘 N”；解锁态沿用现有按钮焦点、Enter/Space 激活和鼠标指针行为。

## 6. 数据流与取整

- 真实招式次数永远先落 `skillUsageCount`，有效次数只在规则边界派生。
- 修炼度使用累计折算差，不逐次 `ceil`，避免 2% 加成在每次使用时膨胀成 100% 加成。
- 所有概率继续使用现有 RNG 注入；属性规则只计算概率，不自行抽数。
- 所有百分比显示复用 `UiStrings.percent`；所有新增玩家文案进入 `UiStrings` 或 `data/events`。
- 装备攻击调用既有 `effectiveEquipmentAttack`，不建立第二套强化/共鸣/开锋公式。

## 7. 错误处理与红线

- `attribute_effects` 生产配置缺失或越界：启动 fail-fast。
- `fortune_required <= 0` 或类型错误：事件加载失败并由生产引用校验暴露。
- 机缘选项引用不存在的 outcome：沿用 `_validateEncounterEventReferences` fail-fast。
- 心法找不到拥有者、角色无主修等既有分支语义不变。
- 根骨减时只改变重伤时长，不改变重伤概率、轻伤层数或伤势 debuff 强度。
- 悟性只改变成长速度和领悟概率，不直接增加伤害、血量、内力或真气。
- 机缘不改变商店价格、装备掉率、数值奖励倍率或在线收益。
- 玩家血量、Boss 血量、永久内力、装备基础攻击、招式倍率和实战不进百万红线不变。

## 8. 测试与验收

实施按 RED → GREEN → REFACTOR：

1. 纯规则测试覆盖根骨/悟性 `1、5、10、15`，比例 clamp 和累计差取整。
2. 伤势测试证明根骨 5/10/15 分别产生 8/7.2/6.4 小时，旧伤恢复逻辑不变。
3. 修炼测试证明真实使用次数不膨胀、有效熟练次数增长、主修修炼度跨小数门槛正确。
4. 凝练测试证明同样消费领悟点时高悟性获得温和加成，余额和事务语义不变。
5. 暴击测试证明身法变化不再影响暴击，基础 7.5%、灵巧和上限仍正确。
6. 奇遇测试证明 `techniqueInsight` 读取悟性，其余类型读取机缘；概率 clamp/RNG 不变。
7. loader/Widget 测试覆盖四个机缘选项、门槛显示、禁用/解锁、语义、键盘、focus 和 mouse cursor。
8. 面板测试覆盖装备攻击、基础防御率及 1280×720、1440×900 无 overflow。
9. 配置测试覆盖生产缺段和越界 fail-fast；事件 outcome 引用完整性继续通过。
10. 相关伤势、结算、心法、奇遇、角色面板、存档迁移、多槽、数值红线和平衡测试通过。
11. 批末运行 `flutter analyze --no-pub`、格式检查、`git diff --check` 和并发全量测试。
12. macOS 真窗口检查角色面板以及机缘锁定/解锁场景，记录未覆盖的 Windows 风险。

## 9. 文档同步

- 更新 `GDD.md §4.1` 四项基础属性职责。
- 更新 GDD 暴击、奇遇和商店措辞，明确机缘不参与定价。
- 更新 `CLAUDE.md` 版本摘要及相关公式说明。
- 不修改 `data_schema.md`，因为没有持久化结构变化。

## 10. 非目标

- 不做属性洗点、随机重抽、加点 UI、命格系统或第五属性。
- 不做装备掉率幸运值、暴击幸运值或商店折扣。
- 不把悟性变成直接伤害乘区。
- 不重平衡关卡或顺手调整其他战斗数值。
- 不拆分 `numbers.yaml` 或全量重构 `NumbersConfig`。
