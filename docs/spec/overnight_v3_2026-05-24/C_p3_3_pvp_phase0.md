# Worktree C · P3.3 PVP Phase 0 6 维 reality check

> 分支:`phase0/p3_3_pvp` · 路径:`../wuxia_idle-pvp-p0` · 模型:**opus high** · 估时:~1.5h
> 上游:GDD.md §12.x(PVP 占位段)+ ROADMAP_1_0.md(P3.3 占位)+ memory `feedback_phase0_grep_two_axes`(Phase 0 6 维体例)
> 沿例:`docs/phase0/p1_2_jianghu_enmity_phase0_2026-05-24.md`(D 批 Phase 0 体例)

## 0. 起会话第一动作

```bash
cd ../wuxia_idle-pvp-p0
git pull --rebase origin main
cat docs/spec/overnight_v3_2026-05-24/C_p3_3_pvp_phase0.md
```

读完 spec 后:
1. 读 `docs/phase0/p1_2_jianghu_enmity_phase0_2026-05-24.md`(Phase 0 体例 · 42 行 · 全沿)
2. 读 memory `feedback_phase0_grep_two_axes`(6 维 grep 体例)
3. 读 GDD.md §12 全段(找 PVP 占位 + 红线)
4. 读 ROADMAP_1_0.md(找 P3.3 PVP 段)

## 1. 任务范围

**核心 deliverable**:
- Phase 0 6 维 grep 全跑(沿 P1.2 体例):
  - A schema(PvpMatch / Arena / Ranking / Ladder / PvpResult / OpponentSnapshot)
  - B caller(谁会调用 PVP)
  - C 邻近系统(BattleService / Supabase / Leaderboard 现状)
  - D UI widget(PvpScreen / ArenaScreen / RankingScreen 候选)
  - E 红线层(GDD §12 PVP 占位 + ROADMAP P3.3 段)
  - F 公式层(numbers.yaml pvp / ranking 段)
- 5 项 Q&A 候选清单(起床用户拍板 · **无推荐 · 主轴留用户**):
  - Q1 PVP 范围:A 真人对战 / B 异步快照战(同 P3.1.B 自动战) / C 跨周目排行榜对战 / D A+B 全包
  - Q2 阵容粒度:A 单人 1v1 / B 三人 3v3(沿 P3.2.A) / C 混合可选
  - Q3 段位/积分:A ELO / B 简化段位(段+星) / C 直接看 win rate
  - Q4 触发条件:A 主线 Ch5 cleared / B 武圣境界 unlocked / C wuSheng·dengFeng 双门槛
  - Q5 Supabase 后端:A 全异步 PvpMatch Collection / B 仅 LeaderRanking 表 + battle 本地跑 / C 全本地 mock + 1.1 上 server
- 输出 `docs/phase0/p3_3_pvp_phase0_2026-05-24.md`(沿 P1.2 phase0 doc 体例 · ≤80 行)
- 输出 GDD §12 升档草案段(在 phase0 doc 末尾 · 不直接改 GDD.md)

**OUT(不做)**:
- ❌ 实装任何 PVP code(0 Isar / 0 service / 0 UI)
- ❌ 拍板 Q1-Q5(留用户起床)
- ❌ 改 GDD.md / numbers.yaml(留用户审稿后改)
- ❌ Supabase schema 设计(留 spec 阶段)

## 2. Phase 0 6 维 grep 命令(参考)

```bash
# A schema
grep -rEi "class\s+(PvpMatch|Arena|Ranking|Ladder|PvpResult|OpponentSnapshot)" lib/ --include='*.dart'
# B caller
grep -rEi "PvpService|pvpService|enterPvp|matchOpponent" lib/ --include='*.dart'
# C 邻近(Supabase + leaderboard 现状)
grep -rEi "Supabase|leaderboard|ranking" lib/ data/ --include='*.dart' --include='*.yaml' | head -30
# D UI
grep -rEi "(Pvp|Arena|Ranking).*(Screen|Widget|Page)" lib/ --include='*.dart'
# E 红线层(GDD §12 + ROADMAP)
grep -nEi "pvp|对决|对战|排行" GDD.md ROADMAP_1_0.md
# F 公式层
grep -nEi "pvp|arena|ranking|elo" numbers.yaml
```

## 3. 自主决策清单

| 决策点 | 默认决议 |
|---|---|
| Q1-Q5 候选写法 | 沿 P1.2 phase0 Q1-Q5 体例 · 每 Q 3-5 候选 · 不推荐 |
| 6 维全 greenfield 判定 | grep 0 hit → ✅ greenfield · ≥1 hit 列具体文件:行号 |
| GDD §12.x 升档草案 | 沿 P1.2 「§12.4.X」体例 · 单段 5-8 行 · 列触发/红线/数据流 |
| 与 P3.1.B / P3.2 体例继承 | 战斗机制层全沿 BattleStrategy / damage_multiplier 已有 abstraction |

## 4. 估时与里程碑

| 里程碑 | 估时 | 产出 |
|---|---|---|
| M1 6 维 grep 全跑 | ~30min | grep 输出表 |
| M2 Q1-Q5 候选起草 | ~30min | Q&A 表 |
| M3 GDD §12.x 升档草案 | ~15min | 草案段 |
| M4 phase0 doc 完稿 + push + 草稿 PR | ~15min | doc ≤80 行 + PR |

## 5. PR 体例

```bash
git add docs/phase0/p3_3_pvp_phase0_2026-05-24.md
git commit -m "[phase0] P3.3 PVP · 6 维 reality check + Q1-Q5 候选 + GDD §12 升档草案"
git push -u origin phase0/p3_3_pvp
gh pr create --draft --title "[phase0] P3.3 PVP Phase 0 + Q&A 候选" --body "$(cat <<'EOF'
## 概要
P3.3 PVP Phase 0 6 维 reality check + Q1-Q5 主轴未拍板候选 + GDD §12.x 升档草案。**不实装**。

## 改动
- `docs/phase0/p3_3_pvp_phase0_2026-05-24.md` (新)
- 0 code / 0 schema / 0 数值 / 0 GDD 改

## 验证
- 6 维 grep 结论列具体 hit 文件:行号(或 ✅ greenfield)
- Q1-Q5 候选清单 ≥ 3 选项/Q · 无推荐
- GDD §12.x 升档草案沿 P1.2 体例
EOF
)"
```

会话清理建议:**必须清理**(Phase 0 单波闭环)
