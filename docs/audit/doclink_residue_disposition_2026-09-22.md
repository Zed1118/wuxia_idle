# 死链残余处置台账（派单 F-续）

> 日期：2026-09-22
> 状态：RESIDUE_CLOSED
> 基线：8d8ae91951950d0fa8113e689491061da8047783；续办起点：0b3b4d905

## 1. 规则与改前/改后摘要

沿用 2026-09-21 用户拍板：来源文件 basename 含 YYYY-MM-DD 短横日期即历史快照，失效引用与五个既有归档目录并列归 archival；前缀、中缀、后缀均算，八位无横日期与目录名日期不算，存活及 ignored 判定不变。归档动机是引用指向写作当时的仓库状态。本轮从 dead 转入归档恰为 219 条：docs/spec 205、docs/phase0 7、docs/art 7；原包 220 更正为 219。
改前 python3 tools/doc_link_scan.py 摘要原文（已含前轮入库的台账与恢复点）：

```text
汇总:
  扫描 md 文件数:  1832
  引用总数(存活+死+ignored+归档):  12372
  ├─ 存活(已跟踪):  9784
  ├─ ignored(gitignored,不计死链):  781
  ├─ 归档类(归档文档内的失效引用,不进修复清单):  1582
  └─ 死链(未跟踪且未被 ignore):  225
  跳过类(通配/模板/worktree 名等):  607
    (其中出 repo 边界:  102)
  已跟踪文件总数(参考):  5549
```

改后 python3 tools/doc_link_scan.py 摘要原文：

```text
汇总:
  扫描 md 文件数:  1832
  引用总数(存活+死+ignored+归档):  12366
  ├─ 存活(已跟踪):  9784
  ├─ ignored(gitignored,不计死链):  781
  ├─ 归档类(归档文档内的失效引用,不进修复清单):  1801
  └─ 死链(未跟踪且未被 ignore):  0
  跳过类(通配/模板/worktree 名等):  607
    (其中出 repo 边界:  102)
  已跟踪文件总数(参考):  5549
```

--rows 与 --json rows 逐条对照：225 = 219 条转归档 + 下表 6 条取消路径引用；引用总数仅减少 6，md 数与存活、ignored、原 1582 条归档明细均保持不变，JSON key 与归档明细列结构不变。

## 2. 六条活文档处置（已完成）

| 来源 | 引用 | 处置与证据 |
|---|---|---|
| docs/ROADMAP_1_0.md:47 | test/tools/balance_simulator_test.dart | 去反引号并注已随路线 C ca548a3a7 移除；该提交状态 D。 |
| docs/ROADMAP_1_0.md:165 | test/balance/battle_strategy_e2e_test.dart | 去反引号并注已随路线 C ca548a3a7 移除；该提交状态 D。 |
| docs/PUBLISHING_ART_PASS_1_0.md:53 | assets/techniques/ | 改纯文本，注 7 张零引用 cover 已于 d3cde5a33 清理、目录不存在；场景引用保留。 |
| docs/PUBLISHING_ART_PASS_1_0.md:248 | assets/techniques/ | 改纯文本，注 d3cde5a33 移除目录、心法图尚未形成体系；7 张 cover 与 .gitkeep 均为 D。 |
| docs/RELEASE_CHECKLIST_1_0.md:110 | docs/handoff/r3_visual_check_screenshots/ | 去反引号并注证据图不入库、从未跟踪；当前可达全部 Git 历史查询无输出，同行其余引用保留。 |
| docs/phase0/route-c-external-gate-preflight.md:13 | data/app.so | 仅此串改纯文本并注构建产物路径、不入库；Windows Profile 脚本第 94/97 行定位 AOT 载荷并取 SHA-256，同行 wuxia_idle 保留。 |

## 3. 历史引用留痕

- assets/audio/voice、assets/audio/sfx/battleDeath.mp3、assets/audio/LICENSES 三条分别为录制计划、无资产未接线和未完成验收计划，与 docs/audio_asset_generation_guide.md 的计划素材排除性质相同。
- assets/images/inner_demon/enemy_*.png 七条来自 docs/art/inner_demon_enemy_mj_prompts_2026-05-24.md:126–132；git log --all -- 'assets/images/inner_demon' 无输出，当前可达全部 Git 历史未发现入库记录，属于计划素材。
- docs/phase0 原八条：旧 3v3 文件六条、tools/phase0minus_probe/test/host_human_session_macos_test.dart 一条已按日期规则归档；data/app.so 一条为 Windows Profile AOT 构建载荷路径，来源无日期，本轮补授权后按上表处置。
