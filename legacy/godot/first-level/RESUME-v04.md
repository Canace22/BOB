# v0.4 接续
读取docs/v04/execution.md、scene-manifest.json、element-mapping.json、qa-summary.json、delivery.md和.production状态。
正式工程仍godot/first-level；固定4.7.2.ed1daf0bf。七房场景scenes/r1，设计数据assets/rooms.json，原图及SVG assets/reference/r1。runtime/v04为5项新分层/模块资源；source/master保留未改原件。
本轮新增room_routes、route_blueprint、scene_inspector、world_graph、route_checks、route_mechanism_checks、v04_art_checks；main/level/player/game/scenery_motion/atmosphere已接入。
主路门按数据与门ID匹配返回，F9借A2/A3且禁止写档；远侧闩保持关闭；07右墙封闭。Inspector状态退出必须恢复层显隐、原进度和位置。
证据evidence/v04/package-*；branch/latch/death为项目图形或独立进程回归。A3测试夹具起点x25/y16，仅之后挂环与跨房属Input路线实测。
备份work/r1-before-route-v04.zip；v0.3运行包与原设计册未变。
不要重跑work/r1_route_art_v04.py或r1_route_code_v04.py，它们是一次性修改脚本，会重复节点。修改新场景后按实际影响重测。work/r1_v04_verify.py接受art/routes/mechanisms/play/branch/latch/death/reload/normal；最后导出work/r1_v04_package.py。map-only变化可--visual-only，必须记录复用测试的范围。
后续可做：统一门、奖励与敌人的正式分件动画；长地形专用模块；真实可步行失败坡（需单独更新几何合同）；后续区域A2/A3取得流程。当前不扩建后续区域。
