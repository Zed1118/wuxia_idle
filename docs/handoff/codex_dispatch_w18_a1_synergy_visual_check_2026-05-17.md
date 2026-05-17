# Codex 桌面 @ Pen 视觉验收派单 · W18-A1 心法相生 5 组合(2026-05-17)

> 派单方:Mac Opus(zhangpeng.12334@gmail.com)
> 执行方:Codex 桌面 @ Pen Windows
> 沟通契约:Codex 全程不联系派单方,只在 closeout 报回。探路失败也有价值,不要硬撑。

---

## 0. 必读清单(顺序)

1. **本派单**
2. **`docs/handoff/codex_w17_lineage_panel_visual_check_2026-05-17.md`**(W17 上一轮 Pen 工具链 closeout,沿用 build/截图工具链)
3. `PROGRESS.md`(W18 当前阶段 - A1 心法相生 0→1 全链闭环)
4. `lib/data/defs/synergy_def.dart` + `data/synergies.yaml`(5 组合定义)
5. `lib/features/cultivation/application/synergy_service.dart`(detectActive 优先级:schoolPair > sameSchool > sameTier)
6. `lib/features/character_panel/presentation/character_panel_screen.dart` 660-744(`_SynergyChip` 实装)
7. `lib/features/battle/application/stage_battle_setup.dart` 120-180(`_applySynergy` 4 字段注入)
8. `lib/features/debug/application/phase2_seed_service.dart` `seedVisualCheckW18A1` doc-comment 配对表

---

## 1. 任务一句话

**Phase2 → VC18-A1 按钮 → CharacterPanelScreen,5 Tab 切 5 角色截 5 张 chip;再进 stage_01_05 战斗截 1 张 BattleScreen 验 HpBar maxHp 数字注入(A·阴阳 +20% vs B/C 基线)。**

W18-A1 心法相生 5 组合 (yaml/service/UI chip/战斗注入) 已 812/812 + analyze 0 收口(commit `a752c7d`),本批 fixture `seedVisualCheckW18A1` 已 push(commit `4899693`,817/817)。本派单为 GUI 视觉层验收 chip 显示 + 战斗注入字段在 BattleScreen 上的可视效果。

---

## 2. 验收对象 · `_SynergyChip` + StageBattleSetup 注入

### 2.1 `_SynergyChip` UI(`character_panel_screen.dart:667-744`)

主修 + 第 1 辅修双 `techniqueByIdProvider` watch ready 后,调 `SynergyService.detectActive`。命中即显:

```
┌─────────────────────────────────────────────────┐
│ ⚡ 相生  阴阳调和 · 攻 +10% 速 +10% 血 +20%      │
└─────────────────────────────────────────────────┘
```

- 金边卡片(`WuxiaColors.resultHighlight` 0.6 alpha border)
- 左侧 `Icons.auto_awesome` 14px
- label「相生」(`UiStrings.synergyActiveLabel`,resultHighlight 色 / 12px / w600)
- 内容「{synergy.name} · {synergy.multipliers.summary()}」(textPrimary / 12.5px)
- 未命中(0 个)时返回 `SizedBox.shrink()` — 不显空容器

### 2.2 `_applySynergy` 战斗注入(`stage_battle_setup.dart:158-180`)

命中相生 → `BattleCharacter.copyWith` 调 4 字段:
- `maxHp` ← `base.maxHp × (1 + hpPct)`
- `speed` ← `base.speed × (1 + speedPct)`
- `totalEquipmentAttack` ← `base.totalEquipmentAttack × (1 + attackPct)`
- `maxInternalForce` ← `base.maxInternalForce × (1 + internalForceMaxPct)`,cap ≤ 15000

**defensePct / internalForceGrowthPct 2 字段当前 W18-A1 不消费**(下批 W18-A1.2 接 damage_calculator / seclusion-growth hook)。`summary()` 文案可能含「防 +X%」「内力增长 +X%」字段,但本批战斗实测不生效 — 已在 yaml 注释锚定。

### 2.3 fixture 5 角色配对(`phase2_seed_service.dart` seedVisualCheckW18A1 doc-comment 表)

