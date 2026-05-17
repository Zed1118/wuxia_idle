# lib/ 目录结构审计 vs CLAUDE.md §3（2026-05-17）

> Nightshift T05 产出。预期 0 漂移（Phase 5 #3 第 6 批 finalization 销账后）。

## 0. 扫描范围

- 工作树：`/Users/a10506/Desktop/wuxia-idle-T05`（基于 main HEAD `fc25207`，branch `nightshift/T05`）
- 输入：`lib/` 全树 + `CLAUDE.md` §3 锚点
- 扫描时间：2026-05-17
- 生成文件工具：`find lib/ -type d | sort` + `find lib/ -type f -name "*.dart" -not -name "*.g.dart" | sort`

---

## 1. 目录树快照

```
lib/
├── main.dart
├── core/
│   ├── application/
│   │   ├── battle_providers.dart
│   │   ├── character_providers.dart
│   │   └── inventory_providers.dart
│   └── domain/
│       ├── attributes.dart
│       ├── character.dart
│       ├── enums.dart
│       ├── equipment.dart
│       ├── forging_slot.dart
│       ├── game_event.dart
│       ├── inventory_item.dart
│       ├── lore.dart
│       ├── reward_entry.dart
│       ├── save_data.dart
│       ├── skill_usage_entry.dart
│       └── technique.dart
├── data/
│   ├── defs/
│   │   ├── drop_entry.dart
│   │   ├── equipment_def.dart
│   │   ├── master_def.dart
│   │   ├── realm_def.dart
│   │   ├── skill_def.dart
│   │   ├── stage_def.dart
│   │   └── technique_def.dart
│   ├── game_repository.dart
│   ├── isar_provider.dart
│   ├── isar_setup.dart
│   ├── lore_loader.dart
│   ├── narrative_loader.dart
│   ├── numbers_config.dart
│   └── yaml_loader.dart
├── features/
│   ├── battle/          [domain ✓ application ✓ presentation ✓]
│   ├── character_panel/ [domain ✗ application ✓ presentation ✓]
│   ├── cultivation/     [domain ✗ application ✓ presentation ✓]
│   ├── debug/           [domain ✗ application ✓ presentation ✓]
│   ├── dispel/          [domain ✗ application ✓ presentation ✗]
│   ├── encounter/       [domain ✓ application ✓ presentation ✓]
│   ├── equipment/       [domain ✗ application ✓ presentation ✓]
│   ├── festival/        [domain ✗ application ✓ presentation ✗]  ← W16 新增
│   ├── inventory/       [domain ✗ application ✗ presentation ✓]
│   ├── main_menu/       [domain ✗ application ✗ presentation ✓]
│   ├── mainline/        [domain ✓ application ✓ presentation ✓]
│   ├── narrative/       [domain ✗ application ✗ presentation ✓]
│   ├── seclusion/       [domain ✓ application ✓ presentation ✓]
│   ├── technique_panel/ [domain ✗ application ✗ presentation ✓]
│   └── tower/           [domain ✓ application ✓ presentation ✓]
└── shared/
    ├── effects/
    │   └── screen_shake.dart
    ├── theme/
    │   ├── colors.dart
    │   └── tier_colors.dart
    ├── utils/
    │   ├── rng.dart
    │   └── rng_provider.dart
    └── strings.dart
```

---

## 2. 15 feature 子目录三态完整性

| feature | domain/ | application/ | presentation/ | 备注 |
|---|---|---|---|---|
| battle | ✓ | ✓ | ✓ | 全三层 |
| character_panel | ✗ | ✓ | ✓ | 无 domain/，非漂移（UI 层 feature） |
| cultivation | ✗ | ✓ | ✓ | 无 domain/，非漂移 |
| debug | ✗ | ✓ | ✓ | 无 domain/，非漂移（开发辅助 feature） |
| dispel | ✗ | ✓ | ✗ | 无 domain/ 无 presentation/；UI 在 `technique_panel/presentation/dispel_dialog.dart`，非漂移 |
| encounter | ✓ | ✓ | ✓ | 全三层 |
| equipment | ✗ | ✓ | ✓ | 无 domain/，非漂移 |
| **festival** | **✗** | **✓** | **✗** | **W16 新增，仅 application/；Phase 5 #3 finalization 基线外** |
| inventory | ✗ | ✗ | ✓ | 纯 UI feature，非漂移 |
| main_menu | ✗ | ✗ | ✓ | 纯 UI feature，非漂移 |
| mainline | ✓ | ✓ | ✓ | 全三层 |
| narrative | ✗ | ✗ | ✓ | 纯 UI feature，非漂移 |
| seclusion | ✓ | ✓ | ✓ | 全三层 |
| technique_panel | ✗ | ✗ | ✓ | 纯 UI feature，非漂移 |
| tower | ✓ | ✓ | ✓ | 全三层 |

全三层：battle / encounter / mainline / seclusion / tower（5 个）

---

## 3. §3 期望对账

