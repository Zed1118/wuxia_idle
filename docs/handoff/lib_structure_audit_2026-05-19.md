# lib/ 目录结构审计 · 2026-05-19

> Nightshift T09 audit 产出。**只审,不动 lib/**。CLAUDE.md §3 三层规范周期复审。

## §1 lib/features/ 全 feature 三层完整度

| feature | domain/ | application/ | presentation/ | 备注 |
|---|---|---|---|---|
| baike | ❌ | ❌ | ✅ | 百科 UI,纯展示层 |
| battle | ✅ | ✅ | ✅ | 核心战斗 |
| character_panel | ❌ | ✅ | ✅ | 用 core/domain 实体 |
| codex | ✅ | ✅ | ✅ | P1.z 新增 |
| cultivation | ❌ | ✅ | ✅ | 用 core/domain |
| debug | ❌ | ✅ | ✅ | 调试工具,无领域层 |
| dispel | ❌ | ✅ | ❌ | 纯散功 service,无 UI |
| encounter | ✅ | ✅ | ✅ | 奇遇系统 |
| equipment | ❌ | ✅ | ✅ | 用 core/domain |
| event | ❌ | ✅ | ❌ | 纯事件 service |
| festival | ❌ | ✅ | ❌ | W16 新增,节日 encounter service |
| home_feed | ❌ | ✅ | ✅ | 首页动态 |
| inventory | ❌ | ❌ | ✅ | 纯背包展示 |
| main_menu | ❌ | ❌ | ✅ | 主菜单展示 |
| mainline | ✅ | ✅ | ✅ | 主线 |
| narrative | ❌ | ❌ | ✅ | 叙事展示,纯 UI |
| seclusion | ✅ | ✅ | ✅ | 闭关系统 |
| technique_panel | ❌ | ❌ | ✅ | 心法面板展示 |
| tower | ✅ | ✅ | ✅ | 爬塔 |
| tutorial | ✅ | ✅ | ✅ | P1.x/P1.y 新增 |

总 feature 数:**20**(不含 README.md)。三层全:battle/codex/encounter/mainline/seclusion/tower/tutorial = **7 个**。`lineage` feature 尚未创建(T09 handoff 提及但目录不存在)。

## §2 跨 feature import 依赖图

| from | to | import path | 是否违 DDD? |
|---|---|---|---|
| battle/application | equipment/application | drop_service.dart | OK(app→app) |
| event/application | battle/domain | enum_localizations.dart | OK(app→domain) |
| seclusion/presentation | battle/domain | enum_localizations.dart | OK(pres→domain) |
| tower/presentation | equipment/application | drop_service.dart | ⚠️ pres→外部app |
| lib/core/application | battle/application+equipment/application | battle_resolution / drop_service | ⚠️ core/app→features/app 双向耦合 |
| lib/data/ | 多 feature domain | codex/encounter/seclusion/mainline/tower domain | OK(data层引 domain 实体) |

`tower/presentation` 直接 import `equipment/application/drop_service` 跳过了本 feature application 层,轻微违 DDD(不算硬阻塞)。`lib/core/application/` import `features/*/application/` 是现有战斗 provider 聚合点,结构性耦合,建议后续 Phase 3+ 迁移至 `features/battle/application/`。

## §3 命名规范偏差

| file/class | 偏差 | 建议 |
|---|---|---|
| — | 无文件名 non-snake_case 违规 | — |
| — | 无 `^class [a-z]` 违规 | — |
| `battle/domain/strategy/` | 二级子目录(合规,snake_case) | 维持 |

无偏差,全 feature 文件名/类名命名合规。

## §4 总结 + 推荐处置

- 全 feature 数:**20**
- 三层完整:**7**(35%)——其余 13 个均按"用 core/domain 共享实体"模式只建所需层,属设计有意为之
- 跨 feature import 违规:**1 处轻微**(tower/presentation→equipment/application)
- 结构性关注:**1 处**(core/application 聚合了 features application 层)
- `lineage` feature:**未创建**,若 W17 任务包含 lineage,需新建 feature 目录

推荐:① `tower/presentation/tower_entry_flow.dart` drop_service 调用移入 `tower/application/` 封装 ② `lib/core/application/battle_providers.dart` 中长期迁至 `features/battle/application/` ③ 其余维持现状

**closeout**:本批审计基线对齐 CLAUDE.md §3。20 feature 全扫,7 三层全,1 轻微 DDD 偏差,0 命名违规。
