# Phase 2 战场边界与终局技能印返工（2026-09-05）

> 后续已获用户授权进入 main；精确集成 SHA、全量返工与 CI 结果见[集成验收报告](phase2_desktop_fixes_integration_2026-09-05.md)。下文保留候选冻结时的验证边界，不回填历史版本为最终版本 PASS。

## 核心结论

- 用户授权“按照建议修复”。本轮两个客观缺陷均完成本地修复与实机复验：**0/2 → 2/2**。正式里程碑仍 **1/10 = 10%**；本分支合计包含上一轮四项及本轮两项修复，不将六个缺陷计入 M0–M9 分母。
- 冻结运行的代码版本：`8c50f0f99cb7eac1955dd0d1cead099ac62490e4`。后续收口提交只更新文档；不能把文档 HEAD 偷换为已构建运行的 SHA。
- **生产路径**：主线、塔、轻功、守城、断魂庄等宿主共用 `Phase0aBattleScreen → Phase0aStage`；修复在共享表现层生效。未改领域坐标、75% 镜头范围、攻击距离、AI、战斗数值、奖励、迁移集合或存档格式。
- **验证**：有效 RED 3 FAIL；扩展回归 **249 PASS**；增强屏外选敌断言后定向 **15 PASS**（与 249 重叠，不相加）。移除屏外鼠标保护得到 1 FAIL，恢复后通过。analyze 无问题、format/diff check、测试契约迁移 Gate、macOS Profile 构建通过。
- **实机**：同 AOT、独立 bundle ID、真实存档副本，从生产根入口进入轻功、守城、断魂庄及主线。1280×720 检查通过；守城另做目标 1440×900 的原生窗口扩展 smoke，工具只返回缩略图，未取得精确原生 frame 读回，尺寸证据限制见下。
- **交付状态**：本地修复候选写完待评；未合并 main、未 push、无新增 CI。main/origin/main 仍 `79adb840be807e0ef6af048b2f9deef0732bd0ab`、clean。正式分发包、统一集成 SHA 与完整 M4 验收尚未放行。

## 缺陷、措施与复验

| 缺陷 | 根因与修复 | 冻结版本实测 |
| --- | --- | --- |
| 人物被视口/HUD 边缘裁切、屏外人物仍能点击 | 原投影安全区只留脚点边距，没有完整人物尺寸和底部 HUD 带；现在为脚点投影预留最大半宽、镜头上沿对应身高及 180 px 底部表现区。镜头外 actor 不绘制且不参与鼠标选敌，仍保留领域角色和 resident widget；下方屏外威胁标记同样避让 HUD | 轻功开场三名敌人、守城开场可见敌人、断魂庄首关三名敌人的上下边缘与底部控件分开。守城暂停、扩展窗口、恢复、失败再战流程已实走。镜头外敌人没有强行挪进画面，不声称所有敌人始终可见 |
| 胜利后存活角色 Q/R 显示“倒地” | 终局禁用复用 down 状态，原印章直接显示其说明；现在存活终局隐藏 Q/R 状态行及对应语义，保留禁用，真实倒地仍显示倒地 | 主线 `stage_01_05` 风雨渡口可见重打胜利：祖师气血 **6070/6070**、真气 **20/100**；画面及 AX 只保留“聚 Q / 清 R”，没有倒地；继续后回关卡、章节、主菜单 |

近身围攻时人物之间仍有重叠，Boss 自身条目也可能压住立绘局部；本轮只关闭**视口/底部 HUD 边界缺陷**，不把它外推为高密度信息层级全面通过。断魂庄本次实际败局，离庄后帖子 1→0；没有声称三关通关或全机制应对通过。

## 自动化与测试契约

```sh
flutter test --no-pub --reporter expanded \
  test/features/battle/presentation/phase0a \
  test/features/mainline/presentation/phase0a_mainline_wiring_test.dart \
  test/features/tower/presentation/phase0a_tower_wiring_test.dart \
  test/features/boss_gauntlet/gauntlet_entry_flow_test.dart \
  test/features/mainline/application/phase0a_mainline_g2_production_acceptance_test.dart
# 249 PASS，报告耗时 00:33；日志 /tmp/phase2-visibility-tests.ZvLJR6

flutter test --no-pub --reporter expanded \
  test/features/battle/presentation/phase0a/phase0a_offscreen_indicator_test.dart
# 加强 primary-click / 隐藏选中标记 / 实际 attack command 检查后 15 PASS

flutter analyze --no-pub
# No issues found

bash tools/test_contract_migration_gate.sh . \
  b13a0094938921be39853a9cd0e0093c2030ef74 \
  8c50f0f99cb7eac1955dd0d1cead099ac62490e4 \
  docs/dispatch/phase2_wiring/test_contract_migrations/p2-m4-battle-visibility-20260905.yaml
# PASS：expect 删除 1 / 新增 30，用例删除 0 / 新增 5，登记 1
```

