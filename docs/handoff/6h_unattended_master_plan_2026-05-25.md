# 6h 挂机派单 master plan · 2026-05-25(pre-launch)

> launch 前用户在场制定 · 用户离开 6h 后回来看本 doc 知本批做了什么
> T22 跑完会产 `docs/handoff/6h_unattended_handoff_2026-05-25.md`(实际完工 doc)· 本 doc 是 pre-launch 计划

## TL;DR

主对话起 6 task nightshift opus --print 单 shot 串行批 · 6h 挂机离开
- launch 时间:2026-05-25 ~01:00 CST(本 doc 写完后)
- 预估结束:~05:00-06:00 CST(wall ~4-4.5h + cherry-pick overhead 1-1.5h)
- main HEAD launch base:`d6983d4`(本 doc 推 main 后 + 1)
- 6 worktree 路径:`/Users/a10506/Desktop/wuxia-idle-T1{7..22}/`

## 6 task 矩阵

| Task | 内容 | wall 估 | TIMEOUT | 关键产出 |
|---|---|---|---|---|
| **T17** | P1.2 §12.1+§12.2 江湖恩怨+声望 全 4 batch 一次过 | ~80-110min | 120min | Reputation/NpcRelation Isar + 12 UiStrings + R5 ~10 测 · 4 commit 单 worktree 累积 |
| **T18** | P3.3 PVP narrative 10 + P3.4 sect narrative 8 双补全 | ~25min | 120 | tournament 3 + mission 3 + crisis 2 + PVP 10 + R4 loader 双测 |
| **T19** | 技术债 3 清 | ~35min | 120 | PvpDef/SectEventDef 强类型 + sect Isar 持久化 + systemClockProvider |
| **T20** | 跨系统数值红线 audit | ~30min | 120 | audit doc + R5 6-10 测(0 lib 改动) |
| **T21** | P4.1 §12.2 帮派门派 Phase 0 + spec 起草 | ~40min | 120 | phase0 + spec ~150 行(Q1-Q8 默认决议 · 0 实装) |
| **T22** | 总收尾 | ~15min | 120 | stage_audit + ROADMAP v1.3 + 6h handoff + PROGRESS 顶段 |

**总 wall 估**:~4-4.5h · INTER_TASK_BUFFER_SEC=30s × 5 = 2.5min 间隔 · cherry-pick overhead ~1-1.5h(用户回来人工 review)= **~6h**

## launch 后用户回来该看的(顺序)

1. **`.nightshift/SUMMARY.md`**(morning.sh 自动生成 · 含 6 task 最终状态)
2. **`.nightshift/status/T1{7..22}.status`**(每 task started/finished/status/reason · wall 实测)
3. **`.nightshift/logs/dispatcher.log`**(主流程日志)
4. **`.nightshift/logs/T1{7..22}.log`**(每 task claude --print + verify 输出)
5. **`docs/handoff/6h_unattended_handoff_2026-05-25.md`**(T22 跑完产生 · 实际完工总结)
6. **`docs/handoff/stage_audit_1_0_overall_2026-05-25.md`**(T22 跑完产生 · 1.0 整体跳档审查)

## cherry-pick 顺序(用户人工 · ~1-1.5h)

每个 task 在自己 worktree commit · 未 push origin。用户回来后:

```bash
cd /Users/a10506/Desktop/挂机武侠

# 1. 看每个 task commit
for t in T17 T18 T19 T20 T21 T22; do
  echo "=== nightshift/$t ==="
  git log --oneline nightshift/$t ^main | head -5
done

# 2. cherry-pick(建议顺序 · 低撞优先)
git cherry-pick nightshift/T20    # audit 纯 doc · 无撞
git cherry-pick nightshift/T21    # P4.1 phase0+spec 纯 doc · 无撞
git cherry-pick nightshift/T18    # narrative 纯文案 · 无 lib 撞
git cherry-pick nightshift/T17    # P1.2 4 commit · numbers.yaml 末位可能撞 T19
git cherry-pick nightshift/T19    # 技术债 · numbers_config.dart 可能撞 T17 JianghuConfig
git cherry-pick nightshift/T22    # 总收尾 · ROADMAP/PROGRESS 撞 T17/T19 commit message hash

# 3. 撞 conflict 处理体例(memory feedback_local_doc_unpushed_remote_squash_diverge)
# numbers.yaml 末位撞 → 手工合 jianghu/pvp/sect_event 三段
# PROGRESS 撞 → keep T22 顶段(本批最终结果)
# ROADMAP 撞 → keep T22 v1.3 段(包含 T17/T19 状态对齐)

# 4. push
git push origin main

# 5. 清 worktree
for t in T17 T18 T19 T20 T21 T22; do
  git worktree remove /Users/a10506/Desktop/wuxia-idle-$t --force 2>/dev/null
  git branch -D nightshift/$t 2>/dev/null
done
```

## 风险预案(本批已沿用)

| 风险 | 预案 | 实战参考 |
|---|---|---|
| **R1 A1-A7 verify 假阳性** | C1 §6「失败但有产出」cherry-pick 救回 | `feedback_nightshift_v2_first_run_lessons` |
| **R2 P1.2 schema 失败连锁 service/UI/R5** | T17 单 worktree 累积 4 commit · idempotent claude-skip 自动跳 batch 失败 | T17 4 batch 在同一 task 内 |
| **R3 大 spec 触发 TIMEOUT** | TASK_TIMEOUT_MIN 75→120(T17 wall 估 80-110)| 本 conf 已升 |
| **R4 cherry-pick conflict 数高** | T20+T21+T18 纯 doc 无撞 / T17+T19+T22 三个有 numbers.yaml/PROGRESS/ROADMAP 撞 ~5-10min/cycle | memory `feedback_local_doc_unpushed_remote_squash_diverge` |
| **R5 数值红线被破** | T17 + T20 都有 R5 测族守 § 5.4 | T20 audit 兜底 |

## 用户离开期间自主决策权限(用户拍板「完全自主」)

- 不发问 · 不停下 · 单 shot 不交互(nightshift opus --print 模型本身就不能交互)
- cherry-pick conflict 留用户回来 review(主对话本 doc 已沟通)
- fail_verify 留 morning.sh 自动汇报(SUMMARY.md)+ 用户回来手工 cherry-pick

## 不变量沿用(全 6 task 都守)

- §5.4 数值红线:普伤 ≤8000 / 玩家血 ≤20000 / 内力 ≤15000 / 装备攻击 ≤2000
- §5.3 三系七阶锁:reputation 7 阶等 xueTu..wuSheng · 不开新阶
- §5.5 在线=离线:reputation 仅靠 trigger 累积 · 0 后台时钟
- §5.1 反留存:0 每日声望任务
- §6 公式:DamageCalculator 0 改 · BattleStrategy 接口不动
- doc 体量:closeout ≤80 / handoff ≤50 / audit ≤60 / spec ≤150 / PROGRESS ≤100

---

**预计 launch**:本 doc 推 main 后立即 `bash .nightshift/launch.sh` 后台启动 · run_in_background=true。用户可随时 `cat .nightshift/SUMMARY.md` 或 `tail -f .nightshift/logs/dispatcher.log` 看进度。
