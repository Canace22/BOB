# 须门遗港六条接续原画

[打开原图册的六条接续](../../../docs/鲸腹遗城原画集/须门遗港精修设计/原画册.html#connections)。

本轮补绘E01、E02、E03、E04、E33、E35各一张专用原画：四幅水平主路、两幅上行回访线。每幅参考相邻两房，联合重绘离开、经过、抵达，不把两张房图贴在一起。保留原七房六边、原能力门和原角色；未改game/。

- `images/`：6张无字原尺寸绘画，内置imagegen。
- `prompts/`、`prompts.json`：每图真实英文提示词、参考路径、生成编号。
- `art-manifest.json`：原图尺寸与哈希。
- `reference-manifest.json`：实际用到的7张房间原画哈希。
- `connections.json`：部位、三段接续、地标、光照、材质、分层、动态候选及现碰撞快照。
- `render_atlas.py`：生成可编辑HTML/SVG注记，原画不烘焙文字。
- `acceptance.md`：视觉观察、技术核对与边界。

重新生成图册：在仓库根目录运行`assets/source/xumen-keyart-v2/build_atlas.py`（使用带Pillow的Python）。浏览器检查仍用`node assets/source/xumen-keyart-v2/verify_atlas.cjs`。历史8张主图不重新生成；本轮加6张，合计14张概念原画。

这是接续设计，不是新运行素材或已验证动画。图上的01→02→03为阅读方向，不是碰撞折线。E04只绘胜利后开放态，关闭与动画仍属后续制作；E33/E35的概念压缩图不能用来增减现有8/10级连接平台或推导新锚定距离。
