# Phase 3 Week 5 F 主线扩 15 关 + 战败 narrative hook 全交付收尾（2026-05-13）

> 写给下一会话开局后接 Week 6 的 Mac Opus 自己看。
> Week 5 F 主线扩容 + defeat hook 全部落地 + Pen Windows 视觉验收 6 截图通过 + tag `v0.3.0-w5` push origin。
> PROGRESS.md「当前阶段」段是单一信源；本文档补充「为什么这么做」与「下次开局必读」。

---

## 1. 一句话结论

Week 5 F 主线扩容 **T59→T62 单日交付**：stages.yaml 6→15 关 schema + 数值梯度 + narrativeDefeatId 字段 / GameRepository 主线红线 / stage_entry_flow 战败 hook / Pen 视觉验收 6 截图 + 2 旁支 fix（CharacterPanelScreen AppBar / stage_01_05 跨阶 balance）。`main` HEAD `92760fd`，tag `v0.3.0-w5` push origin。**530/530** 测试，analyze 0 issues。**销账 #29**。**核心销账截图 06**：风雨渡口·败 narrative 显示「撑伞的人没有追」文案，T60 defeat hook 视觉落地。

---

## 2. commit 时间线（本会话）

| # | hash | T | 类型 | 简述 |
|---|---|---|---|---|
| 1 | `f4bad18` | T59+T60 | feat | 主线 6→15 关 + 战败 narrative hook（销账 #29）|
| 2 | `c272914` | T62 | docs | Pen 视觉验收 spec + 截图目录预留 |
| 3 | `87387ad` | — | fix | CharacterPanelScreen AppBar + 返回按钮（T56 遗留 UX 盲区，验收中途发现） |
| 4 | `4fb22f4` | — | balance | stage_01_05 跨阶升 sanLiu（intermediate，仍碾压） |
| 5 | `73c1f37` | — | balance | stage_01_05 跨 2 阶 erLiu（强制升阶设计，玩家方稳输） |
| 6 | `92760fd` | T62 | docs | Pen 6 截图归档 + phase3_summary W5 段 + Week 5 全交付 |
| — | tag `v0.3.0-w5` | — | tag | Phase 3 Week 5 F 主线扩容 + defeat hook 全交付（销账 #29）|

---

## 3. 关键决策链 + 教训复盘（本会话新增）

### 3.1 起手 4 决策（用户拍板）

| # | 决策项 | 选择 | 备注 |
|---|---|---|---|
| 1 | 章节结构 | **3 章 × 5 关** | 对齐 GDD §7 Demo 3 章 |
| 2 | 战败 UX | **narrative 后回 stage list** | 不阻断重试 / 不计 cleared |
| 3 | DeepSeek 协作 | **Mac 先上 yaml** | DeepSeek 实际已铺 30 narrative + 6 defeat（章末两关 4/5 才有 defeat），意外发现 |
| 4 | effort | **升 xhigh** | 跨子系统 + 双端协作 + 挂账收尾，决策点多 |

### 3.2 旧 6 关数值层与 DeepSeek narrative 编号不对齐隐藏 bug 处理

T59 实施时审计 DeepSeek narrative 内容（`stage_NN_02_opening.yaml`）发现：
- 旧 `stage_01_02` Mac 写「林间伏击 山贼」≠ DeepSeek 写「荒山野店 茶馆独臂老汉」
- 旧 `stage_02_02` Mac 写「黑风寨 Boss 6500HP」≠ DeepSeek 写「茶馆论剑 借剑老者」（中段非 Boss）
- 旧 `stage_03_02` Mac 写「一战封王 大 Boss 11000HP」≠ DeepSeek 写「许昌擂台 1v1 光头汉」

这是 P1 #1 narrative schema 迁移时只改 id 没核对内容的遗留。Week 5 一并修复：把章末大 Boss 重定位到 stage_NN_05，章内 stage_NN_02 全改成 DeepSeek narrative 对应的中段普通敌。**用户对齐策略选项 A**（按 DeepSeek 重对齐 stages.yaml，工作量最大但清账最彻底）。

