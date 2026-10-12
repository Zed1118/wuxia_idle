# 真实存档冷副本迁移 0.40.0→0.52.0 复验(2026-10-12)

> 用户 2026-10-12 授权「在真档副本上跑迁移,真档目录只读」。代码 = main `1a588a764`(review-followthrough 合入后)。证据根:`~/Desktop/wuxia_save_migration_probe_20261012/`。真实三档全程只读,开工与每轮收尾各核一次 sha256,均不变。

## 结论

| 层 | slot1 | slot2 | slot3 |
|---|---|---|---|
| 纯迁移(生产 `IsarSetup.init` 打开副本) | PASS | PASS | PASS |
| 纯迁移幂等(再开一次) | 0 差异 | 0 差异 | 0 差异 |
| 原生首开→退出(独立 bundle `com.pen.wuxia.realsavemig20261012`) | 进主页+离线弹窗正常;**退出与字段审计未完成**(用户需用电脑,暂停;用户 2026-10-12 定:以后补跑,结论标「含调试数据」) | PASS(21 处差异全归因) | 未跑 |
| 原生再开→退出 | 未跑 | PASS(13 处差异全归因) | 未跑 |

## 真档身份(只读)

| 档 | sha256 | 版本 | mtime | 概况 |
|---|---|---|---|---|
| slot1 | `509be321…` | 0.40.0 | 09-13 16:40 | 6 角色 / 111 装备 / 76 心法;主线 47 关、塔 7 层;离线 08-30 12:23 |
| slot2 | `7d623e76…` | 0.40.0 | 09-13 16:40 | 1 角色;主线 2 关;离线 08-30 22:15 |
| slot3 | `cbfc2298…` | 0.40.0 | 09-13 16:40 | 1 角色;主线 5 关;祖师重伤 3.73h / 紊乱 5.73h;离线 08-30 16:49 |

三档哈希与 `save_migration_050_verification_2026-09-16.md` 记录一致:09-13 之后未被改动。

## 纯迁移差异归因(raw→migrate)

- `saveVersion` 0.40.0→0.52.0;`gauntletRunSerial`/`expeditionRunSerial`/`baicaoMaxDepth`/`duanhunClearedCyclesMax`/`passiveMojianshiRemainder`/`passiveExperienceRemainder`/`innerBreathDisorderHoursRemaining` null→哨兵默认值;桃花岛 `productStocks` null→`[]`。
- `passiveLastSettledAt` 与每名角色的 `recoverySettledAt` = 旧 `lastOnlineAt`(三档均无 active 闭关);伤势、紊乱、轻伤迁移前后不变,符合段 22「只补锚不疗养」。
- 历史奖励墓碑:slot1 60 条(主线 46 + 塔 14 = 7 层 × 2 周目)、slot2 2 条、slot3 5 条,全部 `isHistoricalTombstone`,`createdAt == lastSavedAt`。
- slot1 主线已通 47 关,墓碑 46 条:差的是 `stage_inner_demon_01`。迁移代码明写心魔首通属个人 scope、旧档不猜人(v1.97)。

## 原生 slot2 差异归因

- 首开:离线 1020.874h → 经验 +3062(×3.0/h)、磨剑石 +255(×0.25/h),余数 0.6237 / 0.2186 与公式逐位一致;库存 383→638;累计账同增;各锚推进到退出时刻;`Sect.lastTickAt` = 创建 07-07 + 3×30 天;写入 7 条渐进解锁基线(心魔 open:祖师恰在学徒·熟练即心魔首节点,经验已满)。
- 再开:间隔 2m53s(0.04804h),经验余数 +0.1441、磨剑石余数 +0.0120 逐位吻合;解锁回执身份/首次时间保持,仅观测时间前进。
- 原生运行只改 slot2;slot1/3 容器文件逐字节等于原件。

## 发现(待用户定夺,本次未修)

1. **slot1 残留闭关指针**:角色 6「闭关行者」`currentRetreatSessionId=1`,该会话 `status=completed`(08-05 已收功,且 `realmTierAtStart=zongShi` 与角色学徒境界不符)。`CharacterOccupancyService` 只看指针非空,会把该角色永久判为闭关中;R1 合入后闭关入口也读此占用。属迁移前已存在的数据异常,非本次迁移引入。**根因已定位为调试造档,非生产缺陷**:`Phase2SeedService.seedTeamLineup()`(`lib/features/debug/application/phase2_seed_service.dart:1288-1392`)固定 `now = 2026-07-14`,直接给「闭关行者」写 `retreatSessionId: 1` 而不建会话;id=1 的会话来自另一条调试种子(`visual_route_host.dart:383-405`,宗师·藏经阁,归属角色 1)。生产路径的开始/收功都校验归属并成对写清指针(`seclusion_service.dart:226/594`),无法造出此状态。故 slot1 是含调试数据的档,其原生复验结论只代表「迁移不崩、不改数据」,不代表正常玩家档;本次不改代码。
2. **心魔个人进度展示**:slot1 心魔第 1 关的突破门槛(读全局 `MainlineProgress`)不受影响;但角色面板/心魔列表改读个人收据,会显示无人通过,原通关者可再领一次首通奖励。属 v1.97「旧档不猜人」的既定后果。
3. **退出确认框正文对比度过低**:宣纸底上浅灰字几乎不可读(截图 `shots/04-quit-confirm.png`)。

## 剩余步骤

slot1 退出→冷拷贝→字段审计→再开;slot3 首开→退出→审计(重点:1026h 离线应把 3.73h 重伤 / 5.73h 紊乱疗养到 0)→再开。需要借鼠标约 5 分钟。全部通过后,才能按 09-16 文档的第 2 步,先冷备份再用正式 bundle 打开真档。
