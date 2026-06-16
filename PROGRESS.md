# 挂机武侠 · 开发进度

> Mac 端 Claude Code 维护。会话开始主动读取，任务完成主动更新。
> 总行数控制在 100 行内，超出归档到末尾。
>
> **当前阶段：1.0 长线打磨期（质量优先 · 不设上线时间压力）** — Demo ✅(2026-05) → 1.0 内容周期 ✅(P1-P5+) → 打磨中。阶段一变只改本行；工作原则见 CLAUDE.md §7。

## 当前阶段

> ✅ **2026-06-16 续15(全功能真审计 + 按级修复批 · 合 main `b8330c14` · opus xhigh · 6 维只读扇出 + TDD)**:**纠上会话幻觉**——上会话(工具输出污染)幻觉了一份「45 项 · 14 High」审计并谎称落盘 push,实际全仓(git/reflog/stash/内容)查无→重跑真审计(6 维 subagent 实证、每条 file:line + confidence)。**真图景:1 High + 7 Medium + 1 Low + 2 doc drift**,5 个红线维度(三系锁死/反留存/公式层/数据正确性/UI 健壮性)基本全清,幻觉吹的 3 个 High 红线项(闭关内力 clamp/师承遗物 canEquip/心法 canPractice)实证全为误报。报告落盘 `docs/audit/full_audit_2026-06-16.md`。**修复**:① **H1** 爬塔周目迁移加版本门(`isar_setup` tower 块原无条件重置 → 0.21+ 已推进存档被打回周目 1 数据丢失;+1 H1 回归测)② **D1/D2** §6 公式/散功失效路径 drift(formulas.dart→features/battle/domain · dispel_cultivation→features/dispel)③ **M1/M2** 正名 EnumL10n + battle_log 为合法集中 sink(CLAUDE v1.20,删 stale「Phase 4 迁出」承诺)④ **M3-M5** 散写中文迁 UiStrings(门派/关卡进出/loadFailed×3 dedupe/百科/心魔镜像名,行为保持逐字节不变)⑤ **M6** 核查确认心魔失败惩罚(`InnerDemonFailurePenalty`)从未 wire,GDD §6「全收尾✅」不实 → 纠偏注(本轮不实装,留拍板)⑥ **M7** 换主清零标未消费 · **L1** 门派 Dialog 限高 80% 屏 + 长文滚动。全量 analyze **0** / 全量 **2247 测** +1 skip 零回归。**待拍板 backlog**:心魔失败惩罚实装(M6)。

> ✅ **2026-06-15 续14(P3 战报失败诊断系统 立项→实装 全闭环 · 合 main `6a32901a` · opus · brainstorm→spec→plan→TDD)**:可玩性二期 backlog「战报诊断规则(§11.4)」打磨项。把败北单条硬编码提示升级为 §7.2 **三段式失败复盘**(1 主因 + 2 数据 + ≤2 跳转建议)。核心 = 纯函数 `BattleDiagnosis.from(BattleState, BattleReportConfig)` 镜像 `BattleStatsSummary`,**全 5 类规则**优先级有序首条命中即止:killed_by_charge(100)/internal_wound(90)/mob_overrun(80,§11.4 原条)/frontline_fragile(60)/dps_too_low(40)+generic 兜底。阈值进 numbers.yaml `battle_report` 段(4 字段 schema 校验);文案进 UiStrings(退役 `battleDefeatHintInterrupt`)守 §5.6;增强 `VictoryOverlay` 败北路径不新建 screen,跳转(skills/equipment/cultivation)叠 overlay 不打断「继续」(team 无 screen 拍板不做按钮)。防御式 `_safeDiagnose`(config 未就绪退化 null 不崩 overlay)。**0 改伤害公式/红线**。+14 测(config 2+diagnosis 9+overlay 3)/全量 **2245 测**+1 skip 零回归/analyze 0。**待视觉验收**:三段式诊断块排版(visual_route_host 已补败北诊断态预览)。spec+plan `2026-06-15-battle-report-diagnosis-*`。

> ✅ **2026-06-15 续13(P1b MeridianBar wiring · 合 main · opus high)**:四系统进度展示统一收口——`technique_panel` 修炼度 tile 从 Material `LinearProgressIndicator` 换 `StageProgressRow`(MeridianBar + 当前/下一阶伤害倍率五要素),与 character_panel/熟练度/共鸣度同款规范;**残页保留方块**(离散收集 X/N 片语义,用户拍板)。Explore 盘点四系统现状(校正其「character_panel 编译报错」误判)→ 实际单处 wire。+1 widget 测 / 全量 **2231 测**零回归 / analyze 0。**待视觉验收**:StageProgressRow 嵌入 technique tile 协调(与 M2/L3 挂账一起真机看)。

