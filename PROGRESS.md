# 挂机武侠 · 开发进度

> Mac 端 Claude Code + Opus 4.7 维护。会话开始主动读取，任务完成主动更新。
> 总行数控制在 100 行内，超出归档到末尾。

## 当前阶段

**Phase 4 W14-3 整体闭环 奇遇/武学领悟 vertical slice 完成**(2026-05-15)。W14-3-A(skill 池 + 装备 UI,commit `9320286`)+ W14-3-B(DeepSeek 12 条 events 文案,commit `db046fa`)+ W14-3-C(dialog 节奏精修 commit `da61652` + Codex Pen 视觉验收 commit `db15252` 6 张截图 5 PASS + 1 WARN)+ `seedVisualCheckW14_3` fixture(commit `bcc8031`,预 unlock 7 招 tier 1-7 各 1 + 大弟子装 tier 3 + Phase2TestMenu「VC14_3」按钮)全落地。**610/610 测试,analyze 0 issues**。**待打 tag `v0.5.0-w14`**。下批可派 Codex 用 seedVisualCheckW14_3 跑完整 EncounterSkillSection unlocked 态(bottom sheet 列表 + lock icon)。

## 已完成(近 W6 起,早期归档见末尾)

- **Phase 4 W14-3 整体闭环**(2026-05-14 to 2026-05-15,xhigh):① **W14-3-A** 奇遇专属 skill 池(`data/encounter_skills.yaml` 35 招 / 7 阶 × 5,含 W14-1/W14-2 已引用 6 招)+ SkillDef 加 nullable tier + isEncounterSkill getter + Character.equippedEncounterSkillId 角色级 slot(schema 0.6.0→0.7.0)+ EncounterService.equipEncounterSkill 返回 sealed result(三系锁死 GDD §5.3)+ BattleCharacter 装载 3+1 招 + CharacterPanelScreen EncounterSkillSection widget(+17 test);② **W14-3-B** DeepSeek 补 W14-2 新 12 条 events 文案(`data/events/<id>.yaml`,文风沿 W14-1 体例);③ **W14-3-C** EncounterDialog 节奏精修(入场 AnimatedOpacity 500ms easeOut + opening↔outcome AnimatedSwitcher 420ms FadeTransition,抽 _OpeningStage/_OutcomeStage)+ Codex Pen 视觉验收 6 张截图 5 PASS + 5-1 fade-in 中间帧 WARN 降级(截图工具抓不到 500ms 中间帧,非产品 bug);④ `seedVisualCheckW14_3` fixture seed(预 unlock tier 1-7 各 1 招 + 大弟子 id=2 erLiu 预装备 tier 3 skill,Phase2TestMenu「VC14_3」按钮,+3 phase2_seed_service test + phase2_test_menu_test 6→7 按钮断言修正)。**610/610**(W14-2 590 → +20 net),analyze 0 issues。详 `docs/handoff/week14_3a_encounter_skill_pool_2026-05-14.md` + `codex_w14_3c_visual_check_2026-05-14.md` + `week14_3b_deepseek_dispatch_2026-05-14.md`
- **Phase 4 W14-2 C 任务 biome/weather + 闭关 idle tick + tower 接入**(2026-05-14,high):W14-1 单 school 维度扩到 4 维 AND(school + biome 60+ values 累计 + weather 5 values 累计 + fortune)。EncounterBiome 15 值 / EncounterWeather 5 值枚举,stages.yaml 15 关 + numbers.yaml 5 闭关图 全标 biome/weather。SeclusionService 注入 encounterService 闭关收功喂 actualHours×60 累计(分两 txn,嵌套 writeTxn 限制)。runEncounterHookAfterVictory 抽到 encounter_hook.dart 共享,stage + tower 双端 victory 都接奇遇。encounters.yaml 3→15 条。schema 升 0.5.0→0.6.0。18 新 test,**590/590**(W14-1 572 → +18)。详 handoff `week14_2_biome_weather_idle_tick_2026-05-14.md`
- **Phase 4 W14-1 C 任务 vertical slice tag v0.4.0-w11**(2026-05-14,xhigh):GDD §7.2 奇遇/武学领悟系统 0→1。新建 `EncounterDef` + 4 枚举 + `EncounterProgress` Isar collection + `EncounterService`(recordKill / evaluateTriggers fortune 软概率 / applyOutcome lifetime cap 5) + 3 条 encounters.yaml + UI 三段式 dialog + 战斗 victory hook。20 新 test,**572/572**(W13 552 → +20)。
- **Phase 5 W6 升级 + 架构重构 tag v0.3.0-w6**(2026-05-14):isar→isar_community 3.3.2 / flutter_riverpod 3.x / riverpod_annotation 4.x / riverpod_generator 4.x / analyzer 5.x→9.x。8 个有 Isar 依赖的 service 改实例化 + 构造函数接 Isar;新 `IsarSetup.instanceOrNull` + nullable isarProvider + 9 个 service provider,widget test 自动短路。**销账 #23**(架构层面)。530/530 测试,详条 `docs/handoff/week6_full_closeout_2026-05-14.md`
- **Phase 3 Week 7 T63 装备 fixture 扩 10→35 件 + 覆盖度红线**(2026-05-13):equipment.yaml 7 阶 × 5 件重写;GameRepository `_enforceEquipmentRedLines`(单件 baseAttackMax ≤ 2000 + 三件套覆盖)。test +2,532/532
- **Phase 3 Week 8 T64 心法扩 6→21 本 + 招式扩 18→63 招 + 覆盖度红线**(2026-05-13):techniques.yaml 7 阶 × 3 流派 + skills.yaml 21×3=63 招;GameRepository `_enforceTechniqueRedLines`(组合 + 3 招 type + parent 指向)。test +2,534/534
- **Phase 4 W11 victory 路径接 BattleResolutionService 双端 + 销账 #32**(2026-05-13,xhigh,commit `a2de8a2`):W10 自审发现 `BattleNotifier.resolveBattle` 全仓库 0 调用,主线/爬塔 victory 装备 battleCount/心法 skillUsage/主修升层全未生产路径落地。`BattleResolutionService.resolve` stageDef 改 nullable;主线 `_applyVictoryResolution` + 爬塔 `_applyTowerVictoryResolution`,与 W10 体例对齐;test +2,544→546
- **Phase 4 W10 战斗结算扩展 Boss 战败被动散功**(2026-05-13,xhigh,commit `4e59e9b`):四决策点拍板:① 仅 Boss 关 ② 不掉装备 ③ 主修「无换修」散功(IF×0.5 + progress×0.5 + layer 重算,境界不动) ④ 损失摘要走 NarrativeReader topBanner。numbers.yaml `techniques.defeat` 段 + DispelService.applyDefeatPenalty + _DefeatLossBanner widget。test +10,534→544
- **Phase 3 Week 2 T42-T46 详条补录 + Week 9 A 自审 + W6 drift 收尾**(2026-05-13):自审发现 W9 候选 A「爬塔 UI 串联」实际在 W2 已交付完整(commits `41530aa`-`0b25229` merge `74d30bd` v0.3.0-w2,11 tower widget test);本会话仅做 W6 drift 收尾(`tower_entry_flow.dart` `_persistDrops` 迁 `ref.read(isarProvider)`)。挂账 #31 widget test 死循环已记。534/534

