# M4 PoC #46 美术 89 张 assets 归位 + Flutter UI 接入 spec(2026-05-20)

> **范围**:Stage 2 量产收官后 89 张产物 → `assets/` 归位 + yaml schema 字段注册 + Flutter UI 3 处接入
> **scope 拍板**:**完整方案 Phase 1+2+3**(2026-05-20 用户拍板)
> **节奏**:主对话 opus xhigh,估时 ~1.5-2h
> **Baseline**:HEAD `a5c5282` · flutter test 1123 pass + 1 skip + 0 fail / analyze 0 issues

---

## §1 三 Phase 实装清单

### Phase 1 文件归位(89 张 → `assets/`)

| 类别 | 数 | 源目录 | 目标 | 命名规则 |
|---|---|---|---|---|
| 装备 icon | 35 | MJ_Stage1_PoC + W1-W5 | `assets/equipment/<id>.png` | 按 equipment.yaml id |
| 装备 detail | 35 | 同上 | `assets/equipment/<id>_detail.png` | 同上加 `_detail` |
| 装备 alt 备选 | 1 | MJ_Stage1_PoC | `assets/equipment/_alt/01_tie_jian_icon_alt.png` | 归档不用 |
| 立绘 portrait | 3 | MJ_Stage2_W4 | `assets/characters/<id>.png` | founder / first_disciple / second_disciple |
| 闭关地图 | 5 | MJ_Stage2_W6 | `assets/maps/<map_type>.png` | shanLin / guJianZhong / cangJingGe / xuanYaPuBu / duanYaJueBi |
| UI 资源 | 10 | MJ_Stage2_W6 | `assets/ui/<name>.png` | 见 §2.5 表 |

**合计 89 张全归位。**

### Phase 2 schema 注册(yaml + Dart def + pubspec)

5 项改动:

1. **`pubspec.yaml`** flutter.assets 加 4 行:`assets/equipment/` / `assets/maps/` / `assets/characters/` / `assets/ui/`
2. **`data/equipment.yaml`** 35 件加 `detailPath: assets/equipment/<id>_detail.png`(原 iconPath 已就绪不动)
3. **`data/numbers.yaml`** retreat.maps[] 5 张加 `image_path: assets/maps/<map_type>.png`(snake_case 沿用 numbers.yaml 约定)
4. **`data/masters.yaml`** 3 角色加 `portraitPath: assets/characters/<id>.png`(camelCase 沿用 masters.yaml 约定)
5. **Dart def parse**:
   - `lib/data/defs/equipment_def.dart` 加 `final String? detailPath` + factory parse(向后兼容 nullable)
   - `lib/features/seclusion/domain/seclusion_map_def.dart` 加 `final String? imagePath` + factory parse
   - `lib/data/defs/master_def.dart` 加 `final String? portraitPath` + factory parse

### Phase 3 UI 接入(3 处)

1. **`lib/features/seclusion/presentation/seclusion_map_list_screen.dart`**:l.314 处 Icon placeholder 替换为 `Image.asset(mapDef.imagePath)`(5 张地图大图)
2. **新建 `lib/features/splash/presentation/splash_screen.dart`**:启动期间显示 `50_landscape_loading.png`(等 GameRepository.loadAllDefs + IsarSetup.init 完成后进 HomeFeedScreen)+ `main.dart` 改 home: SplashScreen
3. **`lib/features/equipment/presentation/forging_panel.dart`**:探查是否显示装备 icon,如有则接入 `Image.asset(def.iconPath)` 替换 placeholder

---

## §2 89 张 → assets/ 完整映射表

### §2.1 装备 35 件 × 2 张 = 70 张(按 equipment.yaml 顺序)

#### 寻常货(xunChang)5 件

| equipment id | 源 icon | 源 detail |
|---|---|---|
| weapon_xunchang_tie_jian | MJ_Stage1_PoC/01_tie_jian_icon.png | MJ_Stage1_PoC/01_tie_jian_detail.png |
| weapon_xunchang_zhe_dao | MJ_Stage2_W1/08_zhe_dao_icon.png | MJ_Stage2_W1/08_zhe_dao_detail.png |
| weapon_xunchang_ruan_bian | MJ_Stage2_W1/09_ruan_bian_icon.png | MJ_Stage2_W1/09_ruan_bian_detail.png |
| armor_xunchang_bu_yi | MJ_Stage2_W1/10_bu_yi_icon.png | MJ_Stage2_W1/10_bu_yi_detail.png |
| accessory_xunchang_yu_pei | MJ_Stage2_W1/11_yu_pei_icon.png | MJ_Stage2_W1/11_yu_pei_detail.png |

