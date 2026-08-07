# 试跑单 B1 · docs/ 内部引用死链扫描(codebuddy 首单·2026-08-07)

## 背景与基线
- 仓库:/Users/a10506/Desktop/Projects/挂机武侠;工作树(已建):`.claude/worktrees/cb-linkscan`,分支 `cb/trial-doc-links`
- 动机:docs/ 大量 md 相互引用 repo 内路径(spec/handoff/audit 互链+代码路径引用),文件移动/删除后死链无人察觉
- **本单性质:只读扫描+写报告,零代码改动**(硬边界)

## 任务
1. 扫描 `docs/**/*.md`(排除 `docs/_archive/`)里的 repo 内相对路径引用:md 链接 `[..](路径)` 与正文反引号内的 `docs/...`、`lib/...`、`test/...`、`data/...` 形式路径
2. 对每个引用验证目标在 worktree 内是否存在(自解析 md 相对路径规则:相对于所在 md 文件目录或 repo 根,两种都试,任一命中算存活)
3. 产出 `REPORT_B1.md`(worktree 根):统计(扫描文件数/引用总数/死链数)+ 死链清单表(md 文件:行/引用原文/判定)+ 方法与局限声明(行号引用如 file:line 的 line 漂移不在本单范围,只验文件存在性)

## 验收
- REPORT_B1.md 落盘;`git add REPORT_B1.md && git commit -m "[READY] B1 docs 死链扫描报告"`;除报告外零改动(git status 干净)

## 禁区
不修死链(只报告);不动 _archive;不跑 flutter;误报可能高的形式(通配/模板路径)单独列「跳过类」说明,禁滥报。
