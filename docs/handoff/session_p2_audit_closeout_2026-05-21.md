# P2 audit + 6 决策拍板 session closeout(2026-05-21 二段)

> **会话总览**:2026-05-21 主对话二段(/clear 后)· Mac opus xhigh ~50min · 1.0 路线图 P2 第二条主线启动准备 + 6 关键决策全拍板 + 桌面 8 nightshift worktree 清理
>
> **HEAD**:`99dccdd` → 本会话 commit 后将 push origin/main
> **测试基线**:1127 pass + 1 skip + 0 fail / analyze 0 issues(本会话只动 docs,无 code 变化)
> **PROGRESS.md**:96 行(在 100 cap 内)

---

## §1 会话三段落

### 1.1 段 A · P2 Phase 0 reality check audit(opus xhigh ~30min)
- Phase 0 四维 grep(memory `feedback_phase0_grep_two_axes`):
  - **维度 A schema**:**0 命中** `secondMainline / MainlineId` 层 — `MainlineProgress` 32 行单条主线 / `StageDef` 14 字段无 mainlineId
  - **维度 B caller**:8 处跨 feature 耦合(main_menu / chapter_list / tutorial×2 / event_service / phase2_seed / tower+seclusion 注释独立)
  - **维度 C 邻近目录**:`lib/features/mainline/` 已建 9 文件 1576 行(domain/application/presentation 三层全)
  - **维度 D UI widget**:`ChapterListScreen._chapters = [1,2,3]` 硬编码 · 单入口 `main_menu.dart:117`
- 产出:`docs/handoff/p2_mainline_audit_2026-05-21.md` 314 行(§0 grep 清单 / §1 schema 现状 / §2 caller 耦合 / §3 数据 delta / §4 6 决策推荐 / §5 改造影响面 / §6 工期 / §7 风险 / §8 ROADMAP 关系)

### 1.2 段 B · 6 决策拍板 + 执行路径拍板(用户回合)
- **6 decision 全方案 A · D5 简化为方案 B**:
  - D1 `MainlineProgress`+`StageDef` 加 `mainlineId` String
  - D2 String("primary"/"secondary")
  - D3 secondary 复用 ch1-3 + `stage_p2_*` prefix(UI 显示「序章/中卷/终卷」语义标签)
  - D4 ChapterListScreen 内分两段(MainMenu 不加按钮)
  - D5 **仅 Ch3 全通**(单门槛简化 · erLiu 保留作 service assert)
  - D6 第二主线不触发 tutorial(`if mainlineId=='primary'` 守卫)
- **执行路径拍板:保守路径**(audit §10):
  1. ✅ 当前会话:audit + decision 拍板,不动 schema
  2. ⭐ 下波:P1.1 A1/A3/A4 收口(sonnet 各 1-3h ≈ 1 工作日)
  3. 下下波:P1.2 §12 江湖恩怨+声望(opus xhigh 6-8h 独立模块)
  4. 再下波:P2.1.0 schema(opus xhigh 4-6h)
- audit doc §9 + §10 + §11 同步更新拍板结果

### 1.3 段 C · 桌面 8 nightshift worktree 清理(~10min)
- **来源确认**:2026-05-20 凌晨 03:20-03:48 P1 #45 Demo §8.4 polish nightshift 创建(opus --print 8 task 34min),**不是本会话产物**
- **内容核对**:
  - T01-T07 共 7 commit 已 cherry-pick 到 main(`1d0df4c` `8e345eb` `3aba3fb` `cf6cb32` `5bae60a` `3cfc052` `c3db590`)
  - T08 closeout 已被 main `944cc90 docs(P1 #45)` 取代
  - T01 设计 bug 已被 `93bf94b fix(synergy): T01 +3→+2 回退` 修复
- **清理动作**:8 个 worktree 全 `git worktree remove`,桌面只剩主仓库 `挂机武侠`
- **暂未清理**:8 nightshift/T01-T08 branch 保留待用户拍板删除(reflog 30 天可恢复)

