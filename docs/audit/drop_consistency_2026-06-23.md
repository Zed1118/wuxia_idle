# 掉落表一致性审计（第五阶段·掉落优化 子系统 A）

> 2026-06-23 · 纯只读诊断（0 改代码/yaml）· 4 路 subagent 扇出 + 逐条独立 grep 亲核
> 对象：`data/stages.yaml`(47 stage) + `data/towers.yaml`(30 floor) 的 dropTable
> 锚：stage `requiredRealm` 字段 / equipment.yaml `tier` 字段 / GDD §5.3 七阶锁死

## 结论速览

掉落表**整体健康**（tier 梯度 98.7% 合格 / 7 阶无缺口 / 0 悬空引用 / 9 本秘籍 100% 必得 / 材料前后期分工清晰）。
未发现「系统性掉落太苦」——**对子系统 C 防衰的直接含义：缺乏 evidence 支撑需要保底机制**。
真问题集中在 **1 个 content bug（3 件装备不可获得）+ 4 个配置卫生/一致性项**。

## Findings（按优先级，均已 grep 亲核）

### 高 · 真 content bug

**F1 — 3 件 special 装备完全不可获得**（最高价值）✅ 已修(2026-06-23 续47 · 方案 A 实装 3 里程碑通道)
- `weapon_special_wu_ming_jian`(宝物) / `accessory_special_xin_mo_zhu`(重器) / `armor_special_bai_zhan_jia`(利器)
- 三件有完整定义 + 美术(icon+detail) + 典故 lore，`dropSourceTags` 声明授予通道 `ascension_reward`/`inner_demon_reward`/`mass_battle_merit`（equipment.yaml:1322/1339/1354）
- **亲核证实**：① `dropSourceTags` 全 lib **0 消费**（仅 equipment_def.dart:19/58/84 解析）② 3 个 tag 字符串只在 equipment.yaml 出现，无任何消费方 ③ 3 件 defId 全仓查（lib/data/test）**无任何授予逻辑**，只有定义/lore/asset ④ 配合心魔关 `dropTable: []`，飞升/群战/心魔三个声明通道**均未实装**
- 后果：玩家**永远拿不到这 3 件装备**，美术+文案+数值全部沉没
- 修复方向（留 B/独立批拍板）：要么实装 3 个授予通道，要么并入 dropTable（违 dropSourceTags 原意），要么明确砍掉这 3 件

### 中 · 体验/一致性

**F2 — 首通秘籍 loot preview rarity 标签偏差**（子系统 B 的核心命中）✅ 已修(2026-06-23 续48 · 全面修 · `4772c5be`)
- 主线 3 本秘籍 `item_scroll_*` dropChance=1.0（stages.yaml:380/727/1095）运行时**确实首通门控**（`shouldSkipScrollDrop` stage_entry_flow.dart:1215，应用于 :828）
- 但主线预览整表硬编码 `isFirstClearGated: false`（stage_list_screen.dart:328）→ 这 3 本被归入 `changKeDe`(常可得)，**实际是首通必得、重打不补**
- 根因：runtime 首通门控在主线是**逐 defId**（仅 scroll），preview 的 gated 是**整表单布尔**，表达不了「同表内秘籍门控、装备不门控」
- 爬塔侧不受影响（整渠道 gated，tower_floor_card.dart:328 true 对全表都对）
- **实修(全面修)**：`fromDropTable` 表级布尔 → `FirstClearGating` 枚举(scrollOnly 逐条/wholeChannel 整渠道)逐条判 gated；抽 `isTechniqueScrollDefId` 谓词入 core/domain/enums，runtime `shouldSkipScrollDrop` + `enums.fromDefId` + preview **三方共用**，消除 `item_scroll_` 前缀散写 3 处 drift；dialog footer 按 gating 选串(主线新串「秘籍首通必得，重打不补」)。bucketOf/爬塔/runtime 掉落行为零变。analyze 0 / 全量 2848+1skip(+9 新测)。

**F3 — stage_04_05 章末 Boss 宝物护甲越 2 阶 + 概率偏高**（边界）— ✅ **resolved 2026-06-24（续50 · 方案 A · commit 346712eb）**
- `armor_baowu_jin_si_jia`(宝物) 在 requiredRealm=一流 的关卡 dropChance=0.40（stages.yaml:1402）
- 越 2 阶（一流→宝物，需绝顶才解锁），0.40 刚越过 0.30 aspirational 阈值
- **处置（用户拍板方案 A）**：换 `armor_zhongqi_han_tie_zhong_jia`(重器/绝顶阶，+1 阶) 贴齐跨阶 jueDing Boss 及同关另两件 zhongQi 掉落；dropChance 0.40→0.30 与饰品 0.50 拉开层次。金丝甲回归 dropSourceTags 声明来源 tower_30/zongShi_unlock，不再一流阶提前架空里程碑。无 test 硬引用旧 defId，掉落改动不触战斗红线。analyze 0 / 全量 2855+1skip（0 回归）。

