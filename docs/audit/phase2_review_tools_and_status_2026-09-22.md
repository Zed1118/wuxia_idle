# 全面审查工具修复与状态同步

2026-09-22，统一分支 `codex/review-followthrough-20260922`，本批父提交 `75dfb21d0`。本批收口审查 R6、登记簿漏读、coverage 旧门槛和当前状态入口；不修改游戏规则、数值、存档或已生效决策。最终 SHA、原始命令与结果在 `/Users/a10506/Documents/Codex/2026-09-22/wuxia-review-followthrough/` 的恢复点及交付收据。

## 工具行为与回归

死链扫描原来为每条引用补 `/`，遇已构建 macOS Framework 符号链接会使整批 `git check-ignore` 退出128；链接子路径本身也会报错。现仅在 Git 查询边界把 probe 截到首个符号链接自身，不跟随 referent，再将命中映射回完整引用。普通目录的尾斜杠探查保留；Git 非0/1仍抛错，tracked/ignored/dead/archival判定规则未改。

新增6条真实Git回归先在旧源码得到5个symlink错误、1个控制例通过，退出1；修复后解析26例、真Git27例全部通过。覆盖无build/普通build/Framework link相同分类、未跟踪/断链接、已跟踪链接自身与子路径、中文回映射、日期归档与非Git错误。原47条测试保留。真实仓库扫描自然退出0，活文档dead=0；数量仅为本次源码快照，不声称任意历史工作树分类必然相同。

登记簿脚本只从顶层读取集成提交，漏掉Ch8直接evidence中的 `integration_content_commit` 与 `integration_governance_commit`。现显式承认直接evidence下这两个字段及 `integration_commit` / `integration_commits`，与原顶层字段合并；全部可解析并为目标祖先才通过该证据分支。非法引用保留字段路径，不先过滤非法项；任意base、implementation、CI SHA和深层嵌套不升级为完成证据。已有完成端点、主题、patch-id和correction优先级不变。

登记簿新增24项独立临时Git回归：旧源码8失败、0error、退出1；修复后24通过、退出0。真实登记簿从166已集成/1未判定变为167已集成/0未判定，分类变化仅Ch8；两项集成提交均是统一候选祖先。这不是167个新完成任务，也不代替Gate、CI或真人签认。

复跑入口：

```sh
python3 -B tools/test_doc_link_scan.py
python3 -B tools/test_doc_link_scan_gitfixture.py
python3 -B tools/audit/test_task_registry_triage.py
python3 -B tools/doc_link_scan.py --json
python3 -B tools/audit/task_registry_triage.py --target HEAD
```

本地工具仍按既有定位不进CI；没有新增另一套流水线。原始RED/GREEN、补丁及真实仓库结果分别在外部 `r6-prep`、`registry-prep`、`tool-final`。

## Coverage门槛

两次当前成功CI采用相同Flutter 3.41.5、workflow与LCOV解析规则：生成文件排除，同一源文件/行取最高hits、不重复计数。

| 成功CI / SHA | 已覆盖/有效行 | 覆盖率 |
|---|---:|---:|
| [35679748700](https://github.com/Zed1118/wuxia_idle/actions/runs/35679748700) / `81c2f06c8` | 50904/58494 | 87.0243% |
| [35681867388](https://github.com/Zed1118/wuxia_idle/actions/runs/35681867388) / `02994529f` | 51060/58611 | 87.1168% |

取较低样本向下落到0.05个百分点，再保留原有0.05个百分点容差，将旧门槛81.25%提高到86.95%。未改变分母或排除规则，不以测试数量替代覆盖率。当前统一候选须独立通过最终完整coverage回归；失败套件产生的LCOV仅作诊断。数据和公式见外部 `coverage-review/assessment.json`。

`2db7e263f` 的统一回归发现CI契约测试仍硬编码旧采样日期。确认失败后于135秒主动中断该轮，保留原始日志；其退出0没有done事件且存在失败和中断清理错误，不能作为完整PASS。随后将日期断言迁至09-22，并新增86.95精确门槛断言，原类型/正数守卫保留。最终以修正后的新SHA自然完成回归为准。

## 状态入口

PROGRESS压缩为当前候选、证据、前三阻塞与恢复入口；旧长篇状态由git和原audit追溯。NEXT去除已过时的只读契约、硬编码模型、等待5A、落后20提交与8分钟杀测试指令，恢复时按当前请求与CLAUDE核权。BACKLOG更新M4实测边界并登记R5语义待选。

registry将09-05 M2数据保留为历史快照，补09-22两条新档诊断与双视口工程smoke；M4旧24实体技术数字明确标注历史，补29d2塔6轮原始通过/3轮静默合格及28格未采。M0生产时间轴/真气接线已进入统一候选，不能继续写“uncommitted”。20项数值方向不重投票；心魔逐身份签认仍缺。

正式M0–M9仍1/10，仅M1，主WIP为M2；工程塔49/49不关闭正式M7，不解锁M8/M9。29d2的原生包、人工单和性能采样不覆盖本轮新候选。主目录四个用户文件、真实存档保持保护，未合main、push或发布。
