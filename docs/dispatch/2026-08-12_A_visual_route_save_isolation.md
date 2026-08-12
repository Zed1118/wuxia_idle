# 派单 A · 视觉路由 Isar 与生产存档隔离(BACKLOG 二#12)

- **执行端**:kimi · **性质**:debug 基建修复 + 测试,**改 `lib/features/debug/` 与 `test/`**
- **worktree**:`/Users/a10506/Desktop/Projects/挂机武侠/.claude/worktrees/afk-a-visual-isolation` · **分支**:`fix/visual-route-save-isolation`
- **基线**:`480c0248`(= origin/main)· **日期**:2026-08-12 夜批
- **worktree 已预热**(`libisar.dylib` 已拷、`pub get` 已跑)。若 `flutter test` 报 `.g.dart` 找不到,先跑 `dart run build_runner build --delete-conflicting-outputs`。

## 一、任务背景(自包含,执行端无本方上下文)

本仓是 Flutter Desktop 写实武侠挂机游戏,用 Isar 做本地存档。游戏有 3 个存档槽,文件名 `wuxia_save_slot{1,2,3}.isar`,生产落在 `getApplicationDocumentsDirectory()`。

仓里有一套「视觉验收路由」(visual route):用 `--dart-define=VISUAL_ROUTE=<id>` 或 `--visual-route=<id>` 启动 app,直达某个界面并冻结成可截图的状态,供美术/UI 验收。入口是 `lib/features/debug/presentation/visual_route_host.dart`。

## 二、缺陷(已由派单方实锤,当作判据锚点,不必重新论证)

**根因**:`lib/features/debug/presentation/visual_route_host.dart:204` 调用

```dart
await IsarSetup.init();
```

**不传 `directory`**。而 `lib/data/isar_setup.dart:206-213` 的签名是:

```dart
static Future<void> init({
  int slotId = 1,
  Directory? directory,
  bool inspector = true,
}) async {
  ...
  final dir = directory ?? await getApplicationDocumentsDirectory();
```

⇒ **视觉路由打开的是玩家真实存档 slot 1**。

### 危害一:静默迁移存档版本(已实证)

2026-08-11 23:46 跑 `wuxia_idle --visual-route=lineage_character_detail`(仅为验证路由能起),
`~/Library/Containers/com.pen.wuxia.wuxiaIdle/Data/Documents/wuxia_save_slot1.isar` mtime 变 `23:46:31`,
`saveVersion` 被迁到 `0.39.0`(slot2/3 未动)。平时无感(版本一致时迁移是 no-op),但**只要分支上有 saveVersion bump,跑一次视觉验收就把生产档顶到未来版本,main 构建再也打不开**(`_ensureSaveData` 见存档版本高于程序版本抛 `UnsupportedSaveVersionException`)。

### 危害二:清空玩家业务表(本单新查实,比 BACKLOG 原登记严重一档)

`lib/features/debug/application/phase2_seed_service.dart:1052-1058`:

```dart
Future<void> _clearAll() async {
  await isar.characters.clear();
  await isar.equipments.clear();
  await isar.techniques.clear();
  await isar.inventoryItems.clear();
  await isar.gameEvents.clear();
}
```

`_clearAll()` 被 6 个 seed 方法调用(`phase2_seed_service.dart:58 / :83 / :115 / :171 / :233 / :271`),
而 `visual_route_host.dart:204` 递给它们的正是**生产 Isar 实例**。
⇒ 跑一条会 seed 的视觉路由(如 `technique_panel_tier_all`、`character_panel_growth`、`sect_screen_npc`)
= **清空玩家全部角色 / 装备 / 心法 / 道具 / 事件记录**。

## 三、关键前置事实(派单方已核实,直接用,不要再花时间验证)

**没有任何视觉路由依赖真实存档数据**——每条碰 Isar 的路由都自带 seed:

- `Phase2SeedService(isar: isar).seedXxx()` 系列(`visual_route_host.dart:339 / :342 / :349 / :353-355 / :358 / :367` 等)
- `OnboardingService(isar: isar).ensureFoundingMasters(...)`(`:315-317 / :323-325 / :331-333 / :361-363 / :370-372 / :375-377` 等)
- `_seedCleanMainMenu(isar)`(定义在 `visual_route_host.dart:1397-1407`)
- `_seedInventoryItem(isar, ...)`(`:1123 / :1128 / :1133-1135 / :1140-1144` 等)

`visual_route_host.dart` 里 seed 调用点合计 **33 处**(`grep -c` 实测)。

⇒ **换成空的隔离目录不会让任何路由变哑**。这是本单能安全做的前提。
若你在实现中发现**反例**(某条路由读真实存档且不自带 seed),**停下走 §七 [BLOCKED]**,不要自己发明兜底。

## 四、要做的改动(方案已由派单方拍板,按此实现)

### 4.1 目录隔离

1. 在 `lib/features/debug/` 下新增一个**具名、可测**的目录解析函数(命名自定,建议 `visualRouteIsarDirectory()`),语义:
   - 返回 `${Directory.systemTemp.path}` 下的固定子目录,建议名 `wuxia_idle_visual_routes`
   - **每次进程启动先递归删除该目录再重建**,即每次跑视觉路由都是干净空库
   - 绝不返回 `getApplicationDocumentsDirectory()`