| Tab# | 角色名     | main tech              | assist tech            | 命中 SynergyDef.id          | summary() 文案预期                              |
|------|------------|------------------------|------------------------|-----------------------------|-------------------------------------------------|
| 1    | A·阴阳     | tech_gangmeng_mingjia  | tech_yinrou_mingjia    | synergy_yin_yang_he_xie     | 攻 +10% 速 +10% 血 +20%                         |
| 2    | B·刚柔     | tech_gangmeng_mingjia  | tech_lingqiao_mingjia  | synergy_gang_rou_bing_ji    | 速 +25%                                         |
| 3    | C·阴影     | tech_yinrou_mingjia    | tech_lingqiao_mingjia  | synergy_yin_ying_xun_jie    | 攻 +15% 速 +15%                                 |
| 4    | D·同流派   | tech_yinrou_mingjia    | tech_yinrou_changlian  | synergy_tong_pai_jing_jin   | 攻 +20%                                         |
| 5    | E·同辈     | tech_lingqiao_mingjia  | tech_yinrou_mingjia    | synergy_tong_bei_hu_bu      | 内力上限 +25%                                   |

注:summary() 实际格式以 `SynergyMultipliers.summary()` 实装为准(本派单允许字段顺序/单位/连接符微差异,但**字段类型必须命中**)。

5 角色全 **一流·启蒙**(equipment cap=liQi tier 4 / technique cap=menPaiJueXue tier 4),无装备(GDD §5.3 三系锁死避漂移),物料 100 磨剑石 + 10 心血结晶,Ch1 01-04 已 cleared 直挑 stage_01_05。

---

## 3. 工具链 · seed + chip + 战斗注入截图

### 3.1 步骤

```
1. cd F:\Projects\wuxia_idle && git pull
   → 拉到 commit 4899693 或更新
2. flutter clean
   (避增量 build 缓存假象坑,memory feedback_codex_pen_windows_visual_check W16 round2 教训)
3. dart run build_runner build --delete-conflicting-outputs
   (本批未新增 @riverpod provider,但 W17 已有 lineage_info_provider.g.dart;
    clean 后必须重生 — wuxia_idle .g.dart 全 gitignored)
4. flutter build windows --debug
5. 启动 build\windows\x64\runner\Debug\wuxia_idle.exe

【截图 01 · Phase2TestMenu 13 按钮全景】
6. 主菜单 → tap「Phase 2 调试场景」按钮
   → Phase2TestMenu 完全加载,**滚到底部**让「VC18-A1 · 心法相生 5 组合视觉验收预设」按钮可见
   → 截全屏
   → 验收:13 按钮可见(VC18-A1 在 VC15-fresh 之后、DEBUG · 切今日节日 之前)
   → 文件名:w18_a1_phase2menu_13buttons.png

【截图 02-06 · 5 角色 chip(每 Tab 1 张)】
7. Phase2TestMenu → tap「VC18-A1 · 心法相生 5 组合视觉验收预设」按钮
   → SnackBar 显「种子加载中…」或直接 push CharacterPanelScreen
   → 默认进入 Tab 1(A·阴阳),CharacterPanelScreen 完全加载
8. 滚动 _Body SingleChildScrollView 到底部确认 _SynergyChip 可见(主修+辅修 tile 后)
   → 截全屏 → 文件名:w18_a1_chip_01_yinyang.png(A·阴阳,组合 1 阴阳调和)

9. tap Tab 2「大弟子」(B·刚柔)
   → 等 chip 渲染完成
   → 截全屏 → 文件名:w18_a1_chip_02_gangrou.png(B·刚柔,组合 2 刚柔并济)

10. tap Tab 3「二弟子」(C·阴影)
    → 截全屏 → 文件名:w18_a1_chip_03_yinying.png(C·阴影,组合 3 阴影迅捷)

11. tap Tab 4「三弟子」(D·同流派)
    → 截全屏 → 文件名:w18_a1_chip_04_tongpai.png(D·同流派,组合 4 同流派精进)

12. tap Tab 5「四弟子」(E·同辈)
    → 截全屏 → 文件名:w18_a1_chip_05_tongbei.png(E·同辈,组合 5 同辈互补)

【截图 07 · stage_01_05 BattleScreen 注入对照】
13. tap AppBar 返回箭头 → 回 Phase2TestMenu → tap AppBar 返回 → 回主菜单
14. 主菜单 → tap「主线」按钮 → 主线关卡列表
    → 等 stage_01_05 可见(Ch1 01-04 已 cleared,stage_01_05 应解锁,memory
       feedback_codex_pen_windows_visual_check W7-W11 实战路径)
15. tap stage_01_05 → 进 BattleScreen
    → 等战斗 init 完成(玩家方 3 角色入场,槽位 1=A·阴阳 / 2=B·刚柔 / 3=C·阴影,
       按 activeCharacterIds 前 3 进队)
    → 截全屏(尽量在 HP 还满 / 战斗刚启动时 — 数字最清)
    → 验收:A·阴阳 HpBar `current/max` max 数字应明显大于 B·刚柔 / C·阴影
       (hpPct=0.20 → A maxHp ≈ B/C × 1.2)
    → 文件名:w18_a1_battle_stage_01_05_injection.png
```

