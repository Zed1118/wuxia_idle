# Suno V2 素材技术处理报告
- 处理时间：2026-06-10 19:33:25
- 原始目录：`/Users/a10506/Desktop/挂机武侠_音乐音效素材_V2_20260610`
- 输出目录：`/Users/a10506/Desktop/挂机武侠_音乐音效素材_V2_20260610/06_技术处理_可播放裁切版`
- 命名规则：处理版统一使用 `bgm_场景_v2_编号.mp3` / `sfx_用途_v2_编号.mp3`，原始下载文件不改名、不覆盖。
- 处理方式：先检测可播放性、响度与头尾静音，再只按头尾静音边界精确裁切；短音效裁切尾部时保留约 50ms 尾巴，避免切掉瞬态余韵；输出统一为 44.1kHz / stereo mp3。

## 总览
- 扫描 mp3：22 个
- 可播放：22 个
- 无法播放/无法解码：0 个
- 已输出处理版：22 个
- 处理后复检可播放：22 个
- 疑似全静音：0 个
- 检出明显头/尾静音：19 个

## 关键结论
- 未发现无法播放素材，22 个源文件均可正常解码。
- 未发现疑似全静音素材。
- 两条 battle BGM 源文件本身只有十几秒，技术处理只能保证可播放和裁掉空白，不能补成正式长 BGM。
- realmAdvance 两条源文件处理后仍约 9-10 秒，作为“突破反馈音效”偏长；建议后续重生成或创意剪成 2-4 秒版本。

