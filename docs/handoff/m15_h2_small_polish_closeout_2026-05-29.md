# H2 小套餐(接线 polish)closeout

> 2026-05-29 · H 段 Batch H2 实装第一批 · opus xhigh · TDD red-green
> 来源 audit `h2_midgame_audit_2026-05-29.md` §5 小套餐 · 用户拍「按推荐执行」
> verify:**1534 测全过**(baseline 1520 + 新增 14)· **0 analyze** · ~1 skip(既有)

## 实装(5 项,0 数值改 0 schema 改)

- **C1 章节翻篇过场** ✅:`NarrativeLoader.loadChapter` + `ChapterNarrative` model(接 `data/narratives/chapters/<id>.yaml` 的 prologue/epilogue · 此前 lib/ 0 引用 dead content)+ `ChapterTransitionScreen`(卷首始终显 / 卷尾仅 cleared 解锁 / placeholder 兜底)+ `chapter_list_screen` 章节卡「卷」入口(`Icons.auto_stories`,不撞现有 lock/check_circle 计数)。测 +7(loader 4 + 屏 3)。
- **C2 升阶大境界仪式** ✅:`AdvancementResult.crossedTier` getter(didAdvance && tierAfter≠tierBefore)+ `AdvancementSummary` 大境界走 `_TierUpRow`(military_tech 勋章 + 「大境界突破」badge,区别小层 `_LayerUpRow` auto_awesome)+ `retreat_result_screen._AdvancementBanner` 同步分支。测 +5(crossedTier 3 + summary 2)。
- **E2 effective 实战值可见** ✅:`equipment_detail_screen._StatRow` 显 `CharacterDerivedStats.effectiveEquipment{Attack,Hp,Speed}`(强化×共鸣×开锋乘法值)· effective≠base 时高亮 + 「(基 N)」副标。测 +2。
- **S3 死字段清理** ✅:`cultivation_progress_pct` 全 lib/ 0 公式消费(verify 实测)→ numbers.yaml 注释加重「未生效·Phase 5+」+ lineage_panel 移除误导性「+3% 修炼度」buff 行(避免向玩家展示不生效 buff;UiString 保留待 Phase 5+ 接公式恢复)。
- **R2 共鸣晋升反馈** ✅ **verified 已实装**:mainline + tower victory dialog 都已显 `ResonanceUpgradeBanner`(P1.1 候选 3-a · 装备名+共鸣晋阶+icon+label)+ GameEvent feed 条目。audit agent 自标「需确认 caller」的 R2 是误判 → **不加冗余 toast**。

## 决策 / deviation

- **C1 接入点选 chapter_list 卡「卷」入口,不动战斗 victory 流**:Boss 通关自动触发的一次性翻篇仪式需 seen-flag 持久化(scope 外)→ 本批做"可达 + 可重入阅读",仪式自动触发留后续(候选)。
- **E2 只做 effective 可见,delta-vs-已装备 defer**:「换装对比 delta」需 owner character → equipped{Slot}Id → Isar async load 同槽件的 plumbing(无现成 provider)→ 留候选。effective 可见已解 audit 主诉「裸 base 不反映实战值,玩家无从知真实战力」。
- **R2 不动**:已实装,don't build what exists。

## 残留 / 后续候选(用户拍)

- C1 Boss victory 自动翻篇仪式(seen-flag 持久化)
- E2 换装 delta vs 已装备(equipped-item provider plumbing)
- R2 共鸣度首次 tutorial 引导(onboarding step,属 G2 类)
- **中套餐(根因A 挂机循环重平衡)**:idle 喂共鸣度/修炼度 + 闭关 EXP 重平衡 + insightPoints/learnPoints 消费 sink · 需数值决策 + balance_simulator 验证 · 建议单独批先定方向

## 文件

13 改 + 2 新(`chapter_transition_screen.dart` + 其测)· lib 8 / data 1 / test 5(含 1 新)
