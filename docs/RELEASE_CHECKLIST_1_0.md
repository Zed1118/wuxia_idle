# 挂机武侠 1.0 Release Checklist

> **v1.0** 起草 2026-05-25 · Mac+Opus xhigh · **长寿文档**(跨阶段更新)
> 状态来源:`docs/handoff/1_0_release_audit_v2_2026-05-25.md` 6 系统快照 + 本会话 P5.0
> 与 `docs/ROADMAP_1_0.md` 互补:ROADMAP 是 16 月宏观规划,本文档是 Steam 上线前**二元勾选清单**
> ⚠ 本 checklist 是 Steam 1.0 上线前的最终勾选,**所有 A-E 段必收勾完方可上线**

## TL;DR

**当前 release readiness:~96%**(A+B+C 全 PASS · 0 P0/P1 阻塞 · **1519 测 / 139 测文件 / 0 analyze** · P2.1 4 批全收 + 77 件主线装备 drop 全覆盖 + **80 件装备 icon 美术全齐** · 剩 D 性能 / E 音频 / F Steam / G 法律商业 + 装备 detail 图 80 张 M15-16)

| 段 | 完成度 | 阻塞? |
|---|---|---|
| A 代码质量 | ✅ 100% | — |
| B 系统完整性(6 系统) | ✅ 100% | — |
| C 视觉验收 | ✅ 100% C.1 8/8 + C.2 4/4 + **C.3 R3 必收 10/10 PASS** | — |
| D 性能稳定(P5.2) | ✗ 0% | M15-16 |
| E 音频(P5.3) | ✗ 0% | M15-16 |
| F Steam 集成(P5.4) | ✗ 0% | M15-16 |
| G 法律商业 | ✗ 0% | M15-16 |

## A. 代码质量(本机可验 · ✅ 全过)

- [x] `flutter analyze` 0 issues
- [x] 全测族过(**1519 测** / 139 测文件)
- [x] 数值红线 §5.4 测族 13+ 守护(普伤 ≤8000 / 玩家血 ≤20000 / 内力 ≤15000 / 装备攻击 ≤2000)
- [x] 三系锁 §5.3 测族 5+ 守护(境界 ↔ 装备阶 ↔ 心法阶)
- [x] §5.5 在线=离线(挂机 = 实际时间)
- [x] §5.1 反留存(无每日任务 / 登录奖励 / 战令 / 抽卡 / VIP / 体力)
- [x] §6 公式集中在 `lib/core/combat/formulas.dart` + `damage_calculator.dart`
- [x] 0 硬编码(中文文案走 `data/narratives/lore/events/` · 数值走 `data/*.yaml`)
- [x] Isar schema 0.14.0 稳定(Q6B saveVersion 升档)
- [x] Riverpod 3.x 锁定(无 BLoC)
- [x] 无第三方游戏引擎(无 Flame)

## B. 系统完整性(audit v2 6 系统 · ✅ 全健康)

- [x] **战斗核心**:19 file(engine/state/log/ai/damage_calc/strategy×3)· 红线 13+ / 三系锁 5+ / 流派克制 wire 完整 · **P3.2.B 群战 wave 间 IF 恢复调优 ✅**(aliveIfRecoveryPct=0.50 修全 draw) · **P3.x 群战 UI wiring ✅**(MassBattleStrategy 接入 stage_entry_flow + 阵型选择 dialog)
- [x] **encounter**:94 测 / festival 8 全 wire · 软概率公式 `p = base × (1 + fortune/20)` 与 GDD §12.2 #6 v1.9 对齐
- [x] **闭关**:62 测 · 时辰加成 `solarTermMultiplier` wire · 12 节气 hardcode · 离线累积 idle tick
- [x] **师徒/共鸣/飞升**:49 测 · founderBuff 三维度(maxHp/crit/internal)· P5+ 多代飞升 + 真传位完整(v1.15)
- [x] **社交(sect+jianghu+pvp)**:22 文件 / 123 测 · enmity clamp / sectRank 三阶 ≠ 七阶 / ELO 数值范围 · **P4.1 1.1 sect 全闭环 ✅**(Q6A encounter recruit + Q6B stage_boss recruit + founder_buff cross_sect + polish)
- [x] **cross-system**:T20 跨系统数值红线 audit 通过 · `balance/ch4/5/6` + synergy hot loop + maxhp extremum + p3_1 light foot · **P1.2 Boss 击杀声望 wire ✅**(StageDef.factionId + factions.yaml 加载 + boss 派 -5 / rival 派各 +3)

### B 段附加(production seed 阻塞清)

