# Week 15 · Phase 5 #2 DDD 目录整理 + 闭关 feature 试点 closeout

> 2026-05-15 · opus(xhigh + 用户拍板)· #30 收口后 Phase 5 主战场起步首批。
>
> **结论**:闭关 feature 完整迁到 `lib/features/seclusion/{domain,application,presentation}/`,3 屏全 Consumer 化,**#28 闭关 widget e2e 老挂账销账**(W6 drift 5 轮探路无解的硬骨头通过 fake service + `ProviderScope.overrides` 解了)。**653/653 测试**(原 649 → +4 e2e),analyze 0 issues。

---

## 1. 一句话结论

DDD 骨架建立,闭关 feature 试点完整迁移,#28 销账,迁移 cookbook 落地。后续 feature 照此样板批量迁。

## 2. 会话密度统计

- 起步:候选 6 选 1(用户拍板 A),细分方案 3 选 1(用户拍板方案 2)
- 侦察:1 轮 grep + 1 轮 import 关系
- 迁移:7 个 lib 文件 + 3 个 test 文件 git mv(`.g.dart` 走普通 mv 因 .gitignore)
- import 改:7 内部文件 + 5 外部文件(明显 4 + 隐藏 1:`numbers_config.dart`)
- Consumer 化:3 屏(`map_list/setup/active`)
- e2e widget test:1 新建文件 + 4 case
- 全测 0 regress

## 3. 用户拍板的 2 决策点

### 3.1 候选 A(Phase 5 #2 DDD 起步)

`#30` closeout §6.3 排序 6 候选,用户拍 A(xhigh + 用户拍板,3-5h)。理由:Phase 5 主战场起步 + 可顺路销 #28。

### 3.2 细分方案 2(DDD 骨架 + 闭关试点)