### 3.2 截图清单(7 张)

| # | 文件名 | 内容 | 必需 |
|---|---|---|---|
| 01 | `w18_a1_phase2menu_13buttons.png` | Phase2TestMenu 13 按钮全景,VC18-A1 位置 | ✓ |
| 02 | `w18_a1_chip_01_yinyang.png` | Tab 1 A·阴阳 chip(组合 1 阴阳调和) | ✓ |
| 03 | `w18_a1_chip_02_gangrou.png` | Tab 2 B·刚柔 chip(组合 2 刚柔并济) | ✓ |
| 04 | `w18_a1_chip_03_yinying.png` | Tab 3 C·阴影 chip(组合 3 阴影迅捷) | ✓ |
| 05 | `w18_a1_chip_04_tongpai.png` | Tab 4 D·同流派 chip(组合 4 同流派精进) | ✓ |
| 06 | `w18_a1_chip_05_tongbei.png` | Tab 5 E·同辈 chip(组合 5 同辈互补) | ✓ |
| 07 | `w18_a1_battle_stage_01_05_injection.png` | BattleScreen 玩家方 3 角色 HpBar,A 数字 > B/C ~20% | ✓ |

每张截图建议尺寸 ≥ 1280×900,全屏即可。

---

## 4. 验收点(每张截图自检)

### 4.1 Phase2TestMenu 13 按钮(01)

- [ ] 13 按钮全部可见(滚动到底也算 PASS)
- [ ] VC18-A1 按钮在「VC15-fresh」之后、「DEBUG · 切今日节日」之前
- [ ] 按钮 label「VC18-A1 · 心法相生 5 组合视觉验收预设」+ hint「5 角色一流·启蒙 + main/assist 配对覆盖 5 相生组合各 1 命中,切 Tab 看 chip + 进 stage_01_05 看 HpBar/内力条数字注入」
- [ ] 按钮样式与其他 12 按钮一致

### 4.2 chip 5 张(02-06)

每张通用验收:
- [ ] AppBar「角色面板」可见,左侧 BackButton 可见
- [ ] TabBar 5 个 Tab(祖师 / 大弟子 / 二弟子 / 三弟子 / 四弟子)可见,当前 Tab 高亮
- [ ] 主修 tile + 3 个辅修 tile(2/3 个为空状态)可见
- [ ] **关键** `_SynergyChip` 在 4 辅修 tile Row 下方可见:
  - 金边卡片(borderRadius 4,resultHighlight 色 0.6 alpha border)
  - ⚡ 图标 + 「相生」label(resultHighlight 色)
  - 「{组合名} · {summary()}」文案(textPrimary)
- [ ] 中文渲染无方框 / 缺字

每张专项(对照 §2.3 表):
- **02 A·阴阳**:文案含「阴阳调和」+ 至少 1 个 buff 字段
- **03 B·刚柔**:文案含「刚柔并济」
- **04 C·阴影**:文案含「阴影迅捷」
- **05 D·同流派**:文案含「同流派精进」
- **06 E·同辈**:文案含「同辈互补」

**重要**:`summary()` 文案字段实际包含哪些 buff 由 `SynergyMultipliers.summary()` 实装决定。本批 W18-A1 不消费的字段(defensePct / internalForceGrowthPct)yaml 已删,summary 输出应只含 4 个生效字段。验收**不要求数字精确**,只要求**组合名命中**。

### 4.3 BattleScreen 注入对照(07,1 张)

- [ ] BattleScreen 完全加载(顶部状态栏 + 6 个 CharacterAvatar 3v3)
- [ ] 玩家方(左队)3 角色 HpBar 可见,带 `current/max` 数字
- [ ] **关键**:A·阴阳(左队槽位 1)HpBar 的 max 数字**明显大于** B·刚柔(槽位 2)/ C·阴影(槽位 3)的 max 数字
  - 理论 ratio:A ≈ B × 1.20(hpPct 0.20)
  - B 与 C 的 max 数字应**相等或几乎相等**(都无 hpPct;基础属性同 const=6 同境界)
  - 容差:A:(B/C) 比值在 1.15 ~ 1.25 之间 PASS
- [ ] 中文渲染无方框

**若 A:B 比值 ≈ 1.0(注入未生效)→ FAIL,closeout 中标记** + 附 BattleScreen 截图作反证据。

