# P2 G2 真人验收候选统一收口

## 目标与分母

在不修改 `main` / `origin/main`、不 push、不改 schema / migration / GDD 的前提下,将用户已选择的姿态 B、破防 A 与攻击令牌 A(`1/1/1/1`)收敛到一条干净统一候选链,交付 `G2-HUMAN-READY` 证据。权威分母仍是《二阶段优化方案》M2 的八项真人试玩检查;未获得用户逐项签字前,不宣称 G2 或 M2 通过。

## 分支与恢复基线

- worktree:`/Users/a10506/Desktop/Projects/挂机武侠-p2-g2-ready-20260827`
- branch:`codex/p2-g2-human-ready-20260827`
- base:`049fce083417077ed178f7b50294f4fdadc7a97a`
- 恢复边界:原 N6 / N10 / N11 与挂机 runner 进程保持 `SIGSTOP`;不使用它们的脏工作树,不恢复、不清理。

## 验收标准

1. 姿态、Boss 强控转姿态、破防加成和攻击令牌均由生产 YAML 经 typed loader 进入真实 reducer / `stage_01_03` 宿主,无 fixture-only 绕路。
2. 直接相关 targeted tests 通过,并有至少一项会对生产值漂移报红的负向证明。
3. 真实 `stage_01_03` 可连续清完 40 敌,手动 / bot / headless 复用同核生产规则;不把局部纯领域测试冒充生产验收。
4. `1280×720` 与 `1440×900` 常规视口完成生产路由 visual smoke;性能证据按方案 §21.5 标记已测、未测或阻塞,不降低真实敌人数粉饰结果。
5. `dart format --output=none --set-exit-if-changed .`、`flutter analyze --no-pub`、批末 `flutter test --no-pub` 通过;另检查 reporter 中的真实失败记录。
6. 无新中文文案/数值常量散写进 Dart,无 schema/迁移,无红线、三系锁死或在线=离线口径变更。
7. 统一候选工作树 clean,tip 以 `[BLOCKED]` 或 `[READY]` 如实标记;未完成八项人类签字时使用 `[BLOCKED]`。

## 任务切片

1. 从干净 main 新建候选 worktree,恢复 Flutter / Isar 环境前置。
2. 复核并串行接入 P1 姿态、N1 破防、T1 攻击令牌;排除与用户选择冲突的 T2。
3. 运行姿态/破防/令牌/生产目录/40 敌纵切 targeted 回归和负向证明。
4. 只读对账 G0 决策签字,不借此扩面实现。
5. 跑生产入口、双视口 visual smoke 与可行的物理 profile;然后跑 analyze / format / 全量。
6. 生成八项 `PASS / REWORK / BLOCKED` 晨间表,冻结干净候选,不合并 main。

## 当前恢复点

- 状态:`WIP`。
- 最后完成:已新建干净 worktree,运行 `flutter pub get` 和 `dart run build_runner build --delete-conflicting-outputs`;已串行 cherry-pick P1/N1/T1 七个实质提交,T2 未接入。
- 已跑验证:姿态 10、姿态生产接线 5、破防 3、防御纵切 5、战斗屏 28、生产 G2 纵切 2、令牌/目录/候选/调参 28,均通过。
- 下一步:跑攻击令牌生产值 break-red,接着进行真实入口、双视口与 profile 验证。
- 阻塞项:用户的 G2 八项主观签字只能在人类试玩后完成;本批只能交付 `G2-HUMAN-READY`。
