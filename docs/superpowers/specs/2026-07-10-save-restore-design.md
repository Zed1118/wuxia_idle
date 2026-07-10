# 存档备份恢复设计

**日期**：2026-07-10  
**分支**：`codex/save-restore-design`  
**范围**：补齐现有本地备份的当前槽恢复能力；不做发布准备，不改玩法、数值、schema 或存档版本。

## 1. 现状与目标

当前 `SaveManagementService` 已支持创建、列出和删除 Isar 紧凑备份，设置页也已展示当前槽状态和最近备份，但“恢复备份”仍为禁用占位。玩家遇到坏档或误操作时，只能得到一个备份文件，不能在游戏内完成恢复。

本批目标：玩家可从当前槽的历史备份中选择一份，游戏先保存当前状态作为安全备份，再用所选备份替换当前槽。恢复完成后关闭游戏，下一次启动由正常 Isar 初始化和既有迁移逻辑加载恢复档。

成功标准：

- 恢复不会覆盖或删除所选历史备份。
- 覆盖当前槽之前必定生成一份可识别的安全备份。
- 非当前槽、备份目录外、缺失、空文件、损坏或未来版本备份均在关闭当前数据库前拒绝。
- 文件替换中断后，下次启动至少能回到恢复前存档，不留下无法启动的半档。
- 恢复成功或数据库关闭后的失败都不继续运行旧 Riverpod/Isar 状态，而是阻塞界面并退出应用。

## 2. 方案选择

### 方案 A：覆盖当前槽，恢复后重启（采用）

恢复前自动备份当前档，关闭 Isar，替换当前槽文件，完成后退出应用。优点是槽位语义不变、影响面有限，旧 provider 和计时器不会继续引用已关闭数据库。缺点是玩家需要重新打开游戏。

### 方案 B：覆盖后在应用内重开（不采用）

替换完成后立即重开 Isar，并刷新全部 provider。表面上少一次重启，但项目中存在持有 Isar/service/timer 的长生命周期对象；一次漏刷就可能读旧实例或产生串档。收益不足以覆盖风险。

### 方案 C：导入空槽（不采用）

把备份复制为另一个槽。它避免覆盖当前档，但需要迁移 `SaveData.slotId` 及各 collection 的 `saveDataId`，还受固定三槽限制，已经不是单纯恢复功能。

## 3. 架构边界

### 3.1 `SaveManagementService`

保留现有备份职责，并新增恢复编排：

- 校验 `SaveBackupInfo` 必须位于当前 `backupDirectory`，文件名必须属于当前槽且扩展名为 `.isar`。
- 把源备份复制为同目录候选文件，不直接打开或修改原备份。
- 调用 `IsarSetup` 校验候选数据库的结构、`SaveData`、槽位、版本和祖师记录。
- 刷新 `lastOnlineAt`，再调用现有 `createBackup()` 保存恢复前状态。
- 关闭当前 Isar 后执行候选文件与当前槽文件的可恢复替换。
- 返回包含安全备份信息的 `SaveRestoreResult`。

文件操作通过一个很小的 `SaveRestoreFileOps` 边界提供 `copy/rename/delete/exists/length`。生产实现使用 `dart:io`，测试实现可在第二次 rename 等指定阶段注入失败，验证回滚路径。该边界不扩展为通用文件系统框架。

### 3.2 `IsarSetup`

新增两个基础设施能力：

1. **候选校验**：用 `_allSchemas` 打开候选副本，不调用 `_ensureSaveData`，检查数据库可打开、存在 id=0 的 `SaveData`、`slotId` 等于当前槽、版本不高于当前程序，并能找到 `founderCharacterId` 对应的祖师。校验后关闭候选实例并清理 lock。旧版本候选允许通过，正式恢复后仍走现有迁移。
2. **中断恢复**：`init()` 在打开正式槽之前检查该槽的 restore candidate/rollback 文件。若正式文件缺失且 rollback 存在，优先恢复 rollback；若只有完整 candidate，则恢复 candidate；若正式文件存在，则清理遗留 candidate/rollback。未完成复制使用 `.partial` 后缀，启动时只删除，不把它当成可恢复数据库。

这些方法持有 `_allSchemas` 和 `_compareVersion` 所需知识，避免 feature 层复制 schema 清单或版本比较。

### 3.3 设置页

现有“恢复备份”按钮在有备份时启用：

