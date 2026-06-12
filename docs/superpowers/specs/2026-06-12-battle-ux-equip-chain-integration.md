# 整合方案 · 战斗指令台 + 装备/藏经阁操作链路

> 日期:2026-06-12 · 阶段:1.0 长线打磨期 · 模型:opus xhigh
> 来源:桌面方案文档1(战斗UI+操作链路)+ 文档2(玩法创新10点),经 Phase 0 三路核实(战斗/装备/藏经阁)。
> 核实结论:文档1 现状描述几乎全真,仅两处勘误(见下)。文档2 属大 feature,本批不纳入。

## 0. 范围三分(关键决策)

文档内容天然分三类,本方案**只生产第一类**:

| 类别 | 内容 | 是否本批 | 理由 |
|---|---|---|---|
| **A 纯 UX/操作链路** | 战斗指令台(暴露全槽+状态)、蓄力危险条、战报3条、换招弹窗文案玩家化、槽位说明、武学库直接装配、残页来源、装备入口前移、divider 纯绘制、角色面板快捷操作、仓库筛选、物料用途 | ✅ **本批生产** | 零战斗数值改动、零产品方向改动、全复用现有 service、可逆、低风险,正是"可落地"子集 |
| **B 半手动战斗** | `BattleControlMode`、`requestManualSkill`、`advance()` 单步语义、手动选目标 | ❌ 待拍板 | 是"挂机 vs 手动参与"的产品方向拍板点,且是真 domain 工程(Phase 0 证实这些都不存在)。须用户先定方向 |
| **C 玩法进化** | 文档2 全部(江湖记招/问鼎轮回/编年史/传闻/诊断帖…) | ❌ 待拍板 | 大 feature,各需独立 spec+TDD。其中"江湖记招/问鼎轮回"还依赖 B 的手动战斗方向 |

> B 和 C 进 backlog(待拍板类,符合 §7 backlog 原则),不在本批硬实装。

## 1. Phase 0 勘误(两处,已据此调整)

1. **半手动相关全不存在**:`BattleControlMode` / `requestManualSkill` 均无;`request_manual_skill_test.dart` 实为 `requestUltimate()` 的别名测试。→ 半手动归入待拍板类 B,不混进本批。
2. **`ink_divider.png` 资源完好**(330K、已注册):所谓"小白块"非资源缺失,而是 330K 大图缩到 `height:8` 的渲染不确定性。→ T9 改纯 Flutter 绘制,定位为"消除不确定性",非修 bug。

## 2. 本批任务清单(全 P0 · 零数值改动 · 复用现有 service)

### 战斗指令台(阶段A,不改 domain,只读+走现有 requestUltimate)

- **T1 指令台升级** `battle_screen.dart` `_BottomBar`(:1168)
  现状只暴露大招/破招两类按钮 → 改为"重点角色指令台":展示该角色 `availableSkills`(:110)分组按钮(强力/破招/共鸣/大招),每按钮带 内力消耗/CD/pending/可破招 状态;点头像切重点角色;敌人蓄力时重点角色自动切到可破招者。点击仍调 `requestUltimate()`。
- **T2 蓄力危险条 + 可破招高亮** 只读 `rightTeam.chargingSkill/chargeTicksRemaining` → 顶部危险条"X 正在蓄势:招名 N" + 可破招我方头像发亮。
- **T3 最近战报3条** 底部常驻最近 3 条关键战报(大招/破招/蓄势/击杀/暴击/战败),点开复用 `_LogDrawer`(:859)。
- **T-feedback 待发印** 点击只 pending 的技能后,按钮盖"待发"印,区分"已排队下次行动"vs"立即释放"。(并入 T1)

### 藏经阁