## 已知偏差 / 挂账事项

- 2. **lib/ 目录结构**:CLAUDE.md 写 DDD,实际用 phase1_tasks 的 flat。Phase 5 整理
- 3. **`riverpod_lint` 未引入**(W6 重评估):custom_lint 0.8.x 锁 analyzer ^7.5/^8 与 link 4.x ^9 互斥,等 custom_lint 升级
- 4. **IDS_REGISTRY.md 自报「143 个内容 ID」错误**:实际 238 个,等 DeepSeek 改
- 6. **GDD §5.3/§5.6 公式系数 vs numbers.yaml**:GDD 字面 ×8/×5 是「口误」,代码以 yaml 平衡值为准
- 7. **numbers.yaml 节气列表混入「中秋」**:中秋是农历节日不是节气,GDD 没明确 24 节气,待定
- 8. **CLAUDE.md §12 待人类决策清单 13 条**:境界/修炼度层重名等,实现到对应位置时按需提问
- 9/11. **T05/T07 验收**:Mac 无 Xcode 跑不了 desktop,留 Windows 首跑验
- 10. **yaml key 命名约定差异**:numbers.yaml snake_case,内容 yaml camelCase,按文件类型隔离不冲突
- 17. **phase1_tasks T12 §709 笔误**:差 2 守方 0.05 错(实际差 2 守方=0.3,差 3+ 才 0.05),「必败」语义仍成立
- 28. **闭关 widget e2e test 缺失**(2026-05-13 xhigh 5 轮探路无解):W6 后 service 注入完成但 3 屏(list/setup/active)仍走 `IsarSetup.instance`(W6 drift)。`fake_async vs native Isar zone 边界`不可解,真解需 ≈ Phase 5 #2 DDD 级(3 屏 Consumer 化 + service interface),留 Pen 视觉验收兜底
- 30. **闭关 3 个扩展维度未接 service**(§12 #5 收口留尾):numbers.yaml retreat 已配 technique_learn_rate / internal_force_growth / 节气日 / 正午阳刚,但 `seclusion_service.computeOutputs` 未消费;依赖 §12 #7 节气清单 + 农历库
- 31. **main_menu「问鼎九霄」widget test 写不出**(2026-05-13 W9 自审踩坑):`pumpAndSettle` 死循环,多 provider+Navigator 链异步 future + 帧 ticker 冲突。已有 11 个 tower widget test 覆盖核心,nav 路径不再硬塞
- 34. **#10 stage drop 视觉验收未取得硬截图**(2026-05-14 Codex v4):RDP 高度 + 1280×900 窗口下 Codex 主菜单底部入口/滚动操作不稳定,跑了 stage_01_01 victory 但没成功进库存页拍到新增装备。代码层 service test 兜底验证 dropTable 配置生效(`game_repository_test` line 124+)。后续视觉验收建议给 Pen 配 ≥1080 屏幕高 + 库存页快捷入口

> 已销账条目(#1/#5/#12/#13/#14/#15/#16/#18/#19/#20/#21/#22/#23/#24/#25/#26/#27/#29/#32)详见末尾归档。

## 下一步

W14-3 整体闭环。候选:
- **打 tag `v0.5.0-w14`**(高):W14-3 vertical slice 完整(代码 + 文案 + 视觉验收 + 下批 fixture),HEAD `bcc8031` 适合标记 milestone
- **下批 Codex 完整 EncounterSkillSection 验收**(medium):用 Phase2TestMenu「VC14_3」按钮(`seedVisualCheckW14_3`)→ 师徒 3 人 yiLiu/erLiu/sanLiu 看不同 lock 行为(可装 tier ≤ 4/3/2)+ bottom sheet 列表 7 招 + 切角色 + 装/卸操作
- **dialog visual check 强制触发入口**(low,Codex 反馈):当前 victory hook 走 `baseProbability 0.5` 软概率,Codex 反复打 stage 才能触发奇遇。可加 debug 入口"指定 encounter id 强制触发"绕过软概率,或在 VC seed 后挂"触发奇遇"按钮
- **W14-3-A 收尾候选**:① 让 W14-3-A 35 招拿到更多实战 unlock 路径(只配了 6 招对应 outcome,余 29 招暂无 encounter 引用);② 扩 encounter outcome 引用 tier 1-2 / tier 7 池里的招式补 7 阶覆盖度;③ 主线 victory 装备奇遇 skill 后是否 NarrativeReader 提示(参考散功 banner 体例)
- **Phase 5 #2 DDD 目录整理 + 屏 Consumer 化收尾**(xhigh,可重新捡回 #28 闭关 widget e2e)
- **#30 闭关 3 维度接 service**(§12 #7 节气清单 + 农历库阻塞,先解人类决策)
- **#34 stage drop 视觉验收 Pen 环境改善**(配 ≥1080 屏幕 + 库存页快捷入口,然后 Codex 重跑补 #10)
- **Pen-only T64 test fail 排查**(`.dart_tool/build` cache stale 推测,Mac 端不重现)

> CLAUDE.md §12 #1(境界 vs 修炼度名重叠)实质消解:Phase 1 已用「启蒙/入门/熟练/精通/圆熟/化境/登峰」vs「初窥/小成/中成/大成/圆满/巅峰/通神/无瑕/极境」严格不同名,见 `enum_localizations.dart:39,78`。

## 关键约束(每次开局必读)

- 数值红线:普伤 ≤8000 / 玩家血 ≤20000 / 内力 ≤15000 / 装备攻击 ≤2000(GDD §5.2)
- 不硬编码数值(走 numbers.yaml)、不硬编码中文文案(战斗调试日志走 enum_localizations.dart,UI 走 lib/ui/strings.dart,剧情走 data/narratives, lore, events)
- Riverpod 状态管理;Isar 本地存储;data/ 是 asset 根目录
- 写代码不动 GDD.md / CLAUDE.md / numbers.yaml / data_schema.md / IDS_REGISTRY.md(DeepSeek 领地)
- Mac 端写 lib/、data/*.yaml(顶层)、test/;DeepSeek 写 data/narratives/、data/lore/、data/events/

## 远程仓库

- GitHub:https://github.com/Zed1118/wuxia_idle
- 主分支 main
- 双端协作:Mac+Opus 写代码与数值;Windows+DeepSeek 写文案;Codex 桌面 @ Pen 跑视觉验收(详 `feedback_codex_pen_windows_visual_check.md`)

## 归档

### 已解决挂账(逆时序)

- **W12-W13 销账**(2026-05-14):#12 LevelDiff 数据/公式层语义统一(commit `0771c90`) / #23 widget test 不接真 Isar 架构层销账(W6 service 实例化 + nullable propagation) / #28 探路终结判不可解(5 轮 fake_async 边界,留 Pen 兜底) / #32 victory 接 resolveBattle(commit `a2de8a2`)
- **W4-W5 销账**(2026-05-13):#25 Phase2SeedService 缺主修(T54 seedMasterDisciple) / #26 闭关入口硬编码(T56 _SeclusionMenuButton) / #29 defeat hook + 9 关扩容(T59+T60)
- **W3 销账**(2026-05-12):#27 narrative schema 对齐(NarrativeLoader 子目录扫描 + stages 6 关 id 迁移)
- **W1-W2 销账**(2026-05-11):#22 T32 #22a/#22b service.persistResult + widget guard / #24 装备名未渲染(EquipmentDef.name + Flexible/ellipsis)
- **Phase 1-2 销账**(2026-05-10/11):#1 Riverpod 锁 2.x / #5 T17 笔误差 2→差 3 / #13 yaml b/c max_hp / #14-15 灵巧暴击 +0.20 与 ×2.0 yaml 化 / #16 战例 E ≤100000 / #19 T15 远程沙箱无 Flutter / #20 T15-17 Windows 视觉验收(5 截图 4 场景全命中)/ #21 screen_shake + tier_colors helper 抽取
- **W6 验证为伪挂账**:#18 flutter build web 被 Isar 阻塞(项目无 web platform target)

### Phase 1-3 W1-W5 详条已迁出

- **Phase 1 T01-T18**:`phase1_summary.md` + git log `v0.1.0-phase1` 前 commits(约 25 条带 `[Tnn]` 前缀)
- **Phase 2 T19-T32**:`phase2_summary.md` + git log `v0.2.0-phase2` 前 commits + merge `5efe8d5`
- **Phase 3 Week 1-3**:`phase3_summary.md` §Week 1-3 + git log + tags `v0.3.0-w1` / `v0.3.0-w3`
- **Phase 3 Week 4-5**:git log `9349626`(T53)→ `73c1f37`(stage_01_05 balance) + tags `v0.3.0-w4` / `v0.3.0-w5` + handoff `t58_visual_check_spec_2026-05-13.md` / `t62_visual_check_spec_2026-05-13.md` / `week5_full_closeout_2026-05-13.md`
