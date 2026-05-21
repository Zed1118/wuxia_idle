# P1.1 候选 4 A4 开锋 build 内容扩 · closeout

> 2026-05-21 主对话 Mac+Opus xhigh ~50min(audit 25min + 实装 25min)。HEAD 起 `8b64390` → 收尾 `<本 commit>`。1170 → **1172 pass**(+2)/ analyze 0 issues / saveVersion 0.12.0(不动)。
> 输入:`p1_1_a4_forging_phase0_audit_2026-05-21.md`(grill 4 项全走推荐 G1.a + G2.b + G3.a + G4.a)。

## §1 一句话总结

35 件装备 `specialSkillCandidates` 内容扩,纯 yaml 改动:21 件 weapon 各配 2 个同流派同阶 skills.yaml 现成招(`<school>_<tier>_skill + <school>_<tier>_ult`),14 件 armor/accessory 不参与 specialSkill 槽 → UI 槽 3 +19 时走「无专属技能」兜底(已实装)。**0 代码改动、0 schema 改动、0 新增 skills.yaml**。

## §2 grill 4 项决议(audit doc §3 推荐路径全采纳)

| # | grill point | 决议 | 备注 |
|---|---|---|---|
| G1 | armor / accessory 是否参与 specialSkill 槽? | **G1.a 不参与** | 14 件 yaml 不填,Dart 默认 `const []`,UI 显「无专属技能」兜底 |
| G2 | weapon 21 件 candidates 数 N? | **G2.b N=2(skill+ult)** | 玩家在 +19 时二选一,微决策不烦 |
| G3 | 复用 skills.yaml vs 新增专属招? | **G3.a 纯复用** | 21 × 2 = 42 candidates 全部从 skills.yaml 63 通用招中机械映射 |
| G4 | lore yaml 是否同步加 skill_signature 段? | **G4.a 不动 lore** | UI 显 skill_id,Demo 够用,1.0 升级再说 |

## §3 实装详情(单 commit)

### §3.1 mapping 表(21 件 weapon)

| tier | weapon id | schoolBias | candidates(2) |
|---|---|---|---|
| xunChang | weapon_xunchang_tie_jian | lingQiao | `skill_lingqiao_jichu_skill` + `skill_lingqiao_jichu_ult` |
| xunChang | weapon_xunchang_zhe_dao | gangMeng | `skill_gangmeng_jichu_skill` + `skill_gangmeng_jichu_ult` |
| xunChang | weapon_xunchang_ruan_bian | yinRou | `skill_yinrou_jichu_skill` + `skill_yinrou_jichu_ult` |
| xiangYang | weapon_xiangyang_gang_dao | gangMeng | `skill_gangmeng_changlian_skill` + `skill_gangmeng_changlian_ult` |
| xiangYang | weapon_xiangyang_chang_jian | lingQiao | `skill_lingqiao_changlian_skill` + `skill_lingqiao_changlian_ult` |
| xiangYang | weapon_xiangyang_jiu_jie_bian | yinRou | `skill_yinrou_changlian_skill` + `skill_yinrou_changlian_ult` |
| haoJiaHuo | weapon_haojiahuo_qing_feng_jian | lingQiao | `skill_lingqiao_mingjia_skill` + `skill_lingqiao_mingjia_ult` |
| haoJiaHuo | weapon_haojiahuo_xuan_hua_fu | gangMeng | `skill_gangmeng_mingjia_skill` + `skill_gangmeng_mingjia_ult` |
| haoJiaHuo | weapon_haojiahuo_chan_si_suo | yinRou | `skill_yinrou_mingjia_skill` + `skill_yinrou_mingjia_ult` |
| liQi | weapon_liqi_long_quan | lingQiao | `skill_lingqiao_menpai_skill` + `skill_lingqiao_menpai_ult` |
| liQi | weapon_liqi_pan_long_dao | gangMeng | `skill_gangmeng_menpai_skill` + `skill_gangmeng_menpai_ult` |
| liQi | weapon_liqi_lian_zi_bian | yinRou | `skill_yinrou_menpai_skill` + `skill_yinrou_menpai_ult` |
| zhongQi | weapon_zhongqi_po_zhen_chui | gangMeng | `skill_gangmeng_jianghu_skill` + `skill_gangmeng_jianghu_ult` |
| zhongQi | weapon_zhongqi_qing_xu_jian | lingQiao | `skill_lingqiao_jianghu_skill` + `skill_lingqiao_jianghu_ult` |
| zhongQi | weapon_zhongqi_du_long_suo | yinRou | `skill_yinrou_jianghu_skill` + `skill_yinrou_jianghu_ult` |
| baoWu | weapon_baowu_xuan_tian_fu | gangMeng | `skill_gangmeng_shichuan_skill` + `skill_gangmeng_shichuan_ult` |
| baoWu | weapon_baowu_chang_hong_jian | lingQiao | `skill_lingqiao_shichuan_skill` + `skill_lingqiao_shichuan_ult` |
| baoWu | weapon_baowu_xue_lian_bian | yinRou | `skill_yinrou_shichuan_skill` + `skill_yinrou_shichuan_ult` |
| shenWu | weapon_shenwu_po_jun_dao | gangMeng | `skill_gangmeng_chuanshuo_skill` + `skill_gangmeng_chuanshuo_ult` |
| shenWu | weapon_shenwu_tian_wen_jian | lingQiao | `skill_lingqiao_chuanshuo_skill` + `skill_lingqiao_chuanshuo_ult` |
| shenWu | weapon_shenwu_huan_meng_bian | yinRou | `skill_yinrou_chuanshuo_skill` + `skill_yinrou_chuanshuo_ult` |

