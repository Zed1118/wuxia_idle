# Phase 3 Week 4 D 师徒系统 全交付收尾（2026-05-13）

> 写给下一会话开局后接 Week 5 的 Mac Opus 自己看。
> Week 4 D 师徒系统 5 个 T 任务全部落地 + Pen Windows 视觉验收 8 截图通过 + tag `v0.3.0-w4` push origin。
> PROGRESS.md「当前阶段」段是单一信源；本文档补充「为什么这么做」与「下次开局必读」。

---

## 1. 一句话结论

Week 4 D 师徒系统 **T53→T58 一周交付**，3 师徒数据 schema + 种子 service + 师承遗物字段 + Character Panel Tab UI + 师承段 + 3v3 装配链集成测试 + Pen Windows 8 截图视觉验收全部到位。`main` HEAD `b74bb04`，tag `v0.3.0-w4` push origin。**529/529** 测试，analyze 0 issues。**T56/T57/T55 lineage buff 三大交付 UI 实测落地**：祖师 UI 内力 3800/4180（含 +10% lineage buff）/ 师承段 4 行完整 / stage_01_01 3v3 同阵 7 tick 速胜 + 3 流派克制全触发。销账 #25 + #26。

---

## 2. commit 时间线（本会话）

| # | hash | T | 类型 | 简述 |
|---|---|---|---|---|
| 1 | `e698190` | T56 | feat | 角色面板「师承」段 + Tab 三角色切换 + 销账 #26 |
| 2 | `88014eb` | T57 | feat | 3v3 师徒集成测试 + T55 战斗路径 lineage buff 补齐 |
| 3 | `ea13704` | T58 | docs | phase3_summary Week 4 段（T53-T58）+ T55 教训复盘 |
| 4 | `b658e85` | T58 | docs | T58 师徒系统 Pen Windows 视觉验收 spec |
| 5 | `5334714` | T58 | fix | T58 spec 环境段补 build_runner 步骤（Pen 首跑暴露） |
| 6 | `b74bb04` | T58 | docs | Pen 视觉验收 8 截图归档 + Week 4 全交付 |
| — | tag `v0.3.0-w4` | — | tag | Phase 3 Week 4 D 师徒系统 全交付 |

会话前 Week 4 T53-T55 commits：`9349626` / `ed8b183` / `1418176` / `efc50db` 详 closeout `week4_t53_t55_closeout_2026-05-13.md`。

---

## 3. 关键决策链 + 教训复盘（本会话新增）

### 3.1 T56 UI 决策（与用户对齐后实施）

- **UI-1 师承段位置**：方案 A 复用 `character_panel_screen` 内部加 section（vs 方案 B 主菜单新增「师徒」入口）
- **UI-2 3 角色切换方式**：方案 X 顶部 Tab（vs PageView 滑切 / 祖师页签内列徒弟）
- 实施时 `CharacterPanelScreen` 从 ConsumerWidget 改为 ConsumerStatefulWidget，加 `_selectedCharacterId` state；TabBar 从 `activeCharacterIdsProvider` 读 id 顺序

### 3.2 销账 #26 实现方式

`MainMenu` 从 StatelessWidget 改 ConsumerWidget + 新建 `_SeclusionMenuButton`，Riverpod `.when()` 异步读首位角色 realmTier。loading→Opacity 0.4 disabled；error/null 不可达分支 fallback `id=1/xueTu`（旧默认保留作兜底）。

### 3.3 T55 commit 描述误导教训（本会话发现 + 修复）

**T55 commit message 写"祖师战斗内力 +5%"，但实际只在 UI 落地。** `BattleCharacter.fromCharacter` line 171 当时直接 `maxInternalForce: character.internalForceMax`（不走 lineage 版）。T57 写集成测试时审计 fromCharacter 才发现，改用 `CharacterDerivedStats.internalForceMaxWithLineage(character, equipped, numbers)`。

这是 [feedback_layered_bugs] 典型场景：UI 显示对了（character_panel 直接调 lineage 公式）→ 误以为整条路径都通 → 战斗路径的潜在 bug 被掩盖。**教训：commit message 写"落地"前必须穷举接入点**，不只 UI 还有 BattleCharacter 装配链。

### 3.4 Pen 首跑环境基线失败（新记 memory `feedback_wuxia_pen_build_runner.md`）

T58 派 Pen 视觉验收，Pen analyze 报 6 个 undefined provider error。**根因**：`*.g.dart` 全 gitignored（phase1_tasks T01 决策"CI 必须先跑 build_runner"），T56 新加 `activeCharacterIdsProvider` 后 Pen `git pull` 拿不到生成产物。**修复**：T58 spec 环境准备段第一行加 `flutter pub run build_runner build --delete-conflicting-outputs`。

**未来 Pen 派单规则**：任何新增 `@riverpod` provider 后，spec 必须显式包含 build_runner 步骤。前几次 Pen 验收（T15/T16/T17/T52）没踩是因为没新 provider，Pen 本地老 .g.dart 复用，问题被掩盖。