3 个细分方案:
- 方案 1:屏 Consumer 化优先(#28 老挂账) — 不动目录
- **方案 2:DDD 骨架 + 闭关试点(选定)** — 建样板
- 方案 3:全量 DDD 迁移 — 不推荐

用户拍方案 2,理由:Phase 5 真起步 + 顺路销 #28 + 后续 feature 有样板。

## 4. 代码改动清单

### 4.1 新建目录骨架

- `lib/core/`(空)
- `lib/features/seclusion/{domain,application,presentation}/`
- `lib/shared/`(空)
- `test/features/seclusion/{domain,application,presentation}/`
- `lib/features/README.md` cookbook(8 段:三层职责 / 闭关迁移路径 / 8 步迁移步骤 / 踩坑记录)

### 4.2 迁文件清单(10 个,git mv 9 + 普通 mv 1)

```
原                                                  新
─────────────────────────────────────────────────────────────────────────────────
lib/data/models/retreat_session.dart           → lib/features/seclusion/domain/retreat_session.dart            [git mv]
lib/data/models/retreat_session.g.dart         → lib/features/seclusion/domain/retreat_session.g.dart          [mv 普通 — .gitignore *.g.dart]
lib/data/defs/seclusion_map_def.dart           → lib/features/seclusion/domain/seclusion_map_def.dart          [git mv]
lib/services/seclusion_service.dart            → lib/features/seclusion/application/seclusion_service.dart     [git mv]
lib/ui/seclusion/seclusion_map_list_screen.dart → lib/features/seclusion/presentation/seclusion_map_list_screen.dart [git mv]
lib/ui/seclusion/seclusion_setup_screen.dart   → lib/features/seclusion/presentation/seclusion_setup_screen.dart    [git mv]
lib/ui/seclusion/active_retreat_screen.dart    → lib/features/seclusion/presentation/active_retreat_screen.dart     [git mv]
lib/ui/seclusion/retreat_result_screen.dart    → lib/features/seclusion/presentation/retreat_result_screen.dart     [git mv]
test/services/seclusion_service_test.dart      → test/features/seclusion/application/seclusion_service_test.dart    [git mv]
test/data/seclusion_map_def_test.dart          → test/features/seclusion/domain/seclusion_map_def_test.dart         [git mv]
test/ui/seclusion/seclusion_map_list_screen_test.dart → test/features/seclusion/presentation/seclusion_map_list_screen_test.dart [git mv]
```

`lib/ui/seclusion/` 和 `test/ui/seclusion/` rmdir 清掉。

### 4.3 改 import 清单(12 处)

**内部 import**(7 文件):3 个 domain/application 改互引 + 3 个 presentation 改相对路径 + 1 个 retreat_result_screen 改 ui/strings 路径。

**外部 import**(5 文件,grep 全仓后找出):
- `lib/data/game_repository.dart`:`defs/seclusion_map_def.dart` → `../features/seclusion/domain/seclusion_map_def.dart`
- `lib/data/isar_setup.dart`:`models/retreat_session.dart` → `../features/seclusion/domain/retreat_session.dart`
- `lib/data/numbers_config.dart`:`defs/seclusion_map_def.dart` → `../features/seclusion/domain/seclusion_map_def.dart`(隐藏 import,首轮 analyze 才暴露)
- `lib/ui/main_menu.dart`:`seclusion/seclusion_map_list_screen.dart` → `../features/seclusion/presentation/seclusion_map_list_screen.dart`
- `lib/providers/isar_provider.dart`:`../services/seclusion_service.dart` → `../features/seclusion/application/seclusion_service.dart`

**test import**(3 文件):`package:wuxia_idle/...` 路径全改新位置。

### 4.4 Consumer 化 3 屏

| 屏 | 旧 | 新 |
|---|---|---|
| seclusion_map_list_screen | StatefulWidget / State | ConsumerStatefulWidget / ConsumerState |
| seclusion_setup_screen | StatefulWidget / State | ConsumerStatefulWidget / ConsumerState |
| active_retreat_screen | StatefulWidget / State | ConsumerStatefulWidget / ConsumerState |

调用点改造:
- `IsarSetup.instanceOrNull` + `SeclusionService(isar: isar)` → `ref.read(seclusionServiceProvider)` + null check throw StateError
- 旧 `new SeclusionService(isar: IsarSetup.instance, encounterService: ...)` → `ref.read(seclusionServiceProvider)`(provider 已注入 EncounterService 自 W6/W14-2)

`retreat_result_screen` 保持 StatelessWidget(纯展示无 service 调用)。

### 4.5 e2e widget test 新建(4 case)

`test/features/seclusion/presentation/seclusion_e2e_test.dart`:

- `_FakeSeclusionService implements SeclusionService`(getter `isar` throw UnimplementedError,public 4 方法 + counter)
- `ProviderScope.overrides: [seclusionServiceProvider.overrideWithValue(fake)]`
- e2e #1:list 点山林 → push SetupScreen
- e2e #2:setup 点开始 → pushReplacement ActiveScreen + verify startCallCount=1
- e2e #3:active(done)点收功 → pushReplacement ResultScreen + verify completeCallCount=1
- e2e #4:active(未 done)点提前收功 → confirm dialog → 取消(completeCallCount=0)/确认(completeCallCount=1 + push Result)

**这是 W6 drift 5 轮探路无解的真解**:Consumer 化后 fake service 绕过 native Isar zone,fake_async 不再需要,直接 `tester.pump` / `tester.pumpAndSettle` 走通 e2e。

## 5. 测试与验证

- **闭关相关 49/49**(`test/features/seclusion/` 总 28 service + 14 def + 3 list widget + 4 e2e)
- **全测 653/653**(原 649 → +4 e2e)
- **analyze 0 issues**

## 6. 下次开局必读

### 6.1 状态快照

- HEAD 待 push(本会话末态待 commit)
- 653/653 测试 + analyze 0 issues
- §12 待决 2 条不变(#7 / #10)
- 闭关 feature 完整迁到 `lib/features/seclusion/`,**老结构 lib/ui/seclusion 和 lib/services/seclusion_service.dart 不再存在**
- 老挂账 #28 闭关 widget e2e **销账**(4 e2e widget test 全过)
- 其他 13 feature 未迁(`combat / data / providers / services / ui / utils` 留 flat 结构)

### 6.2 开局动作

1. 读 PROGRESS.md「当前阶段」+「下一步」+「挂账事项」
2. 读本 closeout §6 下次开局必读
3. `git pull --rebase --autostash` 看 drift

### 6.3 下波候选

| 候选 | 模型 | 时长 | 备注 |
|---|---|---|---|
| **A. 第 2 批 feature 迁移(tower / mainline / encounter)** | **xhigh + 拍板** | **4-6h** | 照闭关试点 cookbook 批量迁,后续 feature 模式一致 |
| B. service interface 抽离 + Mocktail 引入 | sonnet | 1-2h | 闭关 fake service 路径成熟后,可优化成正规 Mocktail 体例(implements concrete class 不优雅) |
| C. lib/core 抽公共代码 | sonnet | 1h | combat/formulas.dart 等纯函数迁 lib/core/combat/ |
| D. lib/shared 抽 UI 通用组件 | sonnet | 1-2h | tier_colors / screen_shake / 通用 dialog 迁 lib/shared/ |
| E. #34 stage drop 视觉验收 Pen 环境改善 | Codex 派 | 1h | 配 ≥1080 屏(老挂账) |
| F. Pen-only T64 test fail 排查 | sonnet | 30min | 老挂账 |
| G. techniqueLearnPoints / internalForcePoints 消费层接入 | opus | 2-3h | #30 新维度真正落到 Character/Technique 增长(需先评估 Demo 节奏) |

**推荐起手 A(xhigh + 拍板)**:Phase 5 主战场,DDD 整理一鼓作气批量迁。建议先迁 `tower`(15 个文件,体量与 seclusion 相当),再 `mainline`,最后 `encounter`(最复杂)。每个 feature 迁完独立 commit,渐进式销老结构。

### 6.4 硬约束(沿用 + W15 Phase 5 #2 新增)

- 不动 GDD.md / numbers.yaml 数值层 / IDS_REGISTRY.md / data_schema.md
- 不动 data/narratives/ data/lore/ data/events/(DeepSeek 领地)
- Mac 缺 Xcode 跑不了 flutter run -d macos,实战截图派 Pen Codex
- catch 块加 debugPrint / Isar @embedded List 写前 List.of 转 growable
- 不跨 service 嵌套 writeTxn / Dart extension 不与 List.add 同名签名冲突
- preset lore 按需 LoreLoader.load 不写 Isar;Equipment.lores 留延续典故
- 红线测试写「约束语义」不写「瞬时事实」
- closeout 涉及数字必须 grep 实测,加和也要复测
- 派单 spec 的「预期值」必须 grep 派单源头
- UI 字段读取:实例可与 def 不一致的字段一律读实例,def-level 不可变字段读 def
- 视觉验收 FAIL 字段类 1 行 fix → widget test 兜底
- Codex 双备份角色,默认三方隔离
- Pen GUI 长链路连续导航不稳 → 走干净启动 + fixture 路径
- 节气清单方案 A 公历 hardcode(W15 §12 收口决议)
- **#30 沿用**:闭关产出 4 维度全乘 `realmScale × solarBonus`,内力维度额外乘 `ziShiBonus`
- **#30 沿用**:乘数字段必须有 base 锚点(numbers.yaml retreat.base_*_per_hour)
- **Phase 5 #2 新增**:迁 feature 前先 grep 全仓 import(不只看明显 4 处,如 `numbers_config.dart` 隐藏 import 需 analyze 才暴露)
- **Phase 5 #2 新增**:`.g.dart` 在 .gitignore 中,迁文件时用普通 `mv` 而非 `git mv`,源 `.dart` 走 `git mv` 保 blame
- **Phase 5 #2 新增**:Riverpod codegen `.g.dart` 是 `part of` 同源 `.dart`,改源文件 import 后**不需要重跑 build_runner**(part of 不带 import)
- **Phase 5 #2 新增**:Consumer 化后 e2e widget test 用 `_FakeService implements ConcreteService` + `provider.overrideWithValue(fake)`,绕过 native Isar zone(fake_async 不再必要)

## 7. 教训沉淀

### 7.1 隐藏 import 必须 grep 全仓后再 analyze

明显外部 import 4 处(grep 外部直接 import 那 4 文件),改完跑 analyze **发现 `numbers_config.dart` 还引用了 `defs/seclusion_map_def.dart`**(用作类型注解 / 函数参数)。这种隐藏 import 不在直接 grep 范围,要通过 analyze 暴露。

**教训**:迁文件后必先 `flutter analyze`,看 `Target of URI doesn't exist` 错误,补完才能跑 test。不要 grep 几个引用点就以为完事。

### 7.2 .g.dart 文件迁移特殊处理

`*.g.dart` 在 `.gitignore` 中,直接 `git mv` 会 fail:`not under version control`。同时 .g.dart 一般和源 .dart 一起放,迁移时:

1. **先 mv `.g.dart`(普通 mv)**
2. **再 git mv `.dart`(保 blame)**
3. **不需要重跑 build_runner**(`part of '<source>.dart';` 是文件名引用,跟随源文件即可)

**教训**:批量 `git mv` 列表里夹一个 `.g.dart` 会让整批失败(本会话第一次踩这个,之后改成分两步)。

### 7.3 Consumer 化 + fake service 是 fake_async 边界的真解

`#28 闭关 widget e2e` 在 W6 drift 后被 5 轮探路标记为「fake_async vs native Isar zone 边界不可解」,留挂账等 Phase 5 #2 DDD 级真解。

实际真解路径:
- **3 屏 Consumer 化**:不再走 `SeclusionService(isar: IsarSetup.instance)`,改 `ref.read(seclusionServiceProvider)`
- **fake service implements concrete class**:`_FakeSeclusionService implements SeclusionService`,Isar getter throw UnimplementedError(fake 路径不访问)
- **ProviderScope.overrideWithValue(fake)** 注入
- **完全绕过 native Isar zone**,不再需要 fake_async,直接 `tester.pump()` / `tester.pumpAndSettle()` 走 e2e

**教训**:测试层面"不可解的边界"往往不是真的不可解,是依赖注入路径不到位让边界穿透到测试层。Consumer 化把边界封死在 provider override 之下,fake_async 就不再是必须。

### 7.4 迁移过程中保持渐进 verify

迁移 → analyze fix → analyze 0 → 全测 0 regress → Consumer 化 → analyze 0 → 全测 0 regress → 新 e2e test → 全测 0 regress + analyze 0。

**每步 verify** 是关键,如果一次性做 4 步再跑 test,debug 路径就乱了。本会话每两步一 verify,3 次 analyze + 3 次全测,每次都有明确锚点。

## 8. 文件清单

- `lib/features/README.md` cookbook(8 段)
- `docs/handoff/week15_phase5_2_ddd_seclusion_pilot_2026-05-15.md` 本 closeout
- 10 文件迁移(7 lib + 3 test)
- 12 处 import 改(7 内部 + 5 外部)
- 3 屏 Consumer 化
- 1 新建 e2e widget test 文件(4 case)
- PROGRESS.md 更新(#28 销账)
- `lib/data/models/retreat_session.dart` / `lib/data/defs/seclusion_map_def.dart` / `lib/services/seclusion_service.dart` 等老路径**已不存在**

---

**本 closeout 完。下次会话从 §6 开局动作起步,推荐 A 候选第 2 批 feature 迁移(xhigh + 用户拍板,4-6h),先 tower 后 mainline。**