2. `visual_route_host.dart:204` 改成把该目录传进 `IsarSetup.init(directory: ...)`。
3. 启动时打一行 `debugPrint`,把实际使用的隔离目录路径打出来(供截图脚本日志留证)。前缀沿用本文件既有 `VISUAL_ROUTE_` 体例,例如 `VISUAL_ROUTE_ISAR_DIR: <path>`。

**为什么是「每次启动清空」而不是「持久复用」**:视觉路由要的是确定性帧。部分路由(如 `shop` 系列的 `_seedInventoryItem`)**只增不清**,复用同一个库会让上一条路由的 fixture 漏进下一条,正是 memory 记过的「seed 复用同库第二跑撞唯一性」那类坑。清空即从根上消除。

**并发注意**:固定目录名意味着两个视觉路由进程同时跑会互相清库。当前截图管线是串行的,可接受;请在函数 doc 注释里写明这条限制(**只写注释,不要为此加锁或改管线**——超出本单范围)。

### 4.2 测试(硬要求)

新增测试,至少覆盖:

1. **目录语义**:该函数返回路径在 `Directory.systemTemp` 之下;不等于、也不在 app documents 目录之下。
2. **清空语义**:预先在目标目录放一个哨兵文件 → 调用该函数 → 哨兵文件不存在(证明真的重建了)。
3. **生产调用点已接线**:断言 `visual_route_host.dart` 的 Isar 初始化路径确实传了 directory。
   - 优先做成**行为断言**;若无法在不起 app 的前提下行为验证,允许退化成对 `visual_route_host.dart` 源码的静态守卫(本仓有同类体例:`test/data/pubspec_asset_declaration_test.dart`),但**必须断言得足够紧**——「不含裸 `IsarSetup.init()` 调用」这种,要保证把 `directory:` 参数删掉时它必然红。

**破坏证红是交付条件**:每条新断言都要实测「把对应那行生产代码改坏 → 该断言必红 → 还原 → 复绿」,把三态的实际输出贴进交付说明。**没做破坏证红的测试视为未交付。**

自检判据(本仓硬规矩):**「破坏那行生产代码,这条断言必然红吗?」** 答不出「必然红」的断言不要写。

## 五、验收标准(派单方会逐项复跑,数字必须实测)

1. `flutter analyze --no-pub` → `No issues found!` exit 0(贴输出)
2. targeted:新增测试文件 + `test/` 下与 visual route / debug 相关的既有测试,**逐文件单独跑**并确认每个都出现 `All tests passed`(本仓有「多路径批跑静默漏跑」的实录,禁一条命令塞多个路径然后只看末尾)
3. **不跑全量**(本单自包含,守项目 §8.0 测试节奏;全量由派单方批末统一跑)
4. `dart format` 已跑(CI 有 format 门禁,漏跑必红)
5. 交付说明里写清:改了哪些文件、新增几条断言、三次破坏证红的实际输出、残留风险

## 六、边界约束(硬)

- **禁区文件,一个都不许碰**:`data/numbers.yaml`、`GDD.md`、`PROGRESS.md`、`lib/shared/strings.dart`、`pubspec.yaml`
- **禁 push、禁 merge、禁碰 main、禁 revert**。只在本 worktree 的 `fix/visual-route-save-isolation` 分支上 commit。
- **不许改 `lib/` 下 `features/debug/` 以外的生产代码**。特别是**不要改 `lib/data/isar_setup.dart`**——它的 `directory` 参数已经是对的,缺的是调用点没传。
- **不要顺手改 `phase2_seed_service.dart` 的 `_clearAll` 语义**。seed 服务在隔离库里清空是正确行为,问题从来在于库是哪个。
- **不许动用户真实存档**:不要为了验证而去读/写/删 `~/Library/Containers/com.pen.wuxia.wuxiaIdle/Data/Documents/` 下任何文件。
- **不要跑 `flutter run` / `flutter build macos` / 视觉截图脚本**去"实地验证"——在修好之前跑它正是本单要消灭的危险动作,修好之后跑它属于派单方的复核环节。用测试证明,不要用真机跑证明。
- commit message 用**中文动宾**结构(英文 conventional 前缀如 `fix:` 属违规,合并 Gate 会查)。
- 交付时:工作区必须干净(全 commit),分支 **tip commit 消息以 `[READY]` 开头**,格式如 `[READY] 隔离视觉路由 Isar 目录与生产存档`。

## 七、[BLOCKED] 出口

以下任一情况,**立刻停下**,把分支 tip commit 消息前缀打成 `[BLOCKED]` 并在交付说明写清困惑点与已掌握证据,**禁止硬做**:

- 发现某条视觉路由确实依赖真实存档数据(与 §三 的前置事实矛盾)
- 隔离后有既有测试变红,且修法需要改 `lib/features/debug/` 以外的生产代码
- 需要改 saveVersion、schema、迁移逻辑才能推进
- 需要改玩家可见 UI 或数值配置才能推进
- 任何你拿不准是否越过 §六 边界的改动

拿不准就冻结,不要硬做——夜里没人能给你拍板,硬做的代价比停下高。
