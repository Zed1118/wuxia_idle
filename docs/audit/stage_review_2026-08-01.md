# 挂机武侠 · 阶段性全面审查（2026-08-01）

> 代码态 `42d7e00c` · 六维体例沿 `full_project_review_2026-07-02.md`
> 全部数字为本会话实测，非转抄。

## 总评

**健康度高，无 P0。** 主线内容与美术已闭环，1.0 打磨期。工程门禁密（40 个守卫测文件、
allowlist 全部极小且带棘轮），全量 4780/0、analyze 0 issue、CI 双 job 与 Windows release 均绿。

本次审查的核心产出不是发现存量 bug，而是从当天修掉的章数 drift **归纳出一类系统性缺口**（P1-1）。

## 实测基线

| 维度 | 实测 |
|---|---|
| 代码 | `lib/` 519 文件 / 123,100 行（不含 `.g.dart`）· 50 feature 模块 · 610 provider |
| 测试 | `test/` 729 文件 · 全量 **4780 pass / 0 fail** · `skip: true` **0** 处 |
| 数据 | `data/` 652 yaml · 主线 21 章 105 关 · 塔 30 层 · 心魔 7 关 · 轻功 5 · 群战 5 · 断魂庄 3 |
| 内容 | 装备 83 · 心法 49 · 招式 87 · 奇遇 68 · 典故 83 · 事件 68 · 叙事 348 |
| 资产 | 693 跟踪文件 / 113M · 缺图 allowlist **0 条** |
| 门禁 | 守卫测 40 文件 · 中文散写 allowlist **2 条**（只减不增棘轮）· 桌面语义 6 条 |
| 发布 | main CI 绿 · Windows release 连续 3 周 success（07-13/20/27） |
| 仓库 | 3891 commit（近 30 天 1354）· `.git` 1.1G · 工作树干净同步 |

## P0

**无。**

## P1

### 1 · 规模类文案「写死数字 + 无守卫」缺口（本次新发现）

2026-07-31 逮到 `mainlineRouteMapSubtitle` 写着「十六章」而实况 21 章，已修并把两条 UI 文案
纳入 `truth_source_guard_test`。但**同类文案还有约 11 处仍在守卫之外**：

- 塔 30 层 ×5（`mainMenuTowerHint` / `mainMenuTowerCompleteStatus` / `towerNextMilestoneComplete`
  / `towerCycleReadyHint` / `sweepTowerButton`）
- 心魔 7 关 ×2（`mainMenuInnerDemonHint` / `innerDemonEmpty`）
- 轻功 5 关 ×1 · 群战 5 关 ×1 · 断魂庄 3 关 ×2（`gauntletSubtitle` / `gauntletEnemiesSection`）

**当前值逐个实测全部正确**（塔 30 ✅ 心魔 7 ✅ 轻功 5 ✅ 群战 5 ✅ 断魂庄 3 ✅），所以**不是活 bug**；
风险是**扩内容时会静默 drift**——章数那处正是这样活了 5 个章的。既有测试引用常量本身
（`find.text(UiStrings.xxx)`）不钉字面量，拦不住。

> 核对期间两处量测假报，均已证伪：`grep -c 'stageType: innerDemon'` 报 8（第 8 个是**注释行**，
> 生效条目 7）；`towers.yaml` grep 报 60（`- floor:` 与 `- id:` 双模式重复计数，实为 30 层）。

**建议**：沿 `truth_source_guard_test` 既有体例扩一批断言，各玩法规模从生产 yaml 派生。~40min。

### 2 · 依赖锁死差距在拉大

`analyzer` 钉 **9.0.0** 而上游已 **14.1.0**（差 5 个大版本），`_fe_analyzer_shared` 92 vs 105。
根因是 isar_community fork 不支持 analyzer ≥12，已登记 `BACKLOG.md` §三#2。差距每月在扩，
拖久了升级成本非线性上升，且拿不到新 lint 与安全修复。

**建议**：季度性查一次上游 isar_community 是否已支持，别等到必须升的时候才动。

## P2

- **`audioplayers` 6.7.1 → 6.8.1 值得一查**：`windows-release.yml` 头注明写「解除条件 =
  audioplayers 升级到支持 VS2026 的版本」，目前 runner 钉在 `windows-2022`。6.8.1 若已支持即可解钉。
- **4 处 `TODO(batch3-probe)`**（`expedition_service:111` + `boss_gauntlet_config` ×3）：同源，
  指向断魂庄奖励数值/命名待定案。生产里真 TODO 仅此 4 处，其余 6 处在 test/ 里是**断言文案不含
  TODO 的守卫**，属资产非债。
- **断魂庄 / 百草岭远征无 audit 路由**：已入 `BACKLOG.md` §二#5，是 153 关视觉验收覆盖外唯一缺口。
- **`.git` 1.1G**：历史包袱主要来自旧 `Builds/` blob（约 484MB）。2026-07-11 已明确结论
  **不做 filter-repo / force push**，此处仅作现状登记，不建议动。
- **大文件 top3**：`strings.dart` 3938 / `numbers_config.dart` 3175 /
  `visual_route_host.dart` 3160。前两者是集中 sink（合法体例），第三个是 debug 域。
  2026-07-10 已拍板「不再排一次性机械重构，按真实热点拆」，维持。

## 健康面（实测确认，六维）

1. **发布链路** — main CI 绿；Windows release 连续 3 周 success；`macos-build` + `test` 双 job 常态
2. **代码与架构** — analyze **0 issue**；生产真 TODO 仅 4 处且同源；50 feature 模块边界清晰
3. **数据与内容** — 内容规模全面超 Demo 目标；`encounters 68 = events 68` **逐值吻合**，§8.1 联结完整
4. **测试** — 4780 pass / 0 fail；`skip: true` 0 处；守卫测 40 文件；红线族覆盖 balance + data 两层
5. **资产** — 缺图 allowlist **0 条**；693 文件 113M；pubspec 声明有守卫测兜底
6. **文档真相源** — GDD 头部状态块实测正确（cap 49 / 21 章 105 关）且被守卫测钉住；
   过时数字已显式标注「历史快照」；`PROGRESS.md` 96 行、`BACKLOG.md` 40 行，均在上限内
7. **红线** — §5.3 三系锁死三个校验点全部在位
   （`isEquippableAtRealm` 14 处 / `techniqueTierCapOf` 8 处 / `canEquipEncounterSkillByTier` 2 处）

## 修复路线图（附推荐）

| # | 项 | 级别 | 预估 | 推荐 |
|---|---|---|---|---|
| 1 | 规模类文案扩守卫（P1-1） | P1 | ~40min | **推荐先做**：本次审查唯一新增缺口，成本低、防的是已发生过一次的 drift |
| 2 | 断魂庄 / 远征补 audit 路由 | P2 | ~1h | 次选：唯一真覆盖缺口，做完视觉验收全覆盖 |
| 3 | 查 audioplayers 6.8.1 是否解 VS2026 | P2 | ~15min | 顺手：一条命令的事，解了就能松开 windows-2022 钉 |
| 4 | 复刻批余下 2 分 / B3 观感调档 | P2 | 40/20min | 已在 BACKLOG §二#6·#7 |
| 5 | isar/analyzer 三角 | 锁死 | — | 只能等上游，季度复查 |