> ✅ **2026-06-15 续12(M2 范围 B 通用被动离线挂机 立项→实装 全闭环 · 合 main `212b572c` · opus xhigh · subagent-driven)**:brainstorming 拍 9 决策(闭关增强版/25% 涓流/经验+磨剑石/自动入包仅告知/互斥不叠加)→ spec+plan→ 7 Task TDD(PassiveIdleConfig→compute 纯函数→SaveData 累计字段 saveVer **0.24.0**→settle 入库+gate 闭关被动互斥分流+旧档首启不回溯→lastOnlineAt 真写入点 AppLifecycleListener→归来卡被动变体→balance_simulator 红线复评)。**兑现 GDD §5.5「关游戏=挂机」**(原 lastOnlineAt 死字段),被动经验走 applyExperience 含心魔锁/升层不破境界锁(§5.3),无领取按钮守 §5.1,0 改伤害红线。Task4 完整 reviewer ✅ + final review **READY TO MERGE**(9 决策全兑现)。全量 2214→**2230 测**零回归 / analyze 0。**待真机验收**:关游戏重开被动卡 + lifecycle detached 写 lastOnlineAt 实效(bg 测不到 GUI)。spec+plan `2026-06-15-m2-offline-passive-idle-*`。

> ✅ **2026-06-15 续11(L1 Codex 本机验收 + 两 fail 回修 · 合 main `a0f77a8b` · opus xhigh)**:Codex GUI 验收 L1(closeout `2026-06-15_l1_display_codex_acceptance.md`)— L1-1 全屏 / L1-4 重启恢复 / L1-5 M2 归来卡视觉 ✅;两 fail 回修:① L1-2 设置面板 720p 底部 overflow → ConstrainedBox(80% 屏)+SingleChildScrollView(回归测 +1)② L1-3 macOS F11 被系统「显示桌面」占 → 补 Alt+Enter(留 F11 给 Windows)。**二轮用户本机实测 Alt+Enter/720p 无 overflow/前去收功跳转全 pass,L1+M2 验收闭环、无遗留**。全量 2213→**2214 测**零回归。

> ✅ **2026-06-15 续10(L3+2 清理合并 + M2 归来卡 + L1 显示设置 · 全合 main · opus xhigh)**:① L3 闭关非阻塞(续9 worktree)+ 2 项安全清理经独立 gate review 全过,ff-merge 合 main(`45f0f5d4`)。② **M2 离线收益范围 A**(`7efb82c8`,13 测 TDD):重开 HomeFeed 首帧查 active 闭关,离开≥1h 弹「归来」水墨卡(已满/进行中 P%+预估磨剑石·经验+去收功),复用 computeOutputs 同口径,0 改 schema/红线(GDD §5.5 无关,仅可见化已发生闭关产出);范围 B 通用被动挂机触红线单独立项待拍板。③ **L1 显示设置**(`130b40ac`,10 测 TDD):引 window_manager 0.5.1,全屏+3 档分辨率(1280×720/1600×900/1920×1080)+F11,SharedPreferences 持久化(端机偏好不进 Isar),WindowController 抽象隔离 platform channel。闸门 analyze 0 / 全量 2190→**2213 测**(+M2 13+L1 10)/零回归。**待真机验收**(bg 无法跑 GUI):L1 窗口实效(全屏/resize/F11)。spec:m2-offline-recap-design.md / l1-display-settings-design.md。**UX 滚动表 H/M/L 全清**。

> **2026-06-14 红线/战斗交互重做批已压缩归档**(git log `7adc8532→3edc99ae` · 详各 closeout · 2160→2165 测):战斗交互重做 Phase1-4(自动播放+随时拖招,废半手动/录制回放净 -2050 行)+ 周目按章(saveVer0.23)+ 周目进化 A-F1(敌人 scale/5 反制词条/Boss HP 红线 50000→60000 · Codex 视觉 10/10)+ 拖招表现层微调(引导线外发光/蓄势呼吸光晕 · Codex 5/5)+ **红线语义收口分两层**(硬=配置基础表值 schema 拦截 / 软=极值满 build 实战可见值不进百万,balance_simulator 极值×周目诊断证伪「不进十万」)+ towers 注释补漏。

