# Nightshift Plan · 2026-05-20 Demo §8.4 polish nightshift(opus)

Window: 用户睡眠 8h 内(opus 1.5-2x sonnet,实际预期 4.5-6h 串行完成)
Total tasks: 8
Model: **opus**(全 task,用户钉死)
Dispatcher 间隔: 30s buffer(task timeout 75m + 30s 间隔)
HEAD baseline: `598015a`(main, 0 issues + 1119 pass + 1 skip)

> **本批主题**:Demo §8.4 14 项达标后的「polish 丰满化」批次。心法相生触 §4.5 上限 / 武学领悟 / 基础奇遇 / 心法 description 占位填实 / narrative 文案 / Phase 5+ 师徒 spec 起草 / closeout 收尾。
>
> **task pool 设计原则**:① 8 task 全独立无 file 冲突(0 file overlap,见冲突排雷表);② 全 **opus --print** 跑;③ T01-T03 数值类(改 yaml + test);T04-T06 文案类(yaml 内容);T07-T08 文档类(audit + closeout);④ T02/T04/T05 跨 worktree 共享 14 个钉死 id(spec 已 hard-code);⑤ 每 task spec Phase 0 reality check 必跑;⑥ 用 Edit 工具不 Write 整文件(opus 64K output cap)。
>
> **沿用 2026-05-19 nightshift 教训**:① dispatcher auto-create worktree(`-B` 覆盖);② verify "改动越界" 改 `git diff-tree --no-commit-id --name-only -r HEAD`(memory `feedback_nightshift_verify_changedoutside_bug`);③ analyze `--fatal-warnings` 不 `--fatal-infos`(memory `feedback_flutter_analyze_fatal_errors_invalid`);④ `CLAUDE_CODE_MAX_OUTPUT_TOKENS=64000` env(memory `feedback_nightshift_max_output_token`);⑤ 数字必 grep 实测不写死(memory `feedback_closeout_numbers_grep`)。
>
> **文件冲突排雷表(0 overlap ✅)**:
> - T01 → `data/synergies.yaml` + `test/balance/synergy_hot_loop_upgrade_test.dart`
> - T02 → `data/encounters.yaml` + `data/encounter_skills.yaml` + `test/data/encounters_loader_test.dart`
> - T03 → `data/techniques.yaml`(只改 21 处 description 字段)
> - T04 → `data/narratives/techniques/insights/` ×5 新文件
> - T05 → `data/events/` ×4 新文件
> - T06 → `data/narratives/techniques/` ×4 新文件(不动 insights/ 子目录)
> - T07 → `docs/handoff/phase5_master_disciple_spec_2026-05-20.md`
> - T08 → `docs/handoff/p1_45_demo_polish_closeout_2026-05-20.md`

## T01: 心法相生 +3(5→8 触 §4.5 上限)+ 红线 test
- status: pending · worktree: ../wuxia-idle-T01 · skippable: true · timeout: 75m · risk: low · type: A 数值
- goal: synergies.yaml 5→8(刚阴互制 / 灵刚汇流 / 灵阴归一,反向 schoolPair)+ test/balance/synergy_hot_loop_upgrade_test.dart +3 红线 case。**数值红线** ≤ 0.30 per multiplier。详 `.nightshift/prompts/T01.md`。
- verify: `bash .nightshift/prompts/T01.verify.sh`

## T02: encounters.yaml +9(领悟 +5 / 奇遇 +4)+ encounter_skills.yaml +5
- status: pending · worktree: ../wuxia-idle-T02 · skippable: true · timeout: 75m · risk: mid · type: A 数值
- goal: 5 武学领悟(qing_lin_si_yu / gu_dao_chi_jian / mo_jian_ru_yu / xue_ye_xing_kong / chuan_long_dan_xin)+ 联结 5 招(skill_encounter_*)+ 4 基础奇遇(qin_lou_fang_you / gu_si_qiu_shu / ma_kuai_song_hua / xian_zhou_yi_lu)。详 `.nightshift/prompts/T02.md`。
- verify: `bash .nightshift/prompts/T02.verify.sh`

## T03: techniques.yaml 21 本 description 占位 → 真文案
- status: pending · worktree: ../wuxia-idle-T03 · skippable: true · timeout: 75m · risk: low · type: B 文案
- goal: 21 处 `description: TODO_NARRATIVE` → 真文案(沿 Tier 风格梯度 7 阶,memory `feedback_collab_mode_single_lore_workflow`)。**必 Edit 不 Write**(opus 64K cap)。详 `.nightshift/prompts/T03.md`。
- verify: `bash .nightshift/prompts/T03.verify.sh`

## T04: 武学领悟招式 narrative +5(insights/)
- status: pending · worktree: ../wuxia-idle-T04 · skippable: true · timeout: 75m · risk: low · type: B 文案
- goal: 5 个新 yaml 文件,对应 T02 钉死招式 id(tian_xin_ting_yu / gu_dao_jian_yi / mo_jian_xiang_xin / xue_ye_xing_yi / chuan_long_xiao_ge)。沿既有 35 个 insights 体例(id/name/description/prerequisite_hint)。详 `.nightshift/prompts/T04.md`。
- verify: `bash .nightshift/prompts/T04.verify.sh`

## T05: 基础奇遇 events narrative +4
- status: pending · worktree: ../wuxia-idle-T05 · skippable: true · timeout: 75m · risk: low · type: B 文案
- goal: 4 个新 yaml 文件,对应 T02 钉死奇遇 id。沿既有 46 events 体例(id/title/opening/3 choices)。outcome_id 严格匹配 T02 outcomeMapping。详 `.nightshift/prompts/T05.md`。
- verify: `bash .nightshift/prompts/T05.verify.sh`