## 命名映射与处理明细
| 源文件 | 处理版命名 | 源时长 | 处理后 | 裁切范围 | 峰值dB | 平均dB | 头静音 | 尾静音 | 状态 / 处理 |
|---|---|---:|---:|---:|---:|---:|---:|---:|---|
| `01_BGM候选/当前接线/battle/battle_v2_candidate_01.mp3` | `bgm/bgm_battle_short_loop_v2_01.mp3` | 17.40s | 17.40s | 0.00-17.40s | -1.2 | -15.8 | 0.30s | 0.00s | 正常可播放；无明显可裁头尾静音，仅标准化转码 |
| `01_BGM候选/当前接线/battle/battle_v2_candidate_02.mp3` | `bgm/bgm_battle_short_loop_v2_02.mp3` | 12.92s | 12.92s | 0.00-12.92s | -3.0 | -17.5 | 0.31s | 0.75s | 正常可播放；无明显可裁头尾静音，仅标准化转码 |
| `01_BGM候选/当前接线/mainMenu/mainMenu_v2_candidate_01.mp3` | `bgm/bgm_main_menu_v2_01.mp3` | 129.60s | 128.53s | 0.00-128.53s | -0.3 | -15.1 | 0.54s | 1.07s | 尾部静音约1.07s；按头尾静音边界精确裁切并重编码 |
| `01_BGM候选/当前接线/mainMenu/mainMenu_v2_candidate_02.mp3` | `bgm/bgm_main_menu_v2_02.mp3` | 162.32s | 159.25s | 0.88-160.12s | -0.0 | -14.5 | 0.88s | 2.20s | 头部静音约0.88s；尾部静音约2.20s；按头尾静音边界精确裁切并重编码 |
| `01_BGM候选/当前接线/seclusion/seclusion_v2_candidate_01.mp3` | `bgm/bgm_seclusion_v2_01.mp3` | 149.76s | 148.36s | 0.00-148.36s | -0.0 | -13.9 | 0.74s | 1.40s | 尾部静音约1.40s；按头尾静音边界精确裁切并重编码 |
| `01_BGM候选/当前接线/seclusion/seclusion_v2_candidate_02.mp3` | `bgm/bgm_seclusion_v2_02.mp3` | 146.64s | 146.64s | 0.00-146.64s | -0.8 | -15.1 | 0.78s | 0.00s | 正常可播放；无明显可裁头尾静音，仅标准化转码 |
| `02_SFX候选/UI/uiTap/uiTap_sfx_v2_candidate_01.mp3` | `sfx_ui/sfx_ui_tap_v2_01.mp3` | 2.00s | 0.11s | 0.00-0.11s | -9.0 | -42.3 | 0.00s | 1.94s | 尾部静音约1.94s；按头尾静音边界精确裁切并重编码 |
| `02_SFX候选/UI/uiTap/uiTap_sfx_v2_candidate_02.mp3` | `sfx_ui/sfx_ui_tap_v2_02.mp3` | 2.00s | 0.12s | 0.00-0.12s | -0.0 | -36.5 | 0.00s | 1.93s | 尾部静音约1.93s；按头尾静音边界精确裁切并重编码 |
| `02_SFX候选/战斗/battleCrit/battleCrit_sfx_v2_candidate_01.mp3` | `sfx_battle/sfx_battle_crit_v2_01.mp3` | 2.00s | 0.31s | 0.00-0.31s | 0.0 | -32.6 | 0.00s | 1.74s | 尾部静音约1.74s；按头尾静音边界精确裁切并重编码 |
| `02_SFX候选/战斗/battleCrit/battleCrit_sfx_v2_candidate_02.mp3` | `sfx_battle/sfx_battle_crit_v2_02.mp3` | 2.00s | 0.43s | 0.00-0.43s | -0.2 | -30.0 | 0.00s | 1.62s | 尾部静音约1.62s；按头尾静音边界精确裁切并重编码 |
| `02_SFX候选/战斗/battleHit/battleHit_sfx_v2_candidate_01.mp3` | `sfx_battle/sfx_battle_hit_v2_01.mp3` | 2.00s | 0.36s | 0.00-0.36s | -0.8 | -21.2 | 0.00s | 1.69s | 尾部静音约1.69s；按头尾静音边界精确裁切并重编码 |
| `02_SFX候选/战斗/battleHit/battleHit_sfx_v2_candidate_02.mp3` | `sfx_battle/sfx_battle_hit_v2_02.mp3` | 2.00s | 0.43s | 0.00-0.43s | -0.2 | -25.3 | 0.00s | 1.62s | 尾部静音约1.62s；按头尾静音边界精确裁切并重编码 |
| `02_SFX候选/战斗/battleInterrupt/battleInterrupt_sfx_v2_candidate_01.mp3` | `sfx_battle/sfx_battle_interrupt_v2_01.mp3` | 2.00s | 1.39s | 0.00-1.39s | -11.0 | -36.1 | 0.00s | 0.66s | 尾部静音约0.66s；按头尾静音边界精确裁切并重编码 |
| `02_SFX候选/战斗/battleInterrupt/battleInterrupt_sfx_v2_candidate_02.mp3` | `sfx_battle/sfx_battle_interrupt_v2_02.mp3` | 5.00s | 2.62s | 0.00-2.62s | 0.0 | -29.8 | 0.00s | 2.43s | 尾部静音约2.43s；按头尾静音边界精确裁切并重编码 |
| `03_短音效候选/掉落突破/rareDrop/rareDrop_sfx_v2_candidate_01.mp3` | `sfx_system/sfx_rare_drop_v2_01.mp3` | 3.64s | 2.66s | 0.00-2.66s | -0.3 | -35.6 | 0.00s | 1.03s | 尾部静音约1.03s；按头尾静音边界精确裁切并重编码 |
| `03_短音效候选/掉落突破/rareDrop/rareDrop_sfx_v2_candidate_02.mp3` | `sfx_system/sfx_rare_drop_v2_02.mp3` | 3.28s | 1.40s | 0.00-1.40s | -0.9 | -27.6 | 0.00s | 1.93s | 尾部静音约1.93s；按头尾静音边界精确裁切并重编码 |
| `03_短音效候选/掉落突破/realmAdvance/realmAdvance_sfx_v2_candidate_01.mp3` | `sfx_system/sfx_realm_advance_v2_01.mp3` | 11.76s | 8.57s | 0.00-8.57s | -1.8 | -18.9 | 0.00s | 3.24s | 尾部静音约3.24s；按头尾静音边界精确裁切并重编码 |
| `03_短音效候选/掉落突破/realmAdvance/realmAdvance_sfx_v2_candidate_02.mp3` | `sfx_system/sfx_realm_advance_v2_02.mp3` | 12.24s | 9.81s | 0.00-9.81s | -4.2 | -18.0 | 0.00s | 2.48s | 尾部静音约2.48s；按头尾静音边界精确裁切并重编码 |
| `03_短音效候选/胜利失败/defeat/defeat_sfx_v2_candidate_01.mp3` | `sfx_result/sfx_result_defeat_v2_01.mp3` | 4.80s | 2.83s | 0.00-2.83s | -0.0 | -24.2 | 0.00s | 2.02s | 尾部静音约2.02s；按头尾静音边界精确裁切并重编码 |
| `03_短音效候选/胜利失败/defeat/defeat_sfx_v2_candidate_02.mp3` | `sfx_result/sfx_result_defeat_v2_02.mp3` | 3.88s | 2.21s | 0.00-2.21s | 0.0 | -22.0 | 0.00s | 1.72s | 尾部静音约1.72s；按头尾静音边界精确裁切并重编码 |
| `03_短音效候选/胜利失败/victory/victory_sfx_v2_candidate_01.mp3` | `sfx_result/sfx_result_victory_v2_01.mp3` | 3.12s | 1.75s | 0.00-1.75s | -0.8 | -28.5 | 0.00s | 1.42s | 尾部静音约1.42s；按头尾静音边界精确裁切并重编码 |
| `03_短音效候选/胜利失败/victory/victory_sfx_v2_candidate_02.mp3` | `sfx_result/sfx_result_victory_v2_02.mp3` | 2.24s | 1.81s | 0.00-1.81s | 0.0 | -21.3 | 0.00s | 0.48s | 尾部静音约0.48s；按头尾静音边界精确裁切并重编码 |

## 后续建议
- 试听时优先使用 `06_技术处理_可播放裁切版` 下的文件。
- battle BGM 建议单独重生成 60-120 秒版本；当前两条只适合作短循环或战斗提示素材。
- realmAdvance 建议后续剪成 2-4 秒强信号版本，或重新提示 Suno 生成更短的一击式突破音效。
