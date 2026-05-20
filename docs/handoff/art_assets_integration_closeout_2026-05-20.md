# M4 PoC #46 美术 89 张 assets 归位 + Flutter UI 接入 closeout(2026-05-20)

> **scope**:Stage 2 量产收官后 89 张产物 → `assets/` 归位 + yaml schema 字段注册 + Flutter UI 3 处接入
> **节奏**:主对话 opus xhigh,**实测 ~40min**(spec 预估 1.5-2h,memory `feedback_opus_xhigh_interactive_duration` 又一次 1.7-3× 加速实证)
> **结果**:**Phase 1+2+3 全闭环** ✅ · 89 张全归位 / 6 个 schema 改动 / 3 处 UI 接入 / **flutter test 1123 pass / analyze 0 issues 维持 baseline**

---

## §1 时间线

| 时刻 | 事件 |
|---|---|
| T0 | 用户拍板候选 1 完整方案(Q1/Q2/Q3 全 A),升档 opus xhigh |
| T+5min | Phase 0 reality check 三维实查 — 89 张实清 / equipment.yaml 35 件 iconPath 已就绪 / detailPath/portraitPath/imagePath 字段未预留 / lib/ 0 处 Image.asset 接入 |
| T+10min | spec doc 锁定 + assets/ 4 目录就绪(本地 mkdir 我自己干 · memory `feedback_no_mkdir_dispatch`) |
| T+15min | Phase 1 89 张 cp + rename(bash 一波脚本化)完工 |
| T+25min | Phase 2 schema 6 项注册(equipment.yaml 35 件 detailPath perl 批量 / pubspec / 3 Dart def / numbers.yaml maps / masters.yaml)+ pub get + analyze + test 全通过 |
| T+35min | Phase 3 UI 3 处接入(地图缩略 + splash screen + home_feed seal 印章)+ underscore lint 修 6 处 |
| T+40min | analyze 0 issues + test 1123 pass 维持,closeout + PROGRESS + commit |

---

## §2 三 Phase 实装实测

### Phase 1 文件归位(89 张 → assets/)

| 目录 | 数 | 验证 |
|---|---|---|
| `assets/equipment/` | 70 张(35 件 × icon + detail) | ✅ |
| `assets/equipment/_alt/` | 1 张(01_tie_jian_icon_alt) | ✅ 归档 |
| `assets/characters/` | 3 张(founder / first_disciple / second_disciple) | ✅ |
| `assets/maps/` | 5 张(shanLin/guJianZhong/cangJingGe/xuanYaPuBu/duanYaJueBi) | ✅ |
| `assets/ui/` | 10 张(paper_bg / mountain_bg / scroll × 2 / seal / ink_divider / icons × 3 / loading) | ✅ |
| **合计** | **89 张** ✅ | |

**关键**:09/10/11 编号在 Stage 1 PoC(ruan_bian/bu_yi/yu_pei)和 Stage 2 W2(gang_dao/chang_jian/jiu_jie_bian)双胞胎,源目录隔离 + pinyin 命名差异 → cp 脚本零冲突 100% 正确归位。

### Phase 2 schema 注册(6 项改动)

| 文件 | 改动 | 验证 |
|---|---|---|
| `pubspec.yaml` | 加 `assets/equipment/` `assets/characters/` `assets/maps/` `assets/ui/` 4 行 | flutter pub get ✅ |
| `data/equipment.yaml` | 35 件加 `detailPath`(perl -i 批量,正则 `iconPath: assets/equipment/(\w+)\.png` → 后加 `detailPath: assets/equipment/$1_detail.png`) | grep -c "detailPath:" → 35 ✅ |
| `data/numbers.yaml` | retreat.maps[] 5 张加 `image_path`(snake_case) | Edit 5 处 ✅ |
| `data/masters.yaml` | 3 角色加 `portraitPath`(camelCase 沿 masters 约定) | Edit 3 处 ✅ |
| `lib/data/defs/equipment_def.dart` | `final String? detailPath` + factory parse | analyze ✅ |
| `lib/data/defs/master_def.dart` | `final String? portraitPath` + factory parse | analyze ✅ |
| `lib/features/seclusion/domain/seclusion_map_def.dart` | `final String? imagePath` + factory parse(读 yaml snake_case `image_path`) | analyze ✅ |

**字段命名约定保持**:`equipment.yaml` / `masters.yaml` 沿 camelCase / `numbers.yaml` 沿 snake_case(Dart factory parse 时按需转换)。memory `feedback_batch_sed_analyze_radar` 教训应用:perl -i 批量加字段后立即 analyze + test 两层校验,零漏改。

### Phase 3 UI 接入(3 处实装)

#### 3.1 `lib/features/seclusion/presentation/seclusion_map_list_screen.dart` _MapCard 加左侧地图缩略

`_MapCard` 卡片 Row 最前面新增 `Image.asset(def.imagePath!, width: 96, height: 64, fit: BoxFit.cover)`:
- `locked` 状态加 `BlendMode.darken` + 黑色 50% 透明覆盖,让锁定地图视觉灰化
- `errorBuilder` fallback 到默认 `Icons.landscape`(防 asset 加载失败 crash)
- `imagePath != null` 守卫:防 def 缺字段(向后兼容 nullable 设计)
- 5 张闭关地图大图 9.0/10 ⭐⭐⭐ Stage 2 最佳批全部消费

#### 3.2 新建 `lib/features/splash/presentation/splash_screen.dart` + main.dart wire