## T06: 心法 narrative +4(冰魄/赤阳/流云/太一)
- status: pending · worktree: ../wuxia-idle-T06 · skippable: true · timeout: 75m · risk: low · type: B 文案
- goal: 4 个新心法 yaml(bing_pian_xin_jue / chi_yang_jin_gang_quan / liu_yun_qing_ling_shen_fa / tai_yi_xuan_shen_jue)。沿既有 22 本体例(id/name/origin/[mantra]/moves×3)。详 `.nightshift/prompts/T06.md`。
- verify: `bash .nightshift/prompts/T06.verify.sh`

## T07: Phase 5+ 师徒升级 spec 起草
- status: pending · worktree: ../wuxia-idle-T07 · skippable: true · timeout: 75m · risk: low · type: D doc
- goal: 起草 `docs/handoff/phase5_master_disciple_spec_2026-05-20.md`(60-80 行),含飞升机制 + 收徒孙 + 祖师爷 buff + 遗物 4 规则代码实装清单。**0 改 yaml/lib**。详 `.nightshift/prompts/T07.md`。
- verify: `bash .nightshift/prompts/T07.verify.sh`

## T08: Demo §8.4 验收 + closeout
- status: pending · worktree: ../wuxia-idle-T08 · skippable: true · timeout: 75m · risk: low · type: C 收尾
- goal: 在 main HEAD 跑全量 flutter test + analyze + Demo §8.4 14 项 grep 实测,起草 `docs/handoff/p1_45_demo_polish_closeout_2026-05-20.md`(100-150 行,7 段)。详 `.nightshift/prompts/T08.md`。
- verify: `bash .nightshift/prompts/T08.verify.sh`

---

## 启动

```bash
bash /Users/a10506/Desktop/挂机武侠/.nightshift/launch.sh
```

`launch.sh` 内含 `caffeinate -dimsu nohup ... &` + disown,关闭 Terminal 不影响 dispatcher。

## Dry-run(睡前必跑一次)

```bash
bash /Users/a10506/Desktop/挂机武侠/.nightshift/dispatcher.sh --dry-run
```

< 5 s 完成,看到「DRY RUN: would auto-create worktree ... + claude --print ...」说明 dispatcher 健康。

## 早上 cherry-pick 3 phase 清单

详 `.nightshift/prompts/T08.md` Phase 1 → `docs/handoff/p1_45_demo_polish_closeout_2026-05-20.md` §4,核心动作:

```bash
# Phase A · 阅状态(5 min)
ls /Users/a10506/Desktop/挂机武侠/.nightshift/status/
tail -100 /Users/a10506/Desktop/挂机武侠/.nightshift/logs/dispatcher.log
git log --all --oneline | grep nightshift   # 8 task commits

# Phase B · 各 task git diff(各 1-2 min)
for t in T01 T02 T03 T04 T05 T06 T07 T08; do
  echo "=== $t ==="; cd "/Users/a10506/Desktop/wuxia-idle-$t" 2>/dev/null && git diff main..HEAD --stat
done

# Phase C · cherry-pick 合 main(各 10-30 s)
cd /Users/a10506/Desktop/挂机武侠 && git checkout main
git cherry-pick nightshift/T01 nightshift/T02 nightshift/T03 nightshift/T04 nightshift/T05 nightshift/T06 nightshift/T07
# T08 closeout 不合 main(本 PROGRESS 更新由主对话 review 后做)

flutter test                  # 预期 ≥ 1119 + (T01 +3 + T02 +2 ≈ +5) = 1124 pass
flutter analyze --fatal-warnings  # 预期 0 issues
git push origin main
```

## 清理 worktree(早上合并后)

```bash
for t in T01 T02 T03 T04 T05 T06 T07 T08; do
  git worktree remove "../wuxia-idle-$t" 2>/dev/null
  git branch -D "nightshift/$t" 2>/dev/null
done
```

## 风险与已知偏差(opus 专属修补)

1. **opus 比 sonnet 慢 1.5-2x**:task timeout 拉到 75 min,budget 拉到 $8/task(8 task 总 $64 上限)。**实际 opus 预期 25-50 min/task**,8 task 总 3.5-6.7h,8h 窗仍有 1.3-4.5h buffer。
2. **opus output token cap 64K**:CLAUDE_CODE_MAX_OUTPUT_TOKENS=64000 env 已配。**所有 task spec 钉死用 Edit 不 Write 整文件**(T03 21 处 description / T08 closeout 大文件都走 Edit)。
3. **verify "改动越界" bug 修**:`git diff-tree --no-commit-id --name-only -r HEAD`(memory `feedback_nightshift_verify_changedoutside_bug`)。
4. **analyze --fatal-warnings**:不用 --fatal-infos(memory `feedback_flutter_analyze_fatal_errors_invalid`)。
5. **跨 worktree id 一致**:T02/T04/T05 共享 14 个钉死 id,spec 已 hard-code,各 task 不能 paraphrase。
6. **黑名单词**:legendary/epic/史诗/神器/传说级/无敌/最强/究极/霸气/逆天/刀光剑影/血溅,各 verify.sh grep 拦。
7. **Tier 风格梯度**:T03/T06 沿 7 阶语感梯度(memory `feedback_collab_mode_single_lore_workflow`)。
8. **API 网络 / Mac sleep**:`caffeinate -dimsu` + `nohup` 兜底,半夜代理断 → SKIPPED 不阻塞下一个。

## 容错保证

- 全 task `skippable: true`,1 个失败不阻塞下一个
- 每个 task 内 claude 也有 max-budget 兜底($8/task)
- dispatcher 用 perl alarm 强制 75 min/task timeout
- 所有 task 产出在独立 worktree + 独立分支,**main 不会被任何 task 污染**
- T01-T08 全 task 文件 0 重叠(冲突排雷表已验)
