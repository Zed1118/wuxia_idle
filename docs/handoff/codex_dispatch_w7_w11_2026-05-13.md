# Codex 桌面派单 · W7-W11 视觉验收自动化首跑

- **派单方**:Mac Opus(zhangpeng)
- **派单日期**:2026-05-13
- **执行方**:Codex 桌面版 @ Pen Windows(F:\Projects\wuxia_idle)
- **任务模式**:探路性自动化尝试,**不强求 100% 完成**,关键在于探明 Pen 本机 Flutter Desktop GUI 自动化可行性
- **预算**:2-3 小时,超时 stop + 写部分完成 closeout

---

## 0. 一句话目标

跑 `docs/handoff/w7_w11_visual_check_spec_2026-05-13.md` 的 15 个截图场景,**尽可能不依赖人手操作**,归档到 `docs/screenshots/phase4_w7_w11/`,完事后写 closeout handoff 报回探路结论。

跑不通也 OK——把"什么路走通了/哪步卡了/下次怎么改"写清楚比硬跑完 15 张更有价值。

---

## 1. 你相比 Mac SSH 派的优势

- **本机跑**,无 SSH 网络延迟,鼠标/键盘/截图/UIA 全部本机直接调
- **多模态视觉**,截图自己看自己判断 + 标定坐标 + 重试不依赖回报 Mac
- 完整 PowerShell .NET / Python / AutoHotkey / FlaUI 等工具链任你选
- 文件系统 + git 本机直接动,改完 commit 不用走 SSH

---

## 2. 必读文件(开工前 30 分钟)

按顺序读:

