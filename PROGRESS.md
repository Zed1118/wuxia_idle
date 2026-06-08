# 挂机武侠 · 开发进度

> Mac 端 Claude Code + Opus 4.7 维护。会话开始主动读取，任务完成主动更新。
> 总行数控制在 100 行内，超出归档到末尾。

## 当前阶段

> ✅ **2026-06-08 续(§5.6 硬编码中文审计 6 处抽 UiStrings + 装备 G2.2 抠白底 Phase 0 收口待晚上视觉)**:① **§5.6 审计**(subagent 全扫 227 dart):A 类 6 真违例全抽 `UiStrings`(equipment 基础值后缀 `(基 N)` / sect lazy-init `'无名宗'` ×2 生产 / 门派事件 dialog 3 fallback+拒绝按钮)· B 类 112+ assert/log + C 类 28+ debug 按规不抽 · analyze 0 / 全量 **1763 测过** · `3b256a9`(销 main 既有 `(基 $base)` nit)。② **装备 G2.2 Phase 0+试点完成**(零仓库写):160 图=80 icon+80 detail,背景三类(白 23 / 暖底 116 / **整幅水墨场景 21**)· 用户拍板=scene 当装裱画整幅渲染(**alpha 通道自动路由**,widget 仅删 multiply)+ 可抠 139 收紧抠投影去朱印 · v3 抠图器(投影感知+软斜坡 alpha+补环心洞+红印去除)出 139 透明成品+3 montage 持久化 `docs/handoff/equipment_cutout_g22_2026-06-08/` · **剩 ~20 氛围/泼墨底尾巴需人眼/Codex 定 cut-or-frame + widget 改+替 assets → 晚上视觉验收**。

> ✅ **2026-06-08(心法 7 阶 cover 重出透明卷轴 · 解 G5.1 伪书法红线 · `c991984`)**:旧 cover 含 MJ 伪书法(main 既有 2026-05-21)→ 用户重下 56 张无字卷轴候选,自写 flood-fill 边缘连通抠白底透明(Pillow+numpy 无 rembg · 只抠和边缘连通的背景保住卷身亮高光)+ 收 1px 边吃抗锯齿浅边 + 轻羽化。**踩坑**:首版自检合成在浅纸底(以为面板宣纸)藏住白边/投影,游戏深木底才暴露白光晕 → 改合成**真木底**自检 → 收边管线根除(memory `feedback_visual_check_real_target_bg`)。7 阶选定 1952×608+alpha · pngquant+oxipng 3.8MB 替换 `tier_*.png`。Codex 分隔符误用卷轴图同修(`8d25709`)。闸门 analyze 0 / **1763 测全过** → ff 合并 main。**下一步=装备图 G2.2 抠白底**(同 drop-shadow 问题更复杂,升 xhigh)。

> ✅ **2026-06-06..07(Codex 两天 UI 包装+MJ 素材接入 43 commit 合并 main · `a195547`)**:Codex 桌面备份端两天连续推进三条线:① UI 连续包装(装备/仓库/角色面板/主菜单/主线/爬塔/闭关/心法/胜利成长反馈,全走 WuxiaUi kit + `textScale 1.12` 全局放大)② MJ 素材接入(37 组筛完留 39 张,接主菜单山门/仪式页/战斗特效/Boss 框/红印 · `assets/ui/mj` 56 张 + pubspec 注册 + 运行时盘点)③ 用户现场反馈修正(角色页装备白底/标题伪底/字号偏小)。**Claude 接手分支级 review**:analyze 0 / 全量 **1763 测** / 红线数值未动 / 无逻辑回归(唯一行为变更=心法相生检测改遍历全部辅修槽,对齐 GDD §4.5 正确性修复,有「多辅修槽候选」测守)+ 深扫挖出 7 处硬编码中文抽 `UiStrings`(闭关/装备界面)→ ff 合并 + push origin/main(43+1 commit)。**Codex 视觉复查总判 FAIL**:G5.1 红线=心法 7 阶 cover `tier_*.png` 含 MJ 伪书法(**main 既有非本批引入**,挂账重出)· G2.2/G3.1 WARN。交接 `docs/handoff/codex_to_claude_full_handoff_2026-06-07.md`。

