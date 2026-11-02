# main 水下柔光制作源

从 zhaosongju 的 main 提交 `49ed188ac1f90ac8f1aaf61fa370169aa6edfb69` 选择性复用独立柔光，供母蟹训练场使用。没有重新生成图片，原七房关卡和其他环境层保留在来源分支。

- [生成原件](generated/underwater-light-original.png)：1024×1536 RGBA，原调用提示词见 [prompt.txt](prompt.txt)，工具与原件哈希见 [provenance.json](provenance.json)。
- [编辑母版](master/UNDERWATER-SOFT-LIGHT.png)：512×768 RGBA，原流程缩放并羽化边缘。
- [运行导出](../../runtime/xumen-soft-light/UNDERWATER-SOFT-LIGHT.png)：与来源提交逐字节一致，经运行清单同步到 `game/art/environment/soft_light.png`。

原批次还修复了旧背景中的多边形光束接缝。训练场使用自己的完整洞窟位图，不需要那套背景修复图。本地只保存本次使用的柔光源文件；[原批次完整记录](https://github.com/Canace22/BOB/tree/49ed188ac1f90ac8f1aaf61fa370169aa6edfb69/assets/source/xumen-soft-light)保留原制作脚本和其余文件。

训练场的独立纹理、12 秒呼吸、边缘渐隐、强度和实机验收见[接入说明](../crab-environment-main/README.md)。这是静态光效位图加材质播放，不计新增逐帧动画。
