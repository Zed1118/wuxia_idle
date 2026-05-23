# Worktree B · memory sink 用户审稿前置加工 + GDD §10 教程审计

> 分支:`audit/memory_sink_gdd10` · 路径:`../wuxia_idle-mem-sink` · 模型:**sonnet** · 估时:~1h
> 上游:`docs/handoff/memory_sink_candidates_2026-05-24.md`(上波 candidates 60 行 · 用户尚未审稿)
> 体例锚:VulnFix P0 修补后「memory 必经用户审稿」纪律(8h v2 越权回滚教训)

## 0. 起会话第一动作

```bash
cd ../wuxia_idle-mem-sink
git pull --rebase origin main
cat docs/spec/overnight_v3_2026-05-24/B_memory_sink_gdd10.md
```

读完 spec 后:
1. 读 `docs/handoff/memory_sink_candidates_2026-05-24.md`(上波 3 候选 · 60 行)
2. 读 `~/.claude/projects/-Users-a10506/memory/MEMORY.md`(看现有 feedback_8h_autonomous_workflow_template / feedback_doc_inflation_overnight 是否过载)
3. 读 GDD.md §10 「新手引导节奏」(教程类规则当前状态)
4. 读 CLAUDE.md §5.7 「让玩家先感受问题,再给答案」(教程 anti-pattern)

## 1. 任务范围(2 个独立子任务)

### 子任务 B.1 · memory sink 用户审稿前置加工(~30min)

**核心 deliverable**:
- 把上波 `memory_sink_candidates_2026-05-24.md` 3 候选**重排为可直接 Edit 的 ready-to-paste 块**(用户起床看到不用自己改格式):
  - 每候选先列「目标 memory 文件路径」+「Edit 操作类型(append / insert before / replace)」
  - 然后列「old_string」(若 replace / insert before 操作)+「new_string」(完整可贴块)
  - 末尾列「应用后 memory 文件行数预测」(用户判断是否过载)
- **审计候选 3 (新建 memory `feedback_user_offline_indicates_session_boundary_not_session_count`)** 与现有 `feedback_clear_session_timing` + `feedback_user_offline_autonomous` 重叠度:
  - 若 ≥60% 重叠 → 建议合并到现有 memory(给 merge 方案)而非新建
  - 若 <60% 重叠 → 保留新建建议
- 输出新 doc `docs/handoff/memory_sink_ready_to_paste_2026-05-24.md`(≤80 行 · 替代上波 candidates)
- 旧 candidates doc 加头注「已被 ready_to_paste 取代 · 留存」或 `git rm`(自主决策)

**OUT(不做)**:
- ❌ 直接 Edit memory 文件(VulnFix P0 红线 · 必须用户审稿)
- ❌ 新增 sink 候选(上波 3 候选范围内加工 · 不扩)

### 子任务 B.2 · GDD §10 教程审计(~30min)

**核心 deliverable**:
- 读 GDD.md §10「新手引导节奏」段落 + CLAUDE.md §5.7「让玩家先感受问题」原则
- grep 全仓 lib/ 找当前 tutorial / hint / guide 实装:
  ```
  grep -rEi "tutorial|tooltip|onboarding|guide_step|hint_overlay" lib/ data/ --include='*.dart' --include='*.yaml'
  ```
- 评估 3 维:
  1. **GDD §10 节奏对齐**:当前实装匹配 §10 哪些节点?哪些节点未实装?
  2. **§5.7 原则违规**:是否有教程弹窗 / 教学说明替代「玩家先感受」?
  3. **菜单灰掉/隐藏机制**:未解锁系统按钮是否真灰 / 真隐藏?
- 输出 audit doc `docs/handoff/gdd_section10_tutorial_audit_2026-05-24.md`(≤60 行)
- 列「健康项 ✅」/ 「违规项 ⚠」 / 「未实装但 §10 要求 ❌」三段
- **不修代码**(audit only · 修留用户拍板)

**OUT(不做)**:
- ❌ 改 tutorial / hint 任何 dart 文件
- ❌ 改 GDD.md §10(DeepSeek 领地红线 · 即便 DeepSeek 退役也留用户)
- ❌ 删 lib/ 任何 tutorial 类(audit only)

## 2. 自主决策清单

| 决策点 | 默认决议 |
|---|---|
| B.1 候选 3 重叠判定 | 阅读 `feedback_clear_session_timing.md` + `feedback_user_offline_autonomous.md` 全文后判 |
| B.1 旧 candidates doc 处理 | 加 deprecated 头注留存(不 git rm · 历史可追溯) |
| B.2 grep 关键词扩展 | 若初版 grep 0 hit · 扩 `教学` `引导` `首次` `第一次` 中文词 |
| B.2 违规判定严格度 | 沿 CLAUDE.md §5.7 字面理解 · 紧 ≥ 松 |

## 3. 估时与里程碑

| 里程碑 | 估时 | 产出 |
|---|---|---|
| M1 B.1 candidates 重读 + ready_to_paste 起草 | ~20min | doc 草稿 |
| M2 B.1 候选 3 重叠判定 + ready_to_paste 终稿 | ~10min | doc 完稿 |
| M3 B.2 GDD §10 + CLAUDE §5.7 阅读 + grep | ~10min | grep 输出 + 分类 |
| M4 B.2 audit doc 起草 + 完稿 | ~15min | audit doc |
| M5 push + 草稿 PR | ~5min | PR |

## 4. PR 体例

```bash
git add docs/handoff/memory_sink_ready_to_paste_2026-05-24.md
git add docs/handoff/gdd_section10_tutorial_audit_2026-05-24.md
git add docs/handoff/memory_sink_candidates_2026-05-24.md  # 若加 deprecated 头注
git commit -m "[audit] memory sink ready-to-paste + GDD §10 教程审计"
git push -u origin audit/memory_sink_gdd10
gh pr create --draft --title "[audit] memory sink 前置加工 + GDD §10 教程审计" --body "$(cat <<'EOF'
## 概要
B.1 上波 memory sink candidates 重排为 ready-to-paste 块(用户起床直接 Edit)
B.2 GDD §10 教程节奏 + CLAUDE §5.7 「玩家先感受」原则审计

## 改动
- `memory_sink_ready_to_paste_2026-05-24.md` (新)
- `gdd_section10_tutorial_audit_2026-05-24.md` (新)
- `memory_sink_candidates_2026-05-24.md` (加 deprecated 头注)
- 0 code / 0 数值 / 0 schema 改

## 验证
- B.1 三候选格式可直接贴 Edit 工具
- B.2 grep 关键词全 ≥ 6 类 · 健康/违规/未实装 三段全列
EOF
)"
```

会话清理建议:**必须清理**(audit + sink 类双子任务闭环)
