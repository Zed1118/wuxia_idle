# 滚动单池(跨夜不清空,水位 ≥3;收账销已做补新拍)
| 单 | 端 | 状态 |
|---|---|---|
| ~~P1~~ 资源总览接 MaterialSourceSheet **2026-08-07 试跑批 kimi 消化合入(789d0f4d)** | kimi | 已销 |
| P2 真机录屏验收管线准备(CGEvent 打局+screencapture 录屏+关键帧;首用例塔 42,下批真机位) | Claude | 待发 |
| P3 checklist E 段 reconcile(BGM 8 轨已实装未勾等 stale 批注) | Claude/捎带 | 待发 |
| P4 Q2/A1 审计脚本入仓补齐可复现性(2026-08-07 夜抽验 3 条全中、两报告结论已确认成立并合入 main;**缺的只是脚本**——叶字段提取/消费扫描留在 `/tmp/q2/`、字段读写扫描留在 `/tmp/a1_audit/`,致 8/7/21 与 44/14 五个计数不可一键复跑。顺带按当前 main 重新定位 numbers.yaml 行号:报告写 `:1917` 现为 `:1954`) | qoderclicn 或 pi | 待发 |
| P5 PROGRESS.md 瘦身(2026-08-07 实测 107→110 行 / 79623 bytes / 最长单行 5043 字符,Read 单次读不下前 45 行即 26905 tokens,每次开局须绕 awk 截断) | Claude | 待发 |
| P6 死链扫描器准确率标注验证(人工标注 50-100 条真实引用样本,算 precision/recall;现有 10 类固定样例只覆盖解析层且 mock 了 git 调用,不能证明全仓底账可信。通过后才可把 `tools/README.md` 里的「可试用」升级为事实源) | pi 或 qoderclicn | 待发 |