> ✅ **2026-06-05(UI kit v1 序 0 地基落地 · subagent-driven · xhigh · `feat/ui-kit-v1`)**:承 UI 包装方案 v1 → writing-plans 拆**单 plan 全 kit** → TDD 实装。**9 组件 kit**(`lib/shared/widgets/wuxia_ui/`:PaperPanel/SectionHeader/SealBadge/ItemSlot/MeridianBar/PlaqueButton/WuxiaTitleBar〔PreferredSizeWidget 替 AppBar〕/PlaqueTab/PaperDialog〔+`show` 入口〕)+ **母题 token** `WuxiaUi`(`shared/theme/wuxia_tokens.dart` 色/边/面/形/资产,浅色宣纸笺,锚 demo `:root`,区别战斗深色 `WuxiaColors`,与现有 `WuxiaPaperPanel` 并存)+ barrel。每组件 widget 测(errorBuilder/IntrinsicHeight/钳值守 · 复用 `EquipGlyph`+`wuxiaAssetErrorBuilder`)。**T11 callsite 试点**:仓库分组头(`inventory_screen._SlotGroupSection`)竖条+label+计数 → `SectionHeader`(数量 (N) 与 demo §2 段头一致去掉,整页 rollout 可回收)。**两段式只读 review**(spec 合规 ✅ + 代码质量 ✅)+ 最终 review ✅ ready to merge,修 2 Nit(绛红旁路 `0xFF8A2B21`→`WuxiaUi.jiang` token + 补 ItemSlot highTier 分支测)。全量 **1713→1744 测 / 1 skip / 0 analyze**(+31)· 13 commit。**T11 视觉自验留 Codex/用户**(CLI 不截 native app)。**下一步=序 1 装备仓库+详情逐页改造**(趁热吃重出水墨图红利,kit 落地)。plan `docs/superpowers/plans/2026-06-05-ui-kit-v1.md`。

> 🎨 **2026-06-04 续(8 张装备图重出 + 工作树清理 + UI 包装改造方案 v1)**:① **8 张产品照/借线感装备 detail 重出归位**(铜铃/蛇胆丸/平安扣/棉甲/短褂/锁子甲/铁片甲/柳叶刀 · 白底产品照/藏品照 → MJ v7 水墨统一风格,**配方=主环境 sref `ae8355ca` + `--sw 50`**〔先前漏写,这批坐实是装备 detail 核心配方〕+ 题字朱印 + 7阶梯度词 + 柳叶刀锁 dao 无 jian 漂移 · pngquant+oxipng 244-361KB · 读图选片归位 `229e7ea` · 派单 `mj_equipment_reshoot_productphoto8_2026-06-04.txt`)。② **工作树清理**(drop stash + macos 构建产物/`.claude/` 入 .gitignore + skip-worktree 屏蔽 pbxproj 噪音 · `5f83d31` 已 push)。③ **UI 包装改造方案 v1 · brainstorming 收口**(承外部 UI 评估「系统页停在 Flutter 功能面板视觉语言」· 力度=**重度游戏化重做** · 9 组件 UI kit〔TitleBar/PlaqueTab/PaperPanel/SectionHeader/ItemSlot/MeridianBar/SealBadge/PlaqueButton/PaperDialog〕+ 母题 token/红线〔宣纸/墨边/木牌/朱印/卷轴 · 不走网游金光〕+ 5 核心屏〔主菜单/角色/仓库/详情/战斗胜利〕· **真实资产 demo** `docs/handoff/ui_mockup_v1/`〔python http.server 预览,主菜单三版对比后**定 C 宣纸笺**〕· spec `docs/superpowers/specs/2026-06-04-ui-packaging-pass-v1-design.md` · `9ea8f4f`)· **下一步 = writing-plans 拆实现计划,kit 先行**(0 代码尚未动)。

