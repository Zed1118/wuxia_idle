# 第七阶段 批一 · 战后体验:英雄镜头 + 珍稀掉落触发细化

> 设计稿(brainstorm 定稿)。上游 master spec `playability_upgrade_master_spec_2026-06-09.md` §六/§七/§13 P3。
> 第七阶段 = P2/P3 续作,分三批:**批一·战后体验(本稿)** / 批二·Boss 机制标准 / 批三·队伍成长。
> 阶段定调:1.0 长线打磨期,质量优先(CLAUDE.md §7)。

## 1. 背景与范围

当前战后流程(交互式胜利路径)= `presentVictoryCeremony`(`stage_entry_flow:218` / `tower_entry_flow:587`)→ 爆品镜头 or 简版「勝」。败北诊断三段式 `BattleDiagnosis` **已完整 wire**(`victory_overlay.dart`,本批不改)。缺口:**英雄镜头完全缺失**;珍稀掉落仅 binary gate(`treasureDrop.min_tier=zhongQi`,重器+每次)。

本批交付:
1. **英雄镜头**(新建):Boss 首胜触发,本场最高输出角色立绘切入。
2. **珍稀掉落触发细化**:加「利器+首次获得」,重器+每次保留。

## 2. 决策汇总(用户拍板)

- 英雄镜头呈现 = **立绘切入**(复用现成 `founder.png`/`first_disciple.png`/`second_disciple.png`,无需新美术)。
- 触发范围 = **仅 Boss 首胜**(主线章末 Boss + 爬塔大 Boss),符合「最小版」+ 重打不重复轰炸。
- 出镜角色 = **本场最高输出**(反映「谁是这仗的英雄」,与 `totalDamage` 同源)。
- 珍稀掉落 = **按 spec 细化**(本批做装备 tier;技能书展示见 §6 deferred)。

## 3. 流程编排

master spec §7.1 顺序:胜负定格 → 英雄镜头 → 珍稀掉落 → (复盘已在 overlay)。新流程:

```
战斗结束(leftWin)
  → [新] presentHeroCameraIfBossFirstClear(...)   仅 isBossStage && isFirstClear
  → presentVictoryCeremony(drops, treasureGate)    不变
```

- 新编排函数 `presentHeroCameraIfBossFirstClear(context, state, {required bool isBossFirstClear})`,与 `presentVictoryCeremony` 并列同文件(`victory_ceremony.dart`)。
- 调用点 2 处:`stage_entry_flow`(已有 `stage.isBossStage && isFirstClearStage` at :844 一带)+ `tower_entry_flow`(已有 `isFirstClear`,加 isBoss 楼层判定)。
- **离线/挂机天然不触发**:`presentVictoryCeremony` 全仓仅这 2 个交互 flow 调用,离线走 `offline_recap_service`(§5.5 守)。英雄镜头插同两处,同样不挂机触发。

## 4. 数据派生 `TopDamageContributor`(纯函数,不写 BattleState)

新 `lib/features/battle/domain/top_damage_contributor.dart`,类比 `BattleStatsSummary.from`:

- `TopDamageContributor.from(BattleState state) -> TopDamageContributor?`
- 遍历 `state.actionLog`,按 `action.actorId` 聚合 `attackResult.finalDamage`;仅计玩家方(`actorId` 对应 `teamSide==玩家侧` 的 `BattleCharacter`)。
- 取伤害和最大者;平局取 `slotIndex` 小者(确定性)。无玩家方伤害记录 → 返回 `null`(调用方退化:不弹镜头,直接走 ceremony)。
- 字段:`{ actorId, totalDamage }`。立绘/名/境界由调用方用 `actorId` 解析 `Character`(`portraitPath`/`name`/`realmTier`)。

## 5. `HeroCameraOverlay` widget(立绘切入)

新 `lib/features/battle/presentation/hero_camera_overlay.dart`,纯展示(类比 `VictoryOverlay`):