| 期望 | 状态 | 备注 |
|---|---|---|
| `lib/main.dart` 存在 | ✓ | — |
| `lib/core/domain/` 存在 | ✓ | 12 个领域实体 |
| `lib/core/application/` 存在 | ✓ | 3 个跨 feature provider |
| `lib/data/defs/` 存在 | ✓ | 7 个 def 类 |
| `lib/data/isar_provider.dart` 存在 | ✓ | — |
| `lib/data/` 其余基础设施 | ✓ | `yaml_loader / numbers_config / game_repository / isar_setup / lore_loader / narrative_loader` |
| `lib/features/` 存在 | ✓ | — |
| `lib/features/` feature 数量 | **⚠ 15（期望 14）** | `festival` 为 W16 finalization 基线外新增，见漂移清单 |
| `lib/shared/effects/` 存在 | ✓ | `screen_shake.dart` |
| `lib/shared/theme/` 存在 | ✓ | `colors.dart` + `tier_colors.dart` |
| `lib/shared/utils/` 存在 | ✓ | `rng.dart` + `rng_provider.dart` |
| `lib/shared/strings.dart` 存在 | ✓ | — |
| **不应存在** `lib/ui/` | ✗（正确，不存在） | Phase 5 #3 已迁出 |
| **不应存在** `lib/utils/` | ✗（正确，不存在） | Phase 5 #3 已迁出 |
| **不应存在** `lib/providers/` | ✗（正确，不存在） | Phase 5 #3 已迁出 |
| **不应存在** `lib/services/` | ✗（正确，不存在） | Phase 5 #3 已迁出 |
| **不应存在** `lib/data/models/` | ✗（正确，不存在） | Phase 5 #3 已迁出 |
| feature 直接持有 `.dart`（不经子目录） | ✗（正确，不存在） | 全部文件均在 domain/application/presentation/ 内 |
| `.g.dart` 文件 | ✗（正确，不存在） | build_runner 尚未运行，无生成文件 |

---

## 4. 漂移清单

### 漂移 #1：`lib/features/festival/` — Phase 5 #3 finalization 基线外新增

- **性质**：feature count 从 14 增至 15
- **路径**：`lib/features/festival/application/festival_service.dart` + `lib/features/festival/application/festival_service_providers.dart`
- **来源**：W16（2026-05-16）节日活动 chip 视觉验收（`codex_dispatch_w16_festival_chip_visual_check_2026-05-16.md`）于 Phase 5 #3 第 6 批 finalization 同日写入
- **风险评估**：结构合规（`application/` 子目录）；无 `domain/` 和 `presentation/` 但业务合理（节日逻辑 service-only，UI 在 character_panel 内嵌）；无 `lib/` 顶层新增，不违反 §3 顶层约束
- **处置建议**：将 `festival` 补录进下一版 CLAUDE.md §3 的 feature 清单（feature count 从 14 改为 15）；若后续补 presentation/ 需同步三层

### 其他观察（不计入漂移）

- `lib/features/battle/domain/enum_localizations.dart` 位于 `battle/domain/` 而非 §12.2 #1 文字注释所引用的 `lib/data/enum_localizations.dart`：这是 §12.2 文档注释过时（路径已在 Phase 5 #3 迁移期间变化），不影响 §3 结构合规性。建议 §12.2 #1 注释更新路径引用。
- 10 个 feature 缺少完整三层（无 domain/ 或无 presentation/）：均为业务合理的层省略，§3 期望格式为参考而非强制全层，不算漂移。

---

## 5. 审计结论

**1 漂移**（feature count：15 实际 vs 14 Phase 5 #3 基线期望）。

漂移项 `festival` 为 W16 正常迭代新增，结构合规（遵循 features/<X>/application/ 子目录约定），无顶层污染，无 forbidden 目录残留。Phase 5 #3 第 6 批 finalization 的「0 漂移」承诺在 finalization 时点仍成立；漂移发生在 W16 同日后续提交。

---

## 6. 后续维护建议

1. **CLAUDE.md §3 更新**：feature 数量注释从"14"改为"15"，补录 `festival`
2. **W18+ 新增 feature**：严格 `lib/features/<new>/{domain,application,presentation}/` 约定，即便只实现部分层也需在审计日志中记录原因
3. **任何 lib/ 顶层新文件**：必须在 CLAUDE.md §3 表内注明或新加锚点，否则下次审计计漂移
4. **§12.2 #1 文档修正**：将 `lib/data/enum_localizations.dart` 路径引用更新为 `lib/features/battle/domain/enum_localizations.dart`
5. **定期审计脚本建议**（`.nightshift/prompts/T05.verify.sh` 风格）：
   ```bash
   # 检查 forbidden 顶层目录
   for d in ui utils providers services; do
     [ -d "lib/$d" ] && echo "DRIFT: lib/$d exists" || echo "OK: lib/$d absent"
   done
   # 检查 data/models
   [ -d "lib/data/models" ] && echo "DRIFT: lib/data/models exists" || echo "OK: lib/data/models absent"
   # 统计 feature 数
   echo "feature count: $(ls lib/features/ | wc -l | tr -d ' ')"
   ```