#### 像样货(xiangYangHuo)5 件

| equipment id | 源 icon | 源 detail |
|---|---|---|
| weapon_xiangyang_gang_dao | MJ_Stage2_W2/09_gang_dao_icon.png | MJ_Stage2_W2/09_gang_dao_detail.png |
| weapon_xiangyang_chang_jian | MJ_Stage2_W2/10_chang_jian_icon.png | MJ_Stage2_W2/10_chang_jian_detail.png |
| weapon_xiangyang_jiu_jie_bian | MJ_Stage2_W2/11_jiu_jie_bian_icon.png | MJ_Stage2_W2/11_jiu_jie_bian_detail.png |
| armor_xiangyang_pi_jia | MJ_Stage2_W2/12_pi_jia_icon.png | MJ_Stage2_W2/12_pi_jia_detail.png |
| accessory_xiangyang_yin_jie | MJ_Stage2_W2/13_yin_jie_icon.png | MJ_Stage2_W2/13_yin_jie_detail.png |

> 注:W1 09/10/11 = ruan_bian/bu_yi/yu_pei;W2 09/10/11 = gang_dao/chang_jian/jiu_jie_bian。文件 pinyin 名不同 + 源目录隔离,**不会撞**。

#### 好家伙(haoJiaHuo)5 件

| equipment id | 源 icon | 源 detail |
|---|---|---|
| weapon_haojiahuo_qing_feng_jian | MJ_Stage1_PoC/02_qing_feng_jian_icon.png | MJ_Stage1_PoC/02_qing_feng_jian_detail.png |
| weapon_haojiahuo_xuan_hua_fu | MJ_Stage2_W3/14_xuan_hua_fu_icon.png | MJ_Stage2_W3/14_xuan_hua_fu_detail.png |
| weapon_haojiahuo_chan_si_suo | MJ_Stage1_PoC/05_chan_si_suo_icon.png | MJ_Stage1_PoC/05_chan_si_suo_detail.png |
| armor_haojiahuo_jin_pao | MJ_Stage1_PoC/06_jin_pao_icon.png | MJ_Stage1_PoC/06_jin_pao_detail.png |
| accessory_haojiahuo_yu_pei_lao | MJ_Stage2_W3/15_yu_pei_lao_icon.png | MJ_Stage2_W3/15_yu_pei_lao_detail.png |

#### 利器(liQi)5 件

| equipment id | 源 icon | 源 detail |
|---|---|---|
| weapon_liqi_long_quan | MJ_Stage1_PoC/03_long_quan_icon.png | MJ_Stage1_PoC/03_long_quan_detail.png |
| weapon_liqi_pan_long_dao | MJ_Stage1_PoC/04_pan_long_dao_icon.png | MJ_Stage1_PoC/04_pan_long_dao_detail.png |
| weapon_liqi_lian_zi_bian | MJ_Stage2_W3/16_lian_zi_bian_icon.png | MJ_Stage2_W3/16_lian_zi_bian_detail.png |
| armor_liqi_xuan_tie_jia | MJ_Stage2_W3/17_xuan_tie_jia_icon.png | MJ_Stage2_W3/17_xuan_tie_jia_detail.png |
| accessory_liqi_fei_yu_pei | MJ_Stage2_W3/18_fei_yu_pei_icon.png | MJ_Stage2_W3/18_fei_yu_pei_detail.png |

#### 重器(zhongQi)5 件

| equipment id | 源 icon | 源 detail |
|---|---|---|
| weapon_zhongqi_po_zhen_chui | MJ_Stage2_W4/19_po_zhen_chui_icon.png | MJ_Stage2_W4/19_po_zhen_chui_detail.png |
| weapon_zhongqi_qing_xu_jian | MJ_Stage2_W4/20_qing_xu_jian_icon.png | MJ_Stage2_W4/20_qing_xu_jian_detail.png |
| weapon_zhongqi_du_long_suo | MJ_Stage2_W4/21_du_long_suo_icon.png | MJ_Stage2_W4/21_du_long_suo_detail.png |
| armor_zhongqi_yin_lin_jia | MJ_Stage2_W4/22_yin_lin_jia_icon.png | MJ_Stage2_W4/22_yin_lin_jia_detail.png |
| accessory_zhongqi_qing_yu_huan | MJ_Stage2_W4/23_qing_yu_huan_icon.png | MJ_Stage2_W4/23_qing_yu_huan_detail.png |