> ✅ **2026-06-04 续(P0-3 ②③ 主修 hero + 心魔成长瓶颈面板 · xhigh · `f9425b8`)**:角色卡核心玩法视觉收口最后一块。**②** 主修心法 tile hero 化(`WuxiaPaperPanel` 宣纸底〔包 `IntrinsicHeight` 解滚动列无界高度〕+ 主修真名 `techniqueDefs[defId].name` 加大 20px 校色 + 阶名/段位/进度条保留;辅修不动)。**③** 心魔成长瓶颈面板(武圣**常驻** · 旧 `_BreakthroughBlockerSection` 仅「被拦窗口」显 → 改常驻 X/7)——3 层纯单元:`InnerDemonProgress.from`(派生 clearedCount/totalCount〔派生不硬编码 7〕/nextUncleared)+ `resolveInnerDemonPanel`(cleared/blocked/inProgress 三态 + 非武圣/空配置 null)+ `InnerDemonProgressPanel`(泛化旧 blocker,纯渲染);`innerDemonProgressProvider` 从 `mainlineProgressProvider` 派生(单一真相源 = clearedStageIds);「突破」CTA 仅导航不引新机制(进阶仍自动)。文案全 `UiStrings`。验收 seed `seedCharacterPanelGrowth` + route `character_panel_growth`(祖师 bump 武圣·熟练 exp满 → 2/7 被拦,不动被广依赖的 seedMasterDisciple)。**brainstorm→spec→plan→TDD 9 task 全流程** · 只读对抗式 review 2 findings(total==0 空配置 → 采纳改 null;IntrinsicHeight 无界高度 → 误报,测证 takeException null 保留)· 全量 **1697→1712 测 / 0 analyze** · 验收包重编 @ `f9425b8`(hub)· 派单 `codex_vis_char_panel_bc_2026-06-04.md` 待 Codex 截图。spec/plan 见 `docs/superpowers/{specs,plans}/2026-06-04-p0-3-bc-*`。**待 Codex 视觉验收 PASS 后核心玩法视觉 pass(战斗+角色页+仓库)全闭环**。

> **2026-06-01..03 详条已压缩归档**(git log/closeout 完整可溯 · 1661→1697 测/0 analyze):① **P0-2 战斗单位可见化全闭环**(玩家立绘+单位放大 110+死亡 grayscale+弹道笔触+受击闪+折叠日志+胜负 vignette · 弹道/受击走 actionLog 不写 BattleState 红线 · `c7fb79c`)② **P0-3 角色卡 ① 装备外观可视化**(装备槽 iconPath+tier 色 _EquipGlyph)③ **P0-4b 仓库格子化实装**(列表→部位分组网格+tier 边框+强化徽章+师承标+境界锁灰化 · `2049265` · Codex R3 PASS `880d7f7`)④ **装备 detail 45 件 + 敌人图 37/37 全归位**(美术缺口归零 `239d1d9` · 129 敌人图 + 80 装备 detail)⑤ **验收提速基建**(`VISUAL_ROUTE=hub` 一次 build 点遍 12 路由 + `tool/build_acceptance.sh` 预编 · `d94a56a`)。详 `docs/handoff/overnight_2026-06-03_handoff.md` + 各 closeout。

> **2026-05-30..06-02 出版美术 pass(1.0 Presentation Pass)全闭环已归档**(1581→1667 测/0 analyze · `docs/PUBLISHING_ART_PASS_1_0.md`):战斗屏(主菜单水墨山门 + B1 背景按 biome 接线+scrim+胜负仪式 overlay + B2 大招题字+Boss 金边)+剧情屏(narrative_scene 基建+30 图)+战斗场景 16 biome 全覆盖+角色页档案化+章节封面 6 章 · Codex 多门视觉验收 PASS · D 段性能稳定性验证(8h/leak/ANR 逻辑层已验)+窗口 min size Pen 3/3 PASS + B1 release audit doc 同步(CLAUDE v1.17 测数 1667)+ P5.2 敌人内力按境界对称化 scale=0.20 + 文案 polish H 段全角标点 + #4③ 数值迁 yaml + V3 神物金掉落验收 3/3 PASS。git log `c97c682→880d7f7` 区间 + 各 closeout 完整可溯。

> **2026-05-30 H1 修复批全闭环已压缩归档**(`58c6f29`→`2dd597b` · 1555→1569 测 / 0 analyze):批1 主菜单 7 未解锁系统 §5.7 门控 + 门派名迁 UiStrings · 批2 `EquipmentService.equip/unequip` 装备穿戴入口(修核心循环断裂 · §5.3 守卫 + picker)· 批3 掉落 dialog 品阶仪式感 + 闭关装备名 bug + 凝练常驻态 + 过场调色 + tick→回合术语 · picker「他人装备中」移装标注。详各 commit/closeout。

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
- ~~stage_05_05 on-level ceiling 20%~~ 跨阶墙 **2026-05-31 sim 复核销账**(non-bug · data-confirmed · `test/tools/output/balance_summary_2026-05-31.md`)
- ~~`equipment_detail_screen.dart:489 '(基 $base)'` 硬编码 nit~~ 已抽 `UiStrings.equipmentStatBaseValue`(2026-06-08 §5.6 · `3b256a9`)

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
- **心法 7 阶 cover 伪书法 G5.1 红线**(2026-06-08):重出透明无字卷轴替换(`c991984`)· flood-fill 抠白底+收边 · 真木底自检无白晕

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
