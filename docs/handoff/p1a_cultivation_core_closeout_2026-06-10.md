# P1a 养成内核 实装 closeout(2026-06-10 overnight)

> 分支 `feat/p1a-cultivation-core` · 15 commit · 全 ff 合 main + push。
> spec `docs/spec/2026-06-09-playability-p1a-cultivation-core-design.md` · plan 同名 plans/。

## 成果(16 任务全落)

**单元 C 熟练度阶段效果**(C1-C6):numbers.yaml `combat.skill_proficiency` 5 阶(1.00→1.30)+ `SkillProficiency` 纯域(stageFor/combinedMult 130% cap/effectiveCooldown/interruptWindowBonus)+ `SkillDef.proficiency.effects` schema + damage_calculator `proficiencyDamageMult` 乘项 + **双路径 wire**(Character `calculate` / 实战 `_calculateInBattle` 经 `BattleCharacter.skillUses` 进场快照)+ per-skill cooldown_delta / 破招窗口应用。实战端到端验证 900→1170(×1.30)。

**单元 A 技能解锁进度**(A1-A2):`SkillUnlockEntry` @embedded + MapLike(indexWhere)+ `SaveData.skillUnlockProgress` + `SkillUnlockService`(grantManual/addFragment 阈值幂等)。

**单元 B Boss 掉技能书**(B1-B3):numbers.yaml `skill_unlock`(阈值5/残页率0.20)+ `StageDef.dropSkillManualId/FragmentId` + `_enforceSkillDropRedLines`(仅Boss/id存在)+ victory hook(**首通快照** clearedBeforeVictory → 真解只首通给)。

**D1 内容**:3 主线真解(stage_01/02/03_05 → yinrou_mingjia_ult / 青锋绝 / gangmeng_mingjia_ult)+ proficiency.effects(青锋绝/破势/2真解,只配已消费字段)。
**D2 装配 gate**:`SkillDef.canEquipAtRealm`(§5.3,沿 equipEncounterSkill `index>=tier-1` 约定)+ refactor 装配入口调用。
**E1 红线**:+30% 相对 cap airtight 测(4 测)。

## 闸门
analyze 0 / 全量 **1809→1846 测过(+37)/1 skip** / §5.4 守(相对 cap)/ 硬编码 0 新增 / balance_simulator 3000 run 全过(fresh char 零回归)。单元 C review APPROVED_WITH_NITS(已补 interrupt_power_pct 注释)。

## 自主拍板 deviation(详 backlog 六)
1. **残页内容挂载延后**:机制完整+单测,但爬塔在 towers.yaml(非 StageDef)未挂载,差 towers schema+tower flow wire。**真解(主线)已全 wire**。
2. **解锁态消费(注入可用池)= P1b**:spec §六既定,P1a 只做 source,非缺口。
3. **interrupt_power_pct schema-only**:P0 破招二元无标量目标,需设计决策。
4. **166 招 source tag 降级**:P1a 无消费方,不阻塞。
5. **§5.4 绝对测改相对 cap**:满IF+满修炼×3.0 的极值 pre-P1a 即 >8000,绝对测是假红;P1a 数学保证=+30% 相对界。
6. **Isar 修复**:@embedded list fixed-length → service 写前 `List.of()` 转 growable(memory feedback_isar_pitfalls)。
7. **B3 hook 在生产分支**:test stub 路径跳过(无 widget 测覆盖 wire,但 hook 有完整 e2e 域测)。

## 待用户(明早一起做)
- 视觉验收相关(B3+B5 路由 / 音频接入 / 真玩 stage_02_05)全留着,未碰。
- 残页 tower wiring / 解锁态消费(藏经阁 UI)= P1b 下一波。
