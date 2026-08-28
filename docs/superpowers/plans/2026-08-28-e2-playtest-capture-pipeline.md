# 2026-08-28 E2 真机打局录屏验收管线计划

## 结果合同

- 单一目标：在唯一基线 `1ba913a633beb0fd8f9b47764161f47c54260707` 上，从生产主菜单经章节地图进入 `stage_01_03` 黑风岭，用 CGEvent 完成一局真实战斗，并产出可回放录屏、入关/首次接敌/技能释放/结算四类关键帧和自洽 manifest。
- 验收分母：E2-1 驱动工具、E2-2 录屏/关键帧/manifest、E2-3 生产首用例、三槽存档收工还原、双向破坏证红、最终质量门与 clean READY tip，共 6 项。
- 实时基线：分支 `codex/p2-e2-playtest-capture-pipeline-20260828`，HEAD 等于唯一基线，工作树 clean。现有 `tools/visual_capture/` 为 17 文件，有静态截图/窗口/锁/manifest 能力，无录屏能力。
- 开工存档：slot1 `9a79f3e1075a83b769978d869960d9ba9f69991f6eb928ff471f7640d9d8c0ed`，slot2 `4624f51775953f23ea7b2acabe8d1a1e51f6b95348966964f679f60406349199`，slot3 `85003feb66802cf10e7a2b4f6c868d50b1eacab3822f311350c498269da06819`；冷备为 `build/playtest_save_backups/e2_opening_JyE2MB/`，三槽 `cmp=0`。
- 当前关键阻塞：需先固化可重用 CGEvent 序列与存档保护，再用当前真实 slot1 校准章节/重打/战斗动作；不允许改档凑入口。
- 预期增量：从 `0/6` 推进到 `6/6` 候选 READY；任一真实 BLOCKED 出口命中就停线，不冒充完成。
- 成本边界：无可靠 usage 读数，按真实墙钟执行；连续约 90 分钟无主门进展则暂停并重评路线。
- 非目标：不做塔、debug/demo route、CI 接线、`lib/` 改动、数值/设计/进度/schema/saveVersion 改动，不 push/merge/revert/main。

## 验收清单

- 生产路径：直启 debug app 可执行文件且不传 route；真实 slot1 从主菜单进章节地图、第一章、黑风岭，进入真实 `Phase0aBattleScreen`。
- 驱动证据：脚本化键盘/鼠标/滚轮/等待/检查点；每个动作前重读 CGWindow bounds 与 screen scale；JSONL 逐步记时、动作、pid/window id/bounds/scale。
- 采集证据：录屏文件非空且 `ffprobe` 可读；四个检查点均抽帧；manifest 绑定 commit/tree/head_tree/dirty、scenario/actions/video/keyframes 的 SHA256 与三槽存档前后值。
- 存档保护：每轮启动前比对冷备；无论成败均停 app，从冷备精确回填三槽并 `cmp`；收工 SHA 必须与开工一致。
- 工具自测：新增脚本均有对应 `*_test.py` / `*_test.sh`；执行删实现支点与强制退化值两向破坏，记录实际失败数后精确反向补丁还原。
- 质量门：`flutter analyze --no-pub lib test tool`、整仓 format check、加锁全量 test、base..head diff check；逐条读 reporter 末行与 `[E]` 数。
- 范围/红线：只改 `tools/` 与 `docs/`，证据只进 `build/`，禁区和 `lib/` 为零 diff；不触发数值硬红线、三系锁死、在线=离线或反主流项。
- receipt：审计单类型，`break_red` 留空，恰好一个 `audit_verification`；与最终 tip/patch 一致。

## 任务切片

1. 复核现有静态截图、D1 CGEvent 与生产入口。
2. 实现 CGEvent 序列驱动、录屏编排、关键帧抽取、manifest 与存档 guard。
3. 补齐工具自测并做双向破坏证红。
4. 构建 app，校准生产动作序列，跑通黑风岭一局。
5. 复核录像/四帧/manifest/三槽，再跑最终质量门。
6. 写 receipt，提交并打 READY tip，确认 clean。

## 当前恢复点

- 状态：`READY`；实现提交 `b0ba6a04`，本记录提交后用空 `[READY]` tip 冻结，并在最终 tip 后生成 ignored 审计收据。
- 最后完成：生产 `stage_01_03` 首用例已产出录屏、manifest 与 `entry / first_contact / skill_release / settlement` 四帧；slot1 收工 sha256 前缀仍为 `9a79f3e1`，本轮未再驱动游戏。
- 下一步：由协调者独立复跑工具、破坏证红、首用例与 receipt/tip 绑定检查；本执行端不自签正式验收，不 push/merge/main。
- 已跑验证：
  - 工具正常态：`cgevent_driver_test.py` 3/3、`extract_keyframes_test.py` 2/2、`write_playtest_manifest_test.py` 2/2、`playtest_capture_test.sh` PASS。
  - 删除实现支点：删除 manifest 的 `actions.window_sample_count` 后，`write_playtest_manifest_test.py` 实测 `errors=1`；精确反向补丁还原。
  - 强制退化值：将 `save_protection.restored` 强制为 `false` 后，`write_playtest_manifest_test.py` 实测 `failures=1`；精确反向补丁还原，复跑 2/2 OK，`git diff --exit-code` 为 0。
  - analyze：`No issues found! (ran in 92.4s)`。
  - format：`Formatted 1626 files (0 changed) in 16.67 seconds.`。
  - 带锁全量：`12:32 +5643: All tests passed!`，`[E]=0`，退出 0，锁已释放。
  - `git diff --check 1ba913a6..HEAD` 退出 0；`lib/` 与禁区改动均为 0。
- 阻塞项：无；候选 READY 不等于协调者独立验收或集成/main 完成。
