# tool/ — CI 与仓库级工具

> 与 `tools/`(本地开发辅助脚本,不进 CI)职责区分,见其 README。
> **本目录路径被 `.github/workflows/` 引用(如 `tool/coverage_ratchet.dart`),移动/改名前先查 CI。**

| 文件 | 用途 | 消费方 |
|---|---|---|
| `coverage_ratchet.dart` | 行覆盖率棘轮(只升不降),读 `coverage/lcov.info` | CI `ci.yml` |
| `build_acceptance.sh` | 构建验收脚本 | 本地/CI |
| `visual_acceptance.dart` | 视觉验收驱动 | 本地验收流程 |
| `convert_assets_webp.py` | PNG→webp 有损转码(q80,幂等,2026-07-02 资产瘦身批) | 手动 |
