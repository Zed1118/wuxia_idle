# T62 · 主线 15 关 + 战败 narrative 视觉验收（Pen Windows）

- **日期**：2026-05-13 派单 / Pen 执行日期待定
- **执行方**：Pen + Windows RDP 桌面（不能 SSH，需登 GUI）
- **分支 / commit**：main @ `f4bad18`
- **关联**：PROGRESS.md「当前阶段」/ Week 5 T59+T60 代码已落地（530/530 测试 + analyze 0 issues + 销账 #29）
- **截图归档**：`docs/screenshots/phase3_w5/`（已建空目录）

通过后 Mac 端：phase3_summary.md Week 5 段补完 + tag `v0.3.0-w5` push origin。

---

## 0. 环境准备（Pen 物理机 RDP 内）

```powershell
cd F:\Projects\wuxia_idle
git fetch
git checkout main
git pull
git log --oneline -3
# 应看到:
#   f4bad18 feat(phase3-w5): T59 主线 6→15 关 + T60 战败 narrative hook（销账 #29）
#   52b0363 docs(handoff): Week 4 全交付 closeout（Week 5 起手者必读）
#   b74bb04 docs(t58): Pen 视觉验收 8 截图归档 + Week 4 全交付
```

**先跑 build_runner**（沿用 W4 教训：`*.g.dart` 全 gitignored）：

```powershell
"F:\Flutter SDK\flutter_windows_3.41.5-stable\flutter\bin\flutter" pub run build_runner build --delete-conflicting-outputs
```

期望末尾输出 `Succeeded after Xs with N outputs`。失败立刻报回。

跑基线：

```powershell
"F:\Flutter SDK\flutter_windows_3.41.5-stable\flutter\bin\flutter" analyze
"F:\Flutter SDK\flutter_windows_3.41.5-stable\flutter\bin\flutter" test
```

期望：analyze 0 issues / 530 tests pass。任一失败立刻报回。

**清开发态存档**（W4 留下的 cleared 列表会污染 Ch1 通关旁证场景）：

```powershell
rmdir /s /q "$env:APPDATA\wuxia_idle"
```

启动：

```powershell
"F:\Flutter SDK\flutter_windows_3.41.5-stable\flutter\bin\flutter" run -d windows
```

---

## 场景 A · 关卡列表 15 关三态渲染（核心验收 1）

**前置**：清存档新进游戏 → 主菜单点「Phase 2 调试场景」→ 点「P5 师徒系统」（祖师/大弟子/二弟子入阵）→ 返回主菜单 → 点「主线剧情」→ 进入 ChapterListScreen。

| 步骤 | 操作 | 期望 | 截图 |
|---|---|---|---|
| A1 | ChapterListScreen | 3 章卡都渲染：Ch1「学武出山」**进行中** / Ch2「武林初识」**锁** / Ch3「名扬江湖」**锁** | `01_chapter_list_all_locked.jpg` |
| A2 | 点 Ch1 进入 StageListScreen | 5 关全名渲染（**山门之外** / **荒山野店** / **黑风岭** / **洛阳城外** / **风雨渡口**）；01「可挑战」chip + 02-05 锁图标（4 个）+ 副标题「通关前一关解锁」 | `02_ch1_5stages_all_locked.jpg` |
| A3 | 返回 ChapterListScreen 点 Ch2 → 应**不可点**（锁） | 锁图标 + 「需通关 Ch1」副标题，无法 push StageListScreen | `03_ch2_locked.jpg`（可选）|

**A 通过条件**：A1 / A2 截图清晰；Ch1 关名与 T59 yaml 完全一致（不出现旧名「山道试剑/林间伏击/黑风寨/一战封王」）。

---

## 场景 B · 章末 Boss 关战败触发 defeat narrative（核心验收 2 · 销账 #29）

**前置**：场景 A 完成。需要先通过 stage_01_01-04 才能挑战章末 stage_01_05；为节省时间用以下捷径——

**捷径**：返回主菜单点「Phase 2 调试场景」→ 找「主线全通关 Ch1 1-4 关」按钮（若无则按 B0 走真实通关；否则跳 B1）。

> 注：当前 Phase2TestMenu **没有**「跳通关」按钮，所以走 B0 真实通关。stage_01_01-04 玩家方实力足够，每关用大招 2-3 回合可清。

### B0 · 真通 Ch1 01-04（约 5-7 分钟）

| 步骤 | 操作 | 期望 |
|---|---|---|
| B0-1 | StageListScreen 点「山门之外」 | opening 剧情「山门之外·启」→ 进战斗，3 流民弱敌速胜 |
| B0-2 | victory → 「山门之外·胜」→ pop list | 01 显示 cleared icon，02 解锁 |
| B0-3 | 顺次通 02 荒山野店 / 03 黑风岭 / 04 洛阳城外 | 01-04 全 cleared，05 风雨渡口「可挑战」 |

