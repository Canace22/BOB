# 左向跑动候选

本目录用于继续修正拾潮者左向跑动。当前最佳结果是[四关键姿势 v02](keyposes-v02.png)，可以看出近腿与远腿交替，但还没有可交付的完整循环。完整检查和原始输出路径见 [review.json](review.json)。

`keyposes-v02.png`、提示词、时间线和报告随 Git 保存；被拒图片、五帧查错片段的 PNG/ZIP/工程仅本地保留，下面相应链接不保证在新 checkout 存在。详见[本地证据范围](../../animation-platform-20261102.md#git-与本地证据)。

## 先看哪些文件

| 文件 | 内容与状态 |
| --- | --- |
| [keyposes-v01.png](keyposes-v01.png) | 首稿重复同一半步，拒绝使用 |
| [keyposes-v02.png](keyposes-v02.png) | 修正上右、下左的腿部遮挡；四相位分别静态复核可读，保留作下一步参考 |
| [run16-v01-rejected.png](run16-v01-rejected.png) | 16 格没有保持四关键相位，且头盔尺度漂移，拒绝使用 |
| [quarter-01/inbetweens-v01.png](quarter-01/inbetweens-v01.png) | 关键 1→5 之间的三个新姿势；最后一张近/远腿身份又改变，未通过 |
| [quarter-01/timeline.json](quarter-01/timeline.json) | 原图裁框、公共画布、统一倍率和五帧顺序 |
| [quarter-01/platform-options.json](quarter-01/platform-options.json) | 平台工程的候选名称、帧率、单次标记与限制 |

所有图片旁的 `.prompt.txt` 保存实际生成提示；未删去失败稿。生成器没有完成正确补间，因此没有继续制作余下三段，也没有用复制持帧凑成 16 姿势。

## 在 Framecraft 查看局部候选

在 Framecraft 顶部选择本目录的 `quarter-01/platform/projects/`，打开“拾潮者左向跑动_四分之一周期_腿身份待修”。工程目录是 [45c6189921254c8da015a6d33371449a.framecraft](quarter-01/platform/projects/45c6189921254c8da015a6d33371449a.framecraft/project.json)。原帧、处理结果与参数都随工程保存，已由平台 API 保存并重开核对。

这段只包含原关键 1、三个中间姿势、原关键 5，共五帧、30 FPS、单次播放。它是查错用的局部片段。第 4 帧的前景抬腿与第 5 帧的远腿抬起不能可靠衔接；不应循环，也不能当作完整跑步。

三姿势源图实际为 2170×725，确认三列后使用显式裁框，补至共同 725×725 画布，再统一缩至 627×627；两端 627×627 原帧原样保留。没有逐帧按轮廓放大缩小，没有自动贴脚。公共根尚未注册，处理记录保留在时间线中。

平台再按 75% 等比处理为 470×470，使用 soft/Lanczos、RGBA PNG、透明阈值 2、锐化 20。实际 PNG 总量减少 42.84%，报告见 [platform-run.json](quarter-01/platform/review/platform-run.json)。压缩只降低体积，未修复腿部身份、接地或动作顺序。

平台原样导出保存在 [PNG ZIP](quarter-01/platform/exports/player-left-quarter01-candidate.zip)。导出中的 `loop:true` 是平台固定值；[game-metadata.json](quarter-01/platform/game-metadata.json)另记单次播放与未知根部。它仅供后续接入参考，目前没有游戏加载器使用。

本轮未操作浏览器 UI，未进行完整播放、游戏接入或用户美术验收。后续制作应先解决第 4→5 帧的腿部连接与遮挡，再进行完整周期；原视频可用区间见[批次说明](../README.md)。