- [x] **P5.0 onboarding production seed ✅**(2026-05-25 修):`OnboardingService.ensureFoundingMasters()` 幂等(信源 `isFounder=true count`)· 全新启动 Character × 3 + Equipment × 9 + Technique × 4 + 物料 50/0
- [x] **debug 入口 kDebugMode 切除**:Phase1/2 BattleTestMenu/Phase2TestMenu release build 不显
- [x] **home_feed 空 feed 引导**:「按下「直入江湖」启程」文案 wire
- [x] **Boss 招降叙事 6 篇 ✅**(2026-05-27):Ch1-3 折剑/卸刃/空手 + Ch4-6 预写 留镜/解佩/收剑 · `stage_boss_recruit_hook` 接 `NarrativeReaderScreen`
- [x] **debug 强制招募入口 ✅**(2026-05-27):`SectRecruitDebugScreen` 主菜单加「强制招募 NPC」· 跳过战斗/奇遇直走 `runSectRecruitFlow`
- [x] **Boss 招降+收降叙事全齐 12/12 ✅**(2026-05-28):战胜 6 篇(Ch1-3 折剑/卸刃/空手 + Ch4-6 留镜/解佩/收剑)+ 战败 6 篇(Ch1-3 + Ch4-6 败后叙事)
- [x] **P3.2.B 群战数值调优 ✅**(2026-05-28):`aliveIfRecoveryPct=0.50` 修 stage 03/04/05 全 draw → 37W/45W/30W
- [x] **P1.2 Boss 击杀声望 wire ✅**(2026-05-28):`StageDef.factionId` 6 主线 Boss + `_applyBossKillReputation` victory wire + R5.8 6 测
- [x] **P3.x 群战 UI wiring ✅**(2026-05-28):`MassBattleStrategy` 接入 `stage_entry_flow` + `buildEnemyTeamsPerWave` + 阵型选择 dialog + UiStrings 7 段
- [x] **P2.1 内容扩充 4 批全收 ✅**(2026-05-28):装备 35→80(+45 跨 T1-T7 全 slot)/ 心法 21→49(+28 三流派 7 阶覆盖)/ 技能 82→166(+84 招式描述全补齐)/ lore 0→80(装备典故)/ 相生 8→12(+4 传说彩蛋)
- [x] **装备 drop 全覆盖 ✅**(2026-05-28):56 条 dropTable 条目注入 26 个主线关卡 · 77 件主线装备全部有至少 1 个 dropTable 来源 · +1 覆盖率红线测试(sealed class pattern match)
- [x] **装备 icon 美术 45 张入库 ✅**(2026-05-28):MJ v7 水墨厚涂 + AutoSail Chrome 扩展批量 · 7 阶全齐(T1 6/T2 6/T3 6/T4 7/T5 7/T6 7/T7 6=45)· 全 80 件主线装备 iconPath 引用 0 缺图 · detail 图 80 张留 M15-16

## C. UI 视觉验收

### C.1 基础 8 项(Pen Codex ✅ 全 PASS 2026-05-26)

- [x] 全新启动 `江湖见闻`+`直入江湖`引导(`01_fresh_launch_clean_isar.png` · 无 crash)
- [x] 主菜单全 menu 项 release build seeded(`02_main_menu_top_seeded.png` + `03_main_menu_lower_sect_visible.png` · 14+ 项 · 含「门派事务」)
- [x] 门派事务 → sect_screen 4 Tab(`04_sect_four_tabs_current_events.png` · **当前事件 / 历史记录 / 成员 / 领地** · 无名宗 等阶 1 · 声望 50/100)
- [x] sect_screen 成员 Tab(`05_sect_members_tab_clean_seed.png` · clean seed 空状态显示「尚无门派成员」无 layout 破)
- [x] sect_screen 领地 Tab(`06_sect_territories_tab_clean_seed.png` · territory cards + 占领 actions)
- [x] 主线章节屏 clean seed(`07_mainline_chapters_clean_seed.png` · 章节 lock 渲染正常)
- [x] 战斗 e2e(`08_battle_e2e_clean_seed.png` · 3v3 战斗 + 「左队胜 · 总伤害 10022 · 暴击 0 次 · 用时 7 tick」§5.4 红线守)
- [x] 战斗结束结算屏(同 08 · 「返回菜单」按钮)

### C.2 P4.1 1.1 sect recruit 验收(R2 ✅ 全 PASS 2026-05-28)

- [x] 「强制招募 NPC」按钮可见 + 候选列表 **6** NPC(05-28 池扩 valley_hermit 生效)
- [x] 二次确认对话框弹出(标题「是否招入门派?」· 按钮「招入门派」/「婉拒」· 含属性+lore)
- [x] 招募成功 SnackBar 显示(「竹影客 折服于你的剑下,入门派任 [初入] 阶」)
- [x] character_panel「门派同道: 竹影客 / 漠行客」非空成员列表 ✅

