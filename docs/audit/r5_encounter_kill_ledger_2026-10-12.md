# R5 奇遇击杀账口径:影响分析与实装(2026-10-12)

> 用户 2026-10-12 拍板「真实击杀」(BACKLOG 原 #11)。门槛、概率、奖励、schema 均未改动。实装 commit `db190f8fe`。

## 改前事实

- 记账点三处:主线结算 `mainline_settlement.dart`、主线可见重打钩子 `stage_entry_flow.dart`、爬塔钩子 `tower_entry_flow.dart`,均按 `enemyTeam` 每人记 1;主线每关 `enemyTeam` 恒为 1 人。
- 主线 105 关全部已迁 typed 遭遇(`data/combat/manifest/stage_assignments.yaml`),实际出场 2–40 人;同关所有出场敌人共用 `base_enemy_id` 的流派(`phase0a_mainline_repository_runtime_binding_adapter.dart` `school: base.school`)。
- 扫荡与即时快速重打走 `applyVictoryResolution` 但不带 durable 上下文,在记账前返回,两种口径均不记击杀(本次不变)。
- 门槛只是「门」:开门后每场胜利掷一次概率,每场最多触发一个。

## 首通累计(主线 105 关;塔 49 层两口径相同另加 刚38/灵39/阴39)

| 口径 | 刚猛 | 灵巧 | 阴柔 |
|---|---|---|---|
| 旧:每关记 1 | 46 | 28 | 31 |
| 真实击杀(过关必杀 – 全部出场) | 215–265 | 110–137 | 61–69 |

## 击杀门首次打开(主线首通序号)

| 奇遇 | 门槛 | 旧口径 | 真实击杀 |
|---|---|---|---|
| qun_xia_tu | 刚5 | 第9关 | 第1关 |
| jiao_chang_chu_wu | 刚50 | 需塔 | 第2–3关 |
| cha_ting_dui_ju / ma_kuai_song_hua / qin_lou_fang_you | 三系各10/15/20 | 第42/62/79关 | 第13关 |
| gu_si_qiu_shu / xian_zhou_yi_lu | 三系各30/50 | 需塔 | 第20–25 / 43–72关 |
| gu_dao_chi_jian / tie_pu_lian_quan | 刚150/200 | 首通不开 | 第17–31 / 31–64关 |
| chuan_long_dan_xin | 刚250 | 首通不开 | 第64关或加塔 |
| bamboo_listen_rain / qing_lin_si_yu | 灵100 | 首通不开 | 第62–67关 |
| xue_ye_xing_kong / mo_jian_ru_yu / liu_zhi_jian_ying | 灵200/阴120/灵300 | 差约133/50/233次重打 | 差1–3/约1/5–7次重打 |

首通主线+塔后可开门:旧 7/15 → 真实 12/15。另查 2026-07-14 旧版 `stages.yaml`,当时主线每关 `enemyTeam` 亦为 1 人,门槛原按「每关记1+大量重打」标定;扫荡不计击杀后旧口径实际让 8 条成为不可达内容。

## 实装要点

- `CombatSettlementSnapshot.defeatedEnemySchools`:`Phase0aSettlementAdapter` 按 `Phase0aEnemyDefeated` 的单位 id 去重、按首次击败顺序取 `snapshot.school`;玩家或未映射单位被击败即抛 `StateError`(reducer 结算伤害要求每个敌人有快照,故不会误伤正常战斗)。
- 三处记账点改读该列表;钩子去掉「击杀为空即整体跳过」,零击杀胜利照常判定奇遇。durable 路径判定条件不变。
- 守卫:`encounter_kill_ledger_source_test.dart` 禁止 `lib/` 以 `enemyTeam` 生成击杀列表;首关真实键盘战斗断言 25 个刚猛击杀;Ch1 live/headless 同 seed 对拍新增本字段。

## 验证

- 先红:适配器 2、源码契约 1、主线恢复 1(期望2实为1)。
- 双向证红(commit 后):改回 enemyTeam → 恢复 1 + 契约 1 红;列表写死为空 → 适配器 1 + wiring 2 红;还原后绿。
- 定向:适配器 10/10、契约 1/1、主线恢复 2/2、奇遇服务 34/34、主线 wiring 23/23;analyze 0。全量 `flutter test --no-pub`(探针文件移出后)`08:31 +7343: All tests passed!`、0 条 `[E]`、墙钟 514s。

## 未改与后续

- 门槛未重标;如需按新口径重定节奏属改数值,须另行拍板。
- 塔差遣等无 UI 自动路径当前不记击杀,属既有行为,本次未扩。