1. **`docs/handoff/w7_w11_visual_check_spec_2026-05-13.md`**(本任务唯一信源):15 张截图清单 + 验收点 + 已知踩坑 + Mac 端归档动作
2. **`PROGRESS.md`** 当前阶段段(进行中/已完成/已知偏差 #28 #31)
3. **`CLAUDE.md`** §5 红线 + §12 待人类决策清单(碰到立刻停,不要凭空补脑)
4. **`docs/handoff/week11_victory_resolution_2026-05-13.md`** §6.1(W11 销账 #32 5 场景验收点详细描述)
5. **`docs/handoff/week10_phase4_defeat_resolution_2026-05-13.md`** §5.1(W10 banner 销账验收点详细描述)
6. **`docs/handoff/t62_visual_check_spec_2026-05-13.md`**(T62 一次成功的 spec 体例,可参考截图命名 + 报回格式)

---

## 3. 推荐 approach(顺序可改,工具自选)

### Step 1 · 基线核对(必跑,任一失败 stop)

```powershell
Set-Location F:\Projects\wuxia_idle
git pull
flutter pub run build_runner build --delete-conflicting-outputs
flutter analyze       # 期望 0 issues
flutter test          # 期望 546/546
```

期望:HEAD 上有 commit `7404952`(W12 Phase 5 收尾),analyze 0 issues,546/546 pass。

任一失败 → stop,写 closeout 描述失败原因,**不要往代码改**(Mac 端没动过的不该 break)。

### Step 2 · 清存档 + 启动游戏

```powershell
Remove-Item -Recurse -Force $env:APPDATA\wuxia_idle -ErrorAction SilentlyContinue
flutter run -d windows
```

等游戏窗口出现(~30-60s)。**关键:固定窗口位置 + 大小 + 分辨率**,后续所有坐标基于此。建议把窗口拖到主屏幕(0,0)+ 固定 1280×720 或全屏,记录下来。

### Step 3 · 自主选 GUI 自动化工具链

你顺手哪个用哪个:

| 工具 | 优势 | 劣势 |
|---|---|---|
| **PowerShell .NET SendInput / Cursor.Position** | 无依赖,原生 Windows | 写起来 verbose |
| **Python pyautogui** | API 简洁,有 image matching | 需 `pip install pyautogui pillow` |
| **AutoHotkey** | 轻量,社区资源多 | 需另装 |
| **FlaUI / UIAutomation** | 能定位 UIA 控件 | Flutter Desktop 暴露的 a11y tree 不完整,**慎用** |

**Flutter Desktop a11y 实测情况未知**——如果 FlaUI inspect.exe 能看到「主线」「问鼎九霄」这些按钮的 UIA 元素 + ClickInvoke 能点中,**那是最佳路径**(无需坐标硬编码)。先试一下 inspect.exe 看 a11y tree 完整度,5 分钟成本。**不行就退坐标点击**。

### Step 4 · 验证链路(场景 C,最简单)

场景 C 是纯只读 UI 检查(无战斗、无对话框、无文本输入),3 张截图:

1. 主菜单 → 「问鼎九霄」按钮点击 → TowerFloorListScreen
2. 滚到顶 → 截图 `03_w9_tower_floor_list_top.png`
3. 滚到第 5 层附近 → 截图 `04_w9_tower_boss_outline.png`
4. 滚到第 30 层 → 截图 `05_w9_tower_floor_30.png`

**先把这条跑通**:点按钮 → 等屏切换 → 截图 → 自己看截图验证「30 层列表渲染了/Boss outline 金紫色对吗」。

**这一步是探路里程碑**——跑通了再扩展到 D-E-F-G;跑不通直接 stop 写 closeout。

### Step 5 · 跑剩余 12 张(场景 A/B/D/E/F/G)

按 spec 顺序跑。关键技巧:

- **战斗等待**:tick 战斗 5-30s 不固定,**轮询截图 + 找特征文字判断「是否回到 stage list」**(如 OCR 找「山门之外」等关名,或图像匹配 cleared icon)。pyautogui 有 locateOnScreen
- **战败场景(G)** 故意不强化直接打 stage_01_05,设计上必败(T62 已平衡跨 2 阶)
- **stage drop 验收(E)** 需先强化武器 +5 才能胜,**这步操作复杂**——如果坐标点击不稳,**这个场景跳过让 manual** 也行
- **截图命名严格按 spec §收尾「报回 Mac 端」清单**,不要自创命名

### Step 6 · 卡壳处理

- 某场景坐标失败/UI 状态不对 → **不要硬试 >3 次**,标记 manual_needed 跳过,继续下一个
- 整条 GUI 自动化链跑不通(点击都不响应)→ 立刻 stop,写 closeout 报回探路结果
- 战斗结果意外(应该败却胜了 / 应该胜却败了)→ 报回,可能是数值层挂账

---

## 4. 边界(硬约束,违反必须报回)

- **不动**:`GDD.md` `CLAUDE.md` `numbers.yaml` `data_schema.md` `IDS_REGISTRY.md`(DeepSeek 领地 + 数值规约)
- **不动**:`data/narratives/` `data/lore/` `data/events/`(DeepSeek 领地)
- **不改 `lib/` `test/` 任何代码**——本任务是验收不是开发,代码状态固定在 commit `7404952`
- **不 `git push`** —— 完成后 commit 到 main 本地即可,Mac 端用户 review 后再推 origin
- **不删任何 Pen 端文件**,除了 `$env:APPDATA\wuxia_idle\` 存档(spec 0.4 步骤指定的清理)
- **不引入新 npm/pip/choco/winget 包**,除非 pyautogui / pillow / FlaUI 这三个之一(任选其一)且在 closeout 报告里说清楚
- **不动 Mac 端 spec 文件本身**(`docs/handoff/w7_w11_visual_check_spec_2026-05-13.md`),如果发现 spec 有 bug,记到 closeout 里让 Mac 端改

---

## 5. 完成交付

### 5.1 截图归档

`docs/screenshots/phase4_w7_w11/` 下,**严格按 spec §收尾 15 张命名**:

```
01_w7_inventory_35items.png
02_w8_techniques_panel.png
03_w9_tower_floor_list_top.png
04_w9_tower_boss_outline.png
05_w9_tower_floor_30.png
06_w11_before_stage_eq_battlecount.png
07_w11_before_stage_tech_progress.png
08_w11_after_stage_eq_battlecount.png         ← **必收(销账 #32)**
09_w11_after_stage_tech_progress.png          ← **必收(销账 #32)**
10_w11_stage_drop_inventory.png               ← **必收(销账 #32)**
11_w11_tower_floor1_firstclear_rewards.png
12_w11_tower_floor1_replay_no_rewards.png     ← **必收(重打差异点)**
13_w11_tower_replay_battlecount_still_inc.png ← **必收(重打差异点)**
14_w10_defeat_banner_title.png                ← **必收(W10 销账)**
15_w10_defeat_internalforce_halved.png        ← **必收(W10 销账)**
```

**最少 7 张「必收」即可放行**。其他 8 张能给则给,跳过的在 closeout 里说明跳过原因。

### 5.2 Closeout handoff(必交付)

`docs/handoff/codex_w7_w11_visual_check_closeout_2026-05-13.md`,沿用 week11/week12 handoff 体例,至少含:

1. **执行摘要**:跑了几张 / 必收 7 张拿到几张 / 总耗时 / 整体可行性评分(0-10)
2. **场景跑通情况表**:A/B/C/D/E/F/G 各场景一行,状态 ✅成 / ⚠️降级人工 / ❌跑不通 / ⛔跳过
3. **工具链选型 + 实战评价**:用了 SendInput / pyautogui / 哪个 + 坑 + 推荐
4. **坐标标定耗时 + 鲁棒性**:窗口拖动后还能用吗?分辨率变了还能用吗?
5. **截图自动验证情况**:你看了 8/9/10/12/13/14/15 这些必收截图,**视觉判断结果**——battleCount 真 ++ 了吗?banner 真红字了吗?drop 真入背包了吗?(spec 验收点逐条对照)
6. **下次推荐路径**:全自动可行性 / 半自动改进点 / Anthropic Computer Use 值不值得搭
7. **遇到 Mac 端 spec bug 列表**(如果有)

### 5.3 commit + **不 push**

```powershell
git add docs/screenshots/phase4_w7_w11/ docs/handoff/codex_w7_w11_visual_check_closeout_2026-05-13.md
git commit -m "feat(visual-check): W7-W11 五周累积视觉验收 Codex 桌面自动化首跑"
```

**不要 push**——等 Mac 端 review。

---

## 6. 不要硬上的情况

如果你判断:

- < 50% 信心跑通完整 15 张
- 坐标点击 / FlaUI 都试了一遍都不响应
- 战斗状态判断写不出鲁棒逻辑
- ……或者任何让你觉得"硬撑也撑不下来"的信号

**立刻 stop**,写一个**简短 reality check**报告(也叫 `codex_w7_w11_visual_check_closeout_2026-05-13.md`,但内容是探路失败报告):

- 评估理由(哪条路试了 / 试到哪步停)
- 哪些工具链尝试过结果
- 截图能力上限是什么(能截图但点不准?能 a11y 但 Flutter Desktop 没暴露?)
- 推荐替代方案(半自动 / Anthropic Computer Use / 还是别试自动化)

**探路失败也是有价值的输出**——下次知道这条路不能走 = 给我们省时间。

---

## 7. 模型 / 时间预算

- 模型:你自主选(GPT-5 / o1 / 哪个顺手)
- 时间:2-3 小时硬上限,超时立即停 + 写部分完成 closeout
- 重在探路 + 报回,不重在 100% 完成 15 张

---

## 8. 沟通契约

- 全程**不联系 Mac 端**,只在 closeout 文件里报告
- 跑完后 commit 到 main 本地,不 push,**直接 stop**
- Mac 端用户回来看到 commit,人工 review closeout + 截图,**决定下一步**

---

## 9. 已知踩坑预防

- **build_runner 必跑**(memory `feedback_wuxia_pen_build_runner.md`):`*.g.dart` gitignored,不跑会编译报 provider 缺失
- **存档清版本兼容**:W6-W7-W8 累积过 Isar schema,clean slate 最稳(spec 0.4 已写)
- **stage_01_05 默认必败**:T62 跨 2 阶平衡,**这是设计**(章末暗示升阶),不是 bug。场景 E 需强化 +5 才能胜,场景 G 利用必败状态直接验 banner
- **scenarioP5 入口**:主菜单 → 「Phase 2 调试场景」按钮 → 子屏「P5 · 师徒种子」(不是直接「P5」按钮)
- **数值红线**(`CLAUDE.md §5.4`):普伤 ≤8000 / 玩家血 ≤20000 / 内力 ≤15000 / 装备攻击 ≤2000 / Boss 血 ≤50000+。触发越界报回
- **W7/W8 35 件 21 本展示限制**(spec 已写):P5 只给 9 件装备 4 本心法,运行时仓库/心法面板只显示玩家持有,**场景 A/B 截当前持有 + 文字说明即可**,不要花时间找「全图鉴入口」(可能没有)

---

## 10. 探路价值优先级

如果你只有 2 小时,我希望你按以下优先级:

1. **最高**:验证 GUI 自动化可行性(场景 C 跑通就够)+ 写 closeout 评估
2. **次高**:跑通必收 7 张里至少 3 张(D3/F2-3/G2,**销账硬证据**)
3. **可选**:补完剩余 8 张
4. **可选**:寻找全图鉴入口跑场景 A/B 真完整 35 件展示

**前 2 项有就成功**,后 2 项是 bonus。

祝好运,期待你的探路报告。

—— Mac Opus,2026-05-13