> **2026-06-13 半手动战斗 master spec + P0 全闭环已压缩归档**(详 `2026-06-13-semi-manual-battle-*` spec/plan + 各 closeout · 2011→2067 测):半手动+seed重放+周目进化 master spec 定稿 → P0 步骤 3b-5 全闭环(逐 actor 单步 stepOne/单步 UI/重放执行/schema 0.19 落盘 BattleReplayRecord/全局+per-stage 自动开关 UI · 自/手印章 glyph)+ AGENTS.md 瘦身 stub 根治双文档漂移。

> **2026-06-12 UX 整合 + 爆品展示 + 音视频批已压缩归档**(详 `2026-06-12-*` spec + 各 closeout · 1950→2002 测):战斗/装备 UX 整合方案 12/12(藏经阁+装备链路+战斗指令台 · Codex R2 5/5)+ 爆品展示(印章盖落动画/tagline 35句/时序重排爆品当第一高潮)+ BGM 扩 8 轨细分 + D 四类养成进度五要素标准化(StageProgressRow)+ UI 视觉 sweep + 神物金光 TreasureGlowLayer + E 音频 Phase0 摸底。

> **2026-06-11 长线打磨 波A/波B + 音频批已压缩归档**(详 `2026-06-11-wave-{a,b}-*` spec + 各 session · 1888→1932 测):波A P1 机制深度(破招 build gate §9.1/interrupt_power_pct/per-skill 熟练度铺广/来源统一 skillUnlockProgress)+ 波B 24 招全内容+机制 Boss×6+装配池 wiring+30 关高熟练度 sweep + 平A 命中音 6 变体 + 战斗 BGM 短前奏版 + jingle 扩槽 + 工程清理。

> **2026-06-09/10 可玩性 P1a/P1b 养成内核批已压缩归档**(详 `p1a_cultivation_core_closeout_2026-06-10.md` + 各 closeout · 1778→1883 测):P1a 养成内核(per-skill 熟练度 1.00→1.30/解锁进度 SkillUnlockService/Boss 掉书+残页)+ P1b 藏经阁技能装配(Character 5 装配槽 saveVer0.17/SkillLoadout autoFill)+ B3 破招「破!」题字+B5 败北页路由 + P0 手动 Boss 破招全闭环 + 音频系统全闭环(SoundManager/三类 hook)。

> ✅ **2026-06-05..09 归档**(UI kit v1 序 0 = 9 组件 + `WuxiaUi` token · Codex 两天 UI 包装/MJ 56 张接入 `a195547` · §5.6 硬编码审计抽 UiStrings/T5 闭关地图化/截图基建/心法 cover 重出 `c991984` · 1713→1763 测/0 analyze):详 git log `feat/ui-kit-v1`→`e767c42` + 各 closeout/plan。

> **2026-06-04 两条已压缩归档**(8 张装备图重出+工作树清理+UI 包装方案 v1 `9ea8f4f` / P0-3 ②③ 主修 hero+心魔瓶颈面板 `f9425b8` · 1697→1712 测):详 git log + 各 spec/closeout。

> **2026-06-01..03 详条已压缩归档**(git log/closeout 完整可溯 · 1661→1697 测/0 analyze):① **P0-2 战斗单位可见化全闭环**(玩家立绘+单位放大 110+死亡 grayscale+弹道笔触+受击闪+折叠日志+胜负 vignette · 弹道/受击走 actionLog 不写 BattleState 红线 · `c7fb79c`)② **P0-3 角色卡 ① 装备外观可视化**(装备槽 iconPath+tier 色 _EquipGlyph)③ **P0-4b 仓库格子化实装**(列表→部位分组网格+tier 边框+强化徽章+师承标+境界锁灰化 · `2049265` · Codex R3 PASS `880d7f7`)④ **装备 detail 45 件 + 敌人图 37/37 全归位**(美术缺口归零 `239d1d9` · 129 敌人图 + 80 装备 detail)⑤ **验收提速基建**(`VISUAL_ROUTE=hub` 一次 build 点遍 12 路由 + `tool/build_acceptance.sh` 预编 · `d94a56a`)。详 `docs/handoff/overnight_2026-06-03_handoff.md` + 各 closeout。

> **2026-05-30..06-02 出版美术 pass(1.0 Presentation Pass)全闭环已归档**(1581→1667 测/0 analyze · `docs/PUBLISHING_ART_PASS_1_0.md`):战斗屏(主菜单水墨山门 + B1 背景按 biome 接线+scrim+胜负仪式 overlay + B2 大招题字+Boss 金边)+剧情屏(narrative_scene 基建+30 图)+战斗场景 16 biome 全覆盖+角色页档案化+章节封面 6 章 · Codex 多门视觉验收 PASS · D 段性能稳定性验证(8h/leak/ANR 逻辑层已验)+窗口 min size Pen 3/3 PASS + B1 release audit doc 同步(CLAUDE v1.17 测数 1667)+ P5.2 敌人内力按境界对称化 scale=0.20 + 文案 polish H 段全角标点 + #4③ 数值迁 yaml + V3 神物金掉落验收 3/3 PASS。git log `c97c682→880d7f7` 区间 + 各 closeout 完整可溯。

