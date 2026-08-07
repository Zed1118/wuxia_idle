# 新会话开局清单(挂机任务流·大规模多端测试)

> 交接:2026-08-07 16:00 · main HEAD `99003436` · 与 origin 同步 · 全量 4886/0 · CI 绿(run 31155725413)

## 【本会话契约】(置顶最高优先级)

- **模式:挂机任务流执行会话——Claude=审核员**:规划提案/派单/预 Gate 复跑/收账终审,其余全部下放执行端,不亲手写码
- **Fable 周池 67%⚠(周三 3:00 重置)**:Claude 侧极省 token——回复精简、重活全下放、非关键轮次可考虑切 Opus 缓压
- 开工先等用户报**挂机时长**,再出正式提案等拍板;进度条每条消息带(格式=全局 CLAUDE.md「任务进度条」定版)

## 【开局动作】

1. 读桌面《自动化AI工作方案.md》(六端矩阵/派发路由/用量 SOP/锚表,v1.2)
2. 调用 /afk skill 按其 Phase 0 起执行
3. 基线核对:git status 干净+与 origin 同步;`git worktree list` 应只余主 checkout(试跑批 4 个 worktree 已可清:pi-yaml-audit/kimi-p1-overview/qoder-verify/cb-linkscan 均已合并,清理三验后 remove)
4. 六端探活(命令详 memory `reference_cli_dispatch_pipeline` 末段 SOP):CLI 探针+pi 余额 API+**三家后台 playwright 抓(登录态跨会话持久性首验,失效请用户重登一次)**
5. 选读 memory:`reference_cli_dispatch_pipeline`(六端命令+用量 SOP+校准)/`feedback_night_batch_dispatch_protocol`(修订段)

## 【环境快照】(2026-08-07 16:00 实测,改动后必重测禁转抄)

- main `99003436`;全量 4886/0;analyze 0;CI 绿
- 六端全 idle;用量:claude 5h~12%(校准)·周Fable 67%⚠ / kimi 5h4.09%·月52.77% / pi ¥16.34 / qoderclicn 1/2000 / codebuddy 0/500+赠包10.55/100 / codex 独立
- 速度锚:kimi 11-32min/单 · pi 4min/全仓扫描 · qoderclicn 7min/深核 · codebuddy 14.5min/全仓扫 · codex ~10min/图
- 滚动池 `docs/dispatch/pool/`:剩 P2(真机录屏准备)/P3(checklist reconcile)

## 【大规模测试候选池】(出提案的加工素材)

| 单 | 端 | 量 | 依据 |
|---|---|---|---|
| C2 桃花岛正式场景美术(岛景背景+7 建筑热区立绘) | codex | 大 | §十挂账,代码骨架已合 main 只换皮;image_gen 管线成熟 |
| L1 死链修复分片批(1092 处按目录分片并行) | pi+codebuddy | 大 | 底账 `docs/dispatch/reports/2026-08-07_B1_doc_links.md`;纯 docs 低风险 |
| K2 kimi 超排目标序列(假绿抽查扩面+E 组小项+extension 附录 A 复核等 6-8 目标) | kimi | 中大 | 超排 ≥2× 原则 |
| N1 numbers.yaml 16 疑似字段处置 | qoderclicn 出 patch 报告→**Claude 终审收口**(numbers.yaml 红线) | 中 | Q1 深核判定在 `reports/2026-08-07_Q1_field_verify.md` |
| R1 真机录屏塔 42 协同演出(第八阶段关账) | Claude 真机位 | 小 | 已授权「下个夜批实跑」;每晚真机位限 1 |
| 推荐组合 | 8h 档全上;3-4h 档 C2+L1+K2 | | 派单前按 /afk 做预拍板节 |

## 【硬约束沿用】

- 双验证放行制/超排 ≥2×/滚动池自动续派/CI watch 不过夜/首件抽检/挂死 40min 轻巡——全在 /afk
- 数值/schema/红线(numbers.yaml/GDD/strings)执行端禁区,Claude 终审收口;真机位每晚 1;flutter test 并发 ≤2
- 验证数字一律 Claude 本会话复跑;证据图落 build/ 不进 git;执行端报告归位 docs/dispatch/reports/
- perl 改 md 表格用 s#...# 分隔符;中文标点 pattern 必 grep 验证命中(同日两坑,详 `feedback_chinese_path_shell_pitfalls` 尾段)

## 【先报告】(不动手)

1. 防装读:引用《自动化AI工作方案.md》「三、短板」第 1 条原文 + `reference_cli_dispatch_pipeline` 用量 SOP 表 codebuddy 行关键字段原文
2. 报六端探活结果(含三家后台登录态验证)+ 基线核对 + worktree 清理结果
3. 等用户报时长 → 出正式提案(候选池加工+超排排量+预拍板节)→ 等拍板

## 【收尾】

会话结束前沿本体例覆写 NEXT.md + PROGRESS 收账条 + 方案文档版本递增。