---

## §2 关键决策定调(给 P2.1.0 spec 时用)

### 2.1 Schema 改造(D1+D2+D3)
```dart
// lib/features/mainline/domain/mainline_progress.dart
@collection
class MainlineProgress {
  Id id = Isar.autoIncrement;
  late int saveDataId;
  late String mainlineId;  // 新增 'primary' / 'secondary'(Isar 不支持 default,初始化必填)
  int currentChapterIndex = 1;
  List<String> clearedStageIds = [];
  List<DateTime> clearedAt = [];
}

// lib/data/defs/stage_def.dart
class StageDef {
  final String id;
  final String mainlineId;  // 新增,fromYaml 默认 'primary'
  // ... 其他 14 字段不变
}
```

### 2.2 命名约定(D3)
- secondary 主线 chapter 复用 1/2/3(每主线独立编号)
- stage id 前缀 `stage_p2_`:
  - `stage_p2_01_01` ~ `stage_p2_01_05`(序章 5 stage)
  - `stage_p2_02_01` ~ `stage_p2_02_05`(中卷 5 stage)
  - `stage_p2_03_01` ~ `stage_p2_03_05`(终卷 5 stage)
- UI 显示语义标签:「序章」/「中卷」/「终卷」(不显示「Ch1/2/3」防认知冲突)
- chapter narrative 文件:`data/narratives/chapters/chapter_p2_01.yaml` ~ `chapter_p2_03.yaml`

### 2.3 解锁条件(D5 简化)
```dart
// game_repository._enforceSecondaryMainlineUnlock(progress)
// 单门槛:第一主线 Ch3 全通
// erLiu assert 保留(玩家境界达 erLiu,通关 Ch3 时几乎必达,作 safety net)
```

### 2.4 Tutorial 守卫(D6)
```dart
// mainline_progress_service.recordVictory
if (mainlineId == 'primary') {
  await tutorialService?.advanceForStageCleared(stageId);
}
```

### 2.5 UI 分段(D4)
```dart
// chapter_list_screen.dart
// 第一段:第一主线 ch1-3(沿用)
// 第二段:第二主线 ch1-3 + lock overlay(若 D5 未满足)
// 分段标题:_MainlineGroupHeader('第一主线') + _MainlineGroupHeader('第二主线')
```

---

## §3 P2 工期估算(audit §6)

| Phase | 内容 | 估时 spec | 估时 opus xhigh 实测 ×0.6 |
|---|---|---|---|
| P2.1.0 schema + service | D1-6 落地 + build_runner + test | 4-6h | ~2.5-4h |
| P2.1.1 UI 分段 | ChapterListScreen 双段 + StageListScreen + locked | 2-3h | ~1.5-2h |
| P2.1.2 yaml ch1 | 5 stage + narrative + drop | 6-10h | ~4-6h |
| P2.1.3 yaml ch2+ch3 | 10 stage 同上 | 12-20h | ~8-12h |
| P2.1.4 装备扩 35→80 | 7 阶 × 流派 × ~6 件 + lore | 12-20h | ~8-12h |
| P2.1.5 心法扩 21→50 | 7 阶 × 3 流派 × ~7 心法 | 8-12h | ~5-8h |
| P2.1.6 武学领悟扩 35→70 招 | encounter +20 触发 +35 招 | 6-10h | ~4-6h |
| **P2.1 合计** | 主线 + 装备 + 心法 + 招式 | **~50-80h** | **~30-50h** |
| P2.2 心魔系统 | §12.1 心魔关卡 + 数值 + UI | 10-15h | ~6-10h |
| P2.3 飞升 + 遗物 transfer | E.2 + E.3 跨模块 | 15-25h | ~10-15h |

**ROADMAP 窗口**:M5-M10 6 月,工期充裕。

---

## §4 commit 链(本会话)

| # | SHA | 描述 |
|---|---|---|
| 1 | 即将创建 | docs(P2 audit): Phase 0 reality check + 6 决策拍板 · 保守路径 · 桌面 worktree 清理 |

