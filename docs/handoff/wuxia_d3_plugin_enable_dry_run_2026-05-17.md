# D-#3 riverpod_lint plugin 启用本地预演结果(2026-05-17)

> 目的:挂账 #3 半销账 follow-up 估算 validate(W17 D-#3 期间估「启用后 3 处 dependency 标注」)。
> 操作:本地分支不 commit/push,纯 dry run 验估算准不准。

---

## 1. 预演步骤实测

### Step 1 · 启用 plugin

`analysis_options.yaml` 加:
```yaml
plugins:
  riverpod_lint: ^3.1.3
```

跑 `dart analyze`:**1 warning**
- `test/features/tower/presentation/tower_entry_flow_test.dart:53:9` — Scoped providers must specify a list of dependencies. `scoped_providers_should_specify_dependencies`

### Step 2 · 给 `towerProgress` 加 `@Riverpod(dependencies: [])` + 重生 codegen

```dart
// lib/features/tower/application/tower_providers.dart:14
@Riverpod(dependencies: [])
Future<TowerProgress> towerProgress(Ref ref) async { ... }
```

跑 `dart run build_runner build`(6s),`dart analyze`:**3 warning**(级联放大)
- `lib/features/tower/application/tower_providers.dart:24` — Missing dependencies: `towerProgress` `provider_dependencies`(级联到同文件 `towerFloorList`)
- `lib/features/tower/presentation/tower_entry_flow.dart:36` — Missing dependencies: `towerProgress`(`runTowerFlow` 函数)
- `lib/features/tower/presentation/tower_floor_list_screen.dart:14` — Missing dependencies: `towerProgress`(`TowerFloorListScreen` widget)

### Step 3(未执行,只估算)· 给 3 处加 dependencies/`@Dependencies` 注解

**预估改动**:

| 位置 | 改法 | 改动量 |
|---|---|---|
| `tower_providers.dart:24` `towerFloorList` | `@riverpod` → `@Riverpod(dependencies: [towerProgress])` | 1 行 |
| `tower_floor_list_screen.dart:19` `TowerFloorListScreen` | class 上加 `@Dependencies([towerProgress])` + import riverpod_annotation | 2 行 |
| `tower_entry_flow.dart:48` `runTowerFlow` 函数 | 函数上加 `@Dependencies([towerProgress])` + import | 2 行 |

总:**5 行源码改动 + 1 次 build_runner build**。

### Step 4(未执行,只估算)· verify 收尾

- `flutter test` 全测应仍 763/763(预期 W17 DeepSeek 文案落地后)
- `dart analyze` 应 0 issues

---

## 2. 估算 vs 实际

| 维度 | D-#3 半销账估算 | 预演实测 | 偏差 |
|---|---|---|---|
| dependency 标注处数 | 3 处 | 3 处 | ✅ 一致 |
| 工作量估时 | 未明确(follow-up) | ~15 min(5 行改 + 1 次 codegen + verify) | ✅ 偏差小 |
| 需要 codegen | 是 | 是(towerProgress + towerFloorList 注解改) | ✅ |
| 引发新 warning | 不可控级联风险 | 0(3 处全是预期级联) | ✅ 风险可控 |

**结论**:D-#3 半销账估算**准确**,follow-up 实际工作量 ~15 min(原估时未量化,这里 validate 为 sonnet 15-20 min 任务,可单独打包顺手做)。

---

## 3. 触发时机推荐

D-#3 半销账描述里写「Phase 5+ 引入 family/scoped override 时再启用」。本预演印证:**实际启用门槛低**(15 min sonnet 任务),不必等 family。

**推荐**:W17 候选 B/E 闭环后,**作为 W17 polish 收尾任务顺手做掉**。或者下波启用 `family` 时再做(届时会有更多 scoped provider 需要标注,届时统一收口更省 codegen 次数)。

---

## 4. 工程教训

riverpod_lint 3.1.3 的 `provider_dependencies` 是「**级联放大 lint**」:任何 `@Riverpod(dependencies: [])` 的 provider,**所有下游 ref.watch/read 它的 widget/function/provider 都需要显式声明依赖**。一个 `dependencies: []` 标注会暴露 N 个下游 caller(本预演 1 个 root → 3 个下游)。

实战策略:
- 启用 plugin 前先 grep 所有 ProviderScope.overrides 触发点(预演里是 `towerProgressProvider`),数量决定根入口个数
- 每个根入口预估下游 3-5 caller
- 不要一次性全启,按 feature 分批做

---

## 5. 恢复操作

预演完成,本地全恢复:
```sh
# analysis_options.yaml plugins 段已加但未 commit
# tower_providers.dart towerProgress 注解已改但未 commit
# *.g.dart 已重生但 gitignored

git restore analysis_options.yaml lib/features/tower/application/tower_providers.dart
dart run build_runner build  # 恢复 .g.dart 到 @riverpod 版本
```

或简单:`git checkout -- .` 加 `dart run build_runner build`。

---

**预演文档结束。本预演不 commit/push 任何源码改动,只产文档证据。**
