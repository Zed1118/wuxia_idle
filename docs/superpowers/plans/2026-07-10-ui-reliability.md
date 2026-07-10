# UI Reliability Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 用现有 UI kit 统一标题栏返回/主页动作，并保证关键图片缺失时有可见、稳定、可测试的 fallback。

**Architecture:** 不重排所有页面；只修共享根组件。`WuxiaTitleBar` 复用 `WuxiaIconButton` 获得统一 44px 热区、tooltip、键盘与语义；`WuxiaImage` 保留默认静默收起，但关键业务位必须显式传入 fallback，并用审计测试锁定。

**Tech Stack:** Flutter widgets、Wuxia UI kit、flutter_test。

---

### Task 1: 标题栏动作统一

**Files:**
- Modify: `lib/shared/widgets/wuxia_ui/wuxia_title_bar.dart`
- Test: `test/shared/widgets/wuxia_title_bar_test.dart`

- [x] **Step 1: 写失败测试**：返回和主页均有 44x44 热区、tooltip、Semantics button，点击调用正确 callback。
- [x] **Step 2: 用 `WuxiaIconButton` 替换两个裸 `InkWell`，返回使用 `Icons.arrow_back`，主页使用 `Icons.home_outlined`。**
- [ ] **Step 3: 运行 shared widget 测试与 1280x720 标题栏视觉路由。**
- [ ] **Step 4: 提交**：`git commit -m "Unify title bar navigation actions"`。

### Task 2: WuxiaImage 关键 fallback 审计

**Files:**
- Modify: `test/shared/widgets/wuxia_image_fallback_audit_test.dart`
- Modify: audit 命中的关键 feature 图片调用点

- [x] **Step 1: 定义关键位清单**：主菜单背景、章节/关卡封面、角色头像、装备详情、商店商品和桃花岛地图；装饰纹理、印章允许静默收起。
- [x] **Step 2: 写失败审计测试，读取关键文件并要求对应 `WuxiaImage` 调用包含显式 `errorBuilder`。**
- [x] **Step 3: 每个命中点复用现有业务 fallback（图标、文字或 `ErrorFallback`），不新增占位资产。**
- [x] **Step 4: 运行图片、商店、主菜单、章节、角色和桃花岛定向测试。**
- [ ] **Step 5: macOS 通过注入不存在资产验证 fallback 不溢出、不改变容器尺寸。**
- [ ] **Step 6: 提交**：`git commit -m "Harden critical image fallbacks"`。

## 当前恢复点

- 状态：Task 1 已提交；Task 2 代码与定向验证完成，macOS 视觉验收留在批末统一执行。
- 最后完成：锁定六类关键图片 fallback 契约；主菜单背景与章间封面改为稳定、可诊断的 fallback。
- 下一步：提交 Task 2；进入技能数量契约与文档漂移批次。
- 已跑验证：图片共享组件 8/8；关键页面 141/141；相关 analyze 0 问题。
- 阻塞项：无代码阻塞，按批次顺序等待。
