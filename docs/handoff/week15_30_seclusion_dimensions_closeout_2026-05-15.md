# Phase 4 W15 #30 闭关 3 维度接 service closeout

> Mac 端 Opus 4.7 维护,本会话末态。
> 创建日期:2026-05-15(§12 收口之后下波 A 起手)
> 上游锚:`v0.5.3-w15-final` 之后 9 commits,HEAD 待提交

---

## 1. 一句话结论

§12 收口后阻塞解除,本批补齐 `SeclusionService.computeOutputs` 4 个未消费维度(节气日 +30% / 子时 +20% 只乘内力 / techniqueLearnPoints / internalForcePoints),修原 `_timeDayBonus` 全产出 ×1.2 bug,numbers.yaml 加 2 基础锚点(`base_internal_force_per_hour: 5` / `base_technique_learn_per_hour: 0.5`)。test +6,**649/649 + analyze 0 issues**。**销账 #30**。**正午阳刚 +20%** 因 §12.1 #7 流派 extra_effect 未决留挂账。

---

## 2. 会话密度统计

- **2 commits 预计**(本 closeout commit + 主代码 commit)
- **7 文件改动** 277 insertions / 26 deletions:
  - `data/numbers.yaml`(+13)
  - `lib/data/numbers_config.dart`(+54/-3)
  - `lib/services/seclusion_service.dart`(+50/-14)
  - `test/services/seclusion_service_test.dart`(+139/-7)
  - `test/data/seclusion_map_def_test.dart`(+10)
  - `PROGRESS.md`(销账 + 新条目)
  - `CLAUDE.md`(v1.2 → v1.3,§12.1 #7 加备注)
- **649/649 测试**(W15 真闭环 643 → +6)
- **analyze 0 issues**

---

## 3. 用户拍板的 2 决策点

### 3.1 维度落地方案 B(加 base 字段 + 完整接)

`technique_learn_rate` / `internal_force_growth` 是地图特色乘数(0.5~1.5),无基础锚点不能转化为具体产出。决议在 `numbers.yaml retreat` 加 2 锚点:

| 字段 | 数值 | 推算依据 |
|---|---|---|
| `base_internal_force_per_hour` | **5** | 学徒山林 72h cap +360 内力(500→860 涨 17%);断崖宗师 72h +2007 内力。红线 15000(GDD §5.4)远在内。 |
| `base_technique_learn_per_hour` | **0.5** | 山林 72h +36 progress;藏经阁 sanLiu 72h +91 progress(≈ 初窥→小成 100);极境 6500 progress 顶级闭关需 100+ 天,合 GDD「极境=老玩家追求」。 |

### 3.2 正午阳刚 +20% 留挂账

`time_of_day_bonus.zhengWu` `effect: yang_school_techniques` 需要「角色当前主修是否刚猛流派」的判定 + 加成乘到哪个维度(techniqueLearnPoints? internalForcePoints? mojianshi?),均待 §12.1 #7 决议后才能落代码。本批不接,CLAUDE.md §12.1 #7 升 v1.3 加现状备注。

---

## 4. 代码改动清单

### 4.1 `data/numbers.yaml`

`retreat` 根末尾加 2 base 字段段,带完整 yaml 注释说明 #30 引入背景 + 公式 + 推算依据(yaml 自描述,避免数值层失忆)。

### 4.2 `lib/data/numbers_config.dart` `RetreatConfig`

- 新增 5 字段:`baseInternalForcePerHour` / `baseTechniqueLearnPerHour` / `solarTermMultiplier` / `solarTermDays` / `ziShiInternalForceMultiplier`
- `solarTermDays` 类型:`List<({int month, int day})>`(record 元组),不存 year,公历 hardcode 跨年容忍 1 天偏差(§12 #13 方案 A)
- `RetreatConfig.fromYaml` 解析 `solar_term_bonus.days_2026` 字符串 `"YYYY-MM-DD"` 提 month/day + 提 `time_of_day_bonus` 列表 `period=ziShi` 那条的 `multiplier`
- 新增 `isSolarTermDay(DateTime when) → bool`:按 month/day 比对,忽略 year

### 4.3 `lib/services/seclusion_service.dart`

**RetreatOutputs typedef** 加 2 字段:
```dart
typedef RetreatOutputs = ({
  double actualHours,
  int mojianshi,
  List<Equipment> equipmentDrops,
  int experiencePoints,
  int techniqueLearnPoints,   // 新
  int internalForcePoints,    // 新
});
```

**computeOutputs 公式重写**(所有加成按 `session.startedAt` 时刻判定,GDD §7.3 不跨日切换):
```dart
final realmScale = config.realmScaleFor(charRealmTier);
final solarBonus = config.isSolarTermDay(session.startedAt)
    ? config.solarTermMultiplier : 1.0;
final ziShiBonus = _isZiShi(session.startedAt)
    ? config.ziShiInternalForceMultiplier : 1.0;

mojianshi             = floor(def.mojianshiPerHour      × hours × scale × solarBonus)
experiencePoints      = floor(def.experiencePerHour     × hours × scale × solarBonus)
techniqueLearnPoints  = floor(config.baseTechniqueLearnPerHour × def.techniqueLearnRate
                              × hours × scale × solarBonus)
internalForcePoints   = floor(config.baseInternalForcePerHour  × def.internalForceGrowth
                              × hours × scale × solarBonus × ziShiBonus)
```

**bug fix**:删除 `_timeDayBonus`(原把「子时内力 +20%」当全产出 ×1.2),改为 `_isZiShi(startedAt) → bool`,只在 internalForcePoints 公式末位乘 ziShiBonus。

**Isar 不动**:同 experiencePoints 体例,techniqueLearnPoints / internalForcePoints 只算不写,等后续系统(主修 progress 接入 / 角色 internalForce 增长系统)消费。

### 4.4 测试

**`test/services/seclusion_service_test.dart`** 净 +6 case(原 1 个子时旧测试改语义):

| # | 测试名 | 验证 |
|---|---|---|
| 1 | 子时加成 23:00 开始 只乘 internalForcePoints,不影响 mojianshi | mojianshi=4 / experience=400(无子时加成)+ internalForce=24(floor(5×1.0×4×1.0×1.0×1.2)) |
| 2 | 平时(非子时)internalForcePoints 不受子时加成 | floor(5×1.0×4×1.0×1.0×1.0)=20 |
| 3 | 节气日(立春 2026-02-04 上午 10:00)→ 全产出 ×1.30 | mojianshi 5 / experience 520 / internalForce 26 |
| 4 | 节气日 + 子时叠加(冬至 2026-12-22 23:00)→ 内力维度全乘 | internalForce floor(5×1.0×4×1.0×1.30×1.20)=31 / mojianshi 5(不受子时) |
| 5 | 藏经阁 techniqueLearnRate=1.5 → techniqueLearnPoints 翻 1.5 倍 | floor(0.5×1.5×4×1.3×1.0)=3 |
| 6 | 悬崖瀑布 internalForceGrowth=1.5 → internalForcePoints 翻 1.5 倍 | floor(5×1.5×4×1.69×1.0×1.0)=50 |
| 7 | cap 72h 边界 + 断崖宗师全 buff 不超 999999 红线 | actualHours=72 + internalForce ≈3126 < 999999 |

`test/data/seclusion_map_def_test.dart` 加 2 处 `const RetreatConfig(...)` 构造调用补 5 新参数。

---

## 5. 测试与验证

- `flutter analyze`:**No issues found**(ran in 1.9s)
- `flutter test`:**649/649 All tests passed**(W15 真闭环 643 → +6)
- 子套件 `seclusion_service_test`:27/27 全过(原 16 → +6 新 + 5 个原通用 case)

### 数值边界自查(GDD §5.4 红线 + 直觉合理性)

- 学徒山林 72h cap 无加成:internalForce floor(5×1.0×72×1.0×1.0×1.0)=360(500→860,涨 17%)
- 断崖宗师 72h cap + 节气 + 子时:internalForce floor(5×1.5×72×3.713×1.30×1.20)=3126(15000 红线远内)
- 藏经阁 sanLiu 72h 无加成:techniqueLearn floor(0.5×1.5×72×1.3×1.0)=70(初窥→小成 100,2 次闭关 1 层,合理)
- 极境 6500 progress 即便顶级闭关也需 100+ 天 — 合 GDD「极境=老玩家追求」纪律

---

## 6. 下次开局必读

### 6.1 状态快照

- HEAD 待 push(本会话 2 commits 待落)
- tag `v0.5.3-w15-final` 保留(W15 锚点,#30 不另打 tag)
- 649/649 测试 + analyze 0 issues
- §12 待决:13 → 2(剩 #7 流派 extra_effect / #10 师承遗物规则,#7 阻塞 +1 实装路径)
- Encounter 30 / GDD §8.4 上限达成
- SeclusionService 4 维度全消费(余 1 阻塞:正午阳刚)
- numbers.yaml retreat 加 2 base 字段(unique 锚点,后续不重定义)

### 6.2 开局动作

1. 读 PROGRESS.md「当前阶段」+「下一步」+「挂账事项」
2. 读本 closeout §6 下次开局必读
3. `git pull --rebase --autostash` 看 drift(本会话末态已 push,正常无)

### 6.3 下波候选(优先级排序,§12 §30 收口后基本剩下 Phase 5 主战场)

| 候选 | 模型 | 时长 | 备注 |
|---|---|---|---|
| **A. Phase 5 #2 DDD 目录整理 + 屏 Consumer 化收尾** | **xhigh + 用户拍板** | **3-5h** | **可重新捡回 #28 闭关 widget e2e,Phase 5 主战场起手** |
| B. #34 stage drop 视觉验收 Pen 环境改善 | Codex 派 | 1h | 配 ≥1080 屏 + 库存页快捷入口 |
| C. Pen-only T64 test fail 排查 | sonnet | 30min | `.dart_tool/build` cache stale 推测 |
| D. 真 GUI 截图坐标 helper 封装 | sonnet | 1-2h | Codex §8 教训沉淀 |
| E. techniqueLearnPoints / internalForcePoints 消费层接入 | opus | 2-3h | 主修心法 progress 增长 / Character.internalForce 增长。**需先与用户确认产出节奏与 Demo 体验影响** |
| F. #37 第 3 批挂回(可选) | opus | 1-2h | 剩 8 主题不适配,价值低 |

**推荐起手 A(xhigh + 用户拍板)**:#30 收口后,SeclusionService 数值层基本闭环,Phase 5 #2 DDD 是下个主战场,xhigh 级别需要用户先拍板再开工。或者 E(把 #30 新维度真正落到 Character/Technique 增长上),但需评估 Demo 体验(产出节奏会变)。

### 6.4 硬约束(沿用)

- 不动 GDD.md / numbers.yaml 数值层 / IDS_REGISTRY.md / data_schema.md(本批 #30 属用户拍板例外)
- 不动 data/narratives/ data/lore/ data/events/(DeepSeek 领地)
- Mac 缺 Xcode 跑不了 flutter run -d macos,实战截图派 Pen Codex
- catch 块加 debugPrint / Isar @embedded List 写前 List.of 转 growable
- 不跨 service 嵌套 writeTxn / Dart extension 不与 List.add 同名签名冲突
- preset lore 按需 LoreLoader.load 不写 Isar;Equipment.lores 留延续典故
- 红线测试写「约束语义」不写「瞬时事实」
- closeout 涉及数字必须 grep 实测,加和也要复测
- 派单 spec 的「预期值」必须 grep 派单源头,不能信任中间层 PROGRESS / closeout
- UI 字段读取:实例可与 def 不一致的字段一律读 equipment 实例,def-level 不可变字段读 def
- 视觉验收 FAIL 字段类 1 行 fix → widget test 兜底,不重派 Codex;布局/动画/流程 fix → 必须重派
- Codex 双备份角色(可顶 Mac Opus 也可顶 DeepSeek 文案),默认三方隔离
- Pen GUI 长链路连续导航不稳 → 走「干净启动 → 进 fixture → 截图」
- 节气清单方案 A:公历 hardcode 不引入农历库,代码读 yaml 取月日(忽略年)与当前日比较即可,年际偏差仅 1 天
- **#30 新增**:闭关产出 4 维度全乘 `realmScale × solarBonus`,内力维度额外乘 `ziShiBonus`,新维度只算不写 Isar
- **#30 新增**:技能学习率 / 内力增长率两个乘数都需要 base 锚点(numbers.yaml retreat.base_*_per_hour),若有第 3 个类似维度待接入需走同样模式

---

## 7. 教训沉淀

### 7.1 yaml 字段命名暗示语义

`experience_per_hour: 100` / `mojianshi_per_hour: 1.0` 是 **per_hour 绝对值**;但 `technique_learn_rate: 1.0` / `internal_force_growth: 1.0` 是**乘数**(0.5~1.5)。两套命名混在同一 base_outputs 段下,易让代码层误把乘数当绝对值或反之。本批 #30 暴露了:**前 3 个字段直接走 `def.mojianshiPerHour × hours` 公式,后 2 个字段必须先乘 base 锚点(numbers.yaml 缺锚点 → 公式根本算不出来)**。

教训:**yaml 字段命名应该见名知意**,凡是「乘数」字段名加 `_rate` / `_multiplier` / `_factor` 后缀,「绝对值」字段名加 `_per_hour` / `_per_kill` / `_per_session` 后缀。命名规范统一后,代码层一眼能看出该字段是否需要 base 锚点。

### 7.2 「未来主义」字段易留实装阻塞

闭关地图 yaml 早在 W14-2 就配了 `technique_learn_rate` / `internal_force_growth` / `biome` / `weather`(C 任务 biome/weather 当时落了,但 technique/internal 两维度因为没 base 锚点,实际从未消费)。直到 §12 收口 + #30 才查清。

类似的「预留字段但代码不消费」是技术债,实装时需要回查:
- 字段是否真的有用?(不用 → 删字段或加 `unused: true` 注释)
- 字段是否需要补 base 锚点 / 配套字段?(`technique_learn_rate` 缺 base)
- 字段是否阻塞在其他决策上?(正午加成阻塞 §12.1 #7)

**教训**:**新增 yaml 字段时,在代码层先建消费路径(哪怕是 placeholder + TODO)**,避免一年后再回头查「这个字段有人用吗?」

### 7.3 bug 隐藏在「测试断言数字巧合相同」

原 `_timeDayBonus` 子时×1.2 全产出加成是 bug,但旧测试断言「1h 山林 mojianshi=1」在新语义下仍然过(floor(1.0)=floor(1.2)=1)。改测试时一开始仅改名,跑通了才意识到:**floor 边界 + 小数 × 巧合让 bug 测试同时验证「正确实现」和「错误实现」,断言数字相同根本看不出**。

教训:**测试断言尽量用「能凸显加成倍数」的输入**(4h 而非 1h / mojianshiPerHour=2.0 的断崖而非 1.0 山林),避免 floor 抹平差异。新增 7 个 case 全选「乘数差异显著的输入」体现新公式语义。

---

## 8. memory 候选(本批不写,留下次评估)

- **「yaml 字段命名暗示语义」教训**:有 1 次实例(#30),可考虑后续累计实例后沉淀为通用 feedback
- **「未来主义字段易留实装阻塞」**:本批 + W14-2 + LoreLoader 接入有 3 次实例,可沉淀通用 feedback(留下次再写,避免本批单事件就写)
- **「测试断言数字巧合相同」**:1 次实例,与已有 `feedback_red_line_test_semantics`(W15 #36)同一纪律变体,本批教训可并入或单独沉淀,留下次评估

---

**本 closeout 完。下次会话从 §6 开局动作起步,推荐 A 候选 Phase 5 #2 DDD(xhigh + 用户拍板)起手。**
