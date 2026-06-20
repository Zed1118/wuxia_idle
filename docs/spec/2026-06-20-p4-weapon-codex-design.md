# 兵器谱 设计方案(P4 长期档案·子项2)

> 2026-06-20 · brainstorm 拍板 · 武侠 idle 1.0 长线打磨期
> 姊妹功能:战绩册(P4 子项1,`lib/features/battle_record/`),本设计全程对称其体例。

## 0. 一句话

收集式装备图鉴:记录玩家**曾获得**的全部 80 件装备,已获得点亮、未获得水墨剪影,详情卡含个人获得历程。区别于「江湖见闻录·典故」tab 的静态全展示。

## 1. 决策锚点(brainstorm 已拍板)

| 维度 | 决策 | 理由 |
|------|------|------|
| 核心定位 | 收集图鉴(点亮式) | 与已有「典故」tab(静态列全 80 件)区分;贴「长期档案」主题(战绩册记 Boss,兵器谱记兵器) |
| 收录范围 | 全部 80 件装备 | 沿用「兵器谱」雅称(如「江湖见闻录」之于百科)。点亮分母 = 80 |
| 点亮语义 | 曾获得即永久点亮 | 卖掉/分解不灭,真档案语义 |
| 存储丰富度 | 新建 `EquipmentCatalog` @collection | 记获得历程,详情卡有个人历程感,对称战绩册 BossMemory |
| 老档处理 | 回填点亮·来历不详 | 扫当前持有装备点亮,firstObtainedFrom=「来历不详」,对称战绩册 isPreRecord 骨架 |
| 未获得显示 | 剪影占位(藏名) | 水墨剪影+「???」,制造集齐欲望,对称战绩册剩影占位 |

## 2. 架构(对称 `lib/features/battle_record/`)

```
lib/features/weapon_codex/
├── domain/
│   └── equipment_catalog_entry.dart        # @collection
├── application/
│   ├── equipment_catalog_service.dart      # recordAcquisition 幂等业务逻辑
│   ├── equipment_catalog_hook.dart         # best-effort 写入钩子(try-catch 不打断主流程)
│   └── equipment_catalog_providers.dart    # Riverpod providers(+ .g.dart codegen)
└── presentation/
    ├── weapon_codex_screen.dart            # 主屏:tier 分组 + 进度 + 剪影/点亮卡网格
    └── equipment_catalog_detail_screen.dart # 详情屏:静态档案 + 个人历程
```

## 3. 数据层

### 3.1 `EquipmentCatalogEntry` @collection(对称 BossMemory)

| 字段 | 类型 | 说明 |
|------|------|------|
| `id` | Id | Isar autoIncrement |
| `saveDataId` | int | 存档隔离 |
| `defId` | String, @Index | 装备 def 唯一键(对应 EquipmentDef.id) |
| `firstObtainedAt` | DateTime? | 首次获得时间;回填档为 null |
| `firstObtainedFrom` | String | 首次来源;回填档=「来历不详」 |
| `obtainedCount` | int | 历史累计获得次数(重得 ++) |
| `isPreRecord` | bool | 回填骨架标记(语义同战绩册) |

### 3.2 service 幂等语义

`EquipmentCatalogService.recordAcquisition(defIds, from)`:
- 首得该 defId:建 entry(firstObtainedAt=now / firstObtainedFrom=from / obtainedCount=1 / isPreRecord=false)
- 重得:仅 `obtainedCount++`,不动 firstObtained* 与 isPreRecord
- 回填(迁移专用):firstObtainedAt=null / firstObtainedFrom=「来历不详」 / obtainedCount=1 / isPreRecord=true

### 3.3 写入时机(plan Phase 0 钉死单一 chokepoint)

挂在**装备进入持久库存的统一收口处**,须覆盖所有授予路径:
- 游戏内掉落 `DropService`(`lib/features/equipment/application/drop_service.dart`)
- 招募起始装备 `recruitment_service.dart`
- 开局 `master_builder.dart`
- **离线 recap 掉落**(守 §5.5,不漏)

钩子 best-effort:写入失败 try-catch 不打断玩家获得装备主流程(同 boss_memory_hook)。

### 3.4 老档迁移(saveVer `0.26.0 → 0.27.0`)

- 新 collection 注册进 `isar_setup.dart` `_allSchemas`
- 迁移段:扫当前所有 `Equipment` 实例的 defId 去重,逐个 `recordAcquisition` 回填路径建 isPreRecord entry
- 曾卖掉/分解的装备不可追溯(可接受,brainstorm 已确认)

## 4. 表现层

### 4.1 主屏 `weapon_codex_screen`(WuxiaPaperPanel 体例)

- 顶部总进度「已录 X / 80」
- 主分组**按 tier 7 档纵排**(与典故/战绩册体例一致),每档标题带分档进度(如「利器 3/11」)
- 卡网格:已获得=装备图标+名+tier 色边;未获得=水墨剪影+「???」(藏名/属性,tier 档色仍在)
- 顶部 slot 筛选 chips:`全部 / 兵器 / 护甲 / 饰品`(纯前端过滤,默认全部)
- 流派筛选:**不做**(YAGNI,后续可补)
- 交互:点已获得卡→详情屏;点剪影→轻提示「尚未得手」(不进详情)

### 4.2 详情屏 `equipment_catalog_detail_screen`(对称 boss_memory_detail_screen)

- 静态档案(读 `EquipmentDef`):detail 大图 / 名 / tier / 部位 / 属性范围(min~max)/ schoolBias / 开锋候选技 / 绑定典故(可跳 Baike 典故)/ 师承遗物说明(isLineageHeritage)
- 个人历程(读 catalog):首得时间+来源;回填档显「来历已不可考」;「历得 N 件」

## 5. 主菜单入口 + 解锁

- 放 `main_menu.dart` `jianghuItems`(战绩册邻近),图标拟 `Icons.auto_stories_outlined`
- 解锁:获得过任一装备(`acquiredCount > 0`),隐式解锁(§5.7)。开局起始装备即点亮,故几乎一进游戏即解锁

## 6. 红线与测试

### 6.1 红线(全守)
- 纯收集/展示层:不碰伤害公式、掉落经济、概率、min_tier(§5.4/§5.1);catalog 写入旁路 best-effort,失败不影响掉落主流程
- 文案全进 `UiStrings`(§5.6),无硬编码中文 / 无网游稀有词 / 无 %
- 无新可调数值(解锁阈值=0 语义常量,不进 yaml)
- saveVer 0.27.0 新 collection,旧档自动空 + 迁移回填

### 6.2 测试
- service 幂等单测:首得 / 重得累加 / 回填 三态
- 迁移回填单测:老档扫库存去重点亮 + isPreRecord 标记
- 进度 provider 测:X/80 + 分档计数
- 主屏 widget 测:剪影/点亮卡渲染 + slot 筛选
- 详情屏 widget 测:双态(正常 / 来历不详)
- 全量套件零回归;analyze 0

### 6.3 视觉
剪影/点亮/进度/详情卡静态可截,留真机 `flutter run -d macos` 目检(沿战绩册体例,加 VISUAL_ROUTE)。

## 7. 已知 deferred
- 流派筛选(YAGNI)
- 「曾获得后卖掉」的老档装备不可追溯(数据天然缺失)
