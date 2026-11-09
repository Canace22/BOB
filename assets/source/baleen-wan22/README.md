# 四处垂须 · Wan2.2视频到12FPS帧动画

2026-10-29。用户圈定左、中、右近景须帘及右侧远景蓝色垂帘。仅修改环境动画，沿用唯一Godot工程、既有位置和图层，不新增玩法。

## 成果与规格

- 四组各36张RGBA PNG，合计144张。每组12 FPS、3秒，6×6图集。帧尺寸分别430×360、290×230、350×330、220×300；锚点和场景位置见manifest.json。
- ComfyUI 0.42.0实际调用本地Wan2.2 TI2V 5B；权重文件wan2.2_ti2v_5B_fp16.safetensors，运行采用fp8_e4m3fn以适配8GB显存。未调用外部付费服务。
- Krita5.3.4.1实际导入36张动画帧并保存四份KRA：12FPS，0–35帧，每份一层动画、一层空的修正层。没有声称人工逐帧手绘。
- 独立Godot元素BALEEN-LEFT/CENTER/RIGHT/DISTANT已替换图集，主R1-01与环境预览共享。旧Blender源和运行素材保留以便回退。

## 源视频与派生方法

第一份孤立中央须帘视频出现条纹、合并细丝和根部变化，拒绝用于成品，保留raw/BALEEN-CENTER及review/pilot-rejection.json。

定向返修为640×384完整场景图生视频。第二份49帧/24FPS片包含可用垂须运动，但也有轻微全局漂移。最终不直接使用生成视频像素：从视频测量每组局部光流，减去根部共同漂移，将运动投射到已批准的原画RGBA，固定根部和周边、限制幅度，加入平滑回位包络。它是**Wan视频运动驱动的原画帧动画**；远景保留为蓝色内嵌裁片，非逐丝物理模拟。

实际时长49/24=2.041667秒，按用户规则ceil(2.041667)×12=36张。完整源段重定时到3秒，每帧保存来源浮点位置；没有复制最后一帧填充。3秒循环运动有回位处理，与源视频原速不同。所有36帧逐组哈希不同。根部受保护像素变化0；最大位移左6.24px、中8.06px、右8.83px、远景2.88px。首尾图像差低于本组最大相邻帧差，但不等同于用户审美签收。

## 文件与编辑

- reference/：用户红框原件。
- inputs/、workflows/、metadata/*-job.json、*-history.json：实际输入、Comfy API工作流、prompt ID、版本、失败与成功记录。模型本体在本机work/wan22-production，不重复入库。
- raw/、videos/*-source.mp4：未经清理的49帧模型输出与24FPS原片，包含失败样片。
- frames/：4×36最终透明帧。videos/*-12fps.mp4为独立动画预览。
- krita/*.kra：可编辑原生动画文件。打开动画时间轴，修改相应帧；保持画布、12FPS和0–35范围。不要运行生成器覆盖手工修改。
- metadata/*-motion.npz：量化光流、根部权重及源帧位置；manifest.json记录位移、哈希、规格和处理来源。
- ../../runtime/baleen-wan22及Godot/assets/baleen_wan22：最终图集。

## 复现与接续

使用本机work/wan22-production/helpers/Scripts/python.exe，包含OpenCV5、NumPy、Pillow。

1. tools/baleen_wan22.py run --ids CONTEXT-MOTION 查询保存的prompt ID，已完成任务不重复提交。prepare会重建输入清单，手工调整后不运行prepare覆盖。
2. tools/process_baleen_wan22.py：解码原视频，测运动、生成透明帧和图集，写Krita导入请求。
3. tools/install_baleen_krita.py：安装显式请求文件触发的本地插件；启动项目内便携Krita。结果见metadata/krita-results.json，原生文件结构检查见krita-file-checks.json。已有插件与配置保留，配置备份位于work/wan22-production/kritarc.before-baleen。
4. tools/integrate_baleen_wan22.py：绑定现有四个元素和更新布局；基础环境重建脚本末尾已挂接，防止退回旧图集。
5. Godot4.7.2导入后执行tests/baleen_wan22_qa.gd、baleen_wan22_main.gd、motion_elements_qa.gd、motion_loop_render.gd。录像/独立包再验后执行tools/deliver_baleen_wan22.py更新原交付页。

## 验收与限制

19项专项、17项环境、4项渲染循环、8项当前主场景检查通过；KRA内部各36关键帧/12FPS已检查。32秒实机录像、相机边界图、主关卡移动截图和独立包验证在godot/WhalebellyRuins/evidence/baleen_wan22。

旧qa_reference_level测试仍使用旧角色visual_state和旧输入，在新campaign_player中报错，不能称该旧测试通过。本轮改为当前tp_*移动/跳跃、暂停和场景重载测试；不是完整七房通关回归。首次定向测试退出有资源释放警告，改用项目graceful_quit后复测，记录保留于返修说明。

视觉检查是AI对原片和实机抽样关键帧的复核，未声称人工逐帧验收。原贴图细丝边缘仍可能有抠图差异；光流和回位包络是运动处理，不是原画重新设计。