#### 宝物(baoWu)5 件

| equipment id | 源 icon | 源 detail |
|---|---|---|
| weapon_baowu_xuan_tian_fu | MJ_Stage2_W5/27_xuan_tian_fu_icon.png | MJ_Stage2_W5/27_xuan_tian_fu_detail.png |
| weapon_baowu_chang_hong_jian | MJ_Stage2_W5/28_chang_hong_jian_icon.png | MJ_Stage2_W5/28_chang_hong_jian_detail.png |
| weapon_baowu_xue_lian_bian | MJ_Stage2_W5/29_xue_lian_bian_icon.png | MJ_Stage2_W5/29_xue_lian_bian_detail.png |
| armor_baowu_jin_si_jia | MJ_Stage2_W5/30_jin_si_jia_icon.png | MJ_Stage2_W5/30_jin_si_jia_detail.png |
| accessory_baowu_yu_long_pei | MJ_Stage1_PoC/07_yu_long_pei_icon.png | MJ_Stage1_PoC/07_yu_long_pei_detail.png |

#### 神物(shenWu)5 件

| equipment id | 源 icon | 源 detail |
|---|---|---|
| weapon_shenwu_po_jun_dao | MJ_Stage2_W5/31_po_jun_dao_icon.png | MJ_Stage2_W5/31_po_jun_dao_detail.png |
| weapon_shenwu_tian_wen_jian | MJ_Stage2_W5/32_tian_wen_jian_icon.png | MJ_Stage2_W5/32_tian_wen_jian_detail.png |
| weapon_shenwu_huan_meng_bian | MJ_Stage2_W5/33_huan_meng_bian_icon.png | MJ_Stage2_W5/33_huan_meng_bian_detail.png |
| armor_shenwu_xuan_huang_pao | MJ_Stage2_W5/34_xuan_huang_pao_icon.png | MJ_Stage2_W5/34_xuan_huang_pao_detail.png |
| accessory_shenwu_kun_lun_pei | MJ_Stage2_W5/35_kun_lun_pei_icon.png | MJ_Stage2_W5/35_kun_lun_pei_detail.png |

### §2.2 立绘 3 张

| master id | 源 | 目标 |
|---|---|---|
| founder | MJ_Stage2_W4/24_founder_portrait.png | assets/characters/founder.png |
| first_disciple | MJ_Stage2_W4/25_first_disciple_portrait.png | assets/characters/first_disciple.png |
| second_disciple | MJ_Stage2_W4/26_second_disciple_portrait.png | assets/characters/second_disciple.png |

### §2.3 闭关地图 5 张

| map_type | 源 | 目标 |
|---|---|---|
| shanLin | MJ_Stage2_W6/36_shanLin_map.png | assets/maps/shanLin.png |
| guJianZhong | MJ_Stage2_W6/37_guJianZhong_map.png | assets/maps/guJianZhong.png |
| cangJingGe | MJ_Stage2_W6/38_cangJingGe_map.png | assets/maps/cangJingGe.png |
| xuanYaPuBu | MJ_Stage2_W6/39_xuanYaPuBu_map.png | assets/maps/xuanYaPuBu.png |
| duanYaJueBi | MJ_Stage2_W6/40_duanYaJueBi_map.png | assets/maps/duanYaJueBi.png |

### §2.4 UI 资源 10 张

| 用途 | 源 | 目标 |
|---|---|---|
| 米黄宣纸主背景 | 41_paper_bg.png | assets/ui/paper_bg.png |
| 远山 UI 背景 | 42_mountain_bg.png | assets/ui/mountain_bg.png |
| 纵向卷轴弹窗 | 43_scroll_vertical.png | assets/ui/scroll_vertical.png |
| 横向卷轴标题 | 44_scroll_horizontal.png | assets/ui/scroll_horizontal.png |
| 红印章落款 | 45_seal_red.png | assets/ui/seal_red.png |
| 水墨横分隔线 | 46_ink_divider.png | assets/ui/ink_divider.png |
| 古铜钱图标 | 47_coin_icon.png | assets/ui/coin_icon.png |
| 莲花图标(领悟) | 48_lotus_icon.png | assets/ui/lotus_icon.png |
| 蒲团香炉(闭关) | 49_meditation_icon.png | assets/ui/meditation_icon.png |
| 渔舟远山(loading) | 50_landscape_loading.png | assets/ui/landscape_loading.png |

