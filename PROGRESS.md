# 挂机武侠 · 开发进度

> Mac 端 Claude Code + Opus 4.7 维护。会话开始主动读取，任务完成主动更新。
> 总行数控制在 100 行内，超出归档到末尾。

## 当前阶段

> 📊 **2026-05-30 H 主聚焦(打磨期)· release readiness ~98%(CHECKLIST v1.12)· Codex 视觉验收 §9 8/9+V2b 修 · #4 A组死代码清理 · B1 敌人内力诊断→推迟 P5.2 · origin 26541cc · 1581 测/0 analyze**

**2026-05-30 续(doc 重估+Codex triage+A组+V2b+B1 推迟)**(origin `26541cc` · 1581 测/0 analyze · 2 commit push):① **CHECKLIST v1.12+ROADMAP v1.11** release readiness ~97→**98%**(白屏证伪摘风险悬顶+H1 上手 audit 全闭环·`4a21a54`)。② **Codex 视觉验收 triage**(代码核实):§9 实 8/9 正确——**V2b 强化按钮非金=真 bug 已修**(`26541cc`·`enhance_dialog:299` ElevatedButton 补 `resultHighlight`)/ V1 凝练入口绛红=`schoolColor` 流派色 by-design 不改(同「设为主修」体例)/ V2d 胜利「返回菜单」=Codex 截错按钮(主线 `stage_victory_dialog:39` 确金,Codex 截到 `battle_screen:280` 战斗结算中性按钮)/ V3 神物金 BLOCKED(VC-P5+ seed 只 mark stage_06_05 cleared,章节列表 Ch6 仍锁→派单路径错·逻辑+单测已覆盖非阻塞)。③ **#4 A 组死代码清理**(`15966de`·删 `sectMemberCountProvider`(冗余)+`seedSectEventProvider`+notifier·battle_demo 经核=活 test fixture 保留·memory `feedback_git_grep_pathspec_glob_trap` glob 漏顶层)。④ **B1 敌人内力封顶 1000→路A 推迟 P5.2**:坐实 Ch6 终 Boss `chuanshuo_ult`(1600)/`shichuan_ult`(1100) 永久放不出(`battle_ai:105` 内力<cost),抬 2000 修但与刚缓和的 stage_05_05 耦合(on-level ceiling 76→20% 过难)→「敌人内力按境界对称化(方案A)+per-stage 重调」整体推 P5.2·worktree 弃·numbers 仍 1000。

**2026-05-30 白屏证伪收口 + H1 批3 视觉验收 5/5 PASS + #3 凝练态 seed**(main `a262358` · 1580→1581 测 / 0 analyze · Pen+Codex 两趟 + Mac worktree 一实装):① **主线白屏证伪收口**(Codex Pen):clean 存档 + dirty seed 3 轮均不复现 · flutter run 日志 0 exception/RenderFlex/assertion/Navigator → 判**非真 runtime bug,已被 B6 provider invalidate 加固消除**(closeout `codex_whitescreen_repro_2026-05-30.md` + 12 截图/日志落库,我多模态亲验 chapterlist 正常 paint)。② **H1 批3 视觉验收 5/5 PASS**(Codex Pen · 我多模态亲验 5 关键截图):①过场暗红✅ ②掉落品阶仪式感(勋章图标+品阶标签+寻常货灰,道具朴素;神物金色 RNG 未刷到,逻辑+单测已覆盖)✅ ③回合术语✅ ④凝练 0 点灰显常驻态✅(P3 seed) ⑤picker 关闭按钮+他人装备中✅(closeout `codex_batch3_visual_2026-05-30.md` + 18 截图)。③ **#3 凝练态验证路径缺口修复**(Mac worktree):新增 `seedRefineInsight` debug seed(主修+insightPoints 50+tutorialStep 3)+ Phase2「凝练态验证」按钮 + 1 seed 单测(widget 测计数 14→15) → 下趟 Pen 可验 ④「· 50 点」有点态。**剩余**:批3 两未观察分支(神物金色 drop + 凝练有点态)待下趟 Pen pull `a262358` 补验 · §9 dialog 8 个正向收益确认按钮已统一金 ✅(`2adbdae` · victory/爬塔/招募/凝练/奇遇/飞升/强化 · dispel 散功确认已改绛红 ✅gangMeng;「设为主修」蓝紫=阴柔流派色 by design 不改)。

