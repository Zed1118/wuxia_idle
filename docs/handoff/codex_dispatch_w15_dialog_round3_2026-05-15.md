# Codex 桌面 @ Pen 视觉验收派单 · W15 dialog round3 W14-2 新 12 events 文案验收(2026-05-15)

> 派单方:Mac Opus(zhangpeng.12334@gmail.com)
> 执行方:Codex 桌面 @ Pen Windows
> 沟通契约:Codex 全程不联系派单方,只在 closeout 报回。探路失败也有价值,不要硬撑。

---

## 0. 必读清单(顺序)

1. **本派单**
2. **`docs/handoff/codex_w14_3c_visual_check_2026-05-14.md`**(round1 closeout — 工具链 + 踩坑沿用)
3. **`docs/handoff/codex_w14_3_round2_visual_check_2026-05-15.md`**(round2 closeout — 4/4 PASS + topmost 经验)
4. `PROGRESS.md`(W15 当前阶段)
5. `WINDOWS_DEEPSEEK_GUIDE.md` §6.5(奇遇事件文案规范 — 验收时对照)

---

## 1. 任务一句话

**用 Phase2TestMenu「VC-EVENT」按钮 → encounter debug picker → 强制触发 W14-2/W14-3-B 新 12 条 events,抽样 6 条出截图,验文案/dialog 节奏/outcome body。**

W14-3 整体 round2 完美线 4/4 PASS 已收。本次为 round3 - dialog 内容层验收(round1/2 是结构层 + skill section 装备态)。

---

## 2. 验收对象 · W14-2/W14-3-B 新 12 条 events

12 条由 DeepSeek 落地于 `git show db046fa`(`feat(W14-3-B): 补 W14-2 新 12 条 encounter events 文案`)。按字典序:

| # | id | 题材气质(从文件抽样) | 推荐抽样? |
|---|---|---|---|
| 1 | `cang_jing_ge_wu` | 藏经阁悟道 | — |
| 2 | `du_kou_chun_yu` | 渡口春雨,送别 | ★ |
| 3 | `duan_ya_chui_lian` | 断崖垂练,登高 | — |
| 4 | `gu_dao_xue_ji` | 古道雪迹,追索 | ★ |
| 5 | `gu_jian_zhong_yin` | 古剑冢拾遗(已 抽审过) | — |
| 6 | `lu_pang_xian_xian` | 路旁见闲,救助 | ★ |
| 7 | `qun_xia_tu` | 群侠图,江湖众生 | ★ |
| 8 | `shan_dao_wu_zhe` | 山道悟者,问道 | — |
| 9 | `shan_lin_qi_yu` | 山林奇遇 | — |
| 10 | `xiao_zhen_wen_yi` | 小镇瘟疫,救治 | ★ |
| 11 | `xuan_ya_pu_bu_li_lian` | 悬崖瀑布里炼 | — |
| 12 | `ye_xing_xun_dao` | 夜行寻道 | ★ |

**抽样 6 条**(★):覆盖渡口/古道/路旁/群侠/小镇瘟疫/夜行 — 不同地貌、不同 outcome 风格(领悟 / 救助 / 旁观 / 试炼)。

剩余 6 条若 Codex 时间富余,可补 quick scan(只截 opening 不细看 outcome body),否则不强制。

---

## 3. fixture 状态(派单时 self-check)

| # | 验收点 | 现状 | 说明 |
|---|---|---|---|
| ✅ 1 | VC-EVENT 按钮已在 Phase2TestMenu | commit `cce2023` | UiStrings.scenarioVcEvent |
| ✅ 2 | EncounterDebugPickerScreen 已实现 | commit `cce2023` | `lib/ui/debug/encounter_debug_picker.dart` |
| ✅ 3 | picker 按 id 字典序列出全 15 条 encounters | 包含 12 新条 + 3 W14-1 标杆 | OK |
| ✅ 4 | encounter_dialog 节奏 round1 验过 | 入场 500ms fade + opening↔outcome 420ms switcher | 仍生效 |
| ✅ 5 | EncounterEventLoader 加载 events/<id>.yaml | OK | 派单方刚 grep 验过 12 文件全在 |

---

## 4. 启动 + 环境(Pen flutter run)

派单方 Mac 这一波**没有**预先重启 Pen。Codex 需自行启动:

### 4.1 必跑 build_runner(Pen .g.dart gitignored)

W14-4 之后 schema 未升版,但 W15 #36(commit `897a9b1`)动了 `SkillDef`(纯 Dart 类,**理论无需 build_runner**,因为 SkillDef 没 freezed/json_serializable),**保险起见仍跑一次**:

```powershell
cd F:\Projects\wuxia_idle
git pull --rebase --autostash
git log -1 --oneline    # 应到 897a9b1 (或更新)
dart run build_runner build --delete-conflicting-outputs
```

### 4.2 启动 wuxia_idle GUI(SSH 远端启动陷阱已知)

沿 `reference_pen_wuxia_flutter_run.md` 模板(schtasks Console Session 1 启动):

```powershell
# 1. 清理潜在残留进程 + schtask
Get-Process wuxia_idle -ErrorAction SilentlyContinue | Stop-Process -Force
schtasks /Delete /TN WuxiaRun /F  2>$null

# 2. 注册新 schtask(Session 1 = Console / GUI session)
schtasks /Create /TN WuxiaRun /TR "F:\Projects\wuxia_idle\build\windows\x64\runner\Debug\wuxia_idle.exe" /SC ONCE /ST 23:59 /RU INTERACTIVE /RL HIGHEST /F

# 3. 启动
schtasks /Run /TN WuxiaRun

# 4. 验证窗口可见
Get-Process wuxia_idle | Select-Object Id, MainWindowTitle, MainWindowHandle
# MainWindowHandle 非 0 = 可见
```

### 4.3 窗口尺寸固定 1280×900(沿用 round1/2 标准)

```powershell
Add-Type -AssemblyName System.Windows.Forms
$hwnd = (Get-Process wuxia_idle).MainWindowHandle
# 用 SetWindowPos 设 1280×900 居中(具体调用见 round1 closeout §6.3)
```

---

## 5. 验收路径(主截图 6 张 + 可选 6 张)

### 5.1 进入 picker

主菜单 → 「Phase 2 调试场景」 → **「VC-EVENT · 触发奇遇 debug」** 按钮(第 8 个,挂在 VC14_3 之后)
→ EncounterDebugPickerScreen 出现,15 条 encounters 按 id 字典序排列

### 5.2 抽样 6 条 · 每条 2 张

**重要前置**:Picker 每点一条会 `markTriggered` 写库,该 encounter 进 `triggeredEncounterIds` 后正常 hook 不再选它。**但 picker 不受 triggered 限制**(不查 evaluateTriggers),所以同 session 可连续点不同 id 全部触发。

**每条流程**:点 id → opening dialog 出现(fade 500ms 入场)→ **截图 A** opening 全文 + 选项按钮 → 点其中一个非 skip outcome → AnimatedSwitcher 420ms 切到 outcome body → **截图 B** outcome body 文末状态(switcher 完整收尾后)

| # | id | 选哪个 outcome 截 B | 截图文件名建议 |
|---|---|---|---|
| 1 | `du_kou_chun_yu` | 第一个非 skip | `r3-1a_opening.png` / `r3-1b_outcome.png` |
| 2 | `gu_dao_xue_ji` | 第一个非 skip | `r3-2a_opening.png` / `r3-2b_outcome.png` |
| 3 | `lu_pang_xian_xian` | 第一个非 skip | `r3-3a_opening.png` / `r3-3b_outcome.png` |
| 4 | `qun_xia_tu` | 第一个非 skip | `r3-4a_opening.png` / `r3-4b_outcome.png` |
| 5 | `xiao_zhen_wen_yi` | 第一个非 skip | `r3-5a_opening.png` / `r3-5b_outcome.png` |
| 6 | `ye_xing_xun_dao` | 第一个非 skip | `r3-6a_opening.png` / `r3-6b_outcome.png` |

总计 **12 张主截图**(6 对 a+b)。存 `docs/screenshots/w15_round3/`(目录请新建)。

### 5.3 可选补截(若时间允许 / 不强制)

剩余 6 条(`cang_jing_ge_wu` / `duan_ya_chui_lian` / `gu_jian_zhong_yin` / `shan_dao_wu_zhe` / `shan_lin_qi_yu` / `xuan_ya_pu_bu_li_lian`)只截 opening,文件名 `r3-7~r3-12_opening.png`。

---

## 6. 验收红线(每张主截图自查)

对照 `WINDOWS_DEEPSEEK_GUIDE.md` §6.5 + §4-§5 风格规范:

### 6.1 文案层(看图读字)

