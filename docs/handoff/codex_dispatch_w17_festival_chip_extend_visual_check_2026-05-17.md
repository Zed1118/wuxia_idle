# Codex 桌面 @ Pen 视觉验收派单 · W17 _TodayFestivalChip 扩 chuXi/qingMingJie 视觉验收(2026-05-17)

> 派单方:Mac Opus(zhangpeng.12334@gmail.com)
> 执行方:Codex 桌面 @ Pen Windows
> 沟通契约:Codex 全程不联系派单方,只在 closeout 报回。探路失败也有价值,不要硬撑。

---

## 0. 必读清单(顺序)

1. **本派单**
2. **`docs/handoff/codex_w16_festival_chip_visual_check_2026-05-16.md`**(W16 全链验收 closeout - 7 PASS / 0 WARN / 0 FAIL,本派单是 W17 增量,沿用工具链)
3. `PROGRESS.md`(W17 当前阶段 - B framework 6→8 + D 双销账)
4. `lib/features/main_menu/presentation/main_menu.dart:184-216`(`_TodayFestivalChip` 实现,W17 无改动)
5. `lib/features/debug/presentation/phase2_test_menu.dart` 末尾`_FestivalOverrideButton`(W17 dialog 7→9 选项)

---

## 1. 任务一句话

**进 Phase2TestMenu →「DEBUG · 切今日节日」按钮 → SimpleDialog 选 chuXi(除夕)/ qingMingJie(清明)2 新节日 → 每次返主菜单截图 = 2 张图;加 1 张 dialog 9 选项展开图证明 framework 扩展到位。**

W17 framework Festival enum 6→8 扩 chuXi/qingMingJie 已 761/761 + analyze 0 收口(commit `9b795a0`),本派单为 GUI 视觉层验收 2 新 chip 显示效果一致性 + dialog 选项扩展可见。

---

## 2. 验收对象 · `_TodayFestivalChip` W17 新增 2 节日 chip

代码:`lib/features/main_menu/presentation/main_menu.dart:184-216`(W17 无改动)。

| Festival enum | EnumL10n 中文 | chip 文本 | numbers.yaml 公历日期 |
|---|---|---|---|
| `chuXi` | 除夕 | 今日:除夕 | 2026-02-16(春节前一天) |
| `qingMingJie` | 清明 | 今日:清明 | 2026-04-05(既节气又节日,两通道独立) |

**chip 设计语言**(代码层,W16 同):水墨克制,`WuxiaColors.panel` 背景 + `WuxiaColors.border` 描边 + `borderRadius: 12` + `padding: 12/4` + `fontSize: 12` + `color: WuxiaColors.textSecondary`,标题下方 12px 居中。

---

## 3. 工具链 · Mac debug override 切节日(W16 工具链复用)

**关键**:W16 落地的 `debugFestivalOverrideProvider` + Phase2TestMenu「DEBUG · 切今日节日」入口在 W17 自动扩展到 8 节日(`Festival.values` 遍历),无需调系统时间到节日日。

### 3.1 步骤

```
1. flutter clean  (避增量 build 缓存假象坑 - W16 round2 教训沉淀,memory feedback_codex_pen_windows_visual_check)
2. dart run build_runner build  (W17 D-#3 半销账期间已 regen 过 .g.dart,clean 后必须重生)
3. flutter build windows --debug
4. 启动 build\windows\x64\runner\Debug\wuxia_idle.exe
5. 主菜单 → tap「Phase 2 调试场景」按钮 → Phase2TestMenu
6. 滚到最底 → tap「DEBUG · 切今日节日」按钮 → SimpleDialog 弹起
7. dialog 应显 9 选项:除夕 / 春节 / 元宵 / 清明 / 端午 / 七夕 / 中秋 / 重阳 / 清除覆盖
   → 截图 dialog 展开图(证明 W17 framework 扩 8 节日到位)
8. tap「除夕」→ dialog 关闭 → SnackBar「已覆盖今日为:除夕」浮起
9. tap AppBar 返回箭头 → 回主菜单 → 标题下方 chip「今日:除夕」显应景 → 截图
10. 重复步骤 5-9 切换「清明」→ 截图
11. (可选)tap「清除覆盖」→ 验证 chip 消失,本派单不强求(W16 已验 baseline)
```

### 3.2 截图清单(3 张)

| # | 文件名建议 | 内容 | 必需 |
|---|---|---|---|
| 01 | `w17_festival_chip_chuXi.png` | 主菜单 + chip「今日:除夕」 | ✓ |
| 02 | `w17_festival_chip_qingMingJie.png` | 主菜单 + chip「今日:清明」 | ✓ |
| 03 | `w17_festival_dialog_9_options.png` | Phase2TestMenu 内 SimpleDialog 9 选项展开 | ✓(证明 framework 扩展) |