**2026-05-30 overnight 自主批(Pen 验收收尾 + 5 批安全清理)**(main `fe23ccb` · 全量 1580 测 / 0 analyze · 用户 overnight 授权无人介入):**Pen H1 批1+2+3 视觉验收完成 + Windows 已关机**(closeout+10 截图落库 `ada39ba`):批1 门控 4/4 PASS · 批2 picker 核心 PASS · 批3+凝练态未视觉验(心法面板门控锁够不到凝练 / 过场+战斗被**主线白屏**阻塞)· 🔴 主线白屏判**非本次回归**(ChapterListScreen 三批未碰+全量测过,疑 Pen seed-state,明早 clean 存档复现)。**overnight 6 批实装全 merge**(每批 worktree 隔离+全量绿+0 analyze):Batch1 17 处硬编码中文→UiStrings(§5.6)· Batch2 补 5 篇 techniqueInsight 文案 · **Batch3 picker header 关闭按钮**(修 Pen 确诊空态卡死)· Batch4 tower 注释+`_layerLabel` dead-dup+`_attr/_terrain/formation`→EnumL10n · Batch5 剩余 22 处标签→UiStrings/EnumL10n · **Batch6** debug seed 后补 14 provider invalidate(主线白屏最可能诱因加固)。**对抗式 review 5 批 diff:0 真问题**(逐字节核对 28 文件)+ 修 1 标点 nit。**主线白屏诊断**:确证非渲染 bug 非 H1 回归(在 ChapterListScreen 之外·导航/帧调度层),Batch6 加固诱因,明早 clean 存档复现确认。**安全自主池见底**(round-1/2 双轮消化)· handoff `docs/handoff/overnight_2026-05-30_handoff.md` · 留决策:A6 飞升路标/battle_demo 角色名/疑似 dead provider/wf_audit 数值/ceiling 取舍。

**2026-05-30 H1 picker 移装标注(批2 已知偏差收口)**(commit `2dd597b` · 1568→1569 测 / 0 analyze · high · 与 Pen 批1+2+3 视觉验收并行推进):`character_panel` 装备 picker 此前显该 slot 全部装备(含已被队内其他角色穿戴的),选中静默把原角色卸下。加「· 他人装备中」标注(刚猛红 TextSpan · `equipWornByOther`)让玩家选前知情;**不禁用**——自由池移装是合理队内调配(沿批2 service 语义),只去「静默」意外感。+1 widget 测(他人装备项显标注+真名 `weapon_xunchang_tie_jian`→铁剑)。**简化决策**:标注用 generic「他人装备中」不解析 owner 具体名(避 async 名查 + 加载闪烁;active 仅 3 角色场景下足够),若要「XX 装备中」具名为 1.1 follow-up。**批2 picker 偏差销账** · 剩余:ceiling 满配碾压(1.0 暂接受)/ Pen 视觉验收结果待回。

**2026-05-30 H1 批3 掉落仪式感 + 🟡 polish 一波**(commit `67d160c` · 1564→1568 测 / 0 analyze · high · 纯 UI 0 数值/schema 改):H1 上手 audit 🔴#3 + 一批 🟡 收口,**H1 修复批全闭环(批1✅批2✅批3✅)**。① **掉落 dialog 仪式感**:`stage_victory_dialog` 装备掉落抽 `_EquipmentDropRow`,按品阶上色(`tierColorForEquipment` 神物高亮金→寻常货暗灰)+ 勋章图标 + 品阶标签,消除「磨剑石与神物视觉同」零反馈(§10);道具仍朴素列。② **闭关装备名真 bug**:`retreat_result_screen:108` `label: eq.defId` → `GameRepository.getEquipment(defId).name`(沿 character_panel 体例 + isLoaded 兜底)。③ **凝练入口常驻态**:`technique_panel` 主修凝练按钮有点显「凝练领悟·N 点」可点 / 0 点显「·暂无领悟点」灰显不可点(§5.7 状态常驻,不靠点击后 SnackBar 才知)。④ **过场按钮调色**:`chapter_transition` FilledButton 默认 M3 蓝紫 → `WuxiaColors.gangMeng` 刚猛红,统一 §9 水墨。⑤ **tick→回合术语**:`battle_log`(行首/总结)+ `strings.battleSummary` 玩家可见「tick」→「回合」(复用既有 tickPrefix 语义)。+4 测(凝练常驻态 2 / 掉落品阶 1 / 闭关装备名 1)+ 改 3 处 battle_log 术语断言守护。**已知偏差续**:批2 picker 移装静默卸下他人弟子装备(Demo 可接受)/ ceiling 满配碾压(buy-out power fantasy 1.0 暂接受)/ 待 Pen 视觉验收(批1 门控+批2 picker+批3 掉落色)。

