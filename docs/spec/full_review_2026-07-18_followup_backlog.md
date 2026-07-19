# 2026-07-18 外部审查报告 followup backlog

> 源:`~/Desktop/挂机武侠_全量审查报告_2026-07-18.md` · overnight 落地批(分支 `fix/audit-batch-20260718`)triage 后的 deferred 项。
> 体例沿 `full_review_2026-07-02_followup_backlog.md`。backlog 合法性:均为「需用户拍板」或「依赖未解除」项(CLAUDE §7 打磨期原则)。

## 需用户拍板

| # | 项 | 报告# | 现状与拍板点 |
|---|---|---|---|
| 1 | CLAUDE §5.4「schema 真 sink」表述订正(v1.40) | — | 批C 把 `_enforceEncounterSkillRedLines` 迁至 `lib/data/validation/encounter_red_lines_validator.dart`(公名 `enforceEncounterSkillRedLines`),CLAUDE §5.4/§8.1 相关行需同步;CLAUDE 是 no-touch 文件,待用户过目后我来改 → **✅ v1.40 已落(2026-07-18 用户拍板)** |
| 2 | 存档(Isar)载入关键字段 clamp | #11 | clamp 边界=数值设计决策(clamp 到硬红线?软线?哪些字段?),与红线测试语义耦合,不宜代拍 → **✅ 2026-07-18 拍板不做,进 rejected registry**(理由见 registry 条目) |
| 3 | GameRepository 去单例化(provider 注入) | #2 后半 | 用户已拍「今晚不做」;若未来要做,建议先 grep `GameRepository.instance` callsite 量再定 facade 策略 → **✅ 2026-07-18 实测 1269 callsite,拍死不做,进 rejected registry** |
| 4 | `设计文档/`、`审查报告/` 两个未入库中文目录去留 | #23 | 入库 or .gitignore,用户定 → **✅ 2026-07-18 拍板:排除规则入库 .gitignore(本地 exclude 转正,目录留作用户草稿区)** |
| 5 | debug feature(~7000 行)迁出 lib 树 | #7 | 已证伪其安全/体积危害(kDebugMode const+tree-shaking,release 无残留),纯目录整洁问题;若仍想做,是大迁移需专批 → **✅ 2026-07-18 拍板不做,进 rejected registry** |

## 依赖未解除

| # | 项 | 报告# | 依赖 |
|---|---|---|---|
| 6 | `equipment_disposal.dart` 迁 data/defs(numbers_config 唯一残留 data→features 边) | #3 余项 | 依赖 `equipment_slot_occupancy` 同迁或解耦(含逻辑非纯 def),级联面待评估 → **✅ 2026-07-19 K1 拆分迁落地(`1b1eef21`·仅 config 类迁 defs+export 透传,slot_occupancy 同迁/解耦均被级联评估证伪,详 plan)** |
| 7 | isar community fork 供应链 / analyzer 三角解锁 | #13/#14 | 上游 isar_community 支持 analyzer ≥12 才能动(2026-06-30 维护轮结论);analyzer 已钉 9.0.0 止血 |
| 8 | strict-inference 启用 | #17 | strict-casts 已于本批启用(仅 9 处 legacy dynamic,全修) → **✅ 2026-07-19 kimi B 单全仓启用(31 处显式化·夜批收账合入 f962b056)** |

## 已在本批证伪不做(留档防重提)

- #15 skills.yaml 倍率无 enforce → false positive(enforce+双向守门测均在,系 yaml 头注过时,已订正)
- #19 慢模拟测试剥离提速 → false positive(JSON 计时实测 test/tools 全目录并发墙钟贡献 ~4s;balance_simulator 1.2s;耗时大头=622 suite 编译+feature 测试广布)
- #9 battle_demo 死代码 → 半错(16 个测试文件消费的 test harness,批E 迁 test/support/)
- #5 拆 5 个 2000 行 screen → 大部证伪(除 main_menu 外四屏实测均已 21-30 私有 widget 良好拆分,最大 build 144-196 行;报告按文件行数点名。唯一真 462 行 build=main_menu 已批D 拆;文件级再拆不做防 codex 冲突)
