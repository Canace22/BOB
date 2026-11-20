# 当前19房角色对照与工作位补齐

2026-11-16；基线`600a9568`。仅改R3-01视觉props/landmarks，无新增命名角色或动作；未运行sync/build。

已看：`whalefall-v5-2-complete/references/`下N01、22_R3-01、15_R2-01、35_R4-05；下述居民、红索/壳窝位图；`game/build/qa/completion-20261114/runtime/`的01、03、06历史截图。本轮未运行游戏。其余敌人图、outputs图未观看；outputs V2/V3文字已读，其护送和三关敌人不进入19房，只沿用画风。

## 现用归属

- `game/content/whalebelly/world/recipes/R3-01.json`：`hub-yusuo`在(17.4,26)U、高1.3U，`hub-beituo`在(21,26)U、高1.35U；静态交谈，铜横镜/红索、蓝双条大钳/背壳符合N01。源位图统一为`assets/runtime/sprites/<art>/base.png`，同步至`game/art/world-kit/<art>.png`。
- `R2-01.json`：`nursery-sac`在(5.6,19)U、高2.2U，已有壳托和读取float的孔瓣。N01是扎根共生体，与outputs背育囊的旅客不同。不重复授能或增加护送。
- 主角36动作、尸蟹/母蟹、鸣贝八帧、幼体八帧均不缺。`R4-03.json`、`R4-05.json`都用`clam-spit-cycle-v1`；R4-05原画双贝与当前单Boss有差异，但补第二攻击体会改战斗，不列必做。血巢已有核心、覆膜允许程序驱动，不按旧missing重做。

## 本轮实施与旧值

1. **余索工作位**：新增prop `red-tether-segment`，(16.3,25.65)U、宽1.8U、layer 0、`Color(0.6,0.65,0.68,1)`。旧值：不存在。短水平索连接壳营右缘与余索身侧。结头图有红晕未采用；不增柱架/锚点。
2. **贝驮空壳工作位**：`r3-shell-nest-before`移入props，(19.65,26.02)U、宽2.5U、layer 0、`Color(0.85,0.85,0.82,1)`。旧landmark：(20,26)U、宽4U、opacity 0.7、parallax 0.7，已移除。实际看图为三个空壳，现放贝驮左后侧，右端约20.9U、层在角色之后。不加营地交互，不改shell-camp。

JSON解析、diff --check通过。排除props/landmarks后的内容SHA256修改前后一致（`90A4B5…E19548`）。真实比例/接地/钳脚遮挡待根代理统一生成与实机复核；上述坐标为候选摆位。

## 唯一动作建议（未生成）

`yusuo-rope-idle-v1`：右向驻足理索，8帧、约1.2秒循环；脚底固定、铜盔与背索轮廓稳定，两手收紧同一小段红索后回原姿。共享画布/缩放/pivot、RGBA透明；不多手、不变盔镜，无发光/位移/递物/授能。交谈停在持索帧。表现劳动身份；缺此动作不阻断道具补齐。在R3真实镜头验收循环、遮挡、暂停冻结及返回房间。


统一接入后的实际结果与原生GPU／路线验收见[本批主记录](../README.md)。本文件前文为制作前审查，未实现的建议不能据此宣称完成。