**2026-05-30 H1 批2 装备穿戴入口(修核心循环断裂)**(commit `e90c180` · 1558→1564 测 / 0 analyze · xhigh · TDD):H1 上手 audit 🔴#2 修 —— 掉落装备 `ownerCharacterId=null` 入背包后**无玩家穿戴 UI**(`equippedXxxId` 赋值此前只在 recruitment/ascension/seed/debug),装备系统半残。① 新 **`EquipmentService.equip/unequip`**(writeTxn · §5.3 `isEquippableAtRealm` 守卫 · 自由池移装语义防双持 · 沿 ascend auto_swap 体例)。② **character_panel 装备槽可点 → modal bottom sheet picker**(镜像 encounter_skill picker:同 slot 列表 · 境界不达灰显+锁图标 · [当前]标注 · 卸下)· `isarProvider` 内联构造 service · equip 后 invalidate characterById/allEquipments/equipmentById。③ UiStrings 4 段。④ TDD:+5 service 测(空槽装/换装回池/§5.3 拒/卸下/移装防双持)+ 1 picker-open widget 测。**H1 批3(掉落仪式感+🟡 polish)待续**。

**2026-05-30 H1 批1 主菜单未解锁系统门控(§5.7)+ 门派名迁 UiStrings(§5.6)**(commit `58c6f29` · 1555→1558 测 / 0 analyze · 纯接线无数值):H1 上手 audit 🔴#1+#4 修。① **主菜单 7 个未解锁系统按钮加 disabled 门控**,镜像各屏 `clearedStageIds` prereq 单一真相源:心魔/轻功/群战 @ `stage_06_05`(Ch6 末)· PVP @ `stage_05_05`(Ch5 末)· 江湖/门派/排行榜 @ `stage_01_05`(Ch1 末 · 社交/竞技此后才有意义,用户拍统一里程碑默认)· 沿心法(step<3)/闭关(step<5)既有 disabled 体例 + locked hint。② onboarding `'我的门派'` 硬编码 → `UiStrings.defaultSectName`。③ +3 门控 widget 测(空进度全锁 / Ch1 通关社交解锁后期仍锁 / Ch6 通关后期解锁)。**H1 批2(装备穿戴入口)+ 批3(掉落仪式感+polish)待续**。

> **2026-05-29 详条已压缩归档**(全程 commit/closeout/git log 完整可溯,1534→1555 测):① 方向调整(F/G Steam 搁置 · H 段升主聚焦 · balance_simulator PoC)· H1-Q1 主菜单产品名 P0 清零 · H2/H3/H1 三部曲 audit(`h{1,2,3}_*_audit_2026-05-29.md`)② 外部 review 修复批 P1-a 飞升 auto_swap §5.3 守卫 / P2-a 奇遇招式池空 fail-fast / P2-b 敌人属性抽 numbers / P2-c 战斗公式双路径收敛单一真相源 / P3 三文档血量公式 drift 对齐(commit `559455f`/`f719172`/`62b0b7e`/`2686815`/`1afc888`)③ 根因A 挂机循环重平衡 B1+B2+B3 实装(共鸣双管+闭关 EXP+insightPoints sink · `a359dc2`/`d7ee3f9`)+ B2 低 tier EXP 回 ×1.0 修正 + idle_economy 验证 · 红线值统一 numbers.yaml(`7a1d1e7`)· balance_simulator 升真 build + floor/ceiling bracket + on-level 修正 ④ D 段难度修复:stage_01_05 Ch1 Boss +2 阶硬墙(`781c85b`)+ stage_05_05 跨阶过苛缓和(`24cea80`)→ 过难关清零。

> 2026-05-28 三条(CHECKLIST v1.5+ROADMAP v1.8+R4 派单 / 装备 drop 全覆盖+P2.1 4 批 / P3.2.B+P1.2+P3.x+过夜清理 · 1508→1519 测)已归档,详末尾「2026-05-25/26/27/28 详条归档」段。

---

**2026-05-27 Boss 招降叙事+debug 招募+R2 派单**(7 commit · 1505 测):详 `session_closeout_2026-05-27_boss_narrative_debug_recruit.md`。

---

**2026-05-25/26/28 归档**:见末尾归档段。

## 已完成(近 W6 起,早期归档见末尾)

> W15 + W17-W18 + P5+ + P3.1+P3.2+心魔+Ch4-6 详条均已归档,详末尾归档段。

## 已知偏差 / 挂账事项

- ~~37 / 38 / 40 / 41 / 42 / 43 / 44 / 45 全销账~~(2026-05-17/18/19/20):详各 closeout

