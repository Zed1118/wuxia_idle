# Ch12「名下之实」美术交付报告

生成方式：Codex 内置 `image_gen`，以 Ch10/11 中州敌立绘与 Ch11 场景图为风格锚；立绘采用品红色键生成、本地转 RGBA，并做一次 1 px 边缘收缩。脚底 fraction 按 `alpha > 0` 包围盒底边 `(bbox.bottom - 1) / 1536` 实测。

| 路径 | 尺寸 | 透明确认 | 脚底 fraction | 自评 |
|---|---:|---|---:|---|
| `assets/enemies/zhongzhou_hanjiang_chenggao.png` | 1024×1536 | RGBA；四角 alpha=0 | 0.964844 | 蓑衣、长篙与极稳下盘形成清晰灵巧轮廓，平凡感与真功夫兼具。 |
| `assets/enemies/zhongzhou_huaixiang_quanshi.png` | 1024×1536 | RGBA；四角 alpha=0 | 0.957682 | 短打布衣、老茧筋骨和朴实直拳准确落在“不图名的真功夫”。 |
| `assets/enemies/zhongzhou_qiushan_tiaoshan.png` | 1024×1536 | RGBA；四角 alpha=0 | 0.949870 | 双柴担完整可读，沉身卸力的姿态把阴柔借势藏进劳作动作。 |
| `assets/enemies/zhongzhou_laotie_tiejiang.png` | 1024×1536 | RGBA；四角 alpha=0 | 0.955078 | 裸臂、焦革围裙与精准持锤兼具章中 Boss 体量和守成匠人气质。 |
| `assets/enemies/zhongzhou_huangcun_wuming.png` | 1024×1536 | RGBA；四角 alpha=0 | 0.950521 | 旧衣、扫帚、矮凳和松静坐姿刻意去除名家排场，平凡之下留有无破绽的压迫感。 |
| `assets/scenes/chapter_12_cover.png` | 1456×816 | 不要求透明；RGB | — | 寒江渡、孤舟、远村与微灯串成由渡口通往荒村的旅途，留白克制。 |
| `assets/scenes/narrative_stage_12_01.png` | 1456×816 | 不要求透明；RGB | — | 晨雾冷江与孤舟竹篙清楚建立寒江渡口，人物保持环境尺度。 |
| `assets/scenes/narrative_stage_12_02.png` | 1456×816 | 不要求透明；RGB | — | 槐花、青砖窄巷、旧摊与无字酒旗具足市井生活感，拳师退在巷底。 |
| `assets/scenes/narrative_stage_12_03.png` | 1456×816 | 不要求透明；RGB | — | 湿石阶、克制红叶和雾中挑夫形成绵长向上的秋山道节奏。 |
| `assets/scenes/narrative_stage_12_04.png` | 1456×816 | 不要求透明；RGB | — | 暗室炉火、铁砧、水槽与农具构成有年代的老铁铺，暖光控制克制。 |
| `assets/scenes/narrative_stage_12_05.png` | 1456×816 | 不要求透明；RGB | — | 荒村空路与野店孤灯收束全章，安静、寻常而有末关余味。 |

## QA 结论

- 11 个目标路径全部存在，文件名与缺图清单逐字一致。
- 5 张立绘均为 1024×1536 RGBA，alpha 范围 0–255，四角 alpha=0，全身与主要道具完整；脚底 fraction 为 0.949870–0.964844。
- 章封面及 5 张剧情背景均为 1456×816 RGB，无文字、UI、logo 或 watermark。
