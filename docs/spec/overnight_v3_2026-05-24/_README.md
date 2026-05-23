# 8h overnight v3 派单总览(2026-05-24 凌晨第二波)

> 派单方:Mac Opus 4.7(主 cwd · 多 worktree 模式 v3)
> 主 cwd HEAD `<本 commit>` · 5 worktree 独立分支 · 每 worktree 完成 → push → 草稿 PR
> 起床体例:`gh pr list --author @me --draft` → 串行审 → squash merge → `git worktree remove`

## 5 worktree 派单表

| # | 分支 | worktree 路径 | spec | 模型 | 估时 |
|---|---|---|---|---|---|
| A | `fix/ch4_5_yiliu_words` | `../wuxia_idle-ch45-yiliu` | `A_ch4_5_yiliu_words.md` | sonnet | ~2h |
| B | `audit/memory_sink_gdd10` | `../wuxia_idle-mem-sink` | `B_memory_sink_gdd10.md` | sonnet | ~1h |
| C | `phase0/p3_3_pvp` | `../wuxia_idle-pvp-p0` | `C_p3_3_pvp_phase0.md` | opus high | ~1.5h |
| D | `phase0/p3_4_sect_event` | `../wuxia_idle-sect-p0` | `D_p3_4_sect_event_phase0.md` | opus high | ~1.5h |
| E | `feat/p1_2_spec` | `../wuxia_idle-p12-spec` | `E_p1_2_jianghu_spec.md` | opus xhigh | ~2h |

## 全局硬约束(5 worktree 沿用)

1. **不动 main · 不动其他 worktree** — 各干各的
2. **不动 GDD.md / CLAUDE.md / numbers.yaml / data_schema.md / IDS_REGISTRY.md**(DeepSeek 领地标的红线 · 即便 DeepSeek 已退役,这 5 文件仍按 P5+ 主轴前置留用户拍板)
3. **不上需要主轴拍板的实装** — Phase 0 / spec / audit / 文案补漏类 OK,新模块代码实装 NO
4. **doc 体量上限** — closeout ≤80 / handoff ≤50 / audit ≤60 / phase0 ≤80 / spec ≤150 行
5. **commit message 体例** — `[<type>] <subsystem> · <summary>` 中文动宾(`[fix]` / `[audit]` / `[phase0]` / `[spec]` / `[chore]`)
6. **memory sink** — 用 audit doc 候选体例(`docs/handoff/memory_sink_candidates_*.md`),**绝不直接 Edit memory 文件**
7. **完成动作** — 全 task 完毕后:
   - `flutter test`(如有 code 改)/ `flutter analyze --fatal-warnings`
   - `git add -A && git commit -m "<message>"`
   - `git push -u origin <branch>`
   - `gh pr create --draft --title "<title>" --body-file <path>` 或简短 inline body
   - 末尾 1 行**会话清理建议**(`必须清理` 默认)
8. **失败兜底** — 任何 task 卡住 ≥30min 未解 / 测试反复 fail → **stop · 别强推** · push 当前进度 + PR body 写「卡点 X · 留用户审」标 `[WIP]` title

## 起床检查清单(用户)

```bash
cd /Users/a10506/Desktop/挂机武侠
git fetch origin
git worktree list                # 看 5 worktree 状态
gh pr list --author @me --draft  # 看 5 草稿 PR
```

逐个审:
1. PR 内容 + diff 看一眼
2. 满意 → `gh pr ready <num>` → `gh pr merge <num> --squash --delete-branch`
3. `git worktree remove ../wuxia_idle-<name>`(分支已自动删)
4. `git pull --rebase`(主 cwd 拉合并后的 main)