### §2.5 alt 备选 1 张

| 源 | 目标 |
|---|---|
| MJ_Stage1_PoC/01_tie_jian_icon_alt.png | assets/equipment/_alt/01_tie_jian_icon_alt.png |

---

## §3 Phase 2 schema diff(精确)

### 3.1 `data/equipment.yaml` 35 件加 detailPath

每件装备 `iconPath:` 行下面加 `detailPath:`,例:
```yaml
    iconPath: assets/equipment/weapon_xunchang_tie_jian.png
    detailPath: assets/equipment/weapon_xunchang_tie_jian_detail.png
```

### 3.2 `data/numbers.yaml` retreat.maps[] 5 张加 image_path

每张 map `weather:` 行下面加 `image_path:`,例:
```yaml
    - map_type: shanLin
      ...
      weather: clear
      image_path: assets/maps/shanLin.png
```

### 3.3 `data/masters.yaml` 3 角色加 portraitPath

每角色 `enabledInDemo:` 行下面加 `portraitPath:`,例:
```yaml
  - id: founder
    ...
    enabledInDemo: true
    portraitPath: assets/characters/founder.png
```

### 3.4 `lib/data/defs/equipment_def.dart` 加 detailPath

- field:`final String? detailPath;`
- constructor:`this.detailPath,`
- factory:`detailPath: y['detailPath'] as String?,`

### 3.5 `lib/features/seclusion/domain/seclusion_map_def.dart` 加 imagePath

- field:`final String? imagePath;`
- constructor:`this.imagePath,`
- factory:`imagePath: y['image_path'] as String?,`(snake_case)

### 3.6 `lib/data/defs/master_def.dart` 加 portraitPath

- field:`final String? portraitPath;`
- constructor:`this.portraitPath,`
- factory:`portraitPath: y['portraitPath'] as String?,`

### 3.7 `pubspec.yaml` flutter.assets 加 4 行

```yaml
  assets:
    - data/
    - ...(已有)
    - assets/equipment/
    - assets/maps/
    - assets/characters/
    - assets/ui/
```

---

## §4 Phase 3 UI 接入(3 处)

### 4.1 seclusion_map_list_screen.dart l.314 Icon → Image.asset

把当前 Icon placeholder 替换为 `Image.asset(mapDef.imagePath ?? '', errorBuilder: ...)`,fit BoxFit.cover,放卡片顶部或左侧。

### 4.2 新建 splash_screen.dart + main.dart wire

启动期间(GameRepository.loadAllDefs + IsarSetup.init 阶段)显示全屏 `assets/ui/landscape_loading.png`。完成后 push replacement 进 HomeFeedScreen。

### 4.3 forging_panel.dart 装备 icon 接入(探查)

读 `forging_panel.dart` 看是否显示 EquipmentDef.iconPath,若有则接入 `Image.asset(def.iconPath)`。

---

## §5 验收

- [ ] `assets/equipment/` 70 张装备 + `_alt/` 1 张 = 71 张
- [ ] `assets/characters/` 3 张立绘
- [ ] `assets/maps/` 5 张地图
- [ ] `assets/ui/` 10 张 UI = **合计 89 张** ✅
- [ ] `flutter pub get` 成功(pubspec.yaml 改动后必跑)
- [ ] `flutter analyze` 0 issues
- [ ] `flutter test` 1123 pass 维持(或 ≥)
- [ ] flutter run -d macos / 或用户 Windows 启动验视觉(3 处接入点)
- [ ] commit + PROGRESS 更新

---

## §6 完工后下一步候选

1. 候选 2 心法相生 §4.5 触上限 8 重设计(sonnet+opus 1-2h)
2. 候选 3 Demo §8.4 14/14 全达标确认(opus 半工日)
3. 候选 4 LoRA 训练数据扩充(远期)
4. 1.0 路线图 Demo §7 UI 完善阶段:装备列表页 / 师徒展示页 / 装备详情弹窗(detail 大图全部消费)/ UI 类资源(seal/scroll/divider)全面接入
