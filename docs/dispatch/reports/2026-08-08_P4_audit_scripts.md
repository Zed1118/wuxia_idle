# REPORT_P4 · Q2/A1 审计脚本入仓与五计数可复现补齐

- **时间**:2026-08-08(夜批)
- **执行**:qoderclicn · worktree `qoder-p4-0808` · 分支 `qoder/p4-audit-scripts-0808`
- **性质**:工具入仓 + 报告行号订正;零 `lib/` 改动、零 `data/*.yaml` 值改动、零 `.dart` 改动
- **上游**:`2026-08-07_Q2_config_bypass.md`、`2026-08-07_A1_dead_fields.md`(结论已抽验采信)
- **本单边界**:不重做审计、不改审计结论;只让五个计数可被一条命令复跑

---

## 一、入仓脚本清单(`tools/audit/`)

源:2026-08-07 审计时写在 `/tmp/q2/`、`/tmp/a1_audit/` 的临时脚本。
入仓前已核对 `/tmp` 与协调者备份(`~/.claude/jobs/1dedbe6d/tmp/p4_backup/`)
**逐字节一致**(`diff -r` 零差异),以 `/tmp` 为源。

| 文件 | 来源 | 职责(一句话) |
|---|---|---|
| `q2_leaf_extract.py` | `/tmp/q2/leaf_extract.py` 原样 | 按缩进轻量解析单个 yaml,产出全部标量叶子 `(路径, 值, 行号)` |
| `q2_field_usage.py` | `/tmp/q2/field_usage.py` | 提取 loader 的 `final` 强类型配置字段,逐字段 grep 业务侧引用,零引用者即机械筛候选 |
| `a1_extract_fields.py` | `/tmp/a1_audit/extract_fields.py` | 扫 102 个领域文件,按类体深度提取实例字段声明 `(类, 字段, file:line)` |
| `a1_refs.py` | `/tmp/a1_audit/refs.py` | 对每个字段在全部非 `.g.dart` dart 文件做词边界引用枚举 |
| `a1_classify.py` | `/tmp/a1_audit/classify.py` | 引用行读/写/声明/debug 形态分类,产出无生产读候选 |
| `a1_classify_owned.py` | `/tmp/a1_audit/classify_owned.py` | 类上下文归属过滤(消同名字段污染)后再分类;抽出 `filter_owned()` 供入口复用 |
| `a1_verify_fields.py` | `/tmp/a1_audit/verify_fields.py` | 复核字段表每行确实形如声明(非注释/非方法签名) |
| `audit_anchors.py` | **新写**(数据取自两份报告主表) | 把报告结论逐条落成机器可读锚点(Q2 8+7+21、A1 44+14+1) |
| `run_all.py` | **新写** | 统一入口:机械底座 + 锚点复验,打印五个计数;`--json` / `--full` |

入仓改动口径(与原脚本的差异,全部为可复现性所需,判据零改动):

- 写死的 worktree 绝对路径(`…/qoder-config-bypass`、`…/pi-deadfield`)一律改为
  从 `__file__` 推导仓库根;中间产物路径参数化(`--workdir`),不再写死 `/tmp`。
- `fields.tsv`/`refs_by_field.tsv` 内文件路径改为**仓库相对路径**,任何 worktree 跑结果一致。
- 判据正则、排除规则(lib/data、features/debug、`*.g.dart`)、读/写形态定义与
  归属规则**逐行保留**,未做任何调整。
- 只用 Python 3 标准库 + `grep` 子进程,与 `tools/doc_link_scan.py` 同体例,无第三方依赖。

## 二、五个计数的实跑输出与比对

命令:`python3 tools/audit/run_all.py`(约 25s;`--json` 输出结构化结果,
`--full` 追加跑全量 A1 管道)。输出第一屏:

```text
==============================================================
Q2/A1 审计五计数复跑(HEAD aea56f2c)
==============================================================

五个计数(复跑值 = 仍成立的报告结论条数):
  Q2 背离(confirmed) = 7    (报告值 8) △
  Q2 部分背离 = 7    (报告值 7) ✓
  Q2 休眠配置(已解析零 caller) = 21    (报告值 21) ✓
  A1 只写不读 = 43    (报告值 44) △
  A1 仅 debug/test 读 = 14    (报告值 14) ✓

Q2 机械底座:
  顶层 config yaml 数        = 20
  叶字段总数                 = 14944(numbers.yaml 1239)
  强类型配置字段数           = 630
  业务侧零引用候选数         = 92
A1 机械底座:
  领域文件数 = 102  类数 = 102  字段数 = 661
```

