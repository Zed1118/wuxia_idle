# Codex 桌面 @ Pen 视觉验收派单 · W17 候选 E LineagePanelScreen 师徒名单(2026-05-17)

> 派单方:Mac Opus(zhangpeng.12334@gmail.com)
> 执行方:Codex 桌面 @ Pen Windows
> 沟通契约:Codex 全程不联系派单方,只在 closeout 报回。探路失败也有价值,不要硬撑。

---

## 0. 必读清单(顺序)

1. **本派单**
2. **`docs/handoff/codex_w17_festival_chip_extend_visual_check_2026-05-17.md`**(W17 前一轮 Pen 工具链 closeout,沿用 build/截图工具链)
3. `PROGRESS.md`(W17 当前阶段 - 候选 E LineagePanelScreen 实装)
4. `lib/features/character_panel/presentation/lineage_panel_screen.dart`(本轮验收对象,W17 候选 E 新增)
5. `lib/features/character_panel/application/lineage_info_provider.dart`(view model + 派生 provider)
6. `lib/features/main_menu/presentation/main_menu.dart`(主菜单 9 按钮 W17 新增「师徒名单」)

---

## 1. 任务一句话

**主菜单进「师徒名单」按钮 → LineagePanelScreen → 空态/完整态各截一图;再加 1 张主菜单 9 按钮全景图证明入口接入。**

W17 候选 E LineagePanelScreen 已 764/764 + analyze 0 收口(commit `9dcfe8a`),本派单为 GUI 视觉层验收师徒名单全局关系视图 sub-screen 3 段(祖师 chip / 弟子 chip 列表 / 师承遗物 row 列表)的显示效果 + 主菜单按钮接入位置。

---

## 2. 验收对象 · LineagePanelScreen 3 段

代码:`lib/features/character_panel/presentation/lineage_panel_screen.dart`(W17 候选 E 新增)。

### 2.1 屏幕结构

```
Scaffold
├─ AppBar(title: "师徒名单", leading: BackButton)
└─ body: SingleChildScrollView
    ├─ Section 1 (_PanelCard): _SectionTitle("祖师")
    │   └─ _CharacterChip(founder) 或 _EmptyText("祖师未定")
    ├─ Section 2 (_PanelCard): _SectionTitle("弟子")
    │   └─ List<_CharacterChip(disciple)> 或 _EmptyText("尚无弟子")
    └─ Section 3 (_PanelCard): _SectionTitle("师承遗物") + 右上「N 件」计数
        └─ List<_HeritageRow(equipment)> 或 _EmptyText("尚未拥有师承遗物")
```

### 2.2 _CharacterChip 设计语言

- `WuxiaColors.avatarFill` 背景 + `WuxiaColors.border` 细描边 + `borderRadius: 4`
- 左侧 4 × 28 流派色条(`WuxiaColors.schoolColor(character.school!)`)
- 中部 Column:角色 name(15px / w600 / textPrimary)+ `EnumL10n.realm(realmTier, realmLayer)` 12px 灰
- padding 10,横向 Row 布局

### 2.3 _HeritageRow 设计语言

- 6×6 tier color dot(`tierColorForEquipment(tier)`)
- 装备名(13px / textPrimary,GameRepository 解析失败 fallback 到 defId 字符串)
- enhance level > 0 时右侧显「+N」(12px / w600 / tier color)

### 2.4 师承遗物计数

- 段标题 Row mainAxis spaceBetween:左「师承遗物」标题,右「N 件」文字(12px / textMuted)
- equipments.isEmpty 时不显计数,仅显空态文案「尚未拥有师承遗物」

---

## 3. 工具链 · 用 Phase2 P5 师徒种子 seed 数据

**关键**:LineagePanelScreen 经 `lineageInfoProvider` 派生 Isar(`activeCharacterIdsProvider` + `allEquipmentsProvider`),需要 seed 数据才能看完整态。

### 3.1 步骤

