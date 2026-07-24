# Ch15「关山一程」实装批 plan

**日期**:2026-07-24 · **分支**:ch15-impl(worktree)· **模式**:Claude coupled xhigh 单会话整章
**依据**:docs/spec/2026-07-23-ch15-guanshan-yicheng-design.md(已冻结·八项拍板)

## 目标
绝顶段收官章整章实装:5 关 + 真解孤城闭(skill 计数 253→254)+ 13 叙事 + cap 33→35 + ~26 站点 reconcile。

## 验收标准
- analyze 0;批末全量 `flutter test --no-pub` 全绿(`> file 2>&1; echo EXIT=$?` 显式取码)
- 红线:末 Boss 59500<60000 / mult 4800≤8000 / 敌攻≤1850 / 三系锁死 / 15_01 无 prevStageId / chargeSkillId 配 onEnterMechanic: chargeCounter 成对 / 章中 Boss(15_04)stat 门槛无 bossPhases
- 破坏证红(孤城闭 mult 9000>8000 RED→还原绿)在 **commit 后**做(守 feedback_break_red_after_commit)
- progression/idle_horizon/material 逐值实测禁猜;playtest CSV byte-lock `UPDATE_PROGRESSION_PLAYTEST_EVIDENCE=1` 重生
- 叙事黑名单/现代词/网文腔 grep 0

## 切片
1. 内容层:numbers cap / skills 孤城闭 / stages 5 关 / narratives 13 篇 / known_missing +11
2. 生产可见性:chapter_list / strings(Title·Hint·两 switch·mainMenuHint·RouteMapSubtitle)/ main_menu ×2 / status_summary
3. GDD:章表 +15 行 / §8.1 段落 / 招式池 253→254(两字串)
4. 测试 reconcile:count 75 / boss 敌 32 / catalog 45(主线 39)/ skill 254×3 / tempo 终章 15_05 / budget 逐值 / idle_horizon(名 stale 顺修)/ material / narrative_completeness / CSV 重生
5. 验证:analyze → targeted → 批末全量 → commit → 破坏证红 → push → draft PR

## 恢复点
- 状态:切片 1 进行中(Phase-0 已完:站点行号全为本会话实测复定,spec 引用的 3 个测试文件路径已修正——skill_qi_redline/wave_b 在 test/data/、release_budget 在 test/features/cultivation/application/)
- **spec 偏差记录**:§复用策略称 6 件 zhongQi 装备「Ch14 未投放」,实读 stages.yaml Ch14 01-03 关已全部投放(spec 盘点漂移);「Ch15 主用这 6 件」拍板本身照单执行(与 Ch14 04/05 的 Boss 件错开),PR 注明
- 叙事 continuity 决策:Ch4 西行者是第二主线李寒,守关老将「当年放行的少年」写作不点名的往西剑客;回旋落在路的意象(渡口/古道/沙海/关城)与玩家既视感,不与李寒线结局强行衔接