> R1(2026-05-26)3 FAIL:debug picker 不走 recruit wire / 打不赢 Boss / 非空列表未验 · 已修 commit `6e771fd` 加 `SectRecruitDebugScreen` · R2 派单 `docs/handoff/codex_dispatch_r2_sect_recruit_2026-05-27.md`

> 派单单据 + 续跑成功段 `docs/handoff/codex_visual_check_p5_p4_1_2026-05-25.md` · 8 截图归档 `docs/screenshots/p5_p4_1_visual_check_2026-05-25/` · **WARN**:1280×720 截图右边框是 Pen 桌面捕获 framing 不是 in-app bug / clean seed 成员 Tab 空状态预期非 bug · **Isar 路径修正**:派单 prompt 写 `%LOCALAPPDATA%\com.example.wuxia_idle\` 实际是 `getApplicationDocumentsDirectory() → C:\Users\Administrator\Documents\wuxia_save_slot1.isar`(下次派单沿 `isar_setup.dart` grep)

### C.3 R3 合并验收(✅ 必收 10/10 PASS 2026-05-28)

- [x] **R1 P5+ 飞升全流程**(5/5):按钮 enable / 装备选择 / 弟子下拉 / 确认 dialog / snackbar
- [x] **R2 心魔+轻功+群战+阵型**(5/5):3 Screen 入口 + 阵型选择 dialog(雁行/八卦/锋矢)+ 群战结算
- [x] **R3 Ch4-6 章节列表**(1/1):Ch4/5/6 可见 · narrative opening 因章节锁定标 LOCKED_EXPECTED
- [x] **R4 声望面板**(1/1)
- 4.2 门派持久:NOT_APPLICABLE(clean seed 无招募数据 · R2 已验证持久化)

> R3 派单 `docs/handoff/codex_dispatch_r3_consolidated_visual_check_2026-05-28.md` · 16 截图归档 `docs/handoff/r3_visual_check_screenshots/` · closeout `docs/handoff/pen_visual_verify_r3_consolidated_2026-05-28.md`

## D. 性能稳定(P5.2 · 留 M15-16)

- [ ] 长时间运行 8h+ 无 crash(挂机典型场景)
- [ ] 内存增长稳定(无 leak 锚点)
- [ ] FPS 主菜单 / 战斗 / 闭关 平均 ≥ 60(Steam 用户机器最低配)
- [ ] Isar IO 无 ANR(大背包 / 多 character 场景)
- [ ] 30-35 关全玩家路径数值再平衡(P5.2 难度曲线)
- [ ] P5.4b closed beta ~10 人外部反馈(Google 表单结构化:难度评分 / 数值 bug / 流程卡点 / 通关时长)

## E. 音频(P5.3 · 留 M15-16)

- [ ] BGM 主线 / 战斗 / 闭关 3 套(水墨克制基调)
- [ ] SFX 战斗(攻击 / 命中 / 暴击 / 死亡 · 7 阶递进)
- [ ] SFX UI(按钮 / 翻页 / 反馈)
- [ ] 配音(关键剧情:师父三句遗言 / Ch4-6 主敌登场 · 至少 ~10 段)

## F. Steam 集成(P5.4 · 留 M15-16 · 1 月 buffer)

- [ ] Steam developer 账号 + 商品页提交
- [ ] 成就接入(7 阶突破 / 飞升 / 跨章 / 心魔 / 群战 / 轻功 / 师徒传承)
- [ ] 云存档(可选,Demo 同步策略)
- [ ] Steam Demo 版上架(P5.4b · 替代 itch.io 中间态)
- [ ] MSIX 打包工具链
- [ ] Sentry release 监控 + sourcemap 接入
- [ ] 评测 / 锁国问题 / 商品页本地化

## G. 法律商业(留 M15-16)

- [ ] 中国机构 ICP 备案(如发行国内 region)
- [ ] 美术 AI 出图版权声明(LoRA 自训练 · 风格独立 · 非 IP 仿冒)
- [ ] 字体授权(可商用确认)
- [ ] BGM/SFX 来源(原创 / 授权 / CC0)清单
- [ ] 隐私政策 + EULA(Steam 模板适配)

## H. nice-to-have(不阻塞 · 留 M15-16 评估)

- [ ] 英文翻译(主线 / UI / 系统提示 · P4.2 可选 · M12 评估)
- [x] ~~1.1 挂账起步~~ → **P4.1 1.1 四项全闭环 ✅**(Q6A encounter recruit v1.12 + founder_buff cross_sect v1.13 + Q6B stage_boss recruit v1.14 + polish v1.15 · 1505 测)
- [x] ~~1.1 战败收降 + 池扩~~ → **stageBossFailRecoverProb 战败收降 wire ✅ + stage_04_05+ 池扩 ✅**(2026-05-28 过夜清理 · 败后叙事 6 篇 + Ch4-6 bossRecruit config + valley_hermit NPC)
- [ ] 1.1 剩余挂账:candidateRefs rng pick(降级 1.2)
- [ ] Pen 视觉验收发现的产品 bug 修(若 C 段验出)

## I. 1.0 已 OUT 项(留 2.0)

- 婚姻后代(GDD §12.2 · 2026-05-17 砍)
- MOD 支持(GDD §12.4 · 2026-05-17 砍)
- 角色寿命传承(GDD §12.5)
- 江湖编年史(GDD §12.5)
- 跨周目元数据(GDD §12.5)
- 多平台扩展(Mac / Linux / Switch)
- DLC / 资料片 / 持续更新

---

## 修订记录

- **v1.6**(2026-05-28)装备 icon 美术 45 张入库:B 段附加加装备 icon 美术全齐(MJ v7 + AutoSail 批量 · 7 阶全齐 · 80 件 iconPath 0 缺图)· TL;DR 内容总量更新加 80 件装备 icon · release readiness 95%→**~96%**。detail 图 80 张留 M15-16。
- **v1.5**(2026-05-28)P2.1 全收 + drop 全覆盖:A 段测试数 1514→1519 · B 段附加加 P2.1 内容扩充 4 批全收(装备 80/心法 49/技能 166/lore 80/相生 12)+ 装备 drop 全覆盖(56 条 dropTable · 77 件主线装备 · +1 红线测试)· TL;DR 内容总量更新。**~95% 维持**。
- **v1.4**(2026-05-28)C 段 100% + P2.1 Batch 1:C.2 R2 全 PASS 勾完 + C.3 R3 合并验收必收 10/10 PASS(P5+ 飞升/心魔/轻功/群战+阵型/Ch4-6/声望)+ P2.1 Batch 1 装备 35→80 落地。release readiness 93% → **~95%**。
- **v1.3**(2026-05-28)P3.2.B+P1.2+P3.x 三项实装 + 1.1 挂账清理状态对齐:A 段测试数 1505→1514 · B 段战斗核心行加 P3.2.B 群战调优 + P3.x UI wiring · cross-system 行加 P1.2 Boss 声望 wire · B 段附加加 4 项(招降收降叙事 12/12 + P3.2.B + P1.2 + P3.x)· H 段 1.1 战败收降+池扩标闭环 + 剩余挂账缩至 candidateRefs(1.2)· **~93% 维持**。
- **v1.2**(2026-05-27)P4.1 1.1 全闭环状态对齐:A 段测试数 1484→1505 / 139 测文件 / Isar 0.13→0.14 · B 段 sect 社交行加 P4.1 1.1 四项闭环注 · B 段附加加 Boss 招降叙事 6 篇 + debug 强制招募入口 · C 段拆 C.1 基础(8/8 PASS 维持) + C.2 P4.1 1.1 sect recruit(R2 验收中 4 项) · H 段 1.1 挂账标闭环 + 剩余挂账明细 · Pen 仓库从 T18 拉齐到 HEAD `4bdc08d` + git remote 切 SSH · **~93% 维持**(C.2 R2 回来勾完后 C 段 100%)。
- **v1.1**(2026-05-26)Pen Codex 视觉验收 ✅ 闭环:Mac SSH 反向 tar pipe 救场 5min → Codex 续跑 PASS · 8 截图全 PASS(`docs/screenshots/p5_p4_1_visual_check_2026-05-25/01-08.png`)· C 段 8 项全勾 · release readiness 91% → **93%**(本机可验 + 视觉验收 全清零)· 剩 D-G M15-16。**Isar 路径修正记录**:实际路径 `C:\Users\Administrator\Documents\wuxia_save_slot1.isar`(`getApplicationDocumentsDirectory()` Windows fallback)非 `%LOCALAPPDATA%` · 下次派单 prompt 沿 `lib/data/isar_setup.dart` grep。
- **v1.0**(2026-05-25)起草:Mac+Opus xhigh ~25min · 上游 audit v2 doc + P5.0 onboarding 闭环 + Pen 派单准备 · 当前 ~91% release ready · 0 P0/P1 阻塞 · 剩 C 段视觉验收 + D/E/F/G 留 M15-16
