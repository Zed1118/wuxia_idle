# tools/ — 本地开发辅助脚本

> 与 `tool/`(CI 消费的仓库级工具,路径被 workflows 引用)职责区分,见其 README。
> 本目录**不进 CI**,均为本地手动/会话内工具。

| 条目 | 用途 |
|---|---|
| `visual_capture/` | 视觉验收截图工具链(多分辨率 seed/驱动运行中 app 截图) |
| `audit_paper_text_contrast.py` | 宣纸底文字对比度审计 |
| `run_asset_webp_pilot.sh` | webp 转码试点脚本(正式批量转码用 `tool/convert_assets_webp.py`) |
| `pen_screen/` | 历史 Pen Windows 截图遗留(2026-06-11 该路径已下线) |