- 两个精确测试视口为 1280×720、1440×900，含镜头中部及 arena 极值的完整人物边界、HUD 分离、仿射逆变换。真实宿主终局检查同时保留键鼠禁用；实际倒地和空槽原合同未放宽。
- `skipOffstage: false` 检查所有 25 个 resident 人物图片的解码上限，不能用可见人数减少偷渡性能通过。层级测试按实际像素滞回判定，不再把旧投影的固定等待时长当合同；鼠标 fixture 改为镜头内的远目标，仍检查打中远目标而非最近敌人。
- 唯一删除的负载断言为严格浮点向量相等，替换为 x/y 两轴 `1e-9` 容差，登记文件如上。未改生产坐标来凑测试。
- 初始一次过滤器未选中测试、装置编译问题、旧投影假设导致的中间失败不算有效 RED。有效 RED 分别命中双视口越界和存活终局误报；后续 mutation 精确命中隐藏敌人被鼠标选中。恢复后的生产代码与冻结版本一致。
- 本轮没有全仓测试或 CI，不把 targeted/analyze/Profile 代称为全仓通过；合并批次仍须受控全量与 merge exact-SHA CI。

## 包、实机与存档证据

冻结包：`build/phase2_human_acceptance/8c50f0f99cb7/`，macOS Profile 203.6 MB，入口 `production_root_app`。

- AOT SHA256：`85ce101e3a9d2b074f52b16ee55a1e76158f4a3357aea8fb7bd114ef8ba2e43f`。
- fixture SHA256：`becb25943a9f455e77ed1fead7432a6568411b745232600ea12e36a7d94a10fd`，未使用 fixture/visual route 替代实机。
- archive SHA256：`0ff613a57579e9c8c1411bf63b6d6f574651c48dad0e4c8017b70c11f9fca9a0`。
- 实际运行 `build/phase2-visibility-review-20260905.0l1od4/wuxia_visibility.app`，独立 ID `com.pen.wuxia.acceptance20260905`；仅改 root bundle ID 并按原 entitlement 本地签名。AOT 逐字节相同，`codesign --verify --deep --strict` 通过；不等同原 archive 的分发签名验收。
- 原生截图/AX 在本任务工具记录中，没有伪造本地截图文件。关键标题：“以祖师验证真实主线胜利流程”“检查胜利时角色存活与技能印文案”“完成主线胜利结算”“开局检查连战人物边缘”“确认断魂庄结算返回”。轻功、守城及尺寸切换记录在本轮前段。
- 尺寸口径：1280×720 有截图像素与设置项证据；从该窗口右下角原生拖拽增宽 160、增高 180，目标 1440×900。大窗口截图由工具缩为 1229×768，不能把缩略图尺寸当实际窗口尺寸，也不声称获得了精确原生 frame 读回。两种精确尺寸的布局断言属于自动化证据；正式尺寸验收需要可读回的窗口尺寸证据。

只在隔离容器写入；测试前将上一轮隔离 slot1 保留为 `build/phase2-visibility-review-20260905.0l1od4/slot1_before_visibility_review.isar`，再复制同编号冷备份。没有打开或覆盖原用户容器。本轮结束应用已退出（进程检查无匹配）。原三档 SHA256 在 GUI 复验前后核对一致，分别为：

1. `5fce0b9680c4aa5e4106d6089ae29e04e8a440e5a61c3859651415e201ca003e`
2. `bc1dedc1af41e2eae27483045a345e80b3140beb6b05d1c02c08c5a583732f5d`
3. `c0022dcd9c2d70304ddeab85d79d75ac70bf4f7463883338a06fd45de7af52e4`

这仅证明**本轮**原档字节未变；上一轮首次打开原包时的文件字节变化与 3×26 collection 业务比对结果，仍按[首轮报告](phase2_delegated_desktop_acceptance_2026-09-05.md)保留，不改写历史。

## 收口与下一步

- 成本：13:00 起，约 13:21 收口，使用约 21/60 分钟、剩余约 39 分钟；主成本为墙钟，不伪称 token 归因。25% 检查点已有代码/自动化与部分实机证据，随后完成两个本地缺陷门。正式门增量 0，main 集成返工 0（未集成）。
- 按结果驱动流程冻结同一条候选链，不新增孤立分支或转去堆内容；此 READY 仅为写完待评，不是 M4 关闭。既有验收表和包内 `PENDING_HUMAN_EXECUTION` 不被本报告改成自然人 PASS。
- 仍开放：① main 合入后的全量、exact-SHA CI 和统一版本复验；② 近身重叠、五武器完整手感、Boss 应对、长时输入/新叙事等剩余客观检查；③ 精确原生尺寸读回、实际听感及 Windows 实机证据。
- 下一步优先申请合入这一批六项修复并跑集成 Gate；没有新的产品决策待重投票。