每张截图建议尺寸 ≥ 1280×900,主菜单全屏即可。

---

## 4. 验收点(每张截图自检)

### 4.1 chip 显示态(01/02,共 2 张)

- [ ] chip 文本字符完全匹配「今日:X」(X = 除夕 / 清明)
- [ ] chip 背景为 `WuxiaColors.panel` 灰墨色,描边可见,与 W16 6 chip 视觉一致
- [ ] chip 文字色为 `WuxiaColors.textSecondary` 灰色,字号约 12px
- [ ] chip 位置:标题「挂机武侠 · 调试主菜单」下方 12px 居中
- [ ] chip 形状:横向胶囊(borderRadius 12),padding 12/4
- [ ] **不破坏既有 layout**:8 个菜单按钮(主线 / 问鼎九霄 / 闭关修炼 / Phase1 / Phase2 / 角色 / 装备 / 心法)全部可见 + 居中 + 等距,chip 出现不挤压按钮列
- [ ] 中文渲染无方框 / 缺字 / 字体回退

### 4.2 dialog 扩展(03,1 张)

- [ ] SimpleDialog 标题「切今日节日(DEBUG)」可见
- [ ] dialog 9 选项可见(除夕 / 春节 / 元宵 / 清明 / 端午 / 七夕 / 中秋 / 重阳 / 清除覆盖),无遗漏
- [ ] 选项顺序按 Festival enum 声明顺序(chuXi → chunJie → yuanXiao → qingMingJie → duanWu → qiXi → zhongQiu → chongYang → 清除)
- [ ] dialog 不溢出屏幕,9 行可全部容纳

### 4.3 风格统一(对照 W16 6 chip 截图)

- [ ] W17 2 chip 视觉与 W16 6 chip 一致(背景 / 描边 / 字号 / padding 同一份样式)
- [ ] 中文渲染体例统一

---

## 5. 已知风险 / 踩坑提醒

- **flutter clean → 必须先 dart run build_runner build**(W16 round2 沉淀,memory `feedback_codex_pen_windows_visual_check`):`flutter clean` 顺手清掉 `.g.dart` codegen 产物(本仓 `*.g.dart` gitignored),必须 `dart run build_runner build` 重生再 `flutter build windows --debug`,否则代码层 `Festival.chuXi / Festival.qingMingJie` 引用不到 codegen 同步报错。
- **W17 framework 扩展 codegen**:Mac 端在 D-#3 期间已 `dart run build_runner build` 重生 `.g.dart`,但 Pen Windows 端 git pull 后看到的是 source 文件,需自己重生。
- **SimpleDialog 9 选项可能稍长**:Phase2TestMenu 屏幕高度限制下 dialog 可能需要内部 scroll,验收点 4.2「不溢出」按实际渲染判断,若需 scroll 列全 9 项视为 PASS。
- **AppBar 返回箭头**:Phase2TestMenu 有 back button(`automaticallyImplyLeading: true`),tap 返主菜单。

---

## 6. closeout 格式(沿 W16 体例)

Codex 提交 closeout 文档 `docs/handoff/codex_w17_festival_chip_extend_visual_check_2026-05-17.md`,包含:

1. **环境快照**:HEAD SHA / build 命令 / 截图工具版本
2. **3 张截图**(命名见 §3.2,可放 `docs/screenshots/w17/` 目录)
3. **每张截图 PASS/WARN/FAIL** + 一句话原因
4. **总结**:N PASS / M WARN / K FAIL
5. **已知偏差**:任何 chip 文字/样式/layout 异常 / dialog 选项遗漏
6. **commit + push** 截图 + closeout 到 origin/main

---

## 7. 硬约束

- 不动 `lib/` 任何 Dart 代码(Codex 只跑 + 截图)
- 不动 `data/` 任何文件
- 不动 `GDD.md` / `CLAUDE.md` / `PROGRESS.md` / `IDS_REGISTRY.md`
- 若发现 bug → closeout 中报告,Mac 端来修(不要自己改代码)
- `dart run build_runner build` 仅本地重生 `.g.dart`(gitignored),**不要 commit codegen 产物**

---

## 8. 与 DeepSeek W17 派单并行性说明

本派单与 `docs/handoff/deepseek_w17_festival_extend_dispatch_2026-05-17.md`(DeepSeek 2 节日文案派单)**完全独立可并行**:
- Codex 验 chip 视觉走 debug override,**不依赖** chuXi/qingMingJie encounter 文案落地
- DeepSeek 写 encounters.yaml + events/<id>.yaml,**不依赖** chip 视觉验收

两边各自完工 push 后,Mac 端最后统一 PROGRESS 销账 W17 候选 B 全链闭环。

---

**派单文档结束。Codex 接单后如有需要澄清,请在 closeout 文档中报告**(本协作流程通过 GitHub 主分支 commit 同步,沿用 W16 体例)。
