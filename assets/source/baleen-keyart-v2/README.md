# 垂须关键原画与独立2D动画 V2

2026-10-29。本轮完成一簇垂须的六张关键原画、48帧透明动画和Krita母版。沿用既有场景的象牙亮部与深蓝灰阴影，以 [Chaos参考视频](../baleen-chaos/preview.html) 为摆动方向和节奏参考。

[打开原画与动画预览](preview.html)

## 交付

| 文件 | 内容 |
| --- | --- |
| `keyposes-generated.png` | 六姿态原始绘画图，1536×1024，保留生成alpha |
| `keyposes/paint-00.png` 至 `paint-05.png` | 六张独立512×512透明关键原画 |
| `krita/baleen-keyposes.kra` | 六个独立绘画图层，可编辑原画母版 |
| `krita/baleen-sway-12fps.kra` | 原生Krita时间轴，48关键帧、12FPS、384×384 |
| `frames/0000.png` 至 `0047.png` | 48张透明RGBA动画帧 |
| `baleen-sway-atlas.png` | 8列×6行，3072×2304透明图集 |
| `videos/baleen-sway-dark-12fps.mp4` | 4秒暗底预览 |
| `videos/baleen-sway-light-12fps.mp4` | 4秒浅底透明边缘检查 |
| `review/baleen-sway.gif` | 循环查看用GIF；GIF时间单位有限，精确播放以12FPS视频/PNG为准 |
| `workflows/wan22-guided-repair-api.json` | 实际执行的ComfyUI API工作流 |
| `manifest.json` | 根部锚点、时序、逐帧来源与处理说明 |

## 实际使用的工具和来源

1. 原画：内置图像生成工具依据原场景和旧垂须轮廓新绘六姿态；不是Wan生成的六张静态图，也不是手工逐帧绘画。原始生成路径、参考和提示词见 `provenance.json`。
2. 过渡指导：把六张原画统一画幅、固定根带，使用双向DIS光流制作关键姿态间的过渡指导片。保留 `guide-alpha/` 和每段运动场。这是由不同关键原画制作的补间，不是上一版“单张裁片加正弦回位包络”。
3. 实际视频：本地ComfyUI 0.42.0 + Wan2.2 TI2V 5B，fp16权重以fp8_e4m3fn加载；VAEEncode → KSampler → VAEDecode。首轮denoise 0.30偏色/融合，未采用；定向返修denoise 0.10、CFG 2.0，73帧输出保留。两个真实prompt ID及完整历史在 `metadata/`。
4. 后处理：绿色去底、去溢色、用原画指导alpha限制轮廓外残影、固定根带、仅首尾5个源帧做回位修正。全程保留固定384×384画布。最后以预乘alpha进行时间重采样。
5. Krita 5.3.4.1：原生CLI将分层ORA转换成真正Krita像素块；脚本把这些原生像素块组织到48帧时间轴，再用真实Krita `--export-sequence` 导出全部48帧验证。没有把ORA改扩展名冒充KRA。

关键原画依次为静垂、受流、顺流弯曲、反向S弯、反摆、缓和。细化后的纹理略有变化，不能声称每根细丝身份完全一致。

## 时长与循环

实际Wan输出73帧/24FPS = 3.041667秒。按用户规则 `ceil(实际秒数) × 12` 输出48帧、4秒。全动作整体放慢至4秒；没有尾部冻结填充，也没有把生成平台的标称时长当实际时长。

指导片含闭合姿态，交付采样排除重复闭合帧；首尾局部像素回位修正保留在脚本中。可循环预览，但首尾差值不能证明速度连续或自然度，因此不标为严格无缝循环验收通过。

## 已验证与边界

- 实际生成：两个本地Wan任务均保存工作流、prompt ID、历史和源帧；首轮质量不合格已明确记录。
- 已检查六关键原画、八时间点动画对照、明暗底边缘。外侧雾状残影已通过原画alpha上界清理。
- 48张384×384 RGBA，48张内容不同；根部固定区最大色值差1/255，并非1像素位移。
- 原生Krita时间轴12FPS、48关键帧。实际Krita回导48张PNG，与交付PNG逐像素一致，最大通道差0。见 `review/krita-validation.json`。
- 浏览器工具拒绝自动打开本地file页面，因此没有声称完成浏览器互动试玩。用户可直接打开 `preview.html` 查看动画。
- **未做**：原场景四簇不同轮廓的全套重制、主关卡替换、Godot实机验收。这是独立资产制作，不会覆盖已稳定运行的关卡。
- **待确认**：自然度、细丝纹理变化是否可接受、场景尺度下的摆动幅度。现为可编辑候选动画。

## 复跑

在BOB根目录使用已安装的helpers Python：

```powershell
& 'work/wan22-production/helpers/Scripts/python.exe' tools/baleen_keyart_v2.py prepare
& 'work/wan22-production/helpers/Scripts/python.exe' tools/baleen_keyart_v2.py repair
& 'work/wan22-production/helpers/Scripts/python.exe' tools/finish_baleen_keyart_v2.py
& 'work/wan22-production/helpers/Scripts/python.exe' tools/baleen_kra_native.py prepare
& 'work/wan22-production/helpers/Scripts/python.exe' tools/baleen_kra_native.py assemble
& 'work/wan22-production/helpers/Scripts/python.exe' tools/baleen_kra_native.py verify
```

已完成的Wan任务会直接复用；不要删除job记录重交。脚本重建会覆盖本批导出与KRA，手工修改母版后请先另存分支副本。

## Krita导入返修记录

旧Python导入器的 `rename` 因既有 consumed 文件产生错误；本轮新增导入器没有成功运行，最终采用上述原生CLI转换和回导验证路线。原始Krita会话未强制关闭。首次时间轴装配遇到ZIP中文目录编码与重复animation节点问题，修正为ASCII内部路径并只保留一套动画范围后，回导48帧通过。具体脚本保留供复用。

官方源码关于batch导出入口参见 [Krita main.cc](https://github.com/KDE/krita/blob/master/krita/main.cc)；本轮以已安装版本实际运行结果为验收依据。
