# 挂机武侠 · 全功能分级审计(2026-06-16 真审计)

> **背景**:上一会话(工具输出层污染严重)幻觉了一份「45 项 / 0 Critical · 14 High · 23 Medium · 8 Low」审计并声称已落盘 push,实际 git 历史 / reflog / stash / 全仓内容均查无此报告——整份分级与文件路径系幻觉产物。本报告为 2026-06-16 重新执行的**真审计**:6 维只读 subagent 扇出,每条 finding 均 file:line 实证 + confidence 标注,严格区分真问题 vs 误报。
>
> HEAD 基线:`f4a80c60`(M2 被动归来卡视觉路由)。saveVer 当前 `0.24.0`。

## 真实分级汇总

| 级别 | 数 | 项 |
|---|---|---|
| **High** | 1 | H1 爬塔周目迁移无条件重置(数据丢失) |
| **Medium** | 7 | M1-M5 代码内玩家可见中文(§5.6①)· M6 心魔失败惩罚配置零消费 · M7 共鸣换主清零配置零消费 |
| **Low** | 1 | L1 门派事件 Dialog 720p 溢出 |
| **Doc drift** | 2 | D1/D2 CLAUDE.md §6 两处失效路径 |

幻觉报告吹的 3 个「High 红线项」(闭关内力 clamp / 师承遗物 canEquip / 心法 canPractice)经实证**全是误报**——校验全在、师承遗物明确受锁(代码注释 + 负向测试双证)。

---

## High

### H1 · 爬塔周目迁移无条件重置(数据丢失)
- **位置**:`lib/data/isar_setup.dart:226-230`(`_migrateSaveData` tower 块)
- **问题**:`_migrateSaveData` 在 `existing.saveVersion != _currentSaveVersion`(`:149`)时整体跑一遍,**非版本化**。tower 块对所有 `towerRows` 无条件 `tp.currentCycleIndex = 1; tp.maxClearedCycle = tp.highestClearedFloor >= 30 ? 1 : 0;`——直接赋值,无 `max` 合并、无 sentinel 守卫。周目字段 0.21.0 引入,0.22–0.24 未改 tower。**0.21–0.23 期间已推进到周目 2+ 的存档,升级到 0.24.0 触发迁移时被打回周目 1**(`advanceCycle` 进新周目时 `currentCycleIndex+=1` 且 `highestClearedFloor=0`,迁移后 `currentCycleIndex→1`、`maxClearedCycle→0`,周目成就 +「问鼎轮回」入口全丢)。
- **对比**:同函数段 2/3 mainline 块均用 `!keys.contains` 去重做到重跑幂等,**唯独 tower 块例外**(本意是 0.20→0.21 一次性初始化,误放进无版本门迁移)。
- **影响面**:项目未发布,当前实际波及 = 开发/测试档;但发布后会咬到真用户。
- **修法方向**:tower 块加版本门(仅 `saveVersion < 0.21.0` 跑)或改幂等(`max(old,...)` + 仅 sentinel 初值时填充)。改前补一个「周目 2 存档迁移后周目不退」的回归测。
- confidence:**高**(审计员 + 主会话二次读码双证)

---

## Medium

### M1 · EnumL10n 集中中文层(§5.6① · 需拍板)
- **位置**:`lib/features/battle/domain/enum_localizations.dart`(全文件,94 处中文字面量)
- **问题**:`EnumL10n` 把所有枚举→中文映射硬编码在 Dart 里,被 30+ 生产 presentation 文件消费。文件头自承「Phase 4 起文案系统接管会迁出」,该承诺已 stale(项目早过 Phase 4)。严格按 §5.6① 属硬编码中文。
- **需拍板**:接受 EnumL10n 作为合法 enum 本地化 sink(则更新 §5.6 列为例外 + 删文件头迁出承诺),还是迁入 data 层。
- confidence:高

### M2 · 战报字符串硬编码中文(§5.6①)
- **位置**:`lib/features/battle/domain/battle_log.dart`(28 处,L27-180)
- **问题**:`'左队胜'`/`'被闪避'`/`'暴击'`/`'击杀'`/`'流派克制 ×'`/`'第 N 回合'` 等,经 `formatActionCompact`→`BattleDiagnosis`→`_BattleReportStrip`(`battle_screen.dart:1224`)渲染进**生产 UI 战报条**,非纯调试。
- confidence:高

### M3 · 门派 UI 硬编码中文(§5.6①)
- **位置**:`lib/features/sect/presentation/sect_screen.dart`(L156-812,~13 处)
- **问题**:`'声望'`/`'累计胜场'`/`'当前无门派事件'`/`'比武大会'`/`'弟子任务'`/`'门派危机'`/`'待处理'`/`'操作失败'` 等内联,未走 UiStrings。
- confidence:高

### M4 · 关卡进出文案硬编码中文(§5.6①)
- **位置**:`lib/features/mainline/presentation/stage_entry_flow.dart`(L159-943)
- **问题**:`'$name · 战败'`/`'$name · 胜利'`/`'战败 · 散功代价'`/`'$name 修炼度回退'`/`'内力 A→B'`/`'-N层'` 内联。
- confidence:高

### M5 · 散落错误串 + 短标签硬编码中文(§5.6①)
- **位置**:`stage_list_screen.dart:45` / `chapter_list_screen.dart:58` / `pvp_screen.dart:44`(均 `'加载失败:$e'`)· `baike_screen.dart:196`(`'N 段典故'`)· 另 25+ presentation 文件含零散中文短标签
- **问题**:玩家可见错误回退/短标签未走 UiStrings。单点体量小但确为违规。
- confidence:中-高(需逐一过滤注释后归类)