### 3.3 stage_01_05 数值估算偏低教训（balance 2 次迭代）

T59 写章末大 Boss `stage_01_05` 用 xueTu yuanShu 数值（HP 3200-3500 / Atk 150-160），预期玩家方「勉强能过」。Pen 实测：**10 tick 左队胜 21673 总伤**，玩家方一边倒胜。

平衡迭代：
1. `4fb22f4` 跨 1 阶 sanLiu（HP 8500-9000 / Atk 450-480）→ **用户实测仍碾压**
2. `73c1f37` 跨 2 阶 erLiu（HP 9000-10000 / Atk 700-750）→ **17 tick 右队胜 0v2 玩家全阵亡** ✓

**根因**：境界差 1 阶 modifier 1.4/0.7 不足以盖过装备 + 心法 + 内力乘数（公式 (内力×0.4 + 装备×8 + 招式) × 心法 1-3× × 暴击 1-2.5×），玩家方乘数叠加优势太大。**差 2 阶** modifier 2.5/0.3 才让玩家方「近破防免疫」+ Boss「高伤一击」。

新 memory `feedback_wuxia_boss_balance_crosstier.md` 记此规则：章末 Boss 想真难必须**跨 1-2 阶**, 单纯上调 HP/Atk 不够。

### 3.4 CharacterPanelScreen UX 盲区（T56 遗漏，本会话 fix）

Pen 验收期间用户截图反馈：点 P5 师徒种子后自动跳 CharacterPanelScreen，**无返回按钮卡死**。T56 改 Tab 时 Scaffold 保留原始无 AppBar 结构，widget test 在顶层 `pumpWidget(MaterialApp(home: ...))` 测不出 push 后返回链断。

修复 commit `87387ad`：加 `AppBar(title: Text('角色面板'), leading: canPop ? BackButton : null)`，hot reload 后即生效。

新 memory `feedback_flutter_subscreen_appbar_audit.md` 记此规则：加 sub-screen / Tab 时必检 AppBar + 返回按钮。

### 3.5 Pen flutter run SSH 派遣首跑

Week 4 T58 视觉验收 Pen 是用户开 RDP 手动跑。Week 5 T62 试用 SSH schtasks 切 Console Session 1 启动 flutter run，**首跑成功**：

- `schtasks /Create + LogonType Interactive` 让 GUI 渲染到 user 桌面
- 改代码后 `Get-Process flutter,dart,wuxia_idle | Stop-Process -Force` + 重新 `Start-ScheduledTask` 一键重启（Isar 数据持久不丢存档）
- 验收完一键清理 `Unregister-ScheduledTask`

3 次 SSH kill+relaunch 全部成功。具体命令模板见新 memory `reference_pen_wuxia_flutter_run.md`。

---

## 4. 测试基线 deltas（本会话）

| 阶段 | analyze | test |
|---|---|---|
| 开工前（main `52b0363`，Week 4 末）| 0 issues | 529/529 |
| T59+T60 完成（`f4bad18`）| 0 issues | 530/530（+1 主线 15 关红线）|
| 旁支 fix + balance（`87387ad` / `4fb22f4` / `73c1f37`）| 0 issues | 530/530（数值/UI 改动不影响测试期望）|
| T62 收尾（`92760fd`）| 0 issues | 530/530 |

Week 5 累计：529（Week 4 末）→ 530（Week 5 末，+1）。本周以 schema 改动 + UX/数值迭代为主，新增 test 量少。

---

## 5. Week 6 起手者必读（下一会话开局看这段）

### 5.1 入场审计三件套

```bash
cd ~/Desktop/挂机武侠 && git log --oneline -5
flutter analyze
flutter test
```

应得到：HEAD `92760fd` / 0 issues / 530 passed。任一不对停下贴差异。

### 5.2 Week 6 方向候选（3 选 1）