**机械映射规则**:`tier` ↔ 心法阶后缀(`xunChang→jichu / xiangYang→changlian / haoJiaHuo→mingjia / liQi→menpai / zhongQi→jianghu / baoWu→shichuan / shenWu→chuanshuo`);`schoolBias` ↔ 流派前缀(`lingQiao→lingqiao / gangMeng→gangmeng / yinRou→yinrou`)。

### §3.2 文件改动

| 文件 | 改动 |
|---|---|
| `data/equipment.yaml` | +21 行 specialSkillCandidates(21 件 weapon),armor/accessory 不动 |
| `test/data/defs/defs_test.dart` | case 2 +1 assert(`specialSkillCandidates isEmpty` 缺省)+ 新加 1 case「specialSkillCandidates 显式提供」(+2 assert) |
| `test/data/game_repository_test.dart` | 新加 1 case「21 weapon 2 candidates / 14 armor+accessory 留空 + skill_id 在 skills.yaml 存在性」 |

## §4 测试覆盖矩阵(本批 +2 case)

| 测试文件 | 新 case | 验证内容 |
|---|---|---|
| `test/data/defs/defs_test.dart` | `specialSkillCandidates 显式提供 → 正确读出` | yaml round-trip + length=2 + contains 断言 |
| `test/data/game_repository_test.dart` | `P1.1 A4:21 件 weapon 2 候选 / 14 armor+accessory 留空` | 真 equipment.yaml 加载 + slot=weapon 21 件 hasLength(2) + 非 weapon 14 件 isEmpty + skill_id 存在性(防 mapping typo) |

**total**:1170 → **1172 pass**(+2 case)+ 1 skip + 0 fail。

## §5 红线点检

| 红线 | 状态 | 说明 |
|---|---|---|
| §5.3 三系锁死 | ✅ | weapon tier == skill 心法阶 == 玩家境界阶,机械映射天然锁死 |
| §5.4 数值红线 | ✅ | numbers.yaml `forging.slots[3].bonus_value.specialSkill: 1` 是解锁词条非数值加成;skills.yaml 复用 W18 已平衡招式,无新数值引入 |
| §5.6 不硬编码 | ✅ | candidates 全走 yaml,Dart 0 改动 |
| §6.5 三槽 build | ✅ | 槽 3 +19 解锁专属技能,玩家二选一,GDD 原意完整落地 |

## §6 1.0 路线图进度

- ✅ 候选 1 A1 E.1 收徒弹窗(2026-05-21 早,commit `86618f1`)
- ✅ 候选 2 A1 E.5 祖师爷 buff(2026-05-21 早,commit `a0eae82`)
- ✅ 候选 3 A3 共鸣度满级体验(2026-05-21 午,4 commit `3cb9918`→`225ee8e`)
- ✅ **候选 4 A4 开锋 build 内容扩**(本批,2026-05-21 晚)
- → P1.1 加权 4/4 全达标 ✅

## §7 下一步候选(下次会话主菜单)

| # | 任务 | 模型 | 时长 | 备注 |
|---|---|---|---|---|
| **5** ⭐ | P1.1 全收口 + CLAUDE.md §12.2 #11 更新 | opus | 0.5h | founder_ancestor_buff Demo 不实装表述 → 已激活(候选 2 已实装) |
| 6 | Demo §8.4 stage_audit 复跑 | opus | 25min | P1.1 全完成后审 1.0 路线图位置 |
| 7 | M4 #46 Stage 3 美术量产(若决定继续) | opus + 用户产 MJ | 多日 | Stage 2 W1-W6 收官 74 张,Stage 3 = ? |
| 8 | 切下一个 1.0 路线图模块(主线 / 师徒升级 / 武学领悟内容扩) | TBD | TBD | 待 P1.1 全收口后 grill |

**推荐**:候选 5 收尾 P1.1 + 更 CLAUDE.md 表述,然后候选 6 stage_audit 拍板下一阶段重点。

## §8 总时长 vs audit 估算

| 阶段 | 实测 | audit 估算 |
|---|---|---|
| Phase 0 audit + grill | ~25min | 30-45min |
| 实装(21 件 yaml + 3 test case)| ~15min | 30-45min |
| 全量 test + analyze | ~1min | 5-10min |
| closeout doc | ~10min | 15min |
| **总计** | **~50min** | 65-90min |

实测约为 audit 乐观路径估算的 60-75%。原因:① perl 批量插入比预想快;② skill_id 存在性 assert 顺手加;③ 4 grill 全走推荐无往返。

## §9 references

- `docs/handoff/p1_1_a4_forging_phase0_audit_2026-05-21.md`(本批前置 audit doc)
- `data/equipment.yaml` 35 件 fixture(本批 +21 行 specialSkillCandidates)
- `data/skills.yaml` 64 招(63 通用 + 1 joint,候选 3-b 添加,本批复用 42 招)
- `data/numbers.yaml:549-573` forging 配置(3 槽 +10/+15/+19)
- `lib/data/defs/equipment_def.dart:28` specialSkillCandidates schema(早已落)
- `lib/features/equipment/application/forging_service.dart` 137 行 service(早已落)
- `lib/features/equipment/presentation/forging_panel.dart` 312 行 UI(早已落含「无专属技能」兜底)
- GDD §6.5 开锋 3 槽 build + §5.3 三系锁死 + §5.4 数值红线
