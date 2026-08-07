# 试跑单 PI1 · data/ yaml 配置字段消费情况扫描(pi 首单·2026-08-07)

## 背景与基线
- 仓库:/Users/a10506/Desktop/Projects/挂机武侠(Flutter macOS 游戏);工作树(已建):`.claude/worktrees/pi-yaml-audit`,分支 `pi/trial-yaml-audit`
- 动机:yaml 里配置了字段但 lib/ 代码从不消费=文档与行为脱节(本仓历史踩过此坑),需周期性扫描
- **本单性质:只读扫描+写报告,零代码改动**(这是硬边界)

## 任务
1. 遍历 `data/` 下所有 .yaml,提取顶层与二级配置字段名(嵌套 key 取到二级即可)
2. 对每个字段名在 `lib/` 下 grep 消费情况(计数+首个消费点 file:line)
3. 产出报告 `REPORT_PI1.md`(worktree 根):字段总数/已消费数/疑似未消费清单表(yaml 文件/字段/grep 命中数)
4. 疑似未消费的字段**只标「疑似」不下结论**——消费可能走动态 key/字符串拼接,grep 有假阴;报告头部写明此局限

## 验收
- REPORT_PI1.md 落盘,含:扫描范围统计/方法说明/疑似未消费表/局限声明
- git add REPORT_PI1.md && git commit -m "[READY] PI1 yaml 消费扫描报告"
- 除 REPORT_PI1.md 外零文件改动(git status 干净)

## 禁区
不改任何 yaml/dart/其他文件;不跑 flutter 命令;拿不准的存疑列出,禁下修改建议之外的结论。
