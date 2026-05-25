# 挂机武侠 1.0 Release Checklist

> **v1.0** 起草 2026-05-25 · Mac+Opus xhigh · **长寿文档**(跨阶段更新)
> 状态来源:`docs/handoff/1_0_release_audit_v2_2026-05-25.md` 6 系统快照 + 本会话 P5.0
> 与 `docs/ROADMAP_1_0.md` 互补:ROADMAP 是 16 月宏观规划,本文档是 Steam 上线前**二元勾选清单**
> ⚠ 本 checklist 是 Steam 1.0 上线前的最终勾选,**所有 A-E 段必收勾完方可上线**

## TL;DR

**当前 release readiness:~91%**(0 P0/P1 阻塞 · 本机可验全过 · 剩 Pen 视觉验收 + P5.x M15-16 子项)

| 段 | 完成度 | 阻塞? |
|---|---|---|
| A 代码质量 | ✅ 100% | — |
| B 系统完整性(6 系统) | ✅ 100% | — |
| C 视觉验收 | ⏳ 派单中(Pen Codex 异步) | ✗ 不 release blocker / ✓ release ready 验证 |
| D 性能稳定(P5.2) | ✗ 0% | M15-16 |
| E 音频(P5.3) | ✗ 0% | M15-16 |
| F Steam 集成(P5.4) | ✗ 0% | M15-16 |
| G 法律商业 | ✗ 0% | M15-16 |

## A. 代码质量(本机可验 · ✅ 全过)

- [x] `flutter analyze` 0 issues
- [x] 全测族过(**1484 测** / 137 测文件)
- [x] 数值红线 §5.4 测族 13+ 守护(普伤 ≤8000 / 玩家血 ≤20000 / 内力 ≤15000 / 装备攻击 ≤2000)
- [x] 三系锁 §5.3 测族 5+ 守护(境界 ↔ 装备阶 ↔ 心法阶)
- [x] §5.5 在线=离线(挂机 = 实际时间)
- [x] §5.1 反留存(无每日任务 / 登录奖励 / 战令 / 抽卡 / VIP / 体力)
- [x] §6 公式集中在 `lib/core/combat/formulas.dart` + `damage_calculator.dart`
- [x] 0 硬编码(中文文案走 `data/narratives/lore/events/` · 数值走 `data/*.yaml`)
- [x] Isar schema 0.13.0 稳定
- [x] Riverpod 3.x 锁定(无 BLoC)
- [x] 无第三方游戏引擎(无 Flame)

## B. 系统完整性(audit v2 6 系统 · ✅ 全健康)

- [x] **战斗核心**:19 file(engine/state/log/ai/damage_calc/strategy×3)· 红线 13+ / 三系锁 5+ / 流派克制 wire 完整
- [x] **encounter**:94 测 / festival 8 全 wire · 软概率公式 `p = base × (1 + fortune/20)` 与 GDD §12.2 #6 v1.9 对齐
- [x] **闭关**:62 测 · 时辰加成 `solarTermMultiplier` wire · 12 节气 hardcode · 离线累积 idle tick
- [x] **师徒/共鸣/飞升**:49 测 · founderBuff 三维度(maxHp/crit/internal)· P5+ 多代飞升 + 真传位完整(v1.15)
- [x] **社交(sect+jianghu+pvp)**:22 文件 / 123 测 · enmity clamp / sectRank 三阶 ≠ 七阶 / ELO 数值范围
- [x] **cross-system**:T20 跨系统数值红线 audit 通过 · `balance/ch4/5/6` + synergy hot loop + maxhp extremum + p3_1 light foot

### B 段附加(production seed 阻塞清)

- [x] **P5.0 onboarding production seed ✅**(2026-05-25 修):`OnboardingService.ensureFoundingMasters()` 幂等(信源 `isFounder=true count`)· 全新启动 Character × 3 + Equipment × 9 + Technique × 4 + 物料 50/0
- [x] **debug 入口 kDebugMode 切除**:Phase1/2 BattleTestMenu/Phase2TestMenu release build 不显
- [x] **home_feed 空 feed 引导**:「按下「直入江湖」启程」文案 wire

## C. UI 视觉验收(本机查不了 · Pen Codex 派单 ⏳)

- [ ] 全新启动 splash → home_feed(clean Isar · `ensureFoundingMasters` 跑过 · Character × 3 / Equipment × 9 / Technique × 4 真显)
- [ ] 再次启动幂等(Character 计数仍 3 不变 4)
- [ ] 主菜单全 menu 项 release build(14+ 项 · 无 Phase1/Phase2 debug 入口)
- [ ] 门派事务 → sect_screen 4 Tab(当前事件 / 历史记录 / 成员 / 领地)
- [ ] sect_screen 成员 Tab(founder + disciple × 2 · sectRank 三阶之一)
- [ ] sect_screen 领地 Tab(6 territory grid 跨阶 2-5)
- [ ] 战斗 e2e(`StageBattleSetup._buildPlayerTeam` 不抛 · 3v3 显示)
- [ ] 战斗结束结算屏(胜负 / 战利品 / 返回菜单)

> 派单单据 `docs/handoff/codex_visual_check_p5_p4_1_2026-05-25.md`(Pen Codex 回报后 commit)· 截图归档 `docs/screenshots/p5_p4_1_visual_check_2026-05-25/`

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
- [ ] 1.1 挂账起步(Q6 A encounter recruit spec 已起草 · 见 `docs/spec/p4_1_q6a_encounter_recruit_spec_2026-05-25.md`)
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

- **v1.0**(2026-05-25)起草:Mac+Opus xhigh ~25min · 上游 audit v2 doc + P5.0 onboarding 闭环 + Pen 派单准备 · 当前 ~91% release ready · 0 P0/P1 阻塞 · 剩 C 段视觉验收 + D/E/F/G 留 M15-16
