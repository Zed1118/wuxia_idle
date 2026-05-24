# P1.2 spec PR #6 待 4 项 minor fix handoff(2026-05-24)

> 主 cwd HEAD `02370b4` · worktree `/Users/a10506/Desktop/wuxia_idle-p12-spec` 保留 · 分支 `feat/p1_2_spec`
> 上游:overnight v3 reviewer 评 8/10 改后 merge · 详 `overnight_v3_4_of_5_merged_closeout_2026-05-24.md`
> spec doc:`docs/spec/p1_2_jianghu_enmity_spec_2026-05-24.md`(PR #6 加入 · 144 行)

## TL;DR

E PR #6 是 P1.2 江湖恩怨 + 声望 spec 草案(Q1-Q5 默认决议版)· reviewer 评 0 lib/test/data 实改 + 9 节体例 + 沿例引用具体行号合格 · 仅 4 项 spec doc 内容层 minor fix · 用户决策后改 spec + merge。

## 4 项 fix 清单

| # | 位置 | 当前 | 建议 fix | 严重度 |
|---|---|---|---|---|
| 1 | §3 yaml 数值 | `player_attack_power_mult: 1.15` 单一值 + clamp_max=1.25 但 trigger 无第 2 档 | 补 `severe_threshold: -80` + `severe_mult: 1.25`(否则 25% 永远触不到) | 中(数值不闭环) |
| 2 | §1 范围 OUT | 「心魔系统(P2.2 已闭)」 | 改「心魔系统(P3.2.C 销账)」(P2.2 是飞升前置 · 心魔在 P3.2.C) | 低(引用错) |
| 3 | §7 R5.6 | grep 校验作测试 | 改 Dart schema-level 断言(`Reputation.factionId` 类型 != `SectReputation.sectId` Collection/字段分离) | 中(测试方法不正确) |
| 4 | §2 schema | `Reputation.factionId` String 无 composite index | 加 `@Index(composite=[playerId, factionId])` 防同 faction 多行重复 | 中(Isar 体例对齐) |

## 起 fix 命令

```bash
cd /Users/a10506/Desktop/wuxia_idle-p12-spec
git pull --rebase origin main
# 编辑 docs/spec/p1_2_jianghu_enmity_spec_2026-05-24.md 4 项 fix
git add docs/spec/p1_2_jianghu_enmity_spec_2026-05-24.md
git commit -m "[spec] P1.2 reviewer 4 项 minor fix(数值阈值梯度 / OUT 引用 / R5.6 schema 断言 / composite index)"
git push origin feat/p1_2_spec
# PR #6 自动更新
gh pr ready 6 && gh pr merge 6 --squash --delete-branch
git worktree remove /Users/a10506/Desktop/wuxia_idle-p12-spec
git pull --rebase  # 主 cwd
```

## 替代选项

- **A 直接 fix + merge**(~15min · 沿 fix 命令)
- **B 留待 Q1-Q5 真拍板时一起改 spec**(用户起床改 Q1-Q5 决议 → spec 大改可能也涉及这 4 项 → 合批改)
- **C reject E PR 重新起 spec**(不推荐 · 默认决议版 8/10 质量已足 · 改 4 项 + Q1-Q5 决议改即可)

## 估时与不变量

- A 选项:~15min(纯 spec doc fix · 0 code)/ B 选项:Q1-Q5 拍板后 ~30min spec 整体改

- 0 GDD/numbers/data_schema/IDS 改 · 0 lib/test/data 实装 · spec ≤150 · Q1-Q5 决策权留用户