> 已销账条目(#1-#45)详见末尾归档。**P1 阶段全销账 ✅** + **Demo §8.4 14/14 全达标 ✅** + **1.0 ~95% release ready ✅**(A+B+C 全 PASS · 剩 D-G 留 M15-16)。

## 关键约束(每次开局必读)

- 数值红线:普伤 ≤8000 / 玩家血 ≤20000 / 内力 ≤15000 / 装备攻击 ≤2000(GDD §5.2)
- 不硬编码数值/文案(走 numbers.yaml / data/narratives, lore, events)
- Riverpod 状态管理;Isar 本地存储;data/ asset 根
- 不动 GDD.md / CLAUDE.md / numbers.yaml / data_schema.md / IDS_REGISTRY.md(数值/规则层 · 改前 ask)
- Mac 端写 lib/、data/(顶层)、test/、文案(v1.8 起 DeepSeek 退役)

## 远程仓库

- GitHub:https://github.com/Zed1118/wuxia_idle · 主分支 main
- 协作:Mac+Opus 单端代码+数值+文案;Codex 桌面 @ Pen 跑视觉验收

## 归档

### 已解决挂账(逆时序)

- **Phase 1-2 + W1-W13 全销账**(2026-05-10..14):#1/5/12-16/19-29/32 + #18 伪挂账

### Phase 1-4 早期详条已迁出

- Phase 1-3 + W4-W11:`phase{1,2,3}_summary.md` + tags `v0.1.0-phase1` / `v0.3.0-w11`
- W14-W15 + Phase 5 #2/#3 销账详条:git log + handoff/各 closeout

### W17-W18 详条迁出 2026-05-19/20

13 段销账(P1 #42-45 / Nightshift 9 task / P0 4 段 / 外部审查 6 项 / 路线图 launched / Codex 视觉)。详 `p1_4{2,3,4}_*` / `nightshift_20260519_handoff.md` / `p0_38_maxhp_rebalance_closeout_2026-05-17.md` 11 closeout。

### P1.1 候选 1-5 详条迁出 2026-05-21

5 候选全收口(4 实装 + 1 doc):候选 1 收徒池 E.1 / 候选 2 祖师爷 sect_wide_buff / 候选 3 共鸣度 4 子任务 + joint_skill / 候选 4 开锋 build / 候选 5 CLAUDE.md §12 对齐 — `p1_1_*_closeout_2026-05-21.md` 5 closeout。

### M4 #46 美术 + Ch4 Phase 2 详条迁出 2026-05-20/22

- **M4 #46 美术** 5 段(2026-05-20/21):Stage 2 W1-W6 74/74 + assets 89 张 + stage_audit + #45 Demo §8.4 · 详 art_poc_* / art_assets_integration_* / p1_45_demo_polish_*
- **Ch4 1.0 P2 第二条主线第 1 章**(2026-05-21/22):Phase 2.1-2.5 全收口 + 13 narrative ~5,880 字 · 详 p1_x_chapter4_phase2_*

### 2026-05-22/23/24 详条归档

- **2026-05-22 Ch5 + Ch6 飞升 P2 主线全闭环**(2 章 ~12,438 字 · 师父三句遗言完整连通 · 小铜镜+玉佩 hook 闭环 · 详 `p2_x_chapter{5,6}_phase2_full_closeout_2026-05-22.md`)
- **2026-05-23 心魔 Batch 2.1-2.5 + P3.1 轻功对决**(8h overnight worktree · 7+5 关 · 详 `p2_x_inner_demon_final_closeout_2026-05-23.md` + `p3_1_lightfoot_closeout_2026-05-23.md`)
- **2026-05-24 P3.2 群战守城 + P3.1.B 子批 + P5+ 多代飞升 + 真传位 + 8h overnight v2/v3 + nightshift v2 首跑 + UI polish**(git log `efc7604 → b6d8191` 区间 · 详 handoff `p3_2_*` / `p3_1_b_*` / `p5_lineage_full_closeout_2026-05-24.md` / `nightshift_v2_first_run_closeout_2026-05-24.md` / `8h_autonomous_handoff_2026-05-24.md`)
- **2026-05-25 v2.1 工具完善 + T17-T22 cherry-pick + T23/T24 6 关键问题闭环批**(main `74ba519 → b6d8191` · 1458 测 / 0 analyze · 批次质量 A 9.05/10 · P1.2 江湖恩怨+声望 100% + 技术债 3 合一 · 详 `session_closeout_2026-05-25_nightshift_6h_review.md` + `p1_2_jianghu_full.md` + `p3_tech_debt.md`)

### 2026-05-25/26/27/28 详条归档

- **2026-05-25 P4.1+P5.0+audit v2**(1458→1484 测 · 详各 closeout)
- **2026-05-26 P4.1 1.1 四项+audit v3+P5.2+Boss 招降叙事**(1484→1505 测 · 详各 closeout)
- **2026-05-27 Boss 招降叙事+debug 招募+R2 派单**(1505 测 · 详 `session_closeout_2026-05-27_boss_narrative_debug_recruit.md`)
- **2026-05-28 过夜清理+P3 三项+P2.1 4 批+drop 全覆盖+CHECKLIST v1.5+R4 派单**(1505→1519 测 · 详 `overnight_1_1_cleanup_handoff_2026-05-28.md` / `session_closeout_2026-05-28_p3_p1_triple.md` / `codex_dispatch_r4_p2_1_content_drop_2026-05-28.md`)