- **T4 换招弹窗文案玩家化** `skill_slot_picker.dart` `'tier ${skill.tier}'`(:83-84)→ 阶位中文(走 `EnumL10n`/UiStrings);`'倍率 $power'`(:147)→ `伤害 N`;可打断加`可破招`、群攻加`群攻`、高耗加`高内力`。【最明确毛刺,第一刀】
- **T5 槽位用途说明** `cangjingge_screen.dart` 7 槽各加一行短说明,新增文案走 `UiStrings`(strings.dart:1091+ 体例)。
- **T6 武学库招式行直接装配** `skill_proficiency_row.dart`(现纯展示)加点击/尾按钮 → "装到哪个槽"小面板(按招式类型只显合法槽)→ 落库走 `SkillLoadoutService.equipSkill()`(sealed result 校验不绕过)。第一版覆盖主修/辅修/大招/破招。
- **T7 残页来源提示** `fragment_progress_row.dart` 纯 UI 派生:从 `SkillDef.source` + stages/towers.yaml `dropSkillFragmentId` 映射出"主线第N章/爬塔第N层/奇遇/来源未明"。无来源数据则显"来源未明",不硬写。

### 装备链路

- **T8 装备详情入口前移** `equipment_detail_screen.dart` 信息卡首屏加`强化 +N`/`开锋 X/3`按钮,复用 `_openEnhance(0/1)`;底部 `_ActionBar`(:143)降为窄屏兜底保留。
- **T9 `_SegmentDivider` 纯绘制**(:600-631)改横向细线+中央点线,去 `ink_divider.png` 依赖。
- **T10 角色面板快捷操作** `character_panel_screen.dart` `_tappableSlot()`(:835):空槽→`_EquipPickerSheet`;已穿装备→快捷 sheet(更换/强化/开锋/查看典故/卸下),强化开锋复用 `EnhanceDialog(initialTab)`,卸下走 `EquipmentService.unequip()`。
- **T11 仓库筛选条** `inventory_screen.dart` 装备 Tab 顶部加筛选(全部/可装备/已穿戴/可强化/可开锋/境界未达),第一版 UI 层过滤;境界锁文案改具体原因(`需一流境界`)。
- **T12 物料页用途说明** `_MaterialRow`(:395)加用途(磨剑石=强化/心血结晶=强化保底·开锋),可选反向跳转到对应筛选。

## 3. 硬约束(红线)

- 不改战斗数值公式 / 不破 §5.4 红线 / 不改 numbers.yaml。
- 不硬编码中文文案(全走 `UiStrings`)/ 不硬编码数值。
- 不绕过现有 service 校验(equip/unequip/equipSkill/enhance)。
- 不删现有入口(详情页/picker/_ActionBar 保留,只新增快捷入口)。
- 不引入新状态管理库 / 新游戏引擎。
- TDD:能写 widget/单测先红后绿;每任务 analyze 0 + 全量 test 不退。
- 1280×720 不溢出(指令台按钮数量按最低分辨率实测,memory feedback_visual_size_min_resolution)。

## 4. 实施顺序(分批,避免一次改太散)

1. **批一(藏经阁,最低风险先行)**:T4 → T5 → T7 → T6
2. **批二(装备链路)**:T9 → T8 → T10 → T12 → T11
3. **批三(战斗指令台,UI 改动最大)**:T2 → T3 → T1
每批跑全量 test + analyze;视觉项(T1/T8/T10)合 main 前派 Codex 截图验收(memory feedback_codex_visual_loop_claude_gate)。

## 5. 验收总清单

T4 换招弹窗无 `tier`/`倍率` 开发文案 · T5 每槽有用途 · T6 武学库行可直接装配且走 service · T7 残页有来源方向或"来源未明" · T8 详情首屏见强化/开锋 · T9 典故区无小白块/无图依赖 · T10 角色面板点已穿装备出快捷面板、2 击内进强化 · T11 仓库可按状态筛选+锁显具体原因 · T12 物料解释用途 · T1-3 指令台暴露全槽+状态+蓄力危险条+战报3条,不改任何战斗结果测试,1280×720 不溢出。
