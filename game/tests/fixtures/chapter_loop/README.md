# 第一章循环样板场地

场景和两房数据取自已确认源提交`8d086a7caafb31415fef0c3fa24ebce0baace845`，只服务独立`tests/whalebelly/chapter_loop_play.tscn`。场景继续引用项目现有位图和环境；这里不复制素材或存档。正式`content/whalebelly/r1/`保留Vesion/V1.0.1新版地形、岸台与碰撞，不从夹具反向同步。

`ChapterLoopRoomStream`只在该样板中使用；正式主线的默认构造仍为`CampaignRoomStream`。冻结坐标用于复现已确认的对话、聚食区和折井路线，不代表当前正式19房已经接入整章故事。修改样板时运行`test_chapter_loop.gd`与原生`chapter_loop_regression.gd`，保留警告、通行、结果、折井、重玩全部断言。