```
1. flutter clean  (避增量 build 缓存假象坑 - W16 round2 教训沉淀,memory feedback_codex_pen_windows_visual_check)
2. dart run build_runner build  (W17 候选 E 新增 lineage_info_provider.g.dart,clean 后必须重生)
3. flutter build windows --debug
4. 启动 build\windows\x64\runner\Debug\wuxia_idle.exe

【截图 01 · 主菜单 9 按钮全景(证明入口接入)】
5. 主菜单完全加载后 → 截全屏
   → 验收:9 按钮可见,顺序「主线 / 问鼎九霄 / 闭关修炼 / Phase1 / Phase2 / 角色面板 / 师徒名单 / 装备仓库 / 心法面板」
   → 文件名:w17_lineage_main_menu_9buttons.png

【截图 02 · 空态(无 seed)】
6. 主菜单 → tap「师徒名单」按钮 → 进 LineagePanelScreen
   → 应显:AppBar「师徒名单」+ 3 段全空态(「祖师未定」/「尚无弟子」/「尚未拥有师承遗物」)
   → 截全屏
   → 文件名:w17_lineage_panel_empty.png

【截图 03 · 完整态(P5 师徒种子后)】
7. tap AppBar 返回箭头 → 回主菜单 → tap「Phase 2 调试场景」按钮 → Phase2TestMenu
8. tap「P5 · 师徒种子」按钮 → SnackBar 提示 seed 完成 → 等 SnackBar 消失
9. tap AppBar 返回箭头 → 回主菜单 → tap「师徒名单」按钮 → 进 LineagePanelScreen
   → 应显:
     · 祖师段:1 个 chip(祖师姓名 + 一流·X 层 + 流派色条)
     · 弟子段:2 个 chip(大弟子姓名 + 二流·X 层 / 二弟子姓名 + 三流·X 层)
     · 师承遗物段:右上「1 件」(或 2 件,看 P5 fixture)+ 1-2 行 _HeritageRow(tier color dot + 装备名)
   → 截全屏
   → 文件名:w17_lineage_panel_full_after_p5.png
```

### 3.2 截图清单(3 张)

| # | 文件名建议 | 内容 | 必需 |
|---|---|---|---|
| 01 | `w17_lineage_main_menu_9buttons.png` | 主菜单 9 按钮全景 + 「师徒名单」按钮位置 | ✓ |
| 02 | `w17_lineage_panel_empty.png` | LineagePanelScreen 全空态(无 seed) | ✓ |
| 03 | `w17_lineage_panel_full_after_p5.png` | LineagePanelScreen 完整态(P5 后:祖师 + 2 弟子 + N 件 heritage) | ✓ |

每张截图建议尺寸 ≥ 1280×900,全屏即可。

---

## 4. 验收点(每张截图自检)

### 4.1 主菜单 9 按钮(01,1 张)

- [ ] 9 按钮全部可见,无溢出
- [ ] 顺序:主线 / 问鼎九霄 / 闭关修炼 / Phase1 / Phase2 / 角色面板 / **师徒名单** / 装备仓库 / 心法面板
- [ ] 「师徒名单」按钮在「角色面板」之后、「装备仓库」之前
- [ ] 按钮 label「师徒名单」+ hint「查看祖师与弟子的传承链路」
- [ ] 按钮样式与其他 8 按钮一致(`WuxiaColors.panel` 背景 + `WuxiaColors.border` 描边 + borderRadius: 8 + 16px label / 12px hint)

### 4.2 空态(02,1 张)

- [ ] AppBar 标题「师徒名单」可见,左侧 BackButton 可见
- [ ] 3 段 _PanelCard 可见,各自带 _SectionTitle
- [ ] Section 1「祖师」标题下显「祖师未定」灰色文案(13px / textMuted)
- [ ] Section 2「弟子」标题下显「尚无弟子」灰色文案
- [ ] Section 3「师承遗物」标题下显「尚未拥有师承遗物」灰色文案,右上**无**「N 件」计数(空时不显)
- [ ] 各段间距 16px 一致
- [ ] 中文渲染无方框 / 缺字

### 4.3 完整态(03,1 张)

- [ ] AppBar 标题「师徒名单」可见
- [ ] Section 1「祖师」段:1 个 _CharacterChip(姓名 + 境界,左侧流派色条)
- [ ] Section 2「弟子」段:2 个 _CharacterChip(大弟子 + 二弟子),chip 间 8px 间距
- [ ] 3 个 chip 视觉一致(背景 / 描边 / 流派色条 / 字号)
- [ ] Section 3「师承遗物」段:右上「N 件」计数文字(12px 灰),N ≥ 1
- [ ] 每行 _HeritageRow:左侧 6×6 tier color dot + 装备名(中文,如「**山河剑**」)
- [ ] enhance level > 0 的装备右侧显「+N」(tier 颜色,12px / w600)
- [ ] 装备名渲染正常(GameRepository.equipmentDefs 解析到真实中文名;若显 raw defId 如「sword_xxx」说明 GameRepository 未 load 异常,记 WARN)
- [ ] 中文渲染无方框 / 缺字 / 字体回退

