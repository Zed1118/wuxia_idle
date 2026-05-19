# P1 #44 · DeepSeek 派单 · 延续典故 yaml 池补齐 spec

> 2026-05-19 · Mac+Opus 起手,DeepSeek 端接收。Mac 端 schema + wire + test + fallback 已落地(HEAD 待 commit),DeepSeek 端负责为 35 件装备 lore yaml 各加 2 池文案。
>
> **Mac 已完成**:`LoreContent` 加 `continued_lore_obtained` / `continued_lore_boss_defeated` 池字段解析、`GameEventService.recordEquipmentObtained` / `recordBossDefeated` 走 LoreLoader 抽样、占位符替换、空池 → Dart 模板 fallback、9 + 4 个新 test case。

## §1 任务范围

为 `data/lore/<id>.yaml` 35 个装备 yaml **每个**加 2 个文案池字段:
- `continued_lore_obtained`:首次获得装备时触发(战利品掉落 / 剧情奖励)
- `continued_lore_boss_defeated`:此装备见证主战角色击败 Boss(主线 / 爬塔 Boss 关首通)

每池 **3-5 条**,Random 纯随机抽取(不重复防护由 caller 端处理,玩家观感上反复刷塔抽到同条可接受)。

## §2 yaml schema(扩既有字段,与 default_lore 共存)

```yaml
id: weapon_xunchang_ruan_bian           # 既有
name: 软鞭                                # 既有
default_lore:                             # 既有(preset 典故,不动)
  - text: |
      鞭身是熟牛皮绞成的 ...

# ── P1 #44 新增 ──
continued_lore_obtained:                  # 首次获得触发池(3-5 条)
  - text: |
      于「{source}」初见此鞭,鞭梢犹带新革之气。
  - text: |
      初遇于{source},此鞭未沾人血,皮纹尚白。
  # ...
continued_lore_boss_defeated:             # 击败 Boss 见证池(3-5 条)
  - text: |
      斩 {boss_name} 于 {stage_name},鞭身崭新一痕。
  - text: |
      {stage_name}一战胜 {boss_name},此鞭从此沾血。
  # ...
```

## §3 占位符变量约定

| 变量 | 触发池 | 含义 | 样例 |
|---|---|---|---|
| `{source}` | `continued_lore_obtained` | 装备来源(关卡名 / 爬塔层名) | 「夜袭山贼营」/「试炼塔 5 层」 |
| `{boss_name}` | `continued_lore_boss_defeated` | Boss 名 | 「黑面阎罗」/「无影刀客」 |
| `{stage_name}` | `continued_lore_boss_defeated` | 关卡名(主线 stage / 塔层) | 「夜袭山贼营」/「试炼塔 10 层」 |

### 不变量化的字段(yaml 直接写具体兵器名)

`{equip_name}` **不传**。yaml 按装备拆池,文案直接写「此剑」/「此鞭」/「此刀」/「此甲」等具体形态,符合 GDD §6.6 装备典故个性化语义。

❌ 错误:`于「{source}」初见此 {equip_name},初见锋芒。`
✅ 正确:`于「{source}」初见此鞭,初见锋芒。`(因为是 `weapon_xunchang_ruan_bian.yaml` 池,即知装备形态是鞭)

### 占位符使用纪律

- 占位符只有花括号 `{var}` 形式,**不识别**其他模板语法(`{{var}}` / `<var>` / `${var}` 都不替换)
- 池内不强制每条都用占位符,可有的条不用变量(纯静态文案)。但**不要写未约定的占位符**(`{boss_realm}` / `{weather}` 之类),会原样保留出现 bug
- 文案不要硬编码具体关卡 / Boss 名 — 用占位符,让 Mac 端从战斗上下文注入

## §4 量级建议

- **每池 3-5 条**,池太少(< 3)玩家反复抽到同条频繁观感重复,池太多(> 5)文案量超工作量预算
- 35 件装备 × 2 池 × 4 条均值 ≈ 280 条文案,DeepSeek 端总工作量预估 3-5h(按 60-90 条/h 计,含校稿)
- 风格遵循 `data/lore/_templates/` 既有 7 模板基调:水墨克制 / 武侠味重 / 1-3 行文字,**避免**网游风("传说之剑"/"史诗装备")或情绪过浓("热泪盈眶")

## §5 35 件装备覆盖清单(按 tier 分组)

> 全部位于 `data/lore/` 根目录(不含 `_archive/` 和 `_templates/`)。

### 寻常货(xunchang)· 5 件
- `weapon_xunchang_ruan_bian.yaml`(软鞭)
- `weapon_xunchang_tie_jian.yaml`(铁剑)
- `weapon_xunchang_zhe_dao.yaml`(折刀)
- `armor_xunchang_bu_yi.yaml`(布衣)
- `accessory_xunchang_yu_pei.yaml`(玉佩)