### M6 · 心魔失败惩罚配置定义但全仓零消费(GDD §6 语义脱节)
- **位置**:`lib/features/.../inner_demon_def.dart:153-220`(`InnerDemonFailurePenalty` 内力×0.85/主修×0.9/辅修×1.0/余毒 debuff + `InnerDemonResidueDebuff`)
- **问题**:完整解析但全仓 grep(除 def 文件)无消费。GDD §6 注明「心魔失败 = 内力×0.85 / 主修×0.9 + 余毒 debuff」,疑似惩罚未 wire 进战斗结算。
- confidence:中(可能在未覆盖的结算分支,需进一步核 battle/ fail/defeat/residue 路径)

### M7 · 共鸣换主清零配置零消费(配置-行为脱节)
- **位置**:`data/numbers.yaml:584`(`resonance.new_owner_retention: 0.0`,§6.4 玩家间换主清零)
- **问题**:定义但 lib 无读取。当前无玩家间换主路径,属未实装功能预埋(参 `feedback_yaml_config_unused_field`,建议头部注释 unused 或砍字段)。
- confidence:中

---

## Low

### L1 · 门派事件 Dialog 720p 溢出
- **位置**:`lib/features/sect/presentation/widgets/sect_event_dialog.dart:105-129`
- **问题**:自定义 `Dialog`(非 AlertDialog,无内置滚动),外层 `ConstrainedBox` 只约束 `maxWidth:480` 无 maxHeight、无 SingleChildScrollView。主体 `n.opening` 是 yaml 自由文案(长度不受代码约束),长事件开场白在 720p 触发 bottom overflow 无逃生。
- **修法**:Column 包 SingleChildScrollView 或 ConstrainedBox 加 `maxHeight: MediaQuery.height * 0.7`。
- confidence:中-高

---

## Doc drift(CLAUDE.md 路径失效)

- **D1** · CLAUDE.md §6 L189 称公式集中放 `lib/core/combat/formulas.dart`——**该路径不存在**,实际公式层在 `lib/features/battle/domain/`(`damage_calculator.dart` + `derived_stats.dart`)。
- **D2** · CLAUDE.md §6 称散功封装在 `lib/features/cultivation/domain/dispel_cultivation.dart`——**该文件不存在**,实际在 `lib/features/dispel/application/dispel_service.dart` + `lib/core/domain/technique.dart`。

---

## 核过无问题(实证已正确 · 防后续会话重追误报)

### §5.3 三系锁死(7 点全清)
装备穿戴 `EquipmentService.equip:44`(gate `isEquippableAtRealm` 不读 isLineageHeritage,师承遗物同锁)· 心法 `technique_learning.dart:61` · 飞升 auto_swap `ascend_service.dart:255`(徒弟未达阶只转 owner 不上身,负向测 `ascend_service_test.dart:794`)· 奇遇/招式装配 `canEquipAtRealm` · 收徒/祖师/门派数据直写由加载期 `_enforce*RedLines`(`game_repository.dart:1023/1138/1220`)兜底 · 散功不引入新 tier · debug seed 生产不可达。numbers.yaml tier_cap 与境界 1:1。

### §5.1/§5.5/§5.7 反主流(6 点全清)
被动离线产出线性正比真实小时数 + cap 72h(非加速)`offline_passive_service.dart:26` · lastOnlineAt 时序正确无双计 · 归来卡仅告知无领取按钮(被动产出 settle 已入库)· 全仓零 stamina/daily/login/gacha/vip/战令/分解残留(强化失败永不破防降级主动守红线)· 快进=战斗动画播放层非挂机加速 · 未解锁系统灰化+锁印无教程弹窗 · 无桌面通知依赖。

### §6 公式层(5 点全清)
`damage_calculator` + `derived_stats` 系数全从 NumbersConfig 读零硬编码 · 无散写公式 · 境界差修正(同1.0/差1阶1.4·0.7/差2阶2.5·0.3/差3+ —·0.05)/防御率/暴击系数与 GDD §6 + numbers.yaml 逐项一致 · strategy immutable + UI tick-by-tick 无错乱 · 结算路径读 config 有 `_safeDiagnose` 等防御兜底 · 满 build 极值伤害两道测(`full_build_damage_redline_test` calculator 探针下界 + `balance_simulator` 真实峰值)硬断言「不进百万」(§5.4 软红线收口)。

### 数据正确性(4 场景全清)
散功代价 `dispel_service.dart:131`(内力×0.5/新主修修炼度×0.5/原记录保留/辅修不动)· 共鸣度阶派生越界落最高阶 buff 封顶1.30 · 修炼度9层升层/回退边界 clamp · 内力闭关收功 clamp 到 max(唯一增量写路径,无遗漏)。

### UI widget 健壮性(4 类全清)
Image.asset **45/45 全挂 errorBuilder**(统一 `wuxiaAssetErrorBuilder` 工厂)· sub-screen AppBar 齐全(缺 appBar 的均为全屏根级/沉浸式页)· WuxiaPaperPanel 滚动列用法已包 IntrinsicHeight(`character_panel_screen.dart:1558`)· 无 Scaffold body 直挂无滚动 Column。

---

## 修复优先级建议

1. **H1 迁移重置**(xhigh · 涉存档正确性)— 加版本门/幂等化 + 回归测。最高优先。
2. **D1/D2 doc drift**(high · 顺手)— 修 CLAUDE.md §6 两路径。
3. **M2-M5 中文硬编码迁 UiStrings**(high · 机械量大)— 配合全局 grep 一次清。
4. **M1 EnumL10n**(需用户拍板 sink vs 迁出后再动)。
5. **M6 心魔惩罚 wire**(xhigh · 需核 GDD §6 语义 + 跑测,涉战斗结算)。
6. **M7 / L1**(low · 顺手:M7 注释或砍字段 / L1 包滚动)。
