# 设计案 · 角色等级 + 关卡推荐境界 + 掉落悬停预览 + 战斗表现优化

> 2026-06-26 · brainstorm 收敛(用户拍板 A+B+C+D 必做)· 1.0 长线打磨期
> 任务名:**第八阶段 · 成长可见化与战前信息**(批编追踪用)。
> 红线全程守:Lv 不破 §5.4 数值红线 / 不破 §5.3 三系锁死;掉落不显概率% (§2.1);表现层不写 BattleState (§5.7)。

## 背景与目标

用户提三个新点子 + 一个优化方向(均非旧「形与势」框架,旧框架清单已不可考、废弃)。目标:让**成长更可见**(角色 Lv)、**战前信息更透明**(推荐境界 + 掉落预览),并**继续打磨战斗表现**。

## A. 角色等级 Lv(新成长轴 · 全局连续 · 小幅有界加成)

- **数据**:`Character` 加 `int level = 1` + `int levelExp = 0`。saveVer `0.30.0 → 0.31.0`,旧档迁移补默认(level=1/levelExp=0)。
- **经验来源**:战斗 victory 现有 EXP 事件**并行**喂 levelExp(`levelExp += gainedExp`),与境界经验同源不同账。**全局连续涨,跨境界不重置**(境界是独立大门槛)。
- **升级**:`LevelService.applyLevelExp(ch, delta)` 纯函数,while-loop 消费 levelExp 升 level 至上限/不足。阈值走 numbers.yaml `level.exp_to_next_base + (L-1)*exp_to_next_per_level`。`max_level` 封顶后 levelExp 仍累加不破坏。
- **力量模型(红线安全)**:Lv 只注入三处既有 `derived_stats` 派生(均带 clamp 或无红线):
  - `maxHp += level * level.bonus_max_hp_per_level`(加在 clamp 前 → §5.4 血红线 20000 clamp 硬守)
  - `internalForceMax`:`(base + level*bonus_if_per_level) * mult` clamp 15000 硬守
  - `speed += level * bonus_speed_per_level`(速度无红线)
  - **不碰 DamageCalculator**:内力上限提升本就经 `内力×0.4` 间接增伤,优雅且避开伤害红线路径。**不解锁高阶装备/心法**(§5.3 境界锁死不动)。
- **初值(保守 · 待真机校,handoff 标注)**:max_level=100 / exp_to_next_base=120 / per_level=40 / hp_per_level=15(@L100 +1500)/ if_per_level=8(+800)/ speed_per_level=1(+100)。
- **UI**:角色面板显 `Lv N` + 经验条;战斗单位/选关卡轻量显 Lv。
- **红线测**:扩 `maxhp_extremum_redline_test` / 内力 extremum 测带 `level: max_level` 断言仍 ≤ §5.4 红线(clamp 保证);新增 `level_service_test`(升级曲线/封顶/迁移默认)。

## B. 关卡 / Boss 推荐境界指标(纯派生 · 复用 7 阶)

- **数据现成**:`StageDef.requiredRealm`(主线+副本)、`TowerFloorDef.requiredRealm`(塔)均已有 `RealmTier`;`EnemyDef` 带 `realmTier`+`realmLayer` → 可派生更细「推荐:二流·巅峰」(取敌队最强 tier/layer)。
- **helper**:`StageDifficultyAssessor.assess(recommendedRealm, playerRealm)` 纯函数 → `DifficultyVerdict`(够了/适中/偏高/送死),按境界差档(同阶/差1/差2/差3+,对齐 §5.5)给色。
- **不加数据字段、不改关卡 yaml**。

## C. 掉落悬停预览浮层(扩已有 loot_preview)

- **现状**:`lib/features/loot_preview/`「掉落传闻」已存在(5 桶:首通必得/常可得/偶可得/少有人得/江湖传闻,守 §2.1 不显%/不用 SSR 词),`loot_rumor_dialog` + 塔层 `tower_floor_card` Tooltip 在用。
- **改造**:抽统一悬停浮层 widget `StagePreviewHoverCard`(`MouseRegion` desktop hover),内含 **① 推荐境界 + 难度判语(B)+ ② 掉落传闻清单(复用现有桶 + `DropNameResolver`)**。
- **铺开**:主线选关屏(`stage_list_screen`)+ 副本 + 爬塔层(`tower_floor_list`/`tower_floor_card`),统一为 hover 浮层(塔现有 Tooltip 收编)。读现有 `dropTable`,**不新建掉落数据**。
- **回归守**:新加头部/卡片元素守 `feedback_listview_widget_test_viewport`(悬停浮层为 overlay 不占列表高度,避免挤出靠后 item);浮层读 config 走渲染分支不在轻量测崩(`feedback_battle_result_path_config_read_crashes_light_test`)。

## D. 战斗表现继续优化(纯表现层 · 守 §5.7 · 余力做几个标几个)

1. **题字命中分级**:破/斩/震/断题字按伤害量级(普攻/暴击/大招)缩放+配色强化(挂现有 `ImpactGlyphOverlay`/`playbackHoldMs`)。
2. **Lv 升级即时反馈**:战斗中升 Lv 弹小题字「晋」+ 流派色微光(搭 A · `BattleAction` 加布尔标记,纯表现不写战斗数值)。
3. **掉落金光分桶**:稀有桶越高金光越盛(搭 C 桶 · 纯表现层)。

## 架构与隔离

- A 域逻辑纯函数(`LevelService` / derived_stats 注入)可独立 TDD;B helper 纯函数独立测;C 表现层扩既有 feature;D 纯表现层。四块低耦合,A 的 Lv 字段被 B 难度对比 / C 浮层 / D 反馈共读。
- 配置全进 numbers.yaml `level` 新段(schema + 校验);文案全 UiStrings;不硬编码(§5.6)。

## 实装顺序(依赖)

1. **A**(save 字段 + LevelService + derived_stats + UI + 红线测)— 基底,B/C/D 读其 Lv。
2. **B**(难度 helper + verdict)— 独立。
3. **C**(悬停浮层,合并 B 难度 + 掉落传闻)— 读 B。
4. **D**(表现层 polish,搭 A/C)— 余力。

## 今晚「做完」判定

A+B+C 全闭环(TDD + analyze 0 + 全量绿 + 合 main);D 做几个标几个。saveVer bump 全仓同步断言(`feedback_version_bump_test_assert_sync`)。