### 4.4 风格统一(对照 W15-fresh / P5 截图体例)

- [ ] CharacterPanelScreen TabBar 视觉与 W17 lineage panel / W15-fresh 截图一致
- [ ] BattleScreen 与 W11 / W15 victory dialog 截图视觉一致

---

## 5. 已知风险 / 踩坑提醒

- **`flutter clean → 必须先 dart run build_runner build`**(W16 round2 + W17 chuXi/qingMingJie 沉淀,memory feedback_codex_pen_windows_visual_check):wuxia_idle `*.g.dart` 全 gitignored,clean 后必须 `dart run build_runner build --delete-conflicting-outputs` 重生,否则 isar codegen 缺失 build 失败。
- **TabBar 5 Tab 横向排版**(`_LineageTabBar` Row+Expanded 等分):1280 宽下 5 Tab 每个约 256px,字号 14px,「四弟子」「三弟子」3 字应不溢出。**若任一 Tab 文字截断或换行,记 WARN**(本批 fixture 决定的 5 Tab + 既有 _LineageTabBar 实装妥协);Mac 端可后续给 fixture 角色更短 name 或改 TabBar 为 scrollable。
- **chip 隐藏 vs 显示**:`_SynergyChip` 双 watch `mainAsync` + `assistAsync`,任一未 ready 即返 `SizedBox.shrink()`。VC18-A1 seed 一次性写 Isar 完成后 push 屏,首帧 watch 同步命中,**chip 应直接显**;若首次进 Tab chip 不显,**切回 Tab 1 再切回观察**或 pumpAndSettle(rebuild)再截。
- **stage_01_05 平衡 drift**(挂账 #33,W7-W11 closeout 沉淀):本派单**不验战斗输赢**,只截 BattleScreen init 帧看 HpBar max 数字。胜负不重要,截图后可直接退出战斗(AppBar 返回 / 系统按钮)。
- **`summary()` 实装格式未锁死字符串**:验收只要求**组合名命中**(「阴阳调和」/「刚柔并济」/「阴影迅捷」/「同流派精进」/「同辈互补」5 个中文名),不要求数字百分比精确。若文案与 §2.3 表预期偏差大,closeout 中**贴实际文案**,Mac 端来判断是否需要修。
- **A·阴阳 占 id=1 与既有体例一致**:CharacterPanelScreen `_defaultCharacterId=1`,push 后首屏默认 Tab 1 = A·阴阳,无需手动切。

---

## 6. closeout 格式(沿 W17 体例)

Codex 提交 closeout 文档 `docs/handoff/codex_w18_a1_synergy_visual_check_2026-05-17.md`,包含:

1. **环境快照**:HEAD SHA / build 命令 / 截图工具版本
2. **7 张截图**(命名见 §3.2,放 `docs/screenshots/w18/` 目录)
3. **每张截图 PASS/WARN/FAIL** + 一句话原因
4. **5 chip summary() 实际文案表**(对照 §2.3 预期,贴实际字符串)
5. **战斗注入 max HP 实测数字**(A / B / C 三角色 HpBar max 数字 + A:B 比值)
6. **总结**:N PASS / M WARN / K FAIL
7. **已知偏差**:任何 Tab 文字截断 / chip 不显 / 战斗注入未生效 / summary 文案大偏离
8. **commit + push** 截图 + closeout 到 origin/main

---

## 7. 硬约束

- 不动 `lib/` 任何 Dart 代码(Codex 只跑 + 截图)
- 不动 `data/` 任何文件
- 不动 `GDD.md` / `CLAUDE.md` / `PROGRESS.md` / `IDS_REGISTRY.md`
- 若发现 bug → closeout 中报告,Mac 端来修(不要自己改代码)
- `dart run build_runner build` 仅本地重生 `.g.dart`(gitignored),**不要 commit codegen 产物**
- 不 push 到非 main 分支 / 不 merge / 不 tag

---

## 8. 与其他派单并行性说明

本派单**独立**,无并行依赖。W17 候选 E LineagePanelScreen 已收口 + W17 nightshift 6 task 全合并(详 PROGRESS.md)。W18-A2 武学领悟 16→20 触发条件 + A1 心法相生 5 组合 yaml/service/UI/战斗 全链 Mac 端已完成。本派单为 W18-A1 GUI 视觉收口。

---

**派单文档结束。Codex 接单后如有需要澄清,请在 closeout 文档中报告**(本协作流程通过 GitHub 主分支 commit 同步,沿用 W16/W17 体例)。