---

## §5 待决 ops(下次会话开局或本次收尾)

1. **8 nightshift/T0X branch 删除**:reflog 30 天可恢复,内容已合 main,占 8 个 ref 名。**建议删**:
   ```bash
   git branch -D nightshift/T01 nightshift/T02 nightshift/T03 nightshift/T04 \
                  nightshift/T05 nightshift/T06 nightshift/T07 nightshift/T08
   ```
2. **本会话产物 commit + push**:本 closeout + PROGRESS + audit doc(3 files)

---

## §6 下波 P1.1 入口(新会话开局用)

### 6.1 任务清单
- **A1 师徒 E.1 收徒弹窗**(sonnet 1-2h)
  - 现状:`character_recruitment_service` 已建,UI 弹窗待补
  - 设计:战胜玩家境界 -1 阶的 NPC 后概率触发收徒弹窗(GDD §7.1)
  - 影响:character / save_data / UI 新 widget
- **A1 师徒 E.5 founder_ancestor_buff**(sonnet 1-2h)
  - 现状:`numbers.yaml inheritance.founder_ancestor_buff.enabled_when_alive: false`(CLAUDE.md §12.2 v1.5 决议 Demo 不实装,1.0 版本激活)
  - 设计:1.0 范围下需要实装(P1.1 收口意味本项)
- **A3 共鸣度满级体验完整化**(sonnet 2-4h)
  - 现状:joint_skill 倍率 4500 已在 numbers.yaml,但表现层未完整
  - 设计:joint_skill 释放表现层 + banner 时机 + 拆分提示 UI
  - 影响:battle_engine 表现层 + UI widget
- **A4 开锋 3 槽 build 内容扩**(sonnet 2h)
  - 现状:开锋系统已建(GDD §6.5),但每件装备开锋方案待审计
  - 设计:审计 35 件装备开锋槽位 + 方案匹配 build 多样性

### 6.2 Phase 0 reality check 必跑维度
- 维度 A schema:`grep CharacterRecruitment\|JointSkill\|Sharpen\|Resonance lib/`
- 维度 B caller:`grep founder_ancestor_buff numbers.yaml + game_repository._enforce*`
- 维度 C 邻近目录:`find lib/features/{cultivation,character,equipment,inheritance} -type f`
- 维度 D UI widget:已有 widget 清单 + 新增需求

### 6.3 模型选型
- **默认 sonnet**(高 high)— 每项 1-4h 短任务,memory `feedback_opus_print_short_task_speed` 实测 sonnet 短任务 OK
- **可升档 opus xhigh** 单项遇到复杂跨模块时(如 E.5 founder_ancestor_buff 涉及 inheritance + character + save_data + UI)

### 6.4 提示词体例
开局必读:PROGRESS.md(顶段)+ 本 closeout § 6 + memory `feedback_phase0_grep_two_axes` + `feedback_avoid_over_engineer_abstraction`

---

## §7 教训 sink

| # | 教训 | memory 落点 |
|---|---|---|
| 1 | Phase 0 四维 grep 再印证「目录已建 vs schema 0→1」误判预防 | `feedback_phase0_grep_two_axes`(已有,本次又一锚点)|
| 2 | 6 决策清单结构化 + 推荐 + 备选 + 影响面给用户拍板 | 未独立 sink(实战 ≥3 次再总结)|
| 3 | 保守路径 vs 激进路径:工期宽裕时优先 P1 收口防中间态体验缺失 | 未独立 sink |
| 4 | 桌面 worktree 清理时机:cherry-pick 完工后立即清,不过夜 | 未独立 sink(实战 ≥2 次再总结)|

---

**closeout 完结**。本会话 P2 audit + 6 决策拍板 + 保守路径拍板 + 桌面 worktree 清理 4 件事一波收口。下波 P1.1 A1/A3/A4 收口,sonnet 各 1-3h 各项独立,Demo polish 最快见效路径。
