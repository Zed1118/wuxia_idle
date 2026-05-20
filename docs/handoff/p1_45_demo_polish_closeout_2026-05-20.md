# P1 #45 · Demo §8.4 polish nightshift closeout(2026-05-20)

> 2026-05-19 凌晨规划 + 2026-05-20 03:18-03:52 实跑(opus,34 min)+ 早上 cherry-pick + synergy fix 收尾。
> 9 commit 全 push origin/main(`598015a..9f6c649`)。flutter test **1123 pass + 1 skip + 0 fail** / analyze **0 issues**。

---

## §1 Nightshift 8 task 实战表

| Task | status | commit | 产出 | verify fail 真因 |
|---|---|---|---|---|
| T01 | ✅ completed | `1d0df4c` | 心法相生 +3 + 红线 test +3 | — |
| T02 | ⚠️ skipped(产出 OK)| `8e345eb` | encounters +9(领悟 +5/奇遇 +4)+ skills +5 + test 联结 | verify spec 路径写死(`encounters_loader_test.dart`),opus 改对的 `test/features/encounter/domain/` |
| T03 | ✅ completed | `3aba3fb` | techniques.yaml 21 处 description 占位填实 | — |
| T04 | ⚠️ skipped(产出 OK)| `cf6cb32` | 5 个 insights yaml 齐 | build_runner 静默失败 → analyze 误报 727 issues(memory `feedback_nightshift_build_runner_silent_fail`) |
| T05 | ⚠️ skipped(产出 OK)| `5bae60a` | 4 个 events yaml 齐 | verify count off-by-1(spec 数 46 vs 实测 45,memory `feedback_nightshift_verify_count_baseline`) |
| T06 | ⚠️ skipped(产出 OK)| `3cfc052` | 4 个心法 narrative yaml 齐 | 同 T04 codegen bug |
| T07 | ✅ completed | `c3db590` | Phase 5+ 师徒升级 spec 54 行(主动 grep lib 行号) | — |
| T08 | ✅ completed(未合 main)| `71fc74f`(独立分支)| Demo §8.4 验收 + closeout 134 行 | — |

**实战发现**:**8/8 task 产出实际 OK**,4 个 verify fail 全是 verify 脚本自己的 bug。早上不依赖 status 直接看 commit + git diff stat 验证。

---

## §2 早上 cherry-pick + 修复经过

### Phase A · cherry-pick T01-T07 → main(0 conflict)

```bash
git cherry-pick nightshift/T01 ... nightshift/T07
```

7 个全 0 conflict 合 main。T08 closeout 不合(本 doc 覆盖)。

### Phase B · 全量 test 暴露 3 fail(回归 test 写死期望值)

1. `game_repository_test.dart:37/39/44` skillDefs 98→103 / encounter_skills 35→40 / synergies 5→7
2. `phase2_seed_service_test.dart:727` seedVisualCheckW18A1 5 角色 detectActive == yaml 全集(覆盖性红线)
3. `phase2_seed_service_test.dart:761` schoolPair*3 / sameSchool*1 / sameTier*1 期望

### Phase C · T01 设计 bug 发现 + 回退方案

**根因**:T01 +3 反向 schoolPair(synergy 6 刚阴互制 / 7 灵刚汇流 / 8 灵阴归一)让 6 schoolPair 全覆盖 main/assist 方向后,**sameTier 红线无独立触发空间**(E·同辈 lingQiao+yinRou 被 synergy 8 灵阴归一 schoolPair 抢走)。

**回退方案**(commit `93bf94b`):
- 删 synergy 8(灵阴归一),yaml 5→7(GDD §4.5 5-8 范围仍满足)
- 扩 fixture seedVisualCheckW18A1 5→7 角色(加 F·刚阴 + G·灵刚 对应 synergy 6/7)
- 扩 `lineageTabLabels` 5→7 槽
- 同步 magic numbers(skillDefs 98→103 / encounter_skills 35→40 / synergies 5→7 / schoolPair 3→5)

### Phase D · nightshift infra commit(`9f6c649`)

- dispatcher.sh 改 opus + bug 修
- VERIFY_TEMPLATE.sh 新写(下次 nightshift 必套,修补 4 历史 bug)
- TASKS.md / README.md / handoff doc 更新
- 旧 T09/T10 spec 删

### Phase E · push origin/main

`598015a..9f6c649` 9 commit 全 push,worktree clean。

---

## §3 Demo §8.4 14 项最终对账

