# 2026-06-28 Tower Structure Review Plan

## 目标

执行「爬塔层数结构复核」审计，基于 `data/towers.yaml`、必要时对照 `data/stages.yaml` / GDD 红线，复核 30 层塔的 Boss 节奏、小 Boss 间隔、掉落曲线与难度坡度，输出可执行审计文档。

## 分支

`codex/tower-structure-review`

## 验收标准

- 已读取 `AGENTS.md`、`CLAUDE.md` §8.0、`GDD.md` §8.2 / §5 红线、`docs/spec/playability_phase2_backlog.md` §十二。
- 不直接修改 `data/*.yaml` 数值；如发现 P0/P1 问题，仅在审计文档中列为修复候选。
- 产出 `docs/audit/tower_structure_review_2026-06-28.md`，包含现状表、问题分级、是否违反红线、建议切片、需要用户拍板项。
- 使用脚本或测试读取 `data/towers.yaml`、`data/stages.yaml` 等，保证结论有数据依据。
- 完成后提交计划和审计文档；不 merge、不 push、不改 main。

## 任务切片

1. 切换/创建 `codex/tower-structure-review` 分支。
2. 读取指定项目规范与红线。
3. 解析 `data/towers.yaml`，提取层数、Boss、敌方 HP/ATK、经验、掉落曲线。
4. 对照 `data/equipment.yaml` / `data/stages.yaml` 做掉落阶位与参考数据核查。
5. 编写审计文档，按问题分级与建议切片组织。
6. 运行针对性验证命令/测试。
7. 更新本计划当前恢复点并提交。

## 当前恢复点

- 状态：已完成，待主窗口复核。
- 最后完成：已产出 `docs/audit/tower_structure_review_2026-06-28.md`；审计结论为结构红线通过，但 25/30 层 Boss 体感与后段 Boss 机制密度存在 P1/P2 风险，需要用户拍板后再决定是否开调值/机制切片。
- 下一步：主窗口检查审计文档；如用户拍板，另开后段 Boss 机制或奖励信号调整任务。
- 已跑验证：
  - `ruby -ryaml -e '...'` 读取 `data/towers.yaml` 输出 floor/boss/realm/enemies/teamHp/teamAtk/baseExp/drops/fragment。
  - `ruby -ryaml -e '...'` 读取 `data/towers.yaml` 校验 floors=30、indexes_ok=true、Boss 位与 boss_hp_max。
  - `ruby -ryaml -e '...'` 读取 `data/towers.yaml` + `data/equipment.yaml` 汇总装备掉落阶位。
  - `ruby -ryaml -e '...'` 读取 `data/towers.yaml` + `data/stages.yaml` 检查 Boss phase 参考。
  - `dart run build_runner build --delete-conflicting-outputs` 补齐本地生成产物。
  - `flutter test test/features/tower/domain/tower_floor_def_test.dart test/features/tower/tower_skill_fragment_test.dart test/data/wave_b_content_redline_test.dart test/data/drop_table_reference_redline_test.dart` 通过，25 tests。
- 阻塞项：无。