- 第一步弹出历史备份列表，按现有 `createdAt` 倒序展示文件名、文件时间和大小。
- 选择后再显示确认对话框，明确“当前进度会先自动备份；恢复后游戏关闭，需要重新打开”。
- 确认后显示不可关闭的处理中状态，防止重复点击或继续操作已关闭数据库。
- 成功后显示不可关闭的结果对话框，唯一动作是“关闭游戏”，调用可测试覆盖的 `AppExit.quit`。
- 关闭数据库前的预检失败：保留应用可用，显示具体失败原因。
- 关闭数据库后的替换失败：即使 rollback 已恢复，当前进程的 Isar 仍已关闭；显示“当前存档已保留，请重新打开游戏”，唯一动作仍为关闭游戏。

玩家可见中文继续集中在 `lib/shared/strings.dart`，不散写到 widget 或 service。

## 4. 文件替换协议

每个槽使用固定临时名，均与正式数据库位于同一目录，保证 rename 不跨卷：

- `wuxia_save_slotN_restore.partial`
- `wuxia_save_slotN_restore_candidate.isar`
- `wuxia_save_slotN_restore_rollback.isar`
- 正式文件：`wuxia_save_slotN.isar`

执行顺序：

1. 清理上次已被 `init()` 处理后的遗留临时文件。
2. 源备份复制到 `.partial`。
3. 复制完成后 rename 为 candidate；只有完整文件才会获得 `.isar` 后缀。
4. 打开 candidate 完成预检并关闭。
5. `touchOnlineNow()` 后创建恢复前安全备份。
6. 关闭当前 Isar。
7. 正式文件 rename 为 rollback。
8. candidate rename 为正式文件。
9. 成功后删除 rollback 和相关 lock；返回成功并退出应用。

失败规则：

- 第 6 步前失败：删除 partial/candidate，当前数据库保持打开，应用可继续使用。
- 第 7 步后、第 8 步前失败：立即尝试把 rollback rename 回正式文件；无论回滚结果如何都要求退出。
- 进程在第 7、8 步之间崩溃：下次 `IsarSetup.init()` 看到正式文件缺失，优先恢复 rollback，保证回到恢复前状态。
- 进程在第 8 步后崩溃：正式文件已是恢复档；下次启动清理 rollback，并按正常迁移流程打开恢复档。
- 安全备份不随临时文件清理删除，它是最终人工兜底。

## 5. 错误模型

新增类型化结果与异常，UI 不解析异常字符串决定流程：

- `SaveRestoreResult`：所选备份、安全备份、目标槽。
- `SaveRestoreException`：`phase`、`requiresRestart`、底层 cause。
- `SaveRestorePhase` 固定为 `preflight`、`safetyBackup`、`closeDatabase`、`swapFiles`、`rollbackFiles` 五个阶段。

`requiresRestart=false` 只允许出现在数据库仍保持打开的预检/安全备份阶段；一旦开始关闭数据库，后续错误必须为 `true`。

## 6. 测试与验收

### Service / Isar

- 成功路径：备份状态 A，当前档改为 B，恢复 A；重开后读到 A，自动安全备份可读到 B。
- 拒绝备份目录外路径、错误槽位、缺失、空文件、损坏文件和未来版本。
- 原备份在恢复前后内容与文件均保留。
- 注入 candidate→正式文件 rename 失败，验证 rollback 恢复正式文件且异常要求重启。
- 构造“正式文件缺失 + rollback/candidate”中断现场，验证下次 `init()` 的恢复优先级。
- 构造“正式文件存在 + 遗留 rollback/partial”，验证启动清理不影响正式档。

### UI

- 无备份时恢复按钮禁用；有多份备份时按时间倒序展示并可选择。
- 确认文案明确自动安全备份和恢复后关闭应用。
- 处理中不可重复触发。
- 预检失败只提示错误，不调用退出。
- 成功及数据库关闭后失败均只提供退出动作，并通过覆盖 `AppExit.quit` 验证调用。

### 批末验证

- `dart format` 与 `flutter analyze lib/ test/`。
- 存档管理、Isar 槽位和设置页定向测试。
- `flutter test --no-pub` 全量回归。
- macOS 1280x720 与 1440x900 实机检查备份选择、确认、处理中和结果对话框无溢出。
- `git diff --check`，PR CI 通过且 annotations 为空后再合并。

## 7. 明确不做

- 不恢复到其他槽，不改写任何 collection 的槽位字段。
- 不在当前进程内重建全局状态或自动重新打开 Isar。
- 不导入任意外部文件；只恢复本游戏在当前槽备份目录中创建的备份。
- 不自动轮转或删除历史备份，不改变备份数量策略。
- 不改 schema、saveVersion、离线收益、数值或玩法。
- 不包含打包、签名、商店资料或其他发布准备。