### 比对结论

| # | 计数 | 报告值 | 复跑值 | 判定 |
|---|---|---|---|---|
| 1 | Q2 背离(confirmed) | 8 | **7** | △ 差 1,原因明确(见 §三) |
| 2 | Q2 部分背离 | 7 | **7** | ✓ 全中 |
| 3 | Q2 休眠配置 | 21 | **21** | ✓ 全中 |
| 4 | A1 只写不读 | 44 | **43** | △ 差 1,同一原因(见 §三) |
| 5 | A1 仅 debug/test 读 | 14 | **14** | ✓ 全中 |

机械底座同样吻合:叶字段 14,944(numbers.yaml 1,239)与审计存档
`numbers_leaves.tsv` 逐行一致;领域文件/类/字段 = 102/102/661 与 A1 报告 TL;DR 一致。
两处漂移均属"main 前进"的正常口径变化:强类型字段 627→630、零引用候选 89→92
(稀有度收口新增 loader 字段所致);A1 全量管道(`--full`)无生产读候选 71→70。

## 三、差异(两处,同一根因,如实记录)

**根因**:2026-08-08 白天的稀有度收口批次(`19481cba`「NumbersConfig 接入
rarity_distribution 派生」等 7 个 commit)在本单审计基线之后合入,把 Q2 的 B1
与 A1 的 `Character.rarity` 两条结论在 main 上修复了:

- **Q2 B1(`rarity_distribution`)不再背离**:loader 已解析该段
  (`numbers_config.dart` `rarityForTotalPoints`),三个创角/收徒路径的
  `RarityTier.biaoZhun` 字面量已改为按总点数派生,`.rarity` 出现生产读
  (角色档案展示 `lineage_character_detail_screen.dart:303`)。
  → confirmed 背离 8 → **7**(B2-B8 全部仍成立,硬编码证据逐一复验仍在)。
- **A1 `Character.rarity` 不再只写不读**:同上,出现生产读。
  → 只写不读 44 → **43**(其余 43 条逐条复验仍为生产零读)。

这不是脚本凑数,也不是审计结论被推翻:**对 2026-08-07 基线(`af82baea`)两份报告
依然完全正确**;复跑口径是"报告结论在当前代码上是否仍成立",main 前进导致的
失效如实减计。两份原报告已各加 P4 注记块说明此事。

复验细节(`run_all.py` 明细段,摘录):

```text
Q2 背离(confirmed)明细:
  [失效] B1 character.rarity_distribution 六档稀有度概率整段失效
         业务读 .rarity = 3
         证据 lib/features/recruitment/application/recruitment_service.dart  已消失
         证据 lib/features/sect/presentation/sect_recruit_handler.dart  已消失
         证据 lib/features/onboarding/application/master_builder.dart  已消失
  [成立] B2 … B8(证据均在,业务读均 0)

A1 主表 A(只写不读,判据=生产零读)复验:
  [失效] Character.rarity -> has_prod_read
  其余 43 条仍为生产零读
A1 主表 B(仅 debug/test 读,判据=生产零读+读点仍在)复验:
  其余 14 条仍为仅 debug/test 读
```

## 四、行号 drift 订正(旧 → 新,共 31 处)

订正方法:按**字段名正向 grep** `data/numbers.yaml` 现查(不按旧行号反查)。
漂移根因:报告成文后,N1 批(`13ce2300`,+4 段注释)与 2026-08-08 稀有度批次
再次插入注释,行号二次漂移(协调者批注里的 `:1954` 也已过期)。

### Q2 报告(30 处)

