# 滚动单池(跨夜不清空,水位 ≥3;收账销已做补新拍)
| 单 | 端 | 状态 |
|---|---|---|
| ~~P1~~ 资源总览接 MaterialSourceSheet **2026-08-07 试跑批 kimi 消化合入(789d0f4d)** | kimi | 已销 |
| P10 扫描器扫描范围收敛(2026-08-11 评估发现:939 条 dead 里 **600 条(64%)来自 `docs/handoff/` 的 404 篇归档文档**——那里的引用本就指向当时状态,拿这个数当清理清单会做 600 条无意义的活;同时 `tools/doc_link_scan.py:59` 的 `EXCLUDE_DIRS` **定义后全仓零消费**,排除项硬编码在 `collect_scan_files` 里。做法待拍:把 handoff 移出扫描源 / 单列一类 / 只改接线不改范围) | Claude | 待拍范围 |
| ~~P11~~ 资质三连实装 **2026-08-11 Claude 做完(`1e0c810c` 分支 `feat/aptitude-birth-rarity`)**:#15 saveVersion `0.38.0`→`0.39.0` 加迁移段 9 按出生点数(`attributes.total − attributeBonusFromAdventure`)重算全部角色档位;#16 chip 括注改传出生点数;算法 sink 走 `CharacterBirthAttributes` extension——**类内 getter 会被 isar_community 生成成持久化属性**(实证 `Attributes.total` → `attributes.g.dart PropertySchema(id:4)`),故走 extension,重跑 build_runner 后 `character.g.dart` 零命中。新增迁移测 5 例 + chip 测 2 例(该 chip 此前零覆盖),3 次变异全部精确命中(改按当前总点数→`jueShi`、chip 回退、清零 bonus)。**第三项视觉档位化用户拍板并入试玩局,已单独立行为 BACKLOG 一#19** | Claude | 已销 |
| P12 远端 4 个遗留备份分支清理拍板(实测 `main..origin/<b>` 独有 commit:`codex/taohua-art-0807`=0、`qoder/p4-audit-scripts-0808`=0 两个 git 可断言已包含删除零风险;`pi/p6-link-label-0808`=2、`worktree-claude-rarity`=3 是 rebase/cherry-pick 前旧 SHA,内容在 main 但 git 证明不了) | 用户拍板 | 待拍 |
| P2 真机录屏验收管线准备(CGEvent 打局+screencapture 录屏+关键帧;首用例塔 42,下批真机位) | Claude | 待发 |
| ~~P3~~ checklist E 段 reconcile **2026-08-11 Claude 做完(逐条现查:BGM 11 轨 / 战斗 SFX 6 类 / UI SFX 3 类全已实装,原 4 项全未勾属 stale;另订正原文两处与实装不符——「死亡」音 v1 明确不做、「7 阶递进」实为 teamSide×slotIndex 变体;唯一真未完项=配音 0 段)** | Claude | 已销 |
| ~~P4~~ Q2/A1 审计脚本入仓补齐可复现性 **2026-08-07 夜批 qoderclicn 交付并合入(`tools/audit/` 9 脚本 + `run_all.py` 统一入口,五个计数可一键复跑;2026-08-11 核实全部 git 跟踪)** | qoderclicn | 已销 |
| ~~P5~~ PROGRESS.md 瘦身 **2026-08-08 夜批 Claude 做完(110 行 79623B → 100 行 58468B,压缩 11 条旧条目)** | Claude | 已销 |
| ~~P6~~ 死链扫描器准确率标注验证 **2026-08-08 夜批 pi 交付并合入(precision 95.0%/recall 100%/一致率 88/90,查出两处系统性假阳)** | pi | 已销 |
| ~~P7~~ 死链扫描器假阳修复 **2026-08-11 用户拍板合入(`ab38b43c`)**:两处改动 49 行。协调者独立实测——修复前主 checkout dead=939/ignored=592、fresh worktree dead=956/ignored=575(漂移 17),修复后同一份代码两地逐值相同 refs=7442 alive=5929 dead=908 ignored=605(漂移 0);引用总数守恒。两处修复各自破坏证红精确命中 2 条红线 | 用户拍板→Claude | 已销 |
| ~~P8~~ 死链扫描器引真实 git fixture 的测试 **2026-08-08 下午 Claude 做完并合入(`b3c74a6b`)**:15 例(harness 自证 3 + 正确行为回归 5 + 假阳红线 7),真起临时 git 仓只替换 `REPO_ROOT`;4 条 `expectedFailure` 已随 P7 落地转为正式断言 | Claude | 已销 |
| ~~P9~~ `/afk` 工作流 v2 三处门禁缺口 **2026-08-08 夜 Claude 做完(`~/.claude` `f231137`)**:待拍板改双信号源(分支 tip `[BLOCKED]` + 池内「待拍/用户拍板」)并新增致命检查 `tasks_awaiting_decision`;`approved_tasks` 改前导 ID 精确匹配 + `branch:`/`adhoc:` 逃生舱;`doctor --json` 补透出 `dispatch_template`。测试 19→34 例,三次变异各自精确命中 | Claude | 已销 |