**F4 — 终局塔层奖励含水分** — ✅ **resolved 2026-06-24（续51 · 方案 A · commit 0105eaf9）**
- tower 装备封顶 baoWu，**无 shenWu**（towers.yaml:28 文件头自承占位待补）
- floor28-30（宗师境界）大量回掉 liQi 低阶装备（越境界往下 3-4 阶），与「爬塔=高阶挑战奖励」哲学冲突，终局塔层价值偏低
- **Phase 0 修正审计前提（2 处）**：① 「无 shenWu」**非水分**——塔封顶宗师阶（无武圣层，武圣留 Phase 4 飞升），锁步 §5.3 下本不该掉 shenWu（11 件 shenWu 全在主线武圣阶关，towers 0 件，正确）；② 实测最深 **-3 阶**（haoJiaHuo vs baoWu），无 -4。**真问题 = 回掉低阶装备稀释**（floor 23-30，非仅 28-30）。
- **处置（用户拍板方案 A）**：清 floor 23-30 的 10 件回掉低阶装备（long_quan×5/jin_pao×2/yu_pei_lao×2，floor 30 终局 3 件@100%），保留同阶 zhongqi/baowu + 秘籍 + 经验丹，心血结晶各层加码补偿；shenWu 不进塔（与 F3 消越阶自洽）。移除项均在主线/低层仍可获得（不孤儿）。**残留**：floor 20（一流 boss）yu_pei_lao -1 阶轻微回掉，在 16-20 一流段（超本批 23-30 scope），留底未动。analyze 0 / 全量 2855+1skip（0 回归）。

### 低 · 配置卫生 / guardrail 缺失

**F5 — `dropEquipmentDefIds`/`dropItemDefIds` 死字段** ✅ 已修(2026-06-23 续49 · 删字段 `697fedab`)
- stage_def.dart:38-39 定义（tower_floor_def 仅注释提及，无字段），注释自承「Phase 1 占位旧字段」，全 lib **0 读取**，live 掉落 100% 走 dropTable
- ~~建议：删字段或头注释标 unused~~ **实修=删字段**：Phase 0 证伪「0引用」前提（yaml 47 关 94 行 + `game_repository_test` 反向引用校验 + 2 红线测试用作 stages.yaml 锚点字符串）；已证 dropTable 是超集，删字段零信息丢失 → 清 stage_def 字段/构造/fromYaml + stages.yaml 94 key 行 + ~15 测试参数 + 2 红线测试换锚 `stage_01_01` 声明行

**F6 — `dropSourceTags` 死字段**（与 F1 同根）✅ 已修(2026-06-23 续47)
- 0 消费；F1 的 3 个授予通道未实装的直接体现。F1 修复时一并处理
- 实修:`MilestoneEquipmentGrantService._defsForTag` 按 dropSourceTags 筛装备授予,字段变 live 消费源

**F7 — 无全局 dropTable 引用校验器** ✅ 已修(2026-06-23 续49 · `3af2423d`)
- `_enforceRedLines`(game_repository.dart) ~30 条子校验，**无一遍历 dropTable 核对 equipmentDefId/inventoryItemDefId 存在**
- 当前**0 悬空**（已扫，eq+item 全可解析），但无 guardrail：未来悬空 equipmentDefId 会**战斗中崩**（getEquipment throw），悬空 item 会静默变 miscMaterial（enums.dart default 吞值）
- ~~建议~~ **实修**：`GameRepository.enforceDropTableReferences`(static·`_enforceRedLines` 启动期 fail-fast) 遍历 stage+tower 全 dropTable：EquipmentDrop.equipmentDefId∈equipmentDefs / ItemDrop.inventoryItemDefId 经 `ItemType.fromDefId` 解析为非 miscMaterial。补此前无校验的爬塔 floor 盲区。4 红线测

**F8 — shop.yaml §5.7「仅掉落不上架」无 schema 守门** ✅ 已修(2026-06-23 续49 · `3af2423d`)
- 当前货架仅 4 项（磨剑石/心血结晶/凝神丹/培元丹），**0 违规**，秘籍/大还丹均不在架
- ~~但仅靠人工维护 shop.yaml，无校验拦截。建议加断言~~ **实修**：`_enforceShopRedLines` 扩展守门——秘籍(`itemType==techniqueScroll`) + 大还丹(大档经验丹 itemDef.layerFraction==1.0) 不得上架，小/中档(layerFraction<1.0)不限。3 红线测(秘籍/大还丹注入抛 + 小中档正例)

## 健康项（证实无问题，不需动）

- tier 梯度：stages 有掉落 30 关中 29 关合格 + towers 22 floor 全合格 = 98.7%；**Type B 废装 0**
- 7 阶覆盖：每阶都有掉落源，无缺口（神物仅 3 源最稀但非缺口）
- 悬空引用：eq 0 / item 0
- 概率梯度：B 类「唯一来源极低」0 命中；A/C 类全 1.0 仅 3 个爬塔 Boss 首通保底层（有意设计）
- 秘籍：9 本全部 100% 概率绑死章末/塔 Boss，无「永远拿不到」
- 材料：磨剑石(前期)/心血结晶(中后期)分工清晰无断档；大还丹有源
- 双表口径：主线(神物独占+进度目标) vs 爬塔(baoWu 封顶+Boss 确定性) 哲学清晰区分

## 对 B/C/D 的决策含义

- **C 防衰/保底**：审计**无 evidence 支撑掉落太苦**（梯度健康、秘籍/材料 100% 保底）→ 建议 **C 不做**（缺需求 + 贴 §5.1 风险）。「先等 A 结果再定」的答案 = 不做。
- **B loot preview 准确性**：F2 是真 bug，值得做，范围明确（per-entry gated）。
- **F1（3 件不可获得装备）**：审计外溢的最高价值修复，不属原 4 子系统但是真 content bug，建议优先。
- **D 体验/打击感**：审计不直接产出，独立按需。
