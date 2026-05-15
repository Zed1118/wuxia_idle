# lib/features/ DDD 分层约定

> Phase 5 #2 DDD 目录整理起步,首批试点:`seclusion`(W15 闭关 feature)。
> 其他 feature 留下波按本 cookbook 批量迁。

## 三层职责

| 层 | 内容 | 依赖方向 |
|---|---|---|
| `domain/` | Isar collection(`@Collection`)/ def class(`SeclusionMapDef`)/ 纯 Dart 值对象、枚举 | 只依赖 `isar_community`、`package:meta`,**不依赖 Flutter/Riverpod** |
| `application/` | service(无 widget 依赖)/ provider(Riverpod)/ use-case | 依赖 `domain/` + `core/` + 其他 feature 的 `application/`(谨慎) |
| `presentation/` | Widget / Screen / Consumer | 依赖 `application/` provider,**不直接 new service** |

## 闭关试点迁移路径

```
原                                             新
─────────────────────────────────────────────────────────────────────────
lib/services/seclusion_service.dart         → lib/features/seclusion/application/seclusion_service.dart
lib/data/models/retreat_session.dart        → lib/features/seclusion/domain/retreat_session.dart
lib/data/models/retreat_session.g.dart      → lib/features/seclusion/domain/retreat_session.g.dart
lib/data/defs/seclusion_map_def.dart        → lib/features/seclusion/domain/seclusion_map_def.dart
lib/providers/isar_provider.dart 抽出       → lib/features/seclusion/application/seclusion_providers.dart
lib/ui/seclusion/*.dart × 4                 → lib/features/seclusion/presentation/*.dart
test/* 镜像迁                                → test/features/seclusion/{domain,application,presentation}/*
```

## 迁移步骤(cookbook)

1. **建空骨架**:`mkdir -p lib/features/<feature>/{domain,application,presentation}`
2. **git mv** 文件保 blame
3. **改文件内 import**(相对路径 `../data/` → 跨层走包路径或 `../../`)
4. **改外部 import**:grep 旧路径,批量改新路径
5. **provider 抽离**:从 `isar_provider.dart` 把对应 service provider 抽到 `features/<feature>/application/<feature>_providers.dart`,`isar_provider.dart` re-export 一段时间(便于其他未迁 feature 引用)
6. **跑 build_runner** 重生成 .g.dart(Isar / Riverpod codegen)
7. **跑 flutter test + analyze** 确认 0 regress
8. **更新 cookbook**:如果遇到新坑,加到本文件「踩坑记录」段

## 踩坑记录(W15 试点)

### 1. 隐藏 import:`numbers_config.dart` 也引用了 def

明显外部 import 直接 grep 出来 4 处,改完发现 analyze 还报 `Target of URI doesn't exist`。原因:`numbers_config.dart` 把 def 作为类型注解(`List<SeclusionMapDef>`)用。

**经验**:迁文件后必先 `flutter analyze`,补完隐藏 import 才跑 test。

### 2. `.g.dart` 不在 git,git mv 会 fail

`.gitignore` 写了 `*.g.dart`,build_runner 生成的文件不入 git。批量 `git mv` 列表里夹一个 `.g.dart` 让整批 fail。

**经验**:分两步:
1. 普通 `mv` 处理 `.g.dart`
2. `git mv` 处理 `.dart`(保 blame)

不需要重跑 build_runner:`.g.dart` 是 `part of '<source>.dart';`,文件名引用跟随源文件即可。

### 3. Riverpod `*Provider.g.dart` 不需要重跑

`isar_provider.g.dart` 头部仅 `part of 'isar_provider.dart';`,改 `isar_provider.dart` 的 import 路径**不会**让 `.g.dart` 失效(part of 不带 import)。

**经验**:Riverpod codegen 迁移友好,只动源文件 import 即可。

### 4. Consumer 化是 fake_async 边界的真解

W6 drift 时,3 屏没 Consumer 化导致 widget e2e 撞 native Isar zone 边界,fake_async 控不住,5 轮探路无解。Consumer 化后 fake service 通过 `ProviderScope.overrideWithValue` 注入,完全绕过 Isar,fake_async 不再必要,直接 `tester.pump()` / `pumpAndSettle()` 走 e2e。

**经验**:测试层面"不可解的边界"往往是依赖注入路径不到位。Consumer 化是真解。

### 5. fake service `implements ConcreteService` 写法

没装 mocktail / mockito,手写 fake:
- `class _FakeService implements SeclusionService`
- `Isar get isar => throw UnimplementedError('fake: 不应被访问');`
- public 方法直接实现 + counter / factory 字段记录被调用情况

后续 feature 迁移时,如果 fake 需求增加,可考虑引入 mocktail(`dev_dependencies: mocktail: ^1.0.0`)规范化。

