# W15 Phase 5 #3 lib 目录结构 finalization closeout(2026-05-16)

> Phase 5 #3 第 6 批 lib/ 目录最终对齐 CLAUDE.md §3,挂账 #2 销账。

## §1 任务背景

PROGRESS 挂账 #2「lib/ 目录结构:CLAUDE.md 写 DDD,实际用 phase1_tasks 的 flat。Phase 5 整理」自 W6 起记录,Phase 5 #3 第 1-5 批已完成 features 化主战场(11/14 feature 落地 + lib/services/ + lib/ui/{character_panel,inventory,technique_panel,enhancement,battle} + test/services/ + lib/ui/debug/ 消失 + 12 model → lib/core/domain/ + 3 跨 feature provider → lib/core/application/ + isar_provider 拆分),剩 lib/ui/ + lib/utils/ + lib/providers/ + 空目录残留与 CLAUDE.md §3 设计不完全对齐。本批一次性收尾。

## §2 Phase 0 grep 双维度

按 memory `feedback_phase0_grep_two_axes`,两维度扫:

**Schema 维度(目录残留)**

| 残留 | 内容 | §3 归属 |
|---|---|---|
| `lib/data/models/` | 空目录(12 model 第 4 批已迁) | 删 |
| `lib/data/defs/` | 7 个 yaml schema def(56 caller) | 留 `lib/data/`(§3「yaml 加载」) |
| `lib/data/` 顶层 | 6 个 yaml loader / Isar setup / repo / config(130 caller) | 留 `lib/data/` |
| `lib/providers/` | isar_provider(5)+ rng_provider(3)+ 2 codegen | 拆 |
| `lib/shared/` | 空目录 | 接收主题/工具 |
| `lib/ui/` | main_menu / strings / effects / narrative / theme 5 类(76 caller) | 拆 |
| `lib/utils/` | rng.dart(20 caller) | 迁 shared |

**Caller 维度(影响面)**

| 文件 | callers | 决策 |
|---|---|---|
| ui/strings.dart | 35 | shared/strings.dart |
| ui/theme/colors.dart | 28 | shared/theme/colors.dart |
| ui/theme/tier_colors.dart | 5 | shared/theme/tier_colors.dart |
| ui/effects/screen_shake.dart | 3 | shared/effects/screen_shake.dart |
| ui/main_menu.dart | 2 | features/main_menu/presentation/main_menu.dart |
| ui/narrative/narrative_reader_screen.dart | 3 | features/narrative/presentation/narrative_reader_screen.dart |
| providers/isar_provider.dart | 5 | data/isar_provider.dart |
| providers/rng_provider.dart | 3 | shared/utils/rng_provider.dart |
| utils/rng.dart | 20 | shared/utils/rng.dart |

## §3 10 step 分批 commit

| Step | commit | 内容 | 影响 |
|---|---|---|---|
| 1 | `6c3eab4` | 删 lib/data/models 空目录 + test/data/models 2 test 文件迁 test/core/domain/ | 0 lib 改 |
| 2 | `9173ced` | lib/ui/theme/ → lib/shared/theme/ | 30 文件(27 lib + 3 rename),漏 2 处相对路径 import 二次修 |
| 3 | `c425bdb` | lib/ui/effects/ → lib/shared/effects/ | 4 文件 |
| 4 | `b02c8b5` | lib/ui/strings.dart → lib/shared/strings.dart | 37 文件(23 features + 11 test + main_menu 同目录) |
| 5 | `53fa94a` | lib/utils/rng.dart → lib/shared/utils/rng.dart | 21 文件(顺手命中 rng_provider 内部 import) |
| 6 | `0755b65` | lib/ui/narrative/ → lib/features/narrative/presentation/(新建 feature) | 4 文件,内部 imports 深度 +1 + caller 改跨 feature peer |
| 7 | `1708a84` | lib/providers/rng_provider → lib/shared/utils/rng_provider | 4 文件 + .g.dart gitignored mv,part 同目录不破 |
| 8 | `227db0d` | lib/providers/isar_provider → lib/data/isar_provider | 7 文件 + .g.dart mv |
| 9 | `0426145` | lib/ui/main_menu.dart → lib/features/main_menu/presentation/ | 4 文件,深度 1→3 调 11 处 internal imports + 顺手 phase2_test_menu_test 归位 test/features/debug/presentation/ |
| 10 | rmdir | 删 3 空目录(lib/ui/ + lib/providers/ + test/ui/) | 0 commit |

