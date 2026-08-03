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

**A0 · 解层数硬编码(前置阻塞,不做则新层进不去)**
`tower_progress_service.dart` 三处硬编码 30 改为从 `allFloors` 派生:
`:78` `availableFloor` 封顶 / `:89` `canChallenge` 上界 `floorIndex > 30` / `:176` 周目完成判定。
另 `enums.dart:238-240` 注释「30 层共 6 Boss / major 在 10/20/30」须同步。
**破坏证红**:把塔层数据临时截到 20 层,三处派生断言必红。

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

- **状态**:批 D 进行中(spec 已修订完成,plan 本文件)
- **最后完成**:spec 修订 149 行——4 条订正(断档成因/0.05 措辞/70 层否决/D 方案前提证伪)
  + 全入口境界分布表 + 境界差阶梯函数表 + 8 项拍板结果 + 实装批次
- **下一步**:批 D commit/push/draft PR → 用户拍断魂帖里程碑分布 → 开批 A(A0 先行)
- **已跑验证**:批 D 纯文档,无需测试;spec 全部数字本会话实测(HEAD `36fe9d80`)
- **阻塞项**:批 A 开工前须拍断魂帖里程碑分布(见本文开头)
