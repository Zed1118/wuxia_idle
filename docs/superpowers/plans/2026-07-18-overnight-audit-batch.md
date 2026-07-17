# 2026-07-18 overnight 审查落地批(外部审查报告全量 triage + 实装)

- **目标**:落地 `~/Desktop/挂机武侠_全量审查报告_2026-07-18.md` 经证伪后的有效项
- **分支**:`fix/audit-batch-20260718`(worktree `.claude/worktrees/audit-batch-20260718`,基于本地 main `af177610`)
- **用户拍板**(睡前):GameRepository 只拆文件保单例;单分支一个 draft PR;其余自主决策
- **硬约束**:不 push main(仅 push 本分支)/零数值零 schema 零 saveVer/不动 GDD/CLAUDE/numbers.yaml/每批 analyze+测试绿才 commit/09:00 用户接手

## 批次与验收标准

| 批 | 内容 | 验收 |
|---|---|---|
| A ✅ | skills.yaml 过时头注订正(#15 false positive)+ analyzer 钉 9.0.0(lock 零变化);**tags 剥离不做**(#19 证伪见下) | pub solve ✓ analyze ✓(批B末合并验证) |
| B | core→features 3 处反向 import 消除:sect_rank+island_building_state+island_building_type(26 importer,连带)下沉 core/domain;battle_providers(53 importer)迁 features/battle/application;脚本 relpath 重写 | grep 0 反向 import;build_runner 重生;analyze 0;全量绿 |
| C | GameRepository(2402 行)拆文件保单例:校验段拆 lib/data/validation/(沿 drop_table_reference_validator 模式);feature-domain def/config 迁 lib/data/defs/(18 个已在,再迁 ~11,loader 类判断归 lib/data/) | data→features import 清零或仅剩豁免;instance API 零变;analyze 0;全量绿 |
| D | main_menu.dart(1137 行,462 行 build)同文件私有 widget 拆分 | analyze 0;main_menu targeted 绿 |
| E | tower_entry_flow:134 test-hook catchError 补日志/battle_demo(16 测试引用,0 生产引用)迁 test/support//features/README 归档/README yaml 计数 450+/tool+tools 职责 README/strict-casts 试探(<30 修否则回退记账)/建 followup backlog 文件 | analyze 0;涉及测试绿 |
| 收尾 | 全量 analyze+test → push 分支 → draft PR(注明 diff 含 43 个用户未 push main commit)→ handoff ≤50 行 → PROGRESS 顶段(净增≤0) | PR 链接落 handoff;PROGRESS 更新 |

## 报告 triage 结论(证伪记录,均本会话实测)

- **#15 skills.yaml 无倍率 enforce → false positive**:game_repository:1066 对全部 skillDefs 加载期 enforce ≤8000+|qiDelta|,双向守门测 skill_multiplier_redline_test(生产自洽+broken loader 红测)。骗源=skills.yaml 头注过时(v1.32 前表述)。仅修注释。
- **#19 慢模拟拖慢全量 → false positive**:JSON 计时实测(4088 pass/4m49s),test/tools 全目录累计 ~38s、10 核并发摊墙钟 ~4s;balance_simulator(1100 行)仅 1.2s,全部诊断测 <5s。真大头=622 个 suite 编译+feature 测试广布(top: team_lineup 15.8s/maxhp_extremum 15.2s/seclusion 14.3s)。报告按行数推断未实测。tags 剥离收益≈0 且让红线诊断日常缺位——不做。日常提速正解=既有 v1.29 节奏。
- **#9 battle_demo 疑似死代码 → 半错**:0 生产引用但 16 测试文件消费,是 test harness 住错地方,迁 test/support/(批E)。
- **#7 debug feature 迁出 → 降级不做**:kDebugMode const+tree-shaking,release 无残留,纯目录整洁问题 → backlog。
- **#11 存档 clamp → 需数值拍板** → backlog。
- **去单例化 → 用户拍板不做** → backlog。

## 环境备忘(续跑必读)

- worktree 已预热:pub get ✓ dylib 已拷 ✓ build_runner 124 outputs ✓ analyze 0 ✓
- 全量基线:**4088 pass / 0 fail**(01:53-01:58 实测,--file-reporter json 下 4m49s;JSON=`~/.claude/jobs/44f53959/tmp/full_baseline.json`,解析脚本 parse_timing.py 同目录;import 重写脚本 rewrite_imports.py 同目录)
- 在途不碰:`codex/battle-experience-phase3`([READY] 待用户拍板)/`codex/battle-ui-stage`(WIP)/`feat/baicao-duanhun-phase-b`(Ch8 文档)
- 主 checkout main ahead origin 43,push 是用户的活(本分支可 push)

## 当前恢复点

- **状态**:批A ✅(19b9431e) 批B ✅(1aa21961·全量4088/0) C1 ✅(905cbe7a·19 def 迁移) C2a-c ✅(f2fbcae0) **C2d-f ✅编辑完成,全量验证跑批中→绿了就 commit** → 批D
- **C2 终态**:GameRepository **2402→1137 行**;22 个 private _enforce* + 2 个类外自由函数(lineage_onboarding/founder_school_uniqueness,连带 2 个测试文件 import 迁移)→ 6 个域校验文件(economy_codex/encounter/technique_equipment/progression/lineage_recruit/skill);唯一体改=enforceSkillSourceRedLines 的 releaseRealm 改调用方传参(原实例方法内查);4 个 public static enforce* 是公共 API 不动;dart format 已归一
- **C1 追加发现**:numbers_config 8 个 feature 子配置模型一并迁 defs;equipment_disposal 跳过(级联)→ backlog;isar_setup=composition root 豁免+注释
- **下一步**:全量绿 → commit C2d-f → 批D(main_menu 1137 行/462 行 build 同文件私有 widget 拆)→ 批E(tower_entry_flow 空catch/battle_demo 迁 test/support/README 计数/tool README/strict-casts 试探/backlog 文件)→ 收尾(push 分支+draft PR+handoff+PROGRESS)
- **已跑验证**:全量 4088/0(01:58 基线+02:25 批B);C1 targeted 565(02:44);C2 analyze 0+format 归一(04:15)
- **阻塞项**:无;handoff 需记:CLAUDE §5.4「schema 真 sink=game_repository._enforceEncounterSkillRedLines」表述过时待 v1.40(新位置 validation/encounter_red_lines_validator.enforceEncounterSkillRedLines)