### 4.4 风格统一(对照 character_panel_screen 现有 _LineageSection)

- [ ] _PanelCard 视觉与 CharacterPanelScreen 内 _PanelCard 一致
- [ ] _SectionTitle 字号 / 字重 / 颜色一致(14px / w600 / textPrimary)
- [ ] _CharacterChip 与 character_panel _TopBar 流派色条样式同源

---

## 5. 已知风险 / 踩坑提醒

- **flutter clean → 必须先 dart run build_runner build**(W16 round2 + W17 chuXi/qingMingJie 沉淀):本派单新增 `lineage_info_provider.g.dart` 同样 gitignored,clean 后必须 `dart run build_runner build` 重生,否则 `lineageInfoProvider` 引用不到 codegen 同步报错。
- **P5 师徒种子按钮**:Phase2TestMenu 内,代码 `lib/features/debug/presentation/phase2_test_menu.dart` 内 `scenarioP5` 按钮(label「P5 · 师徒种子」)。tap 后会 seed 3 角色 + activeCharacterIds 设置 + 启动装备/心法,与现有 W14 / W16 视觉验收路径相同。
- **AppBar 返回箭头**:LineagePanelScreen 显式写 `Navigator.canPop() ? BackButton(...) : null`(`feedback_flutter_subscreen_appbar_audit` 必检项),push 来的页面必有 back。
- **GameRepository.equipmentDefs 名字解析**:`_HeritageRow._resolveName()` 兜底走 `GameRepository.isLoaded ? equipmentDefs[defId]?.name : defId`,Windows 启动正常应 load 后能解析真实中文装备名。若显 raw defId 字符串说明启动期 GameRepository 未 load 完成,记 WARN(非 FAIL,fallback 设计已护栏)。
- **空态字数判断**:Section 3「师承遗物」段空时**不显**「N 件」计数(代码 `if (equipments.isNotEmpty) Text(count)`),只显空态文案。验收点 4.2 已锚定。
- **scroll 行为**:Demo 阶段 founder + 2 disciples + 1-2 件 heritage,LineagePanelScreen 内容应单屏可容,SingleChildScrollView 不需要滚动。若实际需要滚动(heritage > 5 件)截图标注 + 按 PASS 处理。

---

## 6. closeout 格式(沿 W17 体例)

Codex 提交 closeout 文档 `docs/handoff/codex_w17_lineage_panel_visual_check_2026-05-17.md`,包含:

1. **环境快照**:HEAD SHA / build 命令 / 截图工具版本
2. **3 张截图**(命名见 §3.2,可放 `docs/screenshots/w17/` 目录)
3. **每张截图 PASS/WARN/FAIL** + 一句话原因
4. **总结**:N PASS / M WARN / K FAIL
5. **已知偏差**:任何按钮顺序异常 / chip 样式异常 / 装备名 fallback 到 defId / 空态文案错位 / layout 溢出
6. **commit + push** 截图 + closeout 到 origin/main

---

## 7. 硬约束

- 不动 `lib/` 任何 Dart 代码(Codex 只跑 + 截图)
- 不动 `data/` 任何文件
- 不动 `GDD.md` / `CLAUDE.md` / `PROGRESS.md` / `IDS_REGISTRY.md`
- 若发现 bug → closeout 中报告,Mac 端来修(不要自己改代码)
- `dart run build_runner build` 仅本地重生 `.g.dart`(gitignored),**不要 commit codegen 产物**

---

## 8. 与其他派单并行性说明

本派单**独立**,无并行依赖。W17 候选 B framework + DeepSeek 节日 encounter 文案 + Codex W17 节日 chip 验收三件套已闭环(commit `5e7f587` 销账);W17 polish-C/D 双销账已收口。本派单为 W17 候选 E 收尾视觉验收。

---

**派单文档结束。Codex 接单后如有需要澄清,请在 closeout 文档中报告**(本协作流程通过 GitHub 主分支 commit 同步,沿用 W16/W17 体例)。
