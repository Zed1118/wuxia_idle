# 爬塔与支线终局适配 · 实装 plan

**spec**:`docs/spec/2026-08-01-tower-extension-design.md`(2026-08-03 已拍板,8 项全按推荐)
**分支**:`worktree-tower-extension-spec`(批 D) → 批 A/B/C 各自独立 worktree
**目标**:塔 30→49 层 1:1 锚死 abs;其余 4 支线入口周目语义由「属性缩放」改「境界段推进」。

---

## 开工前须用户拍板(1 项)

**断魂帖里程碑分布**。现状硬编码「第 10/20/30 层一次性各一张」
(`tower_progress_service.dart:33,183` + `save_data.dart:134` 旧档补发防重)。
扩到 49 层后位置必须重定,且影响奖励经济总量。三个选项:

- **(a) 保持 3 张,位置改 16/33/49**——均匀分布,经济总量不变。**推荐**:扩层是内容深度改动,
  不应顺带改奖励经济;16/33 落在 erLiu/jueDing 段内,与 tier 边界不撞,语义干净。
- (b) 跟大 Boss 位走,7 张(7/14/21/28/35/42/49)——奖励翻倍,须重校经济。
- (c) 保持 10/20/30 三个位置不变——但 30 不再是塔顶,「问鼎江湖」语义断裂。

旧档兼容:三选项都须保留 `save_data.dart:134` 的补发防重,已发过的不重发。

---

## 批 A · 塔 30→49 层(主体 · 跨切面 · 约等于一个主线段体量)

**A0 · 解层数硬编码(前置阻塞,不做则新层进不去)** — ✅ **已完成**(2026-08-04,
分支 `worktree-tower-batch-a`,commit `f5f4ac71..e14d927c`)

起草时列「`tower_progress_service.dart` 三处」,**实测为 11 处生产行为点**,其中两处更硬:
- `progression_red_lines_validator.dart:20` `towerFloors.length != 30` 抛错 —— yaml 一扩层
  **启动期直接崩**,比「新层进不去」更早;已改 1:1 锚死上界语义(≤ `maxRealmLayers`)。
- `tower_progress_service.dart:149` `floorIndex <= 30`(recordClear 的 isFirstClear 上界)
  —— 起草版未列;不改则 31-49 层通关后 highest 卡 30 且不发奖,**静默无错**。

做法:`GameRepository.towerMaxFloor` 唯一派生点 + service 四处改注入式 `maxFloor`
(同既有 `allFloors`/`maxCycleCap` 体例)。另修 `main_menu` 完成判定、`boss_memory`
两处 Boss 层清单(改从 `bossKind` 派生)、`battle_test_menu` `towerFloors[29]`→`.last`、
`visual_acceptance_plan` 裸常量提为 `towerAuditFloorCount` + 补 coverage 守卫测。

**有意不动**:`ticketMilestoneFloors`(待拍板)、`isar_setup.dart:344`(0.21.0 前旧档迁移的
历史常量,非当前层数)、`strings.dart` 四条塔文案(`truth_source_guard_test:155` 已断言其
数字 == `towerFloors.length`,扩层不改会红而非静默失效,属 A2)。

**破坏证红(5 轮,逐处植入验证一一对应)**:①`:157` isFirstClear 上界 → 唯一红「超出顶层
不算首通」②`:184` 周目判定 → 唯一红「通关全塔 maxClearedCycle=1」③`:82` availableFloor
封顶 ④`:94` canChallenge 上界 ⑤`towerAuditFloorCount=20` → coverage 测红 2 条。
首轮暴露两个守卫缺口(真 30 层数据下硬编码与派生等价,抓不到)已补:
`tower_cycle_progress_test` 改用非 30 的 `_towerMax=12` 常驻化证红。

**A1 · 重排既有 30 层 → abs 1-30**
现状 floor 1-30 覆盖 abs 1/2/3/8/9/10(每 abs 5 楼),重排为 abs 1-30 各 1 楼。
**这不是纯追加,是整体重排**:既有敌人/掉落/叙事映射须逐层迁移,曲线整体重校。

**A2 · 新增 floor 31-49**(abs 31-49,~38 敌条目;敌队 3 人上限)

**A3 · Boss 位重排 14 个**
大 Boss = 每 tier 末层 7/14/21/28/35/42/49;小 Boss = tier 中点 4/11/18/25/32/39/46。
终局 Boss 走 vulnerability + ward 机制门槛,血量守 ≤60000 硬线(复用 floor25/30 体例)。
现有 `floor30_guardian_ward_{config,redline}_test.dart` 两文件须随塔顶迁移到 floor49。

