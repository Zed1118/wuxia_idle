# Worktree A · Ch4-Ch5 yiLiu 4 风格词补漏

> 分支:`fix/ch4_5_yiliu_words` · 路径:`../wuxia_idle-ch45-yiliu` · 模型:**sonnet** · 估时:~2h
> 上游 audit:`docs/handoff/p5_x_narrative_tier_audit_2026-05-24.md`(Ch4-Ch5 yiLiu 4 词全 0 命中)
> 沿例:F.1 `ascension_lineage_chant.yaml` 4 词完美均匀 ⭐(湛然/寂照/圆融/化机 各 2 处)

## 0. 起会话第一动作

```bash
cd ../wuxia_idle-ch45-yiliu
git pull --rebase origin main    # 拿主 cwd push 的 spec
cat docs/spec/overnight_v3_2026-05-24/A_ch4_5_yiliu_words.md
```

读完 spec 后:
1. 读 `docs/handoff/p5_x_narrative_tier_audit_2026-05-24.md`(audit 完整结论)
2. 读 memory `project_wuxia_idle_ch4_cultural_arc`(Tier yiLiu 体例锚定)
3. 读 memory `feedback_collab_mode_single_lore_workflow`(Tier 风格梯度 7 阶 + 文案 3 Phase 工作流)
4. 读 `data/narratives/chapters/chapter_04.yaml` + `chapter_05.yaml` 全文判断质感
5. 读 `data/narratives/stages/stage_04_*.yaml` + `stage_05_*.yaml`(O 批 audit grep 范围,文件数自查)

## 1. 任务范围

**核心 deliverable**:
- Ch4 narrative(`chapter_04.yaml` + `stage_04_*.yaml` 全文件) `沉着 / 肃杀 / 老练 / 冷静` **各 ≥1 处自然嵌入**(总 ≥4 命中 · 命中分布尽量均匀)
- Ch5 narrative(`chapter_05.yaml` + `stage_05_*.yaml` 全文件) **同上 4 词各 ≥1 处**
- F.1 lineage_chant 体例:**意境融合**(像「岁月磨得湛然」「寂照之间」),不生硬塞词
- 完成后 grep 验证:`grep -E "沉着|肃杀|老练|冷静" data/narratives/chapters/chapter_0[4-5].yaml data/narratives/stages/stage_0[4-5]_*.yaml | wc -l ≥ 8`

**OUT(不做)**:
- ❌ Ch6 / 心魔 / 飞升 narrative(audit 已 ✅ 健康 · 不动)
- ❌ Ch5 末关跨阶 jueDing 4 风格词 sink(audit P3 优先级 · 留用户审稿决策 jueDing 4 词集)
- ❌ memory `project_wuxia_idle_ch4_cultural_arc` update(audit P2 优先级 · 用户决策本批是补 vs 改 memory)
- ❌ 改 stage 数值 / encounter / lore / events 文件
- ❌ 删除 / 替换原有近义词(「沉静」「平静」「冷峻」「肃然」)— 保留 + 加新词 = 增量补漏

## 2. 自主决策清单

| 决策点 | 默认决议 |
|---|---|
| 4 词嵌入位置选择 | 优先 narrative 战斗描写 + 心理刻画段;避开剧情转折硬塞 |
| 4 词命中分布均衡 | 目标 Ch4 各 ≥1 / Ch5 各 ≥1 · 实测可 2-3 · 不强求完美对称 |
| 文字工艺评判 | 沿 memory `feedback_user_offline_autonomous` 教训#1「每段写完读 1 遍判断质感」 |
| 命中验证 | 完成后 grep 命令实测 + 报告 wc -l 数 |

## 3. 估时与里程碑

| 里程碑 | 估时 | 产出 |
|---|---|---|
| M1 Ch4 全文阅读 + 4 词嵌入点定位 | ~30min | Read 13+ narrative 文件 · 选定 4 词嵌入段 |
| M2 Ch4 4 词嵌入 + 自审读 1 遍 | ~30min | Edit narrative · grep 实测 Ch4 ≥4 |
| M3 Ch5 全文阅读 + 4 词嵌入 + 自审读 1 遍 | ~50min | 同 M1+M2 · Ch5 ≥4 |
| M4 全仓 grep 验证 + closeout + push + 草稿 PR | ~10min | closeout ≤60 行 + PR |

## 4. closeout 模板(写完贴 `docs/handoff/A_ch4_5_yiliu_words_closeout_2026-05-24.md`)

```markdown
# Ch4-Ch5 yiLiu 4 风格词补漏 closeout(worktree A)
> 日期:2026-05-24 / 模型:sonnet / 实测 ~Xh
> 上游 audit:`p5_x_narrative_tier_audit_2026-05-24.md`

## 命中分布(完成后)
| 段 | 沉着 | 肃杀 | 老练 | 冷静 | 总 |
|---|---|---|---|---|---|
| Ch4 | X | X | X | X | X |
| Ch5 | X | X | X | X | X |

## 改动文件清单(Ch4 N 件 / Ch5 N 件)
- data/narratives/chapters/chapter_04.yaml: 段落 X 嵌「沉着」...
- ...

## 自审质感评分(1-5)
- Ch4 整体融合度:X / 5
- Ch5 整体融合度:X / 5
- (低于 4 分段落标记 + 写为何留)

## 不变量沿用
- 0 数值 / 0 schema / 0 code 改 · narrative 文学层 only · grep 实测 ≥ 8 命中
```

## 5. PR 体例

```bash
git add data/narratives/
git add docs/handoff/A_ch4_5_yiliu_words_closeout_2026-05-24.md
git commit -m "[fix] narrative · Ch4-Ch5 yiLiu 4 风格词补漏(沉着/肃杀/老练/冷静)"
git push -u origin fix/ch4_5_yiliu_words
gh pr create --draft --title "[fix] Ch4-Ch5 yiLiu 4 风格词补漏" --body "$(cat <<'EOF'
## 概要
上游 audit `p5_x_narrative_tier_audit_2026-05-24.md` 发现 Ch4-Ch5 yiLiu 4 风格词「沉着/肃杀/老练/冷静」全 0 命中。本 PR 在 Ch4 + Ch5 narrative 各嵌入 4 词 ≥1 处。

## 改动
- Ch4 narrative N 处嵌入(分布: 沉着 X / 肃杀 X / 老练 X / 冷静 X)
- Ch5 narrative N 处嵌入(同上)
- 0 数值 / 0 schema / 0 code 改

## 验证
- `grep -E "沉着|肃杀|老练|冷静" data/narratives/chapters/chapter_0[4-5].yaml data/narratives/stages/stage_0[4-5]_*.yaml | wc -l` ≥ 8
- 自审质感评分 Ch4 X/5 · Ch5 X/5

## closeout
`docs/handoff/A_ch4_5_yiliu_words_closeout_2026-05-24.md`
EOF
)"
```

会话清理建议:**必须清理**(子系统单波闭环)
