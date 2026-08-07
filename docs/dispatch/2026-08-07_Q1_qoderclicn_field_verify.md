# 试跑单 Q1 · PI1 疑似未消费字段深核(qoderclicn 首单·2026-08-07)

## 背景与基线
- 仓库:/Users/a10506/Desktop/Projects/挂机武侠;工作树(已建):`.claude/worktrees/qoder-verify`,分支 `qoder/trial-field-verify`
- 上游:`docs/dispatch/reports/2026-08-07_PI1_yaml_consumption.md` 列出 25 个「lib/ grep 零命中疑似未消费」yaml 字段——grep 有假阴(动态 key/字符串拼接/fromYaml 泛读可绕过字面量匹配)
- **本单性质:只读深核+写报告,零代码改动**(硬边界)

## 任务
对 25 个疑似字段逐个深核:在 lib/ 中寻找**非字面量消费证据**(动态 key 拼接/循环遍历 map key/泛型 fromYaml 整段读入后按 key 取/仅测试消费等),或确认真未消费。
产出 `REPORT_Q1.md`(worktree 根):逐字段判定表——字段/所在 yaml/判定(真未消费 | 假阴·附消费证据 file:line | 存疑·说明)/一句话依据。

## 验收
- REPORT_Q1.md 落盘,25 字段全覆盖,判定三态清晰,假阴项必须带 file:line 证据
- `git add REPORT_Q1.md && git commit -m "[READY] Q1 疑似字段深核报告"`;除报告外零文件改动(git status 干净)

## 禁区
不改任何代码/yaml;不跑 flutter;判定拿不准就标「存疑」,禁强行下结论。
