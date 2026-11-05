# 骨壁生台：E33 / E35

按原T03接入合同制作，原七房、26地形碰撞、能力门与V6保存不变。`originals` 为内置Imagegen真实位图原件，`masters` 保存可编辑OpenRaster、逐实例坐标、局部选区及哈希，运行件在 `assets/runtime/scenes/xumen-vertical-v1`，按manifest同步至game。台账与实机状态分别记录，用户审美不等于技术通过。

重建单边：`python assets/source/xumen-vertical-v1/build.py E33`（或E35），随后 `node tools/godot.mjs sync-art`。重建会将该边台账置回候选，应实际复验。不要重建已合格主路资产。ORA使用固定ZIP时间，重复构建不因时间戳改变母版。

纵深背景按高幅原生绘制，等比覆盖画布后裁边；骨壁是低对比中景，平台才对齐单向碰撞。三种平台真实图块分别裁片，平顶配准，接道使用同尺度绘画材质组合。刚性骨质不形变。鱼身帧和路径分开，气泡预热/渐隐/回收，使用章级可暂停时钟。原房柔性件继续保留，不重复烘焙新鱼泡。

E33下口的旧E01骨拱从高处看有平切顶，增加独立手绘骨冠并只退让原拱顶60px的Alpha；原E01地面与碰撞未改。上口仅在限定空间选择旧World/Middle烘焙水色，保留骨、灯、附生物，选区保存为PNG，不是全局蓝键。所有更动必须关闭前景实际查看。

验收：`authored_shaft_qa.gd -- --edge=E33`、`authored_shaft_visual.gd`、`authored_shaft_bench.gd` 与 `web_authored_shafts.mjs`。浏览器明确用现有房间预览/F9练习作为夹具，后续真实键盘下返/上行；不是自然取得后期能力。原生和Web存档均隔离。截图/录像只保存在game/build/qa/xumen-transitions，实际状态见game/progress.md。
