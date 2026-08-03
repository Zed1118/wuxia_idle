# 交接类归档目录

此目录存放**跨 session 的交接类归档**（464 份，2026-07 至今仍在增长）：

- 夜批 / 挂机批收账：`night_batch_closeout_*.md`、`afk_batch_closeout_*.md`
- 派单包与派单收账：`*_dispatch_prompt_*.txt`、`kimi_*_closeout_*.md`
- 美术交付与验收报告：`ch*_art_delivery_report_*.md`、`*-final-verification.md`

> **注意**：`/handoff` 命令生成的 session 记录**不落在这里**，而是写入 `docs/sessions/`：
>
> - session 记录：`docs/sessions/YYYY-MM-DD_HHMM_<主题>.md`
> - 新会话开局清单：`docs/sessions/NEXT.md`（覆盖式，新会话打「开工」即读它）
>
> 本目录无统一命名规则，按批次/用途自命名即可。

## 使用方式

在 Claude Code 中输入 `/handoff` 触发 session 交接。命令的 canonical 定义在 `~/.claude/skills/handoff/SKILL.md`。

> `/handoff-light` 已于 2026-08-03 删除（全项目 415 次交接中 0 次实际使用，功能与 `/handoff` 重叠）。