✅ **opening 80-200 字内**,字体可读、无乱码
✅ **outcome body 50-120 字内**,文末非"你获得了 X 招式"这类 UI 句
✅ **不写"+30 修炼度"具体数字**(描述性"内息渐沉"OK)
✅ **不写网文腔**("瞳孔猛地一缩""仿佛过了一个世纪")
✅ **无错字 / 不通顺句**(读不通就报 FAIL)
✅ **气质统一**(渡口春雨应温润、古道雪迹应荒寒 — 调子明显跑题就报 FAIL)

### 6.2 dialog 节奏(看动画)

✅ **opening fade 入场 500ms**(若一瞬出现 → 节奏破)
✅ **opening↔outcome 切换 AnimatedSwitcher 420ms fade**(若硬切 → 节奏破)
✅ **dialog 不被截字 / 不漏底**(1280×900 下应铺满中间)

### 6.3 outcome body 兜底

✅ 至少出现 1 行能让玩家联想到"果"的句子(领悟 / 获物 / 离去),不写明数值
✅ 不出现"你大喜过望""你怒不可遏"这类替玩家定情绪的句子

---

## 7. 已知风险 + 上批工具链沿用

### 7.1 picker → dialog 转场风险

- picker 是 Scaffold + ListView,dialog 用 `showEncounterDialog` 标准弹窗:**理论上 dialog 出现在 picker 之上,关闭后回 picker 列表**
- 风险:dialog 关闭后立刻 banner,banner 与 picker 视觉叠加 — 这是 W14-3-A 已知行为,**截图时若有 banner 残留,等 banner 消失再截 picker**(banner 3-5s 自动 dismiss)

### 7.2 同 session 连续触发的副作用

每点一条 picker tile:
- `markTriggered` 写库(triggeredEncounterIds 累加)
- `applyOutcome` 写库(unlockSkill / 属性奖励永久落地)

**累积副作用**:祖师角色 6 条非 skip outcome 后可能拿到 6 个 encounter skill / 一堆属性。**VC seed 后整存档 throwaway,放心点**。Pen 端测完不要把存档拷出来用作正式数据。

### 7.3 上批工具链坑沿用

(从 round2 closeout §7 抽要点)

- **WuxiaRun Running ≠ 桌面可见**:必须枚举 `MainWindowHandle` 二次确认
- **旧 wuxia_idle.exe 锁 kernel_blob.bin**:`flutter build windows --debug` 会失败,须先 `Stop-Process wuxia_idle`
- **Codex 桌面长操作后抢前台**:截图前游戏窗口 `SetWindowPos HWND_TOPMOST`(round2 已验证有效)
- **PowerShell `$false` SSH 嵌套转义陷阱**:清理任务用 `schtasks /Delete /TN WuxiaRun /F` 老命令更稳

---

## 8. closeout 模板(完成后 commit)

写到 `docs/handoff/codex_w15_dialog_round3_visual_check_2026-05-15.md`,结构沿用 round2 closeout:

```markdown
# Codex W15 dialog round3 visual check closeout(2026-05-15)

## 1. 一句话结论
6 主截图 + 0/6 可选,X/6 PASS,Y FAIL,Z WARN

## 2. 环境与启动记录
- HEAD: <hash>
- 启动命令(实际跑的)
- 重 build 是否需要(W15 #36 schema 是否触发)

## 3. 截图清单与 PASS/FAIL 评级
| # | id | A opening | B outcome | 评级 | 备注 |
...

## 4. 文案层问题反馈(给 DeepSeek)
若有错字 / 风格走样 / outcome 文末直接交代数值 等

## 5. 节奏层问题反馈(给 Mac)
若 fade 时长不对 / 截字 / 漏底

## 6. 工程教训(本会话产)
若有新工具链坑

## 7. 下次推荐
若 6 张全 PASS → round3 收口,挂账无新增
若有 FAIL → 列具体修复建议
```

---

## 9. 不在本次范围

❌ 不验 EncounterSkillSection / 装备态(round2 已验)
❌ 不验 stage drop 视觉(挂账 #34,留下次)
❌ 不验 dialog 在小屏(< 1280×900)下的截字问题(明确 1280×900)
❌ 不要改任何 .yaml / .dart(纯视觉验收,只截图)

---

## 10. 时间预估

- 启动 + 重 build:10-20 min(若需要重 build)
- 抽样 6 主截图(opening + outcome × 6):30-45 min
- 可选补 6 quick scan:15 min
- 写 closeout:20 min
- **总计 80-110 min**(round2 用了 ~90 min,体量相当)

---

**派单结束。Codex 接手后第一句话:报 HEAD + 启动是否成功。验收过程不联系派单方,closeout 直接写完 push。**