### 像样货(xiangyang)· 5 件
- `weapon_xiangyang_chang_jian.yaml`
- `weapon_xiangyang_gang_dao.yaml`
- `weapon_xiangyang_jiu_jie_bian.yaml`
- `armor_xiangyang_pi_jia.yaml`
- `accessory_xiangyang_yin_jie.yaml`

### 好家伙(haojiahuo)· 5 件
- `weapon_haojiahuo_chan_si_suo.yaml`
- `weapon_haojiahuo_qing_feng_jian.yaml`
- `weapon_haojiahuo_xuan_hua_fu.yaml`
- `armor_haojiahuo_jin_pao.yaml`
- `accessory_haojiahuo_yu_pei_lao.yaml`

### 利器(liqi)· 5 件
- `weapon_liqi_lian_zi_bian.yaml`
- `weapon_liqi_long_quan.yaml`
- `weapon_liqi_pan_long_dao.yaml`
- `armor_liqi_xuan_tie_jia.yaml`
- `accessory_liqi_fei_yu_pei.yaml`

### 重器(zhongqi)· 5 件
- `weapon_zhongqi_du_long_suo.yaml`
- `weapon_zhongqi_po_zhen_chui.yaml`
- `weapon_zhongqi_qing_xu_jian.yaml`
- `armor_zhongqi_yin_lin_jia.yaml`
- `accessory_zhongqi_qing_yu_huan.yaml`

### 宝物(baowu)· 5 件
- `weapon_baowu_chang_hong_jian.yaml`
- `weapon_baowu_xuan_tian_fu.yaml`
- `weapon_baowu_xue_lian_bian.yaml`
- `armor_baowu_jin_si_jia.yaml`
- `accessory_baowu_yu_long_pei.yaml`

### 神物(shenwu)· 5 件
- `weapon_shenwu_huan_meng_bian.yaml`
- `weapon_shenwu_po_jun_dao.yaml`
- `weapon_shenwu_tian_wen_jian.yaml`
- `armor_shenwu_xuan_huang_pao.yaml`
- `accessory_shenwu_kun_lun_pei.yaml`

**Tier 风格梯度建议**:寻常货 → 朴素白描;像样货 / 好家伙 → 有故事感;利器 / 重器 → 沾血味重 + 经历感;宝物 / 神物 → 含传说色彩 + 历史感(但不要"传说之剑"这种网游表达,GDD §4 命名锁死)。

## §6 验收

DeepSeek 端写完后 Mac 端跑:
1. `flutter test test/data/lore_loader_test.dart` — 35 件 yaml 红线红测验证 yaml 仍可解析
2. `flutter test test/features/event/application/game_event_service_test.dart` — 现有 18 case 不破
3. 加 1 个红线 case:35 件 yaml 的 `continued_lore_obtained` / `continued_lore_boss_defeated` 池**全部非空**(防漏件)
4. 删 fallback 路径或保留作 graceful degradation(Mac 端二阶段决定,本批 spec 不强约束)

## §7 硬约束

- Mac 端**不动** `data/lore/<id>.yaml` 文案内容(DeepSeek 领地,见 CLAUDE.md §8)
- DeepSeek 端**不改** schema 字段名(`continued_lore_obtained` / `continued_lore_boss_defeated` 已锁,改字段名 Mac 端 wire break)
- DeepSeek 端**不动** `default_lore`(preset 池,W15 #35 已交付定稿)
- 文件按需提交,可分批(不需要一次提交 35 件),Mac 端等全部到位再做二阶段验收

## §8 参考样例(供 DeepSeek 起手)

```yaml
# data/lore/weapon_xunchang_tie_jian.yaml(寻常货 · 铁剑)
id: weapon_xunchang_tie_jian
name: 铁剑
default_lore:
  - text: |
      (既有 preset 段,不动)

continued_lore_obtained:
  - text: |
      于「{source}」得此铁剑,剑身粗糙,刃口未开。
      握在掌中沉甸,像一截还未开声的钝铁。
  - text: |
      初遇于{source}。是把寻常的铁剑,
      但用过的人都知道——寻常之物,反而经得住磨。
  - text: |
      于{source}得此剑。剑鞘上还留着前人的指印,
      指印的位置告诉你他握剑的姿势,与你不同。

continued_lore_boss_defeated:
  - text: |
      于「{stage_name}」一战,此剑斩 {boss_name}。
      剑身上多了一道豁口,豁口的形状像{boss_name}最后一招的轨迹。
  - text: |
      {stage_name}一战。此剑虽寻常,但你将 {boss_name} 的来路看清了,
      剑就稳得住。这一次它没有崩。
  - text: |
      斩 {boss_name} 于 {stage_name}。
      你不知道此剑还能撑几战,但至少这一战,它没有让你失望。
```

3 obtained + 3 bossDefeated,**仅供风格参考,不要直接复制**到所有装备 yaml(每件装备应有独立文案,寻常货风格朴素,神物风格有历史感)。

---

**DeepSeek 接收后请回执**:确认 schema 字段名 + 占位符约定 + 35 件清单。开工后可分批提交,Mac 端最后做红线 case 验收。