## §4 最终 lib/ 结构(完美对齐 CLAUDE.md §3)

```
lib/
├── core/
│   ├── application/    # 3 跨 feature providers(battle/character/inventory)
│   └── domain/         # 12 model + extension
├── data/               # yaml 加载、Isar 仓储
│   ├── defs/           # 7 yaml schema def
│   ├── *.dart          # game_repository / isar_setup / numbers_config / loaders / yaml_loader / isar_provider (本批迁入)
│   └── *.g.dart        # isar_provider.g.dart(gitignored)
├── features/           # 14 feature(11 已迁 + main_menu + narrative + 早期 11)
│   └── <feature>/{domain,application,presentation}/
├── shared/             # 跨 feature 复用(主题、组件、工具)
│   ├── effects/        # screen_shake
│   ├── strings.dart    # UiStrings 全局文案
│   ├── theme/          # colors + tier_colors
│   └── utils/          # rng + rng_provider + .g.dart
└── main.dart           # entry
```

**lib/ui/ + lib/utils/ + lib/providers/ + lib/data/models/ + lib/shared/(空)5 个"非 §3 设计"目录全部消失。**

## §5 验收

- **723/723 全过**(每 step 都 verify 过)
- **flutter analyze 0 issues**(每 step 都过)
- **9 个 commit + 1 个 rmdir-only step**,每步独立可回滚
- **0 codegen regen**:isar_provider.g.dart + rng_provider.g.dart 的 `part of` 都是同目录引用,主件迁完 .g.dart 跟着 mv 即可,无需 build_runner

## §6 新经验 / cookbook 复证

### 新经验 1 条

**§6.1 子串替换的盲点:同目录与同名相对路径不含目录子串**

Step 2 子串替换 `ui/theme/colors.dart` → `shared/theme/colors.dart` 命中 28 caller,但漏 2 处:

1. `lib/ui/main_menu.dart` 用 `import 'theme/colors.dart';`(同目录,无 `ui/` 前缀)
2. `lib/ui/narrative/narrative_reader_screen.dart` 用 `import '../theme/colors.dart';`(1 层 ../,无 `ui/`)

被 analyze 暴露 `Undefined name 'WuxiaColors'` 后才补修。**教训:全仓 sed 后第 1 次 analyze 是漏改雷达**(memory `feedback_batch_sed_analyze_radar` 复证 N+1 次)。Phase 0 caller grep 用 `import.*ui/theme/colors\.dart` 模式扫不到这两个形式,应该加 `import.*['\"][^'\"]*theme/colors\.dart` 这种宽松形式作 verify pass。

### 复证教训

- `feedback_phase0_grep_two_axes`:schema + caller 双维度扫准,本批 9 文件迁移每步预估 caller 全准
- `feedback_git_mv_perl_stage`:每步 `git add -u` 把 perl 改的内容 stage 入 commit,B 教训完全内化
- `feedback_batch_sed_analyze_radar`:全仓 sed 后 analyze 雷达,Step 2 暴露 2 处漏改成本仅 +30s
- `feedback_avoid_over_engineer_abstraction`:本批未做任何抽象升级,纯目录搬迁,YAGNI
- `feedback_riverpod_codegen_provider_split`:codegen `part of` 同目录引用,主件迁完 .g.dart 跟着 mv 无 regen 需求

## §7 销账

- **PROGRESS 挂账 #2 → 销账**(2026-05-16)
- Phase 5 #3 主战场 11/14 → **14/14 完整收口**(本批 + main_menu + narrative)
- lib/ 目录与 CLAUDE.md §3 设计 **100% 对齐**

## §8 下一步建议

W15 + Phase 5 完整收口里程碑。剩余挂账(#3/#9-11/#17/#31/#37)均长期低优先无紧迫感。下波建议:

- **停手等下一里程碑**(W16 新章节 / 1.0 扩展系统启动 — GDD §12 接口预留)
- **C backlog**:mainline+tower victory e2e widget integration test(sonnet 1-2h,性价比偏低易撞 #31 同款坑)