**A4 · requiredRealm 守卫测**
钉死 `requiredRealm ≤ 该层敌人境界`(该字段经 `tower_entry_flow.dart:235` →
`equipmentTierCapOf` 决定稀有彩头装备阶),防未来配错造成 `GDD.md:593` 的「提前发放」。

**A5 · balance 重校**
`balance_simulator` 全曲线探针;验证 §1.3 的「净威胁增益 ~2.4×」解析推算(spec 标为待实测)。

**A6 · reconcile**
真相源守卫 5 条塔文案从 `towerFloors.length` 派生(`truth_source_guard_test.dart:155`)会自动跟随;
须现查的:10 个引用 `towerFloors` 的测试文件、`towers.yaml` 头注、`GDD.md:593`、
`asset_audit`/`idle_horizon`/`enhancement_material_supply` 三个 tools 测。
扫描指令:`grep -rn "30 层\|towerFloors" lib/ data/ test/ docs/ GDD.md`

**验收**:全量 `flutter test --no-pub` 0 fail · analyze 0 · A0/A3/A4 各破坏证红 · balance 探针不破红线。

---

## 批 B · 周目语义修正(新代码为主)

- **B1** `numbers.yaml` 加周目→境界段映射;**每周目抬 ≥3 阶**(spec §1.3:抬 1-2 阶落
  `diff_3_or_more` 死区完全无效)。同步 `cycle_evolution.assignment` 词条表(现只配到 cycle 2/3)。
- **B2** `_enemyToBattle`(`stage_battle_setup.dart:447-450`)消费境界段推进——现在境界取
  `enemy.realmTier` yaml 原值,scale 只乘 hp/attack/IF。
- **B3** 三系锁死校验:周目抬境界不得让掉落超出玩家可装备阶(§5.3)。
- **B4** 断魂庄/远征补周目接线:`gauntlet_battle_runner.dart:39` /
  `expedition_combat_runner.dart:57` 现调 `buildEnemyTeam` 不传 cycleIndex。
- **B5** 周目解锁绑玩家境界门槛(防低境界玩家撞差 3 阶硬墙)。

**验收**:全量 0 fail · 每个 B 切片各破坏证红 · 5 入口逐个验周目生效。

---

## 批 C · 8 张新 Boss 立绘

codex image_gen 自主批(配方见 memory `reference_codex_image_gen_art_pipeline`);
脚底 fraction 校准 + `character_avatar.dart` 注册 + 真机战斗屏目检。
普通层复用主线敌池(135 张覆盖 abs 1-49),不出新图。

---

## 当前恢复点

- **状态**:**批 A 已合 main(PR #114/#115)+ 批 B 主体完成**(B1-B5 + 净威胁实测),
  分支 `worktree-tower-batch-b`(commit `075b5346` B1+B2 / `ae0dbe52` B4+B5 +
  B3/B6/账本收尾待 commit)
- **最后完成(批 B · 2026-08-04)**:B1 `realm_advance` 配置+解析(tiers 3/cap 3/
  margin 1/奖励 0.25,远征深度里程碑 [20,40]);B2 `_enemyToBattle` 三轴消费
  (effTier→内力派生/防御率档/差距修正,白名单 lightFoot+massBattle,断魂庄/远征
  runner 显式开);B3 摸底证实掉落基准阶全锚静态配置,结构性满足 §5.3,守卫测钉死;
  B4 断魂庄/远征从零建周目(run.cycleIndex+duanhunClearedCyclesMax,零迁移)+
  奖励乘数接线;B5 `CycleRealmGate` 三重门槛(顺序∩cap∩境界)+enter/dispatch
  硬守卫+两屏 `CycleSelectLayout` 复用;**净威胁实测 ×5.11**(spec §1.3 挂账销账,
  calculator 单发交换比口径,第一版整场承伤被自证零负载否决)
- **批 B 拍板(2026-08-04)**:周目体例=主线式自由回选;高周目奖励本批一并做;
  cap 3/margin 1 按推荐;远征(无终点无通关)解锁=深度里程碑
- **塔 cycle2 重校结论**:诊断 3/3 绿(参数本批零改动),≥80% 语义维持,无需调参
- **下一步**:批 C 8 张 Boss 立绘(18/21/25/28/35/39/42/46 现为主线敌池占位,
  codex image_gen)+ 塔 49 层 1280×720 视觉 smoke
- **已跑验证**:见 PROGRESS 顶段批 B 条目(全量数字以其为准)
- **阻塞项**:无