| 字段 | 旧 | 新 |
|---|---|---|
| `character.rarity_distribution`(自校验闸门) | :942 | :966 |
| `character.rarity_distribution`(B1 段) | :942-961 | :966-984 |
| `sect_recruit.stage_boss_recruit_prob`(B3) | :1917 | :1958 |
| `inheritance.heritage_items.transfer_trigger`(B5) | :1408 | :1444 |
| `…multi_disciple_allocation`(B6) | :1409 | :1445 |
| `…stack_across_generations`(B7) | :1410 | :1446 |
| `…conflict_slot_resolution`(B8) | :1411 | :1447 |
| `retreat.zheng_wu.target_attribute`(P1) | :1208 | :1232 |
| `gang_meng_quake` 三布尔(P2) | :878/879/880 | :881/882/883 |
| `yin_rou_internal_injury` 三标志(P3) | :890/891/892 | :893/894/895 |
| `combat.critical.max_damage_multiplier` | :137 | :140 |
| `combat.qi.chain_recovery_pct` | :80 | :83 |
| `inner_demon…internal_force_multiplier` | :1657 | :1698 |
| `inner_demon…internal_force_floor_pct` | :1658 | :1699 |
| `inner_demon…sub_cultivation_multiplier` | :1660 | :1701 |
| `inner_demon…debuff_id` | :1661 | :1702 |
| `inner_demon…debuff_clear_via_retreat_hours` | :1662 | :1703 |
| `sect_recruit.encounter_base_prob` | :1916 | :1957 |
| `jianghu.triggers.encounter_npc_delta_min` | :1900 | :1941 |
| `jianghu.triggers.encounter_npc_delta_max` | :1901 | :1942 |
| `jianghu.enmity.enemy_attack_power_mult` | :1893 | :1934 |
| `sect_management.demo_initial_count` | :1921 | :1962 |
| `light_foot.stage_terrain` | :1735 | :1776 |
| `animation.readable_victory_min_ms` | :1598 | :1639 |
| `animation.shake_offset_px` | :1602 | :1643 |
| `inheritance.founder_ancestor_buff.cultivation_progress_pct` | :1430 | :1466 |

(Q2 正文行号引用合计 30 处;协调者历史批注中的 `:1917/:1954` 为 drift 记录本身,保留原貌不追改。)

### A1 报告(1 处)

| 字段 | 旧 | 新 |
|---|---|---|
| `character.rarity_distribution`(主表 A rarity 行) | :942 | :966 |

> 范围说明:本单只订正 `numbers.yaml:<行号>` 引用(派单限定)。两份报告中
> `numbers_config.dart` / 各 loader 的 dart 行号引用同样存在 drift 风险
> (如 Q2 B3 的 `numbers_config.dart:2687`),未逐一订正——复跑入口不依赖它们。

## 五、存疑(不自行改结论,留档)

1. **B3 `stage_boss_recruit_prob` 仍活着**:复验确认 `stage_def.dart` 的
   `?? 0.40` 字面量与三处误导注释仍在、业务侧零读——该背离在 main 上依旧成立,
   且报告 §八 建议的"纠正三处误导注释"尚未执行。
2. **A1 的 A/B 分档是编辑口径,不可纯机械导出**:报告判据下,A 表本就允许
   test 读存在(如 `criticalMultiplier`/`formulaBreakdown` 有 test 断言读仍归 A);
   故入口按"各表各自判据"复验(A=生产零读;B=生产零读+读点仍在),
   不做跨表重分档——否则计数必然对不上报告,那是口径差异不是结论漂移。
3. **复验器已知局限**(如实说明,不影响本次五计数):
   - 读形态正则与原审计脚本同源,`rarity` 的生产读计数 4 中含 2 行
     `rarity: …rarityForTotalPoints(` 命名参数/派生写点(前缀匹配误判为读),
     真实读点为 `lineage_character_detail_screen.dart:303`;不减计,结论不受影响。
   - A/B 档的 debug/test 读检测对"变量无类型注解"的 test 文件用
     "文件含类名"兜底归属,较原人工核验略宽;本次 14 条全部命中,未见误差。

## 六、未解决 / 建议

1. **建议把 `python3 tools/audit/run_all.py` 纳入滚动巡检**(如夜批例行):
   五个计数一旦变化即提示有新接线/新写死,是配置旁路与死字段的廉价回归哨兵。
2. Q2 报告 §八 的处置建议(接线或删字段)**全部仍待拍板**:7 处背离、7 处部分背离、
   21 处休眠在 main 上原样存在;本单未动任何一处。
3. A1 死字段删除属 schema 红色决策,维持只读底账状态;`rarity` 一项已随收口
   自然出表,无需再处置。
4. `/tmp` 与备份目录里的审计中间产物(`fields.tsv`、`refs_by_field.tsv` 等
   大文件)未入仓(体积大、可由脚本重新生成);脚本本体已入仓,`/tmp` 清理后
   不再影响可复现性。

---

*本单工作区产出:`tools/audit/` 9 个脚本、两份报告行号订正与 P4 注记、本报告。
零 lib/ 改动、零 data/ 值改动、零 .dart 改动。*