| 候选 | 阻塞 | Mac 端可做 | 备注 |
|---|---|---|---|
| **Phase 5** 收尾（DDD 整理 / Riverpod 3.x / Isar 4.x / flutter build web 解锁） | 无 | ✅ | 技术债清理,无新功能；切版本风险大；可拆分多 Week。**建议首选**（不依赖外部决策）|
| **挂账 #30** 闭关 3 维度扩展（technique_learn_rate / internal_force_growth / 节气日 / 子时阳刚） | §12 #7（节气清单 / 农历库选型）+ Character 修炼度字段 | ⚠ 部分 | Phase 4 fixture 改造同源 |
| **C 奇遇** / **E 武学领悟** | §12 #6（机缘值累积规则） | ❌ 需用户决策 | 阻塞同源,需先决 #6 |

**推荐顺序**：Phase 5 技术债（无阻塞 + 解锁 web build）→ 等用户决策 #6 后开 C/E → #30 等节气库选型后补。

### 5.3 起手前必问用户

下一会话开局**不要直接动手**，先问用户：「Week 6 选哪个方向？Phase 5 / #30 / C/E」。

### 5.4 重要的运行时副作用（仍生效）

- `stage_01_05` 章末大 Boss 是 **erLiu 跨 2 阶**设计（撑伞高人 10000HP 750Atk / 渡口刀客剑客 9000HP 700-720Atk），玩家方 xueTu 不可过 —— 后续主线扩容 / 数值调整时**勿误把这关数值降回 xueTu**（会重新引入碾压 bug）。balance commit `73c1f37` 写明设计意图
- CharacterPanelScreen 已有 AppBar（fix `87387ad`），后续如再加 sub-screen 沿用此模板
- DeepSeek narrative 已铺 15 关 30 opening+victory + 6 defeat（章末 4/5 才有 defeat），后续如新增主线关需 DeepSeek 端配套 narrative 文案

### 5.5 已知挂账（仍未销）

参考 PROGRESS.md「已知偏差 / 挂账事项」段：#2/3/4/6/7/8/9/10/11/12/17/18/23/28/30。已销账：#1/5/13/14/15/16/19/20/21/22/24/25/26/27/**29**。

#28 闭关 widget 端到端 test + #18 flutter build web 阻塞都同 Phase 5 一同处理。

### 5.6 数值估算教训（写新主线 / Boss 关时必读）

`feedback_wuxia_boss_balance_crosstier.md` 新 memory：章末大 Boss 想真难必须**跨 1-2 阶 realmTier**, 单纯上调同阶 HP/Atk 会被装备/心法乘数盖过。Week 5 stage_01_05 实测三档对比（xueTu / sanLiu / erLiu）作为锚点。

---

## 6. 关联文档

- **PROGRESS.md**「当前阶段」段（Week 5 全交付 + Week 6 候选）
- **phase3_summary.md** Week 5 段（T59+T60+T62 + 6 截图表 + 决策链 + 销账记录）
- **T62 验收 spec**：`docs/handoff/t62_visual_check_spec_2026-05-13.md`（3 场景 + 5 截图清单 + balance 备选路径）
- **前置 closeout**：`docs/handoff/week4_full_closeout_2026-05-13.md`（Week 4 师徒系统全交付）
- **新 memory 3 条**：
  - `~/.claude/.../memory/feedback_wuxia_boss_balance_crosstier.md`（Boss 跨阶设计规则）
  - `~/.claude/.../memory/feedback_flutter_subscreen_appbar_audit.md`（sub-screen AppBar 必检）
  - `~/.claude/.../memory/reference_pen_wuxia_flutter_run.md`（Pen flutter run SSH 工作流）

---

> 下一会话开局只读 PROGRESS.md 即可；需要「为什么 / Week 5 决策链」翻本文；需要「T62 验收 / balance 详细」翻 `t62_visual_check_spec_2026-05-13.md` + phase3_summary Week 5 段。
