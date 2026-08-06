# 夜批单 C1 · 场景图伪文字题字清查(2026-08-06)

## 背景与基线
- 仓库:/Users/a10506/Desktop/Projects/挂机武侠(Flutter macOS 写实武侠挂机,买断制)
- 工作树(已建好):`.claude/worktrees/codex-inscription`,分支 `codex/tonight-inscription`,基线 main `74a7993c`
- 只动 assets/scenes/ 下清单内图片 + 本单指定的报告/证据文件,其余一律禁区。本单不跑 flutter。
- 规则出处:G5.1「MJ 图里 AI 生成的假汉字/假英文必须被遮盖或避开」(docs/handoff/codex_vis_textscale_recheck_2026-06-07.md:47),针对「冒充可读文本的多字题字」;**朱红印章是主动要的美术母题,必须保留**(docs/PUBLISHING_ART_PASS_1_0.md:215「5-8% 暗红印章」)。

## 任务
清除早期 MJ 批次场景图上的书法题字(多字伪汉字),印章不动。

已确认带题字(8 张,2026-07-26 全库扫描结论):
- battle 5:battle_frontier / battle_dock / battle_escortroad / battle_teahouse / battle_temple(.png)
- 封面 3:chapter_02_cover / chapter_04_cover / chapter_06_cover(.png,先 ls assets/scenes/ 确认真实文件名再动)

待你 Phase 0 确认:narrative_stage_*.png 全量逐张(历史目检估 8-12/30 张带题字,估数未逐张确认,以你实测为准):
- 快筛:受影响图全部属 mtime「2026-07-02 21:17」批次(`ls -la` 按时间筛);7 月 18 日之后的图零问题
- 逐张放大目检,圈出带多字题字的列精确清单(文件名+题字位置);仅印章/无字的不处理

## 处理口径
- 优先「同图重出无字版」:用内置 image_gen,以原图为参考图锚(-i 喂原图)重绘同构图/同色调/同笔触、零伪文字版本;或局部修补去字保留原画面。按图自选,标准=画面完整自然、零可读/伪可读字形残留、印章保留(原图有印章的,处理后仍要有暗红印章落款,单章无字)。
- 规格:与原图同尺寸;格式先 `file <原图>` 确认(库内多为 webp 数据保 .png 扩展名,q80),替换图压回同规格。
- 原图不另备份不删除(git 历史即回滚点),同名覆盖。
- 提示词禁写身体伤害语义(尸体/血迹/冻伤等),换环境/天气口径,防 output moderation 拦截。

## 产出与验收(全部完成才算 [READY])
1. narrative_stage Phase 0 精确判定表(逐张:文件名/有无题字/是否处理)
2. 清单内每张替换完成,规格自检逐张记录(同尺寸/同格式/放大目检零伪文字/印章保留)
3. before/after 对照 contact sheet 落 worktree 内 `docs/dispatch_evidence/inscription_2026-08-06/`
4. 报告落 worktree 根 `REPORT_C1.md`:处理张数/逐张表/方法(重出 or 修补)/自检结果/剩余风险
5. git add + commit 到本 worktree 分支,message 前缀 `[READY] C1 场景题字清查:`;结束时工作树须干净

## 边界约束
- 拿不准的图(题字与画面元素难分/重出效果差)不硬做,报告列 [BLOCKED] 段说明,留终审
- 视觉终拍在用户,你的目检是初检;宁可 [BLOCKED] 不可糊弄
- 禁触碰:lib/ test/ data/ docs/(除本单产出) pubspec.yaml 及 assets/ 其他子目录

## 时长引导
预估 4-6h。主清单完成且有余力:对处理过的图做第二轮交叉复检(放大逐角落查字形残留),更新自检表。