- 径向 vignette 暗幕 + 金光晕。
- 角色立绘 `Image.asset(portraitPath, errorBuilder: 退化为纯题字块)`,侧滑入 + 放大(`AnimationController`)。`portraitPath==null` → 同退化路径(不破布局)。
- 名号横幅(角色名 + 境界/流派)+「击破 {bossName}」题字 + 印章符(复用 `WuxiaUi.ceremonyRedSeal`)。
- 2-4s 自动消失 + 点击跳过(同 `showVictorySealFlash` 的 `showGeneralDialog` 模式)。
- 文案进 `UiStrings`(镜头标题/击破句式);时长/位移/缩放参数进 `numbers.yaml` 新 `post_battle.hero_camera` 段 + `numbers_config.dart` 对应 config 类。

## 6. 珍稀掉落触发细化

`pickTreasureHighlight` 现按 `tier >= minTier`(zhongQi)选;`playTreasureDropIfAny` 据此弹。细化:

- **重器(zhongQi)+ → 每次**:现状保留(`min_tier=zhongQi` 不变)。
- **利器(liQi)+ 首次获得 → 触发**:`playTreasureDropIfAny` 加可选参 `extraDisplayTiers: Set<EquipmentTier>`;`pickTreasureHighlight` 选取条件改为 `tier >= minTier || extraDisplayTiers.contains(tier)`。
  - flow 层(有 Isar)计算 `extraDisplayTiers`:若本次掉落含 liQi 装备,查持久化后 liQi-tier 总数 == 本次掉落 liQi 件数(即先前为 0)→ 首次,加入 `{liQi}`。掉落已在 ceremony 前 `putAll` 入库,故用「总数 − 本次件数 == 0」判先前无。
- **技能书(真解必触发/残页集齐)→ deferred 批二**:技能书/残页走独立 skill-drop hook(不在 `DropResult`),且真解书源自章末 Boss 首胜,与批二 Boss 掉落改造同时机做更自然。
- **材料/熟练突破强展示 → 不做**(YAGNI,留 P4 材料经济)。
- **普通掉落不强展示**:走简版「勝」(现状)。

## 7. 红线守法(GDD §5)

- 纯表现层:不写 `BattleState`、不调伤害公式、不改掉落经济/概率(§5.4)。`TopDamageContributor` 只读 actionLog。
- 数值进 `numbers.yaml`,中文进 `UiStrings`(§5.6)。
- 在线=离线(§5.5):英雄镜头/镜头动画只在交互结算路径,离线汇总不播(§3 已证)。
- 爽感走表现层不走数值膨胀(§5.7 + master spec 硬约束)。

## 8. 测试计划

- `top_damage_contributor_test.dart`:单角色取该角色 / 多角色取最高 / 平局取 slotIndex 小 / 仅计玩家方(敌方伤害不入)/ 无玩家伤害返回 null。
- `hero_camera_overlay_test.dart`(widget):立绘渲染 / `portraitPath==null` 与 asset 缺失走 errorBuilder 不破布局 / 名号 + 击破题字文案 / 点击跳过回调。
- 触发 gate 测:非 Boss 不弹 / Boss 非首胜不弹 / Boss 首胜弹(经 flow 编排函数,纯逻辑层断言,不走重型战斗 harness)。
- 珍稀掉落细化:`pickTreasureHighlight` 加 `extraDisplayTiers` 后 —— liQi 在集合内被选 / 不在集合内按 minTier 过滤 / 首次判定纯函数(总数−本次件数==0)。
- 全量回归 `flutter test` + `flutter analyze` 0。

## 9. 文件清单

**新增**:`top_damage_contributor.dart` / `hero_camera_overlay.dart` + 两测文件 + `post_battle.hero_camera` numbers 段 + config 类 + UiStrings 词条。
**改动**:`victory_ceremony.dart`(加编排函数)/ `stage_entry_flow.dart` + `tower_entry_flow.dart`(调用点 + extraDisplayTiers 计算)/ `treasure_drop_overlay.dart` + `pickTreasureHighlight`(extraDisplayTiers 参)/ `numbers.yaml` + `numbers_config.dart` / `strings.dart`。

## 10. 明确不做 / deferred

- 战后复盘「队伍」跳转目标 → 批三(队伍成长,届时有编成界面才可跳)。
- 技能书/残页珍稀展示 → 批二(Boss 掉落改造同批)。
- 材料/熟练突破强展示 → P4 材料经济。
- 场景 zoom 镜头(英雄镜头方案 C)→ 不做(工程量/风险最大,单帧不易验收)。
