# Codex 桌面 @ Pen 视觉验收派单 · W16 主菜单 _TodayFestivalChip 6 节日视觉验收(2026-05-16)

> 派单方:Mac Opus(zhangpeng.12334@gmail.com)
> 执行方:Codex 桌面 @ Pen Windows
> 沟通契约:Codex 全程不联系派单方,只在 closeout 报回。探路失败也有价值,不要硬撑。

---

## 0. 必读清单(顺序)

1. **本派单**
2. **`docs/handoff/codex_w15_victory_dialog_round2_visual_check_2026-05-16.md`**(round2 closeout - GUI 自动化 + 增量 build 缓存假象坑沿用)
3. **`docs/handoff/codex_w15_dialog_round3_visual_check_2026-05-15.md`**(round3 - 工具链体例)
4. `PROGRESS.md`(W16 当前阶段 - framework + DeepSeek 6 文案 + Mac debug override 全收口)
5. `lib/features/main_menu/presentation/main_menu.dart:184-216`(`_TodayFestivalChip` 实现)
6. `lib/features/debug/presentation/phase2_test_menu.dart` 末尾`_FestivalOverrideButton`(本批新加)

---

## 1. 任务一句话

**进 Phase2TestMenu →「DEBUG · 切今日节日」按钮 → SimpleDialog 选 6 节日 + 1 次「清除覆盖」→ 每次返主菜单截图 = 7 张图(6 节日 chip + 1 张无覆盖 baseline)。**

W16 framework + 6 文案 + Mac debug override 三段已 759/759 + analyze 0 收口,本派单为 GUI 视觉层验收 `_TodayFestivalChip` 6 节日 chip 显示效果 + 主菜单整体 layout 无破坏。

---

## 2. 验收对象 · `_TodayFestivalChip` 6 节日 chip

代码:`lib/features/main_menu/presentation/main_menu.dart:184-216`。

| Festival enum | EnumL10n 中文 | chip 文本 |
|---|---|---|
| `chunJie` | 春节 | 今日:春节 |
| `yuanXiao` | 元宵 | 今日:元宵 |
| `duanWu` | 端午 | 今日:端午 |
| `qiXi` | 七夕 | 今日:七夕 |
| `zhongQiu` | 中秋 | 今日:中秋 |
| `chongYang` | 重阳 | 今日:重阳 |

**chip 设计语言**(代码层):水墨克制,`WuxiaColors.panel` 背景 + `WuxiaColors.border` 描边 + `borderRadius: 12` + `padding: 12/4` + `fontSize: 12` + `color: WuxiaColors.textSecondary`,标题下方 12px 居中。

---

## 3. 工具链 · Mac debug override 切节日(无需调系统时间)

**关键**:本批 Mac 端已落 `debugFestivalOverrideProvider` NotifierProvider + Phase2TestMenu「DEBUG · 切今日节日」入口,**Codex 无需调系统时间到节日日**,直接在 debug build 内切节日。

### 3.1 步骤

```
1. flutter clean  (避增量 build 缓存假象坑 - round2 教训沉淀,memory feedback_codex_pen_windows_visual_check 已记)
2. flutter build windows --debug
3. 启动 build\windows\x64\runner\Debug\wuxia_idle.exe
4. 主菜单 → tap「Phase 2 调试场景」按钮 → Phase2TestMenu
5. 滚到最底 → tap「DEBUG · 切今日节日」按钮 → SimpleDialog 弹起
6. dialog 显 7 选项:春节 / 元宵 / 端午 / 七夕 / 中秋 / 重阳 / 清除覆盖
7. tap 一个节日(例如「春节」)→ dialog 关闭 → SnackBar「已覆盖今日为:春节」浮起
8. tap AppBar 返回箭头 → 回主菜单 → 标题下方 chip「今日:春节」显应景
9. 截图:主菜单整图(标题 + chip + 8 个菜单按钮)
10. 重复步骤 4-9 切换 6 节日各 1 次
11. 最后一次:tap「清除覆盖」→ 返主菜单 → chip 应 disappear(非节日日 → SizedBox.shrink 不占空间)→ 截图 baseline
```

### 3.2 截图清单(7 张)

