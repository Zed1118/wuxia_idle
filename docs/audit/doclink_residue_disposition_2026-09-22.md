# 死链归档扩类阻塞台账（派单 F）

> 日期：2026-09-22
> 状态：BLOCKED；开局核查发现白名单外残余，未实施规则和五处修文。
> 基线：8d8ae91951950d0fa8113e689491061da8047783

## 1. 规则与实测差异

沿用 2026-09-21 用户拍板：来源文件 basename 含 YYYY-MM-DD 即历史快照，失效引用与五个既有归档目录并列归 archival；无横日期与目录名日期不算。归档动机是引用指向写作当时的仓库状态，不重新论证该决议。
基线 python3 tools/doc_link_scan.py 摘要原文：

```text
汇总:
  扫描 md 文件数:  1830
  引用总数(存活+死+ignored+归档):  12372
  ├─ 存活(已跟踪):  9784
  ├─ ignored(gitignored,不计死链):  781
  ├─ 归档类(归档文档内的失效引用,不进修复清单):  1582
  └─ 死链(未跟踪且未被 ignore):  225
```

对 --rows 对应的 --json rows 逐条按 basename 日期判据复核：docs/spec 205、docs/phase0 7、docs/art 7，共 219 条；派单写 220 条，差额唯一对应 docs/phase0/route-c-external-gate-preflight.md:13 → data/app.so。该来源文件无日期，且不在白名单内。
未执行改后扫描，不填造实装数字；按明细推算，仅落实原派单将得到存活 9784 / ignored 781 / 归档 1801 / dead 1，无法达到归档 1802 / dead 0。
本次只新增台账与恢复点，入库后扫描 md 增加 2；两文均不新增扫描器可提取的路径引用，四分类数字保持上述基线。收据所在目录按既有规则排除。

## 2. 五条既定处置（已核证据，尚未执行）

| 来源 | 引用 | 处置与证据 |
|---|---|---|
| docs/ROADMAP_1_0.md:47 | test/tools/balance_simulator_test.dart | 去反引号，注明随路线 C ca548a3a7 移除；该提交状态 D。 |
| docs/ROADMAP_1_0.md:165 | test/balance/battle_strategy_e2e_test.dart | 去反引号，注明随路线 C ca548a3a7 移除；该提交状态 D。 |
| docs/PUBLISHING_ART_PASS_1_0.md:53 | assets/techniques/ | 改为纯文本，注明 7 张零引用 cover 已于 d3cde5a33 清理、目录不存在；不动场景引用。 |
| docs/PUBLISHING_ART_PASS_1_0.md:248 | assets/techniques/ | 改为纯文本，注明 d3cde5a33 移除目录、心法图尚未形成体系；7 张 cover 与 .gitkeep 均为 D。 |
| docs/RELEASE_CHECKLIST_1_0.md:110 | docs/handoff/r3_visual_check_screenshots/ | 去反引号，注明证据图不入库、从未跟踪；git log --all 查询无输出，同行其他引用保留。 |

## 3. 历史引用留痕

- assets/audio/voice、assets/audio/sfx/battleDeath.mp3、assets/audio/LICENSES 三条分别为录制计划、无资产未接线和未完成验收计划，与 docs/audio_asset_generation_guide.md 的计划素材排除性质相同。
- assets/images/inner_demon/enemy_*.png 七条来自 docs/art/inner_demon_enemy_mj_prompts_2026-05-24.md:126–132；git log --all -- 'assets/images/inner_demon' 无输出，当前可达全部 Git 历史未发现入库记录，属于计划素材。
- docs/phase0 共八条：旧 3v3 文件六条、tools/phase0minus_probe/test/host_human_session_macos_test.dart 一条可按日期规则归档；data/app.so 一条是 Windows Profile AOT 构建载荷路径，来源无日期，仍是本次阻塞残余。

## 4. 阻塞出口与续办条件

依派单“若确需改白名单外文件，停下打 [BLOCKED]”停止实现。建议协调者仅补授权 docs/phase0/route-c-external-gate-preflight.md:13 的引用串处置，并将归档预期更正为 1801；保持日期规则不变。未获新派单前不改该文件，不放宽排除或清洗规则。
