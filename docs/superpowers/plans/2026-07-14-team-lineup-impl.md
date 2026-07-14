# 出战编成屏实装批 · plan(2026-07-14)

> spec:`docs/spec/2026-07-14-team-lineup-screen-design.md`(用户拍板 C 完整编成屏)。
> 执行:bg 会话 inline TDD,worktree `team-lineup-impl`,分支 `feat/team-lineup-screen`。

**目标**:出战编成屏(3 槽+替补池,点选交换)+ `LineupService` 单事务唯一编成写入口
(`activeCharacterIds` 唯一真相源、`isActive` 镜像)+ PR #36 观察①(无主修才弹主/辅修选择)。

**分支**:`feat/team-lineup-screen`(base `bc00917c` = origin/main;docs 切片前 rebase 合并后 main)。

## Phase 0 现查结论(实装依据)

- 替补池口径:**`isActive==false && isAlive && !isFounder` 索引查询**——recruitedDiscipleIds
  只覆盖 E.1(`recruitment_service.dart:170` 唯一写点),Boss 招降/门派任务走 sect 流
  (`sect_recruit_handler.dart:101` 创建 isActive=false、masterId=null、不记 recruited);
  已飞升太祖 = isFounder && inactive,必须排除。
- 闭关锁判据:`Character.currentRetreatSessionId != null`(`isInRetreat` 是构造器死字段,
  seclusion_service 只维护 sessionId;retreat_session 无 characterId,靠角色指针反向绑定)。
- 「战斗态拒」无可检信号:全仓无战斗进行时全局标记,战斗 roster 在 setup 时快照
  (`stage_battle_setup._buildPlayerTeam`)、结算 roster 由 caller 传入;编成屏与 BattleScreen
  路由互斥 → **结构性保证,服务层不做战斗态校验**(spec §2 口径在 docs 切片如实订正)。
- isActive 镜像是真负载:`item_use_service.dart:150`/`post_battle_healing_panel.dart:40`
  用 `.isActiveEqualTo(true)` 生产查询。
- 门派谱世代卷(`lineage_codex_provider.groupGenerations`)按 masterId 归代,换下 join 弟子
  不消失;sect 招收弟子换上后经当代兜底并入。无分叉。
- 研习流现状:`technique_panel_screen.dart:1184` 无主修 auto-main → 改弹选;
  `TechniqueLearnFlowService.learn` 已带 `role` 参数,服务层零改动。
  `learnTechniqueAsMain/AsAssist/Cost` 字符串已预留(strings.dart:1259-1262)。
- invalidation 体例:`post_combat_invalidation.dart` 集中函数;编成版最小集 =
  activeCharacterIdsProvider + characterByIdProvider + 替补池 provider。

## 任务切片(每片 TDD 红→绿→commit)

1. **LineupService + 替补池查询**(application 纯服务)
   - Create `lib/features/lineup/application/lineup_service.dart` +
     Test `test/features/lineup/application/lineup_service_test.dart`
   - `Future<LineupApplyResult> apply({required List<int> newActiveIds})`,单 writeTxn:
     校验通过 → save.activeCharacterIds=new(列表序=站位序)+ 移出者 isActive=false /
     加入者 isActive=true 镜像;装备/心法不动(spec §4)。
   - 校验矩阵(status enum):saveMissing / emptyLineup / tooMany(>3) / duplicateIds /
     unknownCharacter / deadCharacter / founderMissing(save.founderCharacterId ∉ list)/
     ascendedFounder(isFounder && id≠founderCharacterId)/ retreatLocked(成员增删涉及
     currentRetreatSessionId≠null 者;纯槽序重排不拦)。
   - `Future<List<Character>> loadReserve()`:isActive==false && isAlive && !isFounder,
     绝对境界层 desc → id asc。
2. **providers + invalidation**:Create `lineup_providers.dart`(service+reserve,
   riverpod codegen,沿 technique_learn_flow_service_providers 体例)+
   `invalidateAfterLineupChange`;build_runner;container 测。
3. **TeamLineupScreen + 门派谱入口**:Create `lib/features/lineup/presentation/
   team_lineup_screen.dart`;Modify lineage_panel_screen(AppBar action 出战编成)+
   strings.dart(UiStrings 编成 block)。上半 3 槽(slot0 标前排/集火注)、下半替补池
   (弱势提示色不拦截/空态引导文案);点卡 PaperDialog 选动作(上场换槽/下场/互换),
   不做拖拽。Test 三态 + 交换 e2e + 1280×720/1440×900 smoke。
4. **研习主/辅修弹选**:Modify technique_panel_screen `_confirmAndLearn`:无主修 →
   二确 dialog 升级为三键(立为主修·500 / 纳为辅修·100 / 取消,消费预留字符串);
   有主修维持现状(仅辅修,零新散功)。Test:无主修双分支 + 有主修不弹。
5. **回归 + 视觉路由**:apply 后 battle setup 组队顺序/founder buff 复算回归测;
   visual_route_host 加 `team_lineup` 路由(seed 含 founder+2 active+2 inactive)。
6. **docs 收口**(等 PR #38 合并后 rebase origin/main):spec §2 战斗态口径订正一行 +
   backlog §十三 #4 勾账 + PROGRESS 顶段 + CLAUDE.md v1.39 摘要 + 本文件恢复点。
7. **批末门禁**:analyze 0 → format 0 changed → 新测 targeted → **全量并发**
   (触存档写路径,spec §5 要求)→ push + draft PR。

## 验收标准(§8.2 转写)

- [ ] 生产接线:入口=门派谱 AppBar「出战编成」;消费方=stage_battle_setup(零改动,
      列表序自然生效)+ founder_buff + item_use/healing isActive 查询。
- [ ] targeted:lineup service 矩阵 + screen 三态 + 研习双分支 + 回归测全绿,贴数。
- [ ] 红线:零数值/零 schema/零 saveVer;三系无涉(换人不动装备);§5.1 无涉;
      中文全进 UiStrings;§5.7 替补空态只引导不弹教程。
- [ ] UI 加码:1280×720 + 1440×900 smoke;交互卡 semantics/键盘可达(沿 PlaqueButton)。
- [ ] 残留风险如实列(PR body):真机目检待 Codex;战斗态口径订正。

## 当前恢复点

- 状态:Phase 0 完成,切片 1 进行中(TDD 红)。
- 最后完成:worktree 环境预热(pub get + dylib + build_runner 116 outputs + 冒烟 8/8 绿)。
- 下一步:写 lineup_service_test 校验矩阵(红)→ 实装 LineupService(绿)→ commit。
- 已跑验证:冒烟 technique_learn_flow_service_test 8 pass(本 worktree)。
- 阻塞项:PR #38 CI test job 重跑中(bg watcher 盯),合并后才能做切片 6 docs rebase。
