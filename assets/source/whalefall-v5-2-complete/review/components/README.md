# 静态机关与栖息地组合复核

`components-recipe.json` 保存 18 组机关/奖励、H1–H6 六处生态的静态配方。挂点使用原始基底画布像素，尺寸以 `assets/catalog.json` 中的可见轮廓和 world 单位计算。子件绕明确铰点旋转；同一行所有状态共享比例、取景和注册点。

在 BOB 根目录运行：

```sh
node tools/compose-components.cjs
```

脚本使用可解析的 `playwright` 模块。若已装在其他位置，用 `PLAYWRIGHT_MODULE` 指向该模块目录。第二个命令参数可指定输出目录，例如：

```sh
PLAYWRIGHT_MODULE=/absolute/path/to/playwright node tools/compose-components.cjs assets/source/whalefall-v5-2-complete/review/components/reproduced
```

脚本仅读取项目台账、配方和实际 PNG，输出四张合成板与 `composition-render.json`；不改原素材、台账或游戏。`composition-qa.json` 为已目检的静态证据，`reproduction-comparison.json` 为从项目台账复跑的对照结果。

本轮验证：

1. 脚本通过 `node --check`。
2. 当前 192 项台账中的 51 项配方引用全部存在，未发现缺图。
3. 项目复跑的四张合成板与验收板逐像素一致，变换记录无差异。
4. 三档手柄共用固定轴点；7 个开放通道采样 alpha 为 0。
5. 六处生态均有前后组合，H4 额外区分“已布置”与“母蟹胜后完成”。

这些证据覆盖静态组装，不表示动画、引擎碰撞、实际玩法或用户美术确认已完成。门体静态状态存在轻微重绘，按登记的每态尺寸和挂点换图；不能当作连续动画帧直接播放。