| 项目 | GDD 目标 | baseline | 当前 | 达成 |
|---|---|---|---|---|
| 主线关卡 | 15-20 | 15 | 15 | ✅ |
| 章节剧情 | 3 | 3 | 3 | ✅ |
| 爬塔层数 | 30 | 30 | 30 | ✅ |
| 闭关地图 | 5 | 5 | 5 | ✅ |
| 武学领悟触发 | 20-30 | 20 | **25** | ✅ 中位 |
| 基础奇遇 | 15-25 | 17 | **21** | ✅ 中位 |
| 节日 encounter | 6-10 | 8 | 8 | ✅ |
| 装备 | 30-50 | 35 | 35 | ✅ |
| 心法 | 20-30 | 21 | 21 | ✅ |
| 武学领悟招式 | 30-50 | 36 | **41** | ✅ 中位 |
| **心法相生组合** | **5-8** | **5** | **7**(T01 +3→+2 回退) | ✅ 中位 |
| 师徒角色 | 3 | 3 | 3 | ✅ |
| 典故文案 | 50-80 段 | 360 条 | 360 | ✅ 远超 |
| 主线剧情字数 | 3K-7K | ~6.8K | ~6.8K | ✅ |

**14/14 全达标 ✅**,1.0 路线图加权从 ~22% → **~25%**(Demo polish ✅)。

---

## §4 4 个 memory 新沉淀

| memory | 核心 |
|---|---|
| `feedback_nightshift_verify_count_baseline` | verify 不写死 count → baseline+delta 算式 |
| `feedback_nightshift_build_runner_silent_fail` | `>/dev/null 2>&1 \|\| echo WARN` 吞错误 → fail-fast + tee log |
| `feedback_opus_print_short_task_speed` | opus --print 短任务 3-8 min,不显著慢于 sonnet |
| `feedback_opus_audit_self_grep_lib` | opus 写 audit/spec 主动 grep lib 行号,优先 opus |

**未沉淀 1 项**(待 1.0 时点重启:synergy 8 重设计):**§4.5 触上限 8 需非 schoolPair 类型**(6 schoolPair 方向已全覆盖,sameTier 需空间。新设计候选:`sameTier` 高阶变体 / 新 `SynergyRequirementType.combo` 枚举 / 三流派同时持有的 rare buff)。

---

## §5 验证清单(最终)

- [x] flutter test 1123 pass + 1 skip + 0 fail
- [x] flutter analyze --fatal-warnings 0 issues
- [x] git status worktree clean
- [x] origin/main 同步(`598015a..9f6c649`)
- [x] PROGRESS.md 更新(本批,P1 #45 顶段 + 老段迁出归档)
- [x] memory MEMORY.md 71 行(≤ 200 cap)
- [x] nightshift VERIFY_TEMPLATE.sh 落地(下次 nightshift 用)

---

## §6 1.0 路线图状态

- **Demo §7 12/12 全 ✅** + **Demo §8.4 14/14 polish ✅**
- **P0 100% + P1 100% + Demo polish ✅** → **1.0 路线图加权 ~25%**
- 下一里程碑硬门槛:**美术 PoC + 水墨 LoRA**(M4,GDD §1 水墨克制基调落地)

---

## §7 下波候选

| # | 任务 | 模型 | 时长 | 备注 |
|---|---|---|---|---|
| 1 | 美术 PoC + 水墨 LoRA 调研 | opus xhigh + 用户主导 | 6-10h | **M4 硬门槛**,技术选型必先讨论(AI 出图工具链 SD/Flux/MJ + LoRA 训练数据 + Demo 35 装备首批出图节奏 + GDD §1 风格基调) |
| 2 | Phase 5+ 师徒系统升级实装 | opus xhigh | 8-12 工日 | T07 已起草 spec(`docs/handoff/phase5_master_disciple_spec_2026-05-20.md`),实装顺序建议 §3 飞升 → §5 遗物 → §4 祖师爷 buff |
| 3 | 心法相生 §4.5 触上限 8 重设计 | sonnet 起手 Phase 0 + opus 实装 | 1-2h | yaml 7 现状(2 schoolPair 类型剩余空间 = 0),需新 SynergyRequirementType 枚举值或 sameTier 高阶变体 |
| 4 | 章节扩展(Ch4+)/ 闭关地图扩 | TBD | TBD | 1.0 路线图远期,Demo 完工后再开 |

**默认建议候选 1**(M4 硬门槛,需用户主导技术选型讨论)。