### 3.5 T58 视觉验收特别亮点

stage_01_01 3v3 victory 截图（`08_battle_3v3_victory.png`）实测验证：
- 祖师 7094 HP / 大弟子 5687 HP / 二弟子 4071 HP（3 师徒装备/属性/境界全部独立装配）
- 7 tick 速胜，3 流派克制 ×0.75 全部触发（裂石掌/燕回式/暗影掌 vs 流民 3 流派）
- 战斗日志显示 1 暴击，符合 T56/T57 装配链端到端预期

---

## 4. 测试基线 deltas（本会话）

| 阶段 | analyze | test |
|---|---|---|
| 开工前（main `efc50db` 文档基线后） | 0 issues | 516/516 |
| T56 完成（e698190） | 0 issues | 522/522（+6：character_panel +4 / main_menu +2）|
| T57 完成（88014eb） | 0 issues | 529/529（+7：battle_state lineage 1 + master_disciple_battle 6）|
| T58 收尾（b74bb04） | 0 issues | 529/529 |

Week 4 累计：495（Week 3 末 P1 #1 后基线）→ 529（Week 4 末，+34）。

---

## 5. Week 5 起手者必读（下一会话开局看这段）

### 5.1 入场审计三件套

```bash
cd ~/Desktop/挂机武侠 && git log --oneline -5
flutter analyze
flutter test
```

应得到：HEAD `b74bb04` / 0 issues / 529 passed。任一不对停下贴差异。

### 5.2 Week 5 方向候选（5 选 1）

| 候选 | 阻塞 | Mac 端可做 | 备注 |
|---|---|---|---|
| **F** 主线扩到 15 关 + narrative defeat hook | 无 | ✅ | P1 #1 留尾（6→15 关 + 9 关 defeat 文案接入），DeepSeek 协作面较多 |
| **Phase 5** 收尾（DDD 整理 / Riverpod 3.x / Isar 4.x / flutter build web 解锁） | 无 | ✅ | 技术债清理，无新功能；切版本风险大；可拆分多 Week |
| **挂账 #28** 闭关 widget 端到端 test | Phase 5 service 注入 | ⚠ 部分 | 与 Phase 5 同源，建议合并到 Phase 5 |
| **挂账 #30** 闭关 3 维度扩展（technique_learn_rate / internal_force_growth / 节气日 / 子时阳刚） | §12 #7（节气清单）/ 农历库选型 / Character 修炼度字段 | ⚠ 部分 | 与 #25 同源（Demo 缺单一 character 视角注入），Phase 4 fixture 改造一并处理 |
| **C 奇遇** / **E 武学领悟** | §12 #6（机缘值累积规则） | ❌ 需用户决策 | 阻塞同源，需先决 #6 |

**推荐顺序**：F 主线扩容（无阻塞 + 推 Demo 内容量）→ Phase 5 技术债（解 #28/#18 等）→ 等用户决策 #6 后开 C/E。

### 5.3 起手前必问用户

下一会话开局**不要直接动手**，先问用户：「Week 5 选哪个方向？F / Phase 5 / 其他」。

### 5.4 重要的运行时副作用（仍生效）

- 祖师 starting 含 2 件 isLineageHeritage 装备 → 战斗 maxInternalForce +10%（**T57 已让 BattleCharacter 路径接 lineage 版**，区别于 T55 commit 误导前的"只 UI 接"）
- `SaveData.activeCharacterIds = [1, 2, 3]`（P5 路径），buildTeams 装 3 师徒

### 5.5 已知挂账（仍未销）

参考 PROGRESS.md「已知偏差 / 挂账事项」段：#2/3/4/6/7/8/9/10/11/12/17/18/23/28/29/30。已销账：#1/5/13/14/15/16/19/20/21/22/24/**25**/**26**/27。

---

## 6. 关联文档

- **PROGRESS.md**「当前阶段」段（Week 4 全交付 + Week 5 候选）
- **phase3_summary.md** Week 4 段（T53-T58 + 8 截图表 + 验收结论 + 设计决策）
- **决策草案**：`docs/handoff/week4_d_minimal_spec_2026-05-13.md`（D 方案 A + 3 决策点 ✓）
- **前置 closeout**：`docs/handoff/week4_t53_t55_closeout_2026-05-13.md`（T53-T55 决策链）
- **T58 验收 spec**：`docs/handoff/t58_visual_check_spec_2026-05-13.md`（3 场景 + 8 截图清单 + 反馈格式）
- **新 memory**：`~/.claude/.../memory/feedback_wuxia_pen_build_runner.md`（Pen 派单必跑 build_runner）

---

> 下一会话开局只读 PROGRESS.md 即可；需要"为什么 / Week 4 决策链"翻本文与 `week4_t53_t55_closeout_2026-05-13.md`；需要"T58 验收路径"翻 `t58_visual_check_spec_2026-05-13.md`。