**注**：04 洛阳城外是小 Boss（mult 1.6），若卡关可先去角色面板/仓库提升装备强化等级再战。卡关>3 次直接报回判断数值是否需调。

### B1 · 章末大 Boss stage_01_05 风雨渡口战败 → defeat narrative

| 步骤 | 操作 | 期望 | 截图 |
|---|---|---|---|
| B1-1 | 点「风雨渡口」 | opening 剧情「风雨渡口·启」（撑伞高人 + 渡口刀客 / 剑客）| 不截 |
| B1-2 | 进入战斗 | 3v3，敌方 3 名 xueTu·圆熟（HP 3200-3500 / Atk 150-160）；玩家方 3 师徒（祖师 4180HP / 大弟子 3800HP / 二弟子 3500HP）| 不截 |
| B1-3 | 战斗到玩家全员阵亡（约 10-15 tick）| 战败弹窗或自动 defeat 状态 → BattleScreen pop | 不截 |
| B1-4 | **关键**：自动 push NarrativeReaderScreen 显示「风雨渡口·败」| 标题「风雨渡口·败」+ 3 段文案（撑伞人没追 / 隔河听不清的话） | `04_stage_01_05_defeat_narrative.jpg` |
| B1-5 | 点屏幕/返回 | pop 回 StageListScreen，stage_01_05 仍**未 cleared**（不记进度）| `05_stage_01_05_still_available.jpg` |

**B 通过条件**：B1-4 截图清晰显示「风雨渡口·败」title + 文案（不是「[剧情待补]」）；B1-5 关卡列表 05 仍可挑战，不出 cleared icon。

**若玩家方意外打赢**（lineage buff 实际效力高估）：连续重试 2 次仍胜 → 报回，T59 数值需调（敌方 baseHp/Atk 上浮 20%）。

---

## 场景 C · 章内普通关战败无 defeat narrative（验收 hook 分流）

**前置**：场景 B 完成（stage_01_05 已留在「可挑战」状态）。回到 Ch1 StageListScreen。

**捷径**：场景 B 战败后玩家全员死亡状态下，stage_01_02 之类的普通关在玩家方仍空血时挑战会立刻败（也可重启游戏，但耗时）。

> 实际更简单：清存档 → 重新 P5 种子 → 直接挑 stage_01_01 但**点战斗 UI 不操作**让玩家阵亡（理论上敌方会先死，所以走 stage_01_02 卡 ATK 不足更稳）。如果验不出，用 B0 通关后保留 stage_01_02 状态，**临时改 yaml 把 stage_01_02 敌方 baseHp 上调到 9999**（验完回滚）跑一次战败。

| 步骤 | 操作 | 期望 | 截图 |
|---|---|---|---|
| C1 | 触发任意章内普通关（非 4/5）战败 | BattleScreen pop | 不截 |
| C2 | **关键**：直接返回 StageListScreen，**不**弹 NarrativeReaderScreen | 列表显示同 B1-5 状态，无中间剧情屏 | `06_normal_stage_defeat_no_narrative.jpg` |

**C 通过条件**：C2 截图清晰显示直接 list 状态（无 narrative 阅读界面残留）。

**注**：C 场景验证「defeat hook 仅在配 narrativeDefeatId 的 Boss 关触发」分流逻辑。若验收成本高可放过，已有 widget test 间接覆盖（章内 3 关 stage.narrativeDefeatId == null）。

---

## 收尾 · 报回 Mac 端

通过后在对话里贴：

1. `01_chapter_list_all_locked.jpg`
2. `02_ch1_5stages_all_locked.jpg`
3. `04_stage_01_05_defeat_narrative.jpg`（**最关键**）
4. `05_stage_01_05_still_available.jpg`
5. `06_normal_stage_defeat_no_narrative.jpg`（如完成 C）

3 + 4 张照片就足够通过验收。若卡 B0 真实通关，先报回 B0 数值平衡问题。

通过后 Mac 端动作：

- 截图 commit 入仓 `docs/screenshots/phase3_w5/`
- `phase3_summary.md` 写 Week 5 段（T59+T60+T62）
- tag `v0.3.0-w5` push origin

---

## 已知踩坑 / FAQ

- **build_runner 必跑**：W4 教训，gitignored `*.g.dart` 不在仓库
- **存档清理**：W4 SaveData 字段长度差异同问题，T59 没新加 Isar 字段所以不必须，但保险起见清
- **stage 名以新 yaml 为准**：旧名「山道试剑/林间伏击/黑风寨/一战封王」已废，看见即报错
- **CLAUDE.md 数值红线**：玩家血 ≤ 20000 / 内力 ≤ 15000 / 普伤 ≤ 8000，验收期间若触发越界立刻报回
