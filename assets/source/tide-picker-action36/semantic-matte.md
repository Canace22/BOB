# 本地语义抠像样板与实测

2026-11-04。入口为 `semantic_matte.py`。它使用已训练的分割模型推理，不生成新造型、不插帧、不恢复被遮挡的身体。初始3帧通过后仍需逐动作、逐帧和实机复核。

## 模型与来源

- 模型：BiRefNet General Lite，官方 rembg 发布的 ONNX 包装，输入固定 `[1,3,1024,1024]`。
- [模型下载](https://github.com/danielgatis/rembg/releases/download/v0.0.0/BiRefNet-general-bb_swin_v1_tiny-epoch_232.onnx)。当前外置路径：`G:\鲸落万物生\work\action36-models\birefnet-general-lite.onnx`。不将224 MB模型打入游戏资源。
- 大小：224,005,088字节。
- 官方 MD5：`4fab47adc4ff364be1713e97b7e66334`，本机实测一致。[rembg模型会话与校验值](https://github.com/danielgatis/rembg/blob/main/rembg/sessions/birefnet_general_lite.py)。
- 本机 SHA256：`5600024376f572a557870a5eb0afb1e5961636bef4e1e22132025467d0f03333`。
- [预处理/后处理参考](https://github.com/danielgatis/rembg/blob/main/rembg/sessions/birefnet_general.py)：1024输入、RGB最大值归一、ImageNet均值/方差、输出sigmoid并归一；本脚本独立实现最小调用。
- [BiRefNet原项目及许可](https://github.com/ZhengPeng7/BiRefNet/blob/main/LICENSE)、[rembg许可](https://github.com/danielgatis/rembg/blob/main/LICENSE.txt)、[ONNX Runtime许可](https://github.com/microsoft/onnxruntime/blob/main/LICENSE)均标为MIT。分发这些软件或实质部分时应保留各自版权/许可文本。CUDA/cuDNN附带NVIDIA自己的许可，不应误标为MIT；依赖仅在工作目录用于离线生产，不打入游戏。

## 依赖隔离与调用

使用捆绑Python 3.12：

```powershell
$taskPython = 'C:\Users\Kingsoft\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe'
& $taskPython -m pip install --target 'G:\鲸落万物生\work\action36-deps' --no-deps onnxruntime==1.31.1 coloredlogs flatbuffers protobuf humanfriendly packaging sympy
$env:PYTHONPATH = 'G:\鲸落万物生\work\action36-deps;G:\鲸落万物生\work\animation-repair-packages'
& $taskPython 'G:\鲸落万物生\BOB\assets\source\tide-picker-action36\semantic_matte.py' --samples
```

`--no-deps`用于避免覆盖已有numpy、cv2、scipy、Pillow；这些从既有 `animation-repair-packages` 读取。依赖安装成功后再启动推理，不要在pip尚复制文件时导入模块。

接口：

```python
from semantic_matte import SemanticMatte, body_rgba
engine = SemanticMatte()  # 当前已验证的默认：CPU，原模型1024分辨率
probability = engine.predict(rgb_uint8_hwc, cache_dir)
body = body_rgba(rgb_uint8_hwc, probability)
```

`predict`返回原输入尺寸的float32概率mask；`body_rgba`保持原RGB造型，去除远处不连通物体，在软边进行源底色反混。不按金色/青色全局阈值从身体挖像素。允许提供已人工审阅的 `reject_rects`，但不能以矩形切除真实身体或武器。

缓存key包含完整模型SHA256、预处理版本、源RGB形状及像素字节。源帧或模型更换会失效；缓存概率与后续色边/层拆处理解耦。`review/mask-cache`可以复用，同一批只创建一个推理会话。无效常量/非有限mask必须报错，不能把全透明输出当成功。

## 已完成的CPU样板

证据：`review/{dash,run,pogo}-semantic-review.jpg`、透明PNG及原mask；接触帧反例 `review/pogo-contact-semantic.jpg`。

| 样板 | 4线程秒/帧 | 8线程秒/帧 | 结论 |
|---|---:|---:|---|
| dash 1.4秒 | 31.22 | 21.56 | 头盔、双叉、红绳和披风完整；尾迹与地影去除，源帧效果明显优于旧色阈值。 |
| run 1.1秒 | 25.33 | 22.06 | 灰底与地影去除；源手脚/披风模糊变形仍在，不是正式动作质量自动通过。 |
| pogo 1.75秒 | 23.14 | 21.77 | 原概率mask也识别了贝壳，最大连通体后可去独立贝壳，完整向下叉保留。 |

8线程对4线程的阈值0.5 IoU分别0.999969、0.999863、0.999894；比较基准为8-bit保存mask，包含量化误差。记录在 `review/cpu8-benchmark.json`。CPU进程工作集曾测到约8.9 GB；不是GPU显存数字，不代表整机峰值。8线程结果只是该机器样板耗时，不据此保证整个批次相同速度。

额外pogo 2.2秒测试：叉接触贝壳后形成同一对象，模型保留贝壳，连通体无法自动分离。已复核第44帧1.833333秒叉与壳仍分离；游戏应采用接触前下刺姿态并由真实碰撞反弹，或为接触段制作明确物体mask。

## DirectML未通过

独立目录 `work/action36-dml` 安装 `onnxruntime-directml==1.24.4`，不覆盖CPU包。DXGI实际枚举确认 device_id=0 是 RTX 5060，证据 `review/directml-adapters.json`。

- 默认图融合：provider列表包含DML，但执行 `DmlFusedNode_17_58` 失败，错误 `0x887A0006`，随后出现异常文字编码错误。不能仅凭provider列表声明GPU运行成功。
- 根据[微软会话配置源码](https://github.com/microsoft/onnxruntime/blob/main/onnxruntime/core/providers/dml/dml_session_options_config_keys.h)关闭图融合后：dash 11.16秒返回全零mask，和CPU阈值IoU为0；第二帧执行又失败。这种结果必须拒收。
- 未改Windows TDR、注册表、驱动或系统级GPU设置。模型固定1024，未擅自改512输入或模型图。
- helper保留显式 `provider='dml'` 诊断支持，失败时警告后转同模型、同1024尺寸CPU。默认仍使用已验证CPU。DirectML不作为本项目已验证的加速方案。

## CUDA验证状态：本次环境未取得有效GPU输出

独立 `work/action36-cuda` 安装了 ONNX Runtime GPU 1.26.0及CUDA12/cuDNN9的Windows wheels，不覆盖CPU包。选择1.26.0参考[官方CUDA兼容表](https://onnxruntime.ai/docs/execution-providers/CUDA-ExecutionProvider.html)。

- 首次因cuDNN可选引擎DLL的加载路径不完整，ORT实际退回CPU。结果虽与CPU一致，但provider列表和profile均证明实际是CPU；旧报告的请求provider字段不能当GPU证据。见 `review/cuda-first-attempt-failure.json`。
- 加入仅本进程有效的DLL搜索路径、显式预加载cuDNN库，并关闭ORT隐藏回退后，CUDA provider成功初始化，但推理出现cuDNN无可用执行计划与arena分配失败。日志包含 `Mul /decoder/decoder_block1/dec_att/aspp_deforms.2/atrous_conv/Mul_6`、可用arena为0、请求822,083,584字节；本次设置的GPU arena上限为5 GiB。超过3分钟仍无有效mask，核实命令行后仅停止了本任务的该次测试进程。
- 不能把本次资源/执行失败解释成模型普遍不兼容RTX 5060。测试期间存在其他项目的CPU重载，未停止或修改；缺少失败瞬间的全系统显存快照，不能排除资源竞争。2026-11-04 02:06事后只读 `nvidia-smi` 显示RTX 5060、驱动596.49、1720/8151 MiB显存、GPU利用率1%；WDDM进程表不提供各进程显存，该事后快照不能还原失败瞬间。
- 不继续CUDA重试，不修改驱动/TDR，不声称GPU加速成功。生产继续已验证CPU方案。

## 轻量CPU模型三帧对比

以下官方rembg模型均通过MD5核验，外置于 `work/action36-models`，不进入游戏。使用同一CPU4线程、同一源帧、同一本体连通体清理及边缘反混。支持调用 `SemanticMatte(model_path=..., model_family='u2net', threads=4)`；默认模型未更改。

| 模型 | 大小/MD5 | dash / run / pogo 秒 | 实际视觉结论 |
|---|---|---|---|
| [U2NetP](https://github.com/danielgatis/rembg/releases/download/v0.0.0/u2netp.onnx) | 4,574,861字节；`8e83ca70e441ab06c318d82300c84806` | 0.72 / 0.56 / 0.64 | run保留大片地影，pogo披风/头盔/叉边有灰白边；不能替代BiRefNet。 |
| [U2Net](https://github.com/danielgatis/rembg/releases/download/v0.0.0/u2net.onnx) | 175,997,641字节；`60024c5c889badc19c04ad937298a77b` | 1.41 / 1.42 / 0.89 | run留地影且叉头半透明，其他样板有软灰边；不能替代BiRefNet。 |
| [ISNet General Use](https://github.com/danielgatis/rembg/releases/download/v0.0.0/isnet-general-use.onnx) | 178,648,008字节；`fc16ebd8b0c10d971d3513d564d01e29` | 3.76 / 3.65 / 2.86 | dash、pogo接近BiRefNet；run上叉齿明显半透明、脚部边缘略丢。只可作为逐动作候选，三帧样板没有全面达到替换条件。 |

已逐张查看深浅底对照 `review/{dash,run,pogo}-{u2netp,u2net}-comparison.jpg`，数值见 `review/light-model-benchmark.json`。较高IoU不能代替细绳、叉齿、脚底和光晕的视觉复核。可重跑样板脚本为 `review/benchmark_light_models.py MODEL_NAME`，不改生产默认或运行资源。

ISNet相同3帧证据为 `review/{dash,run,pogo}-isnet-general-use-comparison.jpg`、`review/isnet-general-use-benchmark.json`。输入1024，预处理为RGB按最大值归一后减0.5，原输出归一并还原源尺寸，参考[官方rembg ISNet会话](https://github.com/danielgatis/rembg/blob/main/rembg/sessions/dis_general_use.py)。显式调用 `SemanticMatte(model_path=.../'isnet-general-use.onnx', model_family='isnet', threads=4)`；无需安装rembg整包。它目前是候选而非默认。

另执行了一次U2NetP宽松ROI与源色差混合诊断：概率>0.15的最大连通体膨胀3px，ROI内源底色差恢复alpha，按背景亮度比例识别地影。实际深浅底结果出现浅色头盔/叉齿/靴子丢失、dash披风白圈，拒收。源码 `review/benchmark_hybrid_matte.py` 与三张 `*-u2netp-hybrid-comparison.jpg` 仅保留诊断证据，不可用于生产。源片的背景与象牙装备色彩接近，简单阈值不能可靠分开。

## 既有PyTorch环境只读盘点

`work/wan22-production/venv/Lib/site-packages` 中存在torch、torchvision等目录以及标注 `torch-2.14.1+cu130.dist-info` 的目录，但 `venv/Scripts/python.exe` 不存在，该dist-info中的METADATA也不存在；matting-models目录递归未发现模型文件。目录名不足以证明运行时完整可用，本次没有尝试安装/修复或重新下载GB级依赖。

## 验收边界

模型是前景显著物分割，不保证“仅角色”语义。接触物体、被遮挡身体、头手变形、源镜头裁切都可能需要裁段或返修。语义本体mask不能直接当FX alpha；FX应在身体保护之外单独处理光晕、世界弹体和地面空间。接触表不能证明循环无跳帧、左右操作正确或游戏性能达标。