> **2026-05-30 H1 修复批全闭环已压缩归档**(`58c6f29`→`2dd597b` · 1555→1569 测 / 0 analyze):批1 主菜单 7 未解锁系统 §5.7 门控 + 门派名迁 UiStrings · 批2 `EquipmentService.equip/unequip` 装备穿戴入口(修核心循环断裂 · §5.3 守卫 + picker)· 批3 掉落 dialog 品阶仪式感 + 闭关装备名 bug + 凝练常驻态 + 过场调色 + tick→回合术语 · picker「他人装备中」移装标注。详各 commit/closeout。

> **2026-05-29 详条已压缩归档**(全程 commit/closeout/git log 完整可溯,1534→1555 测):① 方向调整(F/G Steam 搁置 · H 段升主聚焦 · balance_simulator PoC)· H1-Q1 主菜单产品名 P0 清零 · H2/H3/H1 三部曲 audit(`h{1,2,3}_*_audit_2026-05-29.md`)② 外部 review 修复批 P1-a 飞升 auto_swap §5.3 守卫 / P2-a 奇遇招式池空 fail-fast / P2-b 敌人属性抽 numbers / P2-c 战斗公式双路径收敛单一真相源 / P3 三文档血量公式 drift 对齐(commit `559455f`/`f719172`/`62b0b7e`/`2686815`/`1afc888`)③ 根因A 挂机循环重平衡 B1+B2+B3 实装(共鸣双管+闭关 EXP+insightPoints sink · `a359dc2`/`d7ee3f9`)+ B2 低 tier EXP 回 ×1.0 修正 + idle_economy 验证 · 红线值统一 numbers.yaml(`7a1d1e7`)· balance_simulator 升真 build + floor/ceiling bracket + on-level 修正 ④ D 段难度修复:stage_01_05 Ch1 Boss +2 阶硬墙(`781c85b`)+ stage_05_05 跨阶过苛缓和(`24cea80`)→ 过难关清零。


---

## 已知偏差 / 挂账事项

- ~~#37-#45 / stage_05_05 跨阶墙 / equipment_detail '(基 $base)' nit~~ 全销账(2026-05-17..06-08):详各 closeout + 末尾归档

> 已销账条目(#1-#45)详见末尾归档。**P1 阶段全销账 ✅** + **Demo §8.4 14/14 全达标 ✅** + **1.0 ~95% release ready ✅**(A+B+C 全 PASS · 剩 D-G 留 M15-16)。

## 关键约束(每次开局必读)

- 数值红线:普伤 ≤8000 / 玩家血 ≤20000 / 内力 ≤15000 / 装备攻击 ≤2000(GDD §5.2)
- 不硬编码数值/文案(走 numbers.yaml / data/narratives, lore, events)
- Riverpod 状态管理;Isar 本地存储;data/ asset 根
- 不动 GDD.md / CLAUDE.md / numbers.yaml / data_schema.md / IDS_REGISTRY.md(数值/规则层 · 改前 ask)
- Mac 端写 lib/、data/(顶层)、test/、文案(v1.8 起 DeepSeek 退役)

## 远程仓库

- GitHub:https://github.com/Zed1118/wuxia_idle · 主分支 main
- 协作:Mac 单端代码+数值+文案;视觉验收 Mac 本地 Codex(Pen Windows AI 工具 2026-06-11 全下线)

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
- **2026-05-26 P4.1 1.1 四项+audit v3+P5.2+Boss 招降叙事**(1484→1505 测 · 详各 closeout)
- **2026-05-27 Boss 招降叙事+debug 招募+R2 派单**(1505 测 · 详 `session_closeout_2026-05-27_boss_narrative_debug_recruit.md`)
- **2026-05-28 过夜清理+P3 三项+P2.1 4 批+drop 全覆盖+CHECKLIST v1.5+R4 派单**(1505→1519 测 · 详 `overnight_1_1_cleanup_handoff_2026-05-28.md` / `session_closeout_2026-05-28_p3_p1_triple.md` / `codex_dispatch_r4_p2_1_content_drop_2026-05-28.md`)