| # | 文件名建议 | 内容 |
|---|---|---|
| 01 | `w16_festival_chip_chunJie.png` | 主菜单 + chip「今日:春节」 |
| 02 | `w16_festival_chip_yuanXiao.png` | 主菜单 + chip「今日:元宵」 |
| 03 | `w16_festival_chip_duanWu.png` | 主菜单 + chip「今日:端午」 |
| 04 | `w16_festival_chip_qiXi.png` | 主菜单 + chip「今日:七夕」 |
| 05 | `w16_festival_chip_zhongQiu.png` | 主菜单 + chip「今日:中秋」 |
| 06 | `w16_festival_chip_chongYang.png` | 主菜单 + chip「今日:重阳」 |
| 07 | `w16_festival_chip_cleared.png` | 主菜单 baseline(chip 不显,SizedBox.shrink) |

每张截图建议尺寸 ≥ 1280×900,主菜单全屏即可(Phase2TestMenu / SnackBar 不必入图)。

---

## 4. 验收点(每张截图自检)

### 4.1 chip 显示态(01-06,共 6 张)

- [ ] chip 文本字符完全匹配「今日:X」(X = 春节 / 元宵 / 端午 / 七夕 / 中秋 / 重阳)
- [ ] chip 背景为 `WuxiaColors.panel` 灰墨色,描边可见
- [ ] chip 文字色为 `WuxiaColors.textSecondary` 灰色,字号约 12px
- [ ] chip 位置:标题「挂机武侠 · 调试主菜单」下方 12px 居中
- [ ] chip 形状:横向胶囊(borderRadius 12),padding 12/4
- [ ] **不破坏既有 layout**:8 个菜单按钮(主线 / 问鼎九霄 / 闭关修炼 / Phase1 / Phase2 / 角色 / 装备 / 心法)全部可见 + 居中 + 等距,chip 出现不挤压按钮列

### 4.2 baseline(07,1 张)

- [ ] chip **不显**(没有「今日:」字眼)
- [ ] 标题与 8 按钮间距与历史 round2/round3 主菜单截图一致(SizedBox.shrink 不占空间)

### 4.3 风格统一

- [ ] 6 节日 chip 视觉一致(背景 / 描边 / 字号 / padding 同一份样式)
- [ ] 中文渲染无方框 / 缺字 / 字体回退

---

## 5. 已知风险 / 踩坑提醒

- **增量 build 缓存假象**(round2 沉淀,memory `feedback_codex_pen_windows_visual_check`):若 Codex Pen 之前已 build 过 wuxia_idle 旧版本,**必须先 `flutter clean` 再 `flutter build windows --debug`**,否则可能截到旧版主菜单(无 chip / 无 DEBUG 按钮)。
- **SnackBar 持续时间**:tap dialog 选项后 SnackBar 浮起约 4s,不影响主菜单截图,但若 Codex tap 太快截图可能带 SnackBar 余尾,等待 SnackBar 完全消失再截更稳。
- **AppBar 返回箭头**:Phase2TestMenu 有 back button(`automaticallyImplyLeading: true`),tap 返主菜单。

---

## 6. closeout 格式(沿 round2 体例)

Codex 提交 closeout 文档 `docs/handoff/codex_w16_festival_chip_visual_check_2026-05-16.md`,包含:

1. **环境快照**:HEAD SHA / build 命令 / 截图工具版本
2. **7 张截图**(命名见 §3.2,可放 `docs/screenshots/w16/` 目录)
3. **每张截图 PASS/WARN/FAIL** + 一句话原因
4. **总结**:N PASS / M WARN / K FAIL
5. **已知偏差**:任何 chip 文字/样式/layout 异常
6. **commit + push** 截图 + closeout 到 origin/main

---

## 7. 硬约束

- 不动 `lib/` 任何 Dart 代码(Codex 只跑 + 截图)
- 不动 `data/` 任何文件
- 不动 `GDD.md` / `CLAUDE.md` / `PROGRESS.md` / `IDS_REGISTRY.md`
- 若发现 bug → closeout 中报告,Mac 端来修(不要自己改代码)

---

**派单文档结束。Codex 接单后如有需要澄清,请在 closeout 文档中报告**(本协作流程通过 GitHub 主分支 commit 同步,沿用 round2/round3 体例)。
