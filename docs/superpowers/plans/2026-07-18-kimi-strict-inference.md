# 恢复点 · 2026-07-18 · kimi strict-inference 启用（试点 B 单）

## 目标
`analysis_options.yaml` 的 `analyzer.language` 段加 `strict-inference: true`（与 `strict-casts: true` 并列同缩进），修掉全部新报 issue 后 flag 随批入库。

## 分支 / 工作区
- 分支：`kimi/strict-inference`
- worktree：`.worktrees/kimi-strict-inference`（独立目录，不碰主 checkout）

## 验收标准
a. flag 开启态 `flutter analyze --no-pub` = 0 issues
b. 全量 `flutter test --no-pub` 绿（基线 4417 pass / 0 fail，贴 EXIT=0 证据）
c. 31 行逐处修法清单（见下）

## 修法约束
只做显式化（泛型类型实参 / 显式参数类型 / 显式返回类型）；禁 `dynamic` / `as`；零行为变化。

## 任务切片
1. [x] 环境准备（worktree + pub get + build_runner + 基线 analyze 0）
2. [x] 开 flag 复现 31 issues
3. [ ] lib/ 10 处（MaterialPageRoute ×6 + tower_entry_flow 参数 ×4）
4. [ ] test/ 21 处
5. [ ] 批末全量 test + format 兜底 + commit

## 当前恢复点
- **状态**：进行中（31 issues 已复现，与 Claude 实测一致）
- **最后完成**：环境准备 + flag 开启 + 31 处清单确认
- **下一步**：逐处修复 lib/ 10 处
- **已跑验证**：基线 analyze 0 issues；开 flag 后 31 issues
- **阻塞项**：无

## 逐处修法清单（修复中陆续回填）

| # | 文件:行 | 报错类 | 修法 |
|---|---------|--------|------|
| （待回填） | | | |

## 待议项
- 暂无