- 启动期间显示全屏 `assets/ui/landscape_loading.png`(50_landscape_loading 9.5/10 极品 · Stage 2 W6 最佳之一)
- 底部渐变遮罩 + 「挂机武侠」标题(letterSpacing 8 · 32px)+ CircularProgressIndicator
- `initState` 异步跑 `GameRepository.loadAllDefs()` + `IsarSetup.init()`(原 main.dart 同步阻塞 → 现在异步并行 + 视觉占位)
- 完成后 `Navigator.pushReplacement` 进 HomeFeedScreen
- `lib/shared/strings.dart` 新增 `appTitle = '挂机武侠'` 常量(GDD §5.6 红线 — 不硬编码中文)
- `main.dart` 改为 home: SplashScreen,移除原同步 loadAllDefs/IsarSetup 逻辑(迁入 SplashScreen)

#### 3.3 `lib/features/home_feed/presentation/home_feed_screen.dart` AppBar actions 加 seal_red 印章

- AppBar `actions:` 加 `Image.asset('assets/ui/seal_red.png', 36×36)` 右上角落款
- 上线首屏立刻有水墨克制氛围锚点(GDD §1 水墨基调)
- `errorBuilder` 兜底 `SizedBox.shrink()` 防 asset 失败破布局

**第 3 处替换原因**:Phase 0 grep 发现 `forging_panel.dart`(312 行)虽然接收 `EquipmentDef def`,**但 build 方法不显示装备 icon**(只显示词条选项)— 接 iconPath 无意义,改为 home_feed 印章接入(视觉收益更大)。

---

## §3 验收

- [x] `assets/equipment/` 70 张装备 + `_alt/` 1 张 = 71 张
- [x] `assets/characters/` 3 张立绘
- [x] `assets/maps/` 5 张地图
- [x] `assets/ui/` 10 张 UI = **合计 89 张** ✅
- [x] `flutter pub get` 成功
- [x] `flutter analyze` 0 issues
- [x] `flutter test` 1123 pass + 1 skip + 0 fail(维持 baseline)
- [ ] flutter run 视觉验收 — **可选,留用户主导**(Mac 端 web build + python server 验 splash + home_feed seal,Windows Pen `flutter run -d windows` 验完整 3 处)
- [ ] commit + PROGRESS 更新(本 closeout 后)

---

## §4 教训沉淀

### 教训 1:Phase 3 接入广度被 widget 现状真实约束,不是 yaml/PNG 数量决定

Phase 0 reality check 提前发现「lib/features/character/master/disciple 全部不存在」+「forging_panel 不显示 iconPath」+「home_feed 没 splash + 没 meditation 入口」,**避免了「89 张归位 + UI 全接入」的过度承诺**。memory `feedback_phase0_grep_two_axes` 三维 grep 救场:① schema 字段是否预留 ② lib/ 是否已消费 ③ 邻近目录是否有 widget。

实际接入只 3 处 vs 89 张产物的不匹配是**1.0 路线图 Demo §7 UI 完善阶段的工作量信号** — 装备列表页 / 师徒展示页 / 装备详情弹窗(detail 大图消费)等 widget 都要新建。

### 教训 2:Dart wildcard underscores 新规则陷阱

Dart 3.7+ 引入「underscore wildcards」,原 `(_, __, ___)` 模式(3 个不同 underscore 参数名)被 `unnecessary_underscores` lint 标 info — 推荐改 `(_, _, _)`(单 `_` 复用为 wildcard,不绑定名字)。Image.asset 的 errorBuilder 签名 `(BuildContext, Object, StackTrace?)` 三参数全 ignore 是典型场景。

**应对**:写 errorBuilder 默认用 `(_, _, _) => ...`,不再用 `(_, __, ___) =>`。

### 教训 3:errorBuilder 守门 widget test 不破

Image.asset 在 widget test 里实际 fail(test 不加载 pubspec assets)但通过 errorBuilder 兜底 fallback 到 Icon/SizedBox,**widget test 不 crash**。home_feed_screen_test.dart / seclusion_map_list_screen_test.dart 一行不改 1123 pass 维持。

**应对**:任何 Image.asset 必加 errorBuilder fallback,既守 widget test 也守 release 产物(asset 万一加载失败不破布局)。

---

## §5 1.0 路线图后续阶段(候选 1 完工 → 候选 2/3/4)

候选 1 完工把 89 张图全归档项目 + schema 全注册到位,**后续 widget 建好时一行 Image.asset 即可消费**。

下波候选(优先级排):

| # | 任务 | 模型 | 时长 | 备注 |
|---|---|---|---|---|
| 2 | 心法相生 §4.5 触上限 8 重设计 | sonnet Phase 0 + opus | 1-2h | 非阻塞代码任务 |
| 3 | Demo §8.4 14/14 全达标确认 + 余下挂账清算 | opus | 半工日 | 1.0 之前最后里程碑 |
| 4 | 1.0 路线图 Demo §7 UI 完善阶段(装备列表页 / 师徒展示页 / 装备详情弹窗) | opus xhigh | 2-5 工日 | **本次未消费的 64 张装备图 + 3 立绘 + 8 UI 资源全接入** |
| 5 | 1.0 美术 LoRA 训练数据扩充 | opus + 用户手动 | 远期 | 解 memory 第 12/14 条根本 |

---

**closeout 完结**。M4 PoC #46 美术全链路:Stage 0 baseline 探索 → Stage 1 PoC → Stage 1.5 → Stage 2 W1-W6 量产 89 张 → **assets 归位 + schema 注册 + 3 处 UI 接入** ✅。**美术成果首次落入 Flutter app**,玩家上线第一屏可见水墨红印章 + 启动闪屏渔舟远山 + 闭关页地图缩略 5 张水墨意境。
