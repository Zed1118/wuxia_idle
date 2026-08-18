# 一#18 死链扫描器重评:F 合入后新基线 + P6 式标注(2026-08-18)

> 分支 `audit/doclink-scanner-reeval-0818` · 基于 main `1d530af7`
> 性质=纯审计批(零代码改动):产出审计报告 + 拍板材料,不动扫描器/README 定位

## 背景

BACKLOG 一#18 重开原因:2026-08-12 升级拍板当日发现 `git ls-files`/`check-ignore`
对非 ASCII 文件名八进制转义,291 篇中文名文档漏出扫描源 → P6 旧结论
(precision 95.0%/recall 100%)建立在漏扫样本上,不外推。修复 F(`74d081cc`,
`-z` NUL 分隔)已合入。重拍前提=重跑新基线 + 重做 P6 式标注验证。

新基线已跑出(2026-08-18):scanned 1298 / refs 8344 / alive 6686 /
**dead 372** / ignored 693 / archival 593 / skipped 491。

## 验收标准

- [ ] 新基线落盘并与 08-12 隔离实测(1229/7911/366)、08-15 收口口径(278)差异归因
- [ ] 分层抽样 ~90 条(dead 40 / alive 40 / ignored 10,对齐 P6 构成;新增量
      重点覆盖中文名文档引用)逐条独立标注(`ls`/`git ls-files`/`git check-ignore`
      现查,不拿扫描器输出当答案)
- [ ] 混淆矩阵 + precision/recall + 每个 FP/FN 逐条根因
- [ ] 附带:一#20 (b) 案模拟测算——sessions/dispatch/superpowers/audit 纳入
      归档类后 dead 剩多少(数据供用户拍板,本批不做政策变更)
- [ ] 报告 `docs/dispatch/reports/2026-08-18_doclink_scanner_reeval.md`(与 P6
      同口径放排除区,报告引用死链示例不自指) · PROGRESS 登记 ·
      BACKLOG 一#18 更新为「重评已做,带数据待拍」状态
- [ ] CI 守恒:零代码改动,flutter test 计数 5160 不变

## 任务切片

1. RP0:建分支 + 本计划档
2. 基线差异分析:372 vs 366 vs 278 口径归因(增量文档/修复批/分类迁移)
3. 抽样与标注:种子可复现;标注脚本只做机械查询,判定由人(本会话)逐条确认
4. 指标与根因:混淆矩阵;FP/FN 逐条写根因
5. (b) 案模拟:只测算不改 `ARCHIVAL_DIRS`
6. 报告 + commit + 合入收账 + 呈报拍板(#18 升级与否 / #20 三选项)

## 红线

- 不改 `tools/doc_link_scan.py`、不改 `tools/README.md` 定位行(拍板权在用户)
- 不修任何死链;不动 `lib/`/`.dart`;commit 中文动宾

## 当前恢复点

- **状态**:RP0,计划档冻结中
- **最后完成**:分支已建,新基线已跑(1298/8344/6686/372/693/593)
- **下一步**:基线差异归因 → 抽样标注
- **阻塞项**:无
