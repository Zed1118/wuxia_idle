# 挂机武侠 · 开发进度

> Mac 端 Claude Code + Opus 4.7 维护。会话开始主动读取，任务完成主动更新。
> 总行数控制在 100 行内，超出归档到末尾。

## 当前阶段

**Phase 1 战斗系统**（phase1_tasks.md 定义的 T01–T18），目标 3 周交付。

## 已完成

- **T01 项目初始化与依赖配置**（2026-05-10）
  - `flutter create --platforms=windows,macos --org com.pen.wuxia --project-name wuxia_idle`
  - pubspec.yaml: Riverpod 2.5 / Isar 3.1 / yaml / intl 等
  - `numbers.yaml` → `data/numbers.yaml`，pubspec 把 `data/` 声明为 asset
  - `.gitignore` 调整：去 `*.lock` 通配（保留 pubspec.lock）、加 `*.g.dart` 不入库
  - `flutter analyze` 0 issues / `flutter test` 通过 / `dart run build_runner build` 跑通

## 进行中

- **T02 全部枚举定义** — `lib/data/models/enums.dart`，按 data_schema.md §2 共 18 个枚举原样搬入

## 已知偏差 / 挂账事项

1. **Riverpod 版本**：CLAUDE.md v1.1 锁 3.x，但实际用 2.x（phase1_tasks.md 一致）。等 Phase 5 收尾时统一文档
2. **lib/ 目录结构**：CLAUDE.md 写 DDD（`core/features/shared`），实际用 phase1_tasks 的 flat（`data/combat/ui/providers`）
3. **`riverpod_lint` 砍掉**：与 `isar_generator 3.x` 在 analyzer 版本互斥，Phase 5 切 Isar 4.x 时再补
4. **IDS_REGISTRY.md 自报「143 个内容 ID」错误**：实际 238 个（章节3+关卡15+装备45+心法22+招式102+奇遇26+百科18+模板7）。等 DeepSeek 改文末
5. **phase1_tasks.md T17 场景 D 笔误**：「差 2 大境界」应为「差 3」（三流→绝顶）。做到 T17 时一并改
6. **GDD §5.3/§5.6 公式系数 vs numbers.yaml**：GDD 字面 ×8 / ×5 是「口误」，代码以 numbers.yaml 平衡值（×1.0 / ×0.7）为准。GDD 文字暂不修
7. **numbers.yaml 节气列表混入「中秋」**：中秋是农历节日不是节气。GDD 没明确要求 24 节气，待定
8. **CLAUDE.md §12 待人类决策清单 13 条**：境界层 vs 修炼度层重名、属性单项分布、+20+ 强化曲线等。Phase 1 实现到对应位置时按需提问

## 下一步

T02 枚举定义（0.5 天）→ T03 嵌入对象（0.5 天）→ T04 三个核心 Isar 实体（1 天）→ Week 1 收尾 T05/T06/T07

## 关键约束（每次开局必读）

- 数值红线：普伤 ≤8000、玩家血 ≤20000、内力 ≤15000、装备攻击 ≤2000（GDD §5.2）
- 不硬编码数值（走 numbers.yaml）、不硬编码中文文案（走 data/narratives, lore, events）
- Riverpod 状态管理；Isar 本地存储；data/ 是 asset 根目录
- 写代码不动 GDD.md / CLAUDE.md / numbers.yaml / data_schema.md / IDS_REGISTRY.md（DeepSeek 领地）
- Mac 端写 lib/、data/*.yaml（顶层）、test/；DeepSeek 写 data/narratives/、data/lore/、data/events/

## 远程仓库

- GitHub：https://github.com/Zed1118/wuxia_idle
- 主分支 main
- 双端协作：Mac+Opus 写代码与数值；Windows+DeepSeek 写文案
